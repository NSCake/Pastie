//
//  NSArray+Map.h
//  Pastie
//  
//  Created by Tanner Bennett on 2021-05-11
//  Copyright © 2021 Tanner Bennett. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray<T> (Functional)

- (__kindof NSMutableArray *)pastie_mapped:(id(^)(T obj, NSUInteger idx))mapFunc;
+ (instancetype)pastie_forEachUpTo:(NSUInteger)bound map:(T(^)(NSUInteger i))block;
- (NSMutableArray<T> *)pastie_filtered:(BOOL (^)(T obj, NSUInteger idx))filterFunc;

@end
