//
//  STRCaptureFileOrganizer.m
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/11/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import "STRCaptureFileOrganizer.h"

@interface STRCaptureFileOrganizer (InternalMethods)

-(NSString *)randomFileName;
-(NSString *)docsDirectoryPath;

-(void)generateThumbnailForTemporaryImage;
-(void)generateThumbnailForTemporaryVideo;

@end

@implementation STRCaptureFileOrganizer

-(void)saveTempImageFiles {
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString * newDirectoryPath = [[self docsDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]]];
    
    // Make the new directory
    [fileManager createDirectoryAtPath:newDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Temp paths
    NSString * mediaTempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.jpg"];
    NSString * geoDataTempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.json"];
    // New paths
    NSString * mediaNewPath = [newDirectoryPath stringByAppendingPathComponent:[[self randomFileName] stringByAppendingPathExtension:@".png"]];
    NSString * geoDataNewPath = [newDirectoryPath stringByAppendingPathComponent:[[self randomFileName] stringByAppendingPathExtension:@".json"]];
    
    // Copy the files from temp to new
    [fileManager copyItemAtPath:mediaTempPath toPath:mediaNewPath error:nil];
    [fileManager copyItemAtPath:geoDataTempPath toPath:geoDataNewPath error:nil];
}

-(void)saveTempVideoFiles {
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString * newDirectoryPath = [[self docsDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]]];
    
    // Make the new directory
    [fileManager createDirectoryAtPath:newDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Temp paths
    NSString * mediaTempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.mov"];
    NSString * geoDataTempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.json"];
    // New paths
    NSString * mediaNewPath = [newDirectoryPath stringByAppendingPathComponent:[[self randomFileName] stringByAppendingPathExtension:@".mov"]];
    NSString * geoDataNewPath = [newDirectoryPath stringByAppendingPathComponent:[[self randomFileName] stringByAppendingPathExtension:@".json"]];
    
    // Copy the files from temp to new
    [fileManager copyItemAtPath:mediaTempPath toPath:mediaNewPath error:nil];
    [fileManager copyItemAtPath:geoDataTempPath toPath:geoDataNewPath error:nil];
}

@end

@implementation STRCaptureFileOrganizer (InternalMethods)

-(NSString *)randomFileName {
    return [NSString stringWithFormat:@"%@-%f", [[NSUUID UUID] UUIDString], [[NSDate date] timeIntervalSince1970]];
}

-(NSString *)docsDirectoryPath {
    
    NSString * docPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/StraboCaptures"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:docPath isDirectory:YES]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:docPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return docPath;
    
}

-(void)generateThumbnailForTemporaryImage {
    
}

-(void)generateThumbnailForTemporaryVideo {
    
}

@end
