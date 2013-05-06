//
//  EditViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 03.05.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "EditViewController.h"

@interface EditViewController () {
    IBOutlet UINavigationBar *_navigationBar;
    IBOutlet UITextField *_textField;
}

@end

@implementation EditViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _navigationBar.topItem.title = _propertyName;
    _textField.text = _propertyValue;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)finisedTouched:(id)sender
{
    _propertyValue = _textField.text;
    NSLog(@"%@", _propertyValue);
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
