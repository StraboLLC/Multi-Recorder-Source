//
//  STRCaptureViewController.m
//  Toast
//
//  Created by Thomas Beatty on 6/28/12.
//  Copyright (c) 2012 Strabo. All rights reserved.
//
#import "STRSettings.h"

#import "STRCaptureViewController.h"

// Define constants
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

// -- Service Teardown -- //

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

// -- UI Methods -- //
// All of these can be overridden for subclassing //

/**

 */
-(void)mediaSelectorDidChange;
-(void)syncRecordUI;
-(void)syncSelectorUI;
-(void)imageCaptureHandleUI;
-(void)updateGeoIndicatorUI;

/**
 Animates the shutter over the screen to the open position.
 
 This signifies that the view controller has finished loading and is ready to make a capture. It should be called after the view appears, after the location and video capture components have been set up and are running.
 */
-(void)animateShutterOpen;

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

@interface STRCaptureViewController () {
    BOOL _advancedLogging;
    
    // Location Support
    STRGeoLocationData * geoLocationData;
    CLLocation * initialLocation;
    CLHeading * initialHeading;
    
    // Camera capture support
    STRCaptureDataCollector * captureDataCollector;
    AVCaptureVideoPreviewLayer * capturePreviewLayer;
    
    // General capture support
    double mediaStartTime;
    UIDeviceOrientation currentOrientation;

}

@property()BOOL advancedLogging;

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

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Retrieve options from settings
    _advancedLogging = [[STRSettings sharedSettings] advancedLogging];
    
    // Set up recording constants
    mediaStartTime = CACurrentMediaTime();
    self.isRecording = NO;
    self.isReadyToRecord = NO;
    [activityIndicator stopAnimating];
    
    // Set up the mediaSelector event observer
    [mediaSelectorControl addTarget:self action:@selector(mediaSelectorDidChange) forControlEvents:UIControlEventValueChanged];
    
    // Set the default capture mode to video
    [self setCaptureMode:STRCaptureModeVideo];
}

-(void)viewWillAppear:(BOOL)animated {
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

-(void)viewDidAppear:(BOOL)animated {
    
    // UPGRADES NOTE:
    // This could all be launched on a seperate thread so that it doesn't
    // tie up UI elements like the DONE button or other media selectors.
    
    // Check all dependent services
    [self checkEnabledLocationServices];
    
    // Listen for orientation change events
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDidRotate) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    // Set up location and capture here while the shutter is displayed
    // This will be done after the view loads.
    if (!self.locationManager) {
        [self setUpLocationServices];
    }
    [self setUpCaptureServices];
    
    // Now that the capture services are set up,
    // load the video preview layer with the captureSession
    capturePreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:[captureDataCollector session]];
    capturePreviewLayer.frame = videoPreviewLayer.bounds;
    capturePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [videoPreviewLayer.layer addSublayer:capturePreviewLayer];
    
    // Set up the current orientation
    currentOrientation = [[UIDevice currentDevice] orientation];
    
    self.isReadyToRecord = YES;
}

-(void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    videoPreviewLayer = nil;
}

#pragma mark - Custom Accessors

-(void)setIsRecording:(BOOL)isRecording {
    // Change the instance variable
    _isRecording = isRecording;
    // Make updates to the UI as necessary
    [self syncRecordUI];
}

-(void)setIsReadyToRecord:(BOOL)isReadyToRecord {
    // Change the instance variable
    _isReadyToRecord = isReadyToRecord;
    // Make updates to the UI as necessary
    [self syncRecordUI];
}

-(void)setCaptureMode:(STRCaptureModeState)captureMode {
    if (_captureMode != captureMode) {
        // Set the instance variable
        _captureMode = captureMode;
        
        // Set the UI selector, just in case this method is called programatically
        [self syncSelectorUI];
    }
    
    // Annoying logging stuff
    if (_advancedLogging) {
        NSString * modeString;
        if (_captureMode == STRCaptureModeVideo) {
            modeString = @"STRCaptureModeVideo";
        } else {
            modeString = @"STRCaptureModeImage";
        }
        NSLog(@"STRCaptureViewController: Capture mode constant set to %@", modeString);
    }
}

-(STRCaptureModeState)captureMode {
    return _captureMode;
}



#pragma mark - Device Orientation Handling

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)deviceDidRotate {
    UIDeviceOrientation newOrientation = [[UIDevice currentDevice] orientation];
    if (currentOrientation
        && newOrientation
        && (currentOrientation != newOrientation)
        && (!_isRecording)
        && (newOrientation != UIDeviceOrientationFaceUp)
        && (newOrientation != UIDeviceOrientationFaceDown)) {
        
        // Update currentOrientation to keep track of the old orientation
        currentOrientation = newOrientation;
        
        // Update the Location Manager with the new orientation setting.
        _locationManager.headingOrientation = currentOrientation;
        
        if (_advancedLogging) {
            NSLog(@"STRCaptureViewController: Orientation changed to: %i", currentOrientation);
        }
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
    // Vary behavior based on the mediaSelectorControl
    if (_captureMode == STRCaptureModeVideo) {
        // Start or stop recording video
        if (_isRecording) {
            // Stop capturing
            [self stopCapturingVideo];
            
            // Start the activity spinner
            [activityIndicator startAnimating];
            // Disallow activity while spinning
            [recordButton setEnabled:NO];
        } else {
            [self startCapturingVideo];
        }
    } else {
        // Record an image
        [self captureStillImage];
    }
}

@end

@implementation STRCaptureViewController (InternalMathods)

#pragma mark - Service Initialization

-(void)setUpLocationServices {
    
    // Set up the location support
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    [_locationManager startUpdatingHeading];
    [_locationManager startUpdatingLocation];
}

-(void)setUpCaptureServices {
    captureDataCollector = [[STRCaptureDataCollector alloc] init];
    captureDataCollector.delegate = self;
}

-(void)setUpRecordingObservers {
    NSLog(@"Setting up recording observers");
    [self addObserver:self forKeyPath:@"isRecording" options:0 context:nil];
    [self addObserver:self forKeyPath:@"_isRecording" options:0 context:nil];
    
}

#pragma mark - Service Teardown

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
    [geoLocationData addDataPointWithLatitude:_locationManager.location.coordinate.latitude
                                    longitude:_locationManager.location.coordinate.longitude
                                      heading:_locationManager.heading.trueHeading
                                    timestamp:(CACurrentMediaTime() - mediaStartTime)
                                     accuracy:_locationManager.location.horizontalAccuracy];
}

-(void)startCapturingVideo {
    geoLocationData = [[STRGeoLocationData alloc] init];
    [captureDataCollector startCapturingVideoWithOrientation:currentOrientation];
}

-(void)stopCapturingVideo {
    [captureDataCollector stopCapturingVideo];
}

-(void)captureStillImage {
    
    // UPGRADES NOTE:
    // This could all be launched on a seperate thread so that it doesn't
    // tie up UI elements and then the completion handler could set isRecording to NO;
    
    self.isRecording = YES;
    
    // Write a new geoLocationData file
    geoLocationData = [[STRGeoLocationData alloc] init];
    initialLocation = _locationManager.location;
    initialHeading = _locationManager.heading;
    [geoLocationData addDataPointWithLatitude:_locationManager.location.coordinate.latitude
                                    longitude:_locationManager.location.coordinate.longitude
                                      heading:_locationManager.heading.trueHeading
                                    timestamp:0.00
                                     accuracy:_locationManager.location.horizontalAccuracy];
    [geoLocationData writeDataPointsToTempFile];
    
    // Capture the image
    [captureDataCollector captureStillImageWithOrientation:currentOrientation];
    
    // UPGRADES NOTE:
    // Launch this on the main thread
    
    // Provide UI feedback of a still image capture
    [self imageCaptureHandleUI];
    
    self.isRecording = NO;
}

#pragma mark - File Handling

-(void)resaveTemporaryFilesOfType:(NSString *)captureType {
    
    // Perform saving actions
    STRCaptureFileOrganizer * fileOrganizer = [[STRCaptureFileOrganizer alloc] init];
    
    NSString * mediaPath;
    if ([captureType isEqualToString:@"video"]) {
        mediaPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.mov"];
        // Move video files
        [fileOrganizer saveTempVideoFilesWithInitialLocation:initialLocation heading:initialHeading];
    } else if ([captureType isEqualToString:@"image"]) {
        mediaPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.jpg"];
        // Move image files
        [fileOrganizer saveTempImageFilesWithInitialLocation:initialLocation heading:initialHeading];
    } else {
        if (_advancedLogging) NSLog(@"STRCaptureViewController: Method resaveTemporaryFilesOfType: called with improper parameters. Please see documentation.");
    }
    
    // If necessary, save the media file to the photo roll
    
    if ([[STRSettings sharedSettings] saveToPhotoRoll]) {
        if (_advancedLogging) NSLog(@"STRCaptureViewController: Saving media files to the photo roll if possible.");
        [fileOrganizer saveMediaToPhotoRollFromPath:mediaPath];
    }
    
    // Stop the activity spinner
    [activityIndicator stopAnimating];
    
}

#pragma mark - UI Methods

-(void)mediaSelectorDidChange {
    // Switch the capture mode if necessary
    if (_captureMode == STRCaptureModeVideo) {
        [self setCaptureMode:STRCaptureModeImage];
    } else if (_captureMode == STRCaptureModeImage) {
        [self setCaptureMode:STRCaptureModeVideo];
    } else {
        if (_advancedLogging) NSLog(@"STRCaptureViewController: Invalid STRCaptureModeState set for captureMode property.");
    }
    
    // Selector UI is automatically changed because setCaptureMode: automatically
    // also calls the helper UI method syncSelectorUI:.
}

-(void)syncRecordUI {
    
    // Set the record button to enabled if recording is ready
    if (_isReadyToRecord) {
        [recordButton setEnabled:YES];
        [activityIndicator stopAnimating];
    } else {
        [recordButton setEnabled:NO];
        [activityIndicator startAnimating];
    }
    
    if (_isRecording) {
        // Set the record button text
        recordButton.title = @"Stop";
        [mediaSelectorControl setEnabled:NO];
    } else {
        
        if (_captureMode == STRCaptureModeVideo) {
            recordButton.title = @"Rec";
        } else {
            recordButton.title = @"Img";
        }
        
        [mediaSelectorControl setEnabled:YES];
    }
}

-(void)syncSelectorUI {
    // Called when the capture mode is changed
    if (_captureMode == STRCaptureModeImage) {
        recordButton.title = @"Img";
        mediaSelectorControl.selectedSegmentIndex = 1;
    } else if (_captureMode == STRCaptureModeVideo) {
        recordButton.title = @"Rec";
        mediaSelectorControl.selectedSegmentIndex = 0;
    } else {
        if (_advancedLogging) NSLog(@"STRCaptureViewController: Invalid STRCaptureModeState set for captureMode property.");
    }
}

-(void)imageCaptureHandleUI {
    // Provide some sort of feedback to the user when an image has been captured
    
    // Animate a quick flash
    CGRect newFrame = self.view.frame;
    newFrame.origin = CGPointMake(0, 0);
    UIView * flashView = [[UIView alloc] initWithFrame:newFrame];
    
    flashView.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:flashView];
    
    [UIView animateWithDuration:0.4
                     animations:^(void){
                         [flashView setAlpha:0.0f];
                     }
                     completion:^(BOOL finished){
                         [flashView removeFromSuperview];
                     }
     ];
}

-(void)updateGeoIndicatorUI {

}

-(void)animateShutterOpen {
    #warning Incomplete implementation
}

@end

@implementation STRCaptureViewController (CLLocationManagerDelegate)

#pragma mark - Responding to location events
-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    // Log the current location and heading
    if (_isRecording) {
        [self recordCurrentLocationToGeodataObject];
    }
    
    // Update the accuracy indicator or location indicator
    [self updateGeoIndicatorUI];
    
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"STRCaptureViewController: Location manager failed and could not receive location data: %@", error.description);
}

#pragma mark - Responding to heading events
-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    // Log the current heading and location
    if (_isRecording) {
        [self recordCurrentLocationToGeodataObject];
    }
    
    // Update the compass
    [self updateGeoIndicatorUI];
}

-(BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
    if (_isRecording) return NO;
    return YES;
}

@end

@implementation STRCaptureViewController (STRCaptureDataControllerDelegate)


-(void)videoRecordingDidBegin {
    if (_advancedLogging) NSLog(@"STRCaptureViewController: Video recording did begin.");
    self.isRecording = YES;
    
    // Force record the first geodata point
    mediaStartTime = CACurrentMediaTime();
    // Write an initial point to the data
    initialLocation = _locationManager.location;
    initialHeading = _locationManager.heading;
    [geoLocationData addDataPointWithLatitude:_locationManager.location.coordinate.latitude
                                    longitude:_locationManager.location.coordinate.longitude
                                      heading:_locationManager.heading.trueHeading
                                    timestamp:0.00
                                     accuracy:_locationManager.location.horizontalAccuracy];
}

-(void)videoRecordingDidEnd {
    if (_advancedLogging) NSLog(@"STRCaptureViewController: Video recording did end.");
    self.isRecording = NO;
    self.isReadyToRecord = NO;
    
    // Write the JSON geo-data
    [geoLocationData writeDataPointsToTempFile];
    
    // Write files to a more permanent location
    [self resaveTemporaryFilesOfType:@"video"];
    self.isReadyToRecord = YES;
}

-(void)videoRecordingDidFailWithError:(NSError *)error {
    NSLog(@"STRCaptureViewController: !!!ERROR: Video recording failed: %@", error.description);
    self.isReadyToRecord = YES;
}

-(void)stillImageWasCaptured {
    // Save the temp files
    [self resaveTemporaryFilesOfType:@"image"];
    self.isReadyToRecord = YES;
}

@end
