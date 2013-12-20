//
//  Location.m
//  DataCollector
//
//  Created by Simon Bogutzky on 26.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "Location.h"

@implementation Location

- (id)initWithTimestamp:(double)timestamp Location:(CLLocation *)location
{
    self = [super init];
    if (self) {
        self.timestamp = timestamp;
        self.latitude = location.coordinate.latitude;
        self.longitude = location.coordinate.longitude;
        self.altitude = location.altitude;
        self.speed = location.speed;
    }
    return self;
}

- (NSString *)kmlDescription
{
    return [NSString stringWithFormat:@"%f,%f,%f\n",
            self.longitude,
            self.latitude,
            self.altitude
            ];
}

+ (NSString *)kmlHeader
{
    return @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><kml xmlns=\"http://www.opengis.net/kml/2.2\"><Document><name>Paths</name><description></description><Style id=\"yellowLineGreenPoly\"><LineStyle><color>7f00ffff</color><width>8</width></LineStyle><PolyStyle><color>7f00ff00</color></PolyStyle></Style><Placemark><name>Absolute Extruded</name><description>Transparent green wall with yellow outlines</description><styleUrl>#yellowLineGreenPoly</styleUrl><LineString><extrude>2</extrude><tessellate>1</tessellate><altitudeMode>absolute</altitudeMode><coordinates>";
}

+ (NSString *)kmlFooter
{
    return @"</coordinates></LineString></Placemark></Document></kml>";
}

@end