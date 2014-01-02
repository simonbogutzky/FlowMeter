//
//  PrefsTableViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 19.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <DropboxSDK/DropboxSDK.h>
#import "PrefsTableViewController.h"
#import "AppDelegate.h"

@interface PrefsTableViewController () {
    AppDelegate *_appDelegate;
}
@property (weak, nonatomic) IBOutlet UISwitch *dbConnectionStatusSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *hxmConnectionStatusSwitch;
@property (weak, nonatomic) IBOutlet UITableViewCell *hxmTableViewCell;

@end

@implementation PrefsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dBConnectionChanged:) name:NOTIFICATION_DB_CONNECTION_CANCELLED object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.dbConnectionStatusSwitch.on = [[DBSession sharedSession] isLinked];
    self.hxmConnectionStatusSwitch.on = _appDelegate.heartRateMonitorManager.hasConnection;
    self.hxmConnectionStatusSwitch.enabled = _appDelegate.heartRateMonitorManager.hasConnection;
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

- (IBAction)changeHxMConnectionStatus:(UISwitch *)sender {
    if (_appDelegate.heartRateMonitorManager.hasConnection && !sender.on) {
        [_appDelegate.heartRateMonitorManager disconnectHeartRateMonitorDevice];
    }
    sender.enabled = NO;
}


#pragma mark -
#pragma marl - Notification handler

- (void)dBConnectionChanged:(NSNotification *)notification
{
    [_dbConnectionStatusSwitch setOn:!_dbConnectionStatusSwitch.on animated:YES];
}
@end
