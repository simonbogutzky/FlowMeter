//
//  AbtractSlidingTopViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 18.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "AbtractSlidingTopViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"

@interface AbtractSlidingTopViewController () {
    IBOutlet UIBarButtonItem *menuBarButtomItem;
}

@end

@implementation AbtractSlidingTopViewController

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // shadowPath, shadowOffset, and rotation is handled by ECSlidingViewController
    // Set the opacity, radius, and color
    self.view.layer.shadowOpacity = 0.75f;
    self.view.layer.shadowRadius = 10.0f;
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"menu"];
    }
    
    //    if (![self.slidingViewController.underRightViewController isKindOfClass:[UnderRightViewController class]]) {
    //        self.slidingViewController.underRightViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UnderRight"];
    //    }
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark - IBActions

- (IBAction)revealMenu:(id)sender
{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)setSliding:(BOOL)sliding
{
    menuBarButtomItem.enabled = sliding;
    if (sliding) {
        [self.view addGestureRecognizer:self.slidingViewController.panGesture];
        
    } else {
        [self.view removeGestureRecognizer:self.slidingViewController.panGesture];
    }
}

@end
