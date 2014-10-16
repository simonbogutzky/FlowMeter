//
//  PropertyTableViewCell.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 14.10.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PropertyTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *labelPropertyName;
@property (weak, nonatomic) IBOutlet UILabel *labelPropertyValue;
@property (weak, nonatomic) IBOutlet UIView *viewCircle;
@property (weak, nonatomic) IBOutlet UIView *viewCircleSelectionIndicator;
@property (strong, nonatomic) UIColor *color;

@end

