//
//  PastieWindow.h
//  Pastie
//  
//  Created by Tanner Bennett on 2022-04-27
//  Copyright © 2022 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PastieWindow : UIWindow

/// Tracked so we can restore the key window after dismissing a modal.
/// We need to become key after modal presentation so we can correctly capture input.
/// If we're just showing the toolbar, we want the main app's window to remain key
/// so that we don't interfere with input, status bar, etc.
@property (nonatomic, readonly) UIWindow *previousKeyWindow;

@end
