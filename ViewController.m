//
//  ViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 16.01.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "Connection.h"
#import "UserSessionVO.h"
#import "CXHTMLDocument.h"
#import "CXMLNode.h"

@interface ViewController ()
{
    WFSensorConnection *_sensorConnection;
    WFSensorType_t _sensorType;
    BOOL _isCollection;
    UserSessionVO *_userSession;
}

@property (nonatomic, weak) IBOutlet UIButton *blueHRButton;
@property (nonatomic, weak) IBOutlet UILabel *bmpLabel;
@property (nonatomic, weak) IBOutlet UILabel *batteryLevelLabel;


@end

@implementation ViewController

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    dispatcher = [[PdDispatcher alloc]init];
    [PdBase setDelegate:dispatcher];
    patch = [PdBase openFile:@"tuner.pd"
                        path:[[NSBundle mainBundle] resourcePath]];
    if (!patch) {
        NSLog(@"Failed to open patch!"); // Gracefully handle failure...
    }
    
    // Create user session
    _userSession = [[UserSessionVO alloc] init];
    //    userSession.udid = [[UIDevice currentDevice] uniqueIdentifier];
    //    [self addUserSession];
}

-(void)viewDidUnload {
    [super viewDidUnload]; [PdBase closeFile:patch]; [PdBase setDelegate:nil];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark - Convient methods

- (void)startUpdates
{
    [_userSession createMotionStorage];
    
    // Start motion updates
    NSTimeInterval updateInterval = 0.01; // 100hz
    CMMotionManager *motionManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedMotionManager];
    
    if ([motionManager isDeviceMotionAvailable] == YES) {
        [motionManager setDeviceMotionUpdateInterval:updateInterval];
        [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical toQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *deviceMotion, NSError *error) {
            if ([[_userSession appendMotionData:deviceMotion] isEqualToString:@"HS"]) {
                NSLog(@"Play sound");
                //TODO: (nh) Play sound
                //TODO: (nh) Add pd
            }
        }];
    }
    
    // Start location updates
    CLLocationManager *locationManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedLocationManager];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
    [locationManager startUpdatingLocation];
}

- (void)stopUpdates
{
    // Stop motion updates
    CMMotionManager *motionManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedMotionManager];
    if ([motionManager isDeviceMotionActive] == YES) {
        [motionManager stopDeviceMotionUpdates];
    }
    
    // Stop location updates
    CLLocationManager *locationManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedLocationManager];
    [locationManager stopUpdatingLocation];
    
    [_userSession seriliazeAndZipMotionData];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Great job!", @"Great job!")
                                                    message:NSLocalizedString(@"Motion Data has been locally saved." , @"Motion Data has been locally saved.")
                                                   delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                          otherButtonTitles:nil];
    
    [alert show];
    NSLog(@"# Motion Data has been locally saved");
}

#pragma mark -
#pragma mark - IBActions

- (IBAction)startStopCollection:(id)sender
{
    _isCollection = !_isCollection;
    
    UIButton *startStopCollectionButton = (UIButton *)sender;
    
    if (_isCollection) {
        [startStopCollectionButton setTitle:@"stop" forState:0];
        [self startUpdates];
    } else {
        [startStopCollectionButton setTitle:@"start" forState:0];
        [self stopUpdates];
    }
}

- (IBAction)connectDisconnectSensor:(id)sender
{
    if (_sensorConnection.connectionStatus == WF_SENSOR_CONNECTION_STATUS_IDLE) {
        [self initSensorConnection];
    } else {
        [self disconnectSensor];
    }
}

-(void)playNote:(int)n{
    [PdBase sendFloat:n toReceiver:@"midinote"];
    [PdBase sendBangToReceiver:@"trigger"];
    
}

- (IBAction)playE:(id)sender{
    NSLog(@"Playing E");
    [self playNote:40];
}

-(IBAction)playG:(id)sender {
    NSLog(@"Playing G");
    [self playNote:55];
}

#pragma mark -
#pragma mark - Sensor connection

- (void)initSensorConnection
{
    [_userSession createHrStorage];
    
    // Register for HW connector notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSensorData) name:WF_NOTIFICATION_SENSOR_HAS_DATA object:nil];
    
    WFHardwareConnector *hardwareConnector = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedHardwareConnector];
    _sensorType = WF_SENSORTYPE_HEARTRATE;
    _sensorConnection = nil;
    if (hardwareConnector.isCommunicationHWReady) {
        
        // Check for an existing connection to this sensor type
        NSArray *connections = [hardwareConnector getSensorConnections:_sensorType];
        WFSensorConnection *sensor = ([connections count] > 0) ? (WFSensorConnection *) [connections objectAtIndex:0] : nil;
        
        // If a connection exists, cache it and set the delegate to this instance (this will allow receiving connection state changes)
        _sensorConnection = sensor;
        if (sensor) {
            _sensorConnection.delegate = self;
        }
    }
    [self connectSensor];
}

- (void)connectSensor
{
	// Get the current connection status
	WFSensorConnectionStatus_t connectionStatus = WF_SENSOR_CONNECTION_STATUS_IDLE;
	if (_sensorConnection != nil) {
		connectionStatus = _sensorConnection.connectionStatus;
	}
	if(connectionStatus == WF_SENSOR_CONNECTION_STATUS_IDLE) {
			
        // Get the connection params
        WFHardwareConnector *hardwareConnector = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedHardwareConnector];
        WFConnectionParams *params = [hardwareConnector.settings connectionParamsForSensorType:_sensorType];
        if (params != nil) {
            
            // Set the search timeout
            params.searchTimeout = hardwareConnector.settings.searchTimeout;
            
            
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
            dispatch_async(queue,^{
                while (_sensorConnection == nil) {
                    _sensorConnection = [hardwareConnector requestSensorConnection:params];
                }
                
                // Set delegate to receive connection status changes
                _sensorConnection.delegate = self;
            });
        }
    }
}

- (void)disconnectSensor
{
    if (_sensorConnection.connectionStatus == WF_SENSOR_CONNECTION_STATUS_CONNECTED || _sensorConnection.connectionStatus == WF_SENSOR_CONNECTION_STATUS_CONNECTING) {
        [_sensorConnection disconnect];
    }
    
    [_userSession seriliazeAndZipHrData];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Great job!", @"Great job!")
                                                    message:NSLocalizedString(@"HR Data has been locally saved." , @"HR Data has been locally saved.")
                                                   delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                          otherButtonTitles:nil];
    
    [alert show];
    NSLog(@"# HR Data has been locally saved");
}

- (void)updateSensorData
{
    if ([_sensorConnection isKindOfClass:[WFHeartrateConnection class]]) {
        WFHeartrateConnection *hrConnection = (WFHeartrateConnection *)_sensorConnection;
        WFHeartrateData *hrData = [hrConnection getHeartrateData];
        WFHeartrateRawData *hrRawData = [hrConnection getHeartrateRawData];
        if (hrData != nil) {
//            NSLog("---- HR Data ----");
//???: (sb) Always nil
//            NSLog("# Beat time: %d", hrData.beatTime);
//            NSLog("# Computed heartrate: %d", hrData.computedHeartrate);
//            NSLog("# Accum beat count: %d", hrData.accumBeatCount);
//            NSLog("# Timestamp: %f", hrData.timestamp);
//            NSLog("# Timestamp overflow: %@", hrData.timestampOverflow ? @"YES" : @"NO");
//            NSLog("# Formatted heartrate: %@", [hrData formattedHeartrate:YES]);
            
            _bmpLabel.text = [hrData formattedHeartrate:YES];
        }
//???: (sb) Always nil
//        if (hrRawData) {
//            NSLog("---- HR Raw Data ----");
//            NSLog("# R Beat time: %d", hrRawData.beatTime);
//            NSLog("# R Beat count: %d", hrRawData.beatCount);
//            NSLog("# R Computed heartrate: %d", hrRawData.computedHeartrate);
//            NSLog("# R Previous beat time: %d", hrRawData.previousBeatTime);
//        }
        
        // BTLE HR monitors optionally transmit R-R intervals. this demo does not
        // display R-R values.  however, the following code is included to demonstrate
        // how to read and parse R-R intervals.
        if ([hrData isKindOfClass:[WFBTLEHeartrateData class]]) {
            NSArray* rrIntervals = [(WFBTLEHeartrateData*)hrData rrIntervals];
            for (NSNumber* rrInterval in rrIntervals) {
//                NSLog("---- RR Data ----");
                NSLog(@"# R-R interval: %1.3f s.", [rrInterval doubleValue]);
            }
        }
        
        // the common data for BTLE sensors is still in beta state.  this data
        // will eventually be merged with the existing common data.  for current demo
        // purposes, the battery level is updated directly from this HR view controller.
        if (hrRawData.btleCommonData) {
//            NSLog("---- BTLE Common Data ----");
//            NSLog(@"# Battery level: %@", [NSString stringWithFormat:@"# %u %%", hrRawData.btleCommonData.batteryLevel]);
            dispatch_async(dispatch_get_main_queue(), ^{
                _batteryLevelLabel.text = [NSString stringWithFormat:@"%u %%", hrRawData.btleCommonData.batteryLevel];
            });
        }
        [_userSession appendHrData:hrData];
    }
    else {
        NSLog(@"# n/a");
        _bmpLabel.text = @"n/a";
        _batteryLevelLabel.text = @"n/a";
    }
}

#pragma mark -
#pragma mark - SensorConnectionDelegate implementation

- (void)connectionDidTimeout:(WFSensorConnection*)connectionInfo
{
    NSLog(@"# Timeout of %@", connectionInfo.deviceUUIDString);
}

- (void)connection:(WFSensorConnection*)connectionInfo stateChanged:(WFSensorConnectionStatus_t)connState
{
    switch (connState) {
        case WF_SENSOR_CONNECTION_STATUS_IDLE:
            [_blueHRButton setTitle:@"Connect BlueHR" forState:0];
            break;
            
        case WF_SENSOR_CONNECTION_STATUS_CONNECTED:
            [_blueHRButton setTitle:@"Disconnect BlueHR" forState:0];
            break;
        
        case WF_SENSOR_CONNECTION_STATUS_CONNECTING:
            [_blueHRButton setTitle:@"Connecting ..." forState:0];
            break;
            
        case WF_SENSOR_CONNECTION_STATUS_DISCONNECTING:
            [_blueHRButton setTitle:@"Disconnecting ..." forState:0];
            break;
            
        case WF_SENSOR_CONNECTION_STATUS_INTERRUPTED: {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"State changed to Interrupted" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
            break;
            
        default:
            break;
    }
}

//???: (sb) Unused code
//#pragma mark -
//#pragma mark - Server connection
//
//- (void)addUserSession
//{
//    void (^completionHandler)(NSURLResponse*, NSData*, NSError*) = ^(NSURLResponse *response, NSData *data, NSError *error) {
//        if ([data length] > 0 && error == nil) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                CXMLDocument *doc = [[CXMLDocument alloc] initWithData:data options:0 error:nil];
//                NSArray *nodes = nil;
//                
//                // Error case
//                nodes = [doc nodesForXPath:@"/response/objects/Error/id" error:nil];
//                if ([nodes count] > 0) {
//                    
//                    // Feedback
//                    int errorId = [[[nodes[0] childAtIndex:0] stringValue] intValue];
//                    UIAlertView *alert;
//                    switch (errorId) {
//                        case 4:
//                            alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"User session", @"User session")
//                                                               message:NSLocalizedString(@"User session has not been saved.", @"User session has not been saved.")
//                                                              delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
//                                                     otherButtonTitles:nil];
//                            NSLog(@"# User session has not been saved (add user session).");
//                            break;
//                        default:
//                            alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
//                                                               message:NSLocalizedString(@"Unknown error" , @"Unknown error")
//                                                              delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
//                                                     otherButtonTitles:nil];
//                            NSLog(@"# Unknown error (add user session)");
//                            break;
//                    }
//                    [alert show];
//                    return;
//                }
//                
//                // Completed successfully
//                nodes = [doc nodesForXPath:@"/response/objects/UserSession" error:nil];
//                
//                if ([nodes count] > 0) {
//                    NSMutableDictionary *propertyDictionary = [[NSMutableDictionary alloc] init];
//                    int counter;
//                    for(counter = 0; counter < [nodes[0] childCount]; counter++) {
//                        
//                        //  common procedure: dictionary with keys/values from XML node
//                        propertyDictionary[[[nodes[0] childAtIndex:counter] name]] = [[nodes[0] childAtIndex:counter] stringValue];
//                    }
//                    [userSession setWithPropertyDictionary:propertyDictionary];
//                }
//            });
//        } else {
//            if ([data length] == 0 && error == nil) {
//                NSLog(@"# Nothing was downloaded (add user session)");
//            } else {
//                if (error != nil) {
//                    NSLog(@"# Error happened (add user session) = %@", error);
//                }
//            }
//        }
//    };
//    
//    // Server request (add user session)
//    Connection *connection = [[Connection alloc] initWithHost:@"http://galow.flow-maschinen.de/"];
//    [connection aAddWithControllerPath:@"user_sessions" bodyAsString:[userSession xmlRepresentation] completionHandler:completionHandler];
//}
//
//- (void)attachZipFile
//{
//    void (^completionHandler)(NSURLResponse*, NSData*, NSError*) = ^(NSURLResponse *response, NSData *data, NSError *error) {
//        if ([data length] > 0 && error == nil) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                CXMLDocument *doc = [[CXMLDocument alloc] initWithData:data options:0 error:nil];
//                NSArray *nodes = nil;
//                nodes = [doc nodesForXPath:@"/response/objects/Error/id" error:nil];
//                if ([nodes count] > 0) {
//                    
//                    // Feedback
//                    int errorId = [[[nodes[0] childAtIndex:0] stringValue] intValue];
//                    UIAlertView *alert;
//                    switch (errorId) {
//                        case 5:
//                            alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"User session", @"User session")
//                                                               message:NSLocalizedString(@"User session has not been saved.", @"User session has not been saved.")
//                                                              delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
//                                                     otherButtonTitles:nil];
//                            NSLog(@"# User session has not been saved (attach zip file).");
//                            break;
//                        default:
//                            alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
//                                                               message:NSLocalizedString(@"Unknown error" , @"Unknown error")
//                                                              delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
//                                                     otherButtonTitles:nil];
//                            NSLog(@"# Unknown error (attach zip file)");
//                            break;
//                    }
//                    [alert show];
//                    return;
//                }
//                
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"User session", @"User session")
//                                                                message:NSLocalizedString(@"User session has been saved." , @"User session has been saved.")
//                                                               delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
//                                                      otherButtonTitles:nil];
//                [alert show];
//                NSLog(@"# User session has been saved.");
//            });
//        }
//    };
//    
//    // Attach zip file
//    NSData *data = [userSession seriliazeAndZip];
//    
//    if(data != nil) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Great job!", @"Great job!")
//                                                        message:NSLocalizedString(@"Data has been locally saved." , @"Data has been locally saved.")
//                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
//                                              otherButtonTitles:nil];
//        NSLog(@"# Data has been locally saved");
//        [alert show];
//        
//        // Server request (attach zip file)
//        Connection *connection = [[Connection alloc] initWithHost:@"http://galow.flow-maschinen.de/"];
//        [connection aAttachFileWithControllerPath:[NSString stringWithFormat:@"user_sessions/%lu", [userSession.objectId unsignedLongValue]] fileAsData:data contentDispositionName:@"data[UserSession][zip]" contentType:@"application/zip" completionHandler:completionHandler];
//    } else {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Damn!", @"Damn!")
//                                                        message:NSLocalizedString(@"Data has not been saved." , @"Data has not been saved.")
//                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
//                                              otherButtonTitles:nil];
//        [alert show];
//    }
//}

@end
