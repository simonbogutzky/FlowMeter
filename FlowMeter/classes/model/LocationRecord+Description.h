//
//  LocationRecord+Description.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 06.02.15.
//  Copyright (c) 2015 Simon Bogutzky. All rights reserved.
//

#import "LocationRecord.h"

@interface LocationRecord (Description)

- (NSString *)csvDescription;
- (NSString *)csvHeader;

@end
