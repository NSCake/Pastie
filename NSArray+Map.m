//
//  NSArray+Map.m
//  Pastie
//  
//  Created by Tanner Bennett on 2021-05-11
//  Copyright © 2021 Tanner Bennett. All rights reserved.
//

#import "NSArray+Map.h"

@implementation NSArray (Functional)

- (__kindof NSMutableArray *)pastie_mapped:(id (^)(id, NSUInteger))mapFunc {
    NSMutableArray *map = [NSMutableArray new];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id ret = mapFunc(obj, idx);
        if (ret) {
            [map addObject:ret];
        }
    }];

    return map;
}

+ (__kindof NSArray *)pastie_forEachUpTo:(NSUInteger)bound map:(id(^)(NSUInteger))block {
    NSMutableArray *array = [NSMutableArray new];
    for (NSUInteger i = 0; i < bound; i++) {
        id obj = block(i);
        if (obj) {
            [array addObject:obj];
        }
    }

    return array;
}

- (NSMutableArray *)pastie_filtered:(BOOL (^)(id, NSUInteger))filterFunc {
    return [self pastie_mapped:^id(id obj, NSUInteger idx) {
        return filterFunc(obj, idx) ? obj : nil;
    }];
}

- (id)pastie_firstWhere:(BOOL (^)(id, NSUInteger))predicate {
    return [self pastie_filtered:predicate].firstObject;
}

@end
