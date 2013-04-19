//
//  PrefsTableViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 19.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "PrefsTableViewController.h"
#import "TableViewCheckBoxCell.h"

@interface PrefsTableViewController () {
    IBOutlet UISwitch *_dbConnectionSwitch;
}

@end

@implementation PrefsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeDBConnection:) name:NOTIFICATION_DB_LINK_CANCELLED object:nil];
    
    _dbConnectionSwitch.on = [[DBSession sharedSession] isLinked];

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

- (IBAction)changeDropboxLinkState:(id)sender
{
    if (![[DBSession sharedSession] isLinked] && _dbConnectionSwitch.on) {
        [[DBSession sharedSession] linkFromController:self];
    }
    
    if ([[DBSession sharedSession] isLinked] && !_dbConnectionSwitch.on) {
        [[DBSession sharedSession] unlinkAll];
    }
}

#pragma mark -
#pragma marl - Notification handler

- (void)changeDBConnection:(NSNotification *)notification
{
    _dbConnectionSwitch.on = !_dbConnectionSwitch.on;
}

@end
