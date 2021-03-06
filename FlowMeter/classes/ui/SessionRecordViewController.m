//
//  SessionRecordViewController.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 16.01.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "SessionRecordViewController.h"
#import "AppDelegate.h"
#import "User.h"
#import "Activity.h"
#import "Session.h"
#import "SelfReport.h"
#import "HeartRateRecord.h"
#import "MBProgressHUD.h"
#import "LikertScaleViewController.h"
#import <AudioToolbox/AudioServices.h>
#import <CoreMotion/CoreMotion.h>
#import "MotionRecord.h"
#import "LocationRecord.h"
#import "ABFillButton.h"
#import "DBManager.h"

@interface SessionRecordViewController () <ABFillButtonDelegate>

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) Session *session;
@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, strong) NSTimer *selfReportTimer;
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, strong) NSTimer *stopWatchTimer;

@property (nonatomic) NSTimeInterval startSelfReportTimestamp;
@property (nonatomic) int selfReportCount;
@property (nonatomic) float absorptionSum;
@property (nonatomic) float anxietySum;
@property (nonatomic) float fitSum;
@property (nonatomic) float flowSum;
@property (nonatomic) float fluencySum;

@property (nonatomic) BOOL isCollecting;
@property (nonatomic) BOOL isLastSelfReport;
@property (nonatomic) int countdown;
@property (nonatomic) int heartRateCount;
@property (nonatomic) long heartRateSum;

@property (nonatomic, strong) NSNumber *firstMotionTimestamp;
@property (nonatomic, strong) NSNumber *firstHeartRateTimestamp;

@property (nonatomic, strong) DBManager *dbManager;
@property (nonatomic) int sessionPK;

@property (nonatomic, weak) IBOutlet UIView *countdownBackgroundView;
@property (nonatomic, weak) IBOutlet UILabel *countdownLabel;
@property (nonatomic, weak) IBOutlet UILabel *stopWatchLabel;
@property (nonatomic, weak) IBOutlet ABFillButton *stopButton;
@property (nonatomic, weak) IBOutlet UILabel *heartRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *firstUnitStopWatchLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondUnitStopWatchLabel;
@property (weak, nonatomic) IBOutlet UILabel *selfReportCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *skinTemperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *postureLabel;
@property (weak, nonatomic) IBOutlet UILabel *activityLevelLabel;
@property (weak, nonatomic) IBOutlet UILabel *breathRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *activityLevelSignLabel;
@property (weak, nonatomic) IBOutlet UILabel *postureSignLabel;
@property (weak, nonatomic) IBOutlet UILabel *skinTemperatureSignLabel;
@property (weak, nonatomic) IBOutlet UILabel *breathRateSignLabel;

@end

@implementation SessionRecordViewController

#pragma mark -
#pragma mark - Getter

- (AppDelegate *)appDelegate
{
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

- (Session *)session
{
    if (!_session) {
        _session = [NSEntityDescription insertNewObjectForEntityForName:@"Session" inManagedObjectContext:self.appDelegate.managedObjectContext];
        [self.appDelegate saveContext];
        
        // Load session pk
        NSManagedObjectID *sessionID = self.session.objectID;
        self.sessionPK = [[sessionID URIRepresentation].absoluteString.lastPathComponent substringFromIndex:1].intValue;
    }
    return _session;
}

- (User *)getUserWithPredicate:(NSPredicate *)predicate
{
    User *user = nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.appDelegate.managedObjectContext];
    fetchRequest.entity = entity;
    
    fetchRequest.predicate = predicate;
    
    NSArray *fetchedObjects = [self.appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects == nil) {
        // Handle the error.
    }
    
    if (fetchedObjects.count == 0) {
        user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:self.appDelegate.managedObjectContext];
    } else {
        user = fetchedObjects[0];
    }
    
    return user;
}

- (Activity *)getActivityWithPredicate:(NSPredicate *)predicate
{
    Activity *activity = nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Activity" inManagedObjectContext:self.appDelegate.managedObjectContext];
    fetchRequest.entity = entity;
    
    fetchRequest.predicate = predicate;
    
    NSArray *fetchedObjects = [self.appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects == nil) {
        // Handle the error.
    }
    
    if (fetchedObjects.count == 0) {
        activity = [NSEntityDescription insertNewObjectForEntityForName:@"Activity" inManagedObjectContext:self.appDelegate.managedObjectContext];
    } else {
        activity = fetchedObjects[0];
    }
    
    return activity;
}

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.motionManager = [[CMMotionManager alloc] init];
    
    // Start sensor updates
    [self startSensorUpdates];

    // Show UI or start countdown
    self.countdown = [(self.sessionData[1][1])[kValueKey] intValue];
    if (self.countdown < 1) {
        [self showUI];
    } else {
       [self startCountdown];
    }
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    
    //If we want to add shadows and a grow up effect when user press the button
    [self.stopButton configureButtonWithHightlightedShadowAndZoom:NO];
    
    //If we want to empty the button with user pressing
    [self.stopButton setEmptyButtonPressing:YES];
    (self.stopButton).fillPercent = 1.0;
    
    // Initialize the dbManager object
    self.dbManager = [[DBManager alloc] initWithDatabaseFilename:@"FlowMeter.sqlite"];
    
    self.stopWatchLabel.text = @"00:00";
    self.firstUnitStopWatchLabel.text = NSLocalizedString(@"MIN", @"Minuten Einheit Label im SessionViewController");
    self.secondUnitStopWatchLabel.text = NSLocalizedString(@"S", @"Sekunden Einheit Label im SessionViewController");
    self.heartRateLabel.text = NSLocalizedString(@"NA", @"Anfangs-Label im SessionViewController");
    self.breathRateLabel.text = NSLocalizedString(@"NA", @"Anfangs-Label im SessionViewController");
    self.skinTemperatureLabel.text = NSLocalizedString(@"NA", @"Anfangs-Label im SessionViewController");
    self.postureLabel.text = NSLocalizedString(@"NA", @"Anfangs-Label im SessionViewController");
    self.activityLevelLabel.text = NSLocalizedString(@"NA", @"Anfangs-Label im SessionViewController");
    self.selfReportCountLabel.text = @"0";
}

- (bool)prefersStatusBarHidden {
    return YES;
}

#pragma mark -
#pragma mark - Setter

- (void)setCountdown:(int)countdown
{
    _countdown = countdown;
    BOOL hidden = self.countdown < 1;
    self.countdownLabel.hidden = hidden;
    self.countdownLabel.text = [NSString stringWithFormat:@"%d", self.countdown];
}

#pragma mark -
#pragma mark - Convient methods

- (void)startCountdown
{
    self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                    target:self
                                                                  selector:@selector(updateCountdown)
                                                                  userInfo:nil repeats:YES];
}

- (void)updateCountdown
{
    self.countdown--;
    if (self.countdown <= 0) {
        [self.countdownTimer invalidate];
        [self showUI];
    }
}

- (void)showUI
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.countdownBackgroundView.alpha = 0.0;   // fade out
                         self.countdownLabel.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                         self.countdownBackgroundView.hidden = YES;
                         [self startCollecting];
                     }];
}

- (void)startStopWatch
{
    self.session.date = [NSDate date];
    self.stopWatchTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0
                                                           target:self
                                                         selector:@selector(updateStopWatch)
                                                         userInfo:nil
                                                          repeats:YES];
}

- (void)updateStopWatch
{
    NSTimeInterval elapsedTime = [self stopWatchTimeInterval];
    NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:elapsedTime];
    
    // Create a date formatter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0.0];
    
    if (elapsedTime < 1 * 60 * 60) {
        dateFormatter.dateFormat = @"mm:ss";
        self.firstUnitStopWatchLabel.text = NSLocalizedString(@"MIN", @"Minuten Einheit Label im SessionViewController");
        self.secondUnitStopWatchLabel.text = NSLocalizedString(@"S", @"Sekunden Einheit Label im SessionViewController");
    } else {
        dateFormatter.dateFormat = @"HH:mm";
        self.firstUnitStopWatchLabel.text = NSLocalizedString(@"H", @"Stunden Einheit Label im SessionViewController");
        self.secondUnitStopWatchLabel.text = NSLocalizedString(@"MIN", @"Minuten Einheit Label im SessionViewController");
    }
    
    // Format the elapsed time and set it to the label
    NSString *timeString = [dateFormatter stringFromDate:timerDate];
    self.stopWatchLabel.text = timeString;
}

- (NSTimeInterval)stopWatchTimeInterval
{
    // Create date from the elapsed time
    NSDate *currentDate = [NSDate date];
    return [currentDate timeIntervalSinceDate:self.session.date];
}

- (void)startSensorUpdates
{
    // Start heart rate monitor updates
    if (self.appDelegate.heartRateMonitorManager.hasConnection) {
        self.appDelegate.heartRateMonitorManager.delegate = self;
        [self.appDelegate.heartRateMonitorManager startMonitoring];
        self.firstHeartRateTimestamp = nil;
    }
    
    // Start location updates
    if ([(self.sessionData[3][0])[kValueKey] boolValue]) {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways && [CLLocationManager locationServicesEnabled]) {
            self.appDelegate.locationManager.delegate = self;
            [self.appDelegate.locationManager startUpdatingLocation];
        }
    }
    
    // Start motion manager updates
    if ([(self.sessionData[3][1])[kValueKey] boolValue]) {
        self.firstMotionTimestamp = nil;
        
        if ((self.motionManager).deviceMotionAvailable == YES) {
            (self.motionManager).deviceMotionUpdateInterval = 1/102.4;
            [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
                if(self.isCollecting) {
                    if (error == nil) {
                        
                        NSTimeInterval timestamp = 0.0;
                        if (self.firstMotionTimestamp == nil) {
                            timestamp = fabs((self.session.date).timeIntervalSinceNow);
                            self.firstMotionTimestamp = @(motion.timestamp - timestamp);
                        } else {
                            timestamp = motion.timestamp - (self.firstMotionTimestamp).doubleValue;
                        }
                        
                        NSString *query = [NSString stringWithFormat:@"INSERT INTO ZMOTIONRECORD VALUES(NULL, 4, 1, %d, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)", self.sessionPK, motion.attitude.pitch, motion.attitude.roll, motion.attitude.yaw, motion.gravity.x, motion.gravity.y, motion.gravity.z, motion.rotationRate.x, motion.rotationRate.y, motion.rotationRate.z, timestamp, motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z];
                        
                        [self.dbManager executeQuery:query];
                    }
                }
            }];
        }
    }
}

- (void)stopSensorUpdates
{
    // Stop heart rate monitor updates
    if (self.appDelegate.heartRateMonitorManager.hasConnection) {
        [self.appDelegate.heartRateMonitorManager stopMonitoring];
    }
    
    // Stop location updates
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways && [CLLocationManager locationServicesEnabled]) {
        [self.appDelegate.locationManager stopUpdatingLocation];
    }
    
    // Stop motion manager updates
    if ((self.motionManager).deviceMotionActive == YES) {
        [self.motionManager stopDeviceMotionUpdates];
    }
}

- (void)startCollecting
{
    NSLog(@"# Start collecting");
    self.selfReportCount = 0;
    self.flowSum = 0.0;
    self.fluencySum = 0.0;
    self.absorptionSum = 0.0;
    self.anxietySum = 0.0;
    self.fitSum = 0.0;
    self.heartRateCount = 0;
    self.heartRateSum = 0;
    
    NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"(firstName == %@) AND (lastName == %@)", (self.sessionData[0][0])[kValueKey], (self.sessionData[0][1])[kValueKey]];
    User *user = [self getUserWithPredicate:userPredicate];
    
    if (user.firstName == nil && user.lastName == nil) {
        user.firstName = (self.sessionData[0][0])[kValueKey];
        user.lastName = (self.sessionData[0][1])[kValueKey];
    }
    self.session.user = user;
    
    
    NSPredicate *activityPredicate = [NSPredicate predicateWithFormat:@"(name == %@)", (self.sessionData[1][0])[kValueKey]];
    Activity *activity = [self getActivityWithPredicate:activityPredicate];
    
    if (activity.name == nil) {
        activity.name = (self.sessionData[1][0])[kValueKey];
    }
    self.session.activity = activity;
    
    [self startStopWatch];
    self.isCollecting = !self.isCollecting;
    
    if ([(self.sessionData[2][0])[kValueKey] boolValue]) {
        self.selfReportTimer = [NSTimer scheduledTimerWithTimeInterval:[self timeToNextSelfReport] target:self selector:@selector(showSelfReport) userInfo:nil repeats:NO];
    }
}

- (void)saveData
{
    self.countdownBackgroundView.hidden = NO;
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.countdownBackgroundView.alpha = 1.0;   // fade in
                     }
                     completion:^(BOOL finished){
                         
                         if (self.selfReportCount != 0) {
                             self.session.selfReportCount = self.selfReportCount;
                             self.session.averageAbsorption = self.absorptionSum / self.selfReportCount;
                             self.session.averageAnxiety = self.anxietySum / self.selfReportCount;
                             self.session.averageFit = self.fitSum / self.selfReportCount;
                             self.session.averageFlow = self.flowSum / self.selfReportCount;
                             self.session.averageFluency = self.fluencySum / self.selfReportCount;
                         } else {
                             self.session.selfReportCount = 0;
                             self.session.averageAbsorption = 0.f;
                             self.session.averageAnxiety = 0.f;
                             self.session.averageFit = 0.f;
                             self.session.averageFlow = 0.f;
                             self.session.averageFluency = 0.f;
                         }
                         
                         if (self.heartRateCount != 0) {
                             self.session.averageHeartrate = self.heartRateSum / self.heartRateCount;
                         } else {
                             self.session.averageHeartrate = 0.f;
                         }
                         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                             [self.appDelegate saveContext];
                             [self.appDelegate.managedObjectContext reset];
                             self.appDelegate.managedObjectContext = nil;
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [self dismissViewControllerAnimated:YES completion:^{
                                     
                                 }];
                             });
                         });
                     }];
}

#pragma mark -
#pragma mark - HeartRateMonitorManagerDelegate implementation

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager didReceiveHeartrateMonitorData:(HeartRateMonitorData *)data fromHeartRateMonitorDevice:(HeartRateMonitorDevice *)device
{
    if(self.isCollecting) {
        if (data.heartRate != -1) {
            self.heartRateLabel.text = [NSString stringWithFormat:@"%d", data.heartRate];
        }
        
        self.heartRateCount++;
        self.heartRateSum = self.heartRateSum + data.heartRate;
        
        long rrDataCount = (data.rrTimes).count;
//        AudioServicesPlaySystemSound(1057);
        for (int i = 0; i < rrDataCount; i++) {
            
            NSTimeInterval timestamp = 0.0;
            if (self.firstMotionTimestamp == nil) {
                timestamp = fabs((self.session.date).timeIntervalSinceNow);
                self.firstMotionTimestamp = @([(data.rrTimes)[i] doubleValue] - timestamp);
            } else {
                timestamp = [(data.rrTimes)[i] doubleValue] - (self.firstHeartRateTimestamp).doubleValue;
            }
            
            NSString *query = [NSString stringWithFormat:@"INSERT INTO ZHEARTRATERECORD VALUES(NULL, 2, 1, %d, %d, %f, %f)", data.heartRate, self.sessionPK, [(data.rrIntervals)[i] doubleValue], timestamp];
            
            [self.dbManager executeQuery:query];
        }
    }
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didDisconnectHeartrateMonitorDevice:(CBPeripheral *)heartRateMonitorDevice
                          error:(NSError *)error
{
    AudioServicesPlaySystemSound(1073);
    self.heartRateLabel.text = NSLocalizedString(@"ERR", "Fehleranzeige - HR Monitor wurde getrennt");
    self.breathRateLabel.text = NSLocalizedString(@"ERR", "Fehleranzeige - HR Monitor wurde getrennt");
    self.postureLabel.text = NSLocalizedString(@"ERR", "Fehleranzeige - HR Monitor wurde getrennt");
    self.skinTemperatureLabel.text = NSLocalizedString(@"ERR", "Fehleranzeige - HR Monitor wurde getrennt");
    self.activityLevelLabel.text = NSLocalizedString(@"ERR", "Fehleranzeige - HR Monitor wurde getrennt");
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didConnectHeartrateMonitorDevice:(CBPeripheral *)heartRateMonitorDevice
{
    [manager startMonitoring];
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager didReceiveBioHarnessData:(BioharnessData *)data fromHeartRateMonitorDevice:(HeartRateMonitorDevice *)device {
    if (self.breathRateLabel.hidden) {
        self.breathRateLabel.hidden = NO;
        self.breathRateSignLabel.hidden = NO;
        self.postureLabel.hidden = NO;
        self.postureSignLabel.hidden = NO;
        self.skinTemperatureLabel.hidden = NO;
        self.skinTemperatureSignLabel.hidden = NO;
        self.activityLevelLabel.hidden = NO;
        self.activityLevelSignLabel.hidden = NO;
    }
    
    
    self.breathRateLabel.text = [NSString stringWithFormat:@"%.1f", data.breathRate];
    self.postureLabel.text = [NSString stringWithFormat:@"%d", data.posture];
    self.skinTemperatureLabel.text = [NSString stringWithFormat:@"%.1f", data.skinTemperature];
    self.activityLevelLabel.text = [NSString stringWithFormat:@"%.2f", data.activityLevel];
}

#pragma mark -
#pragma mark - LikertScaleViewControllerDelegate implementation

- (void)likertScaleViewController:(LikertScaleViewController *)viewController didFinishWithResponses:(NSArray *)responses atDate:(NSDate *)date
{
    [viewController dismissViewControllerAnimated:YES
                                       completion:^{
                                           ;
                                       }];
    
    SelfReport *selfReport = [NSEntityDescription insertNewObjectForEntityForName:@"SelfReport" inManagedObjectContext:self.appDelegate.managedObjectContext];
    selfReport.timestamp = self.startSelfReportTimestamp;
    selfReport.duration = fabs((self.session.date).timeIntervalSinceNow) - selfReport.timestamp;
    NSDictionary *flowShortScaleFactors = [self calculateFlowShortScaleFactorsFromResponses:responses];
    selfReport.flow = [flowShortScaleFactors[@"flow"] floatValue];
    selfReport.flowSD = [flowShortScaleFactors[@"flowSD"] floatValue];
    selfReport.fluency = [flowShortScaleFactors[@"fluency"] floatValue];
    selfReport.fluencySD = [flowShortScaleFactors[@"fluencySD"] floatValue];
    selfReport.absorption = [flowShortScaleFactors[@"absorption"] floatValue];
    selfReport.absorptionSD = [flowShortScaleFactors[@"absorptionSD"] floatValue];
    selfReport.anxiety = [flowShortScaleFactors[@"anxiety"] floatValue];
    selfReport.anxietySD = [flowShortScaleFactors[@"anxietySD"] floatValue];
    selfReport.fit = [flowShortScaleFactors[@"fit"] floatValue];
    selfReport.fitSD = [flowShortScaleFactors[@"fitSD"] floatValue];
    
    self.selfReportCount++;
    
    self.selfReportCountLabel.text = [NSString stringWithFormat:@"%d", self.selfReportCount];
    
    self.flowSum += selfReport.flow;
    self.fluencySum += selfReport.fluency;
    self.absorptionSum += selfReport.absorption;
    self.anxietySum += selfReport.anxiety;
    self.fitSum += selfReport.fit;
    
    [self.session addSelfReportsObject:selfReport];
    
    if (self.isCollecting) {
        self.selfReportTimer = [NSTimer scheduledTimerWithTimeInterval:[self timeToNextSelfReport] target:self selector:@selector(showSelfReport) userInfo:nil repeats:NO];
    } else {
        if (self.isLastSelfReport) {
            [self saveData];
            self.isLastSelfReport = NO;
        }
    }
}

- (void)likertScaleViewControllerCancelled:(LikertScaleViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES
                                       completion:^{
                                           ;
                                       }];
    if (self.isCollecting) {
        self.selfReportTimer = [NSTimer scheduledTimerWithTimeInterval:[self timeToNextSelfReport] target:self selector:@selector(showSelfReport) userInfo:nil repeats:NO];
    } else {
        if (self.isLastSelfReport) {
            [self saveData];
            self.isLastSelfReport = NO;
        }
    }
}

#pragma mark -
#pragma mark - Self-reports

- (void)showSelfReport
{
    self.startSelfReportTimestamp = fabs((self.session.date).timeIntervalSinceNow);
    AudioServicesPlaySystemSound(1008);
    [self presentViewController:[self flowShortScaleViewControllerFromStoryboard] animated:YES completion:nil];
}

- (LikertScaleViewController *)flowShortScaleViewControllerFromStoryboard
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    LikertScaleViewController *flowShortScaleViewController = (LikertScaleViewController *)[storyboard instantiateViewControllerWithIdentifier:@"LikertScale"];
    
    flowShortScaleViewController.delegate = self;
    flowShortScaleViewController.cicleColors = self.appDelegate.colors;
    
    flowShortScaleViewController.itemLabelTexts = @[
                                                     NSLocalizedString(@"Ich fu??hle mich optimal beansprucht.", @"Ich fu??hle mich optimal beansprucht."),
                                                     NSLocalizedString(@"Meine Gedanken bzw. Aktivita??ten laufen flu??ssig und glatt.", @"Meine Gedanken bzw. Aktivita??ten laufen flu??ssig und glatt."),
                                                     NSLocalizedString(@"Ich merke gar nicht, wie die Zeit vergeht.", @"Ich merke gar nicht, wie die Zeit vergeht."),
                                                     NSLocalizedString(@"Ich habe keine Mu??he, mich zu konzentrieren.", @"Ich habe keine Mu??he, mich zu konzentrieren."),
                                                     NSLocalizedString(@"Mein Kopf ist vo??llig klar.", @"Mein Kopf ist vo??llig klar."),
                                                     NSLocalizedString(@"Ich bin ganz vertieft in das, was ich gerade mache.", @"Ich bin ganz vertieft in das, was ich gerade mache."),
                                                     NSLocalizedString(@"Die richtigen Gedanken/Bewegungen kommen wie von selbst.", @"Die richtigen Gedanken/Bewegungen kommen wie von selbst."),
                                                     NSLocalizedString(@"Ich wei?? bei jedem Schritt, was ich zu tun habe.", @"Ich wei?? bei jedem Schritt, was ich zu tun habe."),
                                                     NSLocalizedString(@"Ich habe das Gefu??hl, den Ablauf unter Kontrolle zu haben.", @"Ich habe das Gefu??hl, den Ablauf unter Kontrolle zu haben."),
                                                     NSLocalizedString(@"Ich bin vo??llig selbstvergessen.", @"Ich bin vo??llig selbstvergessen."),
                                                     NSLocalizedString(@"Es steht etwas fu??r mich Wichtiges auf dem Spiel.", @"Es steht etwas fu??r mich Wichtiges auf dem Spiel."),
                                                     NSLocalizedString(@"Ich darf jetzt keine Fehler machen.", @"Ich darf jetzt keine Fehler machen."),
                                                     NSLocalizedString(@"Ich mache mir Sorgen u??ber einen Misserfolg.", @"Ich mache mir Sorgen u??ber einen Misserfolg."),
                                                     NSLocalizedString(@"Verglichen mit allen anderen Ta??tigkeiten, die ich sonst mache, ist die jetzige Ta??tigkeit...", @"Verglichen mit allen anderen Ta??tigkeiten, die ich sonst mache, ist die jetzige Ta??tigkeit..."),
                                                     NSLocalizedString(@"Ich denke, meine Fa??higkeiten auf diesem Gebiet sind...", @"Ich denke, meine Fa??higkeiten auf diesem Gebiet sind..."),
                                                     NSLocalizedString(@"Fu??r mich perso??nlich sind die jetzigen Anforderungen...", @"Fu??r mich perso??nlich sind die jetzigen Anforderungen...")
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
                                                  @[NSLocalizedString(@"Trifft nicht zu", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils", @"teils-teils"), NSLocalizedString(@"Trifft zu", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils", @"teils-teils"), NSLocalizedString(@"Trifft zu", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils", @"teils-teils"), NSLocalizedString(@"Trifft zu", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils", @"teils-teils"), NSLocalizedString(@"Trifft zu", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils", @"teils-teils"), NSLocalizedString(@"Trifft zu", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils", @"teils-teils"), NSLocalizedString(@"Trifft zu", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils", @"teils-teils"), NSLocalizedString(@"Trifft zu", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils", @"teils-teils"), NSLocalizedString(@"Trifft zu", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils", @"teils-teils"), NSLocalizedString(@"Trifft zu", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils", @"teils-teils"), NSLocalizedString(@"Trifft zu", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils", @"teils-teils"), NSLocalizedString(@"Trifft zu", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils", @"teils-teils"), NSLocalizedString(@"Trifft zu", @"Trifft zu")],
                                                  @[NSLocalizedString(@"Trifft nicht zu", @"Trifft nicht zu"), NSLocalizedString(@"teils-teils", @"teils-teils"), NSLocalizedString(@"Trifft zu", @"Trifft zu")],
                                                  @[NSLocalizedString(@"leicht", @"Schwierigkeit: leicht"), @"", NSLocalizedString(@"schwer", @"Schwierigkeit: schwer")],
                                                  @[NSLocalizedString(@"niedrig", @"F??higkeiten: niedrig"), @"", NSLocalizedString(@"hoch", @"F??higkeiten: hoch")],
                                                  @[NSLocalizedString(@"zu gering", @"Beanspruchung: zu gering"), NSLocalizedString(@"gerade richtig", @"Beanspruchung: gerade richtig"), NSLocalizedString(@"zu hoch", @"Beanspruchung: zu hoch")]
                                                  ];

    return flowShortScaleViewController;
}

- (NSDictionary *)calculateFlowShortScaleFactorsFromResponses:(NSArray *)responses
{
    NSArray *flowItems = @[responses[0], responses[1], responses[2], responses[3], responses[4], responses[5], responses[6], responses[7], responses[8], responses[9]];
    NSArray *fluencyItems = @[responses[7], responses[6], responses[8], responses[3], responses[4], responses[1]];
    NSArray *absorptionItems = @[responses[5], responses[0], responses[9], responses[2]];
    NSArray *anxietyItems = @[responses[10], responses[11], responses[12]];
    NSArray *fitItems = @[responses[13], responses[14], responses[15]];
    
    
    return @{@"flow" : [self meanFromNumbers:flowItems], @"flowSD" : [self sdFromNumbers:flowItems], @"fluency" : [self meanFromNumbers:fluencyItems], @"fluencySD" : [self sdFromNumbers:fluencyItems], @"absorption" : [self meanFromNumbers:absorptionItems], @"absorptionSD" : [self sdFromNumbers:flowItems], @"anxiety" : [self meanFromNumbers:anxietyItems], @"anxietySD" : [self sdFromNumbers:anxietyItems], @"fit" : [self meanFromNumbers:fitItems], @"fitSD" : [self sdFromNumbers:fitItems]};
}

- (NSNumber *)meanFromNumbers:(NSArray *)numbers
{
    NSExpression *expression = [NSExpression expressionForFunction:@"average:" arguments:@[[NSExpression expressionForConstantValue:numbers]]];
    return [expression expressionValueWithObject:nil context:nil];
}

- (NSNumber *)sdFromNumbers:(NSArray *)numbers
{
    NSExpression *expression = [NSExpression expressionForFunction:@"stddev:" arguments:@[[NSExpression expressionForConstantValue:numbers]]];
    return [expression expressionValueWithObject:nil context:nil];
}

- (NSTimeInterval)timeToNextSelfReport
{
    NSTimeInterval time = [(self.sessionData[2][1])[kValueKey] doubleValue];
    NSTimeInterval variability = random() % ((int)([(self.sessionData[2][2])[kValueKey] doubleValue]) / 2);
    if(random() % 2 == 0) {
        return time + variability;
    } else {
        return time - variability;
    }
}

#pragma mark -
#pragma mark - CLLocationManagerDelegate implementation

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (self.isCollecting) {
        CLLocation *newLocation = locations.firstObject;
        NSString *query = [NSString stringWithFormat:@"INSERT INTO ZLOCATIONRECORD VALUES(NULL, 3, 1, %ld, %d, %f, %f, %f, %f, %f, %f, %f, %f)", (long)newLocation.floor.level, self.sessionPK, newLocation.altitude, newLocation.course, (newLocation.timestamp).timeIntervalSinceReferenceDate, newLocation.horizontalAccuracy, newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.speed, newLocation.verticalAccuracy];
        
        [self.dbManager executeQuery:query];
    }
}

#pragma mark -
#pragma mark - ABFillButtonDelegate Implementation
- (void)buttonIsEmpty:(ABFillButton *)button
{
    self.isCollecting = !self.isCollecting;
    [self stopSensorUpdates];
    
    self.session.duration = [self stopWatchTimeInterval];
    
    [self.stopWatchTimer invalidate];
    
    //if ([[self.sessionData[2][0] objectForKey:kValueKey] boolValue]) {
    [self.selfReportTimer invalidate];
    self.isLastSelfReport = YES;
    
    [self showSelfReport];
    //        } else {
    //            [self saveData];
    //        }
}

@end
