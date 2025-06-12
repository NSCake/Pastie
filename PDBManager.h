//
//  PDBManager.h
//  Pastie
//  
//  Created by Tanner Bennett on 2021-05-07
//  Copyright © 2021 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSQLResult.h"
#import "PBURLPaste.h"

NS_ASSUME_NONNULL_BEGIN

/// Pastie database manager
@interface PDBManager : NSObject

+ (void)open:(NS_NOESCAPE void (^)(PDBManager * _Nullable db, NSError * _Nullable error))openHandler;

#pragma mark Properties

/// Defaults to 1000
@property (nonatomic) NSInteger limit;
/// Contains the result of the last operation, which may be an error
@property (nonatomic, readonly, nullable) PSQLResult *lastResult;
/// Computes the result of last row inserted in the last insert operation
@property (nonatomic, readonly, nullable) PSQLResult *lastInsert;

@property (nonatomic, nullable) id lastCopy;

@property (nonatomic, readonly) NSString *databasePath;

#pragma mark Pastes

- (BOOL)addFromClipboard:(UIPasteboard *)clipboard;
- (void)addFromClipboard:(UIPasteboard *)clipboard callback:(NS_NOESCAPE void(^)(BOOL success))callback;

- (BOOL)addStrings:(NSArray<NSString *> *)string;
- (void)addStrings:(NSArray<NSString *> *)string callback:(NS_NOESCAPE void(^)(BOOL success))callback;

- (BOOL)addURL:(NSURL *)url resolvingTitle:(nullable void(^)(void))callback;
- (BOOL)addURL:(NSURL *)url title:(nullable NSString *)title;
- (void)addURL:(NSURL *)url title:(nullable NSString *)title callback:(NS_NOESCAPE void(^)(BOOL success))callback;
// - (BOOL)addURLPaste:(PBURLPaste *)urlPaste;
// - (void)addURLPaste:(PBURLPaste *)urlPaste callback:(NS_NOESCAPE void(^)(BOOL success))callback;

- (BOOL)addImages:(NSArray<UIImage *> *)image;
- (void)addImages:(NSArray<UIImage *> *)image callback:(NS_NOESCAPE void(^)(BOOL success))callback;

- (void)deleteString:(NSString *)string;
- (void)deleteString:(NSString *)string callback:(NS_NOESCAPE void(^)(void))callback;
- (void)deleteStrings:(NSArray<NSString *> *)strings;
- (void)deleteStrings:(NSArray<NSString *> *)strings callback:(NS_NOESCAPE void(^)(void))callback;
// - (void)deleteURL:(NSString *)url;
// - (void)deleteURL:(NSString *)url callback:(NS_NOESCAPE void(^)(void))callback;
- (void)deleteURLPaste:(PBURLPaste *)urlPaste;
- (void)deleteURLPaste:(PBURLPaste *)urlPaste callback:(NS_NOESCAPE void(^)(void))callback;
- (void)deleteURLPastes:(NSArray<PBURLPaste *> *)urlPastes;
- (void)deleteURLPastes:(NSArray<PBURLPaste *> *)urlPastes callback:(NS_NOESCAPE void(^)(void))callback;
- (void)deleteImage:(NSString *)imagePath;
- (void)deleteImage:(NSString *)imagePath callback:(NS_NOESCAPE void(^)(void))callback;

- (NSMutableArray<NSString *> *)allStrings;
/// @return an array of image file names. Pass to \c pathForImageWithName:
- (NSMutableArray<NSString *> *)allImages;
/// @return an array of URL paste objects
- (NSMutableArray<PBURLPaste *> *)allURLs;

- (void)allStrings:(NS_NOESCAPE void(^)(NSMutableArray<NSString *> *strings))callback;
- (void)allImages:(NS_NOESCAPE void(^)(NSMutableArray<NSString *> *images))callback;
- (void)allURLs:(NS_NOESCAPE void(^)(NSMutableArray<PBURLPaste *> *urlPastes))callback;

//- (NSString *)pathForImageWithName:(NSString *)name;

#pragma mark Data Management

- (BOOL)clearHistory:(PBDataType)type;
- (void)clearHistory:(PBDataType)type callback:(NS_NOESCAPE void(^)(NSError *error))callback;
- (void)destroyDatabase:(NS_NOESCAPE void(^)(NSError *))errorCallback;
- (void)importDatabase:(NSURL *)fileURL backupFirst:(BOOL)backup callback:(NS_NOESCAPE void(^)(NSError * _Nullable))callback;

#pragma mark Migrations

- (void)migrateURLsToURLTable:(NS_NOESCAPE void(^)(NSError * _Nullable))callback;

@end

NS_ASSUME_NONNULL_END
