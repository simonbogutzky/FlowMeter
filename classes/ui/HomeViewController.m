//
//  HomeViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 16.01.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "HomeViewController.h"
#import "AppDelegate.h"
#import "User.h"
#import "Session.h"
#import "MotionRecord.h"
#import "HeartrateRecord.h"
#import "LocationRecord.h"
#import "AudioController.h"
#import "MBProgressHUD.h"

@interface HomeViewController ()
{
    WFSensorConnection *_sensorConnection;
    WFSensorType_t _sensorType;
    BOOL _isCollection;
    
    User *_user;
    Session *_session;
    int _lastAccumBeatCount;
    DBRestClient *_restClient;
    
    IBOutlet UILabel *_bmpLabel;
    
    AppDelegate *_appDelegate;
    
    IBOutlet UIView *_counterView;
    IBOutlet UILabel *_counterLabel;
    int _countdown;
    NSTimer *_countdownTimer;
    
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
    NSPredicate *isActivePredicate = [NSPredicate predicateWithFormat:@"isActive == %@", @1];
    _user = [_appDelegate activeUserWithPredicate:isActivePredicate];
    
    _sensorConnection = _appDelegate.wfSensorConnection;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wfSensorDataUpdated:) name:WF_NOTIFICATION_SENSOR_HAS_DATA object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gaitEventDetected:) name:@"DetectGaitEvent" object:nil];
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
            if(_isCollection) {
                
                // Create motion record
                double timestamp = [[NSDate date] timeIntervalSince1970] - startTimestamp;
                MotionRecord *motionRecord = [[MotionRecord alloc] initWithTimestamp:timestamp DeviceMotion:deviceMotion];
 
                // Add motion record
                [_session addDeviceRecord:motionRecord];
            } else {
                NSLog(@"# not in");
            }
        }];
    }
    
    // Start location updates
    CLLocationManager *locationManager = [_appDelegate sharedLocationManager];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
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
    UIButton *startStopCollectionButton = (UIButton *)sender;
    if (![_user.isActive boolValue]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Bitte gib deinen Namen an!", @"Bitte gib deinen Namen an!")
                                                        message:NSLocalizedString(@"Gehe zu Menu > Profil" , @"Gehe zu Menu > Profil")
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                              otherButtonTitles:nil];
        [alert show];
        
        startStopCollectionButton.enabled = NO;
        return;
    }
    
    if (!_isCollection) {
        
        _countdown = 5;
        _counterLabel.text = [NSString stringWithFormat:@"%i", _countdown];
        _countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(initializeCollection) userInfo:nil repeats:YES];
        _counterView.hidden = NO;

        [startStopCollectionButton setTitle:@"stop" forState:0];
        [self startUpdates];
    } else {
        [startStopCollectionButton setTitle:@"start" forState:0];
        [self stopUpdates];
        
        _isCollection = !_isCollection;
        self.sliding = !_isCollection;
        
        if ([_session.motionRecords count] != 0) {
            [_user addSessionsObject:_session];
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                [_appDelegate saveContext];
                [_session saveAndZipMotionRecords];
                [_session saveAndZipHeartrateRecords];
                [_session saveAndZipLocationRecords];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Gute Arbeit!", @"Gute Arbeit!")
                                                                    message:NSLocalizedString(@"Deine Daten wurden lokal gespeichert." , @"Deine Daten wurden lokal gespeichert.")
                                                                   delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                                          otherButtonTitles:nil];
                    [alert show];
                });
            });
            
        } else {
            [_appDelegate.managedObjectContext deleteObject:_session];
        }
    }
}

- (void)initializeCollection
{
    _countdown--;
    _counterLabel.text = [NSString stringWithFormat:@"%i", _countdown];
    
    if (_countdown == 0) {
        [_countdownTimer invalidate];
        _counterView.hidden = YES;
        
        _session = [NSEntityDescription insertNewObjectForEntityForName:@"Session" inManagedObjectContext:_appDelegate.managedObjectContext];
        _session.user = _user;
        [_session initialize];
        
        _isCollection = !_isCollection;
        self.sliding = !_isCollection;
        NSLog(@"# Start collecting");
    }
}

#pragma mark - 
#pragma mark - CLLocationManagerDelegate implementation

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if(_isCollection) {
        for (CLLocation *location in locations) {
        
            // Create location record
            LocationRecord *locationRecord = [[LocationRecord alloc] initWithTimestamp:[[NSDate date] timeIntervalSince1970] - startTimestamp Location:location];
            
            // Add location record
            [_session addLocationRecord:locationRecord];
        }
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
            }
            
            if(_isCollection) {
                
                // Create hr record
                HeartrateRecord *heartrateRecord = [[HeartrateRecord alloc] initWithTimestamp:[[NSDate date] timeIntervalSince1970] - startTimestamp HeartrateData:hrData];
                
                // Add hr record
                [_session addHeartrateRecord:heartrateRecord];
            }
            _lastAccumBeatCount = hrData.accumBeatCount;
        }
    }
    else {
        _bmpLabel.text = NSLocalizedString(@"k. A.", @"k. A.");
    }
}

- (void)gaitEventDetected:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    if ([[userInfo valueForKey:@"event"] isEqualToString:@"HS"]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults boolForKey:@"motionSoundStatus"]) {
            [[AudioController sharedAudioController] playE];
        }
    }
    
    if ([[userInfo valueForKey:@"event"] isEqualToString:@"TO"]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults boolForKey:@"motionSoundStatus"]) {
            [[AudioController sharedAudioController] playE];
        }
    }
    
    if ([[userInfo valueForKey:@"event"] isEqualToString:@"IF"]) {
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//        if ([defaults boolForKey:@"motionSoundStatus"]) {
            [[AudioController sharedAudioController] playNote:90];
//        }
    }
    
    if ([[userInfo valueForKey:@"event"] isEqualToString:@"CF"]) {

    }
    
    [_appDelegate.sharedTCPConnectionManager sendMessage:[NSString stringWithFormat:@"/evnt/%@;", [[userInfo valueForKey:@"event"] lowercaseString]]];
}

@end
