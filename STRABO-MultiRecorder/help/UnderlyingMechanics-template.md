Underlying Mechanics
===

Although it should be rarely necessary to access the underlying file structure containing captures directly, this guide walks you through how captures are stored and upload in the filesystem, how capture tokens work, and the differences between different types of captures.

1. [Capture Tokens](#capturetokens)
4. [General File Structure](#generalfilestructure)
2. [File Type Details](#filetypedetails)
5. [Recording Flow](#recordingflow)
3. [File Uploads](#fileuploads)

<a name="capturetokens"></a>
Capture Tokens
--------------

###Overview

A unique capture token is generated for every capture taken by a user. 

To generate the token, a unique identifier is first generated using Apple's SDK for each application installation. After concatenating this unique application identifier string with a string representation of the current unix timestamp, the combination is run through a SHA2 hash algorithm. This produces unique tokens with negligible probability of collisions.

The token is used to identify a specific capture and is persistant across both the Strabo Mobile SDK as well as the [web API](http://api.strabo.co). You will need this token to retrieve a capture from the Web API - see the online documentation at api.strabo.co for more details.

The capture token is also used in the local iOS application file system to store all files related to a capture. This ensures a unique directory structure and is described in more detail below.

<a name="generalfilestructure"></a>
General File Structure
----------------------

***STUB***

<a name="filetypedetails"></a>
File Type Details
-----------------

***STUB***

<a name="recordingflow"></a>
Recording Flow
--------------

***STUB***

<a name="fileuploads"></a>
File Uploads
------------

***STUB***
