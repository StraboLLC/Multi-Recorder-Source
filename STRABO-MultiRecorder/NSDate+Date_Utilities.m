//
//  NSDate+Unix_Timestamp_Tools.m
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/13/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import "NSDate+Date_Utilities.h"

@implementation NSDate (Date_Utilities)

#pragma mark - Class Methods

+(NSString *)currentUnixTimestampString {
    return [NSString stringWithFormat:@"%d", (int)[[NSDate date] timeIntervalSince1970]];
}

+(NSNumber *)currentUnixTimestampNumber {
    return @((int)[[NSDate date] timeIntervalSince1970]);
}

#pragma mark - Utilities

-(BOOL)isSameDayAsDate:(NSDate*)date {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:date];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:self];
    
    return [comp1 day]   == [comp2 day] &&
    [comp1 month] == [comp2 month] &&
    [comp1 year]  == [comp2 year];
}

@end
