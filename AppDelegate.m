//
//  AppDelegate.m
//  DataCollector
//
//  Created by Simon Bogutzky on 16.01.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "AppDelegate.h"
#import "Utility.h"
#import "PdAudioController.h"
#import <DropboxSDK/DropboxSDK.h>

@interface AppDelegate ()
{
    CMMotionManager *_motionManager;
    CLLocationManager *_locationManager;
    WFHardwareConnector *_hardwareConnector;
    PdAudioController *_audioController;
}
@end

@implementation AppDelegate

#pragma mark -
#pragma mark - Singletons

- (CMMotionManager *)sharedMotionManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _motionManager = [[CMMotionManager alloc] init];
    });
    return _motionManager;
}

- (CLLocationManager *)sharedLocationManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _locationManager = [[CLLocationManager alloc] init];
    });
    return _locationManager;
}

- (WFHardwareConnector *)sharedHardwareConnector
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // Configure the hardware connector.
        _hardwareConnector = [WFHardwareConnector sharedConnector];
        _hardwareConnector.delegate = self;
        _hardwareConnector.sampleRate = 0.001;  // sample rate 1 ns, or 1 kHz.
        _hardwareConnector.settings.searchTimeout = 60;
        
        // Determine support for BTLE
        if (_hardwareConnector.hasBTLESupport) {
            
            // Enable BTLE
            [_hardwareConnector enableBTLE:YES];
        } else {
            NSLog(@"# Device does not support BTLE");
        }
        
//        // Set HW Connector to call hasData only when new data is available.
//        [hardwareConnector setSampleTimerDataCheck:YES];
    });
    return _hardwareConnector;
}

#pragma mark -
#pragma mark - UIApplicationDelegate implementation

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _audioController = [[PdAudioController alloc] init];
    if ([_audioController configureAmbientWithSampleRate:44100 numberChannels:2 mixingEnabled:YES] != PdAudioOK) {
        NSLog(@"failed to initialize audio components");
    }
    
    //Testflight
//#define TESTING 1
//#ifdef TESTING
//    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
//#endif
//    
//    // TestFlight takeoff
//    [TestFlight takeOff:@"9a7d3926-e38a-4359-85f6-717248228a37"];
    
    // Dropbox
    DBSession *dbSession = [[DBSession alloc] initWithAppKey:@"tvd64fwxro7ck60" appSecret:@"2azrb93xdsddgx2" root:kDBRootAppFolder];
    [DBSession setSharedSession:dbSession];
    
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    _audioController.active = YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully!");
            // At this point you can start making API calls
        }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
}

#pragma mark -
#pragma mark - HardwareConnectorDelegate implementation

- (void)hardwareConnector:(WFHardwareConnector*)hwConnector connectedSensor:(WFSensorConnection*)connectionInfo
{
}

- (void)hardwareConnector:(WFHardwareConnector*)hwConnector didDiscoverDevices:(NSSet*)connectionParams searchCompleted:(BOOL)bCompleted
{
    // Post the sensor type and device params to the notification.
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              connectionParams, @"connectionParams",
                              [NSNumber numberWithBool:bCompleted], @"searchCompleted",
                              nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:WF_NOTIFICATION_DISCOVERED_SENSOR object:WF_NOTIFICATION_DISCOVERED_SENSOR userInfo:userInfo];
}

- (void)hardwareConnector:(WFHardwareConnector*)hwConnector disconnectedSensor:(WFSensorConnection*)connectionInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WF_NOTIFICATION_SENSOR_DISCONNECTED object:WF_NOTIFICATION_SENSOR_DISCONNECTED];
}

- (void)hardwareConnector:(WFHardwareConnector*)hwConnector stateChanged:(WFHardwareConnectorState_t)currentState
{
	BOOL connected = ((currentState & WF_HWCONN_STATE_ACTIVE) || (currentState & WF_HWCONN_STATE_BT40_ENABLED)) ? YES : NO;
	if (connected) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WF_NOTIFICATION_HW_CONNECTED object:WF_NOTIFICATION_HW_CONNECTED];
	} else {
        [[NSNotificationCenter defaultCenter] postNotificationName:WF_NOTIFICATION_HW_DISCONNECTED object:WF_NOTIFICATION_HW_DISCONNECTED];
	}
}

- (void)hardwareConnectorHasData
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WF_NOTIFICATION_SENSOR_HAS_DATA object:WF_NOTIFICATION_SENSOR_HAS_DATA];
}

@end
