//
//  Tweak.xm
//  PastieUIKit
//  
//  Created by Tanner Bennett on 2021-05-11
//  Copyright © 2021 Tanner Bennett. All rights reserved.
//

#import "../Interfaces.h"

void ShowPastie();

%hook UIInputSwitcherView
- (void)_reloadInputSwitcherItems {
    %orig;
    
    NSMutableArray<UIInputSwitcherItem *> *items = [(id)self valueForKey:@"m_inputSwitcherItems"];
    UIInputSwitcherItem *item = [%c(UIInputSwitcherItem) switcherItemWithIdentifier:kPackageName];
    item.localizedTitle = @"Pasteboard";
    [items insertObject:item atIndex:2];
}

- (int)didSelectItemAtIndex:(NSInteger)idx {
    NSMutableArray<UIInputSwitcherItem *> *items = [(id)self valueForKey:@"m_inputSwitcherItems"];
    if (items[idx].identifier == kPackageName) {
        [self hide];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Setup connection
            LMConnection connection = {
                MACH_PORT_NULL,
                _kPackageName
            };

            // Send message
            LMResponseBuffer buffer;
            const char *msg = _kPackageName;
            LMConnectionSendTwoWay(&connection, /* msg ID */ 0, msg, strlen(msg) + 1, &buffer);

            // Cleanup
            LMResponseBufferFree(&buffer);
        });
        return idx;
    } else {
        return %orig;
    }
}
%end

// IPC //

void ShowPastie() {
    
}
