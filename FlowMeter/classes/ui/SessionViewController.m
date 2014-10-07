//
//  SessionViewController.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 16.01.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "SessionViewController.h"
#import "AppDelegate.h"
#import "User.h"
#import "Activity.h"
#import "Session.h"
#import "SelfReport.h"
#import "HeartRateRecord.h"
#import "MBProgressHUD.h"
#import "ZCSHoldProgress.h"
#import "LikertScaleViewController.h"
#import <AudioToolbox/AudioServices.h>

@interface SessionViewController ()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) Session *session;

@property (nonatomic, strong) NSTimer *selfReportTimer;
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, strong) NSTimer *stopWatchTimer;
@property (nonatomic, strong) NSDate *stopWatchStartDate;

@property (nonatomic, strong) NSDate *startSelfReportDate;
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
@property (nonatomic) NSTimeInterval lastTimeInterval;

@property (nonatomic, weak) IBOutlet UIView *countdownBackgroundView;
@property (nonatomic, weak) IBOutlet UILabel *countdownLabel;
@property (nonatomic, weak) IBOutlet UILabel *stopWatchLabel;
@property (nonatomic, weak) IBOutlet UIView *stopButtonView;
@property (nonatomic, weak) IBOutlet UILabel *heartRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *firstUnitStopWatchLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondUnitStopWatchLabel;
@property (weak, nonatomic) IBOutlet UILabel *selfReportCountLabel;



@end

@implementation SessionViewController

#pragma mark -
#pragma mark - Getter

- (AppDelegate *)appDelegate
{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (Session *)session
{
    if (!_session) {
        _session = [NSEntityDescription insertNewObjectForEntityForName:@"Session" inManagedObjectContext:self.appDelegate.managedObjectContext];
    }
    return _session;
}

- (User *)getUserWithPredicate:(NSPredicate *)predicate
{
    User *user = nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.appDelegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setPredicate:predicate];
    
    NSArray *fetchedObjects = [self.appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects == nil) {
        // Handle the error.
    }
    
    if ([fetchedObjects count] == 0) {
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
    [fetchRequest setEntity:entity];
    
    [fetchRequest setPredicate:predicate];
    
    NSArray *fetchedObjects = [self.appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects == nil) {
        // Handle the error.
    }
    
    if ([fetchedObjects count] == 0) {
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
    
    // Start sensor updates
    [self startSensorUpdates];

    // Show UI or start countdown
    self.countdown = [[self.sessionData[1][1] objectForKey:kValueKey] intValue];
    if (self.countdown < 1) {
        [self showUI];
    } else {
       [self startCountdown];
    }
    
    // Hide status bar
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    // Set hold press on button
    ZCSHoldProgress *holdProgress = [[ZCSHoldProgress alloc] initWithTarget:self action:@selector(gestureRecogizerTarget:)];
    holdProgress.minimumPressDuration = 1.0;
    holdProgress.allowableMovement = 0;
    holdProgress.hideOnComplete = NO;
    
    holdProgress.alpha = 1.0f;
    holdProgress.color = [UIColor colorWithRed:0.17281592153284672 green:0.51933166058394165 blue:0.76862745098038943 alpha:1.0];
    holdProgress.completedColor = [UIColor colorWithRed:0.17281592153284672 green:0.51933166058394165 blue:0.76862745098038943 alpha:1.0];
    holdProgress.borderSize = 0.0f;
    holdProgress.size = 164.0f;
    holdProgress.minimumSize = 80.0f;
    [self.stopButtonView addGestureRecognizer:holdProgress];
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

- (void)gestureRecogizerTarget:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.isCollecting = !self.isCollecting;
        [self stopSensorUpdates];
        
        self.session.duration = [NSNumber numberWithDouble:[self stopWatchTimeInterval]];
        
        [self.stopWatchTimer invalidate];
        
        if ([[self.sessionData[2][0] objectForKey:kValueKey] boolValue]) {
            [self.selfReportTimer invalidate];
            self.isLastSelfReport = YES;
            
            [self showSelfReport];
        } else {
            [self saveData];
        }
    }
}

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
                         self.stopWatchLabel.text = @"00:00";
                         self.firstUnitStopWatchLabel.text = NSLocalizedString(@"MIN", @"Minuten Einheit Label im SessionViewController");
                         self.secondUnitStopWatchLabel.text = NSLocalizedString(@"S", @"Sekunden Einheit Label im SessionViewController");
                         self.heartRateLabel.text = NSLocalizedString(@"NA", @"Anfangs-Heartrate Label im SessionViewController");
                         self.selfReportCountLabel.text = @"0";
                         [self startCollecting];
                     }];
}

- (void)startStopWatch
{
    self.stopWatchStartDate = [NSDate date];
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
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
    
    if (elapsedTime < 1 * 60 * 60) {
        [dateFormatter setDateFormat:@"mm:ss"];
        self.firstUnitStopWatchLabel.text = NSLocalizedString(@"MIN", @"Minuten Einheit Label im SessionViewController");
        self.secondUnitStopWatchLabel.text = NSLocalizedString(@"S", @"Sekunden Einheit Label im SessionViewController");
    } else {
        [dateFormatter setDateFormat:@"HH:mm"];
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
    return [currentDate timeIntervalSinceDate:self.stopWatchStartDate];
}

- (void)startSensorUpdates
{
    // Start heart rate monitor updates
    if (self.appDelegate.heartRateMonitorManager.hasConnection) {
        self.appDelegate.heartRateMonitorManager.delegate = self;
        [self.appDelegate.heartRateMonitorManager startMonitoring];
    }
}

- (void)stopSensorUpdates
{
    // Stop heart rate monitor updates
    if (self.appDelegate.heartRateMonitorManager.hasConnection) {
        [self.appDelegate.heartRateMonitorManager stopMonitoring];
    }
}

- (void)startCollecting
{
    NSLog(@"# Start collecting");
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.session.date = [NSDate date];
    self.startSelfReportDate = nil;
    self.selfReportCount = 0;
    self.flowSum = 0.0;
    self.fluencySum = 0.0;
    self.absorptionSum = 0.0;
    self.anxietySum = 0.0;
    self.fitSum = 0.0;
    self.heartRateCount = 0;
    self.heartRateSum = 0;
    
    NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"(firstName == %@) AND (lastName == %@)", [self.sessionData[0][0] objectForKey:kValueKey], [self.sessionData[0][1] objectForKey:kValueKey]];
    User *user = [self getUserWithPredicate:userPredicate];
    
    if (user.firstName == nil && user.lastName == nil) {
        user.firstName = [self.sessionData[0][0] objectForKey:kValueKey];
        user.lastName = [self.sessionData[0][1] objectForKey:kValueKey];
    }
    self.session.user = user;
    
    
    NSPredicate *activityPredicate = [NSPredicate predicateWithFormat:@"(name == %@)", [self.sessionData[1][0] objectForKey:kValueKey]];
    Activity *activity = [self getActivityWithPredicate:activityPredicate];
    
    if (activity.name == nil) {
        activity.name = [self.sessionData[1][0] objectForKey:kValueKey];
    }
    self.session.activity = activity;
    self.isCollecting = !self.isCollecting;
    
    [self startStopWatch];
    
    if ([[self.sessionData[2][0] objectForKey:kValueKey] boolValue]) {
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
                         self.session.selfReportCount = [NSNumber numberWithInt:self.selfReportCount];
                         if ([self.session.selfReportCount integerValue] != 0) {
                             self.session.averageAbsorption = [NSNumber numberWithFloat:self.absorptionSum / self.selfReportCount];
                             self.session.averageAnxiety = [NSNumber numberWithFloat:self.anxietySum / self.selfReportCount];
                             self.session.averageFit = [NSNumber numberWithFloat:self.fitSum / self.selfReportCount];
                             self.session.averageFlow = [NSNumber numberWithFloat:self.flowSum / self.selfReportCount];
                             self.session.averageFluency = [NSNumber numberWithFloat:self.fluencySum / self.selfReportCount];
                         }
                         
                         if (self.heartRateCount != 0) {
                             self.session.averageBPM = [NSNumber numberWithFloat:self.heartRateSum / self.heartRateCount];
                         }
                         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                             [self.appDelegate saveContext];
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
        for (NSNumber *rrInterval in data.rrIntervals) {
            HeartRateRecord *heartRateRecord = [NSEntityDescription insertNewObjectForEntityForName:@"HeartRateRecord" inManagedObjectContext:self.appDelegate.managedObjectContext];
            heartRateRecord.date = [NSDate date];
            heartRateRecord.rrInterval = rrInterval;
            heartRateRecord.heartRate = [NSNumber numberWithDouble:60/([rrInterval doubleValue]/1000)];
            self.lastTimeInterval = self.lastTimeInterval + [rrInterval doubleValue];
            heartRateRecord.timeInterval = [NSNumber numberWithDouble:self.lastTimeInterval];
            [self.session addHeartRateRecordsObject:heartRateRecord];
        }
    }
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didDisconnectHeartrateMonitorDevice:(CBPeripheral *)heartRateMonitorDevice
                          error:(NSError *)error
{
    AudioServicesPlaySystemSound(1073);
    self.heartRateLabel.text = NSLocalizedString(@"ERR", "Fehleranzeige - HR Monitor wurde getrennt");
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didConnectHeartrateMonitorDevice:(CBPeripheral *)heartRateMonitorDevice
{
    self.lastTimeInterval = 0.0;
    [manager startMonitoring];
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
    selfReport.date = self.startSelfReportDate;
    selfReport.duration = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceDate:self.startSelfReportDate]];
    NSDictionary *flowShortScaleFactors = [self calculateFlowShortScaleFactorsFromResponses:responses];
    selfReport.flow = [flowShortScaleFactors objectForKey:@"flow"];
    selfReport.flowSD = [flowShortScaleFactors objectForKey:@"flowSD"];
    selfReport.fluency = [flowShortScaleFactors objectForKey:@"fluency"];
    selfReport.fluencySD = [flowShortScaleFactors objectForKey:@"fluencySD"];
    selfReport.absorption = [flowShortScaleFactors objectForKey:@"absorption"];
    selfReport.absorptionSD = [flowShortScaleFactors objectForKey:@"absorptionSD"];
    selfReport.anxiety = [flowShortScaleFactors objectForKey:@"anxiety"];
    selfReport.anxietySD = [flowShortScaleFactors objectForKey:@"anxietySD"];
    selfReport.fit = [flowShortScaleFactors objectForKey:@"fit"];
    selfReport.fitSD = [flowShortScaleFactors objectForKey:@"fitSD"];
    
    self.selfReportCount++;
    
    self.selfReportCountLabel.text = [NSString stringWithFormat:@"%d", self.selfReportCount];
    
    self.flowSum += [selfReport.flow floatValue];
    self.fluencySum += [selfReport.fluency floatValue];
    self.absorptionSum += [selfReport.absorption floatValue];
    self.anxietySum += [selfReport.anxiety floatValue];
    self.fitSum += [selfReport.fit floatValue];
    
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
    self.startSelfReportDate = [NSDate date];
    AudioServicesPlaySystemSound(1008);
    
    if ([[self.sessionData[2][0] objectForKey:kValueKey] boolValue]) {
        [self presentViewController:[self flowShortScaleViewControllerFromStoryboard] animated:YES completion:nil];
    }
}

- (LikertScaleViewController *)flowShortScaleViewControllerFromStoryboard
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    LikertScaleViewController *flowShortScaleViewController = (LikertScaleViewController *)[storyboard instantiateViewControllerWithIdentifier:@"LikertScale"];
    
    flowShortScaleViewController.delegate = self;
    
    flowShortScaleViewController.itemLabelTexts = @[
                                                     NSLocalizedString(@"Ich fühle mich optimal beansprucht.", @"Ich fühle mich optimal beansprucht."),
                                                     NSLocalizedString(@"Meine Gedanken bzw. Aktivitäten laufen flüssig und glatt.", @"Meine Gedanken bzw. Aktivitäten laufen flüssig und glatt."),
                                                     NSLocalizedString(@"Ich merke gar nicht, wie die Zeit vergeht.", @"Ich merke gar nicht, wie die Zeit vergeht."),
                                                     NSLocalizedString(@"Ich habe keine Mühe, mich zu konzentrieren.", @"Ich habe keine Mühe, mich zu konzentrieren."),
                                                     NSLocalizedString(@"Mein Kopf ist völlig klar.", @"Mein Kopf ist völlig klar."),
                                                     NSLocalizedString(@"Ich bin ganz vertieft in das, was ich gerade mache.", @"Ich bin ganz vertieft in das, was ich gerade mache."),
                                                     NSLocalizedString(@"Die richtigen Gedanken/Bewegungen kommen wie von selbst.", @"Die richtigen Gedanken/Bewegungen kommen wie von selbst."),
                                                     NSLocalizedString(@"Ich weiß bei jedem Schritt, was ich zu tun habe.", @"Ich weiß bei jedem Schritt, was ich zu tun habe."),
                                                     NSLocalizedString(@"Ich habe das Gefühl, den Ablauf unter Kontrolle zu haben.", @"Ich habe das Gefühl, den Ablauf unter Kontrolle zu haben."),
                                                     NSLocalizedString(@"Ich bin völlig selbstvergessen.", @"Ich bin völlig selbstvergessen."),
                                                     NSLocalizedString(@"Es steht etwas für mich Wichtiges auf dem Spiel.", @"Es steht etwas für mich Wichtiges auf dem Spiel."),
                                                     NSLocalizedString(@"Ich darf jetzt keine Fehler machen.", @"Ich darf jetzt keine Fehler machen."),
                                                     NSLocalizedString(@"Ich mache mir Sorgen über einen Misserfolg.", @"Ich mache mir Sorgen über einen Misserfolg."),
                                                     NSLocalizedString(@"Verglichen mit allen anderen Tätigkeiten, die ich sonst mache, ist die jetzige Tätigkeit...", @"Verglichen mit allen anderen Tätigkeiten, die ich sonst mache, ist die jetzige Tätigkeit..."),
                                                     NSLocalizedString(@"Ich denke, meine Fähigkeiten auf diesem Gebiet sind...", @"Ich denke, meine Fähigkeiten auf diesem Gebiet sind..."),
                                                     NSLocalizedString(@"Für mich persönlich sind die jetzigen Anforderungen...", @"Für mich persönlich sind die jetzigen Anforderungen...")
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
                                                  @[NSLocalizedString(@"niedrig", @"Fähigkeiten: niedrig"), @"", NSLocalizedString(@"hoch", @"Fähigkeiten: hoch")],
                                                  @[NSLocalizedString(@"zu gering", @"Beanspruchung: zu gering"), NSLocalizedString(@"gerade richtig", @"Beanspruchung: gerade richtig"), NSLocalizedString(@"zu hoch", @"Beanspruchung: zu hoch")]
                                                  ];

    return flowShortScaleViewController;
}

- (NSDictionary *)calculateFlowShortScaleFactorsFromResponses:(NSArray *)responses
{
    NSArray *flowItems = @[[responses objectAtIndex:0], [responses objectAtIndex:1], [responses objectAtIndex:2], [responses objectAtIndex:3], [responses objectAtIndex:4], [responses objectAtIndex:5], [responses objectAtIndex:6], [responses objectAtIndex:7], [responses objectAtIndex:8], [responses objectAtIndex:9]];
    NSArray *fluencyItems = @[[responses objectAtIndex:7], [responses objectAtIndex:6], [responses objectAtIndex:8], [responses objectAtIndex:3], [responses objectAtIndex:4], [responses objectAtIndex:1]];
    NSArray *absorptionItems = @[[responses objectAtIndex:5], [responses objectAtIndex:0], [responses objectAtIndex:9], [responses objectAtIndex:2]];
    NSArray *anxietyItems = @[[responses objectAtIndex:10], [responses objectAtIndex:11], [responses objectAtIndex:12]];
    NSArray *fitItems = @[[responses objectAtIndex:13], [responses objectAtIndex:14], [responses objectAtIndex:15]];
    
    
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
    NSTimeInterval time = [[self.sessionData[2][1] objectForKey:kValueKey] doubleValue];
    NSTimeInterval variability = random() % ((int)([[self.sessionData[2][2] objectForKey:kValueKey] doubleValue]) / 2);
    if(random() % 2 == 0) {
        return time + variability;
    } else {
        return time - variability;
    }
}

@end
