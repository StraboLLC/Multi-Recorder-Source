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
    
}

///---------------------------------------------------------------------------------------
/// @name Class Methods
///---------------------------------------------------------------------------------------

/**
 
 */
+(STRCapture *)createCaptureFromFilesAtDirectory:(NSString *)captureDirectory;


@end
