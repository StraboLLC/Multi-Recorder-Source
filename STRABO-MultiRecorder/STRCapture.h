//
//  Capture.h
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/12/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

/**
 Holds all of the information about a capture taken with the Strabo MultiRecorder.
 
 Creating a Capture object
 -------------------------
 
 Editing a Capture object
 ------------------------
 */
@interface STRCapture : NSObject {
    NSString * _captureInfoPath;
    NSDate * _creationDate;
    NSString * _geoDataPath;
    NSNumber * _heading;
    NSNumber * _latitude;
    NSNumber * _longitude;
    NSString * _mediaPath;
    NSString * _thumbnailPath;
    NSString * _title;
    NSString * _token;
    NSString * _type;
    NSDate * _uploadDate;
    UIImage * _thumbnailIamge;
}

/**
 A UIImage representation of the associated thumbnail image.
 */
@property(readonly)UIImage * thumbnailImage;

/**
 Date when the capture was first taken.
 */
@property(readonly)NSDate * creationDate;

///---------------------------------------------------------------------------------------
/// @name Geodata
///---------------------------------------------------------------------------------------

/**
 Initial heading of the capture.
 
 @warning This value might not equate exactly to the first point in the geo-data file.
 */
@property(readonly)NSNumber * heading;

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
 
 Notice that the capture directory is not the absolute path to the directory, but is rather the name of the directory containing the capture media files relative to the "StraboCaptures" directory. ~~For example, under the naming scheme as of July, 2012, the capture directory could be something like: @"1342193443".~~ For example under the naming scheme as of August, 2012, the capture directory could be something like "
 
 @param captureDirectory The name of the directory containing the capture media files.
 */
+(STRCapture *)captureFromFilesAtDirectory:(NSString *)captureDirectory;

/**
 Retrieves the locally stored capture with the specified token and returns a STRCapture object representing the capture.
 
 @param token The token for the capture that you wish to retrieve.
 
 @return STRCapture A new instance of a STRCapture object defined by the specified token.
 */
+(STRCapture *)captureWithToken:(NSString *)token;

///---------------------------------------------------------------------------------------
/// @name Utility Methods
///---------------------------------------------------------------------------------------

/**
 An easy to check to see if a capture has been uploaded.
 
 For more detailed information, check the uploadDate property. This property will return nil if the file has not been uploaded. It should also give you a more precise date about when the file was uploaded.
 
 @return BOOL Returns YES if the capture has been previously uploaded and NO if it has not.
 */
-(BOOL)hasBeenUploaded;

///---------------------------------------------------------------------------------------
/// @name Geo Data Methods
///---------------------------------------------------------------------------------------

/**
 Returns a CLLocation object containing the initial latitude and longtiude values of the capture.
 
 This method is helpful when dealing with maps and other iOS SDK classes that deal directly with CLLocation objects. Instead of working with a capture's latitude and longitude properties, you can access the initial location of the capture via this initialLocation method. Note that the CLLocation object returned by this method has nil attributes `altitude`, `horizontalAccuracy`, `verticalAccuracy` and `timestamp`. You should use the value returned to determine a 2D position in space only.
 
 @return CLLocaiton The initial location of the capture.
 */
-(CLLocation *)initialLocation;

/**
 Gets an array of the timestamps that correspond to the geodata points associated with this track.
 
 Generates an array of timestamps from the geodata associated with the track. Each timestamp corresponds to a bundle of geodata information that was recorded at that time relative to the start of a capture's recording.
 
 @return NSArray An array of NSValue objects containing CMTime values, each of which represents a capture timestamp.
 
 Returns nil in the event of an error.
 */
-(NSArray *)geoDataPointTimestamps;

/**
 Generates a dictionary of points information with timestamps as keys and geodata objects.
 
 The returned dictionary contains keys of the same values as returned by geoDataPointTimestamps. These keys correspond to NSArray objects. The first element of the array object is a CLLocation. The second array element is a heading, represented by an NSNumber. This method essentially builds an object from the [geodata file](UnderlyingMechanics) that you can handle easily.
 
 @return NSDictionary A dictionary of key-value pairs that correspond to geodata points collected during a capture. The keys correspond to timestamps and the values are arrays containing CLLocations at index 0 and NSNumber headings at index 1.
 
 Returns nil in the event of an error.
 */
-(NSDictionary *)geoDataPoints;

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
