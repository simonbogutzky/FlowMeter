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
    unsigned long _dataCount;
    unsigned int _fileCount;
    
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
    [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:8000] forKey:@"timestamp"];
    [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:8000] forKey:@"rotationRateX"];
    [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:8000] forKey:@"filteredRotationRateX"];
    [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:8000] forKey:@"label"];
    
    [_storage setObject:[NSNumber numberWithBool:NO] forKey:@"unfilteredIndicator"];
    [_storage setObject:[NSNumber numberWithBool:NO] forKey:@"filteredIndicator"];
    
    // Counts
    _dataCount = 0;
    _fileCount = 1;
    
    // Create data string
    _data = [NSMutableString stringWithCapacity:1048576]; // 191520000 + 141 bytes for to hours of data and 2 hours overhead (one hour approx. 45mb)
    [_data appendFormat:@"\"%@\",\"%@\",\"%@\",\"%@\"\n",
     @"timestamp",
     @"rotationRateX",
     @"filteredRotationRateX",
     @"label"
     ];
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
        
            // Store measurement
            [[_measurements objectForKey:@"timestamp"] addObject:[NSNumber numberWithDouble:timestamp]];
            double rotationRateX = deviceMotion.rotationRate.x;
            [[_measurements objectForKey:@"rotationRateX"] addObject:[NSNumber numberWithDouble:rotationRateX]];
            double filteredRotationRateX = [self filterX:rotationRateX];
            [[_measurements objectForKey:@"filteredRotationRateX"] addObject:[NSNumber numberWithDouble:filteredRotationRateX]];
        
            // Wait five seconds
            if (timestamp - [[[_measurements objectForKey:@"timestamp"] objectAtIndex:0] doubleValue] > 5.0) {
//                if (timestamp - [[[_measurements objectForKey:@"timestamp"] objectAtIndex:0] doubleValue] < 6.0) {
                    double quantile06 = [Utility quantileFromX:[_measurements objectForKey:@"rotationRateX"] prob:.06];
                    [_storage setObject:[NSNumber numberWithDouble:quantile06] forKey:@"unfilteredQuantile06"];
//                }
                
                [self isPeakFromStorage:_storage withKey:@"unfiltered" x:rotationRateX quantile:[[_storage objectForKey:@"unfilteredQuantile06"] doubleValue]];
                [self isPeakFromStorage:_storage withKey:@"filtered" x:filteredRotationRateX quantile:[[_storage objectForKey:@"unfilteredQuantile06"] doubleValue]];
                
                if ([[_storage objectForKey:@"unfilteredIndicator"] boolValue] && [[_storage objectForKey:@"filteredIndicator"] boolValue]) {
                    NSLog(@"Is Peak with: %f rad/s over quantile with: %f rad/s", filteredRotationRateX, [[_storage objectForKey:@"unfilteredQuantile06"] doubleValue]);
                    [_storage setObject:[NSNumber numberWithBool:NO] forKey:@"unfilteredIndicator"];
                    [_storage setObject:[NSNumber numberWithBool:NO] forKey:@"filteredIndicator"];
                    label = @"HS";
                }
            } else {
                NSLog(@"Timestamp: %f",timestamp - [[[_measurements objectForKey:@"timestamp"] objectAtIndex:0] doubleValue]);
            }
            [[_measurements objectForKey:@"label"] addObject:label];

            // Save, if needed
            if (_dataCount != 0 && _dataCount % 6721 == 0) {
                [self seriliazeAndZipMotionData];
                _data = [NSMutableString stringWithCapacity:1048576];
            }
            // Append to data string
            [_data appendFormat:@"%f,%f,%f,%@\n",
                timestamp - [[[_measurements objectForKey:@"timestamp"] objectAtIndex:0] doubleValue],
                rotationRateX,
                filteredRotationRateX,
                label
             ];
        }
    }
    _dataCount++;
    return label;
}

- (NSData *)seriliazeAndZipMotionData
{
    // Create a date string of the current date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    [dateFormatter setDateFormat:@"HH-mm-ss"];
    NSString *timeString = [dateFormatter stringFromDate:[NSDate date]];
    
    // Create the path, where the data should be saved
    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *pathComponent = [NSString stringWithFormat:@"%@-t%@-%03d.csv.zip", dateString, timeString, _fileCount];
    NSString *savePath = [rootPath stringByAppendingPathComponent:pathComponent];
    
    // Create ZIP file
    ZipFile *zipFile = [[ZipFile alloc] initWithFileName:savePath mode:ZipFileModeCreate];
    ZipWriteStream *stream = [zipFile writeFileInZipWithName:[NSString stringWithFormat:@"%@-t%@-%03d.csv", dateString, timeString, _fileCount] compressionLevel:ZipCompressionLevelDefault];
    [stream writeData:[_data dataUsingEncoding:NSUTF8StringEncoding]];
    [stream finishedWriting];
    [zipFile close];
    
    _fileCount++;
    
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
    [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:8000] forKey:@"hrTimestamp"];
    [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:8000] forKey:@"rrIntervals"];
}

- (void)appendHrData:(WFHeartrateData *)hrData
{
    if ([hrData isKindOfClass:[WFBTLEHeartrateData class]]) {
        NSArray* rrIntervals = [(WFBTLEHeartrateData*)hrData rrIntervals];
        for (NSNumber* rrInterval in rrIntervals) {
            [[_measurements objectForKey:@"hrTimestamp"] addObject:[NSNumber numberWithDouble:hrData.timestamp]];
            [[_measurements objectForKey:@"rrIntervals"] addObject:rrInterval];
        }
    }
}

- (void)seriliazeAndZipHrData
{
    // Create a date string of the current date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    [dateFormatter setDateFormat:@"HH-mm-ss"];
    NSString *timeString = [dateFormatter stringFromDate:[NSDate date]];
    
    // Create the path, where the data should be saved
    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *pathComponent = [NSString stringWithFormat:@"%@-t%@-hr.txt.zip", dateString, timeString];
    NSString *savePath = [rootPath stringByAppendingPathComponent:pathComponent];
    
    // Create data string
    NSMutableString *dataString = [[NSMutableString alloc] initWithCapacity:16000];
    
    // Get first timestamp
    NSNumber *timestamp = [[_measurements objectForKey:@"hrTimestamp"] objectAtIndex:0];
    
    for (int i = 0; i < [[_measurements objectForKey:@"hrTimestamp"] count]; i++) {
        
        // Append to data string
        [dataString appendFormat:@"%f\t%f\n",
         [[[_measurements objectForKey:@"hrTimestamp"] objectAtIndex:i] doubleValue] - [timestamp doubleValue],
         [[[_measurements objectForKey:@"rrIntervals"] objectAtIndex:i] doubleValue]
         ];
    }
    
    // Create ZIP file
    ZipFile *zipFile = [[ZipFile alloc] initWithFileName:savePath mode:ZipFileModeCreate];
    ZipWriteStream *stream = [zipFile writeFileInZipWithName:[NSString stringWithFormat:@"%@-t%@-hr.txt", dateString, timeString] compressionLevel:ZipCompressionLevelDefault];
    [stream writeData:[dataString dataUsingEncoding:NSASCIIStringEncoding]];
    [stream finishedWriting];
    [zipFile close];
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
