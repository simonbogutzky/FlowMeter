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
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
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
    self.hxmConnectionStatusSwitch.enabled = self.appDelegate.heartRateMonitorManager.hasConnection;
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
    }
    sender.enabled = NO;
}

#pragma mark -
#pragma marl - Notification handler

- (void)dBConnectionChanged:(NSNotification *)notification
{
    if ([notification.name isEqualToString:@"NotificationDBLinkCancelled"] && self.dbConnectionStatusSwitch.on) {
        [self.dbConnectionStatusSwitch setOn:NO animated:YES];
    }
}
@end
