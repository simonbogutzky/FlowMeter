//
//  Session.m
//  DataCollector
//
//  Created by Simon Bogutzky on 25.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "Session.h"
#import "Location.h"
#import "Motion.h"
#import "User.h"

#import <zipzap/zipzap.h>

@interface Session () {

}

@property (nonatomic, strong, readonly) NSString *userDirectory;

@end

@implementation Session

@dynamic identifier;
@dynamic isSynced;
@dynamic isZipped;
@dynamic timestamp;
@dynamic motionRecordsCount;
@dynamic locationRecordsCount;
@dynamic heartrateRecordsCount;
@dynamic user;


@synthesize motionRecords = _motionRecords;
@synthesize locationRecords = _locationRecords;
@synthesize heartrateRecords = _heartrateRecords;

- (void)initialize
{
    self.timestamp = [NSDate date];
    
    // Create a date string of the current date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormatter stringFromDate:self.timestamp];
    [dateFormatter setDateFormat:@"HH-mm-ss"];
    NSString *timeString = [dateFormatter stringFromDate:self.timestamp];
    self.identifier = [NSString stringWithFormat:@"%@-t%@", dateString, timeString];
    
    _motionRecords = [NSMutableArray arrayWithCapacity:24000];
    _locationRecords = [NSMutableArray arrayWithCapacity:10000];
    _heartrateRecords = [NSMutableArray arrayWithCapacity:10800];
}

- (void)addMotionRecord:(Motion *)motionRecord
{
        [_motionRecords addObject:motionRecord];
        
        if ([_motionRecords count] >= 1000) {
            NSArray *motions = [NSArray arrayWithArray:_motionRecords];
            [_motionRecords removeAllObjects];
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                [self storeMotions:motions andNotify:NO];
            });
    }
}

- (void)addLocationRecord:(Location *)locationRecord
{
    [_locationRecords addObject:locationRecord];
}

- (void)addHeartrateRecord:(HeartRateMonitorData *)heartrateRecord
{
    [_heartrateRecords addObject:heartrateRecord];
}

- (void)storeMotions:(NSArray *)motions andNotify:(BOOL)notify
{
    if (motions == nil) {
        motions = _motionRecords;
    }
    
    self.motionRecordsCount = [NSNumber numberWithInt:[self.motionRecordsCount intValue] + [motions count]];

    // Create archive data
    NSMutableData *data = [NSMutableData dataWithData:[[Motion csvHeader] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    for (Motion *motion in motions) {
        [data appendData:[[motion csvDescription] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    }
    
    NSString *filename = [NSString stringWithFormat:@"%@-%@", self.identifier, @"motion-data.csv"];
    NSString *newFilename;
    if ([self.isZipped boolValue]) {
        newFilename = [self zipData:data withFilename:filename];
    } else {
        newFilename = [self writeData:data withFilename:filename];
    }
    
    if (notify) {
        
        // Send notification
        NSDictionary *userInfo = @{@"filename": newFilename};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MotionDataAvailable" object:nil userInfo:userInfo];
    }
}

- (void)storeHeartRateMonitorData
{
    if ([_heartrateRecords count] != 0) {
        
        self.heartrateRecordsCount = [NSNumber numberWithInt:[_heartrateRecords count]];
        
        // Create archive data
        NSMutableString *dataString = [[NSMutableString alloc] initWithCapacity:240000];
        [dataString appendFormat:@"\"%@\"\n", @"rrIntervals"];
        for (HeartRateMonitorData *heartRateMonitorData in _heartrateRecords) {
            for (NSNumber *rrIntervall in heartRateMonitorData.rrIntervals) {
                [dataString appendFormat:@"%d\n", [rrIntervall intValue]];
            }
        }
        NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSString *filename = [NSString stringWithFormat:@"%@-%@", self.identifier, @"rr-interval-data.csv"];
        NSString *newFilename;
        if ([self.isZipped boolValue]) {
            newFilename = [self zipData:data withFilename:filename];
        } else {
            newFilename = [self writeData:data withFilename:filename];
        }
        if (newFilename != nil) {
            
            // Send notification
            NSDictionary *userInfo = @{@"filename": newFilename};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HeartRateMonitorDataAvailable" object:nil userInfo:userInfo];
        }
    }
}

- (void)storeLocationData
{
    if ([_locationRecords count] != 0) {
        
        self.locationRecordsCount = [NSNumber numberWithInt:[_locationRecords count]];
        
        // Create  archive data
        NSMutableString *dataString = [[NSMutableString alloc] initWithCapacity:240000];
        [dataString appendString:[Location gpxHeader]];
        
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[_locationRecords objectAtIndex:0] systemTime]];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"YYYY-MM-dd'T'HH:mm:ss'Z'"];
        NSString *datetring = [formatter stringFromDate:date];
        [dataString appendFormat:@"<time>%@</time>", datetring];
        [dataString appendString:@"<trk>"];
        [dataString appendString:@"<trkseg>"];
        for (Location *locationRecord in _locationRecords) {
            
            // Append to data string
            [dataString appendString:[locationRecord gpxDescription]];
            
        }
        [dataString appendString:@"</trkseg>"];
        [dataString appendString:@"</trk>"];
        [dataString appendString:[Location gpxFooter]];
        
        NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSString *filename = [NSString stringWithFormat:@"%@-%@", self.identifier, @"location-data.gpx"];
        NSString *newFilename;
        if ([self.isZipped boolValue]) {
            newFilename = [self zipData:data withFilename:filename];
        } else {
            newFilename = [self writeData:data withFilename:filename];
        }
        if (newFilename != nil) {
            
            // Send notification
            NSDictionary *userInfo = @{@"filename": newFilename};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationDataAvailable" object:nil userInfo:userInfo];
        }
    }
}

- (NSString *)writeData:(NSData *)data withFilename:(NSString *)filename
{
    NSString *filePath = [self.userDirectory stringByAppendingPathComponent:filename];
//    if (![data writeToFile:filePath atomically:YES]) {
//        return nil;
//    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath])
    {
        [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    }
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:data];
    [fileHandle closeFile];
    
    return filename;
}

- (NSString *)zipData:(NSData *)data withFilename:(NSString *)filename
{
    
    // Create archive entry
    NSString *entryFileName = [NSString stringWithFormat:@"%@", filename];
    ZZArchiveEntry *archiveEntry = [ZZArchiveEntry archiveEntryWithFileName:entryFileName
                                                                   compress:YES
                                                                  dataBlock:^(NSError** error)
                                    {
                                        return data;
                                    }];
    NSString *archiveName = nil;
    if (archiveEntry) {
        archiveName = [NSString stringWithFormat:@"%@.zip", filename];
        NSString *archivePath = [self.userDirectory stringByAppendingPathComponent:archiveName];
        
        ZZMutableArchive *archive = [ZZMutableArchive archiveWithContentsOfURL:[NSURL fileURLWithPath:archivePath]];
        NSError *error = nil;
        [archive updateEntries:@[archiveEntry] error:&error];
        
        if (error) {
            NSLog(@"Error: %@", [error localizedDescription]);
            return nil;
        }
        
    } else {
        NSLog(@"Error while creating archive entry: %@", entryFileName);
        return nil;
    }
    return archiveName;
}

- (NSString *)userDirectory
{
    // Create user directory, if need
    NSString *userDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    userDirectory = [userDirectory stringByAppendingPathComponent:self.user.username];
    if (![[NSFileManager defaultManager] fileExistsAtPath:userDirectory])
        [[NSFileManager defaultManager] createDirectoryAtPath:userDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    
    return userDirectory;
}

@end
