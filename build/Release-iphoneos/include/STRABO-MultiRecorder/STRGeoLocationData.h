//
//  STRGeoLocationData.h
//  Toast
//
//  Created by Thomas Beatty on 6/28/12.
//  Copyright (c) 2012 Strabo. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Holds the geo-location data recorded by a capture.
 
 Using one of these objects is a convenient way to store a series of geo-data points associated with any type of capture supported by Strabo.
 
 @warning When implementing the basic functions of the SDK, you should not need to create a STRCaptureDataCollector instance directly. This object is used by a STRCaptureViewController to handle the recording of geodata.s
 */
@interface STRGeoLocationData : NSObject {
    id delegate;
    NSMutableArray * dataPoints;
}

/**
 Add a datapoint to the list of points.
 
 @param latitude The latitude double value.
 
 @param longitude The longitude double value.
 
 @param heading The 360 degree heading double value.
 
 @param timestamp The timestamp double value. This value should be used to tag the data point with a video scrub timestamp or an audio timestamp. Pass 0 if the timestamp field is not applicable.
 
 @param accuracy The accuracy of the datapoint, in meters.
 */
-(void)addDataPointWithLatitude:(double)latitude longitude:(double)longitude heading:(double)heading timestamp:(double)timestamp accuracy:(double)accuracy;

/**
 Returns an array of points. 
 
 The points are in dictionary format and can easily be written to JSON. The array returned is in the following format where {} designate dictionary objects:
 
    [
        {
            "coords":[(double)latitude, (double)longitude],
            "heading": (double)heading,
            "accurady": (double)accuracy,
            "timestamp": (double)timestamp
        },
        {
            "coords":[(double)latitude, (double)longitude],
            "heading": (double)heading,
            "accurady": (double)accuracy,
            "timestamp": (double)timestamp
        }
    ]
 
 */
-(NSArray *)dataPointList;

/**
 Write the collected data points to a temporary file in the tmp directory.
 
 The name of this file will be output.JSON
 */
-(void)writeDataPointsToTempFile;

@end
