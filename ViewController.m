//
//  ViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 16.01.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "CMDeviceMotion+TransformToReferenceFrame.h"
#import "Connection.h"
#import "UserSessionVO.h"
#import "CXHTMLDocument.h"
#import "CXMLNode.h"

@interface ViewController ()
{
    NSMutableString *data;
    BOOL isCollection;
    UserSessionVO *userSession;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startUpdates
{
    [self addUserSession];
    
    data = [NSMutableString stringWithCapacity:191520141]; // 191520000 + 141 bytes for to hours of data and 2 hours overhead (one hour approx. 45mb)
    [data appendFormat:@"\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\"\n",
     @"timestamp",
     @"userAccX",
     @"userAccY",
     @"userAccZ",
     @"userWAccX",
     @"userWAccY",
     @"userWAccZ",
     @"gravityX",
     @"gravityY",
     @"gravityZ",
     @"rotRateX",
     @"rotRateY",
     @"rotRateZ",
     @"attYaw",
     @"attRoll",
     @"attPitch"
     ];
    NSTimeInterval updateInterval = 0.01; // 100hz
    CMMotionManager *motionManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedMotionManager];
    
    if ([motionManager isDeviceMotionAvailable] == YES) {
        [motionManager setDeviceMotionUpdateInterval:updateInterval];
        [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical toQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *deviceMotion, NSError *error) {
            if (error == nil) {
                [data appendFormat:@"%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
                 deviceMotion.timestamp,
                 deviceMotion.userAcceleration.x,
                 deviceMotion.userAcceleration.y,
                 deviceMotion.userAcceleration.z,
                 deviceMotion.userAccelerationInReferenceFrame.x,
                 deviceMotion.userAccelerationInReferenceFrame.y,
                 deviceMotion.userAccelerationInReferenceFrame.z,
                 deviceMotion.gravity.x,
                 deviceMotion.gravity.y,
                 deviceMotion.gravity.z,
                 deviceMotion.rotationRate.x,
                 deviceMotion.rotationRate.y,
                 deviceMotion.rotationRate.z,
                 deviceMotion.attitude.yaw,
                 deviceMotion.attitude.roll,
                 deviceMotion.attitude.pitch
                 ];
                //NSLog(@"%.2f", deviceMotion.attitude.yaw);
            } else {
                [data appendFormat:@"NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN\n"];
            }
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
    
    [self saveData];
    
    CLLocationManager *locationManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedLocationManager];
    [locationManager stopUpdatingLocation];
}

- (void)saveData
{
    
    // Create a date string of the current date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    [dateFormatter setDateFormat:@"HH-mm-ss"];
    NSString *timeString = [dateFormatter stringFromDate:[NSDate date]];
    
    // Create the path, where the data should be saved
    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *pathComponent = [NSString stringWithFormat:@"%@-t%@.csv", dateString, timeString];
    NSString *savePath = [rootPath stringByAppendingPathComponent:pathComponent];
    
    // Save the data
    NSError *error = nil;
    if([data writeToFile:savePath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Great job!", @"Great job!")
                                                        message:NSLocalizedString(@"Data has been saved." , @"Data has been saved.")
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                              otherButtonTitles:nil];
        NSLog(@"# Data has been saved");
        [alert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Damn!", @"Damn!")
                                                        message:NSLocalizedString(@"Data has not been saved." , @"Data has not been saved.")
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                              otherButtonTitles:nil];
        [alert show];
        
        if (error != nil) {
            NSLog(@"# Error: %@", error);
        }
    }
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
    void (^completionHandler)(NSURLResponse*, NSData*, NSError*) = ^(NSURLResponse *response, NSData *theData, NSError *error) {
        NSLog(@"# Response received");
        if ([theData length] > 0 && error == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CXMLDocument *doc = [[CXMLDocument alloc] initWithData:theData options:0 error:nil];
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
                            break;
                        default:
                            alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                               message:NSLocalizedString(@"Unknown error" , @"Unknown error")
                                                              delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                                     otherButtonTitles:nil];
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
                    NSLog(@"%@", userSession.created);
                }
            });
        } else {
            if ([data length] == 0 && error == nil) {
                NSLog(@"# Nothing was downloaded");
            } else {
                if (error != nil) {
                    NSLog(@"# Error happened = %@", error);
                }
            }
        }
    };
    
    // Server request (add user session)
    Connection *connection = [[Connection alloc] initWithHost:@"http://galow.flow-maschinen.de/"];
    userSession = [[UserSessionVO alloc] init];
    userSession.udid = [[UIDevice currentDevice] uniqueIdentifier];
    [connection aAddWithControllerPath:@"user_sessions" bodyAsString:[userSession xmlRepresentation] completionHandler:completionHandler];
}
    
    

@end
