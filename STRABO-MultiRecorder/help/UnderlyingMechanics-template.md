Underlying Mechanics
===

Although it should be rarely necessary to access the underlying file structure containing captures directly, this guide walks you through how captures are stored and upload in the filesystem, how capture tokens work, and the differences between different types of captures. If you are editing source code in the SDK directly, the following documentation will probably contain necessary knowledge.

1. [Capture Tokens](#capturetokens)
4. [General File Structure](#generalfilestructure)
2. [File Details](#filedetails)
5. [Recording Flow](#recordingflow)
3. [File Uploads](#fileuploads)

<a name="capturetokens"></a>
Capture Tokens
--------------

A unique capture token is generated for every capture taken by a user. 

To generate the token, a unique identifier is first generated using Apple's SDK for each application installation. After concatenating this unique application identifier string with a string representation of the current unix timestamp, the combination is run through a SHA2 hash algorithm. This produces unique tokens with negligible probability of collisions.

The token is used to identify a specific capture and is persistant across both the Strabo Mobile SDK as well as the [web API](http://api.strabo.co). You will need this token to retrieve a capture from the Web API - see the online documentation at api.strabo.co for more details.

The capture token is also used in the local iOS application file system to store all files related to a capture. This ensures a unique directory structure and is described in more detail below.

<a name="generalfilestructure"></a>
General File Structure
----------------------

###Overview

All captures are stored in a folder within the application documents directory. This directory is located at the following path:

	/Documents/StraboCaptures

All of the files pertaining to a capture are located within a subdirectory named according to that capture's token. For example, if the capture token is `338d2c23d2308bfced6117b3e9d63180d5594c8a9f5b8bd5a050914c239f358d`, the relevant capture files would be located in:

	/Documents/StraboCaptures/338d2c23d2308bfced6117b3e9d63180d5594c8a9f5b8bd5a050914c239f358d

Although this makes for rather long file paths, it ensures unique paths.

###Capture Files

Each capture has four files:

<table>
    <tr style="font-weight: bold;">
        <td>Description</td><td>File&nbsp;Name</td><td>File&nbsp;Extension</td><td>File&nbsp;Type</td><td>Notes</td>
    </tr>
    <tr>
    	<td><a href="#mediafile">Media</a></td><td>&lt;Capture&nbsp;Token&gt;</td><td>.mov or .jpg</td><td>MOV or JPEG</td><td></td>
    </tr>
    <tr>
    	<td><a href="#thumbnailimagefile">Thumbnail Image</a></td><td>&lt;Capture&nbsp;Token&gt;</td><td>.png</td><td>PNG</td><td>A thumbnail image representation of the media file. This image should fit into a 300x300 px box. The aspect ratio may be different based on the device used to capture the video or image. Thus, this image is resized so that no side is longer than 300 pixels and the original aspect ratio is preserved.</td>
    </tr>
    <tr>
    	<td><a href="#geodatafile">Geo-Data</a></td><td>&lt;Capture&nbsp;Token&gt;</td><td>.json</td><td>JSON</td><td></td>
    </tr>
    <tr>
    	<td><a href="#captureinfofile">Capture Info</a></td><td>capture-info</td><td>.json</td><td>JSON</td><td></td>
    </tr>
</table>

<a name="filedetails"></a>
File Details
-----------------

<a name="mediafile"></a>
###Media

This file could either be a quicktime movie file or an image, depending on the type of capture taken. It is automatically rotated to the proper orientation. If you need to programatically determine whether this is a movie file or an image file, you can use either the file extension or the `media_type` property in the [Capture Info](#captureinfofile) file.

<a name="thumbnailimagefile"></a>
###Thumbnail Image

This file is a small image (PNG) representation of the media file. If the media file is an image, then the thumbnail is simply a scaled-down version of the media (image) file. Alternatively, if the media file is a movie, then the thumbnail is generated from one of the first frames of the media (movie) file.

Different types of media files capture visual data with different aspect ratios and qualities. Similarly, not all Apple devices are capable of capturing high resolution images and video with the same aspect ratios. Because of the great variability expected in aspect ratios of the media file, the thumbnail is always generated to maintain that aspect ratio. It is scaled so that no side is greater than 300 px. Thus, it will always fit into a 300x300 box. Keep this in mind if you choose to display the thumbnail image as a representation of capture media.

<a name="geodatafile"></a>
###Geo-Data

This file contains an array of points (in JSON format) that correspond to geo-data points collected during a capture. If the capture is an image, the array may contain only one point. If the capture is a video, the array contains a number (possibly very large) of points. The number of points will never be zero - the array will never be empty.

Each point is a dictionary (or hash table, depending on your preferred terminology...) which contains specific information about that point including a timestamp, accuracy (in meters), latitude and longitude coordinates, and a heading (in degrees). Points are collected when the device senses a change in location or heading during a capture, so the timestamp interval between two points is not standard.

The contents of a sample Geo-Data file for an exceptionally short movie would look similar to the following:

	{
		"points": [{
			"timestamp": 0,
			"accuracy": 65,
			"coords": [43.62538491719486, -72.51787712345703],
			"heading": 99.43981838226318
		}, {
			"timestamp": 0.1515992499989807,
			"accuracy": 65,
			"coords": [43.62538491719486, -72.51787712345703],
			"heading": 98.43981838226318
		}, {
			"timestamp": 0.3319714166718768,
			"accuracy": 65,
			"coords": [43.62538491719486, -72.51787712345703],
			"heading": 97.43981838226318
		}, {
			"timestamp": 0.4355032083331025,
			"accuracy": 65,
			"coords": [43.62538491719486, -72.51787712345703],
			"heading": 96.43981838226318
		}]
	}

You can expect the best-possible value for the accuracy to be around 5 meters.

<a name="captureinfofile"></a>
###Capture Info

This JSON file is used to store non-geographic related data about the capture. It is the source of the information that the [STRCapture](STRCapture) class uses to produce instances of STRCapture objects. Its properties are defined below:

* created_at
	* UNIX timestamp creation date
* uploaded_at
	* UNIX timestamp for when the file was uploaded. This value is set to 0.0 by default when the capture is created.
* media_type
	* String representation of the type of capture. This value can be either `video` or `image`
* token
	* String of characters that is unique to each capture. This is a SHA 2 hash.
* title
	* String set to "Untitled Track" or similar by default. This string can be altered to any value - it can be user-defined.
* coords
	* Latitude and longitude coordinates that represent the initial location for the capture. This is helpful for displaying pins for captures on a map, etc. It is easier and faster to parse through the capture info file to find this information than it is to get the first coordinates taken from the geo-data file.
* heading
	* The initial heading of the capture in degrees. Commonly used to display pins on maps, etc.
* geodata_file
	* The local path to the [Geo-Data file](#geodatafile), relative to /Documents/StraboCaptures.
* thumbnail_file
	* The local path to the [Thumbnail Image file](#thumbnailimagefile), relative to /Documents/StraboCaptures.
* media_file
	* The local path to the [Media file](#mediafile), relative to /Documents/StraboCaptures.

The contents of a capture-info file should look similar to the following:

	{
		"created_at": 1344352260,
		"heading": 99.43981838226318,
		"thumbnail_file": "338d2c23d2308bfced6117b3e9d63180d5594c8a9f5b8bd5a050914c239f358d\/338d2c23d2308bfced6117b3e9d63180d5594c8a9f5b8bd5a050914c239f358d.png",
		"media_file": "338d2c23d2308bfced6117b3e9d63180d5594c8a9f5b8bd5a050914c239f358d\/338d2c23d2308bfced6117b3e9d63180d5594c8a9f5b8bd5a050914c239f358d.mov",
		"media_type": "video",
		"token": "338d2c23d2308bfced6117b3e9d63180d5594c8a9f5b8bd5a050914c239f358d",
		"uploaded_at": 1344352275.333697,
		"coords": [43.62538491719486, -72.51787712345703],
		"geodata_file": "338d2c23d2308bfced6117b3e9d63180d5594c8a9f5b8bd5a050914c239f358d\/338d2c23d2308bfced6117b3e9d63180d5594c8a9f5b8bd5a050914c239f358d.json",
		"orientation": "horizontal",
		"title": "track"
	}

<a name="recordingflow"></a>
Recording Flow
--------------

Captures should be recorded with a [STRCaptureViewController](STRCaptureViewController). The following guide will walk you through how captures are recorded and how the files for a capture are generated and saved by the STRCaptureViewController and associated model files.

###Capturing Media

When media, either an image or video, is captured, it is saved to the temporary directory within the application. The media is stored in either `output.jpg` or `output.mov`. Associated geodata is written to a temporary file called `output.json`. 

Geodata is recorded slightly differently for video and image captures. Throughout the duration of the recording of a movie, a instance of the CLLocationManager class is used to receive periodic location and heading updates at irregular time intervals. Every time an update is made, another point is written to the geodata output temp file in the background. Image files only require one point. When an image is captured and the image file is written, the current location and heading are retrieved from a CLLocationManager and are written as a single point in the geodata temp file.

###Saving Temp Files

After recording of both the media and geodata files is complete, an instance of the [STRCaptureFileOrganizer](STRCaptureFileOrganizer) class copies the temporary files to a more permanent location, creates an appropriate thumbnail image file from whichever media file (either .mov or .jpg) is present, and writes the [Capture Info](#captureinfofile) file. This collection of four files is written to a new directory which corresponds to the capture's unique token - the details of which are described [previously](#generalfilestructure) in this document. When this saving process is complete, the STRCaptureViewController instance is notified and a new recording can commence. Any failures are reported via delegation.

<a name="fileuploads"></a>
File Uploads
------------

Capture uploads can be done easily using a [STRCaptureUploadManager](STRCaptureUploadManager). You can pass any [STRCapture](STRCapture) instance which represents a locally stored capture to a method in the upload manager and it sends all of the capture files to the Strabo servers. See the [STRCaptureUploadManager](STRCaptureUploadManager) documentation for further details and a guide about how you should handle uploads.

When you pass a capture to [STRCaptureUploadManager beginUploadForCapture:], a POST request is generated and prepared to be sent to the Strabo server. This request contains some specific information pertaining to the application, as well as all four files associated with the capture. These files are appended to the request as encoded data.

Once the POST request has been generated, the STRCaptureUploadManager establishes a connection with the server and sends the POST request asynchronously. It is important that the request be sent asynchronously so that the main thread / the user interface is not tied up for the duration of the upload. This also allows you to respond to upload events like failures and upload progress.

Once the upload has completed, the STRCaptureUploadManager waits for a response from the Strabo server. After the server has verified the request, it returns a JSON response that is handled by the STRCaptureUploadManager.

Upon verfication of a successful response, the STRCaptureUploadManager notifies its delegate of a successful upload. Of course, it only notifies its delegate if the delegate implements the [STRCaptureUploadManagerDelegate](STRCaptureUploadManagerDelegate) protocol. This notification, a call to the `fileUploadedSuccessfullyWithToken:` protocol method, passes the unique token that identifies the capture in both the Mobile SDK and the Web API.

