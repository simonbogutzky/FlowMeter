//
//  HeartRateRecord+Description.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 25.08.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "HeartRateRecord+Description.h"

@implementation HeartRateRecord (Description)

- (NSString *)csvDescription
{
    return [NSString stringWithFormat:@"%f,%f\n",
            self.timestamp,
            self.rrInterval
            ];
}

- (NSString *)csvHeader
{
    NSMutableString *header = [NSMutableString stringWithFormat:@"%@,%@\n", NSLocalizedString(@"Zeitstempel (s)", @"Zeitstempel (s)"), NSLocalizedString(@"RR-Intervall (s)", @"RR-Intervall (s)")];
    return header;
}

@end