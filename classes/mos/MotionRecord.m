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
        self.userAccelerationX = deviceMotion.userAcceleration.x;
        self.userAccelerationY = deviceMotion.userAcceleration.y;
        self.userAccelerationZ = deviceMotion.userAcceleration.z;
        self.gravityX = deviceMotion.gravity.x;
        self.gravityY = deviceMotion.gravity.y;
        self.gravityZ = deviceMotion.gravity.z;
        self.rotationRateX = deviceMotion.rotationRate.x;
        self.rotationRateY = deviceMotion.rotationRate.y;
        self.rotationRateZ = deviceMotion.rotationRate.z;
        self.attitudePitch = deviceMotion.attitude.pitch;
        self.attitudeRoll = deviceMotion.attitude.roll;
        self.attitudeYaw = deviceMotion.attitude.yaw;
        
    }
    return self;
}

@end