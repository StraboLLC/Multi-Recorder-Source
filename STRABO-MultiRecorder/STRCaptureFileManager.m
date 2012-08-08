//
//  STRCaptureFileManager.m
//  STRABO-MultiRecorder
//
//  Created by Thomas N Beatty on 7/9/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import "STRCaptureFileManager.h"

@interface STRCaptureFileManager ()
@property(readwrite)NSFileManager * fileManager;
@end

@interface STRCaptureFileManager (InternalMethods)
-(NSString *)capturesDirectoryPath;
@end

@implementation STRCaptureFileManager

#pragma mark - Class Methods

+(STRCaptureFileManager *)defaultManager {
    STRCaptureFileManager * newCaptureManager = [[STRCaptureFileManager alloc] init];
    newCaptureManager.fileManager = [NSFileManager defaultManager];
    return newCaptureManager;
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
    
    if (@(sortedCaptures.count) > limit) {
        NSRange theRange;
        theRange.location = 0;
        theRange.length = limit.integerValue;
        NSArray * subArray = [sortedCaptures subarrayWithRange:theRange];
        return subArray;
    }
    
    return sortedCaptures;
}

-(NSArray *)capturesOnDate:(NSDate *)date {
    // Get all local directories
    NSError * error;
    NSArray * localDirectories = [self.fileManager contentsOfDirectoryAtPath:self.capturesDirectoryPath error:&error];
    if (error) {
        return nil;
    }
    
    // Build an array of STRCapture objects
    // only including those with the right date
    NSMutableArray * captures = [NSMutableArray arrayWithObject:nil];
    for (NSString * subDirectory in localDirectories) {
        STRCapture * capture = [STRCapture captureFromFilesAtDirectory: subDirectory];
        if ([capture.creationDate isSameDayAsDate:date]) {
            [captures addObject:capture];
        }
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
    NSError * error;
    NSString * capturePath = [self.capturesDirectoryPath stringByAppendingPathComponent:capture.token];
    [_fileManager removeItemAtPath:capturePath error:&error];

    if (error) return NO;
    return YES;
}

-(BOOL)deleteCaptureWithToken:(NSString *)token {
    NSError * error;
    NSString * capturePath = [self.capturesDirectoryPath stringByAppendingPathComponent:token];
    [_fileManager removeItemAtPath:capturePath error:&error];
    
    if (error) return NO;
    return YES;
}

@end

@implementation STRCaptureFileManager (InternalMethods)

-(NSString *)capturesDirectoryPath {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/StraboCaptures"];
}

@end
