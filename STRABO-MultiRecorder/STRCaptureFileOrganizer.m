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
+(UIInterfaceOrientation)orientationForVideo:(AVAsset *)asset;
-(UIImage *)thumbnailForImageAtPath:(NSString *)imagePath;
-(UIImage *)thumbnailForVideoAtPath:(NSString *)videoPath;
+(CGImageRef)CGImage:(CGImageRef)imgRef rotatedByAngle:(CGFloat)angle;

@end

@implementation STRCaptureFileOrganizer

-(void)saveTempImageFilesWithInitialLocation:(CLLocation *)location heading:(CLHeading *)heading {
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString * randomFilename = [self randomFileName];
    NSString * newDirectoryPath = [[self capturesDirectoryPath] stringByAppendingPathComponent:randomFilename];
    
    // Make the new directory
    [fileManager createDirectoryAtPath:newDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Temp paths
    NSString * mediaTempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.jpg"];
    NSString * geoDataTempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.json"];
    // New paths
    NSString * mediaNewPath = [newDirectoryPath stringByAppendingPathComponent:[randomFilename stringByAppendingPathExtension:@"jpg"]];
    NSString * geoDataNewPath = [newDirectoryPath stringByAppendingPathComponent:[randomFilename stringByAppendingPathExtension:@"json"]];
    NSString * thumbnailPath = [newDirectoryPath stringByAppendingPathComponent:[randomFilename stringByAppendingPathExtension:@"png"]];
    NSString * captureInfoPath = [newDirectoryPath stringByAppendingPathComponent:@"capture-info.json"];
    [fileManager createFileAtPath:captureInfoPath contents:nil attributes:nil];
    
    // Write the thumbnail image
    [UIImagePNGRepresentation([self thumbnailForImageAtPath:mediaTempPath]) writeToFile:thumbnailPath atomically:YES];
    
    NSString * relativePath = [randomFilename stringByAppendingPathComponent:randomFilename];
    
    // Determine the orientation dynamically
    NSString * orientationString;
    UIImageOrientation imageOrientation = [[UIImage imageWithContentsOfFile:thumbnailPath] imageOrientation];
    if (imageOrientation == UIImageOrientationUp || imageOrientation == UIImageOrientationDown) {
        orientationString = @"vertical";
    } else {
        orientationString = @"horizontal";
    }
    
    // Save the capture info file
    NSDictionary * trackInfo = @{
    @"created_at" : [NSDate currentUnixTimestampNumber],
    @"geodata_file" : [relativePath stringByAppendingPathExtension:@"json"],
    @"coords" : @[ @(location.coordinate.latitude), @(location.coordinate.longitude) ],
    @"heading" : @(heading.trueHeading),
    @"media_file" : [relativePath stringByAppendingPathExtension:@"jpg"],
    @"orientation" : orientationString,
    @"thumbnail_file" : [relativePath stringByAppendingPathExtension:@"png"],
    @"title" : @"Untitled Capture",
    @"token" : randomFilename,
    @"media_type" : @"image",
    @"uploaded_at" : @0
    };
    NSOutputStream * output = [NSOutputStream outputStreamToFileAtPath:captureInfoPath append:NO];
    [output open];
    [NSJSONSerialization writeJSONObject:trackInfo toStream:output options:0 error:nil];
    [output close];
    
    // Copy the files from temp to new
    [fileManager copyItemAtPath:geoDataTempPath toPath:geoDataNewPath error:nil];
    
    // Image copying is screwy with orientations. Change the binary image orientation
    // and save the new resulting image to the permanent file.
    UIImage * image = [UIImage imageWithContentsOfFile:mediaTempPath];
    CGImageRef imgRef = image.CGImage;
    if (image.imageOrientation == UIImageOrientationRight) {
        imgRef = [STRCaptureFileOrganizer CGImage:imgRef rotatedByAngle:-90];
    } else if (image.imageOrientation == UIImageOrientationUp) {
        // Do nothing
    } else if (image.imageOrientation == UIImageOrientationLeft) {
        imgRef = [STRCaptureFileOrganizer CGImage:imgRef rotatedByAngle:90];
    } else if (image.imageOrientation == UIImageOrientationDown) {
        imgRef = [STRCaptureFileOrganizer CGImage:imgRef rotatedByAngle:180];
    }
    UIImage * newImage = [UIImage imageWithCGImage:imgRef scale:1.0 orientation:UIImageOrientationUp];
    [UIImageJPEGRepresentation(newImage, 1.0) writeToFile:mediaNewPath atomically:YES];
}

-(void)saveTempVideoFilesWithInitialLocation:(CLLocation *)location heading:(CLHeading *)heading {
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
    UIImage * thumbnail = [self thumbnailForVideoAtPath:mediaTempPath];
    [UIImagePNGRepresentation(thumbnail) writeToFile:thumbnailPath atomically:YES];
    
    NSString * relativePath = [randomFilename stringByAppendingPathComponent:randomFilename];
    
    // Determine the orientation to dynamically generate capture info file
    NSString * orientationString;
    AVURLAsset * videoFileAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:mediaTempPath] options:nil];
    UIInterfaceOrientation videoOrientation = [STRCaptureFileOrganizer orientationForVideo:videoFileAsset];
    if (videoOrientation == UIInterfaceOrientationLandscapeRight || videoOrientation == UIInterfaceOrientationLandscapeLeft) {
        orientationString = @"horizontal";
    } else {
        orientationString = @"vertical";
    }
    
    // Save the capture info file
    NSDictionary * trackInfo = @{
    @"created_at" : [NSDate currentUnixTimestampNumber],
    @"geodata_file" : [relativePath stringByAppendingPathExtension:@"json"],
    @"coords" : @[ @(location.coordinate.latitude), @(location.coordinate.longitude) ],
    @"heading" : @(heading.trueHeading),
    @"media_file" : [relativePath stringByAppendingPathExtension:@"mov"],
    @"orientation" : orientationString,
    @"thumbnail_file" : [relativePath stringByAppendingPathExtension:@"png"],
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
        
        NSString * newID = (__bridge id)(CFUUIDCreateString(kCFAllocatorDefault, CFUUIDCreate(kCFAllocatorDefault)));
        
        [userDefaults setObject:newID forKey:kSTRUniqueIdentifierKey];
        [userDefaults synchronize];
    }
    uniqueIdentifier = [userDefaults objectForKey:kSTRUniqueIdentifierKey];
    NSString * fileName = [NSString stringWithFormat:@"%@-%d", uniqueIdentifier, (int)[[NSDate date] timeIntervalSince1970]];
    return [fileName SHA2];
}

-(NSString *)capturesDirectoryPath {
    
    NSString * docPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/StraboCaptures"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:docPath isDirectory:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:docPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return docPath;
    
}

+(UIInterfaceOrientation)orientationForVideo:(AVAsset *)asset {
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize size = [videoTrack naturalSize];
    CGAffineTransform txf = [videoTrack preferredTransform];
    
    if (size.width == txf.tx && size.height == txf.ty)
        return UIInterfaceOrientationLandscapeRight;
    else if (txf.tx == 0 && txf.ty == 0)
        return UIInterfaceOrientationLandscapeLeft;
    else if (txf.tx == 0 && txf.ty == size.width)
        return UIInterfaceOrientationPortraitUpsideDown;
    else
        return UIInterfaceOrientationPortrait;
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
        imgRef = [STRCaptureFileOrganizer CGImage:imgRef rotatedByAngle:-90];
    } else if (image.imageOrientation == UIImageOrientationUp) {
        // Do nothing
    } else if (image.imageOrientation == UIImageOrientationLeft) {
        imgRef = [STRCaptureFileOrganizer CGImage:imgRef rotatedByAngle:90];
    } else if (image.imageOrientation == UIImageOrientationDown) {
        imgRef = [STRCaptureFileOrganizer CGImage:imgRef rotatedByAngle:180];
    }
    
    // Return a new scaled image
    UIImage * newImage = [UIImage imageWithCGImage:imgRef scale:scale orientation:image.imageOrientation];
    
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
    CMTime time = CMTimeMakeWithSeconds(0,30);
    CGImageRef imgRef = [generator copyCGImageAtTime:time actualTime:NULL error:&error];
    if (error) {
        NSLog(@"STRCaptureFileOrganizer: Error generating video thumbnail: %@", error);
    }
    
    // Rotate the image if necessary
    UIInterfaceOrientation videoOrientation = [STRCaptureFileOrganizer orientationForVideo:videoFileAsset];
    CGImageRef rotatedImgRef;
    if (videoOrientation == 1) {
        rotatedImgRef = [STRCaptureFileOrganizer CGImage:imgRef rotatedByAngle:-90];
    } else if (videoOrientation == 2) {
        rotatedImgRef = [STRCaptureFileOrganizer CGImage:imgRef rotatedByAngle:90];
    } else if (videoOrientation == 3) {
        rotatedImgRef = [STRCaptureFileOrganizer CGImage:imgRef rotatedByAngle:180];
    } else if (videoOrientation == 4) {
        // No rotation necessary
        rotatedImgRef = [STRCaptureFileOrganizer CGImage:imgRef rotatedByAngle:0];
    } else {
        NSLog(@"STRCaptureFileOrganizer: Video file orientation not recognized.");
    }
    CGImageRelease(imgRef);
    
    UIImage * image = [UIImage imageWithCGImage:rotatedImgRef];
    CGImageRelease(rotatedImgRef);
    return image;
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
    
	return rotatedImage;
}

@end
