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
#import "NSString+Hash.h"

/**
 STRCaptureAttributes
 
 Used as keys in the attributes dictionary of newCaptureWithImageAtPath:attributes:
 
 See the [ConstantsReference] guide for more information.
 */
typedef NSString STRCaptureAttribute;

STRCaptureAttribute * const STRCaptureAttributeLatitude;
STRCaptureAttribute * const STRCaptureAttributeLongitude;
STRCaptureAttribute * const STRCaptureAttributeHeading;
STRCaptureAttribute * const STRCaptureAttributeDate;
STRCaptureAttribute * const STRCaptureAttributeTitle;

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
/// @name Creating Captures
///---------------------------------------------------------------------------------------

/**
 Creates a capture object using the media specified.
 
 This is useful when trying to create a capture object from an image in the photo roll or with an image captured with some other application. You pass a local path pointing to the JPG image, as well as a couple of attributes, and the method builds and saves a capture object locally.
 
 The attributes dictionary contains some geodata information about the image. This is the information that is used to populate local files from which the STRCapture object is built. This dictionary has a set of predefined keys of type STRCaptureAttribute. They are outlined below:
 
 <table>
    <tr style="font-weight: bold;">
        <td>Key</td>
        <td>Associated Value Object Type</td>
        <td>Description</td>
        <td>Required Value?</td>
    </tr>
    <tr>
        <td>STRCaptureAttributeLatitude</td>
        <td>NSNumber</td>
        <td>The latitude value of the location of the image.</td>
        <td>YES</td>
    </tr>
    <tr>
        <td>STRCaptureAttributeLongitude</td>
        <td>NSNumber</td>
        <td>The longitude value of the location of the image.</td>
        <td>YES</td>
    </tr>
    <tr>
        <td>STRCaptureAttributeHeading</td>
        <td>NSNumber</td>
        <td>The heading value in degrees for the image.</td>
        <td>NO: The heading is set to 0 degrees (North) if no other heading is provided.</td>
    </tr>
    <tr>
        <td>STRCaptureAttributeDate</td>
        <td>NSDate</td>
        <td>The date that the image was taken.</td>
        <td>NO: The date is set to the current date if no other date is provided.</td>
    </tr>
    <tr>
        <td>STRCaptureAttributeTitle</td>
        <td>NSString</td>
        <td>The title of the image.</td>
        <td>NO: The title is set to "Untitled Capture" if none is provided.</td>
    </tr>
 </table>
 
 @param mediaPath The path to the image on the device.
 
 @param attributes A dictionary containing attributes associated with the image. Dictionary keys are of type STRCaptureAttribute and the associated object values are described in the table above.
 
 @return STRCapture A STRCapture object created from the new locally saved media file and associated data. Returns nil if there was an error.
 */
-(STRCapture *)newCaptureWithImageAtPath:(NSString *)mediaPath attributes:(NSDictionary *)attributes;

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
 
 @param sorted If you pass the value YES for this parameter, the captures are returned sorted by date captured with the most recent capture first. Passing nil or NO will result in possibly unsorted captures.
 
 @return NSArray An array of STRCapture objects taken on the same day of the date specified.
 */
-(NSArray *)capturesOnDate:(NSDate *)date sorted:(BOOL)sorted;

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
