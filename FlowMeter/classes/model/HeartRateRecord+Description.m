//
//  HeartRateRecord+Description.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 25.08.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "HeartRateRecord+Description.h"
#import "Session.h"
#import "User.h"

@implementation HeartRateRecord (Description)

- (NSString *)csvDescription
{
    return [NSString stringWithFormat:@"%@,%f,%f,%d\n",
            [self.dateFormatter stringFromDate:self.date],
            [self.timeInterval doubleValue] / 1000,
            [self.rrInterval doubleValue] / 1000,
            [self.heartRate intValue]
            ];
}

- (NSString *)csvHeader
{
    NSMutableString *header = [NSMutableString stringWithFormat:@"%@,%@,%@,%@\n", NSLocalizedString(@"Datum", @"Datum"), NSLocalizedString(@"Zeitstempel (s)", @"Zeitstempel (s)"), NSLocalizedString(@"RR-Intervall (s)", @"RR-Intervall (s)"), NSLocalizedString(@"Herzrate (BPM)", @"Herzrate (BPM)")];
    return header;
}

- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return dateFormatter;
}

@end