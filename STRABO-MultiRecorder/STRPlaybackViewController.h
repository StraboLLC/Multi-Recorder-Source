//
//  STRPlaybackViewController.h
//  My Great Capture Recorder
//
//  Created by Thomas Beatty on 8/13/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MapKit/MapKit.h>

#import "STRCapture.h"
#import "STRPlayerView.h"

/*
 A viewer which plays back video and movements on a map simultaneously in a split-screen interface.
 
 Completely self-contained player for a STRCapture object.
 
 @warning This class is built completely on top of and using public functions of the SDK. It is meant to be a proof of concept and is in no way ready for production. It has NOT been debugged and error handling is essentially non-existent. I hacked it out one morning to demonstrate that it is possible (and relatively easy) to build a player on top of the SDK.
 */
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

// Map Stuff
@property(nonatomic, weak)IBOutlet MKMapView * mapView;

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
