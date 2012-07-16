//
//  Capture.m
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/12/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import "STRCapture.h"

@interface STRCapture (InternalMethods)

-(NSString *)straboCaptureDirectoryPath;

@end

@implementation STRCapture

#pragma mark - Class Methods

+(STRCapture *)createCaptureFromFilesAtDirectory:(NSString *)captureDirectory {
    STRCapture * newCapture = [[STRCapture alloc] init];
    
    NSFileManager * fileManager = [NSFileManager defaultManager];

    
    
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
