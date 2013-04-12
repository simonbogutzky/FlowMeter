//
//  CMDeviceMotion+TransformToReferenceFrame.h
//  DataCollector
//
//  Created by Simon Bogutzky on 11.02.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>

@interface CMDeviceMotion (TransformToReferenceFrame)
-(CMAcceleration)userAccelerationInReferenceFrame;
@end
