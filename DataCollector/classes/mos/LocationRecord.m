//
//  LocationRecord.m
//  DataCollector
//
//  Created by Simon Bogutzky on 26.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "LocationRecord.h"

@implementation LocationRecord

- (id)initWithTimestamp:(double)timestamp Location:(CLLocation *)location
{
    self = [super init];
    if (self) {
        self.timestamp = timestamp;
        self.latitude = location.coordinate.latitude;
        self.longitude = location.coordinate.longitude;
        self.altitude = location.altitude;
        self.speed = location.speed;
    }
    return self;
}

@end