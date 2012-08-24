//
//  STRCaptureFileManager.m
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/9/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import "STRCaptureFileManager.h"
#import "STRSettings.h"

STRCaptureAttribute * const STRCaptureAttributeLatitude = @"kSTRCaptureAttributeLatitude";
STRCaptureAttribute * const STRCaptureAttributeLongitude = @"STRCaptureAttributeLongitude";
STRCaptureAttribute * const STRCaptureAttributeHeading = @"STRCaptureAttributeHeading";
STRCaptureAttribute * const STRCaptureAttributeDate = @"STRCaptureAttributeDate";
STRCaptureAttribute * const STRCaptureAttributeTitle = @"STRCaptureAttributeTitle";

@interface STRCaptureFileManager () {
    BOOL _advancedLogging;
}

@property()BOOL advancedLogging;

// Make the fileManager read/write
@property(readwrite)NSFileManager * fileManager;

@end

@interface STRCaptureFileManager (InternalMethods)

// -- Filepath Utilities -- //

-(NSString *)capturesDirectoryPath;

// -- Capture Creation Utilities -- //
-(NSString *)randomFileName;
-(UIImage *)thumbnailForImageAtPath:(NSString *)imagePath;
+(CGImageRef)CGImage:(CGImageRef)imgRef rotatedByAngle:(CGFloat)angle;
+(NSString *)randomStringWithLength:(int)len;

@end

@implementation STRCaptureFileManager

#pragma mark - Class Methods

+(STRCaptureFileManager *)defaultManager {
    
    // Create the new STRCaptureFileManager object
    STRCaptureFileManager * newCaptureManager = [[STRCaptureFileManager alloc] init];
    
    // Set the locally shared file manager
    newCaptureManager.fileManager = [NSFileManager defaultManager];
    
    // Get options from settings
    newCaptureManager.advancedLogging = [[STRSettings sharedSettings] advancedLogging];
    
    return newCaptureManager;
}

#pragma mark - Creating Captures

-(STRCapture *)newCaptureWithImageAtPath:(NSString *)mediaPath attributes:(NSDictionary *)attributes {
    
    // Do some initial setup
    NSString * randomFilename = [self randomFileName];
    NSString * newDirectoryPath = [[self capturesDirectoryPath] stringByAppendingPathComponent:randomFilename];

    // New paths
    NSString * mediaNewPath = [newDirectoryPath stringByAppendingPathComponent:[randomFilename stringByAppendingPathExtension:@"jpg"]];
    NSString * geoDataNewPath = [newDirectoryPath stringByAppendingPathComponent:[randomFilename stringByAppendingPathExtension:@"json"]];
    NSString * thumbnailPath = [newDirectoryPath stringByAppendingPathComponent:[randomFilename stringByAppendingPathExtension:@"png"]];
    NSString * captureInfoPath = [newDirectoryPath stringByAppendingPathComponent:@"capture-info.json"];
    
    // Create new text files
    [_fileManager createFileAtPath:geoDataNewPath contents:nil attributes:nil];
    [_fileManager createFileAtPath:captureInfoPath contents:nil attributes:nil];
    
    // Error handling -> Check for the existance of the passed media file
    if ([_fileManager fileExistsAtPath:mediaPath isDirectory:NO]) {
        if (_advancedLogging) NSLog(@"STRCaptureFileManager: Error processing the media file: it appears that the path is invalid.");
        return nil;
    }
    
    // Generate and write the thumbnail
    [UIImagePNGRepresentation([self thumbnailForImageAtPath:mediaPath]) writeToFile:thumbnailPath atomically:YES];
    
    // Copy the media to the new location
    NSError * error1;
    [_fileManager copyItemAtPath:mediaPath toPath:mediaNewPath error:&error1];
    if (error1) {
        if (_advancedLogging) NSLog(@"STRCaptureFileManager: Error copying the media file: %@", error1.localizedDescription);
        return nil;
    }
    
    NSString * relativePath = [randomFilename stringByAppendingPathComponent:randomFilename];
    
    // Determine the orientation dynamically
    NSString * orientationString;
    UIImageOrientation imageOrientation = [[UIImage imageWithContentsOfFile:thumbnailPath] imageOrientation];
    if (imageOrientation == UIImageOrientationUp || imageOrientation == UIImageOrientationDown) {
        orientationString = @"vertical";
    } else {
        orientationString = @"horizontal";
    }
    
    // Error handling -> Check for the existance of the required attributes
    if (![attributes objectForKey:STRCaptureAttributeLatitude] ||
        ![attributes objectForKey:STRCaptureAttributeLongitude]) {
        if (_advancedLogging) NSLog(@"STRCaptureFileManager: Error finding required attributes when generating new capture file.");
        return nil;
    }
    
    // Read the attributes dictionary
    NSNumber * ATTRlatitude = [attributes objectForKey:STRCaptureAttributeLatitude];
    NSNumber * ATTRlongitude = [attributes objectForKey:STRCaptureAttributeLongitude];
    NSNumber * ATTRheading = ([attributes objectForKey:STRCaptureAttributeHeading]) ? [attributes objectForKey:STRCaptureAttributeHeading] : @(0.0);
    NSDate * ATTRdate = ([attributes objectForKey:STRCaptureAttributeDate]) ? [attributes objectForKey:STRCaptureAttributeDate] : [NSDate date];
    NSString * ATTRTitle = ([attributes objectForKey:STRCaptureAttributeTitle]) ? [attributes objectForKey:STRCaptureAttributeTitle] : @"Untitled Track";
    
    // Save the capture info file
    NSDictionary * trackInfo = @{
    @"created_at" : @( [ATTRdate timeIntervalSince1970] ),
    @"geodata_file" : [relativePath stringByAppendingPathExtension:@"json"],
    @"coords" : @[ ATTRlatitude, ATTRlongitude ],
    @"heading" : ATTRheading,
    @"media_file" : [relativePath stringByAppendingPathExtension:@"jpg"],
    @"orientation" : orientationString,
    @"thumbnail_file" : [relativePath stringByAppendingPathExtension:@"png"],
    @"title" : ATTRTitle,
    @"token" : randomFilename,
    @"media_type" : @"image",
    @"uploaded_at" : @0
    };
    NSOutputStream * output1 = [NSOutputStream outputStreamToFileAtPath:captureInfoPath append:NO];
    [output1 open];
    NSError * error2;
    [NSJSONSerialization writeJSONObject:trackInfo toStream:output1 options:0 error:&error2];
    [output1 close];
    
    // Error handling -> Check for an error writing the JSON object to the file
    if (error2) {
        if (_advancedLogging) NSLog(@"STRCaptureFileManager: Error writing the info file for the new capture: %@", error2.localizedDescription);
        return nil;
    }
    
    // Save the geodata file
    NSDictionary * geodata = @{ @"points" : @[ @{
    @"timestamp" : @0,
    @"accuracy" : @15,
    @"coords" : @[ ATTRlatitude, ATTRlongitude ],
    @"heading" : ATTRheading
    } ] };
    NSOutputStream * output2 = [NSOutputStream outputStreamToFileAtPath:geoDataNewPath append:NO];
    [output2 open];
    NSError * error3;
    [NSJSONSerialization writeJSONObject:geodata toStream:output2 options:0 error:&error3];
    [output2 close];
    
    // Error handling -> Check for an error writing the JSON object to the file
    if (error3) {
        if (_advancedLogging) NSLog(@"STRCaptureFileManager: Error writing the geodata file for the new capture: %@", error3.localizedDescription);
        return nil;
    }
    
    // Everything appears to be successful! Capture has been saved locally.
    // Return a new STRCapture object with the newly created files
    NSString * newToken = randomFilename;
    return [STRCapture captureWithToken:newToken];
}

#pragma mark - Getting Local Captures

-(NSArray *)allCapturesSorted:(BOOL)sorted {
    // Get all local directories
    NSError * error;
    NSArray * localDirectories = [self.fileManager contentsOfDirectoryAtPath:self.capturesDirectoryPath error:&error];
    if (error) {
        return nil;
    }
    
    // Build an array of STRCapture objects
    NSMutableArray * captures = [NSMutableArray arrayWithCapacity:localDirectories.count];
    for (NSString * subDirectory in localDirectories) {
        [captures addObject:[STRCapture captureFromFilesAtDirectory:subDirectory]];
    }
    
    // Sort the array if necessary
    if (sorted) {
        [captures sortUsingComparator:^NSComparisonResult(id a, id b) {
            NSDate *first = [(STRCapture *)a creationDate];
            NSDate *second = [(STRCapture *)b creationDate];
            return [second compare:first];
        }];
    }
    
    return [NSArray arrayWithArray:captures];
}

-(NSArray *)recentCapturesWithLimit:(NSNumber *)limit {
    // Get all local directories
    NSArray * sortedCaptures = [self allCapturesSorted:YES];
    
    if (@(sortedCaptures.count).doubleValue > limit.doubleValue) {
        NSRange theRange;
        theRange.location = 0;
        theRange.length = limit.integerValue;
        NSArray * subArray = [sortedCaptures subarrayWithRange:theRange];
        return subArray;
    }
    
    return sortedCaptures;
}

-(NSArray *)capturesOnDate:(NSDate *)date sorted:(BOOL)sorted {
    // Get all local directories
    NSError * error;
    NSArray * localDirectories = [self.fileManager contentsOfDirectoryAtPath:self.capturesDirectoryPath error:&error];
    if (error) {
        return nil;
    }
    
    // Build an array of STRCapture objects
    // only including those with the right date
    NSMutableArray * captures = [[NSMutableArray alloc] init];
    for (NSString * subDirectory in localDirectories) {
        STRCapture * capture = [STRCapture captureFromFilesAtDirectory:subDirectory];
        if ([capture.creationDate isSameDayAsDate:date]) {
            NSLog(@"Adding object to the array");
            [captures addObject:capture];
        }
    }
    
    // Sort the array if necessary
    if (sorted) {
        [captures sortUsingComparator:^NSComparisonResult(id a, id b) {
            NSDate *first = [(STRCapture *)a creationDate];
            NSDate *second = [(STRCapture *)b creationDate];
            return [second compare:first];
        }];
    }
    
    return [NSArray arrayWithArray:captures];
}

-(NSNumber *)localCaptureCount {
    NSError * error;
    NSArray * localDirectories = [self.fileManager contentsOfDirectoryAtPath:self.capturesDirectoryPath error:&error];
    if (error) {
        return nil;
    }
    return @(localDirectories.count);
}

#pragma mark - Deleting Captures

-(BOOL)deleteCapture:(STRCapture *)capture {
    NSString * capturePath = [self.capturesDirectoryPath stringByAppendingPathComponent:capture.token];
    NSError * error;
    [_fileManager removeItemAtPath:capturePath error:&error];

    if (error) {
        if (_advancedLogging) NSLog(@"STRCaptureFileManager: Error deleting the capture: %@", error.description);
        return NO;
    }
    return YES;
}

-(BOOL)deleteCaptureWithToken:(NSString *)token {
    NSError * error;
    NSString * capturePath = [self.capturesDirectoryPath stringByAppendingPathComponent:token];
    [_fileManager removeItemAtPath:capturePath error:&error];
    
    if (error) {
        if (_advancedLogging) NSLog(@"STRCaptureFileManager: Error deleting the capture: %@", error.description);
        return NO;
    }
    return YES;
}

@end

@implementation STRCaptureFileManager (InternalMethods)

#define kSTRUniqueIdentifierKey @"kSTRUniqueIdentifierKey"

#pragma mark - Filepath Utilities

-(NSString *)capturesDirectoryPath {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/StraboCaptures"];
}

#pragma mark - Capture Creation Utilities

-(NSString *)randomFileName {
    // Get UUID
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    // Generate a new identifier if one does not already exist
    if (![userDefaults objectForKey:kSTRUniqueIdentifierKey]) {
        
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef UUIDstring = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        
        [userDefaults setObject:(__bridge_transfer NSString *)UUIDstring forKey:kSTRUniqueIdentifierKey];
        [userDefaults synchronize];
        
    }
    NSString * uniqueIdentifier = [userDefaults objectForKey:kSTRUniqueIdentifierKey];
    NSString * fileName = [NSString stringWithFormat:@"%@-%@-%d", uniqueIdentifier, [STRCaptureFileManager randomStringWithLength:10], (int)[[NSDate date] timeIntervalSince1970]];
    return [fileName SHA2];
}

-(UIImage *)thumbnailForImageAtPath:(NSString *)imagePath {
    // Get a handle on the image at the path specified
    UIImage * image = [UIImage imageWithContentsOfFile:imagePath];
    
    // Determine the proper scale to fit into 300 X 300
    int longImageSideSize = (image.size.height > image.size.width) ? image.size.height : image.size.width;
    CGFloat scale = (float)(300 / longImageSideSize);
    
    CGImageRef imgRef = [image CGImage];
    
    // Rotate the images
    if (image.imageOrientation == UIImageOrientationRight) {
        imgRef = [STRCaptureFileManager CGImage:imgRef rotatedByAngle:-90];
    } else if (image.imageOrientation == UIImageOrientationUp) {
        // Do nothing
    } else if (image.imageOrientation == UIImageOrientationLeft) {
        imgRef = [STRCaptureFileManager CGImage:imgRef rotatedByAngle:90];
    } else if (image.imageOrientation == UIImageOrientationDown) {
        imgRef = [STRCaptureFileManager CGImage:imgRef rotatedByAngle:180];
    }
    
    // Return a new scaled image
    UIImage * newImage = [UIImage imageWithCGImage:imgRef scale:scale orientation:image.imageOrientation];
    
    return newImage;
}

+(CGImageRef)CGImage:(CGImageRef)imgRef rotatedByAngle:(CGFloat)angle {
    CGFloat angleInRadians = angle * (M_PI / 180);
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
    
	CGRect imgRect = CGRectMake(0, 0, width, height);
	CGAffineTransform transform = CGAffineTransformMakeRotation(angleInRadians);
	CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef bmContext = CGBitmapContextCreate(NULL,
												   rotatedRect.size.width,
												   rotatedRect.size.height,
												   8,
												   0,
												   colorSpace,
												   kCGImageAlphaPremultipliedFirst);
	CGContextSetAllowsAntialiasing(bmContext, YES);
	CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
	CGColorSpaceRelease(colorSpace);
	CGContextTranslateCTM(bmContext,
						  +(rotatedRect.size.width/2),
						  +(rotatedRect.size.height/2));
	CGContextRotateCTM(bmContext, angleInRadians);
	CGContextDrawImage(bmContext, CGRectMake(-width/2, -height/2, width, height),
					   imgRef);
    
	CGImageRef rotatedImage = CGBitmapContextCreateImage(bmContext);
    CFRelease(bmContext);
    
	return rotatedImage;
}

+(NSString *)randomStringWithLength:(int)len {
    
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    
    return randomString;}

@end
