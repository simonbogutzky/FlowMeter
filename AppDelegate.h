//
//  AppDelegate.h
//  DataCollector
//
//  Created by Simon Bogutzky on 16.01.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import <WFConnector/WFConnector.h>
#import "PdAudioController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, WFHardwareConnectorDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic, readonly) CMMotionManager *sharedMotionManager;
@property (strong, nonatomic, readonly) CLLocationManager *sharedLocationManager;
@property (strong, nonatomic, readonly) WFHardwareConnector *sharedHardwareConnector;
@property (strong, nonatomic, readonly) PdAudioController *audioController;

@end
