//
//  TableViewCheckBoxCell.m
//  DataCollector
//
//  Created by Simon Bogutzky on 18.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "TableViewCheckBoxCell.h"

@implementation TableViewCheckBoxCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
