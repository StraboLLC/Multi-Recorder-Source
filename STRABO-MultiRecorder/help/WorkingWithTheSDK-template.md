Working With the SDK
===

If you have not downloaded the SDK yet, see "[Getting the SDK](GettingTheSDK)".

If you have downloaded and implemented the SDK, at some point in your application you will undoubtedly want to display the view to capture a video or image using the Strabo capture geo-tagging technique. This guide will walk you through the steps to present the capture view, dismiss the capture view, and then access the files that may have been captured.

Contents of this guide:

1. [Presenting the Capture View Controller](#section1)
2. [Accessing Local Captures](#section2)
3. [Uploading a Capture](#section3)

<a name="section1"></a>
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

	@interface FirstViewController : UIViewController < STRCaptureViewControllerDelegate > {

	}

	// Button handling (buttons from storyboard)

	-(IBAction)cameraButtonWasPressed;

	// STRCaptureViewControllerDelegate methods

	-(void)parentShouldDismissCaptureViewController:(UIViewController *)sender;

	@end

In your .m file, you should include the code to initialize a new STRCaptureViewController and present it modally when necessary. In this case, we will put this code in the method that is called when the camera button is pressed. The method cameraButtonWasPressed should look like this:

	-(IBAction)cameraButtonWasPressed {
		// Create a new instance of a STRCaptureViewController
		STRCaptureViewController * captureVC = [STRCaptureViewController captureManager];
		// Assign the delegate to be self
		captureVC.delegate = self;
		// Present modally
		[self presentViewController:cameraVC animated:YES completion:nil];
	}

As discussed above, we will need a complete implementation of the delegate method, [parentShouldDismissCaptureViewController:](STRCaptureViewControllerDelegate parentShouldDismissCaptureViewController:). This method should look something like this:

	-(void)parentShouldDismissCaptureViewController:(UIViewController *)sender {
    	[sender dismissViewControllerAnimated:YES completion:nil];
	}

<a name="section2"></a>
Accessing Local Captures
---

Local captures are accessed using a [STRCaptureFileManger](STRCaptureFileManager).

*** STUB ***

<a name="section3"></a>
Uploading a Capture
---

This SDK provides an object to help you upload captures to the Strabo server for later playback and handling on the web. Strabo will handle the storage of the video and you are responsible for keeping track of how videos are associated with users, etc. The following section of the guide walks you through how to use a [STRCaptureFileManager](STRCaptureFileManager) to handle an upload and how to keep track of uploaded videos for later integration with the [web api](http://api.strabo.co/).

To upload a capture, you will need to do the following:

1. [Create a STRCapture Object](#section3.1)
2. [Instantiate a STRCaptureUploadManager](#section3.2)
3. [Upload the Capture Object](#section3.3)
4. [Handle the Upload Appropriately](#section3.4)

<a name="section3.1"></a>
###Create a STRCapture Object

If you wish to upload a capture to the Strabo server, you will first need to create a STRCapture object for the relevant capture. Most practically, this should be done with a [STRCaptureFileManager](STRCaptureFileManager) object, as described in [Accessing Local Captures](#section2). This is the recommended method. 

Alternatively, if you are programming at a lower level of abstraction and know the subdirectory path of the capture within the capture file system, you can instantiate a STRCapture object directly by using the [captureFromFilesAtDirectory:]([STRCapture captureFromFilesAtDirectory:]) class method. This is not recommended, particularly if you do not have access to the source files and are familiar with the file storage system and structures.

<a name="section3.2"></a>
###Instantiate a STRCaptureUploadManager

Instead of sending a POST request to a server yourself, you can use the [STRCaptureUploadManager](STRCaptureFileManager) class to do the work for you. Create a new STRCaptureUploadManager by using the [defaultManager]([STRCaptureUploadManager defaultManager]) class method.

<a name="section3.3"></a>
###Upload the Capture Object

Next, you can pass your previously created STRCapture object to the manager using the [STRCaptureUploadManager beginUploadForCapture:] method. This will start an asynchronous upload to the Strabo servers and will store your capture in the cloud.

Your code will look something like the following:
	
	// Create the capture object
	STRCapture * capture = // Create capture object using a STRCaptureFileManager

	// Upload the capture
	STRCaptureUploadManager * uploadManager = [STRCaptureUploadManager defaultManager];
	[uploadManager beginUploadForCapture:capture];

If at any point you need to cancel the upload, call the [cancelCurrentUpload]([STRCaptureUploadManager cancelCurrentUpload]) method.

To monitor the upload, you should implement the [STRCaptureUploadManagerDelegate](STRCaptureUploadManagerDelegate). Although all of the methods in this protocol are optional, they will be useful to determine the progress and status of the upload. Implementing the protocol is fairly straightforward - see the protocol documentation for more information.

<a name="section3.4"></a>
###Handle the Upload Appropriately

Because the captures are uploaded to the Strabo servers, you will need to get a reference to the uploaded capture in order to access it via the web API. The [STRCaptureUploadManagerDelegate](STRCaptureUploadManagerDelegate) provides a means for you to easily obtain the unique token for a capture upon successful upload. You will need to figure out a way to save this token for later use with the web API. One possible solution is outlined below:

*** STUB ***

- save token
- upload token to server with associated user ID
- access database of tokens