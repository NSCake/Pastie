//
//  PDBManager.h
//  Pastie
//  
//  Created by Tanner Bennett on 2021-05-07
//  Copyright © 2021 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSQLResult.h"

/// Pastie database manager
@interface PDBManager : NSObject

/// Singleton instance
@property (nonatomic, readonly, class) PDBManager *sharedManager;
/// Defaults to 1000
@property (nonatomic) NSInteger limit;
/// Contains the result of the last operation, which may be an error
@property (nonatomic, readonly) PSQLResult *lastResult;

@property (nonatomic) id lastCopy;

- (BOOL)addStrings:(NSArray<NSString *> *)string;
- (BOOL)addImages:(NSArray<UIImage *> *)image;

- (void)deleteString:(NSString *)string;
- (void)deleteImage:(NSString *)imagePath;

- (void)clearAllHistory;
- (void)destroyDatabase:(void(^)(NSError *))errorCallback;

- (NSMutableArray<NSString *> *)allStrings;
/// @return an array of image file names. Pass to \c pathForImageWithName:
- (NSMutableArray<NSString *> *)allImages;

- (NSString *)pathForImageWithName:(NSString *)name;

@end
