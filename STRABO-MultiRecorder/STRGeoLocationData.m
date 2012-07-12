//
//  STRGeoLocationData.m
//  Toast
//
//  Created by Thomas Beatty on 6/28/12.
//  Copyright (c) 2012 Strabo. All rights reserved.
//

#import "STRGeoLocationData.h"

@interface STRGeoLocationData (InternalMathods)

-(NSString *)tempFilePath;

@end

@implementation STRGeoLocationData

-(id)init {
    if (self) {
        dataPoints = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)addDataPointWithLatitude:(double)latitude longitude:(double)longitude heading:(double)heading timestamp:(double)timestamp accuracy:(double)accuracy {
    
    NSDictionary * point = @{ @"coords" : @[ @(latitude), @(longitude) ],
                             @"heading" : @(heading),
                            @"accuracy" : @(accuracy),
                           @"timestamp" : @(timestamp)
    };

    [dataPoints addObject:point];
}

-(NSArray *)dataPointList {
    return dataPoints;
}

-(void)writeDataPointsToTempFile {
    
    NSLog(@"STRGeoLocationData: Writing data points to JSON file.");
    
    NSDictionary * points = [NSDictionary dictionaryWithObject:dataPoints forKey:@"points"];
    
    NSOutputStream * output = [NSOutputStream outputStreamToFileAtPath:[self tempFilePath] append:NO];
    [output open];
    
    [NSJSONSerialization writeJSONObject:points toStream:output options:0 error:nil];
    
    [output close];
}

@end


@implementation STRGeoLocationData (InternalMathods)

-(NSString *)tempFilePath {
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@%@", NSTemporaryDirectory(), @"output", @".json"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // Remove the old file
    if ([fileManager fileExistsAtPath:outputPath]) {
        [fileManager removeItemAtPath:outputPath error:nil];
    }
    // Create a new file
    [fileManager createFileAtPath:outputPath contents:nil attributes:nil];
    
    return outputPath;
}

@end