//
//  PrefsViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 18.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "PrefsViewController.h"
#import "TableViewCheckBoxCell.h"

@interface PrefsViewController () {
    UISwitch *_dbConnectionSwitch;
}

@end

@implementation PrefsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeDBConnection:) name:NOTIFICATION_DB_LINK_CANCELLED object:nil];

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

#pragma mark -
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    static NSString *CellIdentifier;
    switch (indexPath.row) {
        case 1: {
            CellIdentifier = @"prefsItemCheckBoxCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            ((TableViewCheckBoxCell *) cell).textLabel.text = @"Dropbox Verbindung";
            _dbConnectionSwitch = ((TableViewCheckBoxCell *) cell).onOffSwitch;
            _dbConnectionSwitch.on = [[DBSession sharedSession] isLinked];
            [_dbConnectionSwitch addTarget:self action:@selector(changeDropboxLinkState:) forControlEvents:UIControlEventValueChanged];
        }
            break;
        
        default:
            CellIdentifier = @"prefsItemCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            break;
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark -
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
