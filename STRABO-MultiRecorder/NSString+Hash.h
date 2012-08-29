//
//  NSString+Hash.h
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/13/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Extends NSString with functions to produced hashed strings.
 */
@interface NSString (Hash)

/**
 Hashes a given string with the MD5 algorithm.
 
 @return NSString A string hashed with the MD5 algorithm.
 */
-(NSString *)MD5;

/**
 Hashes a given string with the SHA2 algorithm.
 
 @return NSString A string hashed with the SHA2 algorithm.
 */
-(NSString *)SHA2;

@end
