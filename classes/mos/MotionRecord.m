//
//  MotionRecord.m
//  DataCollector
//
//  Created by Simon Bogutzky on 25.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "MotionRecord.h"
#import "Session.h"


@implementation MotionRecord

@dynamic timestamp;
@dynamic userAccelerationX;
@dynamic userAccelerationY;
@dynamic userAccelerationZ;
@dynamic gravityX;
@dynamic gravityY;
@dynamic gravityZ;
@dynamic rotationRateX;
@dynamic rotationRateXFiltered1;
@dynamic rotationRateXFiltered2;
@dynamic rotationRateXQuantile;
@dynamic rotationRateXFiltered1Quantile;
@dynamic rotationRateXFiltered2Quantile;
@dynamic rotationRateXSlope;
@dynamic rotationRateXFiltered1Slope;
@dynamic rotationRateXFiltered2Slope;
@dynamic rotationRateY;
@dynamic rotationRateZ;
@dynamic attitudePitch;
@dynamic attitudeYaw;
@dynamic attitudeRoll;
@dynamic session;

@end
