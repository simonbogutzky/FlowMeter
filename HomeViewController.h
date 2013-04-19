//
//  HomeViewController.h
//  DataCollector
//
//  Created by Simon Bogutzky on 16.01.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFConnector/WFConnector.h>
#import <DropboxSDK/DropboxSDK.h>
#import "AbtractSlidingTopViewController.h"

@interface HomeViewController : AbtractSlidingTopViewController <DBRestClientDelegate>

@end
