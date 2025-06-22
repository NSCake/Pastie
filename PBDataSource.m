//
//  PBDataSource.m
//  Pastie
//  
//  Created on 2025-06-08
//  Copyright © 2025 Tanner Bennett. All rights reserved.
//

#import "PBDataSource.h"
#import "PBMetaTagParser.h"
#import "NSArray+Map.h"
#import "NSString+Regex.h"
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, PDBOperation) {
    PDBOperationInsert,
    PDBOperationDelete,
};

#define kReuseID @"PBViewController"

@interface PBDataSource ()
@property (nonatomic, readwrite) PDBManager *pasteDB;
@property (nonatomic, readwrite) PBDataType type;
@property (nonatomic) NSMutableArray *items; // Either NSString or PBURLPaste depending on type
@end

@implementation PBDataSource

#pragma mark - Initialization and Factory Methods

+ (void)open:(PBDataType)type completion:(void (^)(PBDataSource * _Nullable, NSError * _Nullable))completion {
    PBDataSource *dataSource = [PBDataSource new];
    dataSource.type = type;
    
    [PDBManager open:^(PDBManager * _Nullable db, NSError * _Nullable error) {
        if (error) {
            return completion(nil, error);
        }
        
        dataSource.pasteDB = db;
        
        void (^populateItems)(NSMutableArray *) = ^(NSMutableArray *items) {
            dataSource.items = items ?: [NSMutableArray array];
            completion(dataSource, nil);
        };

        // Initial load of data
        switch (type) {
            case PBDataTypeStrings:
                [db allStrings:populateItems];
                break;
            case PBDataTypeURLs:
                [db allURLs:populateItems];
        }
    }];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _items = [NSMutableArray array];
    }
    
    return self;
}

#pragma mark - Data Loading and Filtering

- (void)reloadDataWithTableView:(UITableView *)tableView animated:(BOOL)animated completion:(void(^)(void))completion {
    NSAssert(self.pasteDB, @"Database must be initialized before reloading data");
    
    void (^refreshUI)(void) = ^{
        // Apply filter if needed
        if (self.filterText.length > 0) {
            [self filterWithText:self.filterText];
        }
        
        if (animated) {
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:0] 
                     withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            [tableView reloadData];
        }
        
        completion();
    };
    
    void (^didFetch)(NSMutableArray *) = ^(NSMutableArray *items) {
        self.items = items ?: [NSMutableArray array];
        dispatch_async(dispatch_get_main_queue(), ^{
            refreshUI();
        });
    };

    switch (self.type) {
    case PBDataTypeStrings:
        [self.pasteDB allStrings:didFetch];
        break;
    case PBDataTypeURLs:
        [self.pasteDB allURLs:didFetch];
        break;
    }
}

- (void)filterWithText:(NSString *)filterText {
    if (!filterText.length || !self.items.count) {
        return;
    }
    
    self.filterText = filterText;
    NSMutableArray *originalItems = self.items;
    NSMutableArray *filteredItems = [NSMutableArray new];
    
    switch (self.type) {
    case PBDataTypeStrings: {
        if ([filterText hasPrefix:@"/"]) {
            NSString *regex = [filterText substringFromIndex:1];
            filteredItems = [originalItems pastie_filtered:^BOOL(NSString *obj, NSUInteger idx) {
                return [obj pastie_matches:regex];
            }];
        }
        // Ignore leading backslash to allow escaping a forward slash
        else if ([filterText hasPrefix:@"\\"]) {
            filteredItems = [originalItems pastie_filtered:^BOOL(NSString *obj, NSUInteger idx) {
                return [obj localizedCaseInsensitiveContainsString:[filterText substringFromIndex:1]];
            }];
        }
        // Regular search
        else {
            filteredItems = [originalItems pastie_filtered:^BOOL(NSString *obj, NSUInteger idx) {
                return [obj localizedCaseInsensitiveContainsString:filterText];
            }];
        }
        break;
    }
    case PBDataTypeURLs: {
        // Filter URL pastes
        NSString *searchText = filterText;
        
        // Filter by regex if the string starts with a slash
        BOOL isRegex = [filterText hasPrefix:@"/"];
        if (isRegex) {
            searchText = [filterText substringFromIndex:1];
        }
        // Handle escaping a forward slash
        else if ([filterText hasPrefix:@"\\"]) {
            searchText = [filterText substringFromIndex:1];
        }
        
        for (PBURLPaste *urlPaste in originalItems) {
            BOOL matches = NO;
            NSString *urlString = urlPaste.url;
            NSString *title = urlPaste.title ?: @"";
            NSString *domain = urlPaste.domain ?: @"";
            
            if (isRegex) {
                matches = [urlString pastie_matches:searchText] || 
                          [title pastie_matches:searchText] || 
                          [domain pastie_matches:searchText];
            } else {
                matches = [urlString localizedCaseInsensitiveContainsString:searchText] || 
                          [title localizedCaseInsensitiveContainsString:searchText] || 
                          [domain localizedCaseInsensitiveContainsString:searchText];
            }
            
            if (matches) {
                [filteredItems addObject:urlPaste];
            }
        }
        break;
    }
    }
    
    self.items = filteredItems;
}

#pragma mark - Data Operations

- (void)deleteItems:(NSArray *)items completion:(void (^)(void))completion {
    switch (self.type) {
        case PBDataTypeStrings:
            [self.pasteDB deleteStrings:items callback:completion];
            break;
        case PBDataTypeURLs:
            [self.pasteDB deleteURLPastes:items callback:completion];
            break;
    }
}

- (void)deleteAllItems:(void(^)(NSError *error))callback {
    [self.pasteDB clearHistory:self.type callback:callback];
}

- (void)addFromClipboard:(void (^)(BOOL didAdd))completion {
    switch (self.type) {
    case PBDataTypeStrings:
        [self.pasteDB addStrings:UIPasteboard.generalPasteboard.strings callback:completion];
        break;
    case PBDataTypeURLs: {
        // If there are any URLs, add them all one at a time (this logic belongs in the pdbmanager)
        if (UIPasteboard.generalPasteboard.hasURLs) {
            __block NSInteger successCount = 0;
            __block NSInteger totalCount = UIPasteboard.generalPasteboard.URLs.count;
            
            for (NSURL *url in UIPasteboard.generalPasteboard.URLs) {
                [self.pasteDB addURL:url resolvingTitle:^{
                    successCount++;
                    if (successCount == totalCount) {
                        completion(YES);
                    }
                }];
            }
        } else {
            completion(NO);
        }
        break;
    }
    }
}

- (void)copyToClipboard:(id)item {
    switch (self.type) {
    case PBDataTypeStrings:
        if ([item isKindOfClass:[NSString class]]) {
            self.pasteDB.lastCopy = item;
            UIPasteboard.generalPasteboard.string = item;
        }
        break;
    case PBDataTypeURLs:
        if ([item isKindOfClass:[PBURLPaste class]]) {
            PBURLPaste *urlPaste = item;
            self.pasteDB.lastCopy = urlPaste.url;
            UIPasteboard.generalPasteboard.URL = [NSURL URLWithString:urlPaste.url];
        }
        break;
    }
}

- (void)importDatabase:(NSURL *)fileURL backupFirst:(BOOL)backup completion:(void (^)(NSError * _Nullable))completion {
    [self.pasteDB importDatabase:fileURL backupFirst:backup callback:completion];
}

- (void)destroyDatabase:(void (^)(NSError * _Nullable))completion {
    [self.pasteDB destroyDatabase:completion];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kReuseID forIndexPath:indexPath];
    cell.textLabel.numberOfLines = 4;
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    
    id item = self.items[indexPath.row];
    
    switch (self.type) {
    case PBDataTypeStrings:
        cell.textLabel.text = [item stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        break;
    case PBDataTypeURLs: {
        PBURLPaste *urlPaste = item;
        
        // Display domain and title if available, otherwise just the URL
        if (urlPaste.title.length > 0) {
            cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", 
                                  urlPaste.title,
                                  urlPaste.url];
        } else if (urlPaste.domain.length > 0) {
            cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", 
                                  urlPaste.domain,
                                  urlPaste.url];
        } else {
            cell.textLabel.text = urlPaste.url;
        }
        break;
    }
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
                                            forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        id item = self.items[indexPath.row];
        
        // Update data model immediately
        [self.items removeObjectAtIndex:indexPath.row];
        
        // Delete from database
        [self deleteItems:@[item] completion:^{
            // Update UI
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }];
    }
}

@end
