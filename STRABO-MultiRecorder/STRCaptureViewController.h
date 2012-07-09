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

// Capture / Location Support
#import "STRCaptureDataCollector.h"
#import "STRGeoLocationData.h"

// Preferences
// #import "STRUserPreferencesManager.h"

@protocol STRCaptureViewControllerDelegate

@optional

-(void)locationServicesNotAuthorized;

@end

@interface STRCaptureViewController : UIViewController {
    
    id delegate;
    BOOL isRecording;
    
    // Preferences
    //STRUserPreferencesManager * preferencesManager;
    
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
 Called to handle rotation events without updating UIInterfaceOrientation
 */
-(void)deviceDidRotate;

///---------------------------------------------------------------------------------------
/// @name Button Handling
///---------------------------------------------------------------------------------------

-(IBAction)doneButtonWasPressed:(id)sender;
-(IBAction)recordButtonWasPressed:(id)sender;
    

@end
