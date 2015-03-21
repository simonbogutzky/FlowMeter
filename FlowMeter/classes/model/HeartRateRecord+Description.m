//
//  HeartRateRecord+Description.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 25.08.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "HeartRateRecord+Description.h"

@implementation HeartRateRecord (Description)

+ (NSString *)csvHeader
{
    return [NSMutableString stringWithFormat:@"%@ \n\n%@,%@\n", NSLocalizedString(@"HR-Messungen", @"HR-Messungen"),NSLocalizedString(@"Zeitstempel (s)", @"Zeitstempel (s)"), NSLocalizedString(@"RR-Intervall (s)", @"RR-Intervall (s)")];
}

@end