//
//  PrefsTableViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 19.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "PrefsTableViewController.h"
#import "AppDelegate.h"
#import "AudioController.h"

@interface PrefsTableViewController () {
    IBOutlet UISwitch *_dbConnectionStatusSwitch;
    IBOutlet UISwitch *_hrConnectionStatusSwitch;
    IBOutlet UILabel *_hrBatteryLevelLabel;
    IBOutlet UILabel *_hrConnectionStatusLabel;
    IBOutlet UISwitch *_motionSoundStatusSwitch;
    IBOutlet UISwitch *_hrSoundStatusSwitch;
    AppDelegate *_appDelegate;
    WFSensorType_t _wfSensorType;
}

@end

@implementation PrefsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (_appDelegate.wfSensorConnection != nil)
        _appDelegate.wfSensorConnection.delegate = self;
    
    _dbConnectionStatusSwitch.on = [[DBSession sharedSession] isLinked];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dBConnectionChanged:) name:NOTIFICATION_DB_CONNECTION_CANCELLED object:nil];
    
    [self setWfSensorConnectionStatus:_appDelegate.wfSensorConnection.connectionStatus];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wfSensorDataUpdated:) name:WF_NOTIFICATION_SENSOR_HAS_DATA object:nil];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _motionSoundStatusSwitch.on = [defaults boolForKey:@"motionSoundStatus"];
    _hrSoundStatusSwitch.on = [defaults boolForKey:@"hrSoundStatus"];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

#pragma mark -
#pragma marl - IBActions

- (IBAction)changeDbConnectionStatus:(id)sender
{
    if (![[DBSession sharedSession] isLinked] && _dbConnectionStatusSwitch.on)
        [[DBSession sharedSession] linkFromController:self];
    
    if ([[DBSession sharedSession] isLinked] && !_dbConnectionStatusSwitch.on)
        [[DBSession sharedSession] unlinkAll];
}

- (IBAction)changeHrSensorConnectionStatus:(id)sender
{
    if (_appDelegate.wfSensorConnection.connectionStatus == WF_SENSOR_CONNECTION_STATUS_IDLE && _hrConnectionStatusSwitch.on)
        [self initHrSensorConnection];
    
    if ((_appDelegate.wfSensorConnection.connectionStatus == WF_SENSOR_CONNECTION_STATUS_CONNECTED || _appDelegate.wfSensorConnection.connectionStatus == WF_SENSOR_CONNECTION_STATUS_CONNECTING) && !_hrConnectionStatusSwitch.on)
        [self disconnectWfSensor];
}

- (IBAction)playE:(id)sender
{
    [[AudioController sharedAudioController] playE];
}

- (IBAction)changeHrSoundStatus:(id)sender
{
    UISwitch *hrSoundStatusSwitch = sender;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:hrSoundStatusSwitch.on forKey:@"hrSoundStatus"];
}

- (IBAction)changeMotionSound:(id)sender
{
    UISwitch *motionSoundStatusSwitch = sender;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:motionSoundStatusSwitch.on forKey:@"motionSoundStatus"];
}

#pragma mark -
#pragma mark - HR Sensor connection

- (void)initHrSensorConnection
{
    WFHardwareConnector *hardwareConnector = [_appDelegate sharedHardwareConnector];
    _wfSensorType = WF_SENSORTYPE_HEARTRATE;
    _appDelegate.wfSensorConnection = nil;
    if (hardwareConnector.isCommunicationHWReady) {
        
        // Check for an existing connection to this sensor type
        NSArray *connections = [hardwareConnector getSensorConnections:_wfSensorType];
        WFSensorConnection *sensorConnection = ([connections count] > 0) ? (WFSensorConnection *) [connections objectAtIndex:0] : nil;
        
        // If a connection exists, cache it and set the delegate to this instance (this will allow receiving connection state changes)
        _appDelegate.wfSensorConnection = sensorConnection;
        if (sensorConnection) {
            _appDelegate.wfSensorConnection.delegate = self;
        }
    }
    [self connectWfSensor];
}

- (void)connectWfSensor
{
	// Get the current connection status
	WFSensorConnectionStatus_t connectionStatus = WF_SENSOR_CONNECTION_STATUS_IDLE;
	if (_appDelegate.wfSensorConnection != nil) {
		connectionStatus = _appDelegate.wfSensorConnection.connectionStatus;
	}
	if(connectionStatus == WF_SENSOR_CONNECTION_STATUS_IDLE) {
        
        // Get the connection params
        WFHardwareConnector *hardwareConnector = [_appDelegate sharedHardwareConnector];
        WFConnectionParams *params = [hardwareConnector.settings connectionParamsForSensorType:_wfSensorType];
        if (params != nil) {
            
            // Set the search timeout
            params.searchTimeout = hardwareConnector.settings.searchTimeout;
            _appDelegate.wfSensorConnection = [hardwareConnector requestSensorConnection:params];
            
            if (_appDelegate.wfSensorConnection == nil)
                [_hrConnectionStatusSwitch setOn:NO animated:YES];
            else
                _appDelegate.wfSensorConnection.delegate = self;
        }
    }
}

- (void)disconnectWfSensor
{
    if (_appDelegate.wfSensorConnection.connectionStatus == WF_SENSOR_CONNECTION_STATUS_CONNECTED || _appDelegate.wfSensorConnection.connectionStatus == WF_SENSOR_CONNECTION_STATUS_CONNECTING) {
        [_appDelegate.wfSensorConnection disconnect];
    }
}

- (void)setWfSensorConnectionStatus:(WFSensorConnectionStatus_t)connectionStatus
{
    switch (connectionStatus) {
        case WF_SENSOR_CONNECTION_STATUS_IDLE:
            [_hrConnectionStatusSwitch setOn:NO animated:YES];
            _hrConnectionStatusLabel.text = NSLocalizedString(@"nicht verbunden", @"nicht verbunden");
            _hrBatteryLevelLabel.text = NSLocalizedString(@"k. A.", @"k. A.");
            break;
            
        case WF_SENSOR_CONNECTION_STATUS_CONNECTED:
            [_hrConnectionStatusSwitch setOn:YES animated:YES];
            _hrConnectionStatusLabel.text = NSLocalizedString(@"verbunden", @"verbunden");
            break;
            
        case WF_SENSOR_CONNECTION_STATUS_CONNECTING:
            [_hrConnectionStatusSwitch setOn:YES animated:YES];
            _hrConnectionStatusLabel.text = NSLocalizedString(@"Verbindung wird hergestellt", @"Verbindung wird hergestellt");
            break;
            
        case WF_SENSOR_CONNECTION_STATUS_DISCONNECTING:
            [_hrConnectionStatusSwitch setOn:NO animated:YES];
            _hrConnectionStatusLabel.text = NSLocalizedString(@"Verbindung wird getrennt", @"Verbindung wird getrennt");
            break;
            
        case WF_SENSOR_CONNECTION_STATUS_INTERRUPTED: {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Brustgurt Verbindung", @"Brustgurt Verbindung") message:NSLocalizedString(@"Die Verbindung wurde getrennt", @"Die Verbindung wurde getrennt") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
            [alert show];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark -
#pragma mark - SensorConnectionDelegate implementation

- (void)connectionDidTimeout:(WFSensorConnection*)connectionInfo
{
    NSLog(@"# Timeout of %@", connectionInfo.deviceUUIDString);
}

- (void)connection:(WFSensorConnection*)connectionInfo stateChanged:(WFSensorConnectionStatus_t)connectionStatus
{
    [self setWfSensorConnectionStatus:connectionStatus];
}

#pragma mark -
#pragma marl - Notification handler

- (void)dBConnectionChanged:(NSNotification *)notification
{
    [_dbConnectionStatusSwitch setOn:!_dbConnectionStatusSwitch.on animated:YES];
}

- (void)wfSensorDataUpdated:(NSNotification *)notification
{
    if ([_appDelegate.wfSensorConnection isKindOfClass:[WFHeartrateConnection class]]) {
        WFHeartrateConnection *_hrSensorConnection = (WFHeartrateConnection *) _appDelegate.wfSensorConnection;
        WFHeartrateRawData *hrRawData = [_hrSensorConnection getHeartrateRawData];
        if (hrRawData != nil) {
            if (hrRawData.btleCommonData) {
                _hrBatteryLevelLabel.text = [NSString stringWithFormat:@"%u %%", hrRawData.btleCommonData.batteryLevel];
            }
        }
    }
}


@end
