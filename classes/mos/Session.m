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
    NSMutableArray *_rotationRateXFiltered2Values;
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
@dynamic motionRecordsCount;
@dynamic locationRecordsCount;
@dynamic heartrateRecordsCount;
@dynamic user;

@synthesize motionRecords = _motionRecords;
@synthesize heartrateRecords = _heartrateRecords;
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
    
    _motionRecords = [NSMutableArray arrayWithCapacity:720000];
    _heartrateRecords = [NSMutableArray arrayWithCapacity:720000];
    _locationRecords = [NSMutableArray arrayWithCapacity:180000];
}

- (bool)isPeakInValues:(NSArray *)values withSlopes:(NSMutableArray*)slopes value:(double)value quantile:(double)quantile
{
    
    // Previous values
    double previousValue = [[values lastObject] doubleValue];
    double previousSlope = [[slopes lastObject] doubleValue];
    
    // Calculate
    double slope = value - previousValue;
    [slopes addObject:@(slope)];
    
    // Look for sign changes
    if (slope * previousSlope < 0 && quantile > previousValue) {
        
        // TODO: Hardcoded value
//        if (value > -3.0 && value < -1.0) {
            return YES;
//        }
    }
    return NO;
}

- (void)addDeviceRecord:(MotionRecord *)deviceRecord
{
    NSString *event = @"";
    double rotationRateX = deviceRecord.rotationRateX;
    
    // Apply filter
    double rotationRateXFiltered1 = [self filterX3000mHz:rotationRateX];
    double rotationRateXFiltered2 = [self filterX1500mHz:rotationRateX];
    
    // Wait fo five hundred values
    // TODO: Hardcoded value
    if ([_rotationRateXValues count] > 499) {
        if (_phase == 0) {
            NSLog(@"# Initialization");
            
            // Send notification
            NSDictionary *userInfo = @{@"event": @"IF"};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DetectGaitEvent" object:self userInfo:userInfo];
        }
        _phase = 1;
    }
    
    if (_phase != 0) {
        if ([_rotationRateXValues count] > 499) {
            if (_phase == 1) {
                NSLog(@"# Calibration");
                
                // Send notification
                NSDictionary *userInfo = @{@"event": @"CF"};
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DetectGaitEvent" object:self userInfo:userInfo];
            }
            _phase = 2;
            
            // Calculate quantiles
            // TODO: Hardcoded value
            _rotationRateXQuantile = [Utility quantileFromX:_rotationRateXValues prob:.06];
            _rotationRateXFiltered1Quantile = [Utility quantileFromX:_rotationRateXFiltered1Values prob:.09];
            _rotationRateXFiltered2Quantile = [Utility quantileFromX:_rotationRateXFiltered2Values prob:.12];
            
            // Remove the first hundred values
            [_rotationRateXValues removeObjectsInRange:NSMakeRange(0, 100)];
            [_rotationRateXFiltered1Values removeObjectsInRange:NSMakeRange(0, 100)];
            [_rotationRateXFiltered2Values removeObjectsInRange:NSMakeRange(0, 100)];
        }
        _phase = 1;
        
        if ([self isPeakInValues:_rotationRateXValues withSlopes:_rotationRateXSlopes value:rotationRateX quantile:_rotationRateXQuantile]) {
            _rotationRateXIndicator = YES;
            _rotationRateXFiltered1Indicator = NO;
            _rotationRateXFiltered2Indicator = NO;
            //            NSLog(@"Indicator 1");
        }
        
        if ([self isPeakInValues:_rotationRateXFiltered1Values withSlopes:_rotationRateXFiltered1Slopes value:rotationRateXFiltered1 quantile:_rotationRateXFiltered1Quantile] && _rotationRateXIndicator) {
            _rotationRateXIndicator = NO;
            _rotationRateXFiltered1Indicator = YES;
            _rotationRateXFiltered2Indicator = NO;
            //            NSLog(@"Indicator 2");
        }
        
        if ([self isPeakInValues:_rotationRateXFiltered2Values withSlopes:_rotationRateXFiltered2Slopes value:rotationRateXFiltered2 quantile:_rotationRateXFiltered2Quantile] &&_rotationRateXFiltered1Indicator) {
            _rotationRateXIndicator = NO;
            _rotationRateXFiltered1Indicator = NO;
            _rotationRateXFiltered2Indicator = YES;
            //            NSLog(@"Indicator 3");
        }
        
        if (_rotationRateXFiltered2Indicator) {
            event = @"TO";
            
            // Send notification
            NSDictionary *userInfo = @{@"event": event};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DetectGaitEvent" object:self userInfo:userInfo];
            
            _rotationRateXIndicator = NO;
            _rotationRateXFiltered1Indicator = NO;
            _rotationRateXFiltered2Indicator = NO;
        }
    }
    
    [_rotationRateXValues addObject:@(rotationRateX)];
    [_rotationRateXFiltered1Values addObject:@(rotationRateXFiltered1)];
    [_rotationRateXFiltered2Values addObject:@(rotationRateXFiltered2)];
    
    deviceRecord.event = event;
    
    // Save filtered values
    deviceRecord.rotationRateXFiltered1 = rotationRateXFiltered1;
    deviceRecord.rotationRateXFiltered2 = rotationRateXFiltered2;
    
    // Save quantile
    deviceRecord.rotationRateXQuantile = _rotationRateXQuantile;
    deviceRecord.rotationRateXFiltered1Quantile = _rotationRateXFiltered1Quantile;
    deviceRecord.rotationRateXFiltered2Quantile = _rotationRateXFiltered2Quantile;
    
    // Save slopes
    deviceRecord.rotationRateXSlope = [[_rotationRateXSlopes lastObject] doubleValue];
    deviceRecord.rotationRateXFiltered1Slope = [[_rotationRateXFiltered1Slopes lastObject] doubleValue];
    deviceRecord.rotationRateXFiltered2Slope = [[_rotationRateXFiltered2Slopes lastObject] doubleValue];
    
    // Save indicators
    deviceRecord.rotationRateXIndicator = _rotationRateXIndicator;
    deviceRecord.rotationRateXFiltered1Indicator = _rotationRateXFiltered1Indicator;
    deviceRecord.rotationRateXFiltered2Indicator = _rotationRateXFiltered2Indicator;
    
    [_motionRecords addObject:deviceRecord];
}

- (void)addHeartrateRecord:(HeartrateRecord *)heartrateRecord
{
    [_heartrateRecords addObject:heartrateRecord];
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
        
        for (MotionRecord *motionRecord in _motionRecords) {
            
            // Append to data string
            [dataString appendFormat:@"%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d,%d,%d,%f,%f,%f,%f,%f,%@\n",
             motionRecord.timestamp,
             motionRecord.userAccelerationX,
             motionRecord.userAccelerationY,
             motionRecord.userAccelerationZ,
             motionRecord.gravityX,
             motionRecord.gravityY,
             motionRecord.gravityZ,
             motionRecord.rotationRateX,
             motionRecord.rotationRateXFiltered1,
             motionRecord.rotationRateXFiltered2,
             motionRecord.rotationRateXQuantile,
             motionRecord.rotationRateXFiltered1Quantile,
             motionRecord.rotationRateXFiltered2Quantile,
             motionRecord.rotationRateXSlope,
             motionRecord.rotationRateXFiltered1Slope,
             motionRecord.rotationRateXFiltered2Slope,
             motionRecord.rotationRateXIndicator,
             motionRecord.rotationRateXFiltered1Indicator,
             motionRecord.rotationRateXFiltered2Indicator,
             motionRecord.rotationRateY,
             motionRecord.rotationRateZ,
             motionRecord.attitudePitch,
             motionRecord.attitudeRoll,
             motionRecord.attitudeYaw,
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
        NSDictionary *userInfo = @{@"localPath": localPath, @"filename": filename};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MotionDataAvailable" object:nil userInfo:userInfo];
    }
}

- (void)saveAndZipHeartrateRecords
{
    if ([_heartrateRecords count] != 0) {
        
        self.heartrateRecordsCount = [NSNumber numberWithInt:[_heartrateRecords count]];
        
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
        
        for (HeartrateRecord *heartrateRecord in _heartrateRecords) {
            
            // Append to data string
            [dataString appendFormat:@"%f,%i,%@,%@\n",
             heartrateRecord.timestamp,
             heartrateRecord.accumBeatCount,
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
        NSDictionary *userInfo = @{@"localPath": localPath, @"filename": filename};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HeartrateDataAvailable" object:nil userInfo:userInfo];
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

// Lowpass Butterworth 2. Order Filter with 1.5Hz corner frequency ("http://www-users.cs.york.ac.uk/~fisher/mkfilter/trad.html")

#define GAIN1500   1.203373697e+02

static float xv1500[NZEROS+1], yv1500[NPOLES+1];

- (double)filterX1500mHz:(double)x
{
    xv1500[0] = x / GAIN1500;
    yv1500[0] = yv1500[1];
    yv1500[1] = yv1500[2];
    yv1500[2] = xv1500[0] + (-0.8752143177 * yv1500[0]) + (1.8669043471 * yv1500[1]);
    return yv1500[2];
}

// Lowpass Butterworth 2. Order Filter with 3Hz corner frequency ("http://www-users.cs.york.ac.uk/~fisher/mkfilter/trad.html")

#define GAIN3000   3.215755043e+01

static float xv3000[NZEROS+1], yv3000[NPOLES+1];

- (double)filterX3000mHz:(double)x
{
    xv3000[0] = x / GAIN3000;
    yv3000[0] = yv3000[1];
    yv3000[1] = yv3000[2];
    yv3000[2] = xv3000[0] + (-0.7660001018 * yv3000[0]) + (1.7349032059 * yv3000[1]);
    return yv3000[2];
}


@end
