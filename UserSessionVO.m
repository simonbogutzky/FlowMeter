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
}
@end

@implementation UserSessionVO

- (id)init
{
	self = [super init];
	if (self != nil) {
        
        // Create dictionary for measurements
        _measurements = [[NSMutableDictionary alloc] init];
        
        // Create store for fix values
        _storage = [[NSMutableDictionary alloc] init];
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
    
    [_storage setObject:[NSNumber numberWithBool:NO] forKey:@"mUnfilteredIndicator"];
    [_storage setObject:[NSNumber numberWithBool:NO] forKey:@"mFilteredIndicator"];
}

- (void)renewMotionMeasurementStorage
{
    [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"mTimestamp"];
    [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"mRotationRateX"];
    [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"mFilteredRotationRateX"];
    [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"mLabel"];
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
    if (slope * previousSlope < 0 && quantile > previousMeasurement) { 
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
//                if (timestamp - [[_storage objectForKey:@"mTimestamp"] doubleValue] < 6.0) 
                    double quantile06 = [Utility quantileFromX:[_measurements objectForKey:@"mRotationRateX"] prob:.06];
                    [_storage setObject:[NSNumber numberWithDouble:quantile06] forKey:@"mUnfilteredQuantile06"];
//                }
                
                [self isPeakFromStorage:_storage withKey:@"mUnfiltered" x:rotationRateX quantile:[[_storage objectForKey:@"mUnfilteredQuantile06"] doubleValue]];
                [self isPeakFromStorage:_storage withKey:@"mFiltered" x:filteredRotationRateX quantile:[[_storage objectForKey:@"mUnfilteredQuantile06"] doubleValue]];
                
                if ([[_storage objectForKey:@"mUnfilteredIndicator"] boolValue] && [[_storage objectForKey:@"mFilteredIndicator"] boolValue]) {
                    NSLog(@"Is Peak with: %f rad/s over quantile with: %f rad/s", filteredRotationRateX, [[_storage objectForKey:@"mUnfilteredQuantile06"] doubleValue]);
                    [_storage setObject:[NSNumber numberWithBool:NO] forKey:@"mUnfilteredIndicator"];
                    [_storage setObject:[NSNumber numberWithBool:NO] forKey:@"mFilteredIndicator"];
                    label = @"HS";
                }
            } else {
                NSLog(@"# Timestamp: %f", timestamp - [[_storage objectForKey:@"mTimestamp"] doubleValue]);
            }
            [[_measurements objectForKey:@"mLabel"] addObject:label];

            // Save, if needed
            if([[_measurements objectForKey:@"mTimestamp"] count] != 0 && [[_measurements objectForKey:@"mTimestamp"] count] % 6000 == 0) {
                [self seriliazeAndZipMotionData];
                [self renewMotionMeasurementStorage];
            }
        }
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
    [dataString appendFormat:@"\"%@\",\"%@\",\"%@\",\"%@\"\n",
     @"timestamp",
     @"rotationRateX",
     @"filteredRotationRateX",
     @"label"
     ];
    
    // Get first timestamp
    NSNumber *timestamp = [_storage objectForKey:@"mTimestamp"];
    
    for (int i = 0; i < [[_measurements objectForKey:@"mTimestamp"] count]; i++) {
        
        // Append to data string
        [dataString appendFormat:@"%f,%f,%f,%@\n",
         [[[_measurements objectForKey:@"mTimestamp"] objectAtIndex:i] doubleValue] - [timestamp doubleValue],
         [[[_measurements objectForKey:@"mRotationRateX"] objectAtIndex:i] doubleValue],
         [[[_measurements objectForKey:@"mFilteredRotationRateX"] objectAtIndex:i] doubleValue],
         [[_measurements objectForKey:@"mLabel"] objectAtIndex:i]
         ];
    }
    
    
    [stream writeData:[dataString dataUsingEncoding:NSUTF8StringEncoding]];
    [stream finishedWriting];
    [zipFile close];
    
    [_storage setObject:[NSNumber numberWithInt:[fileCount intValue] + 1] forKey:@"mFileCount"];
    
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
    [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"hrTimestamp"];
    [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"hr"];
    [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:6000] forKey:@"rrIntervals"];
}

- (void)appendHrData:(WFHeartrateData *)hrData
{
    if ([hrData isKindOfClass:[WFBTLEHeartrateData class]]) {
        NSArray* rrIntervals = [(WFBTLEHeartrateData*)hrData rrIntervals];
        for (NSNumber* rrInterval in rrIntervals) {
            
            // Store first timestamp
            if ([[_measurements objectForKey:@"hrTimestamp"] count] == 0 && [[_storage objectForKey:@"hrFileCount"] intValue] == 1) {
                [_storage setObject:[NSNumber numberWithFloat:hrData.timestamp] forKey:@"hrTimestamp"];
            }
            
            [[_measurements objectForKey:@"hrTimestamp"] addObject:[NSNumber numberWithDouble:hrData.timestamp]];
            [[_measurements objectForKey:@"hr"] addObject:[NSNumber numberWithDouble:hrData.computedHeartrate]];
            [[_measurements objectForKey:@"rrIntervals"] addObject:rrInterval];
            
            // Save, if needed
            if([[_measurements objectForKey:@"hrTimestamp"] count] != 0 && [[_measurements objectForKey:@"hrTimestamp"] count] % 6000 == 0) {
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
    NSNumber *timestamp = [_storage objectForKey:@"hrTimestamp"];
    
    for (int i = 0; i < [[_measurements objectForKey:@"hrTimestamp"] count]; i++) {
        
        // Append to data string
        [dataString appendFormat:@"%f,%f,%f\n",
         [[[_measurements objectForKey:@"hrTimestamp"] objectAtIndex:i] doubleValue] - [timestamp doubleValue],
         [[[_measurements objectForKey:@"hr"] objectAtIndex:i] doubleValue],
         [[[_measurements objectForKey:@"rrIntervals"] objectAtIndex:i] doubleValue]
         ];
    }
    
    [_storage setObject:[NSNumber numberWithInt:[fileCount intValue] + 1] forKey:@"hrFileCount"];
    
    [stream writeData:[dataString dataUsingEncoding:NSASCIIStringEncoding]];
    [stream finishedWriting];
    [zipFile close];
}

- (int)hrCount
{
    if([_measurements objectForKey:@"hrTimestamp"] != nil) {
        return [[_measurements objectForKey:@"hrTimestamp"] count];
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
