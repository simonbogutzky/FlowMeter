//
//  EditViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 03.05.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "EditViewController.h"
#import "User.h"

@interface EditViewController ()

@property (nonatomic, weak) IBOutlet UITextField *textField;

@end

@implementation EditViewController

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.topItem.title = NSLocalizedString(self.propertyName, @"Vorname oder Nachname oder Aktivität") ;
    self.textField.text = [self.propertyDictionary valueForKey:self.propertyName];
}

#pragma mark -
#pragma mark - IBActions

- (IBAction)doneTouched:(id)sender
{
    [self.propertyDictionary setValue:self.textField.text forKey:self.propertyName];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self resignFirstResponder];
}

- (IBAction)cancelTouched:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self resignFirstResponder];
}


@end
