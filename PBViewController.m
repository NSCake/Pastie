//
//  PBViewController.m
//  Pastie
//  
//  Created by Tanner Bennett on 2021-05-11
//  Copyright © 2021 Tanner Bennett. All rights reserved.
//

#import "PBViewController.h"
#import "NSArray+Map.h"
#import "NSString+Regex.h"
#import "PDBManager.h"
#import "PBMetaTagParser.h"
#import "Interfaces.h"

#define kReuseID @"PBViewController"

@interface UIScrollView (Private)
- (BOOL)_scrollToTopIfPossible:(BOOL)animated;
@end

static BOOL PastieController_isPresented = NO;
@implementation PastieController

- (id)init {
    self = [self initWithRootViewController:[PBViewController new]];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFormSheet;
        _tableViewController = self.viewControllers.firstObject;
        PastieController_isPresented = YES;
    }
    
    return self;
}

- (void)dealloc {
    PastieController_isPresented = NO;
}

+ (BOOL)isPresented {
    return PastieController_isPresented;
}

+ (void)setIsPresented:(BOOL)isPresented {
    PastieController_isPresented = isPresented;
}

@end

@interface PBViewController () <UISearchControllerDelegate, UISearchResultsUpdating>
@property (nonatomic, readonly) PDBManager *pasteDB;

@property (nonatomic) NSMutableArray<NSString *> *strings;
@property (nonatomic) NSMutableArray<NSString *> *images;
@property (nonatomic) NSMutableArray<NSString *> *dataSource;
@property (nonatomic) NSDictionary<NSString*,UIImage*> *pathsToImages;

@property (nonatomic, nonatomic) NSString *computedTitle;
/// Filtered, or not, and drived from the strings property.
@property (nonatomic, readonly) NSMutableArray<NSString *> *rows;
@property (nonatomic) NSString *filterText;

@property (nonatomic) UIWindow *window;
@property (nonatomic, readonly) UIMenu *moreMenu;
@property (nonatomic, readonly) NSString *trashTitle;
@property (nonatomic, readonly) NSString *trashButtonTitle;
@property (nonatomic, readonly) NSArray<UIBarButtonItem *> *defaultRightBarButtonItems;
@property (nonatomic, readonly) NSArray<UIBarButtonItem *> *editingRightBarButtonItems;
@end

@implementation PBViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.computedTitle;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
        target:self action:@selector(didPressTrash)
    ];
    
    self.navigationItem.rightBarButtonItems = self.defaultRightBarButtonItems;
    
    if (@available(iOS 13.0, *)) {
        self.navigationItem.leftBarButtonItem.tintColor = UIColor.systemRedColor;
    } else {
        self.navigationItem.leftBarButtonItem.tintColor = UIColor.redColor;
    }
    
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = self;
    searchController.automaticallyShowsCancelButton = YES;
    searchController.obscuresBackgroundDuringPresentation = NO;
    searchController.hidesNavigationBarDuringPresentation = NO;
    self.navigationItem.searchController = searchController;
    
    #ifndef __APPLE__
    self.tableView.automaticallyAdjustsScrollIndicatorInsets = NO;
    #endif
    
    self.tableView.showsVerticalScrollIndicator = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:kReuseID];
    
    [PDBManager open:^(PDBManager *db, NSError * _Nullable error) {
        if (error) {
            
        }
        
        _pasteDB = db;
        [self reloadData:NO];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView _scrollToTopIfPossible:NO];
    
    // CGPoint offset = CGPointMake(0, -(self.tableView.contentInset.top));
    // self.tableView.contentOffset = offset;
    // self.navigationItem.hidesSearchBarWhenScrolling = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.tableView _scrollToTopIfPossible:NO];
    [self reloadData:NO];
    
    // [UIView animateWithDuration:0.2 animations:^{
    //     self.navigationItem.hidesSearchBarWhenScrolling = YES;
    //     [self.navigationController.view setNeedsLayout];
    //     [self.navigationController.view layoutIfNeeded];
    // }];
    
    self.window = self.view.window;
    [self.window makeKeyWindow];
    
    if (self.pasteDB.lastResult.isError) {
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:@"Error"
            message:self.pasteDB.lastResult.message
            preferredStyle:UIAlertControllerStyleAlert
        ];
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete Corrupt Database"
            style:UIAlertActionStyleDestructive
            handler:^(UIAlertAction *action) {
                [self didPressDestroy];
            }
        ]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.window.hidden = YES;
}

#pragma mark Properties

- (NSString *)computedTitle {
    if (self.tableView.isEditing) {
        NSInteger selected = self.tableView.indexPathsForSelectedRows.count;
        return [NSString stringWithFormat:@"%@ Selected", @(selected)];
    }
    
    return @"Pastie";
}

- (NSArray<UIBarButtonItem *> *)defaultRightBarButtonItems {
    #ifdef __APPLE__
    return @[
        [[UIBarButtonItem alloc]
            initWithImage:[UIImage systemImageNamed:@"ellipsis"]
            menu:self.moreMenu
        ],
        [[UIBarButtonItem alloc]
         initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
         target:self action:@selector(addPaste)
        ]
    ];
    #else
    return @[
        [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemDone
            target:self action:@selector(dismiss:)
        ],
        [[UIBarButtonItem alloc]
            initWithImage:[UIImage systemImageNamed:@"ellipsis"]
            menu:self.moreMenu
        ]
    ];
    #endif
}

- (NSArray<UIBarButtonItem *> *)editingRightBarButtonItems {
    return @[
        [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemDone
            target:self action:@selector(endEditingTable)
        ]
    ];
}

- (NSString *)trashTitle {
    if (self.tableView.isEditing) {
        return @"Delete Selected Pastes";
    }

    BOOL filtering = self.filterText.length;
    return filtering ? @"Delete Search Results" : @"Delete All Pastes";
}

- (NSString *)trashButtonTitle {
    if (self.tableView.isEditing) {
        return @"Delete Selected";
    }

    BOOL filtering = self.filterText.length;
    return filtering ? @"Delete Results" : @"Delete All";
}

#pragma mark Buttons

- (void)dismiss:(BOOL)paste {
    #ifndef __APPLE__
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        if (paste) {
            // TODO: paste using UIKeyInput insertText: from a responder
        }
    }];
    #endif
}

- (void)addPaste {
    if (UIPasteboard.generalPasteboard.hasStrings) {
        [self.pasteDB addStrings:UIPasteboard.generalPasteboard.strings callback:^(BOOL success) {
            [self reloadData:YES];
        }];
    }
    else {
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:@"Nothing to add!"
            message:@"Try copying something first, then come back!"
            preferredStyle:UIAlertControllerStyleAlert
        ];
        [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)didPressTrash {
    if (self.tableView.isEditing) {
        NSArray *selected = self.tableView.indexPathsForSelectedRows;
        NSArray *resultsToClear = [selected pastie_mapped:^id(NSIndexPath *obj, NSUInteger idx) {
            return self.dataSource[obj.row];
        }];
        
        if (!resultsToClear.count) {
            return;
        }
        
        return [self promptToDeleteStrings:resultsToClear orClearAll:NO];
    }
    
    BOOL filtering = self.filterText.length;
    NSArray *resultsToClear = filtering ? self.dataSource : nil;
    
    [self promptToDeleteStrings:resultsToClear orClearAll:!resultsToClear];
}

/// Uses the button title properties declared above
- (void)promptToDeleteStrings:(NSArray<NSString *> *)strings orClearAll:(BOOL)clearAllIfEmpty {
    if (!strings.count && !clearAllIfEmpty) {
        return;
    }
    
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:self.trashTitle
        message:@"Are you sure? This operation cannot be undone."
        preferredStyle:UIAlertControllerStyleAlert
    ];
    
    [alert addAction:[UIAlertAction actionWithTitle:self.trashButtonTitle
        style:UIAlertActionStyleDestructive
        handler:^(UIAlertAction *action) {
            id completion = ^{
                [self reloadData:YES];
                [self endEditingTable];
            };
        
            if (strings.count) {
                [self.pasteDB deleteStrings:strings callback:completion];
            } else {
                [self.pasteDB clearAllHistory:completion];
            }
        }
    ]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)didPressDestroy {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Destroy Database"
        message:@"Are you sure? This operation cannot be undone."
        preferredStyle:UIAlertControllerStyleAlert
    ];
    [alert addAction:[UIAlertAction actionWithTitle:@"Yes, Delete the Database"
        style:UIAlertActionStyleDestructive
        handler:^(UIAlertAction *action) {
            [self.pasteDB destroyDatabase:^(NSError *error) {
                UIAlertController(@"Error", error.localizedDescription);
            }];
        }
    ]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)reloadData:(BOOL)animated {
    [self softReloadData:^{
        if (animated) {
            // Preserve filter
            [self filterDataSource:self.filterText];
            // Animate in new rows
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            // Reload data source and table view, preserving filter
            self.filterText = self.filterText;
        }
    }];
}

- (void)softReloadData:(void(^)(void))completion {
    [self.pasteDB allStrings:^(NSMutableArray<NSString *> *strings) {
        [self.pasteDB allImages:^(NSMutableArray<NSString *> *images) {
            self.strings = strings;
            self.images = images;
            [self filterDataSource:self.filterText];
            [self.tableView reloadData];
            
            if (completion) completion();
        }];
    }];
    
}

- (void)setFilterText:(NSString *)filterText {
    _filterText = filterText;
    
    [self filterDataSource:filterText];
    [self.tableView reloadData];
}

/// Filter the data source using the current filter text, if any; does not reload the view
- (void)filterDataSource:(NSString *)filterText {
    if (filterText.length) {
        // Filter by regex if the string starts with a slash
        if ([filterText hasPrefix:@"/"]) {
            NSString *regex = [filterText substringFromIndex:1];
            self.dataSource = [self.strings pastie_filtered:^BOOL(NSString *obj, NSUInteger idx) {
                return [obj pastie_matches:regex];
            }];
        }
        // Ignore leading backslash to allow escaping a forward slash
        else if ([filterText hasPrefix:@"\\"]) {
            self.dataSource = [self.strings pastie_filtered:^BOOL(NSString *obj, NSUInteger idx) {
                return [obj localizedCaseInsensitiveContainsString:[filterText substringFromIndex:1]];
            }];
        }
        // Regular search
        else {
            self.dataSource = [self.strings pastie_filtered:^BOOL(NSString *obj, NSUInteger idx) {
                return [obj localizedCaseInsensitiveContainsString:filterText];
            }];
        }
    } else {
        self.dataSource = self.strings;
    }
}

#pragma mark Public

/// For importing a pastie database
- (BOOL)tryOpenDatabase:(NSURL *)fileURL {
    if ([fileURL.pathExtension isEqualToString:@"db"]) {
        [self promptUserToImportDatabaseWith:^(BOOL shouldImport) {
            if (shouldImport) {
                [self.pasteDB importDatabase:fileURL backupFirst:YES callback:^(NSError *error) {
                    if (error) {
                        [self presentModal:@"Error Importing Pastes" message:error.localizedDescription];
                    }
                    
                    [self reloadData:YES];
                }];
                [self reloadData:YES];
            }
        }];
        return YES;
    }
    else {
        [self presentModal:@"Unsupported File Type" message:@"Expected '.db'"];
        return NO;
    }
}

- (void)promptUserToImportDatabaseWith:(void(^)(BOOL))callback {
    [self promptUser:@"Import Pastie Data?"
             message:@"The current database will be backed up and replaced."
             handler:callback
    ];
}

#pragma mark Actions

- (UIMenu *)moreMenu {
    return [UIMenu menuWithChildren:@[
        [UIAction actionWithTitle:@"Share Full History"
                            image:[UIImage systemImageNamed:@"square.and.arrow.up"]
                       identifier:nil
                          handler:^(UIAction *action) {
            [self shareFullDatabase];
        }],
        [UIAction actionWithTitle:@"Select Pastes"
                            image:[UIImage systemImageNamed:@"checkmark.circle"]
                       identifier:nil
                          handler:^(UIAction *action) {
            [self beginEditingTable];
        }],
        // For debugging, an action to fetch the meta tags of the first URL we find
        [UIAction actionWithTitle:@"Fetch MetaTags"
                            image:[UIImage systemImageNamed:@"tag"]
                       identifier:nil
                          handler:^(UIAction *action) {
            [self testing_fetchMetaTags];
        }]
    ]];
}

- (void)testing_fetchMetaTags {
    if (self.dataSource.count > 0) {
        NSString *firstURL = [self.dataSource pastie_firstWhere:^BOOL (NSString *s, NSUInteger idx) {
            return ([s hasPrefix:@"http://"] || [s hasPrefix:@"https://"]) && [NSURL URLWithString:s];
        }];
        
        if (firstURL) {
            NSURL *url = [NSURL URLWithString:firstURL];
            [PBMetaTagParser fetchMetaTagsForURL:url completion:^(PBMetaTagParser *parser, NSError *error) {
                if (error) {
                    [self presentModal:@"Error Fetching Meta Tags" message:error.localizedDescription];
                } else {
                    [self presentModal:@"Meta Tags" message:parser.description];
                }
            }];
        } else {
            [self presentModal:@"No Valid URL Found" message:@"Please paste a valid URL."];
        }
    } else {
        [self presentModal:@"No URLs Found" message:@"Please paste some URLs first."];
    }
}

- (void)shareFullDatabase {
    NSURL *filePath = [NSURL fileURLWithPath:self.pasteDB.databasePath];
    UIActivityViewController *shareSheet = [[UIActivityViewController alloc]
        initWithActivityItems:@[filePath] applicationActivities:nil
    ];
    [self presentViewController:shareSheet animated:YES completion:nil];
}

- (void)beginEditingTable {
    if (self.tableView.isEditing) {
        return;
    }
    
    self.title = self.computedTitle;
    [self.tableView setEditing:YES animated:YES];
    self.navigationItem.rightBarButtonItems = self.editingRightBarButtonItems;
}

- (void)endEditingTable {
    if (!self.tableView.isEditing) {
        return;
    }
    
    self.title = self.computedTitle;
    [self.tableView setEditing:NO animated:YES];
    self.navigationItem.rightBarButtonItems = self.defaultRightBarButtonItems;
}

- (void)presentModal:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:title
        message:message
        preferredStyle:UIAlertControllerStyleAlert
    ];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIAlertController *)presentAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:title
        message:message
        preferredStyle:UIAlertControllerStyleAlert
    ];
    
    [self presentViewController:alert animated:YES completion:nil];
    return alert;
}

- (void)promptUser:(NSString *)title message:(NSString *)message handler:(void(^)(BOOL))callback {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:title
        message:message
        preferredStyle:UIAlertControllerStyleAlert
    ];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Yes"
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *action) {
            callback(YES);
        }
    ]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
        style:UIAlertActionStyleCancel
        handler:^(UIAlertAction *action) {
            callback(NO);
        }
    ]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        self.title = self.computedTitle;
        return;
    }
    
    id item = self.dataSource[indexPath.row];
    self.pasteDB.lastCopy = item;
    UIPasteboard.generalPasteboard.string = item;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self dismiss:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        self.title = self.computedTitle;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *item = self.dataSource[indexPath.row];
    [self.dataSource removeObjectAtIndex:indexPath.row];
    
    [self.pasteDB deleteString:item callback:^{
        [self softReloadData:^{
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:0];
        }];
    }];
}

- (BOOL)tableView:(UITableView *)tableView shouldBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    [self beginEditingTable];
    return YES;
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kReuseID forIndexPath:indexPath];
    cell.textLabel.numberOfLines = 4;
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    cell.textLabel.text = [self.dataSource[indexPath.row]
        stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet
    ];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

#pragma mark Search Bar

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    self.filterText = searchController.searchBar.text;
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    [self.tableView reloadData];
}

@end
