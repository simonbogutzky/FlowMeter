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
    WFHardwareConnector *hardwareConnector;
    WFSensorConnection *sensorConnection;
    BOOL isCollection;
    UserSessionVO *userSession;
	WFSensorType_t sensorType;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    hardwareConnector = [WFHardwareConnector sharedConnector];
    sensorType = WF_SENSORTYPE_HEARTRATE;
    sensorConnection = nil;
    
    // initialize the display based on HW connector and sensor state.
    if (hardwareConnector.isCommunicationHWReady)
    {
        // Check for an existing connection to this sensor type.
        NSArray *connections = [hardwareConnector getSensorConnections:sensorType];
        WFSensorConnection *sensor = ([connections count] > 0) ? (WFSensorConnection *) [connections objectAtIndex:0] : nil;
        
        // If a connection exists, cache it and set the delegate to this instance (this will allow receiving connection state changes).
        sensorConnection = sensor;
        if (sensor)
        {
            sensorConnection.delegate = self;
        }
        
        // Log status
        [self logStatus];
    }
    
    // Register for HW connector notifications.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logStatus) name:WF_NOTIFICATION_HW_CONNECTED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logStatus) name:WF_NOTIFICATION_HW_DISCONNECTED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logStatus) name:WF_NOTIFICATION_SENSOR_HAS_DATA object:nil];
    
    [self connectSensor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)startUpdates
{
    userSession = [[UserSessionVO alloc] init];
    userSession.udid = [[UIDevice currentDevice] uniqueIdentifier];
//    [self addUserSession];
    
    NSTimeInterval updateInterval = 0.01; // 100hz
    CMMotionManager *motionManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedMotionManager];
    
    if ([motionManager isDeviceMotionAvailable] == YES) {
        [motionManager setDeviceMotionUpdateInterval:updateInterval];
        [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical toQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *deviceMotion, NSError *error) {
            [userSession appendMotionData:deviceMotion];
        }];
    }
    
    CLLocationManager *locationManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedLocationManager];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
    [locationManager startUpdatingLocation];
}

- (void)stopUpdates
{
    CMMotionManager *motionManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedMotionManager];
    
    if ([motionManager isDeviceMotionActive] == YES) {
        [motionManager stopDeviceMotionUpdates];
    }
    
    [self attachZipFile];
    
    CLLocationManager *locationManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedLocationManager];
    [locationManager stopUpdatingLocation];
}

- (IBAction)startStopCollection:(id)sender
{
    isCollection = !isCollection;
    
    UIButton *startStopCollectionButton = (UIButton *)sender;
    
    if (isCollection) {
        [startStopCollectionButton setTitle:@"stop" forState:0];
        [self startUpdates];
    } else {
        [startStopCollectionButton setTitle:@"start" forState:0];
        [self stopUpdates];
    }
}

- (void)addUserSession
{
    void (^completionHandler)(NSURLResponse*, NSData*, NSError*) = ^(NSURLResponse *response, NSData *data, NSError *error) {
        if ([data length] > 0 && error == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CXMLDocument *doc = [[CXMLDocument alloc] initWithData:data options:0 error:nil];
                NSArray *nodes = nil;
                
                // Error case
                nodes = [doc nodesForXPath:@"/response/objects/Error/id" error:nil];
                if ([nodes count] > 0) {
                    
                    // Feedback
                    int errorId = [[[nodes[0] childAtIndex:0] stringValue] intValue];
                    UIAlertView *alert;
                    switch (errorId) {
                        case 4:
                            alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"User session", @"User session")
                                                               message:NSLocalizedString(@"User session has not been saved.", @"User session has not been saved.")
                                                              delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                                     otherButtonTitles:nil];
                            NSLog(@"# User session has not been saved (add user session).");
                            break;
                        default:
                            alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                               message:NSLocalizedString(@"Unknown error" , @"Unknown error")
                                                              delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                                     otherButtonTitles:nil];
                            NSLog(@"# Unknown error (add user session)");
                            break;
                    }
                    [alert show];
                    return;
                }
                
                // Completed successfully
                nodes = [doc nodesForXPath:@"/response/objects/UserSession" error:nil];
                
                if ([nodes count] > 0) {
                    NSMutableDictionary *propertyDictionary = [[NSMutableDictionary alloc] init];
                    int counter;
                    for(counter = 0; counter < [nodes[0] childCount]; counter++) {
                        
                        //  common procedure: dictionary with keys/values from XML node
                        propertyDictionary[[[nodes[0] childAtIndex:counter] name]] = [[nodes[0] childAtIndex:counter] stringValue];
                    }
                    [userSession setWithPropertyDictionary:propertyDictionary];
                }
            });
        } else {
            if ([data length] == 0 && error == nil) {
                NSLog(@"# Nothing was downloaded (add user session)");
            } else {
                if (error != nil) {
                    NSLog(@"# Error happened (add user session) = %@", error);
                }
            }
        }
    };
    
    // Server request (add user session)
    Connection *connection = [[Connection alloc] initWithHost:@"http://galow.flow-maschinen.de/"];
    [connection aAddWithControllerPath:@"user_sessions" bodyAsString:[userSession xmlRepresentation] completionHandler:completionHandler];
}

- (void)attachZipFile
{
    void (^completionHandler)(NSURLResponse*, NSData*, NSError*) = ^(NSURLResponse *response, NSData *data, NSError *error) {
        if ([data length] > 0 && error == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CXMLDocument *doc = [[CXMLDocument alloc] initWithData:data options:0 error:nil];
                NSArray *nodes = nil;
                nodes = [doc nodesForXPath:@"/response/objects/Error/id" error:nil];
                if ([nodes count] > 0) {
                    
                    // Feedback
                    int errorId = [[[nodes[0] childAtIndex:0] stringValue] intValue];
                    UIAlertView *alert;
                    switch (errorId) {
                        case 5:
                            alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"User session", @"User session")
                                                               message:NSLocalizedString(@"User session has not been saved.", @"User session has not been saved.")
                                                              delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                                     otherButtonTitles:nil];
                            NSLog(@"# User session has not been saved (attach zip file).");
                            break;
                        default:
                            alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                               message:NSLocalizedString(@"Unknown error" , @"Unknown error")
                                                              delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                                     otherButtonTitles:nil];
                            NSLog(@"# Unknown error (attach zip file)");
                            break;
                    }
                    [alert show];
                    return;
                }
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"User session", @"User session")
                                                                message:NSLocalizedString(@"User session has been saved." , @"User session has been saved.")
                                                               delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                                      otherButtonTitles:nil];
                [alert show];
                NSLog(@"# User session has been saved.");
            });
        }
    };
            
    // Attach zip file
    NSData *data = [userSession seriliazeAndZip];
    
    if(data != nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Great job!", @"Great job!")
                                                        message:NSLocalizedString(@"Data has been locally saved." , @"Data has been locally saved.")
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                              otherButtonTitles:nil];
        NSLog(@"# Data has been locally saved");
        [alert show];
        
        // Server request (attach zip file)
        Connection *connection = [[Connection alloc] initWithHost:@"http://galow.flow-maschinen.de/"];
//        [connection aAttachFileWithControllerPath:[NSString stringWithFormat:@"user_sessions/%lu", [userSession.objectId unsignedLongValue]] fileAsData:data contentDispositionName:@"data[UserSession][zip]" contentType:@"application/zip" completionHandler:completionHandler];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Damn!", @"Damn!")
                                                        message:NSLocalizedString(@"Data has not been saved." , @"Data has not been saved.")
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)connectSensor
{
	// Get the current connection status.
	WFSensorConnectionStatus_t connectionStatus = WF_SENSOR_CONNECTION_STATUS_IDLE;
	if (sensorConnection != nil)
	{
		connectionStatus = sensorConnection.connectionStatus;
	}
	
	if(connectionStatus == WF_SENSOR_CONNECTION_STATUS_IDLE) {
			
        // Get the connection params
        WFConnectionParams *params = [hardwareConnector.settings connectionParamsForSensorType:sensorType];
        if (params != nil) {
            
            // Set the search timeout
            params.searchTimeout = hardwareConnector.settings.searchTimeout;
            sensorConnection = [hardwareConnector requestSensorConnection:params];

            // Set delegate to receive connection status changes
            sensorConnection.delegate = self;
        }
    }
	[self logStatus];
}

- (void)logStatus
{
	// get the current connection status.
	WFSensorConnectionStatus_t connectionStatus = WF_SENSOR_CONNECTION_STATUS_IDLE;
	if (sensorConnection != nil) {
		connectionStatus = sensorConnection.connectionStatus;
	}
	
	// set the button state based on the connection state.
	switch (connectionStatus)
	{
		case WF_SENSOR_CONNECTION_STATUS_IDLE:
			NSLog(@"Idle");
			break;
		case WF_SENSOR_CONNECTION_STATUS_CONNECTING:
			NSLog(@"Connecting ...");
			break;
		case WF_SENSOR_CONNECTION_STATUS_CONNECTED:
			NSLog(@"Connected");
			break;
		case WF_SENSOR_CONNECTION_STATUS_DISCONNECTING:
			NSLog(@"Disconnecting...");
			break;
        case WF_SENSOR_CONNECTION_STATUS_INTERRUPTED:
            break;
	}
}


@end
