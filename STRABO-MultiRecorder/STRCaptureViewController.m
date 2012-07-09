//
//  STRCaptureViewController.m
//  Toast
//
//  Created by Thomas Beatty on 6/28/12.
//  Copyright (c) 2012 Strabo. All rights reserved.
//

#import "STRCaptureViewController.h"

@interface STRCaptureViewController (InternalMathods)

// -- Service Initialization -- //

/**
 Set up the location services.
 
 Initialize the CLLocationManager (locationManager) and assign values like accuracy and purpose.
 */
-(void)setUpLocationServices;

/**
 Set up the camera capture object.
 
 Set up the STRCaptureDataCollector to receive data from video and audio sources. Prepare to record either audio or video.
 */
-(void)setUpCaptureServices;

// -- Error Handling -- //

/**
 Check to make sure the user has enabled location services.
 
 Dismiss the current view and call the delegate method [STRCaptureViewControllerDelegate locationServicesNotAuthorized] if location services are not enabled.
 */
-(void)checkEnabledLocationServices;

// -- Recording Services -- //

/**
 Record a datapoint to the geoLocationData object if the recorder happens to be on.
 
 Gets the location directly from the locationManager.
 */
-(void)recordCurrentLocationToGeodataObject;

-(void)startCapturingVideo;
-(void)stopCapturingVideo;
-(void)captureStillImage;

@end

@interface STRCaptureViewController (STRCaptureDataControllerDelegate) <STRCaptureDataCollectorDelegate>

-(void)videoRecordingDidBegin;
-(void)videoRecordingDidEnd;
-(void)videoRecordingDidFailWithError:(NSError *)error;

@end

@interface STRCaptureViewController (CLLocationManagerDelegate) <CLLocationManagerDelegate>

// Responding to location events
-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;

// Responding to heading events
-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading;
-(BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager;

// Responding to authorization changes

@end

@implementation STRCaptureViewController

@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //preferencesManager = [STRUserPreferencesManager preferencesForCurrentUser];
    
    mediaStartTime = CACurrentMediaTime();
    isRecording = NO;
}

-(void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
}

-(void)viewDidAppear:(BOOL)animated {
    // Listen for orientation change events
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDidRotate) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    // Set up location and capture here while the shutter is displayed
    // This will be done after the view loads.
    [self setUpLocationServices];
    [self setUpCaptureServices];
    
    // Now that the capture services are set up, 
    // load the video preview layer with the captureSesson
    capturePreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:[captureDataCollector session]];
    capturePreviewLayer.frame = videoPreviewLayer.bounds;
    capturePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [videoPreviewLayer.layer addSublayer:capturePreviewLayer];
    
}

-(void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

#pragma mark - Device Orientation Handling

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)deviceDidRotate {
    NSLog(@"STRCaptureViewController: Orientation change requested.");
    
    UIDeviceOrientation newOrientation = [[UIDevice currentDevice] orientation];
    
    if (currentOrientation
        && newOrientation
        && (currentOrientation != newOrientation) 
        && (!isRecording) 
        && (newOrientation != UIDeviceOrientationFaceUp)
        && (newOrientation != UIDeviceOrientationFaceDown)) {
        
        // Update currentOrientation to keep track of the old orientation
        currentOrientation = newOrientation;
        
        // Update the Location Manager with the new orientation setting.
        locationManager.headingOrientation = currentOrientation;
        
    }
}

#pragma mark - Button Handling

-(IBAction)doneButtonWasPressed:(id)sender {
    NSLog(@"STRCaptureViewController: Dismissing capture controller.");
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)recordButtonWasPressed:(id)sender {
    if (isRecording) {
        NSLog(@"STRCaptureViewController: Rec button pressed - stopping capture session.");
        [self stopCapturingVideo];
    } else {
        NSLog(@"STRCaptureViewController: Rec button pressed - starting capture session.");
        [self startCapturingVideo];
    }
}

@end

@implementation STRCaptureViewController (InternalMathods)

#pragma mark - Service Initialization

-(void)setUpLocationServices {
    // Set up the location support
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    //locationManager.purpose = @"Geotagging your Toast video captures.";
    //locationManager.desiredAccuracy = preferencesManager.desiredLocationAccuracy;
    [locationManager startUpdatingHeading];
    [locationManager startUpdatingLocation];
}

-(void)setUpCaptureServices {
    captureDataCollector = [[STRCaptureDataCollector alloc] init];
    captureDataCollector.delegate = self;
}

#pragma mark - Error Handling

-(void)checkEnabledLocationServices {
    // Check to make sure that the user has location services enabled.
    // If not, present the user with a warning message and kill.
    if (![CLLocationManager locationServicesEnabled] || ![CLLocationManager authorizationStatus]) {
        // Tell the delegate about the problem
        if ([_delegate respondsToSelector:@selector(locationServicesNotAuthorized)]) {
            [_delegate locationServicesNotAuthorized];
        }
        // Dismiss the view
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

#pragma mark - Recording Services

-(void)recordCurrentLocationToGeodataObject {
    // Add a point taken from the locationManager
    NSLog(@"STRCaptureViewController: Recording a geodata point");
    [geoLocationData addDataPointWithLatitude:locationManager.location.coordinate.latitude
                                    longitude:locationManager.location.coordinate.longitude 
                                      heading:locationManager.heading.trueHeading 
                                    timestamp:(CACurrentMediaTime() - mediaStartTime) 
                                     accuracy:locationManager.location.horizontalAccuracy];
}

-(void)startCapturingVideo {
    [captureDataCollector startCapturingVideoWithOrientation:currentOrientation];
}

-(void)stopCapturingVideo {
    [captureDataCollector stopCapturingVideo];
}

-(void)captureStillImage {
    
}

@end

@implementation STRCaptureViewController (CLLocationManagerDelegate)

#pragma mark - Responding to location events
-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    // Log the current location and heading
    if (isRecording) {
        [self recordCurrentLocationToGeodataObject];
    }
    
    // Update the accuracy indicator
    
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"STRCaptureViewController: Location manager failed and could not receive location data: %@", error.description);
}

#pragma mark - Responding to heading events
-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    // Log the current heading and location
    if (isRecording) {
        [self recordCurrentLocationToGeodataObject];
    }
    
    // Update the compass
}

-(BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
    if (isRecording) return NO;
    return YES;
}

@end

@implementation STRCaptureViewController (STRCaptureDataControllerDelegate)


-(void)videoRecordingDidBegin {
    NSLog(@"STRCaptureViewController: Video recording did begin.");
    isRecording = YES;
    
    // Force record the first geodata point
    mediaStartTime = CACurrentMediaTime();
    [self recordCurrentLocationToGeodataObject];
}

-(void)videoRecordingDidEnd {
    NSLog(@"STRCaptureViewController: Video recording did end.");
    isRecording = NO;
    
    // Write the JSON geo-data
    [geoLocationData writeDataPointsToTempFile];
    
    // Write files to a more permanent location
    
    // Add video to the user's album
    
}

-(void)videoRecordingDidFailWithError:(NSError *)error {
    NSLog(@"STRCaptureViewController: !!!ERROR: Video recording failed: %@", error.description);
}

@end
