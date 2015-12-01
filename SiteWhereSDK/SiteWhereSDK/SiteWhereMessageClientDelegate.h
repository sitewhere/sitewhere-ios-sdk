//
//  SiteWhereMessageClientDelegate.h
//  SiteWhereSDK
//
//  Created by Chris Bick on 11/25/15.
//  Copyright © 2015 SiteWhere. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DeviceRegistrationAckState) {
    DeviceRegistrationAckStateNewRegistration = 1,
    DeviceRegistrationAckStateAlreadyRegistered = 2,
    DeviceRegistrationAckStateRegistrationError = 3,
};
    
@protocol SiteWhereMessageClientDelegate <NSObject>

    /**
     * Called after connection to underlying messaging service is complete.
     */
    -(void) onConnectedToSiteWhere;

    /**
     * Called when connection to SiteWhere is disconnected.
     */
    -(void) onDisconnectedFromSiteWhere;

    /**
     * Called when a custom command payload is received.
     */
    - (void)onReceivedCustomCommand:(NSData *)payload;

    /**
     * Called when a custom command payload is received.
     */
    - (void)onReceivedSystemCommand:(NSData *)payload;

    /**
     * Called when a event message is received.
     *
     * @param payload
     */
    - (void)onReceivedEventMessage:(NSString *)topic payload:(NSData *)payload;

    - (void) onReceivedDeviceRegistrationCommand:(DeviceRegistrationAckState)state errorMessage:(NSString *)errorMessage;

@end
