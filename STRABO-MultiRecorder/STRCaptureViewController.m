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

-(void)mediaSelectorDidChange;
-(void)syncRecordUI;
-(void)syncSelectorUI;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Retrieve options from settings
    _advancedLogging = [[STRSettings sharedSettings] advancedLogging];
    
    // Set up recording constants
    mediaStartTime = CACurrentMediaTime();
    isRecording = NO;
    
    // Set up the mediaSelector event listener
    [mediaSelectorControl addTarget:self action:@selector(mediaSelectorDidChange) forControlEvents:UIControlEventValueChanged];
    
    // Set the default capture mode to video
    [self setCaptureMode:STRCaptureModeImage];
}

-(void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
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
    
    // Set up the current orientation
    currentOrientation = [[UIDevice currentDevice] orientation];
    
    // By default, make sure the activity indicator is off
    if (!isRecording) {
        [activityIndicator stopAnimating];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

#pragma mark - Custom Accessors

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
        if (isRecording) {
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
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
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
    // Write a new geoLocationData file
    geoLocationData = [[STRGeoLocationData alloc] init];
    initialLocation = locationManager.location;
    initialHeading = locationManager.heading;
    [geoLocationData addDataPointWithLatitude:locationManager.location.coordinate.latitude
                                    longitude:locationManager.location.coordinate.longitude
                                      heading:locationManager.heading.trueHeading
                                    timestamp:0.00
                                     accuracy:locationManager.location.horizontalAccuracy];
    [geoLocationData writeDataPointsToTempFile];
    
    // Capture the image
    [captureDataCollector captureStillImageWithOrientation:currentOrientation];
}

#pragma mark - File Handling

-(void)resaveTemporaryFilesOfType:(NSString *)captureType {
    
    // Perform saving actions
    STRCaptureFileOrganizer * fileOrganizer = [[STRCaptureFileOrganizer alloc] init];
    
    NSString * mediaPath = NSTemporaryDirectory();
    if ([captureType isEqualToString:@"video"]) {
        mediaPath = [mediaPath stringByAppendingPathComponent:@"output.mov"];
        // Move video files
        [fileOrganizer saveTempVideoFilesWithInitialLocation:initialLocation heading:initialHeading];
    } else if ([captureType isEqualToString:@"image"]) {
        [mediaPath stringByAppendingPathComponent:@"output.jpg"];
        // Move image files
        [fileOrganizer saveTempImageFilesWithInitialLocation:initialLocation heading:initialHeading];
    } else {
        if (_advancedLogging) NSLog(@"STRCaptureViewController: Method resaveTemporaryFilesOfType: called with improper parameters. Please see documentation.");
    }
    
    // If necessary, save the media file to the photo roll
    
    if ([[STRSettings sharedSettings] saveToPhotoRoll]) {
        [fileOrganizer saveMediaToPhotoRollFromPath:mediaPath];
        if (_advancedLogging) NSLog(@"STRCaptureViewController: Saving media files to the photo roll if possible.");
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
    
    // Sync the switch UI
    [self syncSelectorUI];
}

-(void)syncRecordUI {
    // Sync UI to reflect recording status
    // Should be called when a video recording has started
    // and again when a video recording has ended.
    
    // Set the record button to enabled
    [recordButton setEnabled:YES];
    [activityIndicator stopAnimating];
    
    if (isRecording) {
        // Set the record button text
        recordButton.title = @"Stop";
        [mediaSelectorControl setEnabled:NO];
    } else {
        recordButton.title = @"Rec";
        [mediaSelectorControl setEnabled:YES];
    }
}

-(void)syncSelectorUI {
    // Called when the capture mode is changed
    if (_captureMode == STRCaptureModeImage) {
        mediaSelectorControl.selectedSegmentIndex = 1;
    } else if (_captureMode == STRCaptureModeVideo) {
        mediaSelectorControl.selectedSegmentIndex = 0;
    } else {
        if (_advancedLogging) NSLog(@"STRCaptureViewController: Invalid STRCaptureModeState set for captureMode property.");
    }
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
    if (_advancedLogging) NSLog(@"STRCaptureViewController: Video recording did begin.");
    isRecording = YES;
    
    // Sync the UI now that recording has started
    [self syncRecordUI];
    
    // Force record the first geodata point
    mediaStartTime = CACurrentMediaTime();
    // Write an initial point to the data
    initialLocation = locationManager.location;
    initialHeading = locationManager.heading;
    [geoLocationData addDataPointWithLatitude:locationManager.location.coordinate.latitude
                                    longitude:locationManager.location.coordinate.longitude
                                      heading:locationManager.heading.trueHeading
                                    timestamp:0.00
                                     accuracy:locationManager.location.horizontalAccuracy];
}

-(void)videoRecordingDidEnd {
    if (_advancedLogging) NSLog(@"STRCaptureViewController: Video recording did end.");
    isRecording = NO;
    
    // Write the JSON geo-data
    [geoLocationData writeDataPointsToTempFile];
    
    // Write files to a more permanent location
    [self resaveTemporaryFilesOfType:@"video"];
    [self syncRecordUI];
}

-(void)videoRecordingDidFailWithError:(NSError *)error {
    NSLog(@"STRCaptureViewController: !!!ERROR: Video recording failed: %@", error.description);
    [self syncRecordUI];
}

-(void)stillImageWasCaptured {
    // Save the temp files
    [self resaveTemporaryFilesOfType:@"image"];
}

@end
