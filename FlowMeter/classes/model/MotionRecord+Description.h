//
//  MotionRecord+Description.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 21.01.15.
//  Copyright (c) 2015 Simon Bogutzky. All rights reserved.
//

#import "MotionRecord.h"

@interface MotionRecord (Description)

- (NSString *)csvDescription;
- (NSString *)csvHeader;

@end
