Getting the SDK
===

Downloading and installing the SDK is a piece of cake. The steps outlined below will show you how to easily download and include the proper files to work with the Strabo capture code used in the Toast and Ramble products.

Cloning the Git Repo
---

The code that you will need is hosted on [GitHub](http://github.com). Request access by emailing Nate at: nate@strabogis.com. If you already have access to the repository, you can browse it [online](https://github.com/StraboLLC/Strabo-Multi-Recorder). Otherwise, clone the repository:

1. Install [Git](http://git-scm.com/)
2. Clone the repository

Run the following code in terminal:

	$ cd ~/new/directory/strabo-multi-recorder
	$ git clone https://github.com/StraboLLC/Strabo-Multi-Recorder

The contents of this repo should be as follows:

	/Multi-Recorder/
		sample/
			My Great Capture Recorder/
				-sample xcode project files
		scripts/
			buildSDK
			installDocs
		src/
			libStrabo-Multi-Recorder.a

Installing the Documentation
---

The complete documentation for the project comes packaged with the SDK. To install the docs to the Xcode library, open a new terminal window and run the installDocs script.

	$ cd ...Multi-Recorder/scripts/installDocs
	$ ./installDocs

Integrating With a Project
---

You should already have created your Xcode iOS application project. If not, do so now.

The "src" folder contains everything that you need. Find the folder in your cloned repo and drag it into your project. The following prompt will appear:

<img src="xcode-dialog.png" width="450px" />

You can choose whether or not to select the dialog box to copy the files into your project. If you choose to leave it deselected, you can pull the most recent changes from the remote git repository and your files will automatically be kept in sync with the most recent bugfixes, etc. Otherwise, you will need to re-copy the src folder anytime you wish to update to the most recent build.
