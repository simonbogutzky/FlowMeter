//
//  SessionPrefsTableViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 03.05.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "SessionPrefsTableViewController.h"
#import "EditViewController.h"
#import "AppDelegate.h"
#import "Session.h"

@interface SessionPrefsTableViewController ()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) Session *session;
@property (nonatomic, strong) NSMutableDictionary *sessionDictionary;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UITableViewCell *firstNameTableViewCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *lastNameTableViewCell;
@end

@implementation SessionPrefsTableViewController

#pragma mark -
#pragma mark - Getter

- (AppDelegate *)appDelegate
{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (Session *)session
{
    if (!_session) {
        _session = [NSEntityDescription insertNewObjectForEntityForName:@"Session" inManagedObjectContext:self.appDelegate.managedObjectContext];
    }
    return _session;
}

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.sessionDictionary = [NSMutableDictionary dictionaryWithObjects:@[@"", @""] forKeys:@[@"firstName", @"lastName"]];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSString *firstName = [self.sessionDictionary valueForKey:@"firstName"];
    if (firstName != nil && ![firstName isEqualToString:@""]) {
        self.firstNameTableViewCell.detailTextLabel.text = firstName;
    }
    
    NSString *lastName = [self.sessionDictionary valueForKey:@"lastName"];
    if (lastName != nil && ![lastName isEqualToString:@""]) {
        self.lastNameTableViewCell.detailTextLabel.text = lastName;
    }
    
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"editFirstName"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        EditViewController *editViewController = (EditViewController *) navigationController.topViewController;
        editViewController.propertyName = @"firstName";
        editViewController.propertyDictionary = self.sessionDictionary;
        [((UITableViewCell *) sender) setSelected:NO animated:YES];
    }
    
    if ([segue.identifier isEqualToString:@"editLastName"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        EditViewController *editViewController = (EditViewController *) navigationController.topViewController;
        editViewController.propertyName = @"lastName";
        editViewController.propertyDictionary = self.sessionDictionary;
        [((UITableViewCell *) sender) setSelected:NO animated:YES];
    }
}

@end
