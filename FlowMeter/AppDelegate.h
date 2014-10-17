//
//  AppDelegate.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 16.01.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import <HeartRateMonitorFramework/HeartRateMonitorFramework.h>
#import <DropboxSDK/DropboxSDK.h>
#import <AVFoundation/AVFoundation.h>
#import "Reachability.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, DBRestClientDelegate, NSStreamDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) HeartRateMonitorManager *heartRateMonitorManager;
@property (readonly, strong, nonatomic) DBRestClient *dbRestClient;
@property (readonly, strong, nonatomic) Reachability *reachability;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) id timeObserver;

- (void)saveContext;
- (NSString *)userDirectory;
@end
