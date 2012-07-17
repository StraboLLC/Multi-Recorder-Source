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
-(NSString *)capturesDirectoryPath;

-(void)generateThumbnailForTemporaryImage;
-(void)generateThumbnailForTemporaryVideo;

@end

@implementation STRCaptureFileOrganizer

-(void)saveTempImageFiles {
    #warning Incomplete implementation
//    NSFileManager * fileManager = [NSFileManager defaultManager];
//    NSString * newDirectoryPath = [[self docsDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]]];
//    
//    // Make the new directory
//    [fileManager createDirectoryAtPath:newDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
//    
//    // Temp paths
//    NSString * mediaTempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.jpg"];
//    NSString * geoDataTempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.json"];
//    // New paths
//    NSString * mediaNewPath = [newDirectoryPath stringByAppendingPathComponent:[[self randomFileName] stringByAppendingPathExtension:@".png"]];
//    NSString * geoDataNewPath = [newDirectoryPath stringByAppendingPathComponent:[[self randomFileName] stringByAppendingPathExtension:@".json"]];
//    
//    // Copy the files from temp to new
//    [fileManager copyItemAtPath:mediaTempPath toPath:mediaNewPath error:nil];
//    [fileManager copyItemAtPath:geoDataTempPath toPath:geoDataNewPath error:nil];
}

-(void)saveTempVideoFilesWithInitialLocation:(CLLocation *)location {
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString * randomFilename = [self randomFileName];
    NSString * newDirectoryPath = [[self capturesDirectoryPath] stringByAppendingPathComponent:randomFilename];
    
    // Make the new directory
    [fileManager createDirectoryAtPath:newDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Temp paths
    NSString * mediaTempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.mov"];
    NSString * geoDataTempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.json"];
    // New paths
    NSString * mediaNewPath = [newDirectoryPath stringByAppendingPathComponent:[randomFilename stringByAppendingPathExtension:@"mov"]];
    NSString * geoDataNewPath = [newDirectoryPath stringByAppendingPathComponent:[randomFilename stringByAppendingPathExtension:@"json"]];
    NSString * captureInfoPath = [newDirectoryPath stringByAppendingPathComponent:@"capture-info.json"];
    [fileManager createFileAtPath:captureInfoPath contents:nil attributes:nil];
    
    // Save the capture info file
    // NSString * dateString = [[NSDate date] timeIntervalSince1970];
    NSDictionary * trackInfo = @{
    @"created_at" : [NSDate currentUnixTimestampNumber],
    @"geodata_file" : [randomFilename stringByAppendingPathExtension:@"json"],
    @"coords" : @[ @(location.coordinate.latitude), @(location.coordinate.longitude) ],
    @"media_file" : [randomFilename stringByAppendingPathExtension:@"mov"],
    @"thumbnail_file" : @"",
    @"title" : @"Untitled Capture",
    @"token" : randomFilename,
    @"media_type" : @"video",
    @"uploaded_at" : @0
    };
    NSOutputStream * output = [NSOutputStream outputStreamToFileAtPath:captureInfoPath append:NO];
    [output open];
    [NSJSONSerialization writeJSONObject:trackInfo toStream:output options:0 error:nil];
    [output close];
    
    // Copy the files from temp to new
    [fileManager copyItemAtPath:mediaTempPath toPath:mediaNewPath error:nil];
    [fileManager copyItemAtPath:geoDataTempPath toPath:geoDataNewPath error:nil];
}

@end

@implementation STRCaptureFileOrganizer (InternalMethods)

#define kSTRUniqueIdentifierKey @"kSTRUniqueIdentifierKey"

-(NSString *)randomFileName {
    
    // Get UUID
    NSString * uniqueIdentifier;
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    // Generate a new identifier if one does not already exist
    if (![userDefaults objectForKey:kSTRUniqueIdentifierKey]) {
        
        [userDefaults setObject:[[NSUUID UUID] UUIDString] forKey:kSTRUniqueIdentifierKey];
        [userDefaults synchronize];
    }
    uniqueIdentifier = [userDefaults objectForKey:kSTRUniqueIdentifierKey];
    NSString * fileName = [NSString stringWithFormat:@"%@-%d", uniqueIdentifier, (int)[[NSDate date] timeIntervalSince1970]];
    return [fileName MD5];
}

-(NSString *)capturesDirectoryPath {
    
    NSString * docPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/StraboCaptures"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:docPath isDirectory:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:docPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return docPath;
    
}

-(void)generateThumbnailForTemporaryImage {
    
}

-(void)generateThumbnailForTemporaryVideo {
    
}

@end
