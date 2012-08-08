//
//  STRSettings.m
//  STRABO-MultiRecorder
//
//  Created by Thomas Beatty on 8/7/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import "STRSettings.h"

@interface STRSettings () {
    
    @private
    NSDictionary * settingsDict;
}

@property(nonatomic, strong)NSDictionary * settingsDict;

@end

@implementation STRSettings

+(STRSettings *)sharedSettings {
    STRSettings * settings = [[STRSettings alloc] init];
    settings.settingsDict = [[[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"STRSettings" ofType:@"plist"]] objectForKey:@"Root"];
    return settings;
}

-(NSString *)uploadPath {
    NSDictionary * URLs = [_settingsDict objectForKey:@"Upload_URL"];
    NSString * basePath = [URLs objectForKey:@"Base_Path"];
//    NSString *
//    return
    return nil;
}


@end
