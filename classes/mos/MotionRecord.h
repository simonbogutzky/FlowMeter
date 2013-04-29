//
//  MotionRecord.h
//  DataCollector
//
//  Created by Simon Bogutzky on 25.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session;

@interface MotionRecord : NSManagedObject

@property (nonatomic, retain) NSNumber * timestamp;
@property (nonatomic, retain) NSNumber * userAccelerationX;
@property (nonatomic, retain) NSNumber * userAccelerationY;
@property (nonatomic, retain) NSNumber * userAccelerationZ;
@property (nonatomic, retain) NSNumber * gravityX;
@property (nonatomic, retain) NSNumber * gravityY;
@property (nonatomic, retain) NSNumber * gravityZ;
@property (nonatomic, retain) NSNumber * rotationRateX;
@property (nonatomic, retain) NSNumber * rotationRateXFiltered1;
@property (nonatomic, retain) NSNumber * rotationRateXFiltered2;
@property (nonatomic, retain) NSNumber * rotationRateXQuantile;
@property (nonatomic, retain) NSNumber * rotationRateXFiltered1Quantile;
@property (nonatomic, retain) NSNumber * rotationRateXFiltered2Quantile;
@property (nonatomic, retain) NSNumber * rotationRateXSlope;
@property (nonatomic, retain) NSNumber * rotationRateXFiltered1Slope;
@property (nonatomic, retain) NSNumber * rotationRateXFiltered2Slope;
@property (nonatomic, retain) NSNumber * rotationRateY;
@property (nonatomic, retain) NSNumber * rotationRateZ;
@property (nonatomic, retain) NSNumber * attitudePitch;
@property (nonatomic, retain) NSNumber * attitudeYaw;
@property (nonatomic, retain) NSNumber * attitudeRoll;
@property (nonatomic, retain) Session *session;

@end
