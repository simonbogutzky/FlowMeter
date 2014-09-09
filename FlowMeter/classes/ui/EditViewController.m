//
//  EditViewController.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 03.05.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "EditViewController.h"
#import "AppDelegate.h"

@interface EditViewController ()

@property (nonatomic, weak) IBOutlet UITextField *textField;

@end

@implementation EditViewController

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
    self.navigationController.navigationBar.topItem.title = [self.itemDictionary objectForKey:kTitleKey];
    self.textField.text = @"";
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
    NSLog(@"%@", [[self getDisplayNameStrings] componentsJoinedByString:@", "]);
}

- (NSArray *)getDisplayNameStrings
{
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[self.itemDictionary objectForKey:kEntityKey] inManagedObjectContext:self.appDelegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSArray *fetchedObjects = [self.appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects == nil) {
        return @[];
    }
    
    NSMutableArray *displayNameStrings = [NSMutableArray array];
    for (NSManagedObject *object in fetchedObjects) {
        [displayNameStrings addObject:[object valueForKey:[self.itemDictionary objectForKey:kPropertyKey]]];
    }
    
    return displayNameStrings;
}

#pragma mark -
#pragma mark - IBActions

- (IBAction)doneTouched:(id)sender
{
    [self.itemDictionary setValue:self.textField.text forKey:kValueKey];
    if ([self.textField.text isEqualToString:@""]) {
        [self.itemDictionary setValue:@" " forKey:kValueKey];
    }
    [self.textField resignFirstResponder];
}

- (IBAction)cancelTouched:(id)sender
{
    if (![self.textField isFirstResponder]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    [self.textField resignFirstResponder];
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
