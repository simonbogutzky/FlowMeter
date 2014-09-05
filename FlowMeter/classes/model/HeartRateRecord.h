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

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * rrInterval;
@property (nonatomic, retain) NSNumber * timeInterval;
@property (nonatomic, retain) NSNumber * heartRate;
@property (nonatomic, retain) Session *session;

@end
