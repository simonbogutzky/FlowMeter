//
//  InitialSlidingViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 18.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "InitialSlidingViewController.h"

@interface InitialSlidingViewController ()

@end

@implementation InitialSlidingViewController

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Set top view controller
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    self.topViewController = [storyboard instantiateViewControllerWithIdentifier:@"home"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
