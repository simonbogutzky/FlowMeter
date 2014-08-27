//
//  HeartRateRecord+Description.h
//  DataCollector
//
//  Created by Simon Bogutzky on 25.08.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "HeartRateRecord.h"

@interface HeartRateRecord (Description)

- (NSString *)csvDescription;
- (NSString *)csvHeader;

@end
