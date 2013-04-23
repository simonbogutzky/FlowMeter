//
//  UserSessionVO.m
//  Client
//
//  Created by Simon Bogutzky on 05.04.12.
//  Copyright 2012 Simon Bogutzky. All rights reserved.
//

#import "UserSessionVO.h"
#import "Utility.h"

@interface UserSessionVO ()
{
    NSMutableDictionary *_measurements;
    NSMutableDictionary *_storage;
    int _recordCount;
    bool _hasEnoughRecords;
}
@end

@implementation UserSessionVO

- (id)init
{
	self = [super init];
	if (self != nil) {
        
        _storage = [[NSMutableDictionary alloc] init];
        _measurements = [[NSMutableDictionary alloc] init];
	}
	return self;
}

#pragma mark -
#pragma mark - Motion methods

- (void)createMotionStorage
{
    [self renewMotionMeasurementStorage];
    
    // Create a date string of the current date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    [dateFormatter setDateFormat:@"HH-mm-ss"];
    NSString *timeString = [dateFormatter stringFromDate:[NSDate date]];
    
    [_storage setObject:dateString forKey:@"mDateString"];
    [_storage setObject:timeString forKey:@"mTimeString"];
    [_storage setObject:@1 forKey:@"mFileCount"];
    
    [_storage setObject:@0 forKey:@"mRotationRateXQuantile"];
    [_storage setObject:@0 forKey:@"mFilteredRotationRateXQuantile"];
    [_storage setObject:@0 forKey:@"mFilteredRotationRateX1Quantile"];
    
    [_storage setObject:[NSNumber numberWithBool:NO] forKey:@"mRotationRateXIndicator"];
    [_storage setObject:[NSNumber numberWithBool:NO] forKey:@"mFilteredRotationRateXIndicator"];
    [_storage setObject:[NSNumber numberWithBool:NO] forKey:@"mFilteredRotationRateX1Indicator"];
    
    [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:500] forKey:@"mRotationRateX"];
    [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:500] forKey:@"mFilteredRotationRateX"];
    [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:500] forKey:@"mFilteredRotationRateX1"];
    
    _recordCount = 0;
    _hasEnoughRecords = NO;
    
}

- (void)renewMotionMeasurementStorage
{
    [_storage setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"mTimestamp"];
    [_storage setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"mRotationRateX"];
    [_storage setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"mFilteredRotationRateX"];
    [_storage setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"mFilteredRotationRateX1"];
    [_storage setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"mRotationRateXQuantiles"];
    [_storage setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"mFilteredRotationRateXQuantiles"];
    [_storage setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"mFilteredRotationRateX1Quantiles"];
    [_storage setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"mLabel"];
}

- (bool)isPeakFromStorage:(NSMutableDictionary *)storage withKey:(NSString *)key x:(double)x quantile:(double)quantile
{
    // First measurement
    if ([storage objectForKey:[NSString stringWithFormat:@"%@PreviousMeasurement", key]] == nil) {
        [storage setObject:[NSNumber numberWithDouble:x] forKey:[NSString stringWithFormat:@"%@PreviousMeasurement", key]];
        return NO;
    }
    
    // Previous measurement
    double previousMeasurement = [[storage objectForKey:[NSString stringWithFormat:@"%@PreviousMeasurement", key]] doubleValue];
    double previousSlope = [[storage objectForKey:[NSString stringWithFormat:@"%@PreviousSlope", key]] doubleValue];
    double slope = x - previousMeasurement;
    
    // Store current measurement
    [storage setObject:[NSNumber numberWithDouble:slope] forKey:[NSString stringWithFormat:@"%@PreviousSlope", key]];
    [storage setObject:[NSNumber numberWithDouble:x] forKey:[NSString stringWithFormat:@"%@PreviousMeasurement", key]];
    
    // Look for sign changes
    if (slope * previousSlope < 0 && quantile < previousMeasurement) {
        [storage setObject:[NSNumber numberWithBool:YES] forKey:[NSString stringWithFormat:@"%@Indicator", key]];
        return YES;
    }
    return NO;
}

- (NSString *)appendMotionData:(CMDeviceMotion *)deviceMotion
{
    
    NSString *label = @"";
    if (deviceMotion == nil)
        return @"";
    
    // Store device motion for storage and analysis
    double timestamp = deviceMotion.timestamp;
    [[_storage objectForKey:@"mTimestamp"] addObject:[NSNumber numberWithDouble:timestamp]];
    
    double rotationRateX = deviceMotion.rotationRate.x;
    [[_measurements objectForKey:@"mRotationRateX"] addObject:[NSNumber numberWithDouble:rotationRateX]];
    [[_storage objectForKey:@"mRotationRateX"] addObject:[NSNumber numberWithDouble:rotationRateX]];
    
    double filteredRotationRateX = [self filterX5000mHz:rotationRateX];
    [[_measurements objectForKey:@"mFilteredRotationRateX"] addObject:[NSNumber numberWithDouble:filteredRotationRateX]];
    [[_storage objectForKey:@"mFilteredRotationRateX"] addObject:[NSNumber numberWithDouble:filteredRotationRateX]];
    
    double filteredRotationRateX1 = [self filterX2500mHz:rotationRateX];
    [[_measurements objectForKey:@"mFilteredRotationRateX1"] addObject:[NSNumber numberWithDouble:filteredRotationRateX1]];
    [[_storage objectForKey:@"mFilteredRotationRateX1"] addObject:[NSNumber numberWithDouble:filteredRotationRateX1]];
    
    // Save Quantiles
    [[_storage objectForKey:@"mRotationRateXQuantiles"] addObject:[_storage objectForKey:@"mRotationRateXQuantile"]];
    [[_storage objectForKey:@"mFilteredRotationRateXQuantiles"] addObject:[_storage objectForKey:@"mFilteredRotationRateXQuantile"]];
    [[_storage objectForKey:@"mFilteredRotationRateX1Quantiles"] addObject:[_storage objectForKey:@"mFilteredRotationRateX1Quantile"]];
    
    _recordCount++;
    if (_recordCount > 499 && _hasEnoughRecords == NO)
        _hasEnoughRecords = YES;
    
    if (_hasEnoughRecords) {
    
        // Re-calibration
        if ([[_measurements objectForKey:@"mRotationRateX"] count] > 499) {
            double rotationRateXQuantile = [Utility quantileFromX:[_measurements objectForKey:@"mRotationRateX"] prob:.98];
            double filteredRotationRateXQuantile = [Utility quantileFromX:[_measurements objectForKey:@"mFilteredRotationRateX"] prob:.94];
            double filteredRotationRateX1Quantile = [Utility quantileFromX:[_measurements objectForKey:@"mFilteredRotationRateX1"] prob:.92];
            [_storage setObject:[NSNumber numberWithDouble:rotationRateXQuantile] forKey:@"mRotationRateXQuantile"];
            [_storage setObject:[NSNumber numberWithDouble:filteredRotationRateXQuantile] forKey:@"mFilteredRotationRateXQuantile"];
            [_storage setObject:[NSNumber numberWithDouble:filteredRotationRateX1Quantile] forKey:@"mFilteredRotationRateX1Quantile"];
            [[_measurements objectForKey:@"mRotationRateX"] removeObjectsInRange:NSMakeRange(0, 100)];
            [[_measurements objectForKey:@"mFilteredRotationRateX"] removeObjectsInRange:NSMakeRange(0, 100)];
            [[_measurements objectForKey:@"mFilteredRotationRateX1"] removeObjectsInRange:NSMakeRange(0, 100)];
        }
        
        // Find peaks and set indicators
        [self isPeakFromStorage:_storage withKey:@"mRotationRateX" x:rotationRateX quantile:[[_storage objectForKey:@"mRotationRateXQuantile"] doubleValue]];
        
        [self isPeakFromStorage:_storage withKey:@"mFilteredRotationRateX" x:filteredRotationRateX quantile:[[_storage objectForKey:@"mFilteredRotationRateXQuantile"] doubleValue]];
        
        if ([[_storage objectForKey:@"mRotationRateXIndicator"] boolValue] && [[_storage objectForKey:@"mFilteredRotationRateXIndicator"] boolValue]) {
            [_storage setObject:[NSNumber numberWithBool:NO] forKey:@"mRotationRateXIndicator"];
        }
        
        [self isPeakFromStorage:_storage withKey:@"mFilteredRotationRateX1" x:filteredRotationRateX1 quantile:[[_storage objectForKey:@"mFilteredRotationRateX1Quantile"] doubleValue]];
        
        if ([[_storage objectForKey:@"mFilteredRotationRateXIndicator"] boolValue] && [[_storage objectForKey:@"mFilteredRotationRateX1Indicator"] boolValue]) {
            [_storage setObject:[NSNumber numberWithBool:NO] forKey:@"mFilteredRotationRateXIndicator"];
            [_storage setObject:[NSNumber numberWithBool:NO] forKey:@"mFilteredRotationRateX1Indicator"];
            label = @"HS";
        }
    }
    [[_storage objectForKey:@"mLabel"] addObject:label];
    
    // Save, if needed
    if([[_storage objectForKey:@"mTimestamp"] count] != 0 && [[_storage objectForKey:@"mTimestamp"] count] % 6000 == 0) {
        [self seriliazeAndZipMotionData];
        [self renewMotionMeasurementStorage];
    }
    
    return label;
}

- (NSData *)seriliazeAndZipMotionData
{
    NSString *savePath = nil;
    if ([[_storage objectForKey:@"mTimestamp"] count] != 0) {
        NSString *dateString = [_storage objectForKey:@"mDateString"];
        NSString *timeString = [_storage objectForKey:@"mTimeString"];
        NSNumber *fileCount = [_storage objectForKey:@"mFileCount"];
        
        // Create the path, where the data should be saved
        NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *pathComponent = [NSString stringWithFormat:@"%@-t%@-m%03d.csv.zip", dateString, timeString, [fileCount intValue]];
        NSString *savePath = [rootPath stringByAppendingPathComponent:pathComponent];
        
        // Create data string
        NSMutableString *dataString = [[NSMutableString alloc] initWithCapacity:240000];
        [dataString appendFormat:@"\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\"\n",
         @"timestamp",
         @"rotationRateX",
         @"filteredRotationRateX",
         @"filteredRotationRateX1",
         @"rotationRateXQuantiles",
         @"filteredRotationRateXQuantiles",
         @"filteredRotationRateX1Quantiles",
         @"label"
         ];
        
        // Get first timestamp
        NSNumber *timestamp = [[_storage objectForKey:@"mTimestamp"] objectAtIndex:0];
        
        for (int i = 0; i < [[_storage objectForKey:@"mTimestamp"] count]; i++) {
            
            // Append to data string
            [dataString appendFormat:@"%f,%f,%f,%f,%f,%f,%f,%@\n",
             [[[_storage objectForKey:@"mTimestamp"] objectAtIndex:i] doubleValue] - [timestamp doubleValue],
             [[[_storage objectForKey:@"mRotationRateX"] objectAtIndex:i] doubleValue],
             [[[_storage objectForKey:@"mFilteredRotationRateX"] objectAtIndex:i] doubleValue],
             [[[_storage objectForKey:@"mFilteredRotationRateX1"] objectAtIndex:i] doubleValue],
             [[[_storage objectForKey:@"mRotationRateXQuantiles"] objectAtIndex:i] doubleValue],
             [[[_storage objectForKey:@"mFilteredRotationRateXQuantiles"] objectAtIndex:i] doubleValue],
             [[[_storage objectForKey:@"mFilteredRotationRateX1Quantiles"] objectAtIndex:i] doubleValue],
             [[_storage objectForKey:@"mLabel"] objectAtIndex:i]
             ];
        }
        
        ZZMutableArchive *archive = [ZZMutableArchive archiveWithContentsOfURL:[NSURL fileURLWithPath:savePath]];
        [archive updateEntries:
         @[
         [ZZArchiveEntry archiveEntryWithFileName:[NSString stringWithFormat:@"%@-t%@-m%03d.csv", dateString, timeString, [fileCount intValue]]
                                         compress:YES
                                        dataBlock:^(NSError** error)
          {
              return [dataString dataUsingEncoding:NSUTF8StringEncoding];
          }]
         ]
                         error:nil];
        
        [_storage setObject:[NSNumber numberWithInt:[fileCount intValue] + 1] forKey:@"mFileCount"];
        
        // Send notification
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:@[savePath, pathComponent] forKeys:@[@"localPath", @"fileName" ]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MotionDataReady" object:self userInfo:userInfo];
    }
    
    // Compressed data
    return [[NSFileManager defaultManager] contentsAtPath:savePath];
}

#pragma mark -
#pragma mark - Filter

//TODO: (sb) Change filter settings

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

#pragma mark -
#pragma mark - HR methods

- (void)createHrStorage
{
    [self renewHrMeasurementStorage];
    
    // Create a date string of the current date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    [dateFormatter setDateFormat:@"HH-mm-ss"];
    NSString *timeString = [dateFormatter stringFromDate:[NSDate date]];
    
    [_storage setObject:dateString forKey:@"hrDateString"];
    [_storage setObject:timeString forKey:@"hrTimeString"];
    [_storage setObject:@1 forKey:@"hrFileCount"];
    
}

- (void)renewHrMeasurementStorage
{
    [_storage setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"hrTimestamp"];
    [_storage setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"hr"];
    [_storage setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"rrIntervals"];
}

- (void)appendHrData:(WFHeartrateData *)hrData
{
    if ([hrData isKindOfClass:[WFBTLEHeartrateData class]]) {
        NSArray* rrIntervals = [(WFBTLEHeartrateData*)hrData rrIntervals];
        for (NSNumber* rrInterval in rrIntervals) {
            
            [[_storage objectForKey:@"hrTimestamp"] addObject:[NSNumber numberWithDouble:hrData.timestamp]];
            [[_storage objectForKey:@"hr"] addObject:[NSNumber numberWithDouble:hrData.computedHeartrate]];
            [[_storage objectForKey:@"rrIntervals"] addObject:rrInterval];
            
            // Save, if needed
            if([[_storage objectForKey:@"hrTimestamp"] count] != 0 && [[_storage objectForKey:@"hrTimestamp"] count] % 6000 == 0) {
                [self seriliazeAndZipHrData];
                [self renewHrMeasurementStorage];
            }
        }
    }
}

- (void)seriliazeAndZipHrData
{
    NSString *dateString = [_storage objectForKey:@"hrDateString"];
    NSString *timeString = [_storage objectForKey:@"hrTimeString"];
    NSNumber *fileCount = [_storage objectForKey:@"hrFileCount"];
    
    // Create the path, where the data should be saved
    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *pathComponent = [NSString stringWithFormat:@"%@-t%@-hr%03d.csv.zip", dateString, timeString, [fileCount intValue]];
    NSString *savePath = [rootPath stringByAppendingPathComponent:pathComponent];
    
    // Create data string
    NSMutableString *dataString = [[NSMutableString alloc] initWithCapacity:240000];
    [dataString appendFormat:@"\"%@\",\"%@\",\"%@\"\n",
     @"timestamp",
     @"hr",
     @"rrIntervals"
     ];
    
    // Get first timestamp
    NSNumber *timestamp = [[_storage objectForKey:@"hrTimestamp"] objectAtIndex:0];
    
    for (int i = 0; i < [[_storage objectForKey:@"hrTimestamp"] count]; i++) {
        
        // Append to data string
        [dataString appendFormat:@"%f,%f,%f\n",
         [[[_storage objectForKey:@"hrTimestamp"] objectAtIndex:i] doubleValue] - [timestamp doubleValue],
         [[[_storage objectForKey:@"hr"] objectAtIndex:i] doubleValue],
         [[[_storage objectForKey:@"rrIntervals"] objectAtIndex:i] doubleValue]
         ];
    }
    
    [_storage setObject:[NSNumber numberWithInt:[fileCount intValue] + 1] forKey:@"hrFileCount"];
    
    ZZMutableArchive *archive = [ZZMutableArchive archiveWithContentsOfURL: [NSURL URLWithString:savePath]];
    [archive updateEntries:
     @[
     [ZZArchiveEntry archiveEntryWithFileName:[NSString stringWithFormat:@"%@-t%@-hr%03d.csv", dateString, timeString, [fileCount intValue]]
                                     compress:YES
                                    dataBlock:^(NSError** error)
      {
          return [dataString dataUsingEncoding:NSUTF8StringEncoding];
      }]
     ]
                     error:nil];
}

- (int)hrCount
{
    if([_storage objectForKey:@"hrTimestamp"] != nil) {
        return [[_storage objectForKey:@"hrTimestamp"] count];
    }
    return 0;
}

@end
