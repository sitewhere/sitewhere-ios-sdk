//
//  SiteWhereMessageClient.h
//  SiteWhereSDK
//
//  Created by Chris Bick on 11/25/15.
//  Copyright © 2015 SiteWhere. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SiteWhereMessageClientDelegate.h"

@interface SiteWhereMessageClient : NSObject

+(SiteWhereMessageClient*) sharedPlatform;

-(void)     connectWithHost:(NSString*)host port:(short)port;
-(void)     disconnect;

-(void)     sendDeviceRegistrationWithHardwareId:(NSString*)hardwareId specificationToken:(NSString*)specificationToken originator:(NSString*)originator siteToken:(NSString*)siteToken;

-(void)     sendDeviceLocationWithHardwareId:(NSString*)hardwareId latitude:(double)latitude longitude:(double)longitude altitude:(double)altitude specificationToken:(NSString*)specificationToken originator:(NSString*)originator siteToken:(NSString*)siteToken;

-(void)     sendDeviceMeasurmentsWithHardwareId:(NSString*)hardwareId measurements:(NSDictionary*)measurements specificationToken:(NSString*)specificationToken originator:(NSString*)originator siteToken:(NSString*)siteToken;

-(void)     registerForEventsWithTopic:(NSString*)topic;
    
-(NSString*) getUniqueDeviceId;


@property (nonatomic, assign) id <SiteWhereMessageClientDelegate> delegate;

@end
