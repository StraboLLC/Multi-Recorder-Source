//
//  STRCaptureDataCollector.m
//  Toast
//
//  Created by Thomas Beatty on 6/28/12.
//  Copyright (c) 2012 Strabo. All rights reserved.
//

#import "STRCaptureDataCollector.h"

@interface STRCaptureDataCollector (AVCaptureFileOutputRecordingDelegate) <AVCaptureFileOutputRecordingDelegate>
@end

@interface STRCaptureDataCollector ()

@property(readwrite)AVCaptureSession * session;
@property(readwrite)AVCaptureDeviceInput * videoInput;
@property(readwrite)AVCaptureDeviceInput * audioInput;
@property(readwrite)AVCaptureMovieFileOutput * movieFileOutput;
@property(readwrite)AVCaptureStillImageOutput * imageFileOutput;

@end

@interface STRCaptureDataCollector (InternalMethods)

-(void)configureCamera;

// Capture Devices
-(AVCaptureDevice *)cameraWithPosition: (AVCaptureDevicePosition)position;
-(AVCaptureDevice *)frontFacingCamera;
-(AVCaptureDevice *)backFacingCamera;
-(AVCaptureDevice *)audioDevice;

// Utility Methods
-(NSURL *)videoTempFileURL;
  
@end

@implementation STRCaptureDataCollector

@synthesize delegate = _delegate;
@synthesize session = _session;
@synthesize videoInput = _videoInput;
@synthesize audioInput = _audioInput;
@synthesize movieFileOutput = _movieFileOutput;
@synthesize imageFileOutput = _imageFileOutput;

- (id)init
{
    self = [super init];
    if (self) {
        // Set up the object here.
        [self configureCamera];
    }
    return self;
}

#pragma mark - Setting Capture options

-(void)setCaptureQuality:(NSString *)captureSessionQualityPreset {
    _session.sessionPreset = captureSessionQualityPreset;
}

#pragma mark - Recording Audio and Video

-(void)startCapturingVideoWithOrientation:(AVCaptureVideoOrientation)deviceOrientation {
    
    [[NSFileManager defaultManager] removeItemAtURL:[self videoTempFileURL] error:nil];
    
    [[self movieFileOutput] startRecordingToOutputFileURL:[self videoTempFileURL] recordingDelegate:self];
    [_delegate videoRecordingDidBegin];
}

-(void)stopCapturingVideo {
    [[self movieFileOutput] stopRecording];
    [_delegate videoRecordingDidEnd];
}

-(void)captureStillImage {
    
}

@end

@implementation STRCaptureDataCollector (InternalMethods)

-(void)configureCamera {
    
    // Init all instance variables
    _session = [[AVCaptureSession alloc] init];
    _audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self audioDevice] error:nil];
    _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backFacingCamera] error:nil];
    _movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    _imageFileOutput = [[AVCaptureStillImageOutput alloc] init];
    
    // Set up the session with the inputs
    [_session beginConfiguration];
    if ([_session canAddInput:_audioInput]) {
        [_session addInput:_audioInput];
    }
    if ([_session canAddInput:_videoInput]) {
        [_session addInput:_videoInput];
    }
    if ([_session canAddOutput:_movieFileOutput]) {
        [_session addOutput:_movieFileOutput];
    }
    if ([_session canAddOutput:_imageFileOutput]) {
        [_session addOutput:_imageFileOutput];
    }
    [_session commitConfiguration];
    
    // Set the video quality.
    [self setCaptureQuality:AVCaptureSessionPreset640x480];
    
    if (![_session isRunning]) {
        [_session startRunning];
        NSLog(@"STRCaptureDataCollector: Session successfully started.");
    }
}

#pragma mark - Capture Devices

-(AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

-(AVCaptureDevice *)frontFacingCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

-(AVCaptureDevice *)backFacingCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

-(AVCaptureDevice *)audioDevice {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if ([devices count] > 0) {
        return [devices objectAtIndex:0];
    }
    return nil;
}

#pragma mark - Utility Methods

-(NSURL *)videoTempFileURL {
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath]) {
        [fileManager removeItemAtPath:outputPath error:nil];
    }
    return outputURL;
}

@end
