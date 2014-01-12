//
//  Motion.m
//  DataCollector
//
//  Created by Simon Bogutzky on 25.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "Motion.h"

@implementation Motion

- (id)initWithTimestamp:(double)timestamp deviceMotion:(CMDeviceMotion *)deviceMotion
{
    self = [super init];
    if (self) {
        self.timestamp = timestamp;
        self.userAccelerationX = deviceMotion.userAcceleration.x * -9.81;
        self.userAccelerationY = deviceMotion.userAcceleration.y * -9.81;
        self.userAccelerationZ = deviceMotion.userAcceleration.z * -9.81;
        self.gravityX = deviceMotion.gravity.x * -9.81;
        self.gravityY = deviceMotion.gravity.y * -9.81;
        self.gravityZ = deviceMotion.gravity.z * -9.81;
        self.rotationRateX = deviceMotion.rotationRate.x * 180 / M_PI;
        self.rotationRateY = deviceMotion.rotationRate.y * 180 / M_PI;
        self.rotationRateZ = deviceMotion.rotationRate.z * 180 / M_PI;
        self.attitudePitch = deviceMotion.attitude.pitch * 180 / M_PI;
        self.attitudeRoll = deviceMotion.attitude.roll * 180 / M_PI;
        self.attitudeYaw = deviceMotion.attitude.yaw * 180 / M_PI;
    }
    return self;
}

- (NSString *)csvDescription
{
    return [NSString stringWithFormat:@"%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
                self.timestamp,
                self.userAccelerationX,
                self.userAccelerationY,
                self.userAccelerationZ,
                self.gravityX,
                self.gravityY,
                self.gravityZ,
                self.rotationRateX,
                self.rotationRateY,
                self.rotationRateZ,
                self.attitudeYaw,
                self.attitudeRoll,
                self.attitudePitch
            ];
}

+ (NSString *)csvHeader
{
    return @"\"Timestamp\",\"UserAccelerationX\",\"UserAccelerationY\",\"UserAccelerationZ\",\"GravityX\",\"GravityY\",\"GravityZ\",\"RotationRateX\",\"RotationRateY\",\"RotationRateZ\",\"AttitudeYaw\",\"AttitudeRoll\",\"AttitudePitch\"\n";
}

@end