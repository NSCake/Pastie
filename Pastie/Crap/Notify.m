#import "Interfaces.h"
static __attribute__((constructor)) void ctor(int __unused argc, char __unused **argv, char __unused **envp) {
    
    static int token = 0;
    notify_register_dispatch("com.apple.pasteboard.notify.changed", &token, dispatch_get_main_queue(), ^(int _){
        UIPasteboard *pb = UIPasteboard.generalPasteboard;
        if (pb.hasImages) {
            [PDBManager.sharedManager addImages:pb.images];
        } else {
            [PDBManager.sharedManager addStrings:pb.strings];
        }
        
//        UIViewController *root = UIApplication.sharedApplication.keyWindow.rootViewController;
//        [root presentViewController:[PastieController new] animated:YES completion:nil];
    });
}
