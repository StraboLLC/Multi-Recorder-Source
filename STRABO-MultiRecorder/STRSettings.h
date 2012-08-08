//
//  STRSettings.h
//  STRABO-MultiRecorder
//
//  Created by Thomas Beatty on 8/7/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STRSettings : NSObject

+(STRSettings *)sharedSettings;

-(NSString *)uploadPath;

@end
