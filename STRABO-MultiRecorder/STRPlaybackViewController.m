//
//  PlaybackViewController.m
//  My Great Capture Recorder
//
//  Created by Thomas Beatty on 8/13/12.
//  Copyright (c) 2012 Strabo, LLC. All rights reserved.
//

#import "STRPlaybackViewController.h"
#import "STRSettings.h"

// UIImage extension

CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};
CGFloat RadiansToDegrees(CGFloat radians) {return radians * 180/M_PI;};

@interface UIImage (Utilities)

-(UIImage *)imageRotatedByDegrees:(CGFloat)degrees;

@end

@implementation UIImage (Utilities)

-(UIImage *)imageRotatedByDegrees:(CGFloat)degrees {
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.size.width, self.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians(degrees));
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, DegreesToRadians(degrees));
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), [self CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


@end

// STRPlaybackViewController stuff

@interface STRPlaybackViewController () {
    BOOL _advancedLogging;
    
    // A dictionary to store the dataPoints of the local track
    // so that they are readily accessible
    NSDictionary * _dataPoints;
    
    NSArray * _dataKeys;
    
    // Keeps track of the index of the current datapoint
    __block NSNumber * _playTracker;
    
}

@property()BOOL advancedLogging;
@property(nonatomic, strong)NSDictionary * dataPoints;
@property(nonatomic, strong)NSArray * dataKeys;
@property(nonatomic, strong)NSNumber * playTracker;

@end

@interface STRPlaybackViewController (InternalMethods)

// Playback setup stuff
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
-(void)addTimeObserverToPlayer:(AVPlayer *)readyPlayer;

// Playback support
-(void)playerItemDidReachEnd:(NSNotification *)notification;
-(void)resetPlayTracker;
-(void)incrementPlayTracker;

// Map Support
-(void)setUpMap;
-(void)movePinToLocation:(CLLocation *)coordinate withHeading:(NSNumber *)heading;

// Utilities
// Rounds a number to 5 decimal places
-(NSNumber *)roundNumber:(NSNumber *)number;

@end

@interface STRPlaybackViewController (MKMapViewDelegate) <MKMapViewDelegate>

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation;

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
    _dataKeys = [_dataPoints.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        CMTime time1 = [obj1 CMTimeValue];
        CMTime time2 = [obj2 CMTimeValue];
        if (CMTIME_COMPARE_INLINE(time1, <, time2))
            return NSOrderedAscending;
        else if (CMTIME_COMPARE_INLINE(time1, >, time2))
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
    
    // Initialize the play tracker
    [self resetPlayTracker];
    
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
    [self setUpMap];
    [self loadVideoAssetFromFile:assetFilePath];
}

-(void)viewWillDisappear:(BOOL)animated {
    
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

#pragma mark - Playback Setup

// Respond to the player's status change
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                       change:(NSDictionary *)change context:(void *)context {
    if (_advancedLogging) NSLog(@"STRPlaybackViewController: Player status change detected");
    if (context == &ItemStatusContext) {
        [self addTimeObserverToPlayer:_player];
        [self syncUI];
    }
}

// Reset the play head after it reaches the end
-(void)playerItemDidReachEnd:(NSNotification *)notification {
    [_player seekToTime:kCMTimeZero];
    [self resetPlayTracker];
    [self syncUI];
}

#pragma mark - Playback Support

-(void)addTimeObserverToPlayer:(AVPlayer *)readyPlayer {
    
    NSArray * timesArray = [_dataPoints allKeys];
    
    [readyPlayer addBoundaryTimeObserverForTimes:timesArray queue:NULL usingBlock:^(){
        // Every time a CMTime is passed, this action is performed
        if (_playTracker.intValue < _dataPoints.count) {
            NSArray * locationPoint = [_dataPoints objectForKey:[_dataKeys objectAtIndex:_playTracker.intValue]];
            [self movePinToLocation:[locationPoint objectAtIndex:0] withHeading:[locationPoint objectAtIndex:1]];
            [self incrementPlayTracker];
        } else {
            if (_advancedLogging) NSLog(@"STRPlaybackViewController: NSArray bounds error");
        }
    }];
}

-(void)resetPlayTracker {
    _playTracker = @0;
}

-(void)incrementPlayTracker {
    _playTracker = @( _playTracker.intValue + 1 );
}

#pragma mark - Map Support

-(void)setUpMap {
    
    self.mapView.delegate = self;
    
    // Set satellite view
    [self.mapView setMapType:MKMapTypeSatellite];
    
    // Set the center region
    CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(_localCapture.latitude.doubleValue, _localCapture.longitude.doubleValue);
    [self.mapView setCenterCoordinate:centerCoordinate animated:NO];
    
    // Zoom in
    [self.mapView setRegion:MKCoordinateRegionMake(centerCoordinate, MKCoordinateSpanMake(0.001, 0.001)) animated:NO];
    
    // Set up the pin
    MKPointAnnotation * newPin = [[MKPointAnnotation alloc] init];
    newPin.coordinate = centerCoordinate;
    [self.mapView addAnnotation:newPin];
    [self movePinToLocation:[[CLLocation alloc] initWithLatitude:_localCapture.latitude.doubleValue longitude:_localCapture.longitude.doubleValue] withHeading:_localCapture.heading];
    
}

-(void)movePinToLocation:(CLLocation *)coordinate withHeading:(NSNumber *)heading {
    if (_advancedLogging) NSLog(@"Location: %f, %f Heading: %@", coordinate.coordinate.latitude, coordinate.coordinate.longitude, heading);
    MKPointAnnotation * theAnnotation = [self.mapView.annotations objectAtIndex:0];
    [theAnnotation willChangeValueForKey:@"coordinate"];
    [theAnnotation setCoordinate:coordinate.coordinate];
    [theAnnotation didChangeValueForKey:@"coordinate"];
    
    [UIView animateWithDuration:0.1 animations:^{
        CGAffineTransform transform = CGAffineTransformMakeRotation(DegreesToRadians(heading.floatValue));
        [self.mapView viewForAnnotation:theAnnotation].transform = transform;
    }];
}

#pragma mark - Utilities

-(NSNumber *)roundNumber:(NSNumber *)number {
    NSString * numberString = [NSString stringWithFormat:@"%.5f", number.doubleValue];
    return @( [numberString floatValue] );
}

@end

@implementation STRPlaybackViewController (MKMapViewDelegate)

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    static NSString *AnnotationViewID = @"annotationViewID";
    
    MKAnnotationView * annotationView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationViewID];
    
    if (annotationView == nil)
    {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationViewID];
    }
    
    annotationView.image = [UIImage imageNamed:@"pinImage.png"];
    annotationView.annotation = annotation;
    
    return annotationView;
}

@end
