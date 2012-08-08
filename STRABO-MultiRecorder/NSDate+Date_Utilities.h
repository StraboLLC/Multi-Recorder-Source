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

/**
 Generates the current unix time and returns a string value.
 
 @return NSString A string representation of the current unix time.
 */
+(NSString *)currentUnixTimestampString;

/**
 Generates the curent unix time and returns a numerical value.
 
 @return NSNumber A numerical representation of the current unix time.
 */
+(NSNumber *)currentUnixTimestampNumber;

/**
 Compares two dates to determine if they fall on the same day.
 
 For example:
 
    NSDate * oldDate = [NSDate dateWithTimeIntervalSince1970:1];
    NSDate * dateRightNow = [NSDate Date];
    
    // Compare the two dates to see if they are on the same day
    [oldDate isSameDayAsDate:dateRightNow]; // Returns NO
 
 @param date A date for comparison.
 */
-(BOOL)isSameDayAsDate:(NSDate*)date;

@end
