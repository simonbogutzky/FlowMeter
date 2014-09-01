//
//  SessionPrefsTableViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 03.05.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "SessionPrefsTableViewController.h"
#import "EditViewController.h"
#import "SessionViewController.h"
#import "AppDelegate.h"
#import "Session.h"

@interface SessionPrefsTableViewController ()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) NSMutableDictionary *sessionDictionary;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UITableViewCell *firstNameTableViewCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *lastNameTableViewCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *activityTableViewCell;
@property (nonatomic, weak) IBOutlet UISwitch *flowShortScaleStatusSwitch;
@end

@implementation SessionPrefsTableViewController

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
    
    self.sessionDictionary = [NSMutableDictionary dictionaryWithObjects:@[@"", @"", @"", [NSNumber numberWithInt:flowShortScale]] forKeys:@[@"firstName", @"lastName", @"activity", @"questionnaire"]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSString *firstName = [self.sessionDictionary valueForKey:@"firstName"];
    if (firstName != nil && ![firstName isEqualToString:@""]) {
        self.firstNameTableViewCell.detailTextLabel.text = firstName;
    }
    
    NSString *lastName = [self.sessionDictionary valueForKey:@"lastName"];
    if (lastName != nil && ![lastName isEqualToString:@""]) {
        self.lastNameTableViewCell.detailTextLabel.text = lastName;
    }
    
    NSString *activity = [self.sessionDictionary valueForKey:@"activity"];
    if (activity != nil && ![activity isEqualToString:@""]) {
        self.activityTableViewCell.detailTextLabel.text = activity;
    }
    
    [self.tableView reloadData];
}

#pragma mark -
#pragma marl - IBActions

- (IBAction)changeFlowShowScaleStatus:(UISwitch *)sender {
    if (sender.on) {
        [self.sessionDictionary setObject:[NSNumber numberWithInt:flowShortScale] forKey:@"questionnaire"];
    } else {
        [self.sessionDictionary setObject:[NSNumber numberWithInt:none] forKey:@"questionnaire"];
    }
}

- (IBAction)startTouched:(id)sender
{
    SessionViewController *sessionStartViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Session"];
    [UIView beginAnimations:@"flipping view" context:nil];
    [UIView setAnimationDuration:0.75];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.navigationController.view cache:YES];
    [self.navigationController pushViewController:sessionStartViewController animated:NO];
    [UIView commitAnimations];
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
    
    if ([segue.identifier isEqualToString:@"editActivity"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        EditViewController *editViewController = (EditViewController *) navigationController.topViewController;
        editViewController.propertyName = @"activity";
        editViewController.propertyDictionary = self.sessionDictionary;
        [((UITableViewCell *) sender) setSelected:NO animated:YES];
    }
    
    if ([segue.identifier isEqualToString:@"startSession"]) {
        SessionViewController *sessionStartViewController = (SessionViewController *) segue.destinationViewController;
        sessionStartViewController.sessionDictionary = self.sessionDictionary;
    }
}

@end
