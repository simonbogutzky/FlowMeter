//
//  Session.h
//  DataCollector
//
//  Created by Simon Bogutzky on 15.07.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SelfReport, HeartRateRecord, User;

@interface Session : NSManagedObject

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *activity;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) NSSet *selfReports;
@property (nonatomic, retain) NSSet *heartRateRecords;
@property (nonatomic, retain) NSNumber *duration;
@property (nonatomic, retain) NSString *questionnaire;
@property (nonatomic, retain) NSNumber *numberOfItems;
@end

@interface Session (CoreDataGeneratedAccessors)

- (void)addSelfReportsObject:(SelfReport *)value;
- (void)removeSelfReportsObject:(SelfReport *)value;
- (void)addSelfReports:(NSSet *)values;
- (void)removeSelfReports:(NSSet *)values;
- (void)addHeartRateRecordsObject:(HeartRateRecord *)value;
- (void)removeHeartRateRecordsObject:(HeartRateRecord *)value;
- (void)addHeartRateRecords:(NSSet *)values;
- (void)removeHeartRateRecords:(NSSet *)values;

@end
