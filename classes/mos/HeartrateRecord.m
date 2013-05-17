//
//  HeartrateRecord.m
//  DataCollector
//
//  Created by Simon Bogutzky on 26.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "HeartrateRecord.h"

@implementation HeartrateRecord

- (id)initWithTimestamp:(double)timestamp HeartrateData:(WFHeartrateData *)hrData
{
    self = [super init];
    if (self) {
        self.timestamp = timestamp;
        self.accumBeatCount = hrData.accumBeatCount;
        self.heartrate = [hrData formattedHeartrate:NO];
        self.rrIntervals = [[(WFBTLEHeartrateData*)hrData rrIntervals] componentsJoinedByString:@" "];
    }
    return self;
}

@end