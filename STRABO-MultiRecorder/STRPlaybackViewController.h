//
//  STRPlaybackViewController.h
//  My Great Capture Recorder
//
//  Created by Thomas Beatty on 8/13/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "STRCapture.h"
#import "STRPlayerView.h"

@interface STRPlaybackViewController : UIViewController {
    STRCapture * _localCapture;
}

@property(nonatomic, strong)STRCapture * localCapture;

// Toolbar stuff
@property(nonatomic, strong)IBOutlet UIToolbar * toolbar;
@property(nonatomic, strong)IBOutlet UIView * mainView;

// Video Player stuff
@property(nonatomic)AVPlayer * player;
@property(nonatomic)AVPlayerItem * playerItem;
@property(nonatomic, weak)IBOutlet STRPlayerView * playerView;
@property(nonatomic, weak)IBOutlet UIBarButtonItem * playButton;

// UI Stuff
@property(nonatomic, weak)IBOutlet UIActivityIndicatorView * activityIndicator;

// Class methods
+(STRPlaybackViewController *)playbackViewControllerForCapture:(STRCapture *)capture;

// More UI Stuff
-(void)showHideNavbar:(id)sender;

// Playback Support
-(void)loadVideoAssetFromFile:(NSString *)filePath;
-(void)syncUI;

// Button handling
-(IBAction)playButtonWasPressed:(id)sender;

@end
