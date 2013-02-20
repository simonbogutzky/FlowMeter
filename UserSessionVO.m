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
	}
	return self;
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

//--

- (void)seriliazeAsXML
{
    
//    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
//    NSString *pathComponent = [NSString stringWithFormat:@"user_session_%06lu.xml", [self.objectId unsignedLongValue]];
//    NSString *savePath = [rootPath stringByAppendingPathComponent:pathComponent];
//    [[self xmlRepresentationWithInnerXML:YES] writeToFile:savePath 
//                 atomically:NO 
//                   encoding:NSStringEncodingConversionAllowLossy 
//                      error:nil];
}

- (NSData *)seriliazeAndZipAsXML
{
    
//    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
//    NSString *pathComponent = [NSString stringWithFormat:@"user_session_%06lu.xml.zip", [self.objectId unsignedLongValue]];
//    NSString *savePath = [rootPath stringByAppendingPathComponent:pathComponent];
//    
//    ZipFile *zipFile = [[ZipFile alloc] initWithFileName:savePath mode:ZipFileModeCreate];
//    ZipWriteStream *stream = [zipFile writeFileInZipWithName:[NSString stringWithFormat:@"user_session_%06lu.xml", [self.objectId unsignedLongValue]] compressionLevel:ZipCompressionLevelDefault];
//    
//    [stream writeData:[[self xmlRepresentationWithInnerXML:YES] dataUsingEncoding:NSUTF8StringEncoding]];
//    
//    [stream finishedWriting];
//    [zipFile close];
//    
//    return [[NSFileManager defaultManager] contentsAtPath:savePath];
}

- (void)seriliazeAsText
{
//    NSDateFormatter *formatter;
//    NSString        *dateString;
//    
//    formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:@"yyyyMMdd_HHmmss"];
//    
//    dateString = [formatter stringFromDate:[NSDate date]]; 
//    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
//    NSString *pathComponent = [NSString stringWithFormat:@"%@_%@.txt", dateString, self.description];
//    NSString *savePath = [rootPath stringByAppendingPathComponent:pathComponent];
//    [[self xmlRepresentationWithInnerXML:YES] writeToFile:savePath
//                                               atomically:NO
//                                                 encoding:NSStringEncodingConversionAllowLossy
//                                                    error:nil];
}

- (NSData *)seriliazeAndZipAsText
{
//    NSDateFormatter *formatter;
//    NSString        *dateString;
//    
//    formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:@"yyyyMMdd_HHmmss"];
//    
//    dateString = [formatter stringFromDate:[NSDate date]];
//    
//    
//    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
//    NSString *pathComponent = [NSString stringWithFormat:@"%@_%@.txt.zip", dateString, self.description];
//    NSString *savePath = [rootPath stringByAppendingPathComponent:pathComponent];
//    
//    ZipFile *zipFile = [[ZipFile alloc] initWithFileName:savePath mode:ZipFileModeCreate];
//    ZipWriteStream *stream = [zipFile writeFileInZipWithName:[NSString stringWithFormat:@"%@_%@.txt", dateString, self.description] compressionLevel:ZipCompressionLevelDefault];
//    
//    [stream writeData:[[self textRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
//    
//    [stream finishedWriting];
//    [zipFile close];
//    
//    return [[NSFileManager defaultManager] contentsAtPath:savePath];
}


@end
