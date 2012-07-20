//
//  Capture.h
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/12/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Holds all of the information about a capture taken with the Strabo MultiRecorder.
 
 Creating a Capture object
 -------------------------
 
 Editing a Capture object
 ------------------------
 */
@interface STRCapture : NSObject {
    NSString * captureInfoPath;
    NSDate * creationDate;
    NSString * geoDataPath;
    NSNumber * latitude;
    NSNumber * longitude;
    NSString * mediaPath;
    NSString * thumbnailPath;
    NSString * title;
    NSString * token;
    NSString * type;
    NSDate * uploadDate;
}

///---------------------------------------------------------------------------------------
/// @name Geodata
///---------------------------------------------------------------------------------------

/**
 Date when the capture was first taken.
 */
@property(readonly)NSDate * creationDate;

/**
 Initial latitude of the capture.
 
 @warning This value might not equate exactly to the first point in the geo-data file.
 */
@property(readonly)NSNumber * latitude;

/**
 Initial longitude of the capture.
 
 @warning This value might not equate exactly to the first point in the geo-data file.
 */
@property(readonly)NSNumber * longitude;

///---------------------------------------------------------------------------------------
/// @name Associated Files
///---------------------------------------------------------------------------------------

/**
 Path of the geo data file associated with this capture relative to the strabo captures directory.
 */
@property(readonly)NSString * geoDataPath;

/**
 Path of the media file associated with this capture relative to the strabo captures directory.
 
 The media file could either be a video (mov) or an image (jpg) file.
 */
@property(readonly)NSString * mediaPath;

/**
 Path of the thumbnail image that represents this capture relative to the strabo captures directory.
 
 It is always a small JPG image file.
 */
@property(readonly)NSString * thumbnailPath;

/**
 Path of the JSON file that holds the information about the capture.
 
 The path is always relative to the strabo captures directory. The file type is JSON.
 */
@property(readonly)NSString * captureInfoPath;

///---------------------------------------------------------------------------------------
/// @name Capture Info
///---------------------------------------------------------------------------------------

/**
 Unique token that represents the track.
 
 The token is generated from a combination of an identifier unique to each application installation and the date, so it is unique to each capture.
 */
@property(readonly)NSString * token;

/**
 Specifies the capture type: either video or image.
 
 A string with value either @"video" or @"image".
 */
@property(readonly)NSString * type;

///---------------------------------------------------------------------------------------
/// @name Readwrite Properties
///---------------------------------------------------------------------------------------

/**
 The title of the track, which can be defined by the user.
 
 "Untitled Capture" is the default value for this property. If you wish to reset the title of a capture, change this property and then commit your changes by calling the save method.
 */
@property(nonatomic, strong)NSString * title;

/**
 The date that the track was uploaded.
 
 Set to nil by default, but can be changed so that you can keep track of if and when tracks are uploaded to the server. Set this property and then use the save method to commit your changes.
 */
@property(nonatomic, strong)NSDate * uploadDate;

///---------------------------------------------------------------------------------------
/// @name Class Methods
///---------------------------------------------------------------------------------------

/**
 Returns a new STRCapture object with the files at the directory specified.
 
 Notice that the capture directory is not the absolute path to the directory, but is rather the name of the directory containing the capture media files. For example, under the naming scheme as of July, 2012, the capture directory could be something like: @"1342193443".
 
 @param captureDirectory The name of the directory containing the capture media files.
 */
+(STRCapture *)captureFromFilesAtDirectory:(NSString *)captureDirectory;

///---------------------------------------------------------------------------------------
/// @name Editing Methods
///---------------------------------------------------------------------------------------

/**
 Saves changes made to the capture object since it was created.
 
 If you want to make any changes to readwrite properties of an STRCapture object, set the values of those properties and then call this method to write those changes to the appropriate files. This will make changes to the properties persistent.
 
 @return BOOL YES if successful and NO if unsuccessful.
 */
-(BOOL)save;

@end
