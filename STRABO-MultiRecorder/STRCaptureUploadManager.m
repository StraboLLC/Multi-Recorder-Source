//
//  STRCaptureUploadManager.m
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/19/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import "STRCaptureUploadManager.h"

static NSString * const kSTRServerURL = @"http://willpotter.local:3000/api/upload";

@interface STRCaptureUploadManager (NSURLConnectionDelegate) <NSURLConnectionDelegate>
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
-(void)connectionDidFinishLoading:(NSURLConnection *)connection;
-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
@end

@interface STRCaptureUploadManager (InternalMethods)

-(BOOL)generateUploadRequestForCapture:(STRCapture *)capture;
-(void)startCurrentUpload;
-(void)handleResponse:(NSData *)responseJSONdata;

// Utility Methods
-(NSString *)capturesDirectoryPath;

@end

@implementation STRCaptureUploadManager

-(void)beginUploadForCapture:(STRCapture *)capture {
    if ([self generateUploadRequestForCapture:capture]) {
        [self startCurrentUpload];
    } else {
        if ([_delegate respondsToSelector:@selector(fileUploadFailedToStart)]) {
            [_delegate fileUploadFailedToStart];
        }
    }
}

-(void)cancelCurrentUpload {
    
}

@end

@implementation STRCaptureUploadManager (InternalMethods)

-(BOOL)generateUploadRequestForCapture:(STRCapture *)capture {
    // Generate the file paths to upload
    NSString * thumbnailPath = [self.capturesDirectoryPath stringByAppendingPathComponent:capture.thumbnailPath];
    NSString * mediaPath = [self.capturesDirectoryPath stringByAppendingPathComponent:capture.mediaPath];
    NSString * geoDataPath = [self.capturesDirectoryPath stringByAppendingPathComponent:capture.geoDataPath];
    NSString * captureInfoPath = [self.capturesDirectoryPath stringByAppendingPathComponent:capture.captureInfoPath];
    
    // Make sure that all files to upload actually exist
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:mediaPath] || ![fileManager fileExistsAtPath:geoDataPath] || ![fileManager fileExistsAtPath:thumbnailPath] || ![fileManager fileExistsAtPath:captureInfoPath]) {
        NSLog(@"STRCaptureUploadManager: Files not found while generating request.");
    return NO;
    }
    
    // Create the request
    NSMutableURLRequest * postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kSTRServerURL]];
    [postRequest setHTTPMethod:@"POST"];
    
    // Set request constants
    NSString * stringBoundary = @"0xKhTmLbOuNdArY";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",stringBoundary];
    
    // Build the request
    [postRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];
    NSMutableData *postBody = [NSMutableData data];
    // Build the 
    [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"media_file\"; filename=\"%@.%@\"\r\n", mediaPath, mediaPath.pathExtension] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[NSData dataWithContentsOfFile:mediaPath]];
    [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"media_file\"; filename=\"%@.%@\"\r\n", mediaPath, mediaPath.pathExtension] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[NSData dataWithContentsOfFile:mediaPath]];
    [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"media_file\"; filename=\"%@.%@\"\r\n", mediaPath, mediaPath.pathExtension] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[NSData dataWithContentsOfFile:mediaPath]];
    [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"media_file\"; filename=\"%@.%@\"\r\n", mediaPath, mediaPath.pathExtension] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[NSData dataWithContentsOfFile:mediaPath]];
    
    // Add the post body to the request
    [postRequest setHTTPBody:postBody];
    
    currentRequest = postRequest;
    
    return YES;
}

-(void)startCurrentUpload {
    currentConnection = [[NSURLConnection alloc] initWithRequest:currentRequest delegate:self];
    
    currentRequest = nil;
    
    // Get ready to receive data
    receivedData = [[NSMutableData data] init];
    
    // Fire up the connection
    if (currentConnection) {
        [currentConnection start];
        if ([_delegate respondsToSelector:@selector(fileUploadDidStart)]) {
            [_delegate fileUploadDidStart];
        }
    } else {
        NSLog(@"STRCaptureUploadManager: Error initiating connection. Alerting delegate.");
        if ([_delegate respondsToSelector:@selector(fileUploadFailedToStart)]) {
            [_delegate fileUploadFailedToStart];
        }
    }
            
}

-(void)handleResponse:(NSData *)responseJSONdata {
    
}

#pragma mark - Utility Methods

-(NSString *)capturesDirectoryPath {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/StraboCaptures"];
}

@end

@implementation STRCaptureUploadManager (NSURLConnectionDelegate)

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // Reset the received data
    [receivedData setLength:0];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to receivedData
    [receivedData appendData:data];
    NSLog(@"Upload connection received partial response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"STRCaptureUploadManager: Connection failed - authentication challenge received.");
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // Notify the delegate of an error
    
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Make sure that the delegate is informed of 100% progress
    
    // Handle the data response internally
    // Check for errors from the server
    NSData * data = [NSData dataWithData:receivedData];
    [self handleResponse:data];
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    // Notify the delegate that uploading progress has been made
    if ([_delegate respondsToSelector:@selector(fileUploadDidProgress:)]) {
        [_delegate fileUploadDidProgress:@((double)totalBytesWritten/(double)totalBytesExpectedToWrite)];
    }
}

@end
