//
//  TableViewCheckBoxCell.h
//  DataCollector
//
//  Created by Simon Bogutzky on 18.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableViewCheckBoxCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *textLabel;
@property (nonatomic, weak) IBOutlet UISwitch *onOffSwitch;

@end
