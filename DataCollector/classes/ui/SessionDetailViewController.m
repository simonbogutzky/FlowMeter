//
//  SessionDetailViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 04.09.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "SessionDetailViewController.h"

@interface SessionDetailViewController ()

@end

@implementation SessionDetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.detailItem) {
        self.navigationController.title = [[self.detailItem valueForKey:@"User"] valueForKey:@"firstName"];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
