//
//  STRCaptureDataCollector.m
//  Toast
//
//  Created by Thomas Beatty on 6/28/12.
//  Copyright (c) 2012 Strabo. All rights reserved.
//

#import "STRCaptureDataCollector.h"

@interface STRCaptureDataCollector (AVCaptureFileOutputRecordingDelegate) <AVCaptureFileOutputRecordingDelegate>

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error;
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections;

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
-(NSString *)imageTempFilePath;
-(AVCaptureConnection *)videoConnection;
+(AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;

@end

@implementation STRCaptureDataCollector

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
    // Set the video orientation
    [[self videoConnection] setVideoOrientation:deviceOrientation];
    // Remove the old temp file
    [[NSFileManager defaultManager] removeItemAtURL:[self videoTempFileURL] error:nil];
    // Start recording to the movie file output
    [[self movieFileOutput] startRecordingToOutputFileURL:[self videoTempFileURL] recordingDelegate:self];
}

-(void)stopCapturingVideo {
    [[self movieFileOutput] stopRecording];
}

-(void)captureStillImageWithOrientation:(UIDeviceOrientation)deviceOrientation {

    // Get the video connection
    // An active connection must be returned for still image capture
    AVCaptureConnection * videoConnection;
	for (AVCaptureConnection *connection in [_imageFileOutput connections]) {
		for (AVCaptureInputPort *port in [connection inputPorts]) {
			if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) {
            break;
        }
	}
    
    // Set the orientation
    [videoConnection setVideoOrientation:deviceOrientation];
    
    // Capture the image
	[_imageFileOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                  completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
                                                      
                                                      NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                                                      UIImage * image = [[UIImage alloc] initWithData:imageData];
                                                      // Rotate the image here if appropriate
                                                      
                                                      if ([UIImageJPEGRepresentation(image, 1.0) writeToFile:[self imageTempFilePath] atomically:YES]) {
                                                          [_delegate stillImageWasCaptured];
                                                      }
                                                  }];
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

-(NSString *)imageTempFilePath {
    NSString * outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.jpg"];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath]) {
        [fileManager removeItemAtPath:outputPath error:nil];
    }
    return outputPath;
}

-(AVCaptureConnection *)videoConnection {
    // Find and set the video connection
    AVCaptureConnection * newConnection = [STRCaptureDataCollector connectionWithMediaType:AVMediaTypeVideo fromConnections:[_movieFileOutput connections]];
    return newConnection;
}

+(AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections {
	for ( AVCaptureConnection *connection in connections ) {
		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:mediaType] ) {
				return connection;
			}
		}
	}
	return nil;
}

@end

@implementation STRCaptureDataCollector (AVCaptureFileOutputRecordingDelegate)

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    if (error) {
        NSLog(@"STRCaptureDataCollector: An error occurred while ending the video recording: %@", error);
    } else {
        [_delegate videoRecordingDidEnd];
    }
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    [_delegate videoRecordingDidBegin];
}

@end
