//
//  Session.h
//  DataCollector
//
//  Created by Simon Bogutzky on 25.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HeartrateRecord, LocationRecord, MotionRecord, User;

@interface Session : NSManagedObject

@property (nonatomic, retain) NSString *filename;
@property (nonatomic, retain) NSNumber *isSynced;
@property (nonatomic, retain) NSDate *timestamp;
@property (nonatomic, retain) NSMutableArray *motionRecords;
@property (nonatomic, retain) NSMutableArray *heatrateRecords;
@property (nonatomic, retain) NSSet * locationRecords;
@property (nonatomic, retain) User *user;
@end

@interface Session (CoreDataGeneratedAccessors)

- (void)addLocationRecordsObject:(LocationRecord *)value;
- (void)removeLocationRecordsObject:(LocationRecord *)value;
- (void)addLocationRecords:(NSSet *)values;
- (void)removeLocationRecords:(NSSet *)values;

- (void)initialize;

- (void)addDeviceRecord:(MotionRecord *)deviceRecord;
- (void)addHeartrateRecord:(HeartrateRecord *)heartrateRecord;

- (void)saveAndZipMotionRecords;
- (void)saveAndZipHeartrateRecords;
- (void)saveAndZipLocationRecords;

@end
