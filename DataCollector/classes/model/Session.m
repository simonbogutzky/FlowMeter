//
//  Session.m
//  DataCollector
//
//  Created by Simon Bogutzky on 29.08.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "Session.h"
#import "Activity.h"
#import "HeartRateRecord.h"
#import "SelfReport.h"
#import "User.h"


@implementation Session

@dynamic date;
@dynamic duration;
@dynamic selfReportCount;
@dynamic averageBPM;
@dynamic averageFlow;
@dynamic averageFit;
@dynamic averageAbsorption;
@dynamic averageFluency;
@dynamic averageAnxiety;
@dynamic heartRateRecords;
@dynamic selfReports;
@dynamic user;
@dynamic activity;

@end
