//
//  ViewController.h
//  SiteWhereExample
//
//  Created by Chris Bick on 11/25/15.
//  Copyright © 2015 SiteWhere. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SiteWhereSDK/SiteWhereSDK.h>
#import <CoreLocation/CLLocationManagerDelegate.h>

@interface ViewController : UIViewController<SiteWhereMessageClientDelegate,CLLocationManagerDelegate>

@end

