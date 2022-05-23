//
//  PBViewController.m
//  Pastie
//  
//  Created by Tanner Bennett on 2021-05-11
//  Copyright © 2021 Tanner Bennett. All rights reserved.
//

#import "PBViewController.h"
#import "NSArray+Map.h"
#import "PDBManager.h"
#import "Interfaces.h"

#define kReuseID @"PBViewController"

static BOOL PastieController_isPresented = NO;
@implementation PastieController

- (id)init {
    self = [self initWithRootViewController:[PBViewController new]];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFormSheet;
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
@property (nonatomic) NSMutableArray<NSString *> *strings;
@property (nonatomic) NSMutableArray<NSString *> *images;
@property (nonatomic) NSMutableArray<NSString *> *dataSource;
@property (nonatomic) NSDictionary<NSString*,UIImage*> *pathsToImages;

/// Filtered, or not, and drived from the strings property.
@property (nonatomic, readonly) NSMutableArray<NSString *> *rows;
@property (nonatomic) NSString *filterText;

@property (nonatomic) UIWindow *window;
@property (nonatomic, readonly) UIMenu *moreMenu;
@end

@implementation PBViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Pastie";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
        target:self action:@selector(didPressTrash)
    ];
    self.navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemDone
            target:self action:@selector(dismiss:)
        ],
        [[UIBarButtonItem alloc]
            initWithImage:[UIImage systemImageNamed:@"ellipsis"]
            menu:self.moreMenu
        ]
    ];
    
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
    
    self.tableView.automaticallyAdjustsScrollIndicatorInsets = NO;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:kReuseID];
    [self reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.window = self.view.window;
    [self.window makeKeyWindow];
    
    if (PDBManager.sharedManager.lastResult.isError) {
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:@"Error"
            message:PDBManager.sharedManager.lastResult.message
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

- (void)dismiss:(BOOL)paste {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        if (paste) {
            // TODO: paste using UIKeyInput insertText: from a responder
        }
    }];
}

- (void)didPressTrash {
    BOOL filtering = self.filterText.length;
    
    NSString *title = filtering ?
        @"Delete Search Results" : @"Clear History";
    NSString *buttonTitle = filtering ?
        @"Delete Results" : @"Clear History";
    
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:title
        message:@"Are you sure? This operation cannot be undone."
        preferredStyle:UIAlertControllerStyleAlert
    ];
    
    NSArray *resultsToClear = filtering ? self.dataSource : nil;
    
    [alert addAction:[UIAlertAction actionWithTitle:buttonTitle
        style:UIAlertActionStyleDestructive
        handler:^(UIAlertAction *action) {
            if (resultsToClear) {
                [PDBManager.sharedManager deleteStrings:resultsToClear];
            } else {
                [PDBManager.sharedManager clearAllHistory];
            }
        
            [self reloadData];
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
            [PDBManager.sharedManager destroyDatabase:^(NSError *error) {
                UIAlertController(@"Error", error.localizedDescription);
            }];
        }
    ]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)reloadData {
    self.strings = [PDBManager.sharedManager allStrings];
    self.images = [PDBManager.sharedManager allImages];
    // Reload data source and table view, preserving filter
    self.filterText = self.filterText;
}

- (void)setFilterText:(NSString *)filterText {
    _filterText = filterText;
    
    if (filterText.length) {
        self.dataSource = [self.strings pastie_filtered:^BOOL(NSString *obj, NSUInteger idx) {
            return [obj localizedCaseInsensitiveContainsString:filterText];
        }];
    } else {
        self.dataSource = self.strings;
    }
    
    [self.tableView reloadData];
}

#pragma mark Actions

- (UIMenu *)moreMenu {
    return [UIMenu menuWithChildren:@[
        [UIAction actionWithTitle:@"Share Full History"
                            image:[UIImage systemImageNamed:@"square.and.arrow.up"]
                       identifier:nil
                          handler:^(UIAction *action) {
            [self shareFullDatabase];
        }]
    ]];
}

- (void)shareFullDatabase {
    NSURL *filePath = [NSURL fileURLWithPath:PDBManager.sharedManager.databasePath];
    UIActivityViewController *shareSheet = [[UIActivityViewController alloc]
        initWithActivityItems:@[filePath] applicationActivities:nil
    ];
    [self presentViewController:shareSheet animated:YES completion:nil];
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id item = self.dataSource[indexPath.row];
    PDBManager.sharedManager.lastCopy = item;
    UIPasteboard.generalPasteboard.string = item;
    [self dismiss:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *item = self.dataSource[indexPath.row];
    [self.strings removeObject:item];
    [self.dataSource removeObjectAtIndex:indexPath.row];
    
    [PDBManager.sharedManager deleteString:item];
    
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:0];
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kReuseID forIndexPath:indexPath];
    cell.textLabel.text = self.dataSource[indexPath.row];
    cell.textLabel.numberOfLines = 3;
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
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
