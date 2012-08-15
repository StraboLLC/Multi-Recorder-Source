//
//  STRPlayerView.m
//  STRABO-MultiRecorder
//
//  Created by Thomas Beatty on 8/14/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import "STRPlayerView.h"

@implementation STRPlayerView

+(Class)layerClass {
    return [AVPlayerLayer class];
}

-(AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

-(void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

@end
