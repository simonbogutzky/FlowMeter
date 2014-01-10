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
#import "Motion.h"
#import "Location.h"
#import "MBProgressHUD.h"

@interface HomeViewController ()
{
    BOOL _isCollection;
    
    User *_user;
    Session *_session;
    int _lastAccumBeatCount;
    DBRestClient *_restClient;
    
    AppDelegate *_appDelegate;
    
    IBOutlet UIView *_counterView;
    IBOutlet UILabel *_counterLabel;
    IBOutlet UIButton *_startStopCollectionButton;
    int _countdown;
    NSTimer *_countdownTimer;
    
//    double startTimestamp;
}
@property (weak, nonatomic) IBOutlet UILabel *heartRateLabel;

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark - Convient methods

- (void)startUpdates
{
//    startTimestamp = [[NSDate date] timeIntervalSince1970];
    
    // Start motion updates
    NSTimeInterval updateInterval = 0.01; // 100hz
    CMMotionManager *motionManager = [_appDelegate sharedMotionManager];
    
    if ([motionManager isDeviceMotionAvailable] == YES) {
        [motionManager setDeviceMotionUpdateInterval:updateInterval];
        [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical toQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *deviceMotion, NSError *error) {
            if(_isCollection) {
                
                // Create motion record
                double timestamp = [[NSDate date] timeIntervalSince1970]; // - startTimestamp;
                Motion *motionRecord = [[Motion alloc] initWithTimestamp:timestamp DeviceMotion:deviceMotion];
 
                // Add motion record
                [_session addMotionRecord:motionRecord];
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
    
    if (_appDelegate.heartRateMonitorManager.hasConnection) {
        _appDelegate.heartRateMonitorManager.delegate = self;
        [_appDelegate.heartRateMonitorManager startMonitoring];
    }
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
    
    if (_appDelegate.heartRateMonitorManager.hasConnection) {
        self.heartRateLabel.hidden = YES;
        [_appDelegate.heartRateMonitorManager stopMonitoring];
    }
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
        [[self navigationController] setNavigationBarHidden:YES animated:YES];
        
        _countdown = 5;
        _counterLabel.text = [NSString stringWithFormat:@"%i", _countdown];
        _countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(initializeCollection) userInfo:nil repeats:YES];
        _counterView.hidden = NO;

        [startStopCollectionButton setTitle:@"stop" forState:0];
        [self startUpdates];
    } else {
        [self stopUpdates];
        _isCollection = !_isCollection;
        
        if ([_session.motionRecords count] != 0) {
            [_user addSessionsObject:_session];
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                [_appDelegate saveContext];
                [_session storeMotionData];
                [_session storeHeartRateMonitorData];
                [_session storeLocationData];
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
            [[self navigationController] setNavigationBarHidden:NO animated:YES];
            [startStopCollectionButton setTitle:@"start" forState:0];
            [_appDelegate.managedObjectContext deleteObject:_session];
        }
    }
}

- (void)initializeCollection
{
    _countdown--;
    _counterLabel.text = [NSString stringWithFormat:@"%i", _countdown];
    
    if (_countdown == 0) {
        
        NSDictionary *userInfo = @{@"event": @"collecting-starts"};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DetectGaitEvent" object:self userInfo:userInfo];
        
        [_countdownTimer invalidate];
        _counterView.hidden = YES;
        
        _session = [NSEntityDescription insertNewObjectForEntityForName:@"Session" inManagedObjectContext:_appDelegate.managedObjectContext];
        _session.isZipped = [NSNumber numberWithBool:ZIP];
        _session.user = _user;
        [_session initialize];
        
        _isCollection = !_isCollection;
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
            Location *locationRecord = [[Location alloc] initWithTimestamp:[[NSDate date] timeIntervalSince1970]  Location:location]; // - startTimestamp
            
            // Add location record
            [_session addLocationRecord:locationRecord];
        }
    }
}

#pragma mark -
#pragma mark - UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    [_startStopCollectionButton setTitle:@"start" forState:0];
}

#pragma mark -
#pragma mark - HeartRateMonitorManagerDelegate implementation

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager didReceiveHeartrateMonitorData:(HeartRateMonitorData *)data fromHeartRateMonitorDevice:(HeartRateMonitorDevice *)device
{
    self.heartRateLabel.hidden = NO;
    if (data.heartRate != -1) {
        self.heartRateLabel.text = [NSString stringWithFormat:@"%d %@", data.heartRate, data.heartRateUnit];
    }
    
    if(_isCollection) {
        
        // Add hr record
        [_session addHeartrateRecord:data];
    }
}

@end
