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

/**
 Protocol required to be implemented by the delegate object of a [STRCaptureDataCollector].
 
 This protocol allows the STRCaptureDataCollector to notify its delegate object about important recording events, both for image and video recording. This allows the coordination of other data-capture objects in the Strabo Multi-Recorder SDK.
 
 @warning When implementing the basic functions of the SDK, you should not need to create a STRCaptureDataCollector instance directly. This object is used by a STRCaptureViewController to handle video, audio, and image recording.
 */
@protocol STRCaptureDataCollectorDelegate

@required

-(void)videoRecordingDidBegin;
-(void)videoRecordingDidEnd;
-(void)videoRecordingDidFailWithError:(NSError *)error;
-(void)stillImageWasCaptured;

@end

/**
 An object for recording both video and still images.
 
 Upon initialization, this object sets up a recording session with some default values. The recording quality can be set with setCaptureQuality:.
 */
@interface STRCaptureDataCollector : NSObject {
    id _delegate;
    
    AVCaptureSession * _session;
    AVCaptureDeviceInput * _videoInput;
    AVCaptureDeviceInput * _audioInput;
    AVCaptureMovieFileOutput * _movieFileOutput;
    AVCaptureStillImageOutput * _imageFileOutput;
}

/**
 The delegate for the STRCaptureDataCollector object.
 
 The delgate object should implement the [STRCaptureDataCollectorDelegate] protocol.
 */
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
 Begin recording video to a temp video file with a specified orientation.
 
 @param deviceOrientation The current orientation of the device when recording commences. This determines the orientation of both the final video file as well as the thumbnail.
 
 @warning The orientation can only be an AVCaptureVideoOrientation. Device orientations like UIDeviceOrientationFaceDown are not accepted.
 */
-(void)startCapturingVideoWithOrientation:(AVCaptureVideoOrientation)deviceOrientation;

/**
 Stop recording video to the temporary output file.
 
 Should be called after startCapturingVideoWithOrientation: is called, although nothing bad will happen if you call it inadvertantly while a capture is not currently recording - no worries.
 */
-(void)stopCapturingVideo;

/**
 Take a picture and save it to an output file in the temporary directory.
 
 @param deviceOrientation The current orientation of the device when recording commences. This determines the orientation of both the final image file as well as the thumbnail.
 
 @warning The orientation can only be an AVCaptureVideoOrientation. Device orientations like UIDeviceOrientationFaceDown are not accepted.
 */
-(void)captureStillImageWithOrientation:(UIDeviceOrientation)deviceOrientation;

@end
