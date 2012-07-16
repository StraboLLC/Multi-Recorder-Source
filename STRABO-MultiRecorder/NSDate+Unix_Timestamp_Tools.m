//
//  NSDate+Unix_Timestamp_Tools.m
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/13/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import "NSDate+Unix_Timestamp_Tools.h"

@implementation NSDate (Unix_Timestamp_Tools)

+(NSString *)currentUnixTimestampString {
    return [NSString stringWithFormat:@"%d", (int)[[NSDate date] timeIntervalSince1970]];
}

+(NSNumber *)currentUnixTimestampNumber {
    return @((int)[[NSDate date] timeIntervalSince1970]);
}

@end
