//
//  SiteWhereMessageClient.m
//  SiteWhereSDK
//
//  Created by Chris Bick on 11/25/15.
//  Copyright © 2015 SiteWhere. All rights reserved.
//

#import "SiteWhereMessageClient.h"
#import "Sitewhere.pbobjc.h"
#import "MQTTKit.h"
#import "DeviceUID.h"

static SiteWhereMessageClient *_instance = nil;

/** Topic name for outbound messages */
static NSString* OUTBOUND_TOPIC = @"SiteWhere/input/protobuf";

/** Topic prefix for inbound system messages */
static NSString* SYSTEM_TOPIC_PREFIX = @"SiteWhere/system/";

/** Topic prefix for inbound command messages */
static NSString* COMMAND_TOPIC_PREFIX = @"SiteWhere/commands/";

@interface SiteWhereMessageClient()

@property (nonatomic, strong) MQTTClient* mqttClient;

@end
@implementation SiteWhereMessageClient
@synthesize mqttClient, delegate;

+ (SiteWhereMessageClient *)sharedPlatform
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[SiteWhereMessageClient alloc] init];
        _instance.mqttClient = [[MQTTClient alloc] initWithClientId:[[NSUUID UUID]UUIDString]];
    });
    
    return _instance;
}

-(void) connectWithHost:(NSString*)host port:(short)port {
    mqttClient.host = host;
    mqttClient.port = port;
    
    __unsafe_unretained typeof(self) weakSelf = self;
    [mqttClient setMessageHandler:^(MQTTMessage *message) {
        NSString* topic = message.topic;
        if ([topic hasPrefix:SYSTEM_TOPIC_PREFIX]) {
            GPBCodedInputStream* codedStream = [GPBCodedInputStream streamWithData:message.payload];
            SiteWhere_Header* header = [SiteWhere_Header parseDelimitedFromCodedInputStream:codedStream extensionRegistry:nil error:nil];
            switch (header.command) {
                case Device_Command_AckRegistration: {
                    Device_RegistrationAck* ack = [Device_RegistrationAck parseDelimitedFromCodedInputStream:codedStream extensionRegistry:nil error:nil];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.delegate onReceivedDeviceRegistrationCommand:(DeviceRegistrationAckState)ack.state errorMessage:ack.errorMessage];
                    });
                }
            }
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.delegate onReceivedEventMessage:topic payload:message.payload];
             });
        }
    }];
    
    [mqttClient disconnectWithCompletionHandler:^(NSUInteger code) {
        NSLog(@"MQTT Disconnect");
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate onDisconnectedFromSiteWhere];
        });
    }];
    
    [mqttClient connectWithCompletionHandler:^(MQTTConnectionReturnCode code) {
        [weakSelf.mqttClient subscribe:[NSString stringWithFormat:@"%@+",SYSTEM_TOPIC_PREFIX] withCompletionHandler:^(NSArray *grantedQos) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate onConnectedToSiteWhere];
            });
        }];
    }];

}

-(void) disconnect {
    [mqttClient disconnectWithCompletionHandler:^(NSUInteger code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate onDisconnectedFromSiteWhere];
         });
    }];
}

-(void) sendDeviceRegistrationWithHardwareId:(NSString*)hardwareId specificationToken:(NSString*)specificationToken originator:(NSString*)originator siteToken:(NSString*)siteToken {
    
    SiteWhere_RegisterDevice* rb = [[SiteWhere_RegisterDevice alloc] init];
    [rb setHardwareId:hardwareId];
    [rb setSpecificationToken:specificationToken];
    if (siteToken != nil) {
        [rb setSiteToken:siteToken];
    }
    
    [self sendMessage:SiteWhere_Command_SendRegistration message:rb originator:originator label:@"registration"];
}

-(void) sendDeviceLocationWithHardwareId:(NSString*)hardwareId latitude:(double)latitude longitude:(double)longitude altitude:(double)altitude specificationToken:(NSString*)specificationToken originator:(NSString*)originator siteToken:(NSString*)siteToken {
    
    Model_DeviceLocation* deviceLocation = [[Model_DeviceLocation alloc] init];
    [deviceLocation setHardwareId:hardwareId];
    [deviceLocation setLatitude:latitude];
    [deviceLocation setLongitude:longitude];
    [deviceLocation setElevation:altitude];
    
    [self sendMessage:SiteWhere_Command_SendDeviceLocation message:deviceLocation originator:originator label:@"location"];
}

-(void) sendDeviceMeasurmentsWithHardwareId:(NSString*)hardwareId measurements:(NSDictionary*)measurements specificationToken:(NSString*)specificationToken originator:(NSString*)originator siteToken:(NSString*)siteToken {
    
    Model_DeviceMeasurements* deviceMeasurements = [[Model_DeviceMeasurements alloc] init];
    [deviceMeasurements setHardwareId:hardwareId];
    NSMutableArray* measurementArray = [NSMutableArray array];
    for (NSString* key in measurements) {
        Model_Measurement* measurement = [[Model_Measurement alloc] init];
        [measurement setMeasurementId:key];
        [measurement setMeasurementValue:[[measurements valueForKey:key] doubleValue]];
        [measurementArray addObject:measurement];
    }
    [deviceMeasurements setMeasurementArray:measurementArray];
    
    [self sendMessage:SiteWhere_Command_SendDeviceMeasurements message:deviceMeasurements originator:originator label:@"measurements"];
}

-(void) sendDeviceAlertWithHardwareId:(NSString*)hardwareId type:(NSString*)type message:(NSString*)message specificationToken:(NSString*)specificationToken originator:(NSString*)originator siteToken:(NSString*)siteToken {
    
    Model_DeviceAlert* deviceAlert = [[Model_DeviceAlert alloc]init];
    [deviceAlert setHardwareId:hardwareId];
    [deviceAlert setAlertType:type];
    [deviceAlert setAlertMessage:message];
    
    [self sendMessage:SiteWhere_Command_SendDeviceAlert message:deviceAlert originator:originator label:@"alert"];
}

-(void) sendMessage:(SiteWhere_Command) command message:(GPBMessage*) message originator:(NSString*)originator
              label:(NSString*)label {
    
    NSOutputStream* outputStream = [NSOutputStream outputStreamToMemory];
    GPBCodedOutputStream* codedOut = [GPBCodedOutputStream streamWithOutputStream:outputStream];
    SiteWhere_Header* header = [[SiteWhere_Header alloc]init];
    [header setCommand:command];
    if (originator != nil) {
        [header setOriginator:originator];
    }
    [header writeDelimitedToCodedOutputStream:codedOut];
    [message writeDelimitedToCodedOutputStream:codedOut];
    [codedOut flush];
    
    /*
        byte[] encoded = out.toByteArray();
        StringBuffer hex = new StringBuffer();
        for (byte current : encoded) {
            hex.append(String.format("%02X ", current));
            hex.append(" ");
        }
        Log.d(TAG, hex.toString());
     */
    
    NSData* data = [outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [self sendCommand:data];
    
}

-(void) registerForEventsWithTopic:(NSString*)topic {
    [mqttClient subscribe:topic withQos:ExactlyOnce completionHandler:^(NSArray *grantedQos) {
        
    }];
}

-(void) sendCommand:(NSData*)payload {
    [mqttClient publishData:payload toTopic:OUTBOUND_TOPIC withQos:ExactlyOnce retain:NO completionHandler:^(int mid) {
        
    }];
}

-(NSString*) getUniqueDeviceId {
    return [DeviceUID uid];
}

@end
