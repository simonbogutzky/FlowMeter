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
        self.locationTime = [location.timestamp timeIntervalSince1970];
        self.latitude = location.coordinate.latitude;
        self.longitude = location.coordinate.longitude;
        self.altitude = location.altitude;
        self.speed = location.speed;
        self.systemTime = timestamp;
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

- (NSString *)gpxDescription
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.systemTime];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd'T'HH:mm:ss'Z'"];
    NSString *datetring = [formatter stringFromDate:date];
    
    
    return [NSString stringWithFormat:@"<trkpt lat=\"%f\" lon=\"%f\"><ele>%f</ele><time>%@</time></trkpt>",
            self.latitude,
            self.longitude,
            self.altitude,
            datetring
            ];
}

+ (NSString *)gpxHeader
{
    return @"<?xml version=\"1.0\"?><gpx version=\"1.0\" creator=\"DataCollector.app\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://www.topografix.com/GPX/1/0\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd\"><trk><trkseg>";
}

+ (NSString *)gpxFooter
{
    return @"</trk></trkseg></gpx>";
}

@end