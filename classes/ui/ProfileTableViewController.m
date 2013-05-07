//
//  ProfileTableViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 03.05.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "ProfileTableViewController.h"
#import "EditViewController.h"
#import "AppDelegate.h"
#import "User.h"

@interface ProfileTableViewController () {
    NSManagedObjectContext *_managedObjectContext;
    User *_user;
    IBOutlet UITableViewCell *_firstNameTableViewCell;
    IBOutlet UITableViewCell *_lastNameTableViewCell;
    IBOutlet UITableViewCell *_usernameTableViewCell;
}
@end

@implementation ProfileTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    _managedObjectContext = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    NSPredicate *isNotSyncedPredicate = [NSPredicate predicateWithFormat:@"isPreviousUser == %@", @1];
    [fetchRequest setPredicate:isNotSyncedPredicate];
    
    NSArray *fetchedObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects == nil) {
        // Handle the error.
    }
    
    if ([fetchedObjects count] == 0) {
        _user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:_managedObjectContext];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    if (_user.firstName != nil) {
        _firstNameTableViewCell.textLabel.text = _user.firstName;
    }
    
    if (_user.lastName != nil) {
        _lastNameTableViewCell.textLabel.text = _user.lastName;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"editFirstName"]) {
        EditViewController *editViewController = segue.destinationViewController;
        editViewController.propertyName = @"firstName";
        editViewController.user = _user;
    }
    
    if ([segue.identifier isEqualToString:@"editLastName"]) {
        EditViewController *editViewController = segue.destinationViewController;
        editViewController.propertyName = @"lastName";
        editViewController.user = _user;
    }
}

@end
