//
//  PBDataSource.h
//  Pastie
//  
//  Created on 2025-06-08
//  Copyright © 2025 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PDBManager.h"
#import "PBURLPaste.h"

NS_ASSUME_NONNULL_BEGIN

@interface PBDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, readonly) PDBManager *pasteDB;
@property (nonatomic, readonly) PBDataType type;
@property (nonatomic, copy) NSString *filterText;

/// May be stings or URLPaste objects depending on the data source type
@property (nonatomic, readonly) NSArray *data;

+ (void)open:(PBDataType)type
  completion:(void (^)(PBDataSource * _Nullable, NSError * _Nullable))completion;

- (void)reloadDataWithTableView:(UITableView *)tableView
                       animated:(BOOL)animated
                     completion:(nullable void(^)(void))completion;

#pragma mark - Data Operations

/// Deletes specific items (strings or PBURLPastes) from the database
- (void)deleteItems:(NSArray *)items completion:(NS_NOESCAPE void (^)(void))completion;
- (void)deleteAllItems:(NS_NOESCAPE void(^)(NSError *error))callback;

- (void)addFromClipboard:(NS_NOESCAPE void (^)(BOOL didAdd))completion;
- (void)copyToClipboard:(id)item;

/// Filters the data source using the provided text
- (void)filterWithText:(nullable NSString *)text;

- (void)importDatabase:(NSURL *)fileURL
           backupFirst:(BOOL)backup
            completion:(NS_NOESCAPE void(^)(NSError * _Nullable error))completion;

- (void)destroyDatabase:(NS_NOESCAPE void(^)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
