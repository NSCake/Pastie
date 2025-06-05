//
//  PDBManager.h
//  Pastie
//  
//  Created by Tanner Bennett on 2021-05-07
//  Copyright © 2021 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSQLResult.h"

NS_ASSUME_NONNULL_BEGIN

/// Pastie database manager
@interface PDBManager : NSObject

#pragma mark Properties

/// Singleton instance
@property (nonatomic, readonly, class) PDBManager *sharedManager;
/// Defaults to 1000
@property (nonatomic) NSInteger limit;
/// Contains the result of the last operation, which may be an error
@property (nonatomic, readonly, nullable) PSQLResult *lastResult;
/// Computes the result of last row inserted in the last insert operation
@property (nonatomic, readonly, nullable) PSQLResult *lastInsert;

@property (nonatomic, nullable) id lastCopy;

@property (nonatomic, readonly) NSString *databasePath;

#pragma mark Pastes

- (BOOL)addStrings:(NSArray<NSString *> *)string;
- (BOOL)addImages:(NSArray<UIImage *> *)image;

- (void)deleteStrings:(NSArray<NSString *> *)strings;
- (void)deleteString:(NSString *)string;
- (void)deleteImage:(NSString *)imagePath;

- (NSMutableArray<NSString *> *)allStrings;
/// @return an array of image file names. Pass to \c pathForImageWithName:
- (NSMutableArray<NSString *> *)allImages;

- (void)allStrings:(void(^)(NSMutableArray<NSString *> *strings))callback;
- (void)allImages:(void(^)(NSMutableArray<NSString *> *images))callback;

- (NSString *)pathForImageWithName:(NSString *)name;

#pragma mark Data Management

- (void)clearAllHistory;
- (void)destroyDatabase:(void(^)(NSError *))errorCallback;
- (void)importDatabase:(NSURL *)fileURL backupFirst:(BOOL)backup callback:(void(^)(NSError * _Nullable))callback;

@end

NS_ASSUME_NONNULL_END
