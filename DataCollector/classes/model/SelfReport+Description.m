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
    //TODO: Datums und Intervall Formatter einfügen
    return [NSString stringWithFormat:@"%.0f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
            [self.date timeIntervalSince1970],
            [self.duration doubleValue],
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

@end
