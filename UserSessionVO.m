//
//  UserSessionVO.m
//  Client
//
//  Created by Simon Bogutzky on 05.04.12.
//  Copyright 2012 Simon Bogutzky. All rights reserved.
//

#import "UserSessionVO.h"
#import "Zipfile.h"
#import "ZipWriteStream.h"
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
    // Return value label
    NSString *label = @"";
    
    if (deviceMotion != nil) {
        
        // Get timestamp
        double timestamp = deviceMotion.timestamp;
        if (timestamp > 0) {
            
            // Store first timestamp
            if ([[_measurements objectForKey:@"mTimestamp"] count] == 0 && [[_storage objectForKey:@"mFileCount"] intValue] == 1) {
                [_storage setObject:[NSNumber numberWithFloat:timestamp] forKey:@"mTimestamp"];
            }
            
            // Store measurement
            [[_measurements objectForKey:@"mTimestamp"] addObject:[NSNumber numberWithDouble:timestamp]];
            double rotationRateX = deviceMotion.rotationRate.x;
            [[_measurements objectForKey:@"mRotationRateX"] addObject:[NSNumber numberWithDouble:rotationRateX]];
            double filteredRotationRateX = [self filterX:rotationRateX];
            [[_measurements objectForKey:@"mFilteredRotationRateX"] addObject:[NSNumber numberWithDouble:filteredRotationRateX]];
            
            // Wait five seconds
            if (timestamp - [[_storage objectForKey:@"mTimestamp"] doubleValue] > 5.0) {
                int timestampCount = [[_measurements objectForKey:@"mTimestamp"] count];
                if (timestampCount % 500 == 0) {
                    double rotationRateXQuantile06 = [Utility quantileFromX:[_measurements objectForKey:@"mRotationRateX"] prob:.06];
                    [_storage setObject:[NSNumber numberWithDouble:rotationRateXQuantile06] forKey:@"mRotationRateXQuantile06"];
                }
                if ([_storage objectForKey:@"mRotationRateXQuantile06"] != nil) {
                    [self isPeakFromStorage:_storage withKey:@"mRotationRateX" x:rotationRateX quantile:[[_storage objectForKey:@"mRotationRateXQuantile06"] doubleValue]];
                    [self isPeakFromStorage:_storage withKey:@"mFilteredRotationRateX" x:filteredRotationRateX quantile:[[_storage objectForKey:@"mRotationRateXQuantile06"] doubleValue]];
                    
                    if ([[_storage objectForKey:@"mRotationRateXIndicator"] boolValue] && [[_storage objectForKey:@"mFilteredRotationRateXIndicator"] boolValue]) {
                        NSLog(@"Is Peak with: %f rad/s over quantile with: %f rad/s", filteredRotationRateX, [[_storage objectForKey:@"mRotationRateXQuantile06"] doubleValue]);
                        [_storage setObject:[NSNumber numberWithBool:NO] forKey:@"mRotationRateXIndicator"];
                        [_storage setObject:[NSNumber numberWithBool:NO] forKey:@"mFilteredRotationRateXIndicator"];
                        label = @"TO";
                    }
                }
            } else {
                NSLog(@"# Timestamp: %f", timestamp - [[_storage objectForKey:@"mTimestamp"] doubleValue]);
            }
            [[_measurements objectForKey:@"mLabel"] addObject:label];
            
            if ([_storage objectForKey:@"mRotationRateXQuantile06"] != nil) {
                [[_measurements objectForKey:@"mRotationRateXQuantile06"] addObject:[_storage objectForKey:@"mRotationRateXQuantile06"]];
            } else {
                [[_measurements objectForKey:@"mRotationRateXQuantile06"] addObject:@0];
            }
            
            // Save, if needed
            if([[_measurements objectForKey:@"mTimestamp"] count] != 0 && [[_measurements objectForKey:@"mTimestamp"] count] % 6000 == 0) {
                [self seriliazeAndZipMotionData];
                [self renewMotionMeasurementStorage];
            }
        }
    }
    return label;
}

- (NSString *)appendMotionData2:(CMDeviceMotion *)deviceMotion
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
    
    double filteredRotationRateX = [self filterX:rotationRateX];
    [[_measurements objectForKey:@"mFilteredRotationRateX"] addObject:[NSNumber numberWithDouble:filteredRotationRateX]];
    [[_storage objectForKey:@"mFilteredRotationRateX"] addObject:[NSNumber numberWithDouble:filteredRotationRateX]];
    
    double filteredRotationRateX1 = [self filterX1:rotationRateX];
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
            double filteredRotationRateXQuantile = [Utility quantileFromX:[_measurements objectForKey:@"mFilteredRotationRateX"] prob:.98];
            double filteredRotationRateX1Quantile = [Utility quantileFromX:[_measurements objectForKey:@"mFilteredRotationRateX1"] prob:.98];
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
    NSString *dateString = [_storage objectForKey:@"mDateString"];
    NSString *timeString = [_storage objectForKey:@"mTimeString"];
    NSNumber *fileCount = [_storage objectForKey:@"mFileCount"];
    
    // Create the path, where the data should be saved
    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *pathComponent = [NSString stringWithFormat:@"%@-t%@-m%03d.csv.zip", dateString, timeString, [fileCount intValue]];
    NSString *savePath = [rootPath stringByAppendingPathComponent:pathComponent];
    
    // Create ZIP file
    ZipFile *zipFile = [[ZipFile alloc] initWithFileName:savePath mode:ZipFileModeCreate];
    ZipWriteStream *stream = [zipFile writeFileInZipWithName:[NSString stringWithFormat:@"%@-t%@-m%03d.csv", dateString, timeString, [fileCount intValue]] compressionLevel:ZipCompressionLevelDefault];
    
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
    
    
    [stream writeData:[dataString dataUsingEncoding:NSUTF8StringEncoding]];
    [stream finishedWriting];
    [zipFile close];
    
    [_storage setObject:[NSNumber numberWithInt:[fileCount intValue] + 1] forKey:@"mFileCount"];

    // Send notification
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:@[savePath, pathComponent] forKeys:@[@"localPath", @"fileName" ]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MotionDataReady" object:self userInfo:userInfo];
    
    // Compressed data
    return [[NSFileManager defaultManager] contentsAtPath:savePath];
}

#pragma mark -
#pragma mark - Filter

// Lowpass Butterworth 2. Order Filter with 5Hz corner frequency ("http://www-users.cs.york.ac.uk/~fisher/mkfilter/trad.html")

#define NZEROS 0
#define NPOLES 2
#define GAIN   1.265241109e+01

static float xv[NZEROS+1], yv[NPOLES+1];

- (double)filterX:(double)x
{
    xv[0] = x / GAIN;
    yv[0] = yv[1];
    yv[1] = yv[2];
    yv[2] = xv[0] + (-0.6412805170 * yv[0]) + (1.5622441979 * yv[1]);
    return yv[2];
}

// Lowpass Butterworth 2. Order Filter with 7.5Hz corner frequency ("http://www-users.cs.york.ac.uk/~fisher/mkfilter/trad.html")

#define GAIN1   6.283720074e+00

static float xv1[NZEROS+1], yv1[NPOLES+1];

- (double)filterX1:(double)x
{
    xv1[0] = x / GAIN1;
    yv1[0] = yv1[1];
    yv1[1] = yv1[2];
    yv1[2] = xv1[0] + (-0.5135373887 * yv1[0]) + (1.3543959903 * yv1[1]);
    return yv1[2];
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
    
    // Create ZIP file
    ZipFile *zipFile = [[ZipFile alloc] initWithFileName:savePath mode:ZipFileModeCreate];
    ZipWriteStream *stream = [zipFile writeFileInZipWithName:[NSString stringWithFormat:@"%@-t%@-hr%03d.csv", dateString, timeString, [fileCount intValue]] compressionLevel:ZipCompressionLevelDefault];
    
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
    
    [stream writeData:[dataString dataUsingEncoding:NSASCIIStringEncoding]];
    [stream finishedWriting];
    [zipFile close];
}

- (int)hrCount
{
    if([_storage objectForKey:@"hrTimestamp"] != nil) {
        return [[_storage objectForKey:@"hrTimestamp"] count];
    }
    return 0;
}

//???: (sb) Unused code
//- (NSString *)xmlRepresentation
//{
//	NSMutableString *xml = [NSMutableString stringWithCapacity:32];
//	[xml appendString:@"<UserSession>"];
//
//	if (_objectId != nil)
//    {
//		[xml appendFormat:@"<id>%lu</id>", [_objectId unsignedLongValue]];
//	}
//
//	if (_created != nil)
//    {
//		NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
//		[outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//		NSString *createdString = [outputFormatter stringFromDate:_created];
//
//		[xml appendFormat:@"<created>%@</created>", createdString];
//	}
//
//    if (_modified != nil)
//    {
//		NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
//		[outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//		NSString *modifiedString = [outputFormatter stringFromDate:_modified];
//
//		[xml appendFormat:@"<modified>%@</modified>", modifiedString];
//	}
//
//    if (_udid != nil)
//    {
//		[xml appendFormat:@"<udid>%@</udid>", _udid];
//	}
//
//	[xml appendString:@"</UserSession>"];
//	return xml;
//}
//
//- (void)setWithPropertyDictionary:(NSDictionary *)propertyDictionary
//{
//    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//
//    if (propertyDictionary[@"id"] != nil)
//    {
//        NSNumber *tempObjectId = @([[numberFormatter numberFromString:propertyDictionary[@"id"]] unsignedLongValue]);
//        self.objectId = tempObjectId;
//    }
//
//    if (propertyDictionary[@"created"] != nil)
//    {
//        NSDate *createdDate = [dateFormatter dateFromString:propertyDictionary[@"created"]];
//        self.created = createdDate;
//    }
//
//    if (propertyDictionary[@"modified"] != nil)
//    {
//        NSDate *modifiedDate = [dateFormatter dateFromString:propertyDictionary[@"modified"]];
//        self.modified = modifiedDate;
//    }
//
//    if (propertyDictionary[@"udid"] != nil)
//    {
//        self.udid = propertyDictionary[@"udid"];
//    }
//}

@end
