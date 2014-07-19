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

@property (nonatomic) double timestamp;
@property (nonatomic) double userAccelerationX;
@property (nonatomic) double userAccelerationY;
@property (nonatomic) double userAccelerationZ;
@property (nonatomic) double gravityX;
@property (nonatomic) double gravityY;
@property (nonatomic) double gravityZ;
@property (nonatomic) double rotationRateX;
@property (nonatomic) double rotationRateY;
@property (nonatomic) double rotationRateZ;
@property (nonatomic) double attitudePitch;
@property (nonatomic) double attitudeYaw;
@property (nonatomic) double attitudeRoll;

- (id)initWithTimestamp:(double)timestamp deviceMotion:(CMDeviceMotion *)deviceMotion;
- (NSString *)csvDescription;
+ (NSString *)csvHeader;

@end