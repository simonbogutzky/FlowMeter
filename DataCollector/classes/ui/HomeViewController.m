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
#import "MBProgressHUD.h"

@interface HomeViewController ()
{
    BOOL _isCollection;
    
    User *_user;
    int _lastAccumBeatCount;
    DBRestClient *_restClient;
    
    AppDelegate *_appDelegate;
    
    IBOutlet UIView *_counterView;
    IBOutlet UILabel *_counterLabel;
    IBOutlet UIButton *_startStopCollectionButton;
    int _countdown;
    NSTimer *_countdownTimer;
}

@property (nonatomic, strong) Session *session;
@property (nonatomic, weak) IBOutlet UILabel *heartRateLabel;

@end

@implementation HomeViewController

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (Session *)session
{
    if (!_session) {
        _session = [NSEntityDescription insertNewObjectForEntityForName:@"Session" inManagedObjectContext:_appDelegate.managedObjectContext];
        _session.isZipped = [NSNumber numberWithBool:ZIP];
        _session.user = _user;
    }
    return _session;
}

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
    // Start motion updates
    NSTimeInterval updateInterval = 0.01; // 100hz
    CMMotionManager *motionManager = [_appDelegate sharedMotionManager];
    
    if ([motionManager isDeviceMotionAvailable] == YES) {
        [motionManager setDeviceMotionUpdateInterval:updateInterval];
        [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical toQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *deviceMotion, NSError *error) {
            if(_isCollection) {
                
                // Create motion record
                double timestamp = [[NSDate date] timeIntervalSince1970];
                Motion *motionRecord = [[Motion alloc] initWithTimestamp:timestamp deviceMotion:deviceMotion];
 
                // Add motion record
                [self.session addMotionData:motionRecord];
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
        
//        if ([self.session.motionDataCount intValue] != 0) {
            [_user addSessionsObject:_session];
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                [_appDelegate saveContext];
                [self.session storeMotions];
                [self.session storeHeartRateMonitorData];
                [self.session storeLocations];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Gute Arbeit!", @"Gute Arbeit!")
                                                                    message:NSLocalizedString(@"Deine Daten wurden lokal gespeichert." , @"Deine Daten wurden lokal gespeichert.")
                                                                   delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                                          otherButtonTitles:nil];
                    [alert show];
                });
            });
            
//        } else {
//            [[self navigationController] setNavigationBarHidden:NO animated:YES];
//            [startStopCollectionButton setTitle:@"start" forState:0];
//            [_appDelegate.managedObjectContext deleteObject:self.session];
//        }
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
        
        [self.session initialize];
        
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
            
            // Add location record
            [self.session addLocationData:location];
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
        [self.session addHeartRateMonitorData:data];
    }
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didDisconnectHeartrateMonitorDevice:(CBPeripheral *)heartRateMonitorDevice
                          error:(NSError *)error
{
    [manager connectHeartRateMonitorDevice:(HeartRateMonitorDevice *)heartRateMonitorDevice];
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didConnectHeartrateMonitorDevice:(CBPeripheral *)heartRateMonitorDevice
{
    [manager startMonitoring];
}

@end
