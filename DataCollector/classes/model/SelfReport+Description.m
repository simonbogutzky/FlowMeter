//
//  SelfReport+Description.m
//  DataCollector
//
//  Created by Simon Bogutzky on 27.01.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "SelfReport+Description.h"
#import "Session.h"
#import "User.h"

@implementation SelfReport (Description)

- (NSString *)csvDescription
{
    return [NSString stringWithFormat:@"%@,%@,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
            [self.dateFormatter stringFromDate:self.date],
            [self stringFromTimeInterval:[self.duration doubleValue]],
            [self.flow floatValue],
            [self.flowSD floatValue],
            [self.fluency floatValue],
            [self.fluencySD floatValue],
            [self.absorption floatValue],
            [self.absorptionSD floatValue],
            [self.anxiety floatValue],
            [self.anxietySD floatValue],
            [self.fit floatValue],
            [self.fitSD floatValue]
            ];
}

- (NSString *)csvHeader
{
    return [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@\n", NSLocalizedString(@"Datum", @"Datum"), NSLocalizedString(@"Dauer", @"Dauer"), NSLocalizedString(@"Flow", @"Flow"), NSLocalizedString(@"Flow (SD)", @"Flow (SD)"), NSLocalizedString(@"Verlauf", @"Verlauf"), NSLocalizedString(@"Verlauf (SD)", @"Verlauf (SD)"), NSLocalizedString(@"Absorbiertheit", @"Absorbiertheit"), NSLocalizedString(@"Absorbiertheit (SD)", @"Absorbiertheit (SD)"), NSLocalizedString(@"Besorgnis", @"Besorgnis"), NSLocalizedString(@"Besorgnis (SD)", @"Besorgnis (SD)"), NSLocalizedString(@"Passung", @"Passung"), NSLocalizedString(@"Passung (SD)", @"Passung (SD)")];
}

- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateIntervalFormatterShortStyle;
        dateFormatter.timeStyle = NSDateIntervalFormatterShortStyle;
    }
    return dateFormatter;
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval
{
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ldh %02ldm %02lds", (long)hours, (long)minutes, (long)seconds];
}

@end
