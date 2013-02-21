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

@implementation UserSessionVO

- (id)init
{
	self = [super init];
	if (self != nil) {
        _data = [NSMutableString stringWithCapacity:191520141]; // 191520000 + 141 bytes for to hours of data and 2 hours overhead (one hour approx. 45mb)
        [_data appendFormat:@"\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\"\n",
         @"timestamp",
         @"userAccX",
         @"userAccY",
         @"userAccZ",
         @"userWAccX",
         @"userWAccY",
         @"userWAccZ",
         @"gravityX",
         @"gravityY",
         @"gravityZ",
         @"rotRateX",
         @"rotRateY",
         @"rotRateZ",
         @"attYaw",
         @"attRoll",
         @"attPitch"
         ];
	}
	return self;
}

- (void)appendMotionData:(CMDeviceMotion *)deviceMotion {
    if (deviceMotion != nil) {
        [_data appendFormat:@"%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
         deviceMotion.timestamp,
         deviceMotion.userAcceleration.x,
         deviceMotion.userAcceleration.y,
         deviceMotion.userAcceleration.z,
         deviceMotion.userAccelerationInReferenceFrame.x,
         deviceMotion.userAccelerationInReferenceFrame.y,
         deviceMotion.userAccelerationInReferenceFrame.z,
         deviceMotion.gravity.x,
         deviceMotion.gravity.y,
         deviceMotion.gravity.z,
         deviceMotion.rotationRate.x,
         deviceMotion.rotationRate.y,
         deviceMotion.rotationRate.z,
         deviceMotion.attitude.yaw,
         deviceMotion.attitude.roll,
         deviceMotion.attitude.pitch
         ];
    } else {
        [_data appendFormat:@"NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN\n"];
    }
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
    // Create a date string of the current date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    [dateFormatter setDateFormat:@"HH-mm-ss"];
    NSString *timeString = [dateFormatter stringFromDate:[NSDate date]];
    
    // Create the path, where the data should be saved
    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *pathComponent = [NSString stringWithFormat:@"%@-t%@.csv.zip", dateString, timeString];
    NSString *savePath = [rootPath stringByAppendingPathComponent:pathComponent];
    
    // Create ZIP file
    ZipFile *zipFile = [[ZipFile alloc] initWithFileName:savePath mode:ZipFileModeCreate];
    ZipWriteStream *stream = [zipFile writeFileInZipWithName:[NSString stringWithFormat:@"%@-t%@.csv", dateString, timeString]compressionLevel:ZipCompressionLevelDefault];
    [stream writeData:[_data dataUsingEncoding:NSUTF8StringEncoding]];
    [stream finishedWriting];
    [zipFile close];
    
    // Compressed data
    return [[NSFileManager defaultManager] contentsAtPath:savePath];
}


@end
