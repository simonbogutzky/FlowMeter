//
//  Motion.h
//  DataCollector
//
//  Created by Simon Bogutzky on 25.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

@interface Motion : NSObject

@property (nonatomic, assign) double sensorTime;
@property (nonatomic, assign) double userAccelerationX;
@property (nonatomic, assign) double userAccelerationY;
@property (nonatomic, assign) double userAccelerationZ;
@property (nonatomic, assign) double gravityX;
@property (nonatomic, assign) double gravityY;
@property (nonatomic, assign) double gravityZ;
@property (nonatomic, assign) double rotationRateX;
@property (nonatomic, assign) double rotationRateXFiltered;
@property (nonatomic, assign) double rotationRateY;
@property (nonatomic, assign) double rotationRateZ;
@property (nonatomic, assign) double attitudePitch;
@property (nonatomic, assign) double attitudeYaw;
@property (nonatomic, assign) double attitudeRoll;
@property (nonatomic, assign) double systemTime;

- (id)initWithTimestamp:(double)timestamp DeviceMotion:(CMDeviceMotion *)deviceMotion;
- (NSString *)csvDescription;
+ (NSString *)csvHeader;

@end