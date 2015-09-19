//
//  LicenseViewController.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 15.11.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "LicenseViewController.h"

@interface LicenseViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textViewLicense;
@end

@implementation LicenseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.textViewLicense.text = NSLocalizedString(@"Genutzte Lizenzen", @"Genutzte Lizenzen");
}

@end
