//
//  STRCaptureViewController.h
//  Toast
//
//  Created by Thomas Beatty on 6/28/12.
//  Copyright (c) 2012 Strabo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <QuartzCore/CAAnimation.h>

// Capture and Location Support
#import "STRCaptureDataCollector.h"
#import "STRGeoLocationData.h"

// File management
#import "STRCaptureFileOrganizer.h"

//****************************************************************************************
// Constant Definitions
//****************************************************************************************
typedef enum {
    STRCaptureModeVideo,    // Video capture mode
    STRCaptureModeImage     // Image capture mode
} STRCaptureModeState;

NSTimeInterval const STRLenscapAnimationDuration;

/**
 This is the protocol that the delegate object of the STRCaptureViewController should implement.
 
 The only method that you need to implement is parentShouldDismissCaputreViewController:. Because you should have presented the STRCaptureViewController modally, as described in its documentation, it should be dismissed by its parent like any other modally presented view.
 */
@protocol STRCaptureViewControllerDelegate

@required

/**
 Notifies the delegate that the capture view should be dismissed.
 
 When this method is called, take any necessary action and then dismiss the view controller with a line of code similar to the following:
 
    [self dismissViewControllerAnimated:YES completion:^{ NSLog("Capture view controller was dismissed.") }]
 
 @param sender The capture view controller (STRCaptureViewController) that should be dismissed.
 */
-(void)parentShouldDismissCaptureViewController:(UIViewController *)sender;

@optional

/**
 Called if the user has not authorized location services for this application.
 
 In the case that this is called, you should take the appropriate steps to alert the user that the application only works when the location services are enabled.
 */
-(void)locationServicesNotAuthorized;

@end

/**
 A view controller which handles capturing of video and images.
 
 This view controller should be instantiated with the captureManager class method and then presented modally.
 
 Subclassing Notes
 -----------------
 
 It is possible to subclass a STRCaptureViewController. You would do this if you want to include custom UI elements that are not available in the stock UI. Of course, you will need to provide some code to customize the behavior of these non-standard elements. All of the UI updates occur in the following internal methods which you will need to override:
 
    -(void)syncRecordUI;
    -(void)syncSelectorUI;
    -(void)imageCaptureHandleUI;
 
 An overview of the methods to override:
 
 ###syncRecordUI
 
 Syncs the user interface to reflect recording status. This method is called when video recording has started and again when it has ended (independent of success). In this method, you should update any user interface elements that respond to a change in the status of the instance variable isRecording.
 
 First, you should check isRecording to determine the recording state of the player. Next, you should update UI elements as necessary. For example, start or end record button flashing, enable or disable record buttons or capture mode selectors, etc.
 
 ***STUB*** (good BBQ sauce)
 
 */
@interface STRCaptureViewController : UIViewController {
    
    id _delegate;
    
    // Capture Support    
    BOOL _isRecording;
    BOOL _isReadyToRecord;
    STRCaptureModeState _captureMode;
    UIDeviceOrientation _currentOrientation;
    
    // Location support
    CLLocationManager * _locationManager;
    
    // UI Elements
    IBOutlet UIActivityIndicatorView * activityIndicator;
    IBOutlet UISegmentedControl * mediaSelectorControl;
    IBOutlet UIBarButtonItem * recordButton;
    IBOutlet UIView * videoPreviewLayer;
}

/**
 The parent object.
 
 The delegate of a STRCaptureViewController should implement a [STRCaptureViewControllerDelegate].
 */
@property(strong)id delegate;

/**
 Set to YES when the system is recording a new capture.
 
 You should always use the setter setIsRecording: to set the value of this property so that the proper methods are called for UI updates.
 */
@property(nonatomic, setter = setIsRecording:)BOOL isRecording;

/**
 Set to YES when the system is ready to record a new capture. Set to NO when the system is processing and is unable to begin a new recording.
 
 You should always use the setter setIsReadyToRecord: to set the value of this property so that the proper methods are called for UI updates.
 */
@property(nonatomic, setter = setIsReadyToRecord:)BOOL isReadyToRecord;

/**
 Changes the mode so that the recorder captures either a video or an image.
 
 This method is used to switch the capture mode between video and image states. Usually this is called when the selector switch is changed on the capture view controller. If you want to change the capture state programmatically, you can use the custom setter setCaptureMode: to pass either STRCaptureModeVideo or STRCaptureModeImage. For example, after you instantiate an instance of the STRCaptureViewController class, before presenting it, you can change the capture mode so that it will be in either Video mode or Image mode when the user pulls it up.
 */
@property(getter = captureMode, setter = setCaptureMode:)STRCaptureModeState captureMode;

/**
 The current device orientation.
 
 When the device changes orientation, it would be expensive from a system resources perspective to appropriately resize all of the views, etc, particularly during a capture. Thus, whenever an orientation change is detected, the view remains vertical but this property is altered to reflect the change.
 
 If you are subclassing the STRCaptureViewController and are overriding updateInterfaceToReflectOrientationChange, you should check this property and then perform any necessary alterations to your user interface (
 */
@property(nonatomic, readonly)UIDeviceOrientation currentOrientation;

/**
 The CLLocation manager responsible for gathering geolocation information during a capture.
 
 The location manager is set up automatically after a capture view appears and before the camera preview is loaded. STRCaptureViewController implements the CLLocationManagerDelegate protocol. The instance of the STRCaptureViewController class that owns the CLLocationManager should be set as the delegate object of the CLLocationManager instance.
 
 This property is readwrite so that you can optionally use a different instance of the CLLocationManager than the one created by the STRCaptureViewController during setup. If you wish to provide your own instance of the CLLocationManager, simply set this property before modally presenting the STRCaptureViewController. For example:
 
    // Create the instance of the view controller
    STRCaptureViewController * captureView = [STRCaptureViewController captureManager];
 
    // Set up your own location manager
    CLLocationManager * myLocationManager = [[CLLocationManager alloc] init];
    myLocationManager.delegate = captureView; // !! IMPORTANT !!
    // Fire up the location updates
    [myLocationManager startUpdatingHeading];
    [myLocationManager startUpdatingLocation];
 
    // Add the location manager to the STRCaptureViewController instance
    captureView.locationManager = myLocationManager;
    
    // Present the capture view as you normally would
    [captureView self presentModalViewController:captureView animated:YES];
 
 Using your own CLLocationManager can be convenient if you already have one running in your application and would like to re-use that instance with this SDK. Also, because the CLLocationManager frequently takes some time to acquire an accurate location, it may improve accuracy (although also increase power consumption) to start receiving location updates some time before you start capturing any media. A custom CLLocationManager is not, however, required.
 */
@property(nonatomic, strong, readwrite)CLLocationManager * locationManager;

/**
 Returns a new STRCaptureViewControllre object.
 
 Anytime you would like to present a STRCaptureViewController, you should use this method to return the initialized object. Just like presenting a view controller, 
 
 @return STRCaptureViewController a new STRCaptureViewController object.
 */
+(STRCaptureViewController *)captureManager;

/**
 Called to handle rotation events without updating UIInterfaceOrientation.
 
 You should never need to call this method directly. It is called by the default device notification center in the event of a device rotation.
 */
-(void)deviceDidRotate;

///---------------------------------------------------------------------------------------
/// @name Button Handling
///---------------------------------------------------------------------------------------

/**
 Called when the done button (back button) is pressed.
 
 You should never need to call this method. It is handled in the SDK Storyboard.
 */
-(IBAction)doneButtonWasPressed:(id)sender;

/**
 Called when the record button is pressed.
 
 You should never need to call this method. It is handled in the SDK Storyboard. If the mediaSelectorSwitch is set to video, this button starts a video capture. If the mediaSelectorSwitch is set to image, this button captures an image.
 */
-(IBAction)recordButtonWasPressed:(id)sender;
    

@end
