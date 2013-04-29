//
//  HomeViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 16.01.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "HomeViewController.h"
#import "AppDelegate.h"
#import "Session.h"
#import "MotionRecord.h"
#import "HeartrateRecord.h"
#import "LocationRecord.h"
#import "AudioController.h"

@interface HomeViewController ()
{
    WFSensorConnection *_sensorConnection;
    WFSensorType_t _sensorType;
    BOOL _isCollection;
    
    Session *_session;
    int _lastAccumBeatCount;
    DBRestClient *_restClient;
    
    IBOutlet UILabel *_bmpLabel;
    
    AppDelegate *_appDelegate;
    
    double startTimestamp;
}

@end

@implementation HomeViewController

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _sensorConnection = _appDelegate.wfSensorConnection;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wfSensorDataUpdated:) name:WF_NOTIFICATION_SENSOR_HAS_DATA object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark - Convient methods

- (void)startUpdates
{
    startTimestamp = [[NSDate date] timeIntervalSince1970];
    
    // Start motion updates
    NSTimeInterval updateInterval = 0.01; // 100hz
    CMMotionManager *motionManager = [_appDelegate sharedMotionManager];
    
    if ([motionManager isDeviceMotionAvailable] == YES) {
        [motionManager setDeviceMotionUpdateInterval:updateInterval];
        [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical toQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *deviceMotion, NSError *error) {
            
            // Create motion record
            MotionRecord *motionRecord =[NSEntityDescription insertNewObjectForEntityForName:@"MotionRecord" inManagedObjectContext:_appDelegate.managedObjectContext];
            motionRecord.timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] - startTimestamp];
            motionRecord.userAccelerationX = [NSNumber numberWithDouble:deviceMotion.userAcceleration.x];
            motionRecord.userAccelerationY = [NSNumber numberWithDouble:deviceMotion.userAcceleration.y];
            motionRecord.userAccelerationZ = [NSNumber numberWithDouble:deviceMotion.userAcceleration.z];
            motionRecord.gravityX = [NSNumber numberWithDouble:deviceMotion.gravity.x];
            motionRecord.gravityY = [NSNumber numberWithDouble:deviceMotion.gravity.y];
            motionRecord.gravityZ = [NSNumber numberWithDouble:deviceMotion.gravity.z];
            motionRecord.rotationRateX = [NSNumber numberWithDouble:deviceMotion.rotationRate.x];
            motionRecord.rotationRateY = [NSNumber numberWithDouble:deviceMotion.rotationRate.y];
            motionRecord.rotationRateZ = [NSNumber numberWithDouble:deviceMotion.rotationRate.z];
            motionRecord.attitudePitch = [NSNumber numberWithDouble:deviceMotion.attitude.pitch];
            motionRecord.attitudeYaw = [NSNumber numberWithDouble:deviceMotion.attitude.yaw];
            motionRecord.attitudeRoll = [NSNumber numberWithDouble:deviceMotion.attitude.roll];
            
            // Add motion record
            [_session addMotionRecordsObject:motionRecord];
            
//            if ([[_userSession appendMotionData:deviceMotion] isEqualToString:@"HS"]) {
//                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//                if ([defaults boolForKey:@"motionSoundStatus"]) {
//                    [[AudioController sharedAudioController] playE];
//                } 
//            }
        }];
    }
    
    // Start location updates
    CLLocationManager *locationManager = [_appDelegate sharedLocationManager];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
}

- (void)stopUpdates
{
    // Stop motion updates
    CMMotionManager *motionManager = [_appDelegate sharedMotionManager];
    if ([motionManager isDeviceMotionActive] == YES) {
        [motionManager stopDeviceMotionUpdates];
    }
    
    // Stop location updates
    CLLocationManager *locationManager = [_appDelegate sharedLocationManager];
    [locationManager stopUpdatingLocation];
}

#pragma mark -
#pragma mark - IBActions

- (IBAction)startStopCollection:(id)sender
{
    _isCollection = !_isCollection;
    self.sliding = !_isCollection;
    
    UIButton *startStopCollectionButton = (UIButton *)sender;
    
    if (_isCollection) {
        
        _session = [NSEntityDescription insertNewObjectForEntityForName:@"Session" inManagedObjectContext:_appDelegate.managedObjectContext];
        _session.timestamp = [NSDate date];
        
        // Create a date string of the current date
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
        [dateFormatter setDateFormat:@"HH-mm-ss"];
        NSString *timeString = [dateFormatter stringFromDate:[NSDate date]];
        _session.filename = [NSString stringWithFormat:@"%@-t%@", dateString, timeString];
        
        [startStopCollectionButton setTitle:@"stop" forState:0];
        [self startUpdates];
    } else {
        [startStopCollectionButton setTitle:@"start" forState:0];
        [self stopUpdates];
        
        [_appDelegate saveContext];
        [_session saveAndZipMotionRecords];
        [_session saveAndZipHeartrateRecords];
        [_session saveAndZipLocationRecords];
        
        // TODO: (sb) Replace feedback
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Gute Arbeit!", @"Gute Arbeit!")
                                                        message:NSLocalizedString(@"Deine Daten wurden lokal gespeichert." , @"Deine Daten wurden lokal gespeichert.")
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                              otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - 
#pragma mark - CLLocationManagerDelegate implementation

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations) {
        
        // Create location record
        LocationRecord *locationRecord =[NSEntityDescription insertNewObjectForEntityForName:@"LocationRecord" inManagedObjectContext:_appDelegate.managedObjectContext];
        locationRecord.timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] - startTimestamp];
        locationRecord.latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
        locationRecord.longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
        locationRecord.altitude = [NSNumber numberWithDouble:location.altitude];
        locationRecord.speed = [NSNumber numberWithDouble:location.speed];
        
        // Add location record
        [_session addLocationRecordsObject:locationRecord];
    }
}

#pragma mark -
#pragma marl - Notification handler

- (void)wfSensorDataUpdated:(NSNotification *)notification
{
    if ([_appDelegate.wfSensorConnection isKindOfClass:[WFHeartrateConnection class]]) {
        WFHeartrateConnection *hrConnection = (WFHeartrateConnection *) _appDelegate.wfSensorConnection;
        WFHeartrateData *hrData = [hrConnection getHeartrateData];
        if (hrData != nil) {
            _bmpLabel.text = [hrData formattedHeartrate:YES];
            if (_lastAccumBeatCount < hrData.accumBeatCount) {
                
                // Sonify beat
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                if ([defaults boolForKey:@"hrSoundStatus"]) {
                    [[AudioController sharedAudioController] playE];
                }
                
                if(_isCollection) {
                    
                    // Create hr record
                    HeartrateRecord *heartrateRecord =[NSEntityDescription insertNewObjectForEntityForName:@"HeartrateRecord" inManagedObjectContext:_appDelegate.managedObjectContext];
                    heartrateRecord.timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] - startTimestamp];
                    heartrateRecord.accumBeatCount = [NSNumber numberWithDouble:hrData.accumBeatCount];
                    
                    // Add hr record
                    [_session addHeatrateRecordsObject:heartrateRecord];
                }
                
                _lastAccumBeatCount = hrData.accumBeatCount;
                
            }
//            NSArray* rrIntervals = [(WFBTLEHeartrateData*)hrData rrIntervals];
//            for (NSNumber *rrInterval in rrIntervals) {
//                NSLog(@"# rrInterval: %f", [rrInterval doubleValue]);
//            }
        }
    }
    else {
        _bmpLabel.text = NSLocalizedString(@"k. A.", @"k. A.");
    }
}

@end
