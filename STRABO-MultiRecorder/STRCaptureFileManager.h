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
    NSFileManager * _fileManager;
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

/**
 Searches for and returns the most recent captures by date.
 
 @param limit The number of recent captures to return.
 
 @return NSArray An array of STRCapture objects which represent existing local captures. The array is sorted by date with most recent first.
 */
-(NSArray *)recentCapturesWithLimit:(NSNumber *)limit;

/**
 Searches for and returns captures taken on a given date.
 
 @param date The date to match with the capture dates of the captures.
 
 @return NSArray An array of STRCapture objects taken on the same day of the date specified.
 */
-(NSArray *)capturesOnDate:(NSDate *)date;

/**
 Counts the number of local captures.
 
 @return NSNumber The number of captures stored locally.
 */
-(NSNumber *)localCaptureCount;

///---------------------------------------------------------------------------------------
/// @name Deleting Captures
///---------------------------------------------------------------------------------------

/**
 Deletes the passed capture object from the filesystem.
 
 @param capture The STRCapture object to delete from the filesystem.
 
 @return BOOL YES if successful and NO if deletion failed.
 */
-(BOOL)deleteCapture:(STRCapture *)capture;

/**
 Deletes the capture object from the filesystem specified by the passed token.
 
 @param token The STRCapture [token](STRCapture token) associated with the track to delete.
 
 @return BOOL YES if successful and NO if deletion failed.
 */
-(BOOL)deleteCaptureWithToken:(NSString *)token;

@end
