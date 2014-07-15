//
//  LikertScaleViewControllerDelegate.h
//  DataCollector
//
//  Created by Simon Bogutzky on 27.01.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LikertScaleViewController;

@protocol LikertScaleViewControllerDelegate<NSObject>

@optional

- (void)likertScaleViewController:(LikertScaleViewController *)viewController didFinishWithResponses:(NSArray *)responses atDate:(NSDate *)date;
@end
