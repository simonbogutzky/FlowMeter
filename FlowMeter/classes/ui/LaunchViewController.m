//
//  LaunchViewController.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 23.01.15.
//  Copyright (c) 2015 Simon Bogutzky. All rights reserved.
//

#import "LaunchViewController.h"

@interface LaunchViewController ()

@end

@implementation LaunchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    [self performSelector:@selector(showTabBar) withObject:nil afterDelay:3.0];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (void)showTabBar
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    UITabBarController *tabBarController = [storyboard instantiateViewControllerWithIdentifier:@"TabBar"];
    tabBarController.selectedIndex = 1;
    tabBarController.tabBar.translucent = NO;
    
    [self presentViewController:tabBarController animated:NO completion:^{
        [UINavigationBar appearance].tintColor = [UIColor whiteColor];
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
        [UIApplication sharedApplication].statusBarHidden = NO;
    }];
}

@end
