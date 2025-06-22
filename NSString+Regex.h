//
//  NSString+Regex.h
//  Pastie
//
//  Created by Tanner Bennett on 3/31/24.
//  
//

#import <Foundation/Foundation.h>

@interface NSString (Regex)

- (BOOL)pastie_matches:(NSString *)regex;
- (BOOL)pastie_matches:(NSString *)stringOrPattern regex:(BOOL)regex;

@end
