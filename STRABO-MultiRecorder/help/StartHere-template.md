Welcome to Ramble
===

This guide will walk you through downloading and incorporating the Ramble-style capture recorder into your iOS application.

This recorder is similar to the iPhone native camera application in appearance, but it captures location data from the user in a unique way. When taking pictures, the application creates and stores a file with all relevant associated geo-data. For videos, the application creates and stores a file with geo-data relevant to the movemenet of the device throughout the capturing of the video.

This SDK was designed to be as plug-and-play as possible. The files are meant to me a module that you can customize and include in your application in order to modally present a view with camera functionality to your user at any time.

Contents of the guide:

1. [Getting The SDK](GettingTheSDK)
	- Walks you through the process of downloading the necessary files to your local machine and integrating this SDK with an existing Xcode project.
1. [Working With the SDK](WorkingWithTheSDK)
	- Provides an overview of some of the key features of the SDK, including code samples and suggestions for optimal implementations of common views and tasks.
2. [Underlying Mechanics](UnderlyingMechanics)
	- Describes the file system, token generation, and other underlying principles of the SDK. Reading this guide might be helpful for you general understanding, but you shouldn't have to deal with the filesystem and other low-level features of the SDK in practice.
3. [Release History](ReleaseHistory)
	- Historical release notes for revisions of the SDK.

This SDK was built by Nate Beatty. Please feel free to send me an email with any questions or issues: nate@strabogis.com. Alternatively, you can contact Strabo support at support@strabogis.com.