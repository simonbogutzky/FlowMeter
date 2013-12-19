//
//  Session.m
//  DataCollector
//
//  Created by Simon Bogutzky on 25.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "Session.h"
#import "LocationRecord.h"
#import "MotionRecord.h"
#import "User.h"

#import <zipzap/zipzap.h>

@interface Session () {

}

@end

@implementation Session

@dynamic filename;
@dynamic isSynced;
@dynamic timestamp;
@dynamic motionRecordsCount;
@dynamic locationRecordsCount;
@dynamic user;

@synthesize motionRecords = _motionRecords;
@synthesize locationRecords = _locationRecords;

- (void)initialize
{
    self.timestamp = [NSDate date];
    
    // Create a date string of the current date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormatter stringFromDate:self.timestamp];
    [dateFormatter setDateFormat:@"HH-mm-ss"];
    NSString *timeString = [dateFormatter stringFromDate:self.timestamp];
    self.filename = [NSString stringWithFormat:@"%@-t%@", dateString, timeString];
    
    _motionRecords = [NSMutableArray arrayWithCapacity:720000];
    _locationRecords = [NSMutableArray arrayWithCapacity:180000];
}

- (void)addDeviceRecord:(MotionRecord *)deviceRecord
{
    [_motionRecords addObject:deviceRecord];
}

- (void)addLocationRecord:(LocationRecord *)locationRecord
{
    [_locationRecords addObject:locationRecord];
}

- (void)saveAndZipMotionRecords
{
    if ([_motionRecords count] != 0) {
        
        self.motionRecordsCount = [NSNumber numberWithInt:[_motionRecords count]];
        
        // Create the path, where the data should be saved
        NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *filename = [NSString stringWithFormat:@"%@-motion-data.csv.zip", self.filename];
        NSString *localPath = [rootPath stringByAppendingPathComponent:filename];
        
        // Create data string
        NSMutableString *dataString = [[NSMutableString alloc] initWithCapacity:240000];
        
        [dataString appendFormat:@"\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\"\n",
         @"SensorTime",
         @"AccelX",
         @"AccelY",
         @"AccelZ",
         @"GyroX",
         @"GyroY",
         @"GyroZ",
         @"SystemTime",
         @"GaitEvent"
         ];
        
        for (MotionRecord *motionRecord in _motionRecords) {
            
            // Append to data string
            [dataString appendFormat:@"%f,%f,%f,%f,%f,%f,%f,%f\n",
             motionRecord.sensorTime,
             motionRecord.userAccelerationX + motionRecord.gravityX,
             motionRecord.userAccelerationY + motionRecord.gravityY,
             motionRecord.userAccelerationZ + motionRecord.gravityZ,
             motionRecord.rotationRateX,
             motionRecord.rotationRateY,
             motionRecord.rotationRateZ,
             motionRecord.timestamp
             ];
        }
        
        // Zip data
        ZZMutableArchive *archive = [ZZMutableArchive archiveWithContentsOfURL:[NSURL fileURLWithPath:localPath]];
        [archive updateEntries:
         @[
         [ZZArchiveEntry archiveEntryWithFileName:[NSString stringWithFormat:@"%@-motion-data.csv", self.filename]
                                         compress:YES
                                        dataBlock:^(NSError** error)
          {
              return [dataString dataUsingEncoding:NSUTF8StringEncoding];
          }]
         ]
                         error:nil];
        
        // Send notification
        NSDictionary *userInfo = @{@"localPath": localPath, @"filename": filename};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MotionDataAvailable" object:nil userInfo:userInfo];
    }
}

- (void)saveAndZipLocationRecords
{
    if ([_locationRecords count] != 0) {
        
        self.locationRecordsCount = [NSNumber numberWithInt:[_locationRecords count]];
        
        // Save *.csv
        // Create the path, where the data should be saved
        NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *filename = [NSString stringWithFormat:@"%@-l.csv.zip", self.filename];
        NSString *localPath = [rootPath stringByAppendingPathComponent:filename];
        
        // Create data string
        NSMutableString *dataString = [[NSMutableString alloc] initWithCapacity:240000];
        [dataString appendFormat:@"Name: %@ %@\n", self.user.firstName, self.user.lastName];
        [dataString appendFormat:@"\"%@\",\"%@\",\"%@\",\"%@\",\"%@\"\n",
         @"timestamp",
         @"latitude",
         @"longitude",
         @"altitude",
         @"speed"
         ];
        
        // Sort data
        NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
        NSArray *locationRecords = [self.locationRecords sortedArrayUsingDescriptors:@[timestampDescriptor]];
        
        for (LocationRecord *locationRecord in locationRecords) {
            
            // Append to data string
            [dataString appendFormat:@"%f,%f,%f,%f,%f\n",
             locationRecord.timestamp,
             locationRecord.latitude,
             locationRecord.longitude,
             locationRecord.altitude,
             locationRecord.speed
             ];
        }
        
        // Zip data
        ZZMutableArchive *archive = [ZZMutableArchive archiveWithContentsOfURL:[NSURL fileURLWithPath:localPath]];
        [archive updateEntries:
         @[
         [ZZArchiveEntry archiveEntryWithFileName:[NSString stringWithFormat:@"%@-l.csv", self.filename]
                                         compress:YES
                                        dataBlock:^(NSError** error)
          {
              return [dataString dataUsingEncoding:NSUTF8StringEncoding];
          }]
         ]
                         error:nil];
        
        // Send notification
        NSDictionary *userInfo = @{@"localPath": localPath, @"filename": filename};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationDataAvailable" object:nil userInfo:userInfo];
        
        // Save *.kml
        // Create the path, where the data should be saved
        filename = [NSString stringWithFormat:@"%@-l.kml.zip", self.filename];
        localPath = [rootPath stringByAppendingPathComponent:filename];
        
        // Create data string
        dataString = [[NSMutableString alloc] initWithCapacity:240000];
        [dataString appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><kml xmlns=\"http://www.opengis.net/kml/2.2\"><Document><name>Paths</name><description></description><Style id=\"yellowLineGreenPoly\"><LineStyle><color>7f00ffff</color><width>8</width></LineStyle><PolyStyle><color>7f00ff00</color></PolyStyle></Style><Placemark><name>Absolute Extruded</name><description>Transparent green wall with yellow outlines</description><styleUrl>#yellowLineGreenPoly</styleUrl><LineString><extrude>2</extrude><tessellate>1</tessellate><altitudeMode>absolute</altitudeMode><coordinates>"
         ];
        
        for (LocationRecord *locationRecord in locationRecords) {
            
            // Append to data string
            [dataString appendFormat:@"%f,%f,%f\n",
             locationRecord.longitude,
             locationRecord.latitude,
             locationRecord.altitude
             ];
        }
        
        [dataString appendString:@"</coordinates></LineString></Placemark></Document></kml>"
         ];
        
        // Zip data
        archive = [ZZMutableArchive archiveWithContentsOfURL:[NSURL fileURLWithPath:localPath]];
        [archive updateEntries:
         @[
         [ZZArchiveEntry archiveEntryWithFileName:[NSString stringWithFormat:@"%@-l.kml", self.filename]
                                         compress:YES
                                        dataBlock:^(NSError** error)
          {
              return [dataString dataUsingEncoding:NSUTF8StringEncoding];
          }]
         ]
                         error:nil];
        
        // Send notification
        userInfo = @{@"localPath": localPath, @"filename": filename};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationDataAvailable" object:nil userInfo:userInfo];
    }
}

@end
