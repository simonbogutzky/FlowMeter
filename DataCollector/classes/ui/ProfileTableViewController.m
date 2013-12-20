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
    NSMutableDictionary *_userDictionary;
    BOOL _saveContext;
    AppDelegate *_appDelegate;
}
@end

@implementation ProfileTableViewController

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
    
    NSPredicate *isActivePredicate = [NSPredicate predicateWithFormat:@"isActive == %@", @1];
    _user = [_appDelegate activeUserWithPredicate:isActivePredicate];
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
    
    NSString *cleanedFirstName = [self cleanName:_firstNameTableViewCell.detailTextLabel.text];
    NSString *cleanedLastName = [self cleanName:_lastNameTableViewCell.detailTextLabel.text];
    if (![cleanedFirstName isEqualToString:@""] && ![cleanedLastName isEqualToString:@""]) {
        NSString *username = [NSString stringWithFormat:@"%@", cleanedFirstName];
        [_userDictionary setValue:username forKey:@"username"];
        _usernameTableViewCell.detailTextLabel.text = username;
    }
}
    
- (void)viewWillDisappear:(BOOL)animated
{
    NSString *username = [_userDictionary valueForKey:@"username"];
    if (_saveContext && username != nil && ![username isEqualToString:@""]) {
        
        // First use of the app. No user in the database.
        if ((_user.username == nil || [_user.username isEqualToString:@""]) ) {
            _user.firstName = _firstNameTableViewCell.detailTextLabel.text;
            _user.lastName = _lastNameTableViewCell.detailTextLabel.text;
            _user.username = username;
            _user.isActive = @1;
        } else {
            
            // User in the database, but with a different username
            if (![_user.username isEqualToString:username]) {
                _user.isActive = @0;
                
                NSPredicate *isUserWithUsernamePredicate = [NSPredicate predicateWithFormat:@"username == %@", username];
                User *user = [_appDelegate activeUserWithPredicate:isUserWithUsernamePredicate];
                
                // User do not exists. Create one.
                if (user.username == nil || [user.username isEqualToString:@""]) {
                    user.firstName = _firstNameTableViewCell.detailTextLabel.text;
                    user.lastName = _lastNameTableViewCell.detailTextLabel.text;
                    user.username = _usernameTableViewCell.detailTextLabel.text;
                }
                user.isActive = @1;
            }
        }
        NSError *error = nil;
        [_managedObjectContext save:&error];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"editFirstName"]) {
        EditViewController *editViewController = segue.destinationViewController;
        editViewController.propertyName = @"firstName";
        editViewController.propertyDictionary = _userDictionary;
        [((UITableViewCell *) sender) setSelected:NO animated:YES];
        _saveContext = NO;
    }
    
    if ([segue.identifier isEqualToString:@"editLastName"]) {
        EditViewController *editViewController = segue.destinationViewController;
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
