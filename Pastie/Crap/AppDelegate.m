//
//  AppDelegate.m
//  Pastie
//
//  Created by Tanner Bennett on 5/11/21.
//

#import "AppDelegate.h"
#import "Interfaces.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    PBViewController *pb = [PBViewController new];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [PastieController new];
    [self.window makeKeyAndVisible];
    
    [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer *timer) {
        [pb reloadData];
    }];
    
    return YES;
}


@end
