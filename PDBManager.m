//
//  PDBManager.m
//  Pastie
//  
//  Created by Tanner Bennett on 2021-05-07
//  Copyright © 2021 Tanner Bennett. All rights reserved.
//

#import "Interfaces.h"
#import <objc/objc.h>
#import <Foundation/Foundation.h>
#import "NSArray+Map.h"
#import "PBMetaTagParser.h"
#import <sqlite3.h>

NSString * const kAppGroupIdentifier = @"group.com.nscake.pastie";

NSString * const kPDBCreatePastesTable = @"CREATE TABLE IF NOT EXISTS Paste ( "
    "id INTEGER PRIMARY KEY, "
    "string TEXT, "
    "imagePath TEXT " // Actually just filenames
");";

NSString * const kPDBDeleteAll = @"DELETE FROM Paste;";
NSString * const kPDBSaveString = @"INSERT INTO Paste ( string ) VALUES ( $string );";
NSString * const kPDBSaveImage = @"INSERT INTO Paste ( imagePath ) VALUES ( $imagePath );";
NSString * const kPDBDeletePaste = @"DELETE FROM Paste WHERE id = $id;";
NSString * const kPDBDeletePasteByString = @"DELETE FROM Paste WHERE string = $string;";
NSString * const kPDBDeletePastesByStrings = @"DELETE FROM Paste WHERE string in $strings;";
NSString * const kPDBDeletePasteByImage = @"DELETE FROM Paste WHERE imagePath = $imagePath;";
NSString * const kPDBFindPaste = @"SELECT * FROM Paste WHERE id = $id;";
NSString * const kPDBListStrings = @"SELECT id, string FROM Paste WHERE string IS NOT NULL ORDER BY id DESC;";
NSString * const kPDBListImages = @"SELECT id, imagePath FROM Paste WHERE imagePath IS NOT NULL ORDER BY id DESC;";

#define PDBPathForImageWithFilename(filename) [PDBDatabaseDirectory() \
    stringByAppendingPathComponent:[@"Images/" \
        stringByAppendingString:filename \
    ] \
]

NSString * PDBDatabaseDirectory(void) {
    static NSString *directory = nil;
    if (directory) return directory;
    
    #ifdef __APPLE__
    NSURL *container = [NSFileManager.defaultManager
        containerURLForSecurityApplicationGroupIdentifier:kAppGroupIdentifier
    ];
    
    directory = [container URLByAppendingPathComponent:@"Pastes" isDirectory:YES].path;
    #else
    directory = [NSSearchPathForDirectoriesInDomains(
        NSCachesDirectory, NSUserDomainMask, YES
    )[0] stringByAppendingPathComponent:@"Pastie"];
    #endif
    
    return directory;
}

@interface PDBManager ()
@property (nonatomic) sqlite3 *db;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, readonly) NSDateFormatter *dateFieldFormatter;
@end

@implementation PDBManager

+ (instancetype)sharedManager {
    static PDBManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [self new];
    });
    
    return shared;
}

- (id)init {
    self = [super init];
    
    if (self) {
        self.limit = 1000;
        self.path = [PDBDatabaseDirectory() stringByAppendingPathComponent:@"pastes.db"];
        
        // Create pastes and images folders
        [NSFileManager.defaultManager
            createDirectoryAtPath:PDBPathForImageWithFilename(@"")
            withIntermediateDirectories:YES
            attributes:nil
            error:nil
        ];
        
        [self createTables];
    }
    
    return self;
}

- (void)dealloc {
    [self close];
}

- (NSDateFormatter *)dateFieldFormatter {
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [NSDateFormatter new];
        formatter.dateFormat = @"yyyy-MM-dd-HH:mm:ss";
    }
    
    return formatter;
}

- (BOOL)open {
    if (self.db) {
        return YES;
    }
    
    int err = sqlite3_open(self.path.UTF8String, &_db);

    if (err != SQLITE_OK) {
        _db = nil;
        return NO;
    }
    
    return YES;
}
    
- (BOOL)close {
    if (!self.db) {
        return YES;
    }
    
    int  rc;
    BOOL retry, triedFinalizingOpenStatements = NO;
    
    do {
        retry = NO;
        rc    = sqlite3_close(_db);
        if (SQLITE_BUSY == rc || SQLITE_LOCKED == rc) {
            if (!triedFinalizingOpenStatements) {
                triedFinalizingOpenStatements = YES;
                sqlite3_stmt *pStmt;
                while ((pStmt = sqlite3_next_stmt(_db, nil)) != 0) {
                    sqlite3_finalize(pStmt);
                    retry = YES;
                }
            }
        } else if (SQLITE_OK != rc) {
            self.db = nil;
            return NO;
        }
    } while (retry);
    
    self.db = nil;
    return YES;
}

/// @return YES on success, NO if an error was encountered and stored in \c lastResult
- (BOOL)bindParameters:(NSDictionary *)args toStatement:(sqlite3_stmt *)pstmt {
    for (NSString *param in args.allKeys) {
        int status = SQLITE_OK, idx = sqlite3_bind_parameter_index(pstmt, param.UTF8String);
        id value = args[param];
        
        if (idx == 0) {
            // No parameter matching that arg
            @throw NSInternalInconsistencyException;
        }
        
        // Null
        if ([value isKindOfClass:[NSNull class]]) {
            status = sqlite3_bind_null(pstmt, idx);
        }
        // String params
        else if ([value isKindOfClass:[NSString class]]) {
            const char *str = [value UTF8String];
            status = sqlite3_bind_text(pstmt, idx, str, (int)strlen(str), SQLITE_TRANSIENT);
        }
        // Data params
        else if ([value isKindOfClass:[NSData class]]) {
            const void *blob = [value bytes];
            status = sqlite3_bind_blob64(pstmt, idx, blob, [value length], SQLITE_TRANSIENT);
        }
        // Primitive params
        else if ([value isKindOfClass:[NSNumber class]]) {
            TypeEncoding type = [value objCType][0];
            switch (type) {
                case TypeEncodingCBool:
                case TypeEncodingChar:
                case TypeEncodingUnsignedChar:
                case TypeEncodingShort:
                case TypeEncodingUnsignedShort:
                case TypeEncodingInt:
                case TypeEncodingUnsignedInt:
                case TypeEncodingLong:
                case TypeEncodingUnsignedLong:
                case TypeEncodingLongLong:
                case TypeEncodingUnsignedLongLong:
                    status = sqlite3_bind_int64(pstmt, idx, (sqlite3_int64)[value longValue]);
                    break;
                
                case TypeEncodingFloat:
                case TypeEncodingDouble:
                    status = sqlite3_bind_double(pstmt, idx, [value doubleValue]);
                    break;
                    
                default:
                    @throw NSInternalInconsistencyException;
                    break;
            }
        }
        // Unsupported type
        else {
            @throw NSInternalInconsistencyException;
        }
        
        if (status != SQLITE_OK) {
            return [self storeErrorForLastTask:
                [NSString stringWithFormat:@"Binding param named '%@'", param]
            ];
        }
    }
    
    return YES;
}

- (BOOL)storeErrorForLastTask:(NSString *)action {
    _lastResult = [self errorResult:action];
    return NO;
}

- (PSQLResult *)errorResult:(NSString *)description {
    const char *error = sqlite3_errmsg(_db);
    NSString *message = error ? @(error) : [NSString
        stringWithFormat:@"(%@: empty error)", description
    ];
    
    return [PSQLResult error:message];
}

- (void)createTables {
    [self executeStatement:kPDBCreatePastesTable];
}

- (id)objectForColumnIndex:(int)columnIdx stmt:(sqlite3_stmt*)stmt {
    int columnType = sqlite3_column_type(stmt, columnIdx);
    
    switch (columnType) {
        case SQLITE_INTEGER:
            return @(sqlite3_column_int64(stmt, columnIdx)).stringValue;
        case SQLITE_FLOAT:
            return  @(sqlite3_column_double(stmt, columnIdx)).stringValue;
        case SQLITE_BLOB:
            return [NSString stringWithFormat:@"Data (%@ bytes)",
                @([self dataForColumnIndex:columnIdx stmt:stmt].length)
            ];
            
        default:
            // Default to a string for everything else
            return [self stringForColumnIndex:columnIdx stmt:stmt] ?: NSNull.null;
    }
}
                
- (NSString *)stringForColumnIndex:(int)columnIdx stmt:(sqlite3_stmt *)stmt {
    if (sqlite3_column_type(stmt, columnIdx) == SQLITE_NULL || columnIdx < 0) {
        return nil;
    }
    
    const char *text = (const char *)sqlite3_column_text(stmt, columnIdx);
    return text ? @(text) : nil;
}

- (NSData *)dataForColumnIndex:(int)columnIdx stmt:(sqlite3_stmt *)stmt {
    if (sqlite3_column_type(stmt, columnIdx) == SQLITE_NULL || (columnIdx < 0)) {
        return nil;
    }
    
    const void *blob = sqlite3_column_blob(stmt, columnIdx);
    NSInteger size = (NSInteger)sqlite3_column_bytes(stmt, columnIdx);
    
    return blob ? [NSData dataWithBytes:blob length:size] : nil;
}

- (PSQLResult *)executeStatement:(NSString *)sql {
    return [self executeStatement:sql arguments:nil];
}

- (PSQLResult *)executeStatement:(NSString *)sql arguments:(NSDictionary *)args {
    if (![self open]) {
        return nil;
    }
    
    PSQLResult *result = nil;
    
    sqlite3_stmt *pstmt;
    int status;
    if ((status = sqlite3_prepare_v2(_db, sql.UTF8String, -1, &pstmt, 0)) == SQLITE_OK) {
        NSMutableArray<NSArray *> *rows = [NSMutableArray new];
        
        // Bind parameters, if any
        if (![self bindParameters:args toStatement:pstmt]) {
            return self.lastResult;
        }
        
        // Grab columns
        int columnCount = sqlite3_column_count(pstmt);
        NSArray<NSString *> *columns = [NSArray pastie_forEachUpTo:columnCount map:^id(NSUInteger i) {
            return @(sqlite3_column_name(pstmt, (int)i));
        }];
        
        // Hoping to fix weird crash
        if (!pstmt || (void *)pstmt < (void *)0x100000000) {
            return nil;
        }
        
        // Execute statement
        while ((status = sqlite3_step(pstmt)) == SQLITE_ROW) {
            // Grab rows if this is a selection query
            int dataCount = sqlite3_data_count(pstmt);
            if (dataCount > 0) {
                [rows addObject:[NSArray pastie_forEachUpTo:columnCount map:^id(NSUInteger i) {
                    return [self objectForColumnIndex:(int)i stmt:pstmt];
                }]];
            }
        }
        
        if (status == SQLITE_DONE) {
            if (rows.count) {
                // We selected some rows
                result = _lastResult = [PSQLResult columns:columns rows:rows];
            } else {
                // We executed a query like INSERT, UDPATE, or DELETE
                int rowsAffected = sqlite3_changes(_db);
                NSString *message = [NSString stringWithFormat:@"%d row(s) affected", rowsAffected];
                result = _lastResult = [PSQLResult message:message];
            }
        } else {
            // An error occured executing the query
            result = _lastResult = [self errorResult:@"Execution"];
        }
    } else {
        // An error occurred creating the prepared statement
        result = _lastResult = [self errorResult:@"Prepared statement"];
    }
    
    sqlite3_finalize(pstmt);
    return result;
}

- (PSQLResult *)lastInsert {
    // Cache last result so we don't overwrite it with this operation
    PSQLResult *lastResult = _lastResult;
    
    PSQLResult *lastInsert = [self executeStatement:@"SELECT last_insert_rowid();"];
    _lastResult = lastResult;
    
    // Pull rowid out of the result and select that row and return it
    if (!lastInsert.isError) {
        NSInteger rowid = [lastInsert.rows[0][0] integerValue];
        return [self executeStatement:kPDBFindPaste arguments:@{ @"$id": @(rowid) }];
    }
    else {
        return lastInsert;
    }
}

- (NSString *)databasePath { return self.path; }

#pragma mark Pastes

- (BOOL)addStrings:(NSArray<NSString *> *)strings {
    if (!strings.count) return YES;
    
    NSString *string = strings[0];
    if (!string.length) return YES;
    
    if (strings.count > 1) {
        string = [strings componentsJoinedByString:@"\n"];
    }
    // else {
    //     // Abort if this is the string we just copied
    //     if ([self.lastCopy isEqualToString:string]) {
    //         return YES;
    //     }
    // }
    
    // Move this string to the front if it's already inserted
    [self deleteString:string];
    
    return ![self executeStatement:kPDBSaveString arguments:@{
        @"$string": string
    }].isError;
}

- (BOOL)addImages:(NSArray<UIImage *> *)images {
    if (!images.count) return YES;
    
    if (images.count == 1) {
        // Abort if this is the image we last copied
        if (self.lastCopy == images.firstObject) {
            return YES;
        }
    }
    
    // Generate filenames from UUIDs for each image
    NSArray<NSString *> *imagePaths = [images pastie_mapped:^id(UIImage *image, NSUInteger idx) {
        NSString *uuid = [NSUUID.UUID.UUIDString stringByAppendingString:@".png"];
        return uuid;
    }];
    
    // Write images to files on background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSInteger i = 0; i < images.count; i++) {
            UIImage *image = images[i];
            NSString *path = PDBPathForImageWithFilename(imagePaths[i]);
            NSData *data = UIImagePNGRepresentation(image);
            [data writeToFile:path atomically:YES];
        }
    });
    
    // Insert each image
    for (NSString *path in imagePaths) {
        if ([self executeStatement:kPDBSaveImage arguments:@{
            @"$imagePath": path
        }].isError) {
            return NO;
        }
    }
    
    return YES;
}

- (void)deleteStrings:(NSArray<NSString *> *)strings {
    for (NSString *s in strings) {
        [self deleteString:s];
    }
}

- (void)deleteString:(NSString *)string {
    [self executeStatement:kPDBDeletePasteByString arguments:@{
        @"$string": string
    }];
}

- (void)deleteURL:(NSString *)url {
    [self executeStatement:kPDBDeleteURLByString arguments:@{
        @"$string": url
    }];

}

- (void)deleteImage:(NSString *)imagePath {
    [self executeStatement:kPDBDeletePasteByImage arguments:@{
        @"$imagePath": imagePath
    }];
}

/// Not entirely sure why I broke this out; it won't be that useful for much else besides `allStrings`
- (NSMutableArray<NSString *> *)select:(NSString *)query {
    PSQLResult *result = [self executeStatement:query];
    if (!result.isError && result.rows.count) {
        return (NSMutableArray *)[result.rows pastie_mapped:^id(NSArray<NSString *> *row, NSUInteger idx) {
            // This pulls the "string" out of `SELECT id, string`
            return row[1];
        }];
    }
    
    return nil;
}

- (NSMutableArray<NSString *> *)allStrings {
    return [self select:kPDBListStrings];
}

- (NSMutableArray<NSString *> *)allImages {
    return @[].mutableCopy; //[self select:kPDBListImages];
}

- (NSString *)pathForImageWithName:(NSString *)name {
    return PDBPathForImageWithFilename(name);
}

#pragma mark Data Management

- (void)clearAllHistory {
    // Delete images from disk first
    NSArray<NSString *> *images = [self allImages];
    for (NSString *filename in images) {
        NSString *path = [self pathForImageWithName:filename];
        [NSFileManager.defaultManager removeItemAtPath:path error:nil];
    }
    
    [self executeStatement:kPDBDeleteAll];
}

- (void)destroyDatabase:(void(^)(NSError *))errorCallback {
    [self close];
    
    // Skip file deletion if file does not exist
    if (![NSFileManager.defaultManager fileExistsAtPath:self.path]) {
        [self createTables];
    } else {
        NSError *error = nil;
        [NSFileManager.defaultManager removeItemAtPath:self.path error:&error];
        
        if (!error) {
            [self createTables];
        } else {
            errorCallback(error);
        }
    }
}

- (void)importDatabase:(NSURL *)fileURL backupFirst:(BOOL)backup callback:(void(^)(NSError *))callback {
    NSString *path = fileURL.path;
    
    // Ensure file exists at the given path
    if (![NSFileManager.defaultManager fileExistsAtPath:path]) {
        return callback([NSError errorWithDomain:@"PDBManager" code:0 userInfo:@{
            NSLocalizedDescriptionKey: @"File does not exist"
        }]);
    }
    
    [self close];
    NSError *error = nil;
    
    // Backup the old database first
    if (backup) {
        static NSDateFormatter *formatter = nil;
        if (!formatter) {
            formatter = [NSDateFormatter new];
            formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
        }
        
        // Backup path should include the current date in the ISO 8601 format like so: "pastes-2021-05-07T12:00:00Z.db"
        NSString *dateString = [formatter stringFromDate:NSDate.date];
        NSString *backupPath = [PDBDatabaseDirectory()
            stringByAppendingPathComponent:[NSString stringWithFormat:@"pastes-%@.db", dateString]
        ];
        
        // Copy the new database
        [NSFileManager.defaultManager copyItemAtPath:self.path toPath:backupPath error:&error];
        if (error) {
            return callback(error);
        }
    }
    
    // Remove the old the database
    [NSFileManager.defaultManager removeItemAtPath:self.path error:&error];
    if (error) {
        return callback(error);
    }
    
    // Replace existing db with new db
    [NSFileManager.defaultManager copyItemAtPath:path toPath:self.path error:&error];
    
    if (error) {
        return callback(error);
    }
    
    [self open];
    callback(nil);
}

@end
