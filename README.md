# sitewhere-ios-sdk
Use this SDK to access the SiteWhere API from your iOS projects.

# Developer Setup
* Latest version of XCode installed
* Please use [Cocoa Pods](http://cocoapods.org/) to import the SDK into your project.  If you're not familar with Cocoa Pods read the [getting start guide](http://guides.cocoapods.org/using/getting-started.html).  Cocoa Pods in very easy to use.

# Quickstart
Step 1. Clone this repository

Step 2. Using a shell cd into the root directory of the project

Step 3. Install and download dependencies
```
pod install
```
Step 4. Add dependency to your Podfile
```
pod 'SiteWhereSDK', :path => '../' // path to local repository
```
Step 5. Update
```
pod update
```
Step 6. Import header file
```
#import <SiteWhereSDK/SiteWhereSDK.h>
```

# Sample App
The sample app can be found in the SiteWhereExample folder. The app demostrates how an iOS device can be an IoT gateway and/or client device for SiteWhere. As an IoT gateway you can register an iOS device with SiteWhere and send location and measurement events. As an IoT client you can register to have events pushed in real-time to an iOS device. Configuring what events get pushed to a specific device is done using server side filters and groovy scripts. The sample app uses the device's current location and accelerometer.
