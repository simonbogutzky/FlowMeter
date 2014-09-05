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
#import <HeartRateMonitor/HeartRateMonitor.h>
#import <DropboxSDK/DropboxSDK.h>
#import <AVFoundation/AVAudioSession.h>
#import "Reachability.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0] 

@interface AppDelegate : UIResponder <UIApplicationDelegate, DBRestClientDelegate, NSStreamDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) HeartRateMonitorManager *heartRateMonitorManager;
@property (readonly, strong, nonatomic) DBRestClient *dbRestClient;
@property (readonly, strong, nonatomic) Reachability *reachability;

- (void)saveContext;
- (NSString *)userDirectory;
@end
