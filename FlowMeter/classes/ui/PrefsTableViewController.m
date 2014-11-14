//
//  PrefsTableViewController.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 19.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <DropboxSDK/DropboxSDK.h>
#import "PrefsTableViewController.h"
#import "AppDelegate.h"

@interface PrefsTableViewController ()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (weak, nonatomic) IBOutlet UISwitch *dbConnectionStatusSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *hxmConnectionStatusSwitch;
@property (nonatomic, strong) NSMutableArray *heartRateMonitorDevices;

@end

@implementation PrefsTableViewController

#pragma mark -
#pragma mark - Getter

- (AppDelegate *)appDelegate
{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dBConnectionChanged:) name:NOTIFICATION_DB_CONNECTION_CANCELLED object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.dbConnectionStatusSwitch.on = [[DBSession sharedSession] isLinked];
    self.hxmConnectionStatusSwitch.on = self.appDelegate.heartRateMonitorManager.hasConnection;
}

#pragma mark -
#pragma marl - IBActions

- (IBAction)changeDbConnectionStatus:(id)sender
{
    if (![[DBSession sharedSession] isLinked] && self.dbConnectionStatusSwitch.on)
        [[DBSession sharedSession] linkFromController:self];
    
    if ([[DBSession sharedSession] isLinked] && !self.dbConnectionStatusSwitch.on)
        [[DBSession sharedSession] unlinkAll];
}

- (IBAction)changeHxMConnectionStatus:(UISwitch *)sender {
    if (self.appDelegate.heartRateMonitorManager.hasConnection && !sender.on) {
        [self.appDelegate.heartRateMonitorManager disconnectHeartRateMonitorDevice];
    } else {
        [self scan];
    }
}


#pragma mark -
#pragma marl - Notification handler

- (void)dBConnectionChanged:(NSNotification *)notification
{
    if ([notification.name isEqualToString:@"NotificationDBLinkCancelled"] && self.dbConnectionStatusSwitch.on) {
        [self.dbConnectionStatusSwitch setOn:NO animated:YES];
    }
}

#pragma mark -
#pragma mark - Convenient methods of the heart rate monitor

- (void)scan
{
    self.heartRateMonitorDevices = [[NSMutableArray alloc] initWithCapacity:1];
    self.appDelegate.heartRateMonitorManager.delegate = self;
    
    NSString *cause = nil;
    
    switch (self.appDelegate.heartRateMonitorManager.state) {
        case HeartRateMonitorManagerStatePoweredOn: {
            [self.appDelegate.heartRateMonitorManager scanForHeartRateMonitorDeviceWhichWereConnected:YES];
        }
            break;
            
        case HeartRateMonitorManagerStatePoweredOff: {
            cause = NSLocalizedString(@"Überprüfe, ob Bluetooth eingeschaltet ist", @"Überprüfe, ob Bluetooth eingeschaltet ist");
            
        }
            break;
        case HeartRateMonitorManagerStateResetting: {
            cause = NSLocalizedString(@"Bluetooth Manager wird gerade zurückgesetzt", @"Bluetooth Manager wird gerade zurückgesetzt");
        }
            break;
        case HeartRateMonitorManagerStateUnauthorized: {
            cause = NSLocalizedString(@"Überprüfe deine Sicherheitseinstellungen", @"Überprüfe deine Sicherheitseinstellungen");
        }
            break;
        case HeartRateMonitorManagerStateUnknown: {
            cause = NSLocalizedString(@"Ein unbekannter Fehler ist aufgetreten", @"Ein unbekannter Fehler ist aufgetreten");
        }
            break;
        case HeartRateMonitorManagerStateUnsupported: {
            cause = NSLocalizedString(@"Gerät unterstützt kein Bluetooth LE", @"Gerät unterstützt kein Bluetooth LE");
        }
            break;
    }
    
    if (self.appDelegate.heartRateMonitorManager.state != HeartRateMonitorManagerStatePoweredOn) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Keine Bluetooth Verbindung möglich", @"Keine Bluetooth Verbindung möglich")
                                                            message:cause
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
        [self.hxmConnectionStatusSwitch setOn:NO animated:YES];
    }
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didDiscoverHeartrateMonitorDevices:(NSArray *)heartRateMonitorDevices
{
    [self.appDelegate.heartRateMonitorManager stopScanning];
    for (HeartRateMonitorDevice *heartRateMonitorDevice in heartRateMonitorDevices) {
        [self.heartRateMonitorDevices addObject:heartRateMonitorDevice];
    }
    
    if (self.heartRateMonitorDevices.count > 0) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            HeartRateMonitorDevice *heartRateMonitorDevice = [self.heartRateMonitorDevices objectAtIndex:0];
            [self.appDelegate.heartRateMonitorManager connectHeartRateMonitorDevice:heartRateMonitorDevice];
        });
    }
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didDisconnectHeartrateMonitorDevice:(CBPeripheral *)heartRateMonitorDevice
                          error:(NSError *)error
{
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Verbindung wurde getrennt", @"Titel der Fehlermeldung: Verbindung wurde getrennt")
                                                            message:NSLocalizedString(@"Die Verbindung zum HR-Brustgurt wurde unerwartet getrennt.", @"Beschreibung der Fehlermeldung: Verbindung wurde getrennt")
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Ok", @"Bestätigung der Fehlermeldung: Verbindung wurde getrennt")
                                                  otherButtonTitles:nil];
        [alertView show];
        [self.hxmConnectionStatusSwitch setOn:NO animated:YES];
    }
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didFailToConnectHeartrateMonitorDevice:(CBPeripheral *)heartRateMonitorDevice
                          error:(NSError *)error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Fehler beim Verbinden", @"Titel der Fehlermeldung: Fehler beim Verbinden")
                                                        message:NSLocalizedString(@"Es konnte keine Verbindung zum HR-Brustgurt hergestellt werden.", @"Beschreibung der Fehlermeldung: Fehler beim Verbinden")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Ok", @"Bestätigung der Fehlermeldung: Fehler beim Verbinden")
                                              otherButtonTitles:nil];
    [alertView show];
    [self.hxmConnectionStatusSwitch setOn:NO animated:YES];
}

@end
