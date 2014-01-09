//
//  HeartRateMonitorDeviceTableViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 02.01.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "HeartRateMonitorDeviceTableViewController.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"

@interface HeartRateMonitorDeviceTableViewController ()
{
    AppDelegate *_appDelegate;
}

@property (nonatomic, strong) NSMutableArray *heartRateMonitorDevices;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *scanButton;

@end

@implementation HeartRateMonitorDeviceTableViewController

- (NSMutableArray *)heartRateMonitorDevices
{
    if (_heartRateMonitorDevices == nil) {
        _heartRateMonitorDevices = [[NSMutableArray alloc] initWithCapacity:3];
    }
    return _heartRateMonitorDevices;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self scan:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [_appDelegate.heartRateMonitorManager stopScanning];
    [super viewWillDisappear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.heartRateMonitorDevices count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [_appDelegate.heartRateMonitorManager stopScanning];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        HeartRateMonitorDevice *heartRateMonitorDevice = [self.heartRateMonitorDevices objectAtIndex:indexPath.row];
        [_appDelegate.heartRateMonitorManager connectHeartRateMonitorDevice:heartRateMonitorDevice];
        
    });
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"heartRateMonitorDeviceNameCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    HeartRateMonitorDevice *heartRateMonitorDevice = [self.heartRateMonitorDevices objectAtIndex:indexPath.row];
    cell.textLabel.text = heartRateMonitorDevice.name;
    
    return cell;
}

- (IBAction)scan:(id)sender
{
    self.scanButton.enabled = NO;
    self.heartRateMonitorDevices = nil;
    [self.tableView reloadData];
    _appDelegate.heartRateMonitorManager.delegate = self;
    
    NSString *cause = nil;
    
    switch (_appDelegate.heartRateMonitorManager.state) {
        case HeartRateMonitorManagerStatePoweredOn: {
            [_appDelegate.heartRateMonitorManager scanForHeartRateMonitorDeviceWhichWereConnected:[sender isEqual:self]];
        }
            break;
            
        case HeartRateMonitorManagerStatePoweredOff: {
            cause = NSLocalizedString(@"Überprüfe, ob Bluetooth eingeschlatet ist", @"Überprüfe, ob Bluetooth eingeschlatet ist");
            
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
    
    if (_appDelegate.heartRateMonitorManager.state != HeartRateMonitorManagerStatePoweredOn) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Keine Verbindung möglich", @"Keine Verbindung möglich")
                                                            message:cause
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}


- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didDiscoverHeartrateMonitorDevices:(NSArray *)heartRateMonitorDevices
{
    for (HeartRateMonitorDevice *heartRateMonitorDevice in heartRateMonitorDevices) {
        [self.heartRateMonitorDevices addObject:heartRateMonitorDevice];
    }
    [self.tableView reloadData];
    self.scanButton.enabled = YES;
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didConnectHeartrateMonitorDevice:(CBPeripheral *)heartRateMonitorDevice
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didDisconnectHeartrateMonitorDevice:(CBPeripheral *)heartRateMonitorDevice
                          error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Verbindung wurde wieder getrennt", @"Verbindung wurde wieder getrennt")
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didFailToConnectHeartrateMonitorDevice:(CBPeripheral *)heartRateMonitorDevice
                          error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Fehler beim Verbinden", @"Fehler beim Verbinden")
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
}

@end
