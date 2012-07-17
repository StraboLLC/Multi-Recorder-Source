//
//  NSDate+Unix_Timestamp_Tools.h
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/13/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Extends NSDate to include functions for obtaining the unix time.
 
 Includes unixTimestampString and unixTimestampNumber as two options for obtaining the unix time either as an NSString or as an NSNumber.
 */
@interface NSDate (Date_Utilities)

+(NSString *)currentUnixTimestampString;
+(NSNumber *)currentUnixTimestampNumber;

-(BOOL)isSameDayAsDate:(NSDate*)date;

@end
