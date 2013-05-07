//
//  EditViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 03.05.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "EditViewController.h"
#import "User.h"

@interface EditViewController () {
    IBOutlet UINavigationBar *_navigationBar;
    IBOutlet UITextField *_textField;
}

@end

@implementation EditViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _navigationBar.topItem.title = NSLocalizedString(_propertyName, @"Vorname oder Nachname") ;
    _textField.text = [_user valueForKey:_propertyName];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)finisedTouched:(id)sender
{
    [_user setValue:_textField.text forKey:_propertyName];
    NSLog(@"%@", [_user valueForKey:_propertyName]);
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
