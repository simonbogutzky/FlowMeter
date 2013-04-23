//
//  HomeViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 16.01.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "HomeViewController.h"
#import "AppDelegate.h"
#import "UserSessionVO.h"
#import "AudioController.h"

//#import "Reachability.h"


@interface HomeViewController ()
{
    WFSensorConnection *_sensorConnection;
    WFSensorType_t _sensorType;
    BOOL _isCollection;
    
    UserSessionVO *_userSession;
    int _lastAccumBeatCount;
    DBRestClient *_restClient;
    IBOutlet UILabel *_bmpLabel;
    //    Reachability *_internetReachable;
}


@end

@implementation HomeViewController

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create user session
    _userSession = [[UserSessionVO alloc] init];
    //    userSession.udid = [[UIDevice currentDevice] uniqueIdentifier];
    //    [self addUserSession];
    
//    [self testInternetConnection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadFile:) name:@"MotionDataReady" object:nil];
    
    _sensorConnection = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).wfSensorConnection;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSensorData) name:WF_NOTIFICATION_SENSOR_HAS_DATA object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark - Convient methods

- (void)startUpdates
{
    [_userSession createMotionStorage];
    
    // Start motion updates
    NSTimeInterval updateInterval = 0.01; // 100hz
    CMMotionManager *motionManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedMotionManager];
    
    if ([motionManager isDeviceMotionAvailable] == YES) {
        [motionManager setDeviceMotionUpdateInterval:updateInterval];
        [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical toQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *deviceMotion, NSError *error) {
            if ([[_userSession appendMotionData:deviceMotion] isEqualToString:@"HS"]) {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                if ([defaults boolForKey:@"motionSoundStatus"]) {
                    [[AudioController sharedAudioController] playE];
                }
            }
        }];
    }
    
    // Start location updates
    CLLocationManager *locationManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedLocationManager];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
    [locationManager startUpdatingLocation];
}

- (void)stopUpdates
{
    // Stop motion updates
    CMMotionManager *motionManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedMotionManager];
    if ([motionManager isDeviceMotionActive] == YES) {
        [motionManager stopDeviceMotionUpdates];
    }
    
    // Stop location updates
    CLLocationManager *locationManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedLocationManager];
    [locationManager stopUpdatingLocation];
}

#pragma mark -
#pragma mark - IBActions

- (IBAction)startStopCollection:(id)sender
{
    _isCollection = !_isCollection;
    
    UIButton *startStopCollectionButton = (UIButton *)sender;
    
    if (_isCollection) {
        [startStopCollectionButton setTitle:@"stop" forState:0];
        [self startUpdates];
        [_userSession createHrStorage];
    } else {
        [startStopCollectionButton setTitle:@"start" forState:0];
        [self stopUpdates];
        
        [_userSession seriliazeAndZipMotionData];
        
        if ([_userSession hrCount] != 0)
        {
            [_userSession seriliazeAndZipHrData];
        }
        
        // TODO: (sb) Replace feedback
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Gute Arbeit!", @"Gute Arbeit!")
                                                        message:NSLocalizedString(@"Deine Daten wurden lokal gespeichert." , @"Deine Daten wurden lokal gespeichert.")
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                              otherButtonTitles:nil];
        
        [alert show];
    }
}

#pragma mark - Convenient methods
#pragma mark -

//// Checks if we have an internet connection or not
//- (void)testInternetConnection
//{
//    _internetReachable = [Reachability reachabilityWithHostname:@"www.google.com"];
//    
//    // Internet is reachable
//    _internetReachable.reachableBlock = ^(Reachability*reach)
//    {
//        // Update the UI on the main thread
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSLog(@"Yayyy, we have the interwebs!");
//        });
//    };
//    
//    // Internet is not reachable
//    _internetReachable.unreachableBlock = ^(Reachability*reach)
//    {
//        // Update the UI on the main thread
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSLog(@"Someone broke the internet :(");
//        });
//    };
//    
//    if([_internetReachable startNotifier])
//        NSLog(@"Internet");
//    else
//        NSLog(@"No Internet");
//}

- (void)updateSensorData
{
    if ([((AppDelegate *)[[UIApplication sharedApplication] delegate]).wfSensorConnection isKindOfClass:[WFHeartrateConnection class]]) {
        WFHeartrateConnection *hrConnection = (WFHeartrateConnection *) ((AppDelegate *)[[UIApplication sharedApplication] delegate]).wfSensorConnection;
        WFHeartrateData *hrData = [hrConnection getHeartrateData];
        if (hrData != nil) {
            _bmpLabel.text = [hrData formattedHeartrate:YES];
            if (_lastAccumBeatCount < hrData.accumBeatCount) {
                
                // Sonify beat
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                if ([defaults boolForKey:@"hrSoundStatus"]) {
                    [[AudioController sharedAudioController] playE];
                }
                _lastAccumBeatCount = hrData.accumBeatCount;
                
//                NSLog(@"# accumBeatCount: %d", hrData.accumBeatCount);
            }
//            NSArray* rrIntervals = [(WFBTLEHeartrateData*)hrData rrIntervals];
//            for (NSNumber *rrInterval in rrIntervals) {
//                NSLog(@"# rrInterval: %f", [rrInterval doubleValue]);
//            }
            
            if(_isCollection) {
                [_userSession appendHrData:hrData];
            }
        }
    }
    else {
        _bmpLabel.text = NSLocalizedString(@"k. A.", @"k. A.");
    }
}

#pragma mark -
#pragma mark - Dropbox convenient methods

- (DBRestClient *)restClient {
    if (!_restClient) {
        _restClient =
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

- (void)uploadFile:(NSNotification *)notification
{
    if ([[DBSession sharedSession] isLinked]) {
        NSDictionary *userInfo = [notification userInfo];
        
        NSString *localPath = [userInfo objectForKey:@"localPath"];
        NSString *fileName = [userInfo objectForKey:@"fileName"];
        NSString *destDir = @"/";
        
        [[self restClient] uploadFile:fileName toPath:destDir withParentRev:nil fromPath:localPath];
    }
}

#pragma mark -
#pragma mark - DBRestClientDelegate methods

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata
{
    NSLog(@"# File uploaded successfully to path: %@", metadata.path);
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    NSLog(@"# File upload failed with error - %@", error);
}

@end
