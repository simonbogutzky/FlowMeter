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
//#import "CXHTMLDocument.h"
//#import "CXMLNode.h"
#import "PdDispatcher.h"
#import "Reachability.h"


@interface ViewController ()
{
    WFSensorConnection *_sensorConnection;
    WFSensorType_t _sensorType;
    BOOL _isCollection;
    UserSessionVO *_userSession;
    
    PdDispatcher *_dispatcher;
    void *_patch;
    int _lastAccumBeatCount;
    
    DBRestClient *_restClient;
    
    IBOutlet UIButton *_blueHRButton;
    IBOutlet UILabel *_bmpLabel;
    IBOutlet UILabel *_batteryLevelLabel;
    
    Reachability *_internetReachable;
}


@end

@implementation ViewController

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _dispatcher = [[PdDispatcher alloc]init];
    [PdBase setDelegate:_dispatcher];
    _patch = [PdBase openFile:@"tuner.pd"
                        path:[[NSBundle mainBundle] resourcePath]];
    if (!_patch) {
        NSLog(@"Failed to open patch!"); // Gracefully handle failure...
    }
    
    // Create user session
    _userSession = [[UserSessionVO alloc] init];
    //    userSession.udid = [[UIDevice currentDevice] uniqueIdentifier];
    //    [self addUserSession];
    
    [self testInternetConnection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadFile:) name:@"MotionDataReady" object:nil];
}

//??? (nh) won't be used
//-(void)viewDidUnload {
//    [super viewDidUnload];
//    [PdBase closeFile:_patch];
//    [PdBase setDelegate:nil];
//}

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
            if ([[_userSession appendMotionData2:deviceMotion] isEqualToString:@"HS"]) {
                [self playE:self];
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
        [_userSession createHrStorage];
    } else {
        [startStopCollectionButton setTitle:@"start" forState:0];
        [self stopUpdates];
        
        [_userSession seriliazeAndZipMotionData];
        
        if ([_userSession hrCount] != 0)
        {
            [_userSession seriliazeAndZipHrData];
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Great job!", @"Great job!")
                                                        message:NSLocalizedString(@"Data has been locally saved." , @"Data has been locally saved.")
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                              otherButtonTitles:nil];
        
        [alert show];
        NSLog(@"# Data has been locally saved");
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

- (IBAction)playE:(id)sender
{
    [self playNote:90];
}

- (IBAction)playG:(id)sender
{
    [self playNote:55];
    [self didPressLink];
}

#pragma mark - Convenient methods
#pragma mark - 

- (void)playNote:(int)n
{
    [PdBase sendFloat:n toReceiver:@"midinote"];
    [PdBase sendBangToReceiver:@"trigger"];
    
}

// Checks if we have an internet connection or not
- (void)testInternetConnection
{
    _internetReachable = [Reachability reachabilityWithHostname:@"www.google.com"];
    
    // Internet is reachable
    _internetReachable.reachableBlock = ^(Reachability*reach)
    {
        // Update the UI on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Yayyy, we have the interwebs!");
        });
    };
    
    // Internet is not reachable
    _internetReachable.unreachableBlock = ^(Reachability*reach)
    {
        // Update the UI on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Someone broke the internet :(");
        });
    };
    
    if([_internetReachable startNotifier])
        NSLog(@"Internet");
    else
        NSLog(@"No Internet");
}

#pragma mark -
#pragma mark - Sensor connection

- (void)initSensorConnection
{
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
    
    _lastAccumBeatCount = 0;
}

- (void)disconnectSensor
{
    if (_sensorConnection.connectionStatus == WF_SENSOR_CONNECTION_STATUS_CONNECTED || _sensorConnection.connectionStatus == WF_SENSOR_CONNECTION_STATUS_CONNECTING) {
        [_sensorConnection disconnect];
    }
}

- (void)updateSensorData
{
    if ([_sensorConnection isKindOfClass:[WFHeartrateConnection class]]) {
        WFHeartrateConnection *hrConnection = (WFHeartrateConnection *)_sensorConnection;
        WFHeartrateData *hrData = [hrConnection getHeartrateData];
        WFHeartrateRawData *hrRawData = [hrConnection getHeartrateRawData];
        if (hrData != nil) {
            _bmpLabel.text = [hrData formattedHeartrate:YES];
            
            if (_lastAccumBeatCount < hrData.accumBeatCount) {
                // Sonify beat
                [self playE:self];
                
                _lastAccumBeatCount = hrData.accumBeatCount;
            }
            
            // Debug logs
            NSLog(@"# beatTime: %d", hrData.beatTime);
            NSLog(@"# accumBeatCount: %d", hrData.accumBeatCount);

            NSLog(@"# rawBeatTime: %d", hrRawData.beatTime);
            NSLog(@"# rawAccumBeatCount: %d", hrRawData.beatCount);
            
            NSLog(@"# previousBeatTime: %d", hrRawData.previousBeatTime);
            
            NSArray* rrIntervals = [(WFBTLEHeartrateData*)hrData rrIntervals];
            
            for (NSNumber *rrInterval in rrIntervals) {
                NSLog(@"# rrInterval: %f", [rrInterval doubleValue]);
            }
            
            if(_isCollection) {
                [_userSession appendHrData:hrData];
            }
        }
        
        if (hrRawData.btleCommonData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _batteryLevelLabel.text = [NSString stringWithFormat:@"%u %%", hrRawData.btleCommonData.batteryLevel];
            });
        }
        
    }
    else {
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
            _bmpLabel.text = @"n/a";
            _batteryLevelLabel.text = @"n/a";
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

#pragma mark -
#pragma mark - Dropbox convenient methods

- (void)didPressLink
{
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
    }
}

- (DBRestClient *)restClient {
    if (!_restClient) {
        _restClient =
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

- (void)uploadFile:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    
    NSString *localPath = [userInfo objectForKey:@"localPath"];
    NSString *fileName = [userInfo objectForKey:@"fileName"];
    NSString *destDir = @"/";
    
    [[self restClient] uploadFile:fileName toPath:destDir withParentRev:nil fromPath:localPath];
}

#pragma mark -
#pragma mark - DBRestClientDelegate methods

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata
{
    NSLog(@"# File uploaded successfully to path: %@", metadata.path);
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    NSLog(@"# File upload failed with error - %@", error);
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
