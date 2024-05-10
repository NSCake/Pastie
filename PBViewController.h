//
//  PBViewController.h
//  Pastie
//  
//  Created by Tanner Bennett on 2021-05-11
//  Copyright © 2021 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PBViewController;

@interface PastieController : UINavigationController
@property (nonatomic, class) BOOL isPresented;
@property (nonatomic, readonly) PBViewController *tableViewController;
@end

@interface PBViewController : UITableViewController

- (void)reloadData;

@end
