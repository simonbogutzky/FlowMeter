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
#import "SelfReport.h"
//#import "Motion.h"
#import "MBProgressHUD.h"
#import "LikertScaleViewController.h"
#import <AudioToolbox/AudioServices.h>

@interface HomeViewController ()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) Session *session;

@property (nonatomic, strong) NSTimer *selfReportTimer;
@property (nonatomic, strong) NSTimer *startCountdownTimer;
@property (nonatomic, strong) NSTimer *stopWatchTimer;
@property (nonatomic, strong) NSDate *stopWatchStartDate;

@property (nonatomic) BOOL isCollecting;
@property (nonatomic) BOOL isLastSelfReport;
@property (nonatomic) int startCountdown;

@property (nonatomic, weak) IBOutlet UIView *startCountdownView;
@property (nonatomic, weak) IBOutlet UILabel *startCountdownLabel;
@property (nonatomic, weak) IBOutlet UILabel *stopWatchLabel;
@property (nonatomic, weak) IBOutlet UIButton *startStopButton;
@property (nonatomic, weak) IBOutlet UILabel *heartRateLabel;

@end

@implementation HomeViewController

#pragma mark -
#pragma mark - Getter

- (AppDelegate *)appDelegate
{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (User *)user
{
    if (!_user) {
        NSPredicate *isActivePredicate = [NSPredicate predicateWithFormat:@"isActive == %@", @1];
        _user = [self.appDelegate activeUserWithPredicate:isActivePredicate];
    }
    return _user;
}

- (Session *)session
{
    if (!_session) {
        _session = [NSEntityDescription insertNewObjectForEntityForName:@"Session" inManagedObjectContext:self.appDelegate.managedObjectContext];
        _session.isZipped = [NSNumber numberWithBool:ZIP];
        _session.user = _user;
    }
    return _session;
}

#pragma mark -
#pragma mark - IBActions

- (IBAction)startStopTouchUpInside:(UIButton *)sender
{
    if (![self.user.isActive boolValue]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Bitte gib deinen Namen an! *", @"Bitte gib deinen Namen an!")
                                                        message:NSLocalizedString(@"Gehe zu Menu > Profil *" , @"Gehe zu Menu > Profil")
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok *", @"Ok")
                                              otherButtonTitles:nil];
        [alert show];
        sender.enabled = NO;
        return;
    }
    
    if (!self.isCollecting) {
        
        // Hide navigation bar
        [[self navigationController] setNavigationBarHidden:YES animated:YES];
        
        // Rename button title
        [sender setTitle:NSLocalizedString(@"Stop *", @"Stoppe Aufnahme") forState:0];
        
        // Start sensor updates
        [self startSensorUpdates];
        
        // Start start countdown
        // TODO: Sekunden auslagern
        [self startStartCounterWithInterval:5];
        
    } else {
        self.isCollecting = !self.isCollecting;
        [self stopSensorUpdates];
        
        if (self.appDelegate.flowShortScaleIsSelected) {
            [self.selfReportTimer invalidate];
            self.isLastSelfReport = YES;
            
            [self showSelfReport];
        } else {
            [self storeData];
        }
        
    }
}

#pragma mark -
#pragma mark - Convient methods

- (void)startStartCounterWithInterval:(int)seconds
{
    self.startCountdown = seconds;
    self.startCountdownLabel.text = [NSString stringWithFormat:@"%d", self.startCountdown];
    self.startCountdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                target:self
                                                              selector:@selector(updateStartCountdown)
                                                              userInfo:nil repeats:YES];
    self.startCountdownView.hidden = NO;
}

- (void)updateStartCountdown
{
    self.startCountdown--;
    self.startCountdownLabel.text = [NSString stringWithFormat:@"%i", self.startCountdown];
    if (self.startCountdown == 0) {
        [self.startCountdownTimer invalidate];
        self.startCountdownView.hidden = YES;
        
        [self startCollecting];
    }
}

- (void)startStopWatch
{
    self.stopWatchStartDate = [NSDate date];
    self.stopWatchLabel.text = @"00:00:00";
    self.stopWatchLabel.hidden = NO;
    self.stopWatchTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0
                                                           target:self
                                                         selector:@selector(updateStopWatch)
                                                         userInfo:nil
                                                          repeats:YES];
}

- (void)updateStopWatch
{
    // Create date from the elapsed time
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:self.stopWatchStartDate];
    NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    
    // Create a date formatter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
    
    // Format the elapsed time and set it to the label
    NSString *timeString = [dateFormatter stringFromDate:timerDate];
    self.stopWatchLabel.text = timeString;
}

- (void)startSensorUpdates
{
    /*
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
     */
    
    // Start heart rate monitor updates
    if (self.appDelegate.heartRateMonitorManager.hasConnection) {
        self.appDelegate.heartRateMonitorManager.delegate = self;
        [self.appDelegate.heartRateMonitorManager startMonitoring];
    }
}

- (void)stopSensorUpdates
{
    /*
    // Stop motion updates
    CMMotionManager *motionManager = _appDelegate.motionManager;
    if ([motionManager isDeviceMotionActive] == YES) {
        [motionManager stopDeviceMotionUpdates];
    }
    
    // Stop location updates
    CLLocationManager *locationManager = _appDelegate.locationManager;
    [locationManager stopUpdatingLocation];
     */
    
    // Stop heart rate monitor updates
    if (self.appDelegate.heartRateMonitorManager.hasConnection) {
        self.heartRateLabel.hidden = YES;
        [self.appDelegate.heartRateMonitorManager stopMonitoring];
    }
}

- (void)startCollecting
{
    NSLog(@"# Start collecting");
    [self.session initialize];
    self.isCollecting = !self.isCollecting;
    
    [self startStopWatch];
    
    if (self.appDelegate.flowShortScaleIsSelected) {
        //TODO: Minuten auslagern
        self.selfReportTimer = [NSTimer scheduledTimerWithTimeInterval:1 * 60 target:self selector:@selector(showSelfReport) userInfo:nil repeats:NO];
    }
}

- (void)storeData
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.user addSessionsObject:self.session];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //        [self.session storeMotions];
        //        [self.session storeLocations];
        [self.session storeHeartRateMonitorData];
        //TODO: Session 
        [self.session storeSubjectiveResponseData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Gute Arbeit! *", @"Gute Arbeit!")
                                                            message:NSLocalizedString(@"Deine Daten wurden lokal gespeichert. *" , @"Deine Daten wurden lokal gespeichert.")
                                                           delegate:self cancelButtonTitle:NSLocalizedString(@"Ok *", @"Bestätigung: Ok")
                                                  otherButtonTitles:nil];
            [alert show];
        });
    });
}

#pragma mark -
#pragma mark - UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    [self.startStopButton setTitle:NSLocalizedString(@"Start *", "Starte Aufnahme") forState:0];
}

#pragma mark -
#pragma mark - HeartRateMonitorManagerDelegate implementation

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager didReceiveHeartrateMonitorData:(HeartRateMonitorData *)data fromHeartRateMonitorDevice:(HeartRateMonitorDevice *)device
{
    self.heartRateLabel.hidden = NO;
    if (data.heartRate != -1) {
        self.heartRateLabel.text = [NSString stringWithFormat:@"%d %@", data.heartRate, data.heartRateUnit];
    }
    
    if(self.isCollecting) {
        
        // Add hr record
        [self.session addHeartRateMonitorData:data];
    }
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didDisconnectHeartrateMonitorDevice:(CBPeripheral *)heartRateMonitorDevice
                          error:(NSError *)error
{
    AudioServicesPlaySystemSound(1073);
    self.heartRateLabel.text = NSLocalizedString(@"Getrennt *", "HR Monitor wurde getrennt");
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didConnectHeartrateMonitorDevice:(CBPeripheral *)heartRateMonitorDevice
{
    [manager startMonitoring];
}

/*
 #pragma mark -
 #pragma mark - CLLocationManagerDelegate implementation
 
 - (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
 {
 if(_isCollecting) {
 for (CLLocation *location in locations) {
 
 // Add location record
 [self.session addLocationData:location];
 }
 }
 }
 */

#pragma mark -
#pragma mark - LikertScaleViewControllerDelegate implementation

- (void)likertScaleViewController:(LikertScaleViewController *)viewController didFinishWithResponses:(NSArray *)responses atTimestamp:(double)timestamp
{
    [viewController dismissViewControllerAnimated:YES
                                       completion:^{
                                           ;
                                       }];
    
    SelfReport *selfReport = [[SelfReport alloc] initWithTimestamp:timestamp itemResponses:responses];
    [self.session addSubjectiveResponseData:selfReport];
    
    if (self.isCollecting) {
        //TODO: Minuten auslagern
        self.selfReportTimer = [NSTimer scheduledTimerWithTimeInterval:15 * 60 target:self selector:@selector(showSelfReport) userInfo:nil repeats:NO];
    } else {
        if (self.isLastSelfReport) {
            [self storeData];
            self.isLastSelfReport = NO;
        }
    }
}

#pragma mark -
#pragma mark - Self-reports

- (void)showSelfReport
{
    AudioServicesPlaySystemSound(1007);
    
    if (self.appDelegate.flowShortScaleIsSelected) {
        [self presentViewController:[self flowShortScaleViewControllerFromStoryboard] animated:YES completion:nil];
    }
}

- (LikertScaleViewController *)flowShortScaleViewControllerFromStoryboard
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    LikertScaleViewController *flowShortScaleViewController = (LikertScaleViewController *)[storyboard instantiateViewControllerWithIdentifier:@"LikertScale"];
    
    flowShortScaleViewController.delegate = self;
    
    flowShortScaleViewController.itemLabelTexts = @[
                                                     NSLocalizedString(@"Ich fühle mich optimal beansprucht. *", @"Ich fühle mich optimal beansprucht."),
                                                     NSLocalizedString(@"Meine Gedanken bzw. Aktivitäten laufen flüssig und glatt. *", @"Meine Gedanken bzw. Aktivitäten laufen flüssig und glatt."),
                                                     NSLocalizedString(@"Ich merke gar nicht, wie die Zeit vergeht. *", @"Ich merke gar nicht, wie die Zeit vergeht."),
                                                     NSLocalizedString(@"Ich habe keine Mühe, mich zu konzentrieren. *", @"Ich habe keine Mühe, mich zu konzentrieren."),
                                                     NSLocalizedString(@"Mein Kopf ist völlig klar. *", @"Mein Kopf ist völlig klar."),
                                                     NSLocalizedString(@"Ich bin ganz vertieft in das, was ich gerade mache. *", @"Ich bin ganz vertieft in das, was ich gerade mache."),
                                                     NSLocalizedString(@"Die richtigen Gedanken/Bewegungen kommen wie von selbst. *", @"Die richtigen Gedanken/Bewegungen kommen wie von selbst."),
                                                     NSLocalizedString(@"Ich weiß bei jedem Schritt, was ich zu tun habe. *", @"Ich weiß bei jedem Schritt, was ich zu tun habe."),
                                                     NSLocalizedString(@"Ich habe das Gefühl, den Ablauf unter Kontrolle zu haben. *", @"Ich habe das Gefühl, den Ablauf unter Kontrolle zu haben."),
                                                     NSLocalizedString(@"Ich bin völlig selbstvergessen. *", @"Ich bin völlig selbstvergessen."),
                                                     NSLocalizedString(@"Es steht etwas für mich Wichtiges auf dem Spiel. *", @"Es steht etwas für mich Wichtiges auf dem Spiel."),
                                                     NSLocalizedString(@"Ich darf jetzt keine Fehler machen. *", @"Ich darf jetzt keine Fehler machen."),
                                                     NSLocalizedString(@"Ich mache mir Sorgen über einen Misserfolg. *", @"Ich mache mir Sorgen über einen Misserfolg."),
                                                     NSLocalizedString(@"Verglichen mit allen anderen Tätigkeiten, die ich sonst mache, ist die jetzige Tätigkeit... *", @"Verglichen mit allen anderen Tätigkeiten, die ich sonst mache, ist die jetzige Tätigkeit..."),
                                                     NSLocalizedString(@"Ich denke, meine Fähigkeiten auf diesem Gebiet sind... *", @"Ich denke, meine Fähigkeiten auf diesem Gebiet sind..."),
                                                     NSLocalizedString(@"Für mich persönlich sind die jetzigen Anforderungen... *", @"Für mich persönlich sind die jetzigen Anforderungen...")
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
                                                  @[NSLocalizedString(@"Trifft nicht zu *", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils *", @"teils-teils"), NSLocalizedString(@"Trifft zu *", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu *", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils *", @"teils-teils"), NSLocalizedString(@"Trifft zu *", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu *", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils *", @"teils-teils"), NSLocalizedString(@"Trifft zu *", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu *", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils *", @"teils-teils"), NSLocalizedString(@"Trifft zu *", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu *", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils *", @"teils-teils"), NSLocalizedString(@"Trifft zu *", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu *", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils *", @"teils-teils"), NSLocalizedString(@"Trifft zu *", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu *", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils *", @"teils-teils"), NSLocalizedString(@"Trifft zu *", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu *", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils *", @"teils-teils"), NSLocalizedString(@"Trifft zu *", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu *", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils *", @"teils-teils"), NSLocalizedString(@"Trifft zu *", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu *", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils *", @"teils-teils"), NSLocalizedString(@"Trifft zu *", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu *", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils *", @"teils-teils"), NSLocalizedString(@"Trifft zu *", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu *", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils *", @"teils-teils"), NSLocalizedString(@"Trifft zu *", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu *", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils *", @"teils-teils"), NSLocalizedString(@"Trifft zu *", @"Trifft zu")],
                                                  @[NSLocalizedString(@"leicht *", @"Schwierigkeit: leicht"), @"", NSLocalizedString(@"schwer *", @"Schwierigkeit: schwer")],
                                                  @[NSLocalizedString(@"niedrig *", @"Fähigkeiten: niedrig"), @"", NSLocalizedString(@"hoch *", @"Fähigkeiten: hoch")],
                                                  @[NSLocalizedString(@"zu gering *", @"Beanspruchung: zu gering"), NSLocalizedString(@"gerade richtig *", @"Beanspruchung: gerade richtig"), NSLocalizedString(@"zu hoch *", @"Beanspruchung: zu hoch")]
                                                  ];

    return flowShortScaleViewController;
}

@end
