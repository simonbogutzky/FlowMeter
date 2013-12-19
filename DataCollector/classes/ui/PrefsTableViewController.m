//
//  PrefsTableViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 19.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "PrefsTableViewController.h"
#import "AppDelegate.h"

@interface PrefsTableViewController () {
    IBOutlet UISwitch *_dbConnectionStatusSwitch;
    IBOutlet UISwitch *_hrConnectionStatusSwitch;
    IBOutlet UILabel *_hrBatteryLevelLabel;
    IBOutlet UILabel *_hrConnectionStatusLabel;
    IBOutlet UISwitch *_motionSoundStatusSwitch;
    IBOutlet UISwitch *_hrSoundStatusSwitch;
    IBOutlet UISwitch *_tcpConnectionStatusSwitch;
    IBOutlet UITextField *_tcpHostTextfield;
    IBOutlet UITextField *_tcpPortTextfield;
    AppDelegate *_appDelegate;
}

@end

@implementation PrefsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _dbConnectionStatusSwitch.on = [[DBSession sharedSession] isLinked];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dBConnectionChanged:) name:NOTIFICATION_DB_CONNECTION_CANCELLED object:nil];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _motionSoundStatusSwitch.on = [defaults boolForKey:@"motionSoundStatus"];
    _hrSoundStatusSwitch.on = [defaults boolForKey:@"hrSoundStatus"];
    
    _tcpConnectionStatusSwitch.on = _appDelegate.sharedTCPConnectionManager.isStreamOpen;
    _tcpHostTextfield.text = [defaults valueForKey:@"tcpHost"];
    _tcpPortTextfield.text = [defaults valueForKey:@"tcpPort"];

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

- (IBAction)changeTCPConnectionStatus:(id)sender
{
    if (_tcpHostTextfield.text.length != 15) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Fehlende oder fehlerhafte Host-IP", @"Fehlende oder fehlerhafte Host-IP")
                                                        message:NSLocalizedString(@"Bitte neu eingeben!" , @"Bitte neu eingeben!")
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                              otherButtonTitles:nil];
        [alert show];
        [_tcpConnectionStatusSwitch setOn:NO animated:YES];
        return;
    }
    
    if (_tcpPortTextfield.text.length != 4) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Fehlende oder fehlerhafte Port", @"Fehlende oder fehlerhafte Port")
                                                        message:NSLocalizedString(@"Bitte neu eingeben!" , @"Bitte neu eingeben!")
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                              otherButtonTitles:nil];
        [alert show];
        [_tcpConnectionStatusSwitch setOn:NO animated:YES];
        return;
    }
    
    if (_tcpConnectionStatusSwitch.on) {
        [_appDelegate.sharedTCPConnectionManager openStreamsWithHost:_tcpHostTextfield.text port:@([_tcpPortTextfield.text intValue])];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:_tcpHostTextfield.text forKey:@"tcpHost"];
        [defaults setValue:_tcpPortTextfield.text forKey:@"tcpPort"];
    } else {
        [_appDelegate.sharedTCPConnectionManager closeStreams];
    }
}

#pragma mark -
#pragma marl - Notification handler

- (void)dBConnectionChanged:(NSNotification *)notification
{
    [_dbConnectionStatusSwitch setOn:!_dbConnectionStatusSwitch.on animated:YES];
}

#pragma mark -
#pragma mark - UITextfieldDelegate implementation

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (range.length == 1 && range.location == textField.text.length - 1) {
        return YES;
    }
    
    if (textField.tag == 1) {
        if (textField.text.length == 3 || textField.text.length == 7 || textField.text.length == 11) {
            textField.text = [NSString stringWithFormat:@"%@.", textField.text];
        }
        
        if(textField.text.length > 14) {
            return NO;
        }
    }
    
    if (textField.tag == 2) {
        if(textField.text.length > 3)
            return NO;
    }
    
    if (range.length != 0  && range.location != textField.text.length) {
        return NO;
    }
    
    return YES;
}
@end
