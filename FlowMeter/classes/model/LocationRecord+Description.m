//
//  LocationRecord+Description.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 06.02.15.
//  Copyright (c) 2015 Simon Bogutzky. All rights reserved.
//

#import "LocationRecord+Description.h"
#import "Session.h"
#import "User.h"
#import "Activity.h"

@implementation LocationRecord (Description)


- (NSString *)kmlTimelineDescription
{
    NSString *description = [NSString stringWithFormat:@"%@: %@ \n%@: %f \n%@: %f \n%@: %f \n%@: %f \n%@: %f \n %@: %f \n %@: %f \n %@: %d \n",
                             NSLocalizedString(@"Zeit", @"Zeit"),
                             [self.timeFormatter stringFromDate:self.date],
                             NSLocalizedString(@"Breitengrad", @"Breitengrad"),
                             self.latitude,
                             NSLocalizedString(@"Längengrad", @"Längengrad"),
                             self.longitude,
                             NSLocalizedString(@"Höhe (m)", @"Höhe (m)"),
                             self.altitude,
                             NSLocalizedString(@"Geschwindigkeit (m/s)", @"Geschwindigkeit (m/s)"),
                             self.speed,
                             NSLocalizedString(@"Kurs (deg)", @"Kurs (deg)"),
                             self.course,
                             NSLocalizedString(@"Horizontale Genauigkeit (m)", @"Horizontale Genauigkeit (m)"),
                             self.horizontalAccuracy,
                             NSLocalizedString(@"Vertikale Genauigkeit (m)", @"Vertikale Genauigkeit (m)"),
                             self.verticalAccuracy,
                             NSLocalizedString(@"Stockwerk", @"Stockwerk"),
                             self.floor
                        ];
    
    return [NSString stringWithFormat:@"<Placemark><TimeStamp><when>%@</when></TimeStamp><name>Position</name><description>%@</description><styleUrl>#default</styleUrl><Point><coordinates>%.6f,%.6f,%.6f</coordinates></Point></Placemark>",
            [self.dateFormatterForKML stringFromDate:self.date],
            description,
            self.longitude,
            self.latitude,
            self.altitude
            ];
}

- (NSString *)kmlPathDescription
{
    return [NSString stringWithFormat:@"%.6f,%.6f,%.6f ",
            self.longitude,
            self.latitude,
            self.altitude
            ];
}


- (NSString *)kmlHeader
{
    return @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><kml xmlns=\"http://www.opengis.net/kml/2.2\" xmlns:gx=\"http://www.google.com/kml/ext/2.2\" xmlns:kml=\"http://www.opengis.net/kml/2.2\" xmlns:atom=\"http://www.w3.org/2005/Atom\"><Document>";
}

- (NSString *)kmlTimelineHeader
{
    
    NSString *dateString = [self.dateFormatter stringFromDate:self.session.date];
    NSString *timeString = [self.timeFormatter stringFromDate:self.session.date];
    NSString *durationString = [self stringFromTimeInterval:self.session.duration];
    NSString *description = [NSMutableString stringWithFormat:@"%@: %@ \n%@: %@ \n%@: %@ \n%@: %@ \n", NSLocalizedString(@"Datum", @"Datum"), dateString, NSLocalizedString(@"Beginn", @"Beginn"), timeString, NSLocalizedString(@"Dauer", @"Dauer"), durationString, NSLocalizedString(@"Person", @"Person"), [NSString stringWithFormat:@"%@ %@", self.session.user.firstName, self.session.user.lastName]];
    
    return [NSString stringWithFormat:@"<Style id=\"hl\"><IconStyle><scale>1.4</scale><Icon><href>http://maps.google.com/mapfiles/kml/shapes/donut.png</href></Icon></IconStyle><ListStyle></ListStyle></Style><StyleMap id=\"default\"><Pair><key>normal</key><styleUrl>#default0</styleUrl></Pair><Pair><key>highlight</key><styleUrl>#hl</styleUrl></Pair></StyleMap><Style id=\"default0\"><IconStyle><scale>1.2</scale><Icon><href>http://maps.google.com/mapfiles/kml/shapes/donut.png</href></Icon></IconStyle><ListStyle></ListStyle></Style><Folder><name>%@: %@</name><open>1</open><description>%@</description>", NSLocalizedString(@"Aktivität", @"Aktivität"), self.session.activity.name, description];
}

- (NSString *)kmlPathHeader
{
    return @"<Placemark><name>Path</name><Style><LineStyle><color>ffc4842c</color><width>2</width></LineStyle></Style><LineString><tessellate>1</tessellate><altitudeMode>absolute</altitudeMode><coordinates>";
}

- (NSString *)kmlPathFooter
{
    return @"</coordinates></LineString></Placemark>";
}

- (NSString *)kmlTimelineFooter
{
    return @"</Folder>";
}

- (NSString *)kmlFooter
{
    return @"</Document></kml>";
}

- (NSString *)csvDescription
{
    return [NSString stringWithFormat:@"%@,%f,%f,%f,%f,%f,%f,%f,%d\n",
            [self.dateFormatterForCSV stringFromDate:self.date],
            self.latitude,
            self.longitude,
            self.altitude,
            self.speed,
            self.course,
            self.horizontalAccuracy,
            self.verticalAccuracy,
            self.floor
            ];
}

- (NSString *)csvHeader
{
    return [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@\n",
                               NSLocalizedString(@"Datum", @"Datum"),
                               NSLocalizedString(@"Breitengrad", @"Breitengrad"),
                               NSLocalizedString(@"Längengrad", @"Längengrad"),
                               NSLocalizedString(@"Höhe (m)", @"Höhe (m)"),
                               NSLocalizedString(@"Geschwindigkeit (m/s)", @"Geschwindigkeit (m/s)"),
                               NSLocalizedString(@"Kurs (deg)", @"Kurs (deg)"),
                               NSLocalizedString(@"Horizontale Genauigkeit (m)", @"Horizontale Genauigkeit (m)"),
                               NSLocalizedString(@"Vertikale Genauigkeit (m)", @"Vertikale Genauigkeit (m)"),
                               NSLocalizedString(@"Stockwerk", @"Stockwerk")
                               ];
}


- (NSDateFormatter *)dateFormatterForKML
{
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
    }
    return dateFormatter;
}

- (NSDateFormatter *)dateFormatterForCSV
{
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    }
    return dateFormatter;
}

- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    return dateFormatter;
}

- (NSDateFormatter *)timeFormatter
{
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterNoStyle;
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    }
    return dateFormatter;
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval
{
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ldh %02ldm %02lds", (long)hours, (long)minutes, (long)seconds];
}

@end
