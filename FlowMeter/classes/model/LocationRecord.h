//
//  LocationRecord.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 06.02.15.
//  Copyright (c) 2015 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session;

@interface LocationRecord : NSManagedObject

@property (nonatomic, retain) NSDate *date;
@property (nonatomic) double latitude;
@property (nonatomic) double course;
@property (nonatomic) double longitude;
@property (nonatomic) double altitude;
@property (nonatomic) int16_t floor;
@property (nonatomic) double horizontalAccuracy;
@property (nonatomic) double verticalAccuracy;
@property (nonatomic) double speed;
@property (nonatomic, retain) Session *session;

@end
