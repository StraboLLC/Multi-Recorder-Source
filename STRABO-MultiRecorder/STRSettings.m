//
//  STRSettings.m
//  STRABO-MultiRecorder
//
//  Created by Thomas Beatty on 8/7/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import "STRSettings.h"

@interface STRSettings ()

@end

@implementation STRSettings

+(STRSettings *)sharedSettings {
    STRSettings * settings = [[STRSettings alloc] init];
    settings.settingsDict = [[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"STRSettings" ofType:@"plist"]];
    return settings;
}

-(NSString *)uploadPath {
    NSDictionary * URLs = [_settingsDict objectForKey:@"Upload_URL"];
    NSString * basePath = [URLs objectForKey:@"Base_URL"];
    NSString * apiPath = [URLs objectForKey:@"API_URL"];
    NSString * fullPath = [basePath stringByAppendingPathComponent:apiPath];
    return fullPath;
}

-(BOOL)advancedLogging {
    return [[_settingsDict objectForKey:@"Advanced_Logging"] boolValue];
}


@end
