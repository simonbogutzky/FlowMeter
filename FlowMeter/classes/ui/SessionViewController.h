//
//  SessionViewController.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 16.01.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HeartRateMonitor/HeartRateMonitor.h>
#import "LikertScaleViewControllerDelegate.h"

@interface SessionViewController : UIViewController <UIAlertViewDelegate, HeartRateMonitorManagerDelegate, LikertScaleViewControllerDelegate>

@property (nonatomic, strong) NSDictionary *sessionDictionary;

@end
