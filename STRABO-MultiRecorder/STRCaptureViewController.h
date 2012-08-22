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

typedef enum {
    STRCaptureModeVideo,    // Video capture mode
    STRCaptureModeImage     // Image capture mode
} STRCaptureModeState;

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
 
 An overview of the methods to override:
 
 ###syncRecordUI
 
 Syncs the user interface to reflect recording status. This method is called when video recording has started and again when it has ended (independent of success). In this method, you should update any user interface elements that respond to a change in the status of the instance variable isRecording.
 
 First, you should check isRecording to determine the recording state of the player. Next, you should update UI elements as necessary. For example, start or end record button flashing, enable or disable record buttons or capture mode selectors, etc.
 
 ***STUB*** (good BBQ sauce)
 
 */
@interface STRCaptureViewController : UIViewController {
    
    id _delegate;
    BOOL isRecording;
    STRCaptureModeState _captureMode;
    
    // UI Elements
    IBOutlet UIActivityIndicatorView * activityIndicator;
    IBOutlet UISegmentedControl * mediaSelectorControl;
    IBOutlet UIBarButtonItem * recordButton;
    
    // Location support
    CLLocationManager * locationManager;
    STRGeoLocationData * geoLocationData;
    CLLocation * initialLocation;
    CLHeading * initialHeading;
    
    // Camera capture support
    STRCaptureDataCollector * captureDataCollector;
    AVCaptureVideoPreviewLayer * capturePreviewLayer;
    IBOutlet UIView * videoPreviewLayer;
    
    // General capture support
    double mediaStartTime;
    UIDeviceOrientation currentOrientation;
}

/**
 The parent object.
 
 The delegate of a STRCaptureViewController should implement a [STRCaptureViewControllerDelegate].
 */
@property(strong)id delegate;

/**
 Changes the mode so that the recorder captures either a video or an image.
 
 This method is used to switch the capture mode between video and image states. Usually this is called when the selector switch is changed on the capture view controller. If you want to change the capture state programmatically, you can use the custom setter setCaptureMode: to pass either STRCaptureModeVideo or STRCaptureModeImage.
 */
@property(getter = captureMode, setter = setCaptureMode:)STRCaptureModeState captureMode;

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
