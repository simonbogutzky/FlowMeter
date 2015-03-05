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
@property (nonatomic, retain) NSOrderedSet *heartRateRecords;
@property (nonatomic, retain) NSOrderedSet *locationRecords;
@property (nonatomic, retain) NSOrderedSet *motionRecords;
@property (nonatomic, retain) NSOrderedSet *selfReports;
@property (nonatomic, retain) User *user;
@property (nonatomic, strong) NSString *sectionTitle;
@end

@interface Session (CoreDataGeneratedAccessors)

- (void)insertObject:(HeartRateRecord *)value inHeartRateRecordsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHeartRateRecordsAtIndex:(NSUInteger)idx;
- (void)insertHeartRateRecords:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHeartRateRecordsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHeartRateRecordsAtIndex:(NSUInteger)idx withObject:(HeartRateRecord *)value;
- (void)replaceHeartRateRecordsAtIndexes:(NSIndexSet *)indexes withHeartRateRecords:(NSArray *)values;
- (void)addHeartRateRecordsObject:(HeartRateRecord *)value;
- (void)removeHeartRateRecordsObject:(HeartRateRecord *)value;
- (void)addHeartRateRecords:(NSOrderedSet *)values;
- (void)removeHeartRateRecords:(NSOrderedSet *)values;
- (void)insertObject:(LocationRecord *)value inLocationRecordsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromLocationRecordsAtIndex:(NSUInteger)idx;
- (void)insertLocationRecords:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeLocationRecordsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInLocationRecordsAtIndex:(NSUInteger)idx withObject:(LocationRecord *)value;
- (void)replaceLocationRecordsAtIndexes:(NSIndexSet *)indexes withLocationRecords:(NSArray *)values;
- (void)addLocationRecordsObject:(LocationRecord *)value;
- (void)removeLocationRecordsObject:(LocationRecord *)value;
- (void)addLocationRecords:(NSOrderedSet *)values;
- (void)removeLocationRecords:(NSOrderedSet *)values;
- (void)insertObject:(MotionRecord *)value inMotionRecordsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromMotionRecordsAtIndex:(NSUInteger)idx;
- (void)insertMotionRecords:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeMotionRecordsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInMotionRecordsAtIndex:(NSUInteger)idx withObject:(MotionRecord *)value;
- (void)replaceMotionRecordsAtIndexes:(NSIndexSet *)indexes withMotionRecords:(NSArray *)values;
- (void)addMotionRecordsObject:(MotionRecord *)value;
- (void)removeMotionRecordsObject:(MotionRecord *)value;
- (void)addMotionRecords:(NSOrderedSet *)values;
- (void)removeMotionRecords:(NSOrderedSet *)values;
- (void)insertObject:(SelfReport *)value inSelfReportsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSelfReportsAtIndex:(NSUInteger)idx;
- (void)insertSelfReports:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSelfReportsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSelfReportsAtIndex:(NSUInteger)idx withObject:(SelfReport *)value;
- (void)replaceSelfReportsAtIndexes:(NSIndexSet *)indexes withSelfReports:(NSArray *)values;
- (void)addSelfReportsObject:(SelfReport *)value;
- (void)removeSelfReportsObject:(SelfReport *)value;
- (void)addSelfReports:(NSOrderedSet *)values;
- (void)removeSelfReports:(NSOrderedSet *)values;
@end
