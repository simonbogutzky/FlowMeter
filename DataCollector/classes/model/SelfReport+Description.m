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
    return [NSString stringWithFormat:@"%.0f,%@\n",
            [self.date timeIntervalSince1970],
            self.responses
            ];
}

- (NSString *)csvHeader
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:NSLocalizedString(@"dd.MM.yy", @"dd.MM.yy")];
    NSString *dateString = [dateFormatter stringFromDate:self.session.date];
    [dateFormatter setDateFormat:NSLocalizedString(@"HH:mm", @"HH:mm")];
    NSString *timeString = [dateFormatter stringFromDate:self.session.date];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[self.session.duration doubleValue]];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
    NSString *durationString = [dateFormatter stringFromDate:date];
    
    NSMutableString *header = [NSMutableString stringWithFormat:@"%@:\t\t%@\n%@:\t\t%@\n%@:\t\t%@\n%@:\t%@\n%@:\t\t%@\n%@:\t%@\n\n\"%@\",", NSLocalizedString(@"Datum *", @"Datum"), dateString, NSLocalizedString(@"Beginn *", @"Beginn"), timeString, NSLocalizedString(@"Dauer *", @"Dauer"), durationString, NSLocalizedString(@"Aktivität *", @"Aktivität"), self.session.activity, NSLocalizedString(@"Person *", @"Person"), [NSString stringWithFormat:@"%@ %@", self.session.user.firstName, self.session.user.lastName], NSLocalizedString(@"Fragebogen *", @"Fragebogen"), self.session.questionnaire, NSLocalizedString(@"Zeitstempel *", @"Zeitstempel")];
    
    for (int i = 1; i <= [self.session.numberOfItems intValue]; i++) {
        if (i == [self.session.numberOfItems intValue]) {
            [header appendFormat:@"\"%@ %d\"\n", NSLocalizedString(@"Item *", @"Item"), i];
        } else {
            [header appendFormat:@"\"%@ %d\",", NSLocalizedString(@"Item *", @"Item"), i];
        }
    }
    return header;
}

@end
