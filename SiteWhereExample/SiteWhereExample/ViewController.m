//
//  ViewController.m
//  SiteWhereExample
//
//  Created by Chris Bick on 11/25/15.
//  Copyright © 2015 SiteWhere. All rights reserved.
//

#import "ViewController.h"
#import "MBProgressHUD.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <MapKit/MapKit.h>

#define SEND_DATA_TO_SITEWHERE_INTERVAL     5    // 5 seconds
#define ACCELEROMETER_UPDATE_INTERVAL       .01

#define SITEWHERE_MESSAGE_BROKER_HOST       "192.168.86.101"
#define SITEWHERE_MESSAGE_BROKER_PORT       1883

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *longitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *altitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *rotxLabel;
@property (weak, nonatomic) IBOutlet UILabel *rotyLabel;
@property (weak, nonatomic) IBOutlet UILabel *rotzLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, strong) CMMotionManager* motionManager;

@end

@implementation ViewController
@synthesize locationManager, motionManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self startLocationUpdates];
    [self startRotationUpdates];
    [self startSiteWhere];
    
    // start timer to for sending location and measurement data to SiteWhere
    NSMethodSignature *sgn = [self methodSignatureForSelector:@selector(onTick)];
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature: sgn];
    [inv setTarget: self];
    [inv setSelector:@selector(onTick)];
    [NSTimer scheduledTimerWithTimeInterval:SEND_DATA_TO_SITEWHERE_INTERVAL invocation:inv repeats:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)startLocationUpdates {
    locationManager = [[CLLocationManager alloc]init];
    locationManager.delegate = self;
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) {
#if TARGET_OS_IPHONE
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [locationManager requestAlwaysAuthorization];
        }
#endif
    }
}

- (void)startRotationUpdates {
    motionManager = [[CMMotionManager alloc] init];
    motionManager.accelerometerUpdateInterval = ACCELEROMETER_UPDATE_INTERVAL;
    [motionManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init]
                                        withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self motionManager:motionManager didUpdateAccelerometerData:accelerometerData];
        });
    }];
    
    SiteWhereMessageClient* client = [SiteWhereMessageClient sharedPlatform];
    [client sendDeviceAlertWithHardwareId:[client getUniqueDeviceId] type:@"accelerometer.started" message:@"Started to read accelerometer data." specificationToken:@"9f2426bd-46de-49d6-833e-385784a9dc1a" originator:nil siteToken:@"bb105f8d-3150-41f5-b9d1-db04965668d3"];
}

- (void)startSiteWhere {
    SiteWhereMessageClient* client = [SiteWhereMessageClient sharedPlatform];
    client.delegate = self;
    
    // TODO add NSUserDefaults code.  look at android code. implement connection wizard.
    [client connectWithHost:@SITEWHERE_MESSAGE_BROKER_HOST port:SITEWHERE_MESSAGE_BROKER_PORT];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Registering device...";
}


#pragma SiteWhereMessageClientDelegate

-(void) onConnectedToSiteWhere {
    dispatch_async(dispatch_get_main_queue(), ^{
        SiteWhereMessageClient* client = [SiteWhereMessageClient sharedPlatform];
    
        // send connected alert to sitewhere
        [client sendDeviceAlertWithHardwareId:[client getUniqueDeviceId] type:@"sitewhere.connected" message:@"Connected to SiteWhere." specificationToken:@"9f2426bd-46de-49d6-833e-385784a9dc1a" originator:nil siteToken:@"bb105f8d-3150-41f5-b9d1-db04965668d3"];
        
        // register for events for the specified site
        [client registerForEventsWithTopic:@"/bb105f8d-3150-41f5-b9d1-db04965668d3"];
        
        // register device
        [client sendDeviceRegistrationWithHardwareId:[client getUniqueDeviceId] specificationToken:@"9f2426bd-46de-49d6-833e-385784a9dc1a" originator:nil siteToken:@"bb105f8d-3150-41f5-b9d1-db04965668d3"];
    });
}

-(void) onDisconnectedFromSiteWhere {
    // send disconnected alert to sitewhere
    SiteWhereMessageClient* client = [SiteWhereMessageClient sharedPlatform];
    [client sendDeviceAlertWithHardwareId:[client getUniqueDeviceId] type:@"sitewhere.disconnected" message:@"Disconnected to SiteWhere." specificationToken:@"9f2426bd-46de-49d6-833e-385784a9dc1a" originator:nil siteToken:@"bb105f8d-3150-41f5-b9d1-db04965668d3"];
}

-(void) onReceivedDeviceRegistrationCommand:(DeviceRegistrationAckState)state errorMessage:(NSString *)errorMessage {
    switch (state) {
        case DeviceRegistrationAckStateRegistrationError:
            NSLog(@"Device registration error: %@", errorMessage);
            break;
        case DeviceRegistrationAckStateAlreadyRegistered:
            break;
            
        case DeviceRegistrationAckStateNewRegistration:
            break;
            
        default:
            break;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
}

- (void)onReceivedCustomCommand:(NSData *)payload {
    
}

- (void)onReceivedEventMessage:(NSString *)topic payload:(NSData *)payload {
    NSLog(@"Recevied event message");
    NSLog(@"Topic: %@ Data:%@", topic, [[NSString alloc] initWithData:payload encoding:NSUTF8StringEncoding]);
}

- (void)onReceivedSystemCommand:(NSData *)payload {
    
    
}


#pragma CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"Locations: %@",locations);
    
    CLLocation* location = [locations lastObject];
    
    self.latitudeLabel.text = [NSString stringWithFormat:@"%f",location.coordinate.latitude];
    self.longitudeLabel.text = [NSString stringWithFormat:@"%f",location.coordinate.longitude];
    self.altitudeLabel.text = [NSString stringWithFormat:@"%f",location.altitude];
}

-(void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorized) {
        [locationManager startUpdatingLocation];
        
        SiteWhereMessageClient* client = [SiteWhereMessageClient sharedPlatform];
        [client sendDeviceAlertWithHardwareId:[client getUniqueDeviceId] type:@"location.started" message:@"Started to read location data." specificationToken:@"9f2426bd-46de-49d6-833e-385784a9dc1a" originator:nil siteToken:@"bb105f8d-3150-41f5-b9d1-db04965668d3"];
        
    } else if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusNotDetermined || status == kCLAuthorizationStatusRestricted) {
        
    }
}


#pragma helper method for MotionManager block code

- (void)motionManager:(CMMotionManager*)manager didUpdateAccelerometerData:(CMAccelerometerData*)accelerometerData {
    //NSLog(@"Accelerometer: %@",accelerometerData);
    
    self.rotxLabel.text = [NSString stringWithFormat:@"%f",accelerometerData.acceleration.x];
    self.rotyLabel.text = [NSString stringWithFormat:@"%f",accelerometerData.acceleration.y];
    self.rotzLabel.text = [NSString stringWithFormat:@"%f",accelerometerData.acceleration.z];
}

-(void) onTick {
    SiteWhereMessageClient* client = [SiteWhereMessageClient sharedPlatform];
    
    CLLocation* currentLocation = locationManager.location;
    if (currentLocation != nil) {
        [client sendDeviceLocationWithHardwareId:[client getUniqueDeviceId] latitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude altitude:currentLocation.altitude specificationToken:@"d2604433-e4eb-419b-97c7-88efe9b2cd41" originator:nil siteToken:@"bb105f8d-3150-41f5-b9d1-db04965668d3"];
    }
    
    CMAccelerometerData* accelerometerData = motionManager.accelerometerData;
    if (accelerometerData != nil) {
        NSMutableDictionary* measurements = [NSMutableDictionary dictionary];
        [measurements setValue:[NSNumber numberWithFloat:accelerometerData.acceleration.x] forKey:@"x.rotation"];
        [measurements setValue:[NSNumber numberWithFloat:accelerometerData.acceleration.y] forKey:@"y.rotation"];
        [measurements setValue:[NSNumber numberWithFloat:accelerometerData.acceleration.z] forKey:@"z.rotation"];
        
        [client sendDeviceMeasurmentsWithHardwareId:[client getUniqueDeviceId] measurements:measurements specificationToken:@"d2604433-e4eb-419b-97c7-88efe9b2cd41" originator:nil siteToken:@"bb105f8d-3150-41f5-b9d1-db04965668d3"];
    }
}
@end
