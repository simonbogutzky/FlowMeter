//
//  SessionViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 23.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "SessionViewController.h"
#import "SessionTableViewController.h"

@interface SessionViewController ()

@end

@implementation SessionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue destinationViewController] isMemberOfClass:[SessionTableViewController class]]) {
        SessionTableViewController *sessionTableViewController = [segue destinationViewController];
        sessionTableViewController.navigationItem = self.navigationItem;
    }
}

@end
