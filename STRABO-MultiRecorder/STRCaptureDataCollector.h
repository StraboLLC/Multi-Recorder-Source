//
//  STRCaptureDataCollector.h
//  Toast
//
//  Created by Thomas Beatty on 6/28/12.
//  Copyright (c) 2012 Strabo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@protocol STRCaptureDataCollectorDelegate

@required

-(void)videoRecordingDidBegin;
-(void)videoRecordingDidEnd;
-(void)videoRecordingDidFailWithError:(NSError *)error;
-(void)stillImageWasCaptured;

@end

/**
 An object for recording both video and still images.
 
 Upon initialization, this object sets up a recording session with some default values. Values like the recording quality can be altered by calling methods like setCaptureQuality.
 */
@interface STRCaptureDataCollector : NSObject {
    id delegate;
    
    AVCaptureSession * session;
    AVCaptureDeviceInput * videoInput;
    AVCaptureDeviceInput * audioInput;
    AVCaptureMovieFileOutput * movieFileOutput;
    AVCaptureStillImageOutput * imageFileOutput;
}

@property(strong)id delegate;

@property(readonly)AVCaptureSession * session;
@property(readonly)AVCaptureDeviceInput * videoInput;
@property(readonly)AVCaptureDeviceInput * audioInput;
@property(readonly)AVCaptureMovieFileOutput * movieFileOutput;
@property(readonly)AVCaptureStillImageOutput * imageFileOutput;

///---------------------------------------------------------------------------------------
/// @name Settng Capture Options
///---------------------------------------------------------------------------------------

/**
 Resets the [AVCaptureSession sessionPreset] to the desired value.
 
 @param captureSessionQualityPreset The preset recording quality value. The default value is [AVCaptureSessionPresetHigh].
 */
-(void)setCaptureQuality:(NSString *)captureSessionQualityPreset;

///---------------------------------------------------------------------------------------
/// @name Recording Audio and Video
///---------------------------------------------------------------------------------------

/**
 
 */
-(void)startCapturingVideoWithOrientation:(AVCaptureVideoOrientation)deviceOrientation;
-(void)stopCapturingVideo;
-(void)captureStillImage;

@end
