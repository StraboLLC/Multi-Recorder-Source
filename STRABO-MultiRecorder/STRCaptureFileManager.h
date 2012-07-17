//
//  STRCaptureFileManager.h
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/9/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STRCapture.h"

// Tools
#import "NSDate+Date_Utilities.h"

/**
 You should use an STRCaptureFileManager to access files stored on the device. This class provides methods for deleting, searching, and manipulating Strabo captures.
 
 Create a new STRCaptureFileManager by using the class method defaultManager to ensure the proper default setup of the object.
 */
@interface STRCaptureFileManager : NSObject {
    NSFileManager * fileManager;
}

///---------------------------------------------------------------------------------------
/// @name Class Methods
///---------------------------------------------------------------------------------------

/**
 Creates an instance of a STRCaptureFileManager.
 
 @return STRCaptureFileManager A capture file manager set up with default filemanagers, etc.
 */
+(STRCaptureFileManager *)defaultManager;

///---------------------------------------------------------------------------------------
/// @name Getting Local Captures
///---------------------------------------------------------------------------------------

/**
 Searches for all of the captures that exist on the device.
 
 @param sorted If you pass the parameter YES, the captures are returned sorted by date captured with the most recent first.
 
 @return NSArray An array of STRCapture objects, all of which represent existing captures on the device.
 */
-(NSArray *)allCapturesSorted:(BOOL)sorted;

-(NSArray *)recentCapturesWithLimit:(NSNumber *)limit;
-(NSArray *)capturesOnDate:(NSDate *)date;
-(NSNumber *)localCaptureCount;

///---------------------------------------------------------------------------------------
/// @name Deleting Captures
///---------------------------------------------------------------------------------------

-(BOOL)deleteCapture:(STRCapture *)capture;
-(BOOL)deleteCaptureWithToken:(NSString *)capture;

@end
