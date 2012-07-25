//
//  STRCaptureFileOrganizer.h
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/11/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>

// Tools
#import "NSDate+Date_Utilities.h"
#import "NSString+Hash.h"

// The size of the thumbnail output

/**
 See also [STRCaptureFileManager].
 
 Contains the logic for saving temporary capture files to the application documents directory.
 
 This class is used by the STRCaptureViewController to move files to the appropriate locations after a capture has been completed. It also contains some file management helper methods for use with handling strabo captures. 
 
 @warning It should not be necessary to use an instance of this class when implementing the Strabo MultiRecorder SDK. Please see [STRCaptureFileManager] instead.
 */
@interface STRCaptureFileOrganizer : NSObject

/**
 Relocates the most recently captured video files from the temp folder to the documents directory.
 
 In the process of relocating the track files, this method creates a new file, capture-info.json, to store related information about the track. This method uses the parameter, location, to store the location of the track in this file.
 
 @param location The location for the track.
 */
-(void)saveTempVideoFilesWithInitialLocation:(CLLocation *)location heading:(CLHeading *)heading;

/**
 Relocates the most recently captured image files from the temp folder to the documents directory.
 
 @param location The location to record in the capture info file for the track.
 */
-(void)saveTempImageFilesWithInitialLocation:(CLLocation *)location heading:(CLHeading *)heading;

@end
