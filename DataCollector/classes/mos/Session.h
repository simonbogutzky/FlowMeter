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

@class CLLocation, Motion, User;

@interface Session : NSManagedObject

@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSNumber *isSynced;
@property (nonatomic, strong) NSNumber *isZipped;
@property (nonatomic, strong) NSNumber *motionDataCount;
@property (nonatomic, strong) NSNumber *heartRateMonitorDataCount;
@property (nonatomic, strong) NSNumber *locationDataCount;
@property (nonatomic, strong) User *user;

- (void)initialize;

- (void)addMotionData:(Motion *)motion;
- (void)addLocationData:(CLLocation *)location;
- (void)addHeartRateMonitorData:(HeartRateMonitorData *)heartRateMonitorData;

- (NSString *)storeMotions;
- (NSString *)storeHeartRateMonitorData;
- (NSString *)storeLocations;

@end
