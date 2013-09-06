//
//  MotionRecord.m
//  DataCollector
//
//  Created by Simon Bogutzky on 25.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "MotionRecord.h"

@implementation MotionRecord

- (id)initWithTimestamp:(double)timestamp DeviceMotion:(CMDeviceMotion *)deviceMotion
{
    self = [super init];
    if (self) {
        self.timestamp = timestamp * 1000;
        self.sensorTime = deviceMotion.timestamp * 1000;
        self.userAccelerationX = deviceMotion.userAcceleration.x * -9.81;
        self.userAccelerationY = deviceMotion.userAcceleration.y * -9.81;
        self.userAccelerationZ = deviceMotion.userAcceleration.z * -9.81;
        self.gravityX = deviceMotion.gravity.x * -9.81;
        self.gravityY = deviceMotion.gravity.y * -9.81;
        self.gravityZ = deviceMotion.gravity.z * -9.81;
        self.rotationRateX = deviceMotion.rotationRate.x * 180 / M_PI;
        self.rotationRateY = deviceMotion.rotationRate.y * 180 / M_PI;
        self.rotationRateZ = deviceMotion.rotationRate.z * 180 / M_PI;
        self.attitudePitch = deviceMotion.attitude.pitch;
        self.attitudeRoll = deviceMotion.attitude.roll;
        self.attitudeYaw = deviceMotion.attitude.yaw;
        
    }
    return self;
}

@end