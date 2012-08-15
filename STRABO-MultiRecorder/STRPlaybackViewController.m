//
//  PlaybackViewController.m
//  My Great Capture Recorder
//
//  Created by Thomas Beatty on 8/13/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import "STRPlaybackViewController.h"
#import "STRSettings.h"

@interface STRPlaybackViewController () {
    BOOL _advancedLogging;
    
    // A dictionary to store the dataPoints of the local track
    // so that they are readily accessible
    NSDictionary * dataPoints;
}

@property()BOOL advancedLogging;
@property(nonatomic, strong)NSDictionary * dataPoints;

@end

@interface STRPlaybackViewController (InternalMethods)
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
-(void)playerItemDidReachEnd:(NSNotification *)notification;
-(void)addTimeObserverToPlayer:(AVPlayer *)readyPlayer;
@end

@implementation STRPlaybackViewController

// Define this constant for the key-value observation context.
static const NSString *ItemStatusContext;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Retrieve Settings
    _advancedLogging = [[STRSettings sharedSettings] advancedLogging];
    
    // Populate the datapoints from the local capture
    _dataPoints = [_localCapture geoDataPoints];
    
    // Add a tap recognizer to the main view
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showHideNavbar:)];
    [_mainView addGestureRecognizer:tapGesture];
    
    // Sync the UI
    [self syncUI];
}

-(void)viewWillAppear:(BOOL)animated {
    // Get rid of the status bar
    
    // Set the navigation bar to be translucent
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
}

-(void)viewDidAppear:(BOOL)animated {
    // Load the video
    NSString * assetFilePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/StraboCaptures"] stringByAppendingPathComponent:_localCapture.mediaPath];
    [self loadVideoAssetFromFile:assetFilePath];
}

-(void)viewWillDisappear:(BOOL)animated {
    NSLog(@"View will disappear.");
    
    // Remove the observer so that it doesn't send invalid calls
    // to pointers that are about to be released.
    [self.playerItem removeObserver:self forKeyPath:@"status" context:&ItemStatusContext];
    // Reset the navigation and status bars to default
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    
    [self.player pause];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    NSLog(@"View did unload");
    // Release any retained subviews of the main view.
    self.playerView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Class Methods

+(STRPlaybackViewController *)playbackViewControllerForCapture:(STRCapture *)capture {
    UIStoryboard * testStoryboard = [UIStoryboard storyboardWithName:@"STRMultiRecorderStoryboard" bundle:[NSBundle mainBundle]];
    STRPlaybackViewController * newViewController = [testStoryboard instantiateViewControllerWithIdentifier:@"playbackViewController"];
    newViewController.localCapture = capture;
    return newViewController;
}

#pragma mark - User Interface Controls

-(void)showHideNavbar:(id)sender {
    if (self.navigationController.navigationBarHidden) {
        // Show the nav bar and controls
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [_toolbar setHidden:NO];
    } else {
        // Hide the nav bar and controls
        [self.navigationController setNavigationBarHidden:YES animated:NO];
        [_toolbar setHidden:YES];
    }
}

#pragma mark - Playback Support

-(void)loadVideoAssetFromFile:(NSString *)filePath {
    
    AVURLAsset * videoAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:filePath] options:nil];
    NSString * tracksKey = @"tracks";
    
    [videoAsset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:^() {
        
        NSError *error;
        AVKeyValueStatus status = [videoAsset statusOfValueForKey:tracksKey error:&error];
        
        if (status == AVKeyValueStatusLoaded) {
            _playerItem = [AVPlayerItem playerItemWithAsset:videoAsset];
            
            // Observe changes so that we know when the player is ready to play
            [_playerItem addObserver:self forKeyPath:@"status"
                             options:0 context:&ItemStatusContext];
            
            _player = [AVPlayer playerWithPlayerItem:_playerItem];
            [_playerView setPlayer:_player];
            [self syncUI];
            
            // Register with the notification center after creating the player
            [[NSNotificationCenter defaultCenter]
             addObserver:self
             selector:@selector(playerItemDidReachEnd:)
             name:AVPlayerItemDidPlayToEndTimeNotification
             object:[_player currentItem]];
            
            if (_advancedLogging) NSLog(@"STRPlaybackViewController: Video successfully loaded.");
            
        } else {
            if (_advancedLogging) NSLog(@"STRPlaybackViewController: Error loading the capture's video asset: %@", error.localizedDescription);
        }
    }];
    
}

-(void)syncUI {
    
    // Set the button as enabled or disabled
    if ((self.player.currentItem != nil) &&
        ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
        _playButton.enabled = YES;
        [_activityIndicator stopAnimating];
    }
    else {
        _playButton.enabled = NO;
        [_activityIndicator startAnimating];
    }
}

#pragma mark - Button Handling
-(IBAction)playButtonWasPressed:(id)sender {
    if ([_playButton.title isEqualToString:@"Play"]) {
        [_playButton setTitle:@"Pause"];
        [self showHideNavbar:nil];
        [_player play];
    } else {
        [_playButton setTitle:@"Play"];
        [_player pause];
    }
}

@end

@implementation STRPlaybackViewController (InternalMethods)

// Respond to the player's status change
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                       change:(NSDictionary *)change context:(void *)context {
    NSLog(@"Player status change detected");
    if (context == &ItemStatusContext) {
        
        [self addTimeObserverToPlayer:_player];
        
        [self syncUI];
    }
}

// Reset the play head after it reaches the end
-(void)playerItemDidReachEnd:(NSNotification *)notification {
    [_player seekToTime:kCMTimeZero];
    [self syncUI];
}

-(void)addTimeObserverToPlayer:(AVPlayer *)readyPlayer {
    
    NSArray * timesArray = [_dataPoints allKeys];
    
    [readyPlayer addBoundaryTimeObserverForTimes:timesArray queue:NULL usingBlock:^(){
        if (_advancedLogging) NSLog(@"Timestamp notification in playback: %f", ((double)_player.currentTime.value/(double)_player.currentTime.timescale));
    }];
}

@end
