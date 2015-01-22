//
//  HeartRateRecord.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 29.08.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session;

@interface HeartRateRecord : NSManagedObject

@property (nonatomic, assign) double rrInterval;
@property (nonatomic, assign) double timestamp;
@property (nonatomic, assign) int16_t heartRate;
@property (nonatomic, retain) Session *session;

@end
