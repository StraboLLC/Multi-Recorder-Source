//
//  STRCaptureUploadManager.h
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/19/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STRCapture.h"
#import "STRCaptureFileManager.h"

/**
 You should implement the STRCaptureUploadManagerDelegate to receive notifications when im
 */
@protocol STRCaptureUploadManagerDelegate

@optional
-(void)fileUploadDidProgress:(NSNumber *)progress;
-(void)fileUploadDidStart;
-(void)fileUploadFailedToStart;
-(void)fileUploadedSuccessfullyWithToken:(NSString *)token;
-(void)fileUploadDidStop;
-(void)fileUploadDidFailWithError:(NSError *)error;

@end

/**
 An object to help you manage file uploads to the Strabo servers.
 
 ***STUB***
 */
@interface STRCaptureUploadManager : NSObject {
    id delegate;
    
    NSURLConnection * currentConnection;
    NSURLRequest * currentRequest;
    NSMutableData * receivedData;
}

/**
 Returns the delegate for the receiver. Must implement [STRCaptureUploadManagerDelegate].
 */
@property(strong)id delegate;

/**
 Builds a POST request and then begins to send it asynchronously to the server.
 
 Discovers all of the associated files for a capture and uploads them to the server. Because the request is asynchronous, the POST request is sent and then the 
 */
-(void)beginUploadForCapture:(STRCapture *)capture;

-(void)cancelCurrentUpload;

@end
