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
#import <AVFoundation/AVFoundation.h>
#import <WFConnector/WFConnector.h>
#import <DropboxSDK/DropboxSDK.h>
#import "Reachability.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, WFHardwareConnectorDelegate, DBRestClientDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@property (strong, nonatomic, readonly) CMMotionManager *sharedMotionManager;
@property (strong, nonatomic, readonly) CLLocationManager *sharedLocationManager;
@property (strong, nonatomic, readonly) WFHardwareConnector *sharedHardwareConnector;
@property (strong, nonatomic, readonly) DBRestClient *sharedDbRestClient;
@property (strong, nonatomic) WFSensorConnection *wfSensorConnection;
@property (strong, nonatomic, readonly) Reachability *reachability;

@end
