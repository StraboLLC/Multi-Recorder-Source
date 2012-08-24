Constants Reference
===================

Overview
--------

This document describes the constants used in the Strabo iOS Multi-Recorder SDK. It also details the customizable settings and options available in the STRSettings.plist file.

Settings: STRSettings.plist
-----------------

Certain overall options and settings are controlled by constants in the file named STRSettings.plist. 

NOTE: You should never alter the STRSettings class by editing the STRSettings.m or STRSettings.h files. Change the constants as described below in the PLIST file to alter the global behavior of the SDK.

###Available Settings

The settings are laid out as follows:

* `Upload_URL` (Dictionary)
	* `Base_URL` (String)
	* `API_URL` (String)
* `Advanced_Logging` (Boolean)
* `Save_To_Photo_Roll` (Boolean)

###Upload_URL (Dictionary)

This dictionary contains two values, `Base_URL` and `API_URL`, which together define the URL to which the STRCaptureUploadManager should upload captures.

When a capture is uploaded, the two values contained in the `Upload_URL` dictionary are concatenated and the upload POST request is sent to the resulting URL. The two parts, the base and the upload path, are seperated for development convenience when using test servers, production servers, distribution servers, etc.

Default values:
* `Upload_URL` :
	* `Base_URL` : `http://ns-api.herokuapp.com`
	* `API_URL` : `/upload`

###Advanced_Logging (Boolean)

This boolean value determines whether or not the SDK will log its actions. Most error messages are sent to the log so turning this on can be very helpful for debugging (both the SDK and applications built with the SDK). To hide all SDK calls to the NSLog, set the value for this key to `NO`. Otherwise, set the value to `YES`.

Default value:
* `Advanced_Logging` : `YES`

###Save_To_Photo_Roll (Boolean)

Determines whether or not to save captured images and video to the photo roll.

If this value is set to `YES`, any image or video recorded with this SDK will also be copied to the photo roll, provided that the user's iOS privacy settings allow that action to occur. Otherwise, only the SDK copy of the media will be saved and another copy will not be made. Because saving to the photo roll creates another copy of the media, if the user deletes media from the photo roll that was saved there by the SDK, it will not be deleted from the list of local captures. Likewise, a video or image saved in the iOS photo roll will not be deleted if the associated capture is deleted from the list of local captures taken with this SDK.

Default Value:
* `Save_To_Photo_Roll` : `NO`

Constants
---------

###Some Title

***STUB***