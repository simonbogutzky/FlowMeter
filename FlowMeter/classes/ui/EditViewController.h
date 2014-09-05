//
//  EditViewController.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 03.05.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kTitleKey       @"title"   // key for obtaining the data source item's title
#define kValueKey       @"value"   // key for obtaining the data source item's value

@interface EditViewController : UIViewController

@property (nonatomic, strong) NSDictionary *itemDictionary;

@end
