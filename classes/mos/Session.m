//
//  Session.m
//  DataCollector
//
//  Created by Simon Bogutzky on 25.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "Session.h"
#import "HeartrateRecord.h"
#import "LocationRecord.h"
#import "MotionRecord.h"

#import <zipzap/zipzap.h>

@implementation Session

@dynamic filename;
@dynamic isSynced;
@dynamic timestamp;
@dynamic motionRecords;
@dynamic heatrateRecords;
@dynamic locationRecords;

- (void)saveAndZipMotionRecords
{
    if ([self.motionRecords count] != 0) {
        
        // Create the path, where the data should be saved
        NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *filename = [NSString stringWithFormat:@"%@-m.csv.zip", self.filename];
        NSString *localPath = [rootPath stringByAppendingPathComponent:filename];
        
        // Create data string
        NSMutableString *dataString = [[NSMutableString alloc] initWithCapacity:240000];
        [dataString appendFormat:@"\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\"\n",
         @"timestamp",
         @"userAccelerationX",
         @"userAccelerationY",
         @"userAccelerationZ",
         @"gravityX",
         @"gravityY",
         @"gravityZ",
         @"rotationRateX",
         @"rotationRateY",
         @"rotationRateZ",
         @"attitudePitch",
         @"attitudeRoll",
         @"attitudeYaw"
         ];
        
        // Sort data
        NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
        NSArray *motionRecords = [self.motionRecords sortedArrayUsingDescriptors:@[timestampDescriptor]];
        
        for (MotionRecord *motionRecord in motionRecords) {
            
            // Append to data string
            [dataString appendFormat:@"%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
             [motionRecord.timestamp doubleValue],
             [motionRecord.userAccelerationX doubleValue],
             [motionRecord.userAccelerationY doubleValue],
             [motionRecord.userAccelerationZ doubleValue],
             [motionRecord.gravityX doubleValue],
             [motionRecord.gravityY doubleValue],
             [motionRecord.gravityZ doubleValue],
             [motionRecord.rotationRateX doubleValue],
             [motionRecord.rotationRateY doubleValue],
             [motionRecord.rotationRateZ doubleValue],
             [motionRecord.attitudePitch doubleValue],
             [motionRecord.attitudeRoll doubleValue],
             [motionRecord.attitudeYaw doubleValue]
             ];
        }
        
        // Zip data
        ZZMutableArchive *archive = [ZZMutableArchive archiveWithContentsOfURL:[NSURL fileURLWithPath:localPath]];
        [archive updateEntries:
         @[
         [ZZArchiveEntry archiveEntryWithFileName:[NSString stringWithFormat:@"%@-m.csv", self.filename]
                                         compress:YES
                                        dataBlock:^(NSError** error)
          {
              return [dataString dataUsingEncoding:NSUTF8StringEncoding];
          }]
         ]
                         error:nil];
        
        // Send notification
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:@[localPath, filename] forKeys:@[@"localPath", @"filename"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MotionDataAvailable" object:self userInfo:userInfo];
    }
}

- (void)saveAndZipHeartrateRecords
{
    if ([self.heatrateRecords count] != 0) {
        
        // Create the path, where the data should be saved
        NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *filename = [NSString stringWithFormat:@"%@-hr.csv.zip", self.filename];
        NSString *localPath = [rootPath stringByAppendingPathComponent:filename];
        
        // Create data string
        NSMutableString *dataString = [[NSMutableString alloc] initWithCapacity:240000];
        [dataString appendFormat:@"\"%@\",\"%@\"\n",
         @"timestamp",
         @"accumBeatCount"
         ];
        
        // Sort data
        NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
        NSArray *heatrateRecords = [self.heatrateRecords sortedArrayUsingDescriptors:@[timestampDescriptor]];
        
        for (HeartrateRecord *heartrateRecord in heatrateRecords) {
            
            // Append to data string
            [dataString appendFormat:@"%f,%f\n",
             [heartrateRecord.timestamp doubleValue],
             [heartrateRecord.accumBeatCount doubleValue]
             ];
        }
        
        // Zip data
        ZZMutableArchive *archive = [ZZMutableArchive archiveWithContentsOfURL:[NSURL fileURLWithPath:localPath]];
        [archive updateEntries:
         @[
         [ZZArchiveEntry archiveEntryWithFileName:[NSString stringWithFormat:@"%@-hr.csv", self.filename]
                                         compress:YES
                                        dataBlock:^(NSError** error)
          {
              return [dataString dataUsingEncoding:NSUTF8StringEncoding];
          }]
         ]
                         error:nil];
        
        // Send notification
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:@[localPath, filename] forKeys:@[@"localPath", @"filename"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HeartrateDataAvailable" object:self userInfo:userInfo];
    }
}

- (void)saveAndZipLocationRecords
{
    if ([self.locationRecords count] != 0) {
        
        // Save *.csv
        // Create the path, where the data should be saved
        NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *filename = [NSString stringWithFormat:@"%@-l.csv.zip", self.filename];
        NSString *localPath = [rootPath stringByAppendingPathComponent:filename];
        
        // Create data string
        NSMutableString *dataString = [[NSMutableString alloc] initWithCapacity:240000];
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
             [locationRecord.timestamp doubleValue],
             [locationRecord.latitude doubleValue],
             [locationRecord.longitude doubleValue],
             [locationRecord.altitude doubleValue],
             [locationRecord.speed doubleValue]
             
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
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:@[localPath, filename] forKeys:@[@"localPath", @"filename"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationDataAvailable" object:self userInfo:userInfo];
        
        // Save *.kml
        // Create the path, where the data should be saved
        filename = [NSString stringWithFormat:@"%@-l.kml.zip", self.filename];
        localPath = [rootPath stringByAppendingPathComponent:filename];
        
        // Create data string
        dataString = [[NSMutableString alloc] initWithCapacity:240000];
        [dataString appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><kml xmlns=\"http://www.opengis.net/kml/2.2\"><Document><name>Paths</name><description></description><Style id=\"yellowLineGreenPoly\"><LineStyle><color>7f00ffff</color><width>4</width></LineStyle><PolyStyle><color>7f00ff00</color></PolyStyle></Style><Placemark><name>Absolute Extruded</name><description>Transparent green wall with yellow outlines</description><styleUrl>#yellowLineGreenPoly</styleUrl><LineString><extrude>1</extrude><tessellate>1</tessellate><altitudeMode>absolute</altitudeMode><coordinates>"
         ];
        
        for (LocationRecord *locationRecord in locationRecords) {
            
            // Append to data string
            [dataString appendFormat:@"%f,%f,%f\n",
             [locationRecord.longitude doubleValue],
             [locationRecord.latitude doubleValue],
             [locationRecord.altitude doubleValue]
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
        userInfo = [NSDictionary dictionaryWithObjects:@[localPath, filename] forKeys:@[@"localPath", @"filename"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationDataAvailable" object:self userInfo:userInfo];
    }
}

@end
