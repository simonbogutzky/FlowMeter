//
//  LabelAndSwitchTableViewCell.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 08.09.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LabelAndSwitchTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UISwitch *contentswitch;

@end
