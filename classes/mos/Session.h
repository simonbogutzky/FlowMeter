//
//  Session.h
//  DataCollector
//
//  Created by Simon Bogutzky on 25.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HeartrateRecord, MotionRecord;

@interface Session : NSManagedObject

@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSNumber * isSynced;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSSet *motionRecords;
@property (nonatomic, retain) NSSet *heatrateRecords;
@end

@interface Session (CoreDataGeneratedAccessors)

- (void)addMotionRecordsObject:(MotionRecord *)value;
- (void)removeMotionRecordsObject:(MotionRecord *)value;
- (void)addMotionRecords:(NSSet *)values;
- (void)removeMotionRecords:(NSSet *)values;

- (void)addHeatrateRecordsObject:(HeartrateRecord *)value;
- (void)removeHeatrateRecordsObject:(HeartrateRecord *)value;
- (void)addHeatrateRecords:(NSSet *)values;
- (void)removeHeatrateRecords:(NSSet *)values;

- (void)saveAndZipMotionRecords;

@end
