//
//  EditViewController.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 03.05.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "EditViewController.h"
#import "User.h"

@interface EditViewController ()

@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *doneButton;

@end

@implementation EditViewController

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.topItem.title = [self.itemDictionary objectForKey:kTitleKey];
    self.textField.text = @"";
}

#pragma mark -
#pragma mark - IBActions

- (IBAction)doneTouched:(id)sender
{
    [self.itemDictionary setValue:self.textField.text forKey:kValueKey];
    if ([self.textField.text isEqualToString:@""]) {
        [self.itemDictionary setValue:@" " forKey:kValueKey];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    [self resignFirstResponder];
}

- (IBAction)cancelTouched:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self resignFirstResponder];
}


@end
