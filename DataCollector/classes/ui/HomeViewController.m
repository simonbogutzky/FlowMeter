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
#import "SubjectiveResponses.h"
#import "Motion.h"
#import "MBProgressHUD.h"
#import "LikertScaleViewController.h"
#import <AudioToolbox/AudioServices.h>

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
@property (nonatomic, assign) BOOL isLastSubjektiveResponse;
@property (nonatomic, strong) NSTimer *subjektiveResponseTimer;

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
    CMMotionManager *motionManager = _appDelegate.motionManager;
    
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
    CLLocationManager *locationManager = _appDelegate.locationManager;
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
    CMMotionManager *motionManager = _appDelegate.motionManager;
    if ([motionManager isDeviceMotionActive] == YES) {
        [motionManager stopDeviceMotionUpdates];
    }
    
    // Stop location updates
    CLLocationManager *locationManager = _appDelegate.locationManager;
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
            [startStopCollectionButton setTitle:@"stop" forState:0];
        
        
        if (_appDelegate.fssEnqueryStatus) {
            self.subjektiveResponseTimer = [NSTimer scheduledTimerWithTimeInterval:15 * 60 target:self selector:@selector(showFlowShortScale) userInfo:nil repeats:NO];
        }
        
        _countdown = 5;
        _counterLabel.text = [NSString stringWithFormat:@"%i", _countdown];
        _countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(initializeCollection) userInfo:nil repeats:YES];
        _counterView.hidden = NO;
        
        [self startUpdates];
    } else {
        [self stopUpdates];
        _isCollection = !_isCollection;
        
        if (_appDelegate.fssEnqueryStatus) {
            self.isLastSubjektiveResponse = YES;
            [self showFlowShortScale];
            [self.subjektiveResponseTimer invalidate];
        } else {
            [self storeData];
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
    AudioServicesPlaySystemSound(1073);
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didConnectHeartrateMonitorDevice:(CBPeripheral *)heartRateMonitorDevice
{
    [manager startMonitoring];
}

#pragma mark -
#pragma mark - Flow-Kurzskala 

- (void)showFlowShortScale
{
    AudioServicesPlaySystemSound(1007);
    [self presentViewController:[self flowShortScaleViewControllerFromStoryboard] animated:YES completion:nil];
}

- (LikertScaleViewController *)flowShortScaleViewControllerFromStoryboard
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    LikertScaleViewController *flowShortScaleViewController = (LikertScaleViewController *)[storyboard instantiateViewControllerWithIdentifier:@"LikertScale"];
    
    flowShortScaleViewController.delegate = self;
    
    flowShortScaleViewController.itemLabelTexts = @[
                                                     @"Ich fühle mich optimal beansprucht.",
                                                     @"Meine Gedanken bzw. Aktivitäten laufen flüssig und glatt.",
                                                     @"Ich merke gar nicht, wie die Zeit vergeht.",
                                                     @"Ich habe keine Mühe, mich zu konzentrieren.",
                                                     @"Mein Kopf ist völlig klar.",
                                                     @"Ich bin ganz vertieft in das, was ich gerade mache.",
                                                     @"Die richtigen Gedanken/Bewegungen kommen wie von selbst.",
                                                     @"Ich weiß bei jedem Schritt, was ich zu tun habe.",
                                                     @"Ich habe das Gefühl, den Ablauf unter Kontrolle zu haben.",
                                                     @"Ich bin völlig selbstvergessen.",
                                                     @"Es steht etwas für mich Wichtiges auf dem Spiel.",
                                                     @"Ich darf jetzt keine Fehler machen.",
                                                     @"Ich mache mir Sorgen über einen Misserfolg.",
                                                     @"Verglichen mit allen anderen Tätigkeiten, die ich sonst mache, ist die jetzige Tätigkeit...",
                                                     @"Ich denke, meine Fähigkeiten auf diesem Gebiet sind...",
                                                     @"Für mich persönlich sind die jetzigen Anforderungen..."
                                                     ];
     flowShortScaleViewController.itemSegments = @[
                                                   @7,
                                                   @7,
                                                   @7,
                                                   @7,
                                                   @7,
                                                   @7,
                                                   @7,
                                                   @7,
                                                   @7,
                                                   @7,
                                                   @7,
                                                   @7,
                                                   @7,
                                                   @9,
                                                   @9,
                                                   @9
                                                   ];
    flowShortScaleViewController.scaleLabels = @[
                                                  @[@"Trifft nicht zu", @"teils-teils", @"Trifft zu"],
                                                  @[@"Trifft nicht zu", @"teils-teils", @"Trifft zu"],
                                                  @[@"Trifft nicht zu", @"teils-teils", @"Trifft zu"],
                                                  @[@"Trifft nicht zu", @"teils-teils", @"Trifft zu"],
                                                  @[@"Trifft nicht zu", @"teils-teils", @"Trifft zu"],
                                                  @[@"Trifft nicht zu", @"teils-teils", @"Trifft zu"],
                                                  @[@"Trifft nicht zu", @"teils-teils", @"Trifft zu"],
                                                  @[@"Trifft nicht zu", @"teils-teils", @"Trifft zu"],
                                                  @[@"Trifft nicht zu", @"teils-teils", @"Trifft zu"],
                                                  @[@"Trifft nicht zu", @"teils-teils", @"Trifft zu"],
                                                  @[@"Trifft nicht zu", @"teils-teils", @"Trifft zu"],
                                                  @[@"Trifft nicht zu", @"teils-teils", @"Trifft zu"],
                                                  @[@"Trifft nicht zu", @"teils-teils", @"Trifft zu"],
                                                  @[@"leicht", @"", @"schwer"],
                                                  @[@"niedrig", @"", @"hoch"],
                                                  @[@"zu gering",@"gerade richtig", @"zu hoch"]
                                                  ];

    return flowShortScaleViewController;
}

- (void)likertScaleViewController:(LikertScaleViewController *)viewController didFinishWithResponses:(NSArray *)responses atTimestamp:(double)timestamp
{
    [viewController dismissViewControllerAnimated:YES
                                       completion:^{
                                           ;
                                       }];
    
   SubjectiveResponses *subjectiveResponses = [[SubjectiveResponses alloc] initWithTimestamp:timestamp itemResponses:responses];
    [self.session addSubjectiveResponseData:subjectiveResponses];
    
    if (_isCollection) {
        self.subjektiveResponseTimer = [NSTimer scheduledTimerWithTimeInterval:15 * 60 target:self selector:@selector(showFlowShortScale) userInfo:nil repeats:NO];
    } else {
        if (self.isLastSubjektiveResponse) {
            [self storeData];
            self.isLastSubjektiveResponse = NO;
        }
    }
}

- (void)storeData
{
    [_user addSessionsObject:self.session];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.session storeMotions];
        [self.session storeHeartRateMonitorData];
        [self.session storeLocations];
        [self.session storeSubjectiveResponseData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Gute Arbeit!", @"Gute Arbeit!")
                                                            message:NSLocalizedString(@"Deine Daten wurden lokal gespeichert." , @"Deine Daten wurden lokal gespeichert.")
                                                           delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                                  otherButtonTitles:nil];
            [alert show];
        });
    });
}

@end
