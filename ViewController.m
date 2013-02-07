//
//  ViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 16.01.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()
{
//    NSMutableString *data;
    BOOL isCollection;
    BOOL isConnected;
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    IBOutlet UITextField *hostInputField;
    IBOutlet UITextField *portInputField;
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
//    data = [NSMutableString stringWithCapacity:191520141]; // 191520000 + 141 bytes for to hours of data and 2 hours overhead (one hour approx. 45mb)
//    [data appendFormat:@"\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\"\n",
//     @"timestamp",
//     @"userAccX",
//     @"userAccY",
//     @"userAccZ",
//     @"gravityX",
//     @"gravityY",
//     @"gravityZ",
//     @"rotRateX",
//     @"rotRateY",
//     @"rotRateZ",
//     @"attYaw",
//     @"attRoll",
//     @"attPitch"
//     ];
    NSTimeInterval updateInterval = 0.01; // 100hz
    CMMotionManager *motionManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedMotionManager];
    
    // TODO: Check Attitude Reference Frame and set it right
    // NSLog(@"# Attitude Reference Frame: %d", mManager.attitudeReferenceFrame);
    
    if ([motionManager isDeviceMotionAvailable] == YES) {
        [motionManager setDeviceMotionUpdateInterval:updateInterval];
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *deviceMotion, NSError *error) {
            if (error == nil) {
//                [data appendFormat:@"%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
//                 deviceMotion.timestamp,
//                 deviceMotion.userAcceleration.x,
//                 deviceMotion.userAcceleration.y,
//                 deviceMotion.userAcceleration.z,
//                 deviceMotion.gravity.x,
//                 deviceMotion.gravity.y,
//                 deviceMotion.gravity.z,
//                 deviceMotion.rotationRate.x,
//                 deviceMotion.rotationRate.y,
//                 deviceMotion.rotationRate.z,
//                 deviceMotion.attitude.yaw,
//                 deviceMotion.attitude.roll,
//                 deviceMotion.attitude.pitch
//                 ];
                if (isConnected) {
                    [self sendMessage:[NSString stringWithFormat:@"/acc %f %f %f;", deviceMotion.userAcceleration.x, deviceMotion.userAcceleration.y, deviceMotion.userAcceleration.z]];
                    [self sendMessage:[NSString stringWithFormat:@"/gravity %f %f %f;", deviceMotion.gravity.x, deviceMotion.gravity.y, deviceMotion.gravity.z]];
                    [self sendMessage:[NSString stringWithFormat:@"/gyro %f %f %f;", deviceMotion.rotationRate.x, deviceMotion.rotationRate.y, deviceMotion.rotationRate.z]];
                    [self sendMessage:[NSString stringWithFormat:@"/att %f %f %f;", deviceMotion.attitude.yaw, deviceMotion.attitude.roll, deviceMotion.attitude.pitch]];
                }
            } else {
//                [data appendFormat:@"NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN\n"];
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
    
//    [self saveData];
    
    CLLocationManager *locationManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedLocationManager];
    [locationManager stopUpdatingLocation];
}

//- (void)saveData
//{
//    
//    // Create a date string of the current date
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
//    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
//    [dateFormatter setDateFormat:@"HH-mm-ss"];
//    NSString *timeString = [dateFormatter stringFromDate:[NSDate date]];
//    
//    // Create the path, where the data should be saved
//    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
//    NSString *pathComponent = [NSString stringWithFormat:@"%@-t%@.csv", dateString, timeString];
//    NSString *savePath = [rootPath stringByAppendingPathComponent:pathComponent];
//    
//    // Save the data
//    NSError *error = nil;
//    if([data writeToFile:savePath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Great job!", @"Great job!")
//                                                        message:NSLocalizedString(@"Data has been saved." , @"Data has been saved.")
//                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
//                                              otherButtonTitles:nil];
//        NSLog(@"# Data has been saved");
//        [alert show];
//    } else {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Damn!", @"Damn!")
//                                                        message:NSLocalizedString(@"Data has not been saved." , @"Data has not been saved.")
//                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
//                                              otherButtonTitles:nil];
//        [alert show];
//        
//        if (error != nil) {
//            NSLog(@"# Error: %@", error);
//        }
//    }
//}

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

- (void)sendMessage:(NSString *)msg
{
    NSString *response  = [NSString stringWithFormat:@"%@", msg];
    NSData *rdata = [[NSData alloc] initWithData:[response dataUsingEncoding:NSUTF8StringEncoding]];
	[outputStream write:[rdata bytes] maxLength:[rdata length]];
}

- (IBAction)connectDisconnect:(id)sender
{
    if ([hostInputField.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing host!", @"Missing host!")
                                                        message:NSLocalizedString(@"Enter a host." , @"Enter a host.")
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if ([portInputField.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing port!", @"Missing port!")
                                                        message:NSLocalizedString(@"Enter a port." , @"Enter a port.")
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    isConnected = !isConnected;
    
    UIButton *connectToHostButton = (UIButton *)sender;
    
    if (isConnected) {
        [connectToHostButton setTitle:@"disconnect" forState:0];
        [self openStreams];
    } else {
        [connectToHostButton setTitle:@"connect" forState:0];
        [self closeStreams];
    }
}
    
- (void)openStreams
{
    NSString *host = hostInputField.text;
    NSNumber *port = [NSNumber numberWithInt:[portInputField.text intValue]];
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, [port intValue], &readStream, &writeStream);
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
    
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [inputStream open];
    [outputStream open];
}

- (void)closeStreams
{
    [inputStream close];
    [outputStream close];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
