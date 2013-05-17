//
//  LocationRecord.h
//  DataCollector
//
//  Created by Simon Bogutzky on 26.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationRecord : NSObject

@property (nonatomic, assign) double timestamp;
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, assign) double altitude;
@property (nonatomic, assign) double speed;

- (id)initWithTimestamp:(double)timestamp Location:(CLLocation *)location;

@end