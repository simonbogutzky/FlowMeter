//
//  Session.h
//  DataCollector
//
//  Created by Simon Bogutzky on 25.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <HeartRateMonitor/HeartRateMonitor.h>

@class Location, Motion, User;

@interface Session : NSManagedObject

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSNumber *isSynced;
@property (nonatomic, strong) NSNumber *isZipped;
@property (nonatomic, strong) NSNumber *motionRecordsCount;
@property (nonatomic, strong) NSNumber *heartrateRecordsCount;
@property (nonatomic, strong) NSNumber *locationRecordsCount;
@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic, strong) User *user;

@property (nonatomic, strong) NSMutableArray *motionRecords;
@property (nonatomic, strong) NSMutableArray *heartrateRecords;
@property (nonatomic, strong) NSMutableArray *locationRecords;

- (void)initialize;

- (void)addMotionRecord:(Motion *)motionRecord;
- (void)addLocationRecord:(Location *)locationRecord;
- (void)addHeartrateRecord:(HeartRateMonitorData *)heartrateRecord;


- (void)storeMotionData;
- (void)storeHeartRateMonitorData;
- (void)storeLocationData;

@end
