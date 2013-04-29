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
#import "Utility.h"

#import <zipzap/zipzap.h>

@interface Session () {
    BOOL _indicator1;
    BOOL _indicator2;
    BOOL _indicator3;
}

@end

@implementation Session

@dynamic filename;
@dynamic isSynced;
@dynamic timestamp;
@dynamic motionRecords;
@dynamic heatrateRecords;
@dynamic locationRecords;

- (bool)isPeakInRecords:(NSArray *)records withKey:(NSString *)key record:(MotionRecord *)record
{
    
    // Previous record
    MotionRecord *previousRecord = [records lastObject];
    double previousValue = [[previousRecord valueForKey:key] doubleValue];
    double previousSlope = [[previousRecord valueForKey:[NSString stringWithFormat:@"%@Slope", key]] doubleValue];
    double slope = [[record valueForKey:key] doubleValue] - previousValue;
    
    // Store slope
    [record setValue:[NSNumber numberWithDouble:slope] forKey:[NSString stringWithFormat:@"%@Slope", key]];
    
    // Look for sign changes
    if (slope * previousSlope < 0 && [[record valueForKey:[NSString stringWithFormat:@"%@Quantile", key]] doubleValue] < previousValue) {
//        [storage setObject:[NSNumber numberWithBool:YES] forKey:[NSString stringWithFormat:@"%@Indicator", key]];
        return YES;
    }
    return NO;
}

- (void)addMotionRecordsObject:(MotionRecord *)value
{    
    NSString *label = @"";
    
    double rotationRateXfiltered1 = [self filterX5000mHz:[value.rotationRateX doubleValue]];
    value.rotationRateXFiltered1 = [NSNumber numberWithDouble:rotationRateXfiltered1];
    
    double rotationRateXfiltered2 = [self filterX2500mHz:[value.rotationRateX doubleValue]];
    value.rotationRateXFiltered2 = [NSNumber numberWithDouble:rotationRateXfiltered2];
    
    if ([self.motionRecords count] > 499) {
            
        // Subset data
        NSMutableArray *rotationRateX = [NSMutableArray arrayWithCapacity:500];
        NSMutableArray *rotationRateXFiltered1 = [NSMutableArray arrayWithCapacity:500];
        NSMutableArray *rotationRateXFiltered2 = [NSMutableArray arrayWithCapacity:500];
        NSArray *motionRecordSubset = [[[self.motionRecords allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]]] objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([self.motionRecords count] - 500, 500)]];
        for (MotionRecord *motionRecord in motionRecordSubset) {
            [rotationRateX addObject:motionRecord.rotationRateX];
            [rotationRateXFiltered1 addObject:motionRecord.rotationRateXFiltered1];
            [rotationRateXFiltered2 addObject:motionRecord.rotationRateXFiltered2];
        }
        
        // Calculate quantiles
        double rotationRateXQuantile = [Utility quantileFromX:rotationRateX prob:.98];
        double rotationRateXFiltered1Quantile = [Utility quantileFromX:rotationRateXFiltered1 prob:.94];
        double rotationRateXFiltered2Quantile = [Utility quantileFromX:rotationRateXFiltered2 prob:.92];
        value.rotationRateXQuantile = [NSNumber numberWithDouble:rotationRateXQuantile];
        value.rotationRateXFiltered1Quantile = [NSNumber numberWithDouble:rotationRateXFiltered1Quantile];
        value.rotationRateXFiltered2Quantile = [NSNumber numberWithDouble:rotationRateXFiltered2Quantile];
        
        _indicator1 = [self isPeakInRecords:motionRecordSubset withKey:@"rotationRateX" record:value];
        
        if (_indicator1) {
            _indicator2 = [self isPeakInRecords:motionRecordSubset withKey:@"rotationRateXFiltered1" record:value];
            _indicator1 = NO;
        }
        
        if (_indicator2) {
            _indicator3 = [self isPeakInRecords:motionRecordSubset withKey:@"rotationRateXFiltered2" record:value];
            _indicator2 = NO;
        }
        
        if ( _indicator3) {
            _indicator3 = NO;
            label = @"HS";
        }
    }
    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"motionRecords"
                withSetMutation:NSKeyValueUnionSetMutation
                   usingObjects:changedObjects];
    [[self primitiveValueForKey:@"motionRecords"] addObject:value];
    [self didChangeValueForKey:@"motionRecords"
               withSetMutation:NSKeyValueUnionSetMutation
                  usingObjects:changedObjects];
}

- (void)saveAndZipMotionRecords
{
    if ([self.motionRecords count] != 0) {
        
        // Create the path, where the data should be saved
        NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *filename = [NSString stringWithFormat:@"%@-m.csv.zip", self.filename];
        NSString *localPath = [rootPath stringByAppendingPathComponent:filename];
        
        // Create data string
        NSMutableString *dataString = [[NSMutableString alloc] initWithCapacity:240000];
        [dataString appendFormat:@"\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\"\n",
         @"timestamp",
         @"userAccelerationX",
         @"userAccelerationY",
         @"userAccelerationZ",
         @"gravityX",
         @"gravityY",
         @"gravityZ",
         @"rotationRateX",
         @"rotationRateXFiltered1",
         @"rotationRateXFiltered2",
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
            [dataString appendFormat:@"%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
             [motionRecord.timestamp doubleValue],
             [motionRecord.userAccelerationX doubleValue],
             [motionRecord.userAccelerationY doubleValue],
             [motionRecord.userAccelerationZ doubleValue],
             [motionRecord.gravityX doubleValue],
             [motionRecord.gravityY doubleValue],
             [motionRecord.gravityZ doubleValue],
             [motionRecord.rotationRateX doubleValue],
             [motionRecord.rotationRateXFiltered1 doubleValue],
             [motionRecord.rotationRateXFiltered2 doubleValue],
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

#pragma mark -
#pragma mark - Filter

// Lowpass Butterworth 2. Order Filter with 5Hz corner frequency ("http://www-users.cs.york.ac.uk/~fisher/mkfilter/trad.html")

#define NZEROS 0
#define NPOLES 2
#define GAIN5000   1.265241109e+01

static float xv5000[NZEROS+1], yv5000[NPOLES+1];

- (double)filterX5000mHz:(double)x
{
    xv5000[0] = x / GAIN5000;
    yv5000[0] = yv5000[1];
    yv5000[1] = yv5000[2];
    yv5000[2] = xv5000[0] + (-0.6412805170 * yv5000[0]) + (1.5622441979 * yv5000[1]);
    return yv5000[2];
}

// Lowpass Butterworth 2. Order Filter with 7.5Hz corner frequency ("http://www-users.cs.york.ac.uk/~fisher/mkfilter/trad.html")

#define GAIN7500   6.283720074e+00

static float xv7500[NZEROS+1], yv7500[NPOLES+1];

- (double)filterX7500mHz:(double)x
{
    xv7500[0] = x / GAIN7500;
    yv7500[0] = yv7500[1];
    yv7500[1] = yv7500[2];
    yv7500[2] = xv7500[0] + (-0.5135373887 * yv7500[0]) + (1.3543959903 * yv7500[1]);
    return yv7500[2];
}

// Lowpass Butterworth 2. Order Filter with 2.5Hz corner frequency ("http://www-users.cs.york.ac.uk/~fisher/mkfilter/trad.html")

#define GAIN2500   4.528955473e+01

static float xv2500[NZEROS+1], yv2500[NPOLES+1];

- (double)filterX2500mHz:(double)x
{
    xv2500[0] = x / GAIN2500;
    yv2500[0] = yv2500[1];
    yv2500[1] = yv2500[2];
    yv2500[2] = xv2500[0] + (-0.8007999232 * yv2500[0]) + (1.7787197768 * yv2500[1]);
    return yv2500[2];
}


@end
