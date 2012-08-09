//
//  STRCaptureUploadManager.m
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/19/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//
#import "STRSettings.h"

#import "STRCaptureUploadManager.h"

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

#pragma mark - Class Methods

+(STRCaptureUploadManager *)defaultManager {
    return [[STRCaptureUploadManager alloc] init];
}

#pragma mark - Instance Methods

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
    if ([_delegate respondsToSelector:@selector(fileUploadDidStop)]) {
        [_delegate fileUploadDidStop];
    }
    NSLog(@"STRCaptureUploadManager: File upload was cancelled.");
}

@end

@implementation STRCaptureUploadManager (InternalMethods)

-(BOOL)generateUploadRequestForCapture:(STRCapture *)capture {
    // Generate the file paths to upload
    NSString * thumbnailPath = [self.capturesDirectoryPath stringByAppendingPathComponent:capture.thumbnailPath];
    NSString * mediaPath = [self.capturesDirectoryPath stringByAppendingPathComponent:capture.mediaPath];
    NSString * geoDataPath = [self.capturesDirectoryPath stringByAppendingPathComponent:capture.geoDataPath];
    NSString * captureInfoPath = [self.capturesDirectoryPath stringByAppendingPathComponent:capture.captureInfoPath];
    if ([[STRSettings sharedSettings] advancedLogging]) {
        NSLog(@"Uploading file: %@", thumbnailPath);
        NSLog(@"Uploading file: %@", mediaPath);
    }
    // Make sure that all files to upload actually exist
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:mediaPath] || ![fileManager fileExistsAtPath:geoDataPath] || ![fileManager fileExistsAtPath:thumbnailPath] || ![fileManager fileExistsAtPath:captureInfoPath]) {
        NSLog(@"STRCaptureUploadManager: Files not found while generating request.");
    return NO;
    }
    
    // Create the request
    NSMutableURLRequest * postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[[STRSettings sharedSettings] uploadPath]]];
    [postRequest setHTTPMethod:@"POST"];
    
    // Set request constants
    NSString * stringBoundary = @"0xKhTmLbOuNdArY";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",stringBoundary];
    
    // Build the request
    [postRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];
    // Create the request body
    NSMutableData *postBody = [NSMutableData data];
    // Append all data to the mutable request body
    [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    // Dynamically change the post request for video or image
    if ([[STRSettings sharedSettings] advancedLogging]) NSLog(@"Uploading capture of type: %@", capture.type);
    if ([capture.type isEqualToString:@"video"]) {
        [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"media_file\"; filename=\"%@.mov\"\r\n", capture.token] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[@"Content-Type: video/quicktime\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    } else {
        [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"media_file\"; filename=\"%@.jpg\"\r\n", capture.token] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [postBody appendData:[NSData dataWithContentsOfFile:mediaPath]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    // Add the thumbnail to the request body
    [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"thumbnail\"; filename=\"%@.png\"\r\n", capture.token] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Type: image/png\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[NSData dataWithContentsOfFile:thumbnailPath]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    // Add the capture info to the request body
    [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"capture_info\"; filename=\"%@.json\"\r\n", @"capture-info"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Type: application/json\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[NSData dataWithContentsOfFile:captureInfoPath]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    // Add the geo data info to the request body
    [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"geo_data\"; filename=\"%@.json\"\r\n", capture.token] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Type: application/json\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[NSData dataWithContentsOfFile:geoDataPath]];
    // Close the request body with a boundary
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
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
    // Print out the server response for testing purposes
    if ([[STRSettings sharedSettings] advancedLogging]) {
        NSLog(@"Server Response: %@", [[NSString alloc] initWithData:responseJSONdata encoding:NSUTF8StringEncoding]);
    }
    
    // Check the server response to verify success
    NSError * error;
    NSDictionary * responseDict = [NSJSONSerialization JSONObjectWithData:responseJSONdata options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        // The response is invalid, so notify the delegate
        if ([_delegate respondsToSelector:@selector(fileUploadDidFailWithError:)]) {
            [_delegate fileUploadDidFailWithError:error];
        }
        NSLog(@"STRCaptureUploadManager: Error - The server returned an unknown response and the JSON data could not be processed: %@", error);
        return;
    }
    
    // If the server returned an error, notify the delegate
    if ([[responseDict objectForKey:@"error"] isEqualToString:@"true"]) {
        NSLog(@"STRCaptureUploadManager: Error received from server");
        NSDictionary * userInfo = @{ NSLocalizedDescriptionKey : [responseDict objectForKey:@"message"] };
        NSError * newError = [NSError errorWithDomain:nil code:0 userInfo:userInfo];
        if ([_delegate respondsToSelector:@selector(fileUploadDidFailWithError:)]) {
            [_delegate fileUploadDidFailWithError:newError];
        }
        return;
    }
    
    // At this point, everything should have gone through ok
    // Declare the file upload a success!
    // Respond by alerting the delgate if successful
    if ([_delegate respondsToSelector:@selector(fileUploadedSuccessfullyWithToken:)]) {
        [_delegate fileUploadedSuccessfullyWithToken:[responseDict objectForKey:@"token"]];
    }
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
}

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"STRCaptureUploadManager: Connection failed - authentication challenge received.");
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if ([_delegate respondsToSelector:@selector(fileUploadDidFailWithError:)]) {
        [_delegate fileUploadDidFailWithError:error];
    }
    NSLog(@"STRCaptureUploadManager: File upload failed with error: %@", error.localizedDescription);
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Make sure that the delegate is informed of 100% progress
    if ([_delegate respondsToSelector:@selector(fileUploadDidProgress:)]) {
        [_delegate fileUploadDidProgress:@1.0];
    }
    
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
