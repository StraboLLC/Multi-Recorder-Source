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
 You should implement the STRCaptureUploadManagerDelegate to receive notifications when important things happen before, during, and after file uploading. The methods in this protocol will help you handle an upload and alert the user about upload progress, failure, or success.
 
 Method Implementation
 ---------------------
 
 All of the methods in this protocol are optional, but it will be important to implement most if not all of them for proper handling of the upload.
 */
@protocol STRCaptureUploadManagerDelegate

@optional

/**
 Called whenever the upload sends a packet of data to the server from the current connection.
 
 This method is called periodically throughout an upload. It estimates the progress of the upload based on the total size of the request and the data sent thus far. It should be noted that this is only an estimate and does not reflect the true upload progress. It is possible, for example, for a progress value to be less than the previous progress value reported.
 
 Once the upload has been completed, the progress is reported as 1.0. An upload will never complete without first reporting complete upload progress.
 
 @param progress Progress is reported out of a total 1.0. The value should be less than 1 until it is predicted that the upload has been completed.
 */
-(void)fileUploadDidProgress:(NSNumber *)progress;

/**
 Called after the post request is built and the connection to the server has started.
 */
-(void)fileUploadDidStart;

/**
 Called if there was a problem starting the upload connection.
 
 This method is called either if the capture that was passed to the server was invalid or if the connection to the server failed.
 */
-(void)fileUploadFailedToStart;

/**
 Reports that the upload of the capture has completed and that the server responded successfully.
 
 @param token The token associated with the track. You should handle the token appropriately, as described in the [Working With The SDK](WorkingWithTheSDK) guide. 
 */
-(void)fileUploadedSuccessfullyWithToken:(NSString *)token;

/**
 Called when the capture upload was cancelled by a method call to [cancelCurrentUpload]([STRCaptureUploadManager cancelCurrentUpload]).
 */
-(void)fileUploadDidStop;

/**
 Reports that the capture was not able to be successfully uploaded.
 */
-(void)fileUploadDidFailWithError:(NSError *)error;

@end

/**
 An object to help you manage file uploads to the Strabo servers.
 
 For a more detailed tutorial about uploading captures and handling upload information, see also the [Working with the SDK](WorkingWithTheSDK) reference.
 
 To upload a capture, create a new instance of a STRCaptureUploadManager by using the defaultManager class method:
 
    STRCaptureUploadManager * captureUploadManager = [STRCaptureUploadManager defaultManager];
 
 Pass a [STRCapture] object to the beginUploadForCapture: method and the STRCaptureUploadManager will handle the rest of the steps necessary to finish the upload to the Strabo servers.
 
 To cancel and upload in progress, call the cancelCurrentUpload method. 
 
 Although all of the [STRCaptureUploadManagerDelegate] methods are optional, it is HIGHLY RECOMMENDED that the object that implements a STRCaptureUploadManager also conform to the [STRCaptureUploadManagerDelegate]. The the associated documentation or the [Working with the SDK](WorkingWithTheSDK) guide for more information.
 */
@interface STRCaptureUploadManager : NSObject {
    id _delegate;
    
    NSURLConnection * currentConnection;
    NSURLRequest * currentRequest;
    NSMutableData * receivedData;
}

/**
 Returns the delegate for the receiver. Must implement [STRCaptureUploadManagerDelegate].
 */
@property(strong)id delegate;

/**
 Creates and returns a new STRCaptureUploadManager
 
 @return STRCaptureUploadManager A new instance of a STRCaptureUploadManager. Have fun with it.
 */
+(STRCaptureUploadManager *)defaultManager;

/**
 Builds a POST request and then begins to send it asynchronously to the server.
 
 Discovers all of the associated files for a capture and uploads them to the server. Because the request is asynchronous, the POST request is sent and then [delegate](STRCaptureUploadManager) methods are called as the upload progress and status changes.
 */
-(void)beginUploadForCapture:(STRCapture *)capture;

/**
 Cancels the current upload. 
 
 This method will call the delegate method [fileUploadDidStop]([STRCaptureUploadManagerDelegate fileUploadDidStop]) once the cancellation is complete.
 */
-(void)cancelCurrentUpload;

@end
