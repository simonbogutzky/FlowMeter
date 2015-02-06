//
//  LocationRecord+Description.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 06.02.15.
//  Copyright (c) 2015 Simon Bogutzky. All rights reserved.
//

#import "LocationRecord+Description.h"

@implementation LocationRecord (Description)

- (NSString *)csvDescription
{
    return [NSString stringWithFormat:@"%@,%f,%f,%f,%f,%f,%f,%f,%d\n",
            [self.dateFormatter stringFromDate:self.date],
            self.latitude,
            self.longitude,
            self.altitude,
            self.speed,
            self.course,
            self.horizontalAccuracy,
            self.verticalAccuracy,
            self.floor
            ];
}

- (NSString *)csvHeader
{
    NSMutableString *header = [NSMutableString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@\n",
                               NSLocalizedString(@"Datum", @"Datum"),
                               NSLocalizedString(@"Breitengrad", @"Breitengrad"),
                               NSLocalizedString(@"Längengrad", @"Längengrad"),
                               NSLocalizedString(@"Höhe (m)", @"Höhe (m)"),
                               NSLocalizedString(@"Geschwindigkeit (m/s)", @"Geschwindigkeit (m/s)"),
                               NSLocalizedString(@"Kurs (deg)", @"Kurs (deg)"),
                               NSLocalizedString(@"Horizontale Genauigkeit (m)", @"Horizontale Genauigkeit (m)"),
                               NSLocalizedString(@"Vertikale Genauigkeit (m)", @"Vertikale Genauigkeit (m)"),
                               NSLocalizedString(@"Stockwerk", @"Stockwerk")
                               ];
    return header;
}

- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    }
    return dateFormatter;
}



@end
