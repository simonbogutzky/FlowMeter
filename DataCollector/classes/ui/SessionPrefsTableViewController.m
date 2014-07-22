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
#import "User.h"

@interface SessionPrefsTableViewController () {
    NSManagedObjectContext *_managedObjectContext;
    User *_user;
    IBOutlet UITableView *_tableView;
    IBOutlet UITableViewCell *_firstNameTableViewCell;
    IBOutlet UITableViewCell *_lastNameTableViewCell;
    IBOutlet UITableViewCell *_activityTableViewCell;
    NSMutableDictionary *_userDictionary;
    BOOL _saveContext;
    AppDelegate *_appDelegate;
}
@end

@implementation SessionPrefsTableViewController

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _managedObjectContext = _appDelegate.managedObjectContext;
    _userDictionary = [NSMutableDictionary dictionaryWithObjects:@[@"", @"", @""] forKeys:@[@"firstName", @"lastName", @"username"]];
}

- (void)viewWillAppear:(BOOL)animated
{
    _saveContext = YES;
    
    NSString *firstName = [_userDictionary valueForKey:@"firstName"];
    if (firstName != nil && ![firstName isEqualToString:@""]) {
        _firstNameTableViewCell.detailTextLabel.text = firstName;
    } else {
        if (_user.firstName != nil && ![_user.firstName isEqualToString:@""]) {
            _firstNameTableViewCell.detailTextLabel.text = _user.firstName;
            [_userDictionary setValue:_user.firstName forKey:@"firstName"];
        }
    }
    
    NSString *lastName = [_userDictionary valueForKey:@"lastName"];
    if (lastName != nil && ![lastName isEqualToString:@""]) {
        _lastNameTableViewCell.detailTextLabel.text = lastName;
    } else {
        if (_user.lastName != nil && ![_user.lastName isEqualToString:@""]) {
            _lastNameTableViewCell.detailTextLabel.text = _user.lastName;
            [_userDictionary setValue:_user.lastName forKey:@"lastName"];
        }
    }
    
//    NSString *cleanedFirstName = [self cleanName:_firstNameTableViewCell.detailTextLabel.text];
//    NSString *cleanedLastName = [self cleanName:_lastNameTableViewCell.detailTextLabel.text];
//    if (![cleanedFirstName isEqualToString:@""] && ![cleanedLastName isEqualToString:@""]) {
//        NSString *username = [NSString stringWithFormat:@"%@_%@", cleanedFirstName, cleanedLastName];
//        [_userDictionary setValue:username forKey:@"username"];
//        _usernameTableViewCell.detailTextLabel.text = username;
//    }
    [_tableView reloadData];
}

#pragma mark -
#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"editFirstName"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        EditViewController *editViewController = (EditViewController *) navigationController.topViewController;
        editViewController.propertyName = @"firstName";
        editViewController.propertyDictionary = _userDictionary;
        [((UITableViewCell *) sender) setSelected:NO animated:YES];
        _saveContext = NO;
    }
    
    if ([segue.identifier isEqualToString:@"editLastName"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        EditViewController *editViewController = (EditViewController *) navigationController.topViewController;
        editViewController.propertyName = @"lastName";
        editViewController.propertyDictionary = _userDictionary;
        [((UITableViewCell *) sender) setSelected:NO animated:YES];
        _saveContext = NO;
    }
}

- (NSString *)cleanName:(NSString *)name
{
    NSString *cleanedName = [name copy];
    cleanedName = [cleanedName lowercaseString];
    cleanedName = [cleanedName stringByReplacingOccurrencesOfString:@"ä" withString:@"ae"];
    cleanedName = [cleanedName stringByReplacingOccurrencesOfString:@"ö" withString:@"oe"];
    cleanedName = [cleanedName stringByReplacingOccurrencesOfString:@"ü" withString:@"ue"];
    cleanedName = [cleanedName stringByReplacingOccurrencesOfString:@"ß" withString:@"ss"];
    NSCharacterSet *notAllowedChars = [[NSCharacterSet characterSetWithCharactersInString:@" -abcdefghijklmnopqrstuvwxyz"] invertedSet];
    cleanedName = [[cleanedName componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
     
    return cleanedName;
}

@end
