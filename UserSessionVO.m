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

@interface UserSessionVO ()
{
    unsigned long dataCount;
    unsigned int fileCount;
    UserSessionVO *userSession;
    NSString *dateString;
    NSString *timeString;
}
@end

@implementation UserSessionVO

- (id)init
{
	self = [super init];
	if (self != nil) {
//        dataCount = 0;
//        fileCount = 1;
//        
//        // Create a date string of the current date
//        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
//        dateString = [dateFormatter stringFromDate:[NSDate date]];
//        [dateFormatter setDateFormat:@"HH-mm-ss"];
//        timeString = [dateFormatter stringFromDate:[NSDate date]];
//        
//        _data = [NSMutableString stringWithCapacity:1048576]; // 191520000 + 141 bytes for to hours of data and 2 hours overhead (one hour approx. 45mb)
//        [_data appendFormat:@"\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\"\n",
//         @"timestamp",
//         @"userAccX",
//         @"userAccY",
//         @"userAccZ",
//         @"userWAccX",
//         @"userWAccY",
//         @"userWAccZ",
//         @"gravityX",
//         @"gravityY",
//         @"gravityZ",
//         @"rotRateX",
//         @"rotRateY",
//         @"rotRateZ",
//         @"attYaw",
//         @"attRoll",
//         @"attPitch"
//         ];
        
        _measurements = [[NSMutableDictionary alloc] init];
        [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:8000] forKey:@"timestamp"];
        [_measurements setObject:[[NSMutableArray alloc] initWithCapacity:8000] forKey:@"rotationRateX"];
        
	}
	return self;
}

- (void)appendMotionData:(CMDeviceMotion *)deviceMotion {
    double timestamp = deviceMotion.timestamp;
    double rotationRateX = deviceMotion.rotationRate.x;
    [[_measurements objectForKey:@"timestamp"] addObject:[NSNumber numberWithDouble:timestamp]];
    [[_measurements objectForKey:@"rotationRateX"] addObject:[NSNumber numberWithDouble:rotationRateX]];
    
    if (timestamp - [[[_measurements objectForKey:@"timestamp"] objectAtIndex:0] doubleValue] > 5.0) {
        NSLog(@"Count: %d", [[_measurements objectForKey:@"rotationRateX"] count]);
    } else {
        NSLog(@"Timestamp: %f",timestamp - [[[_measurements objectForKey:@"timestamp"] objectAtIndex:0] doubleValue]);
    }
    
    
    
    
//    if (dataCount != 0 && dataCount % 6721 == 0) {
//        [self seriliazeAndZip];
//        _data = [NSMutableString stringWithCapacity:1048576];
//    }
//    
//    if (deviceMotion != nil) {
//        [_data appendFormat:@"%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
//         deviceMotion.timestamp,
//         deviceMotion.userAcceleration.x,
//         deviceMotion.userAcceleration.y,
//         deviceMotion.userAcceleration.z,
//         deviceMotion.userAccelerationInReferenceFrame.x,
//         deviceMotion.userAccelerationInReferenceFrame.y,
//         deviceMotion.userAccelerationInReferenceFrame.z,
//         deviceMotion.gravity.x,
//         deviceMotion.gravity.y,
//         deviceMotion.gravity.z,
//         deviceMotion.rotationRate.x,
//         deviceMotion.rotationRate.y,
//         deviceMotion.rotationRate.z,
//         deviceMotion.attitude.yaw,
//         deviceMotion.attitude.roll,
//         deviceMotion.attitude.pitch
//         ];
//    } else {
//        [_data appendFormat:@"NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN\n"];
//    }
//    
//    dataCount++;
}

- (NSString *)xmlRepresentation
{
	NSMutableString *xml = [NSMutableString stringWithCapacity:32];
	[xml appendString:@"<UserSession>"];
	
	if (_objectId != nil)
    {
		[xml appendFormat:@"<id>%lu</id>", [_objectId unsignedLongValue]];
	}
	
	if (_created != nil)
    {
		NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
		[outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
		NSString *createdString = [outputFormatter stringFromDate:_created];
		
		[xml appendFormat:@"<created>%@</created>", createdString];
	}
    
    if (_modified != nil)
    {
		NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
		[outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
		NSString *modifiedString = [outputFormatter stringFromDate:_modified];
		
		[xml appendFormat:@"<modified>%@</modified>", modifiedString];
	}
    
    if (_udid != nil)
    {
		[xml appendFormat:@"<udid>%@</udid>", _udid];
	}
	
	[xml appendString:@"</UserSession>"];
	return xml;
}

- (void)setWithPropertyDictionary:(NSDictionary *)propertyDictionary 
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    if (propertyDictionary[@"id"] != nil) 
    {
        NSNumber *tempObjectId = @([[numberFormatter numberFromString:propertyDictionary[@"id"]] unsignedLongValue]);
        self.objectId = tempObjectId;
    }
    
    if (propertyDictionary[@"created"] != nil) 
    {
        NSDate *createdDate = [dateFormatter dateFromString:propertyDictionary[@"created"]];
        self.created = createdDate;
    }
    
    if (propertyDictionary[@"modified"] != nil) 
    {
        NSDate *modifiedDate = [dateFormatter dateFromString:propertyDictionary[@"modified"]];
        self.modified = modifiedDate;
    }
    
    if (propertyDictionary[@"udid"] != nil) 
    {
        self.udid = propertyDictionary[@"udid"];
    }
}

- (NSData *)seriliazeAndZip
{

    // Create the path, where the data should be saved
    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *pathComponent = [NSString stringWithFormat:@"%@-t%@-%03d.csv.zip", dateString, timeString, fileCount];
    NSString *savePath = [rootPath stringByAppendingPathComponent:pathComponent];
    
    // Create ZIP file
    ZipFile *zipFile = [[ZipFile alloc] initWithFileName:savePath mode:ZipFileModeCreate];
    ZipWriteStream *stream = [zipFile writeFileInZipWithName:[NSString stringWithFormat:@"%@-t%@-%03d.csv", dateString, timeString, fileCount] compressionLevel:ZipCompressionLevelDefault];
    [stream writeData:[_data dataUsingEncoding:NSUTF8StringEncoding]];
    [stream finishedWriting];
    [zipFile close];
    
    fileCount++;
    
    // Compressed data
    return [[NSFileManager defaultManager] contentsAtPath:savePath];
    
}


@end
