//
//  PBViewController.h
//  Pastie
//  
//  Created by Tanner Bennett on 2021-05-11
//  Copyright © 2021 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PastieController : UINavigationController
@property (nonatomic, class) BOOL isPresented;
@end

@interface PBViewController : UITableViewController

- (void)reloadData;

@end
