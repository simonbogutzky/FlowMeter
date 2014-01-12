//
//  CLLocation+Descriptions.h
//  DataCollector
//
//  Created by Simon Bogutzky on 11.01.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface CLLocation (Descriptions)

- (NSString *)kmlDescription;
+ (NSString *)kmlHeader;
+ (NSString *)kmlFooter;
- (NSString *)gpxDescription;
+ (NSString *)gpxHeader;
+ (NSString *)gpxFooter;

@end
