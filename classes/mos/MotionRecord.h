//
//  MotionRecord.h
//  DataCollector
//
//  Created by Simon Bogutzky on 25.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

@interface MotionRecord : NSObject

@property (nonatomic, assign) double timestamp;
@property (nonatomic, assign) double userAccelerationX;
@property (nonatomic, assign) double userAccelerationY;
@property (nonatomic, assign) double userAccelerationZ;
@property (nonatomic, assign) double gravityX;
@property (nonatomic, assign) double gravityY;
@property (nonatomic, assign) double gravityZ;
@property (nonatomic, assign) double rotationRateX;
@property (nonatomic, assign) double rotationRateXFiltered1;
@property (nonatomic, assign) double rotationRateXFiltered2;
@property (nonatomic, assign) double rotationRateXQuantile;
@property (nonatomic, assign) double rotationRateXFiltered1Quantile;
@property (nonatomic, assign) double rotationRateXFiltered2Quantile;
@property (nonatomic, assign) double rotationRateXSlope;
@property (nonatomic, assign) double rotationRateXFiltered1Slope;
@property (nonatomic, assign) double rotationRateXFiltered2Slope;
@property (nonatomic, assign) BOOL rotationRateXIndicator;
@property (nonatomic, assign) BOOL rotationRateXFiltered1Indicator;
@property (nonatomic, assign) BOOL rotationRateXFiltered2Indicator;
@property (nonatomic, assign) double rotationRateY;
@property (nonatomic, assign) double rotationRateZ;
@property (nonatomic, assign) double attitudePitch;
@property (nonatomic, assign) double attitudeYaw;
@property (nonatomic, assign) double attitudeRoll;
@property (nonatomic, retain) NSString *event;

- (id)initWithTimestamp:(double)timestamp DeviceMotion:(CMDeviceMotion *)deviceMotion;

@end