//
//  Capture.m
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/12/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import "STRCapture.h"

@interface STRCapture ()

// Make readonly properties writable internally
@property(readwrite)NSDate * creationDate;
@property(readwrite)NSNumber * latitude;
@property(readwrite)NSNumber * longitude;

@property(readwrite)NSURL * geoDataURL;
@property(readwrite)NSURL * mediaURL;
@property(readwrite)NSURL * thumbnailURL;

@property(readwrite)NSString * token;
@property(readwrite)NSString * type;

@end

@interface STRCapture (InternalMethods)
-(NSString *)straboCaptureDirectoryPath;
@end

@implementation STRCapture

#pragma mark - Class Methods

+(STRCapture *)captureFromFilesAtDirectory:(NSString *)captureDirectory {
    
    STRCapture * newCapture = [[STRCapture alloc] init];
    
    // Read the appropriate file into a dictionary
    NSError * error;
    NSDictionary * captureDictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[newCapture.straboCaptureDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/capture-info.json", captureDirectory]]] options:nil error:&error];
    if (error) return nil;
    
    // Build up the newCapture object
    
    return newCapture;
}

-(void)save {
    
}

@end

@implementation STRCapture (InternalMethods)

-(NSString *)straboCaptureDirectoryPath {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/StraboCaptures"];
}

@end
