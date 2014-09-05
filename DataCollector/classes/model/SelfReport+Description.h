//
//  SelfReport+Description.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 27.01.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "SelfReport.h"

@interface SelfReport (Description)

- (NSString *)csvDescription;
- (NSString *)csvHeader;

@end
