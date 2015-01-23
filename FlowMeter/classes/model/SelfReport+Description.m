//
//  SelfReport+Description.m
//  FlowMeter
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
    return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f\n",
            self.timestamp,
            self.duration,
            self.flow,
            self.flowSD,
            self.fluency,
            self.fluencySD,
            self.absorption,
            self.absorptionSD,
            self.anxiety,
            self.anxietySD,
            self.fit,
            self.fitSD
            ];
}

- (NSString *)csvHeader
{
    return [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@\n", NSLocalizedString(@"Zeitstempel (s)", @"Zeitstempel (s)"), NSLocalizedString(@"Dauer (s)", @"Dauer (s)"), NSLocalizedString(@"Flow", @"Flow"), NSLocalizedString(@"Flow (SD)", @"Flow (SD)"), NSLocalizedString(@"Verlauf", @"Verlauf"), NSLocalizedString(@"Verlauf (SD)", @"Verlauf (SD)"), NSLocalizedString(@"Absorbiertheit", @"Absorbiertheit"), NSLocalizedString(@"Absorbiertheit (SD)", @"Absorbiertheit (SD)"), NSLocalizedString(@"Besorgnis", @"Besorgnis"), NSLocalizedString(@"Besorgnis (SD)", @"Besorgnis (SD)"), NSLocalizedString(@"Passung", @"Passung"), NSLocalizedString(@"Passung (SD)", @"Passung (SD)")];
}

@end
