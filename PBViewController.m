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
#import "PBMetaTagParser.h"
#import "Interfaces.h"

#define kReuseID @"PBViewController"

@interface UIScrollView (Private)
- (BOOL)_scrollToTopIfPossible:(BOOL)animated;
@end

static BOOL PastieController_isPresented = NO;

@interface PastieController ()
@property (nonatomic) PBViewController *stringsViewController;
@property (nonatomic) PBViewController *urlsViewController;
@end

@implementation PastieController

- (id)init {
    self = [super init];
    if (self) {
        _stringsViewController = [PBViewController stringsPasteViewController];
        _urlsViewController = [PBViewController urlsPasteViewController];
        
        self.viewControllers = @[
            [[UINavigationController alloc] initWithRootViewController:_stringsViewController],
            [[UINavigationController alloc] initWithRootViewController:_urlsViewController],
        ];
        
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
@property (nonatomic) PBDataType type;


@property (nonatomic, nonatomic) NSString *computedTitle;
@property (nonatomic) NSString *filterText;

@property (nonatomic) UIWindow *window;
@property (nonatomic, readonly) UIMenu *moreMenu;
@property (nonatomic, readonly) NSString *trashTitle;
@property (nonatomic, readonly) NSString *trashButtonTitle;
@property (nonatomic, readonly) NSArray<UIBarButtonItem *> *defaultRightBarButtonItems;
@property (nonatomic, readonly) NSArray<UIBarButtonItem *> *editingRightBarButtonItems;
@end

@implementation PBViewController

#pragma mark - Factory Methods

+ (instancetype)type:(PBDataType)type {
    PBViewController *controller = [PBViewController new];
    controller.type = type;
    return controller;
}

+ (instancetype)stringsPasteViewController {
    return [self type:PBDataTypeStrings];
}

+ (instancetype)urlsPasteViewController {
    return [self type:PBDataTypeURLs];
}

#pragma mark - Data Source Delegate

- (PBDataSource *)pastieDataSource {
    return (id)self.tableView.dataSource;;
}

- (void)setPastieDataSource:(PBDataSource *)dataSource {
    self.tableView.dataSource = dataSource;
    [self reloadData:NO];
}

- (void)guardHasDataSource {
    NSAssert(self.pastieDataSource, @"PBViewController must have a valid data source");
}

- (void)promptToDeleteCorruptDatabase {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Error"
        message:@"Could not open database"
        preferredStyle:UIAlertControllerStyleAlert
    ];
    [alert addAction:[UIAlertAction
            actionWithTitle:@"Delete Corrupt Database"
            style:UIAlertActionStyleDestructive
            handler:^(UIAlertAction *action) {
                [self didPressDestroy];
            }
    ]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = nil;
    
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

    [PBDataSource open:self.type completion:^(PBDataSource *dataSource, NSError *error) {
        if (error) {
            return [self promptToDeleteCorruptDatabase];
        }

        self.pastieDataSource = dataSource;
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
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.window.hidden = YES;
}

#pragma mark - Helper Methods

- (NSString *)computedTitle {
    if (self.tableView.isEditing) {
        NSInteger selected = self.tableView.indexPathsForSelectedRows.count;
        return [NSString stringWithFormat:@"%@ Selected", @(selected)];
    }
    
    return @"Pastie";
}

- (PBDataSource *)dataSource {
    return (PBDataSource *)self.tableView.dataSource;
}

#pragma mark - Properties

- (void)setFilterText:(NSString *)filterText {
    _filterText = filterText;
    [self.pastieDataSource filterWithText:self.filterText];
    [self.tableView reloadData];
}

- (BOOL)filtering {
    return self.filterText.length > 0;
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
    NSString *itemType = self.type == PBDataTypeURLs ? @"URLs" : @"Pastes";
    
    if (self.tableView.isEditing) {
        return [NSString stringWithFormat:@"Delete Selected %@", itemType];
    }

    return self.filtering
        ? [NSString stringWithFormat:@"Delete Search Results"]
        : [NSString stringWithFormat:@"Delete All %@", itemType];
}

- (NSString *)trashButtonTitle {
    if (self.tableView.isEditing) {
        return @"Delete Selected";
    }

    return self.filtering ? @"Delete Results" : @"Delete All";
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
    [self guardHasDataSource];
    
    [self.dataSource addFromClipboard:^(BOOL success) {
        if (success) {
            [self reloadData:YES];
        } else {
            [self presentModal:@"Nothing to Add"
                message:@"Try copying something first, then come back!"
            ];
        }
    }];
}

- (void)didPressTrash {
    [self guardHasDataSource];
    
    if (self.tableView.isEditing) {
        NSArray *selected = self.tableView.indexPathsForSelectedRows;
        NSArray *resultsToClear = [selected pastie_mapped:^id(NSIndexPath *obj, NSUInteger idx) {
            return self.dataSource.data[obj.row];
        }];
        
        // FIXME: disable this button if no items are selected
        if (!resultsToClear.count) {
            return;
        }
        
        return [self promptToDeleteEntries:resultsToClear orClearAll:NO];
    }
    
    NSArray *resultsToClear = self.filtering ? self.dataSource.data : nil;
    [self promptToDeleteEntries:resultsToClear orClearAll:!resultsToClear];
}

/// Uses the button title properties declared above
- (void)promptToDeleteEntries:(NSArray *)items orClearAll:(BOOL)clearAllIfEmpty {
    if (!items.count && !clearAllIfEmpty) {
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
            id completion = ^(NSError *error) {
                if (error) {
                    [self presentModal:@"Error Deleting Pastes" message:error.localizedDescription];
                } else {
                    [self reloadData:YES];
                    [self endEditingTable];
                }
            };
        
            if (items.count) {
                [self.pastieDataSource deleteItems:items completion:completion];
            } else {
                [self.pastieDataSource deleteAllItems:completion];
            }
        }
    ]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)didPressDestroy {
    [self guardHasDataSource];
    
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Destroy Database"
        message:@"Are you sure? This operation cannot be undone."
        preferredStyle:UIAlertControllerStyleAlert
    ];
    [alert addAction:[UIAlertAction actionWithTitle:@"Yes, Delete the Database"
        style:UIAlertActionStyleDestructive
        handler:^(UIAlertAction *action) {
            [self.dataSource destroyDatabase:^(NSError *error) {
                if (error) {
                    [self presentModal:@"Error" message:error.localizedDescription];
                }
            }];
        }
    ]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)reloadData:(BOOL)animated {
    [self.dataSource reloadDataWithTableView:self.tableView animated:animated completion:nil];
}

#pragma mark - UI Actions

/// For importing a pastie database
- (BOOL)tryOpenDatabase:(NSURL *)fileURL {
    [self guardHasDataSource];
    
    if ([fileURL.pathExtension isEqualToString:@"db"]) {
        [self promptUserToImportDatabaseWith:^(BOOL shouldImport) {
            if (shouldImport) {
                [self.dataSource importDatabase:fileURL backupFirst:YES completion:^(NSError *error) {
                    if (error) {
                        [self presentModal:@"Error Importing Pastes" message:error.localizedDescription];
                    }
                    
                    [self reloadData:YES];
                }];
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
        [UIAction actionWithTitle:@"Select Items"
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
    if (self.dataSource.data.count > 0) {
        NSString *firstURL = [self.dataSource.data pastie_firstWhere:^BOOL (NSString *s, NSUInteger idx) {
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
    [self guardHasDataSource];
    
    NSURL *filePath = [NSURL fileURLWithPath:self.dataSource.pasteDB.databasePath];
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
    
    id item = self.pastieDataSource.data[indexPath.row];
    [self.pastieDataSource copyToClipboard:item];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self dismiss:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        self.title = self.computedTitle;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    [self beginEditingTable];
    return YES;
}

#pragma mark Search Bar

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    // Automatically reloads the table view, no need to call reloadData
    self.filterText = searchController.searchBar.text;
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    [self.tableView reloadData];
}

@end
