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

/**
 Capture delegate. Discussion goes here.
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
 
 In the case that this is called, you should take the appropriate steps to alert the user that the application only works when the 
 */
-(void)locationServicesNotAuthorized;

@end

/**
 A view controller which handles capturing of video and images.
 
 This view controller should be instantiated with the captureManager class method and then presented modally.
 */
@interface STRCaptureViewController : UIViewController {
    
    id delegate;
    BOOL isRecording;
    
    IBOutlet UIActivityIndicatorView * activityIndicator;
    
    // Location support
    CLLocationManager * locationManager;
    STRGeoLocationData * geoLocationData;
    
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
 
 You should never need to call this method. It is handled in the SDK Storyboard.
 */
-(IBAction)recordButtonWasPressed:(id)sender;

-(IBAction)tempImgButtonPressed:(id)sender;
    

@end
