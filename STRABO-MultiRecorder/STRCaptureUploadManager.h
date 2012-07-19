//
//  STRCaptureUploadManager.h
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/19/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol STRCaptureUploadManagerDelegate

-(void)fileUploadedSuccessfullyWithToken:(NSString *)token;
-(void)fileUploadDidFailWithError:(NSError *)error;

@end

/**
 An object to help you manage file uploads to the Strabo servers.
 
 ***STUB***
 */
@interface STRCaptureUploadManager : NSObject

@end
