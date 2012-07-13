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
 
 ##Creating a Capture object

 ##Editing a Capture object
 */
@interface STRCapture : NSObject {
    NSDate * creationDate;
    NSURL * geoDataURL;
    NSNumber * latitude;
    NSNumber * longitude;
    NSURL * mediaURL;
    NSURL * thumbnailURL;
    NSString * title;
    NSString * token;
    NSString * type;
    NSDate * uploadDate;
}

///---------------------------------------------------------------------------------------
/// @name Class Methods
///---------------------------------------------------------------------------------------

/**
 Returns a new STRCapture object with the files at the directory specified.
 
 Notice that the capture directory is not the absolute path to the directory, but is rather the name of the directory containing the capture media files. For example, under the naming scheme as of July, 2012, the capture directory could be something like: @"1342193443".
 
 @param captureDirectory The name of the directory containing the capture media files.
 */
+(STRCapture *)createCaptureFromFilesAtDirectory:(NSString *)captureDirectory;

///---------------------------------------------------------------------------------------
/// @name Editing Methods
///---------------------------------------------------------------------------------------

/**
 Saves changes made to the capture object since it was created.
 */
-(void)save;

@end
