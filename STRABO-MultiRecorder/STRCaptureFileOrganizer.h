//
//  STRCaptureFileOrganizer.h
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/11/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 See [STRCaptureFileManager] instead.
 
 Contains the logic for saving temporary capture files to the application documents directory.
 
 This class is used by the STRCaptureViewController to move files to the appropriate locations after a capture has been completed. It also contains some file management helper methods for use with handling strabo captures. 
 
 @warning It should not be necessary to use an instance of this class when implementing the Strabo MultiRecorder SDK. Please see [STRCaptureFileManager] instead.
 */
@interface STRCaptureFileOrganizer : NSObject

/**
 Relocates the most recently captured video files from the temp folder to the documents directory.
 */
-(void)saveTempVideoFiles;

/**
 Relocates the most recently captured image files from the temp folder to the documents directory.
 */
-(void)saveTempImageFiles;

@end
