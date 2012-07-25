//
//  NSString+MD5.h
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/13/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Extends NSString with a function to produce a string hashed with the MD5 algorithm.
 */
@interface NSString (MD5)

/**
 Hashes a given string with the MD5 algorithm.
 */
-(NSString *)MD5;

@end
