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
@property(readwrite)UIImage * thumbnailImage;

@property(readwrite)NSDate * creationDate;
@property(readwrite)NSNumber * latitude;
@property(readwrite)NSNumber * longitude;

@property(readwrite)NSString * geoDataPath;
@property(readwrite)NSString * mediaPath;
@property(readwrite)NSString * thumbnailPath;
@property(readwrite)NSString * captureInfoPath;

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
    NSDictionary * captureDictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[newCapture.straboCaptureDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/capture-info.json", captureDirectory]]] options:NSJSONReadingAllowFragments error:&error];
    if (error) return nil;
    
    // Build up the newCapture object
    // Track Info
    newCapture.title = [captureDictionary objectForKey:@"title"];
    newCapture.uploadDate = [captureDictionary objectForKey:@"uploaded_at"];
    newCapture.token = [captureDictionary objectForKey:@"token"];
    newCapture.type = [captureDictionary objectForKey:@"type"];
    // Geo Data
    newCapture.creationDate = [NSDate dateWithTimeIntervalSince1970:[[captureDictionary objectForKey:@"created_at"] doubleValue]];
    newCapture.latitude = [[captureDictionary objectForKey:@"coords"] objectAtIndex:0];
    newCapture.longitude = [[captureDictionary objectForKey:@"coords"] objectAtIndex:1];
    // File Paths
    newCapture.geoDataPath = [captureDictionary objectForKey:@"geodata_file"];
    newCapture.mediaPath = [captureDictionary objectForKey:@"media_file"];
    newCapture.thumbnailPath = [captureDictionary objectForKey:@"thumbnail_file"];
    newCapture.captureInfoPath = [newCapture.token stringByAppendingPathComponent:@"capture-info.json"];
    // Images
    newCapture.thumbnailImage = [UIImage imageWithContentsOfFile:[newCapture.straboCaptureDirectoryPath stringByAppendingPathComponent:newCapture.thumbnailPath]];
    
    return newCapture;
}

-(BOOL)save {
    // Write readonly properties to the file system
    NSError * error;
    // Read the mutable dictionary from the file
    NSMutableDictionary * captureDictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[self.straboCaptureDirectoryPath stringByAppendingPathComponent:self.captureInfoPath]] options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        NSLog(@"STRCapture: There was a problem saving your changes: %@", error.description);
        return NO;
    }
    // Alter the writable entries in the dictionary
    [captureDictionary setObject:self.title forKey:@"title"];
    [captureDictionary setObject:@([self.uploadDate timeIntervalSince1970]) forKey:@"uploaded_at"];
    // Save the changes by overwriting the dictionary
    // to the capture info json file.
    NSOutputStream * JSONOutput = [NSOutputStream outputStreamToFileAtPath:[self.straboCaptureDirectoryPath stringByAppendingPathComponent:self.captureInfoPath] append:NO];
    [JSONOutput open];
    [NSJSONSerialization writeJSONObject:captureDictionary toStream:JSONOutput options:0 error:&error];
    [JSONOutput close];
    if (error) {
        NSLog(@"STRCapture: There was a problem saving your changes: %@", error.description);
        return NO;
    }
    return YES;
}

@end

@implementation STRCapture (InternalMethods)

-(NSString *)straboCaptureDirectoryPath {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/StraboCaptures"];
}

@end
