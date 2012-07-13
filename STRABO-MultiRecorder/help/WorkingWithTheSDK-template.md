Working With the SDK
===

If you have not downloaded the SDK yet, see "[Getting the SDK](GettingTheSDK)".

If you have downloaded and implemented the SDK, at some point in your application you will undoubtedly want to display the view to capture a video or image using the Strabo capture geo-tagging technique. This guide will walk you through the steps to present the capture view, dismiss the capture view, and then access the files that may have been captured.

Presenting the Capture View Controller
---

The custom capture view controller is similar in appearance to Apple's native capture application. You present the capture view, an instance of a [STRCaptureViewController](STRCaptureViewController), modally and then dismiss it when the user is done taking pictures or video.

Prepare the view controller that will present the STRCaptureViewController as follows:

In your header file, import the sdk header file. This will ensure that you have access to all of the classes that you might decide to implement.

	#import "multi-recorder-sdk.h"

Alternatively, if you are a pro, you could just include the files that you know you will need:
	
	#import "StraboCaptureViewController.h"

Your view controller should also serve as a [STRCaptureViewControllerDelegate](STRCaptureViewControllerDelegate). That means that it needs to implement at least the required delegate methods. See the documentation for STRCaptureViewControllerDelegate for more details.

In many examples, the capture view will need to be presented when the user taps a button. For this reason, in my example, I will include the code to display the capture view as if it is hooked up to a button in a Storyboard file.

In total, your .h file might look similar to the following:

	//
	// FirstViewController.h
	// Created by Nate Beatty
	// Copyright (c) 2012 Strabo, LLC

	#import <UIKit/UIKit.h>
	#import "multi-recorder-sdk.h"

	@interface FirstViewController : UIViewController <STRCaptureViewControllerDelegate> {

	}

	// Button handling (buttons from storyboard)

	-(IBAction)cameraButtonWasPressed;

	// STRCaptureViewControllerDelegate methods

	-(void)parentShouldDismissCaptureViewController:(UIViewController *)sender;

	@end

