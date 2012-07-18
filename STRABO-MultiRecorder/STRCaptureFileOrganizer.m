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

// Thumbnail Generation Support
-(UIImage *)thumbnailForImageAtPath:(NSString *)imagePath;
-(UIImage *)thumbnailForVideoAtPath:(NSString *)videoPath;
-(CGImageRef)CGImageRotatedByAngle:(CGImageRef)imgRef angle:(CGFloat)angle;

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
    NSString * thumbnailPath = [newDirectoryPath stringByAppendingPathComponent:[randomFilename stringByAppendingPathExtension:@"png"]];
    NSString * captureInfoPath = [newDirectoryPath stringByAppendingPathComponent:@"capture-info.json"];
    [fileManager createFileAtPath:captureInfoPath contents:nil attributes:nil];
    
    // Write the thumbnail image
    [UIImagePNGRepresentation([self thumbnailForVideoAtPath:mediaTempPath]) writeToFile:thumbnailPath atomically:YES];
    
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

-(UIImage *)thumbnailForImageAtPath:(NSString *)imagePath {
    // Get a handle on the image at the path specified
    UIImage * image = [UIImage imageWithContentsOfFile:imagePath];
    CGImageRef imgRef = [image CGImage];
    
    // Determine the proper scale to fit into 300 X 300
    int longImageSideSize = (image.size.height > image.size.width) ? image.size.height : image.size.width;
    CGFloat scale = (float)(300 / longImageSideSize);
    
    // Return a new scaled image
    UIImage * newImage = [UIImage imageWithCGImage:imgRef scale:scale orientation:UIImageOrientationUp];
    return newImage;
}

-(UIImage *)thumbnailForVideoAtPath:(NSString *)videoPath {
    
    // Set up the generator
    AVURLAsset * videoFileAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:videoPath] options:nil];
    AVAssetImageGenerator * generator = [[AVAssetImageGenerator alloc] initWithAsset:videoFileAsset];
    // Set the maximum size of the image, constrained, of course, to its original aspect ratio.
    generator.maximumSize = CGSizeMake(300, 300);
    
    // Generate the image
    NSError * error;
    // Copy the first image at time (0.0s) in the video file
    CMTime time = CMTimeMakeWithSeconds(0, 30);
    CGImageRef imgRef = [generator copyCGImageAtTime:time actualTime:NULL error:&error];
    if (error) return nil;
    
    UIImage * image = [UIImage imageWithCGImage:imgRef];
    return image;
}

-(CGImageRef)CGImageRotatedByAngle:(CGImageRef)imgRef angle:(CGFloat)angle {
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

@end
