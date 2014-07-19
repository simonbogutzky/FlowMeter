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
#import <DropboxSDK/DropboxSDK.h>

@class CLLocation, Motion, User, SelfReport;

@interface Session : NSManagedObject

@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic, strong) NSString *dateTimeString;
//@property (nonatomic, strong) NSNumber *motionDataCount;
@property (nonatomic, strong) NSNumber *heartRateMonitorDataCount;
//@property (nonatomic, strong) NSNumber *locationDataCount;
@property (nonatomic, strong) NSNumber *selfReportCount;
//@property (nonatomic, strong) NSNumber *motionDataIsSynced;
@property (nonatomic, strong) NSNumber *heartRateMonitorDataIsSynced;
//@property (nonatomic, strong) NSNumber *locationDataIsSynced;
@property (nonatomic, strong) NSNumber *selfReportsAreSynced;
@property (nonatomic, strong) User *user;

- (void)initialize;

//- (void)addMotionData:(Motion *)motion;
//- (void)addLocationData:(CLLocation *)location;
- (void)addHeartRateMonitorData:(HeartRateMonitorData *)heartRateMonitorData;
- (void)addSelfReport:(SelfReport *)selfReport;

//- (NSString *)storeMotions;
- (NSString *)storeHeartRateMonitorData;
//- (NSString *)storeLocations;
- (NSString *)storeSelfReports;

@end
