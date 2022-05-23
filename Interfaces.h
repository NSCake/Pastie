//
//  Interfaces.h
//  Pastie
//
//  Created by Tanner Bennett on 2021-05-07
//  Copyright © 2021 Tanner Bennett. All rights reserved.
//

#pragma mark Imports

#import <UIKit/UIKit.h>
#include <notify.h>
#import "PDBManager.h"
#import "PastieWindow.h"
#import "PBViewController.h"
#define LIGHTMESSAGING_USE_ROCKETBOOTSTRAP 500
#import <LightMessaging/LightMessaging.h>

#pragma mark Interfaces

@interface _UISheetPresentationController : UIPresentationController
@property (setter=_setPresentsAtStandardHalfHeight:) BOOL _presentsAtStandardHalfHeight;
@end

@interface UIInputSwitcherView : UIView
- (void)hide;
@end

@interface UIInputSwitcherItem : NSObject
+ (instancetype)switcherItemWithIdentifier:(NSString *)identifier;
@property NSString *identifier;
@property NSString *localizedTitle;
@end

@interface SBBannerManager : NSObject
@property (nonatomic, readonly) UIWindow *bannerWindow;
@end

@interface SpringBoard : UIApplication
@property (nonatomic, readonly) SBBannerManager *bannerManager;
@end

typedef NS_ENUM(char, TypeEncoding) {
    TypeEncodingNull             = '\0',
    TypeEncodingUnknown          = '?',
    TypeEncodingChar             = 'c',
    TypeEncodingInt              = 'i',
    TypeEncodingShort            = 's',
    TypeEncodingLong             = 'l',
    TypeEncodingLongLong         = 'q',
    TypeEncodingUnsignedChar     = 'C',
    TypeEncodingUnsignedInt      = 'I',
    TypeEncodingUnsignedShort    = 'S',
    TypeEncodingUnsignedLong     = 'L',
    TypeEncodingUnsignedLongLong = 'Q',
    TypeEncodingFloat            = 'f',
    TypeEncodingDouble           = 'd',
    TypeEncodingLongDouble       = 'D',
    TypeEncodingCBool            = 'B',
    TypeEncodingVoid             = 'v',
    TypeEncodingCString          = '*',
    TypeEncodingObjcObject       = '@',
    TypeEncodingObjcClass        = '#',
    TypeEncodingSelector         = ':',
    TypeEncodingArrayBegin       = '[',
    TypeEncodingArrayEnd         = ']',
    TypeEncodingStructBegin      = '{',
    TypeEncodingStructEnd        = '}',
    TypeEncodingUnionBegin       = '(',
    TypeEncodingUnionEnd         = ')',
    TypeEncodingQuote            = '\"',
    TypeEncodingBitField         = 'b',
    TypeEncodingPointer          = '^',
    TypeEncodingConst            = 'r'
};


#pragma mark Macros

#define _kPackageName "com.nscake.pastie"
#define kPackageName @ _kPackageName


#define Alert(TITLE,MSG) [[[UIAlertView alloc] initWithTitle:(TITLE) \
message:(MSG) \
delegate:nil \
cancelButtonTitle:@"OK" \
otherButtonTitles:nil] show];

#define UIAlertController(title, msg) [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:1]
#define UIAlertControllerAddAction(alert, title, stl, code...) [alert addAction:[UIAlertAction actionWithTitle:title style:stl handler:^(id action) code]];
#define UIAlertControllerAddCancel(alert) [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]
#define ShowAlertController(alert, from) [from presentViewController:alert animated:YES completion:nil];
