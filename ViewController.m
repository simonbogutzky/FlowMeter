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
    NSMutableString *data;
    BOOL isCollection;
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
    data = [NSMutableString stringWithCapacity:3192115]; // 3192000 + 115 bytes for to hours of data and 2 hours overhead
    [data appendFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@\n",
     @"timestamp",
     @"userAccX",
     @"userAccY",
     @"userAccZ",
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
    CMMotionManager *mManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];
    
    // TODO: Check Attitude Reference Frame and set it right
    NSLog(@"# Attitude Reference Frame: %d", mManager.attitudeReferenceFrame);
    
    if ([mManager isDeviceMotionAvailable] == YES) {
        [mManager setDeviceMotionUpdateInterval:updateInterval];
        [mManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *deviceMotion, NSError *error) {
            if (error == nil) {
                [data appendFormat:@"%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
                 deviceMotion.timestamp,
                 deviceMotion.userAcceleration.x,
                 deviceMotion.userAcceleration.y,
                 deviceMotion.userAcceleration.z,
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
            } else {
                [data appendFormat:@"NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN\n"];
            }
        }];
    }
}

- (void)stopUpdates
{
    CMMotionManager *mManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];
    
    if ([mManager isDeviceMotionActive] == YES) {
        [mManager stopDeviceMotionUpdates];
    }
    
    [self saveData];
}

- (void)saveData
{
    
    // Create a date string of the current date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd_HHmmss"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    
    // Create the path, where the data should be saved
    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *pathComponent = [NSString stringWithFormat:@"%@.csv", dateString];
    NSString *savePath = [rootPath stringByAppendingPathComponent:pathComponent];
    
    // Save the data
    NSError *error = nil;
    if([data writeToFile:savePath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        NSLog(@"Saved the data");
        
    } else {
        NSLog(@"Did not save the date");
        if (error != nil) {
            NSLog(@"Error: %@", error);
        }
    }
}

- (void)setScreenBrightnessInPercent:(NSNumber *)percent
{
    UIScreen *mainScreen = [UIScreen mainScreen];
    mainScreen.brightness = [percent doubleValue];
}

- (IBAction)startStopCollection:(id)sender
{
    isCollection = !isCollection;
    
    UIButton *startStopCollectionButton = (UIButton *)sender;
    
    if (isCollection) {
        [startStopCollectionButton setTitle:@"stop" forState:0];
        [self startUpdates];
        
        [self performSelector:@selector(setScreenBrightnessInPercent:) withObject:[NSNumber numberWithDouble:0.1] afterDelay:0.5];
        
    } else {
        [startStopCollectionButton setTitle:@"start" forState:0];
        [self stopUpdates];
        
        //TODO: Do it when user touches the screen
        [self setScreenBrightnessInPercent:[NSNumber numberWithDouble:0.5]];
    }
    
}

@end
