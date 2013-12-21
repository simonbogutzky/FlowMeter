//
//  Location.h
//  DataCollector
//
//  Created by Simon Bogutzky on 26.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Location : NSObject

@property (nonatomic, assign) double locationTime;
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, assign) double altitude;
@property (nonatomic, assign) double speed;
@property (nonatomic, assign) double systemTime;

- (id)initWithTimestamp:(double)timestamp Location:(CLLocation *)location;
- (NSString *)kmlDescription;
+ (NSString *)kmlHeader;
+ (NSString *)kmlFooter;
- (NSString *)gpxDescription;
+ (NSString *)gpxHeader;
+ (NSString *)gpxFooter;

@end