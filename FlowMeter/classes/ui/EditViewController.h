//
//  EditViewController.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 03.05.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSDictionary *itemDictionary;

@end
