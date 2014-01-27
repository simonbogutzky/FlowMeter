//
//  HomeViewController.h
//  DataCollector
//
//  Created by Simon Bogutzky on 16.01.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import <CoreLocation/CoreLocation.h>
#import <HeartRateMonitor/HeartRateMonitor.h>
#import "LikertScaleViewControllerDelegate.h"

@interface HomeViewController : UIViewController <CLLocationManagerDelegate, UIAlertViewDelegate, HeartRateMonitorManagerDelegate, LikertScaleViewControllerDelegate>

@end
