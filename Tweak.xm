//
//  Tweak.xm
//  Pastie
//
//  Created by Tanner Bennett on 2021-05-07
//  Copyright © 2021 Tanner Bennett. All rights reserved.
//

#import "Interfaces.h"

/// Present the Pastie controller at half height
%hook _UISheetPresentationController
- (id)initWithPresentedViewController:(id)present presentingViewController:(id)presenter {
    self = %orig;
    if ([present isKindOfClass:PastieController.self]) {
        self._presentsAtStandardHalfHeight = YES;
    }
    
    return self;
}
%end

/// Prevent this window from being hidden while Pastie is presented
%hook SBBannerWindow
- (void)setHidden:(BOOL)hidden {
    if (hidden && PastieController.isPresented) return;
    %orig;
}
%end

void ServerMain(CFMachPortRef port, LMMessage *message, CFIndex size, void *info) {
	// Get the reply port
	mach_port_t replyPort = message->head.msgh_remote_port;

	// Check validity of message
	if (!LMDataWithSizeIsValidMessage(message, size)) {
        LMSendReply(replyPort, NULL, 0);
        LMResponseBufferFree((LMResponseBuffer *)message);
        return;
	}
    
	// Get message data
	// const char *data = (const char *)LMMessageGetData(message);
	// size_t length = LMMessageGetDataLength(message);
    
    // Show pastie
    if (!PastieController.isPresented) {
        // Show it from the banner window; the banner window is usually hidden,
        // so show it first. Pastie will hide it when it dismisses.
        SpringBoard *springboard = (id)UIApplication.sharedApplication;
        UIWindow *window = springboard.bannerManager.bannerWindow; window.hidden = NO;
        UIViewController *root = window.rootViewController;
        [root presentViewController:[PastieController new] animated:YES completion:nil];
    }

	// If we ever need to send data back
	LMSendReply(replyPort, nil, 0);

	// Cleanup
	LMResponseBufferFree((LMResponseBuffer *)message);
}

%ctor {
    %init;
    
    // Start LightMessaging server
    dispatch_async(dispatch_get_main_queue(), ^{
        LMStartService(_kPackageName, CFRunLoopGetCurrent(), (CFMachPortCallBack)ServerMain);
    });
    
    // Observe pasteboard notifications
    static int token = 0;
    dispatch_queue_t global = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    notify_register_dispatch("com.apple.pasteboard.notify.changed", &token, global, ^(int _){
        UIPasteboard *pb = UIPasteboard.generalPasteboard;
        if (pb.hasImages) {
            // [PDBManager.sharedManager addImages:pb.images];
        } else {
            [PDBManager.sharedManager addStrings:pb.strings];
        }
    });
}
