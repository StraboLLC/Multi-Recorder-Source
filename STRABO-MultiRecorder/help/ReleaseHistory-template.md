Strabo Multi Recorder Release History
=====================================

Revisions to the master branch of the SDK will continue to be made, without notice, until August 31, 2012. At that point, bugfixes may be implemented, however the functionality of the SDK will not change and the methods and classes that you have access to will not be altered until the release of the next version. After August 31, the version of the SDK will be "Stable."

1.0
---

###1.0.2 - Stable Release Candidate
#####August 29, 2012

- New Features
	- STRCaptureViewController Lenscap animation
	- Added settings and utility functions to multiple classes
	- Successfully built and tested sample proof of concept capture player
		- Player support utility functions tested, documented, and finalized
- Stabilized Features
	- Multithreaded STRCaptureViewController video initialization
		- Vastly improved video preview loadtime
		- Improved stability
		- UI usability during loadtime now that expensive processing is moved off of the main thread
- Bugfixes
	- Minor bugfixes

###1.0.1 - Beta
#####August 24, 2012
- New Features
	- Settings stored in plist file
	- Import from URL or Photo Roll
	- Export to iOS shared photo roll
	- Viewer support methods
	- Customizable CLLocationManager
	- Improved documentation
- Stabilzed Features
	- Robust uploader error handling
	- Improved capture stability
	- Improved ability to subclass the STRCaptureViewController
		- Improved ability to customize UI elements
- Bugfixes
	- Image rotation
	- Post request headers
	- Capture sorting
	- Plugged memory leaks

###1.0.0 - Alpha
#####August 1, 2012
- Basic Functionality
  - Capture video and still images
  - Upload captures to Strabo servers
  - Manage saved captures