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

@end

@implementation Session

@dynamic filename;
@dynamic filepath;
@dynamic isSynced;
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
    self.filename = [NSString stringWithFormat:@"%@-t%@", dateString, timeString];
    self.filepath = [NSString stringWithFormat:@"%@/", self.user.username];
    
    _motionRecords = [NSMutableArray arrayWithCapacity:720000];
    _locationRecords = [NSMutableArray arrayWithCapacity:180000];
    _heartrateRecords = [NSMutableArray arrayWithCapacity:720000];
}

- (void)addMotionRecord:(Motion *)motionRecord
{
    [_motionRecords addObject:motionRecord];
}

- (void)addLocationRecord:(Location *)locationRecord
{
    [_locationRecords addObject:locationRecord];
}

- (void)addHeartrateRecord:(HeartRateMonitorData *)heartrateRecord
{
    [_heartrateRecords addObject:heartrateRecord];
}

- (void)saveAndZipMotionRecords
{
    if ([self.motionRecords count] != 0) {
        
        self.motionRecordsCount = [NSNumber numberWithInt:[self.motionRecords count]];
        
        // Create archive data
        NSMutableString *dataString = [[NSMutableString alloc] initWithCapacity:240000];
        [dataString appendString:[Motion csvHeader]];
        for (Motion *motionRecord in _motionRecords) {
            [dataString appendString:[motionRecord csvDescription]];
        }
        NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSString *archiveName = [self zipData:data withFilename:[NSString stringWithFormat:@"%@-%@", self.filename, @"motion-data.csv"]]; // Date prefix
        if (archiveName != nil) {
            
            // Send notification
            NSDictionary *userInfo = @{@"archiveName": archiveName};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MotionDataAvailable" object:nil userInfo:userInfo];
        }
    }
}

- (void)saveAndZipHeartrateRecords
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
        
        NSString *archiveName = [self zipData:data withFilename:[NSString stringWithFormat:@"%@-%@", self.filename, @"rr-interval-data.csv"]]; // Date prefix
        if (archiveName != nil) {
            
            // Send notification
            NSDictionary *userInfo = @{@"archiveName": archiveName};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HeartRateMonitorDataAvailable" object:nil userInfo:userInfo];
        }
    }
}

- (void)saveAndZipLocationRecords
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
        
        NSString *archiveName = [self zipData:data withFilename:[NSString stringWithFormat:@"%@-%@", self.filename, @"location-data.gpx"]]; // Date prefix
        if (archiveName != nil) {
            
            // Send notification
            NSDictionary *userInfo = @{@"archiveName": archiveName};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationDataAvailable" object:nil userInfo:userInfo];
        }
    }
}

- (NSString *)zipData:(NSData *)data withFilename:(NSString*)filename
{
    // Create user root directory
    NSString *rootDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    rootDirectory = [rootDirectory stringByAppendingPathComponent:self.user.username];
    if (![[NSFileManager defaultManager] fileExistsAtPath:rootDirectory])
        [[NSFileManager defaultManager] createDirectoryAtPath:rootDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    
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
        NSString *archivePath = [rootDirectory stringByAppendingPathComponent:archiveName];
        
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

@end
