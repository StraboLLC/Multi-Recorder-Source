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

-(IBAction)doneButtonWasPressed:(id)sender;
-(IBAction)recordButtonWasPressed:(id)sender;
    

@end
