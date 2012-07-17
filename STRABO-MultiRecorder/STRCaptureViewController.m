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
 
 Set up the STRCaptureDataCollector to receive data from video and audio sources. Prepare to record either an image or video.
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

// -- File Handling -- //

/**
 Coppies the temporary files to a more permanent and organized location.
 
 This method is called whenever a capture has finished recording to the temp files and is ready to be moved into the documents file heirarchy.
 
 @param captureType The media type captured by the recorder. This value can either be the string @"video" or @"image" for now.
 
 @warning This code should probably be in a model. The logic for moving files should be located somewhere else, not in the view controller, but this works for now.
 */
-(void)resaveTemporaryFilesOfType:(NSString *)captureType;

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

@interface STRCaptureViewController ()

@end

@implementation STRCaptureViewController

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
    // load the video preview layer with the captureSession
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

#pragma mark - Class Methods

+(STRCaptureViewController *)captureManager {
    UIStoryboard * recorderStoryboard = [UIStoryboard storyboardWithName:@"STRMultiRecorderStoryboard" bundle:[NSBundle mainBundle]];
    return [recorderStoryboard instantiateViewControllerWithIdentifier:@"captureViewController"];
}

#pragma mark - Button Handling

-(IBAction)doneButtonWasPressed:(id)sender {
    [self.delegate parentShouldDismissCaptureViewController:self];
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

-(IBAction)tempImgButtonPressed:(id)sender {
    [self captureStillImage];
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
    [geoLocationData addDataPointWithLatitude:locationManager.location.coordinate.latitude
                                    longitude:locationManager.location.coordinate.longitude
                                      heading:locationManager.heading.trueHeading
                                    timestamp:(CACurrentMediaTime() - mediaStartTime)
                                     accuracy:locationManager.location.horizontalAccuracy];
}

-(void)startCapturingVideo {
    geoLocationData = [[STRGeoLocationData alloc] init];
    [captureDataCollector startCapturingVideoWithOrientation:currentOrientation];
}

-(void)stopCapturingVideo {
    [captureDataCollector stopCapturingVideo];
}

-(void)captureStillImage {
    [captureDataCollector captureStillImage];
}

#pragma mark - File Handling

-(void)resaveTemporaryFilesOfType:(NSString *)captureType {
    
    // Start the activity spinner
    [activityIndicator startAnimating];
    
    // Perform saving actions
    STRCaptureFileOrganizer * fileOrganizer = [[STRCaptureFileOrganizer alloc] init];
    
    if ([captureType isEqualToString:@"video"]) {
        // Move video files
        [fileOrganizer saveTempVideoFilesWithInitialLocation:locationManager.location];
    } else if ([captureType isEqualToString:@"image"]) {
        // Move image files
        [fileOrganizer saveTempImageFiles];
    } else {
        NSLog(@"Method resaveTemporaryFilesOfType: called with improper parameters. Please see documentation.");
    }
    
    // Stop the activity spinner
    [activityIndicator stopAnimating];
    
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
    // Write an initial point to the data
    [geoLocationData addDataPointWithLatitude:locationManager.location.coordinate.latitude
                                    longitude:locationManager.location.coordinate.longitude
                                      heading:locationManager.heading.trueHeading
                                    timestamp:0.00
                                     accuracy:locationManager.location.horizontalAccuracy];
}

-(void)videoRecordingDidEnd {
    NSLog(@"STRCaptureViewController: Video recording did end.");
    isRecording = NO;
    
    // Write the JSON geo-data
    [geoLocationData writeDataPointsToTempFile];
    
    // Write files to a more permanent location
    [self resaveTemporaryFilesOfType:@"video"];
    
    // Add video to the user's album
    
}

-(void)videoRecordingDidFailWithError:(NSError *)error {
    NSLog(@"STRCaptureViewController: !!!ERROR: Video recording failed: %@", error.description);
}

@end
