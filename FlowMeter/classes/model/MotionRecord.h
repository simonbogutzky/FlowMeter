//
//  MotionRecord.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 21.01.15.
//  Copyright (c) 2015 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session;

@interface MotionRecord : NSManagedObject

@property (nonatomic) double userAccelerationX;
@property (nonatomic) double userAccelerationY;
@property (nonatomic) double userAccelerationZ;
@property (nonatomic) double gravityX;
@property (nonatomic) double gravityY;
@property (nonatomic) double gravityZ;
@property (nonatomic) double rotationRateX;
@property (nonatomic) double rotationRateY;
@property (nonatomic) double rotationRateZ;
@property (nonatomic) double attitudeRoll;
@property (nonatomic) double attitudePitch;
@property (nonatomic) double attitudeYaw;
@property (nonatomic) double timestamp;
@property (nonatomic, retain) Session *session;

@end
