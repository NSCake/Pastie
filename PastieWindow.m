//
//  PastieWindow.m
//  Pastie
//  
//  Created by Tanner Bennett on 2022-04-27
//  Copyright © 2022 Tanner Bennett. All rights reserved.
//

#import "PastieWindow.h"
#import <objc/runtime.h>

@implementation PastieWindow

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Some apps have windows at UIWindowLevelStatusBar + n.
        // If we make the window level too high, we block out UIAlertViews.
        // There's a balance between staying above the app's windows and staying below alerts.
        // UIWindowLevelStatusBar + 100 seems to hit that balance.
        self.windowLevel = UIWindowLevelStatusBar + 99;
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    BOOL pointInside = [super pointInside:point withEvent:event];
    return pointInside;
}

- (BOOL)_canAffectStatusBarAppearance {
    return self.isKeyWindow;
}

- (BOOL)_canBecomeKeyWindow {
    return YES;
}

- (void)makeKeyWindow {
   _previousKeyWindow = self.appKeyWindow;
   [super makeKeyWindow];
}

- (void)resignKeyWindow {
   [super resignKeyWindow];
   _previousKeyWindow = nil;
}

- (UIWindow *)appKeyWindow {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // First, check UIApplication.keyWindow
    PastieWindow *window = (id)UIApplication.sharedApplication.keyWindow;
#pragma clang diagnostic pop
    if (window) {
        if ([window isKindOfClass:NSClassFromString(@"FLEXWindow")]) {
            return [window previousKeyWindow];
        }
        
        return window;
    }
    
    // As of iOS 13, UIApplication.keyWindow does not return nil,
    // so this is more of a safeguard against it returning nil in the future.
    //
    // Also, these are obviously not all FLEXWindows; FLEXWindow is used
    // so we can call window.previousKeyWindow without an ugly cast
    for (PastieWindow *window in UIApplication.sharedApplication.windows) {
        if (window.isKeyWindow) {
            if ([window isKindOfClass:NSClassFromString(@"FLEXWindow")]) {
                return [window previousKeyWindow];
            }
            
            return window;
        }
    }
    
    return nil;
}

@end
