//
//  Session.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 29.08.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "Session.h"
#import "Activity.h"
#import "HeartRateRecord.h"
#import "LocationRecord.h"
#import "MotionRecord.h"
#import "SelfReport.h"
#import "User.h"


@implementation Session

@dynamic averageAbsorption;
@dynamic averageAnxiety;
@dynamic averageFit;
@dynamic averageFlow;
@dynamic averageFluency;
@dynamic averageHeartrate;
@dynamic date;
@dynamic duration;
@dynamic selfReportCount;
@dynamic activity;
@dynamic heartRateRecords;
@dynamic motionRecords;
@dynamic selfReports;
@dynamic locationRecords;
@dynamic user;
@synthesize sectionTitle;

- (NSString *)sectionTitle
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];
    return [dateFormatter stringFromDate:self.date];
}

- (void)addHeartRateRecordsObject:(HeartRateRecord *)value
{
    NSMutableOrderedSet* tempSet = [self mutableOrderedSetValueForKey:@"heartRateRecords"];
    [tempSet addObject:value];
}

- (void)addLocationRecordsObject:(LocationRecord *)value {
    NSMutableOrderedSet* tempSet = [self mutableOrderedSetValueForKey:@"locationRecords"];
    [tempSet addObject:value];
}

- (void)addMotionRecords:(NSOrderedSet *)values
{
    NSMutableOrderedSet* tempSet = [self mutableOrderedSetValueForKey:@"motionRecords"];
    [tempSet unionOrderedSet:values];
}

- (void)addSelfReportsObject:(SelfReport *)value
{
    NSMutableOrderedSet* tempSet = [self mutableOrderedSetValueForKey:@"selfReports"];
    [tempSet addObject:value];
}

@end
