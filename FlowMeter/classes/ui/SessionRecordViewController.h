//
//  SessionRecordViewController.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 16.01.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HeartRateMonitorFramework/HeartRateMonitorFramework.h>
#import "LikertScaleViewControllerDelegate.h"

@interface SessionRecordViewController : UIViewController <HeartRateMonitorManagerDelegate, LikertScaleViewControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSArray *sessionData;

@end
