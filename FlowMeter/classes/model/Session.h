//
//  Session.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 29.08.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Activity, HeartRateRecord, LocationRecord, MotionRecord, SelfReport, User;

@interface Session : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic) float averageAbsorption;
@property (nonatomic) float averageAnxiety;
@property (nonatomic) float averageFit;
@property (nonatomic) float averageFlow;
@property (nonatomic) float averageFluency;
@property (nonatomic) float averageHeartrate;
@property (nonatomic) double duration;
@property (nonatomic) int16_t selfReportCount;
@property (nonatomic, retain) Activity *activity;
@property (nonatomic, retain) NSSet *heartRateRecords;
@property (nonatomic, retain) NSSet *motionRecords;
@property (nonatomic, retain) NSSet *locationRecords;
@property (nonatomic, retain) NSSet *selfReports;
@property (nonatomic, retain) User *user;
@property (nonatomic, strong) NSString *sectionTitle;
@end

@interface Session (CoreDataGeneratedAccessors)

- (void)addHeartRateRecordsObject:(HeartRateRecord *)value;
- (void)removeHeartRateRecordsObject:(HeartRateRecord *)value;
- (void)addHeartRateRecords:(NSSet *)values;
- (void)removeHeartRateRecords:(NSSet *)values;

- (void)addMotionRecordsObject:(MotionRecord *)value;
- (void)removeMotionRecordsObject:(MotionRecord *)value;
- (void)addMotionRecords:(NSSet *)values;
- (void)removeMotionRecords:(NSSet *)values;

- (void)addSelfReportsObject:(SelfReport *)value;
- (void)removeSelfReportsObject:(SelfReport *)value;
- (void)addSelfReports:(NSSet *)values;
- (void)removeSelfReports:(NSSet *)values;

- (void)addLocationRecordsObject:(LocationRecord *)value;
- (void)removeLocationRecordsObject:(LocationRecord *)value;
- (void)addLocationRecords:(NSSet *)values;
- (void)removeLocationRecords:(NSSet *)values;

@end
