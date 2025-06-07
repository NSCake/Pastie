#import "Interfaces.h"
static __attribute__((constructor)) void ctor(int __unused argc, char __unused **argv, char __unused **envp) {
    
    static int token = 0;
    notify_register_dispatch("com.apple.pasteboard.notify.changed", &token, dispatch_get_main_queue(), ^(int _){
        UIPasteboard *pb = UIPasteboard.generalPasteboard;
        [PDBManager open:^(PDBManager *db, NSError *error) {
            if (pb.hasImages) {
                [db addImages:pb.images];
            } else {
                [db addStrings:pb.strings];
            }
        }];
//        UIViewController *root = UIApplication.sharedApplication.keyWindow.rootViewController;
//        [root presentViewController:[PastieController new] animated:YES completion:nil];
    });
}
