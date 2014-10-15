//
//  PropertyTableViewCell.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 14.10.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "PropertyTableViewCell.h"

@implementation PropertyTableViewCell

@synthesize color = _color;

- (UIColor *)color
{
    if (_color == nil) {
        _color = [UIColor redColor];
    }
    return _color;
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    self.viewCircle.backgroundColor = color;
    if (self.selected) {
        self.viewCircleSelectionIndicator.backgroundColor = color;
    } else {
        self.viewCircleSelectionIndicator.backgroundColor = [UIColor clearColor];
    }
}

- (void)awakeFromNib {
    self.viewCircle.layer.cornerRadius = 10;
    self.viewCircle.backgroundColor = self.color;
    
    self.viewCircleSelectionIndicator.layer.cornerRadius = 14;
    self.viewCircleSelectionIndicator.backgroundColor = [UIColor clearColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    if (selected) {
        self.viewCircleSelectionIndicator.backgroundColor = [self.color colorWithAlphaComponent:0.6];
    } else {
        self.viewCircleSelectionIndicator.backgroundColor = [UIColor clearColor];
    }

}

@end
