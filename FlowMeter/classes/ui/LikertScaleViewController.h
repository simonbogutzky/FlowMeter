//
//  LikertScaleViewController.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 21.01.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LikertScaleViewControllerDelegate.h"

@interface LikertScaleViewController : UIViewController
@property (strong, nonatomic) NSArray *itemLabelTexts;
@property (strong, nonatomic) NSArray *itemSegments;
@property (strong, nonatomic) NSArray *scaleLabels;
@property (strong, nonatomic) NSArray *cicleColors;
@property (weak, nonatomic) id <LikertScaleViewControllerDelegate> delegate;
@end
