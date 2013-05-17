//
//  HeartrateRecord.h
//  DataCollector
//
//  Created by Simon Bogutzky on 26.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WFConnector/WFConnector.h>

@class Session;

@interface HeartrateRecord : NSObject

@property (nonatomic, assign) int accumBeatCount;
@property (nonatomic, retain) NSString *heartrate;
@property (nonatomic, retain) NSString *rrIntervals;
@property (nonatomic, assign) double timestamp;

- (id)initWithTimestamp:(double)timestamp HeartrateData:(WFHeartrateData *)hrData;

@end