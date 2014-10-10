//
//  Session.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 29.08.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Activity, HeartRateRecord, SelfReport, User;

@interface Session : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * selfReportCount;
@property (nonatomic, retain) NSNumber * averageHeartrate;
@property (nonatomic, retain) NSNumber * averageFlow;
@property (nonatomic, retain) NSNumber * averageFit;
@property (nonatomic, retain) NSNumber * averageAbsorption;
@property (nonatomic, retain) NSNumber * averageFluency;
@property (nonatomic, retain) NSNumber * averageAnxiety;
@property (nonatomic, retain) NSSet *heartRateRecords;
@property (nonatomic, retain) NSSet *selfReports;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) Activity *activity;
@property (nonatomic, strong) NSString *sectionTitle;

@end

@interface Session (CoreDataGeneratedAccessors)

- (void)addHeartRateRecordsObject:(HeartRateRecord *)value;
- (void)removeHeartRateRecordsObject:(HeartRateRecord *)value;
- (void)addHeartRateRecords:(NSSet *)values;
- (void)removeHeartRateRecords:(NSSet *)values;

- (void)addSelfReportsObject:(SelfReport *)value;
- (void)removeSelfReportsObject:(SelfReport *)value;
- (void)addSelfReports:(NSSet *)values;
- (void)removeSelfReports:(NSSet *)values;

@end
