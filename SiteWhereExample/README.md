![SiteWhere] (https://s3.amazonaws.com/sitewhere-demo/sitewhere-small.png)

# SiteWhere iOS Example App
The app demostrates how an iOS device can be an IoT gateway and/or client device for SiteWhere. As an IoT gateway you can register an iOS device with SiteWhere and send location and measurement events. As an IoT client you can register to have events pushed in real-time to an iOS device. Configuring what events get pushed to a specific device is done using server side filters and groovy scripts. The sample app uses the device's current location and accelerometer.


## Developer Setup
* Latest version of XCode installed
* Please use [Cocoa Pods](http://cocoapods.org/).  If you're not familar with Cocoa Pods read the [getting start guide](http://guides.cocoapods.org/using/getting-started.html).  Cocoa Pods in very easy to use.

## Quickstart
Step 1. Clone this repository.

Step 2. Using a shell, cd into the "SiteWhereExample" directory of the project.

Step 3. Install and download dependencies:
```
pod install
```
Step 4. Open SiteWhereExample.xcworkspace in XCode

Step 5. Change SiteWhere Server IP:

In ViewController.m change the IP to point to your SiteWhere instance
```
#define SITEWHERE_MESSAGE_BROKER_HOST       "192.168.86.101"
```
# Discussion
Join the discussion - https://groups.google.com/forum/#!forum/sitewhere
