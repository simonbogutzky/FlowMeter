//
//  SplashScreenViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 29.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "SplashScreenViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface SplashScreenViewController() {
    IBOutlet UIImageView *_launchImage;
}

@end


@implementation SplashScreenViewController


- (void)viewDidLoad
{
    [self performSelector:@selector(vanish) withObject:nil afterDelay:0.0];
    [super viewDidLoad];
}


- (void)vanish {
    CATransition* transition = [CATransition animation];
    transition.duration = 1.5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    [self.navigationController popViewControllerAnimated:NO];
    [self.navigationController pushViewController:[storyboard instantiateViewControllerWithIdentifier:@"initial"] animated:NO];
}


@end
