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

@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSNumber *isSynced;
@property (nonatomic, strong) NSNumber *motionRecordsCount;
@property (nonatomic, strong) NSNumber *locationRecordsCount;
@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic, strong) User *user;

@property (nonatomic, strong) NSMutableArray *motionRecords;
@property (nonatomic, strong) NSMutableArray *locationRecords;

- (void)initialize;

- (void)addDeviceRecord:(MotionRecord *)deviceRecord;
- (void)addLocationRecord:(LocationRecord *)locationRecord;

- (void)saveAndZipMotionRecords;
- (void)saveAndZipLocationRecords;

@end
