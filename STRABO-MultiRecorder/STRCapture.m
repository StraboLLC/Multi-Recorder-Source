//
//  Capture.m
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/12/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import "STRCapture.h"
#import "STRSettings.h"

@interface STRCapture () {
    BOOL _advancedLogging;
}

@property()BOOL advancedLogging;

// Make readonly properties writable internally
@property(readwrite)UIImage * thumbnailImage;
@property(readwrite)NSDate * creationDate;

#pragma mark Geodata
@property(readwrite)NSNumber * heading;
@property(readwrite)NSNumber * latitude;
@property(readwrite)NSNumber * longitude;

#pragma mark Associated Files
@property(readwrite)NSString * geoDataPath;
@property(readwrite)NSString * mediaPath;
@property(readwrite)NSString * thumbnailPath;
@property(readwrite)NSString * captureInfoPath;

#pragma mark Capture Info
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
    
    // Set the private advanced logging BOOL value
    newCapture.advancedLogging = ([[STRSettings sharedSettings] advancedLogging]) ? YES : NO;
    
    // Read the appropriate file into a dictionary
    NSError * error;
    NSDictionary * captureDictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[newCapture.straboCaptureDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/capture-info.json", captureDirectory]]] options:NSJSONReadingAllowFragments error:&error];
    if (error) return nil;
    
    // Build up the newCapture object
    // Track Info
    newCapture.title = [captureDictionary objectForKey:@"title"];
    newCapture.token = [captureDictionary objectForKey:@"token"];
    newCapture.type = [captureDictionary objectForKey:@"media_type"];
    NSDate * uploadDate = [NSDate dateWithTimeIntervalSince1970:[[captureDictionary objectForKey:@"uploaded_at"] doubleValue]];
    if ([uploadDate compare:[NSDate dateWithTimeIntervalSince1970:500]] == NSOrderedAscending) {
        newCapture.uploadDate = nil;
    } else {
        newCapture.uploadDate = uploadDate;
    }
    newCapture.creationDate = [NSDate dateWithTimeIntervalSince1970:[[captureDictionary objectForKey:@"created_at"] doubleValue]];
    // Geo Data
    newCapture.heading = [captureDictionary objectForKey:@"heading"];
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

+(STRCapture *)captureWithToken:(NSString *)token {
    // Because of the current directory naming scheme, we can just use the captureFromFilesAtDirectory method to handle this all for us.
    return [self captureFromFilesAtDirectory:token];
}

#pragma mark - Utility Methods

-(BOOL)hasBeenUploaded {
    return (self.uploadDate) ? NO : YES;
}

#pragma mark - Geo Data Methods

-(CLLocation *)initialLocation {
    CLLocation * newLocation = [[CLLocation alloc] initWithLatitude:self.latitude.doubleValue longitude:self.longitude.doubleValue];
    return newLocation;
}

-(NSArray *)geoDataPointTimestamps {
    NSString * filePath = [self.straboCaptureDirectoryPath stringByAppendingPathComponent:self.geoDataPath];
    NSError * error;
    NSArray * points = [[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:filePath] options:NSJSONReadingAllowFragments error:&error] objectForKey:@"points"];
    
    if (error) {
        if (_advancedLogging) NSLog(@"STRCapture: Error reading the geodata file. File may have been corrupted.");
        // Return nil due to error
        return nil;
    }
    
    NSMutableArray * timestamps = [[NSMutableArray alloc] initWithCapacity:points.count];
    for (NSDictionary * point in points) {
        
        CMTime timestamp = CMTimeMake(([[point objectForKey:@"timestamp"] doubleValue] * 1000000000), 1000000000);
    
        [timestamps addObject:[NSValue valueWithCMTime:timestamp]];
    }
    
    // Test code
    NSLog(@"Timestamps array produced: %@", timestamps);
    
    return timestamps;
}

-(NSDictionary *)geoDataPoints {
    NSString * filePath = [self.straboCaptureDirectoryPath stringByAppendingPathComponent:self.geoDataPath];
    NSError * error;
    NSArray * points = [[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:filePath] options:NSJSONReadingAllowFragments error:&error] objectForKey:@"points"];
    
    if (error) {
        if (_advancedLogging) NSLog(@"STRCapture: Error reading the geodata file. File may have been corrupted.");
        // Return nil due to error
        return nil;
    }
    
    NSMutableDictionary * timestamps = [[NSMutableDictionary alloc] initWithCapacity:points.count];
    for (NSDictionary * point in points) {
        CLLocation * location = [[CLLocation alloc] initWithLatitude:[[[point objectForKey:@"coords"] objectAtIndex:0] doubleValue] longitude:[[[point objectForKey:@"coords"] objectAtIndex:1] doubleValue]];
        CMTime timestamp = CMTimeMake(([[point objectForKey:@"timestamp"] doubleValue] * 1000000000), 1000000000);
        NSDictionary * tempDictionary = @{ [NSValue valueWithCMTime:timestamp] : @[ location, [point objectForKey:@"heading"] ] };
        [timestamps addEntriesFromDictionary:tempDictionary];
    }
    return timestamps;
}

#pragma mark - Editing Methods

-(BOOL)save {
    // Write readonly properties to the file system
    NSError * error;
    // Read the mutable dictionary from the file
    NSMutableDictionary * captureDictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[self.straboCaptureDirectoryPath stringByAppendingPathComponent:self.captureInfoPath]] options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        if (_advancedLogging) NSLog(@"STRCapture: There was a problem saving your changes: %@", error.description);
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
        if (_advancedLogging) NSLog(@"STRCapture: There was a problem saving your changes: %@", error.description);
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
