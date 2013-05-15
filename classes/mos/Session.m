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
#import "User.h"

#import <zipzap/zipzap.h>

@interface Session () {
    NSMutableArray *_rotationRateXValues;
    NSMutableArray *_rotationRateXFiltered1Values;
    NSMutableArray *_rotationRateXFiltered2Values;;
    double _rotationRateXQuantile;
    double _rotationRateXFiltered1Quantile;
    double _rotationRateXFiltered2Quantile;
    NSMutableArray *_rotationRateXSlopes;
    NSMutableArray *_rotationRateXFiltered1Slopes;
    NSMutableArray *_rotationRateXFiltered2Slopes;
    BOOL _rotationRateXIndicator;
    BOOL _rotationRateXFiltered1Indicator;
    BOOL _rotationRateXFiltered2Indicator;
    int _phase;
}

@end

@implementation Session

@dynamic filename;
@dynamic isSynced;
@dynamic timestamp;
@dynamic motionRecords;
@dynamic heatrateRecords;
@dynamic locationRecords;
@dynamic user;

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
    
    _rotationRateXValues = [NSMutableArray arrayWithCapacity:500];
    _rotationRateXFiltered1Values = [NSMutableArray arrayWithCapacity:500];
    _rotationRateXFiltered2Values = [NSMutableArray arrayWithCapacity:500];
    _rotationRateXQuantile = 0;
    _rotationRateXFiltered1Quantile = 0;
    _rotationRateXFiltered2Quantile = 0;
    _rotationRateXSlopes = [NSMutableArray arrayWithCapacity:500];
    _rotationRateXFiltered1Slopes = [NSMutableArray arrayWithCapacity:500];
    _rotationRateXFiltered2Slopes = [NSMutableArray arrayWithCapacity:500];
    _rotationRateXIndicator = NO;
    _rotationRateXFiltered1Indicator = NO;
    _rotationRateXFiltered2Indicator = NO;
    _phase = 0;
}

- (bool)isPeakInValues:(NSArray *)values withSlopes:(NSMutableArray*)slopes value:(double)value quantile:(double)quantile
{
    
    // Previous values
    double previousValue = [[values lastObject] doubleValue];
    double previousSlope = [[slopes lastObject] doubleValue];
    
    // Calculate
    double slope = value - previousValue;
    [slopes addObject:[NSNumber numberWithDouble:slope]];
    
    // Look for sign changes
    if (slope * previousSlope < 0 && quantile < previousValue) {
        
        // TODO: Hardcoded value
        if (value > 1.0) {
            return YES;
        }
    }
    return NO;
}

- (void)addMotionRecordsObject:(MotionRecord *)value
{    
    value.event = @"";
    
    double rotationRateX = [value.rotationRateX doubleValue];
    
    // Apply filter
    double rotationRateXFiltered1 = [self filterX5000mHz:rotationRateX];
    double rotationRateXFiltered2 = [self filterX2500mHz:rotationRateX];
    
    // Wait fo five hundred values
    // TODO: Hardcoded value
    if ([_rotationRateXValues count] > 499) {
        if (_phase == 0) {
            NSLog(@"# Initialization");
            
            // Send notification
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:@[@"IF"] forKeys:@[@"event"]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DetectGaitEvent" object:self userInfo:userInfo];
        }
        _phase = 1;
    }
    
    if (_phase != 0) {
        if ([_rotationRateXValues count] > 499) {
            if (_phase == 1) {
                NSLog(@"# Calibration");
                
                // Send notification
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:@[@"CF"] forKeys:@[@"event"]];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DetectGaitEvent" object:self userInfo:userInfo];
            }
            _phase = 2;
            
            // Calculate quantiles
            // TODO: Hardcoded value
            _rotationRateXQuantile = [Utility quantileFromX:_rotationRateXValues prob:.94];
            _rotationRateXFiltered1Quantile = [Utility quantileFromX:_rotationRateXFiltered1Values prob:.93];
            _rotationRateXFiltered2Quantile = [Utility quantileFromX:_rotationRateXFiltered2Values prob:.92];
            
            // Remove the first hundred values
            [_rotationRateXValues removeObjectsInRange:NSMakeRange(0, 100)];
            [_rotationRateXFiltered1Values removeObjectsInRange:NSMakeRange(0, 100)];
            [_rotationRateXFiltered2Values removeObjectsInRange:NSMakeRange(0, 100)];
            
            // Remove the first hundred slopes
//            [_rotationRateXSlopes removeObjectsInRange:NSMakeRange(0, 100)];
//            [_rotationRateXFiltered1Slopes removeObjectsInRange:NSMakeRange(0, 100)];
//            [_rotationRateXFiltered2Slopes removeObjectsInRange:NSMakeRange(0, 100)];
        }
        _phase = 1;
        
        if ([self isPeakInValues:_rotationRateXValues withSlopes:_rotationRateXSlopes value:rotationRateX quantile:_rotationRateXQuantile]) {
            _rotationRateXIndicator = YES;
            _rotationRateXFiltered1Indicator = NO;
            _rotationRateXFiltered2Indicator = NO;
//            NSLog(@"Indicator 1");
        }
        
        if (_rotationRateXIndicator && [self isPeakInValues:_rotationRateXFiltered1Values withSlopes:_rotationRateXFiltered1Slopes value:rotationRateXFiltered1 quantile:_rotationRateXFiltered1Quantile] ) {
            _rotationRateXIndicator = NO;
            _rotationRateXFiltered1Indicator = YES;
            _rotationRateXFiltered2Indicator = NO;
//            NSLog(@"Indicator 2");
        }
        
        if (_rotationRateXFiltered1Indicator && [self isPeakInValues:_rotationRateXFiltered2Values withSlopes:_rotationRateXFiltered2Slopes value:rotationRateXFiltered2 quantile:_rotationRateXFiltered2Quantile] ) {
            _rotationRateXIndicator = NO;
            _rotationRateXFiltered1Indicator = NO;
            _rotationRateXFiltered2Indicator = YES;
//            NSLog(@"Indicator 3");
        }
        
        if (_rotationRateXFiltered2Indicator) {
            value.event = @"HS";
            
            // Send notification
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:@[value.event] forKeys:@[@"event"]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DetectGaitEvent" object:self userInfo:userInfo];
            
            _rotationRateXIndicator = NO;
            _rotationRateXFiltered1Indicator = NO;
            _rotationRateXFiltered2Indicator = NO;
        }
    }
    
    [_rotationRateXValues addObject:[NSNumber numberWithDouble:rotationRateX]];
    [_rotationRateXFiltered1Values addObject:[NSNumber numberWithDouble:rotationRateXFiltered1]];
    [_rotationRateXFiltered2Values addObject:[NSNumber numberWithDouble:rotationRateXFiltered2]];
    
    // Save filtered values
    value.rotationRateXFiltered1 = [NSNumber numberWithDouble:rotationRateXFiltered1];
    value.rotationRateXFiltered2 = [NSNumber numberWithDouble:rotationRateXFiltered2];
    
    // Save quantile
    value.rotationRateXQuantile = [NSNumber numberWithDouble:_rotationRateXQuantile];
    value.rotationRateXFiltered1Quantile = [NSNumber numberWithDouble:_rotationRateXFiltered1Quantile];
    value.rotationRateXFiltered2Quantile = [NSNumber numberWithDouble:_rotationRateXFiltered2Quantile];
    
    // Save slopes
    value.rotationRateXSlope = [_rotationRateXSlopes lastObject];
    value.rotationRateXFiltered1Slope = [_rotationRateXFiltered1Slopes lastObject];
    value.rotationRateXFiltered2Slope = [_rotationRateXFiltered2Slopes lastObject];
    
    // Save indicators
    value.rotationRateXIndicator = [NSNumber numberWithBool:_rotationRateXIndicator];
    value.rotationRateXFiltered1Indicator = [NSNumber numberWithBool:_rotationRateXFiltered1Indicator];
    value.rotationRateXFiltered2Indicator = [NSNumber numberWithBool:_rotationRateXFiltered2Indicator];
    
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
        [dataString appendFormat:@"Name: %@ %@\n", self.user.firstName, self.user.lastName];
        
        [dataString appendFormat:@"\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\"\n",
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
         @"rotationRateXQuantile",
         @"rotationRateXFiltered1Quantile",
         @"rotationRateXFiltered2Quantile",
         @"rotationRateXSlope",
         @"rotationRateXFiltered1Slope",
         @"rotationRateXFiltered2Slope",
         @"rotationRateXIndicator",
         @"rotationRateXFiltered1Indicator",
         @"rotationRateXFiltered2Indicator",
         @"rotationRateY",
         @"rotationRateZ",
         @"attitudePitch",
         @"attitudeRoll",
         @"attitudeYaw",
         @"event"
         ];
        
        // Sort data
        NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
        NSArray *motionRecords = [self.motionRecords sortedArrayUsingDescriptors:@[timestampDescriptor]];
        
        for (MotionRecord *motionRecord in motionRecords) {
            
            // Append to data string
            [dataString appendFormat:@"%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d,%d,%d,%f,%f,%f,%f,%f,%@\n",
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
             [motionRecord.rotationRateXQuantile doubleValue],
             [motionRecord.rotationRateXFiltered1Quantile doubleValue],
             [motionRecord.rotationRateXFiltered2Quantile doubleValue],
             [motionRecord.rotationRateXSlope doubleValue],
             [motionRecord.rotationRateXFiltered1Slope doubleValue],
             [motionRecord.rotationRateXFiltered2Slope doubleValue],
             [motionRecord.rotationRateXIndicator intValue],
             [motionRecord.rotationRateXFiltered1Indicator intValue],
             [motionRecord.rotationRateXFiltered2Indicator intValue],
             [motionRecord.rotationRateY doubleValue],
             [motionRecord.rotationRateZ doubleValue],
             [motionRecord.attitudePitch doubleValue],
             [motionRecord.attitudeRoll doubleValue],
             [motionRecord.attitudeYaw doubleValue],
             motionRecord.event
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
        [dataString appendFormat:@"Name: %@ %@\n", self.user.firstName, self.user.lastName];
        [dataString appendFormat:@"\"%@\",\"%@\",\"%@\",\"%@\"\n",
         @"timestamp",
         @"accumBeatCount",
         @"heartrate",
         @"rrIntervals"
         ];
        
        // Sort data
        NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
        NSArray *heatrateRecords = [self.heatrateRecords sortedArrayUsingDescriptors:@[timestampDescriptor]];
        
        for (HeartrateRecord *heartrateRecord in heatrateRecords) {
            
            // Append to data string
            [dataString appendFormat:@"%f,%f,%@,%@\n",
             [heartrateRecord.timestamp doubleValue],
             [heartrateRecord.accumBeatCount doubleValue],
             heartrateRecord.heartrate,
             heartrateRecord.rrIntervals != nil ? heartrateRecord.rrIntervals : @""
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
