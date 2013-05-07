//
//  EditViewController.h
//  DataCollector
//
//  Created by Simon Bogutzky on 03.05.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>

@class User;

@interface EditViewController : UIViewController

@property (nonatomic, strong) NSString *propertyName;
@property (nonatomic, strong) User *user;

@end
