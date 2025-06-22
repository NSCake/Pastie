//
//  PBViewController.h
//  Pastie
//  
//  Created by Tanner Bennett on 2021-05-11
//  Copyright © 2021 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBURLPaste.h"
#import "PBDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@class PBViewController;

@interface PastieController : UITabBarController
@property (nonatomic, class) BOOL isPresented;
@property (nonatomic, readonly) PBViewController *stringsViewController;
@property (nonatomic, readonly) PBViewController *urlsViewController;
@end

@interface PBViewController : UITableViewController

/// String table or URL table
@property (nonatomic, readonly) PBDataType type;
@property (nonatomic) PBDataSource *pastieDataSource;

+ (instancetype)stringsPasteViewController;
+ (instancetype)urlsPasteViewController;

- (void)reloadData:(BOOL)animated;

/// Import a pastie database, replacing the current one
- (BOOL)tryOpenDatabase:(NSURL *)fileURL;

@end

NS_ASSUME_NONNULL_END
