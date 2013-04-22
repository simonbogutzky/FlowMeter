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
#import "PdDispatcher.h"
//#import "Reachability.h"


@interface HomeViewController ()
{
    WFSensorConnection *_sensorConnection;
    WFSensorType_t _sensorType;
    BOOL _isCollection;
    UserSessionVO *_userSession;
    
    PdDispatcher *_dispatcher;
    void *_patch;
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
    
    _dispatcher = [[PdDispatcher alloc]init];
    [PdBase setDelegate:_dispatcher];
    _patch = [PdBase openFile:@"tuner.pd"
                        path:[[NSBundle mainBundle] resourcePath]];
    if (!_patch) {
        NSLog(@"Failed to open patch!"); // Gracefully handle failure...
    }
    
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
            if ([[_userSession appendMotionData2:deviceMotion] isEqualToString:@"HS"]) {
                [self playE:self];
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
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Gute Arbeit!", @"Gute Arbeit!")
                                                        message:NSLocalizedString(@"Deine Daten wurden lokal gespeichert." , @"Deine Daten wurden lokal gespeichert.")
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                              otherButtonTitles:nil];
        
        [alert show];
    }
}

- (IBAction)playE:(id)sender
{
    [self playNote:90];
}

- (IBAction)playG:(id)sender
{
    [self playNote:55];
}

#pragma mark - Convenient methods
#pragma mark - 

- (void)playNote:(int)n
{
    [PdBase sendFloat:n toReceiver:@"midinote"];
    [PdBase sendBangToReceiver:@"trigger"];
    
}

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
//        WFHeartrateRawData *hrRawData = [hrConnection getHeartrateRawData];
        if (hrData != nil) {
            _bmpLabel.text = [hrData formattedHeartrate:YES];
            
            if (_lastAccumBeatCount < hrData.accumBeatCount) {
                // Sonify beat
                [self playE:self];
                
                _lastAccumBeatCount = hrData.accumBeatCount;
                
                NSLog(@"# accumBeatCount: %d", hrData.accumBeatCount);
            }
            
            // Debug logs
//            NSLog(@"# beatTime: %d", hrData.beatTime);
//            NSLog(@"# accumBeatCount: %d", hrData.accumBeatCount);
//
//            NSLog(@"# rawBeatTime: %d", hrRawData.beatTime);
//            NSLog(@"# rawAccumBeatCount: %d", hrRawData.beatCount);
//            
//            NSLog(@"# previousBeatTime: %d", hrRawData.previousBeatTime);
            
            NSArray* rrIntervals = [(WFBTLEHeartrateData*)hrData rrIntervals];
            
            for (NSNumber *rrInterval in rrIntervals) {
                NSLog(@"# rrInterval: %f", [rrInterval doubleValue]);
            }
            
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
    NSDictionary *userInfo = [notification userInfo];
    
    NSString *localPath = [userInfo objectForKey:@"localPath"];
    NSString *fileName = [userInfo objectForKey:@"fileName"];
    NSString *destDir = @"/";
    
    [[self restClient] uploadFile:fileName toPath:destDir withParentRev:nil fromPath:localPath];
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
