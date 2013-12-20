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
@dynamic user;

@synthesize motionRecords = _motionRecords;
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
    self.filepath = [NSString stringWithFormat:@"%@/", self.user.username];
    
    _motionRecords = [NSMutableArray arrayWithCapacity:720000];
    _locationRecords = [NSMutableArray arrayWithCapacity:180000];
}

- (void)addMotionRecord:(Motion *)motionRecord
{
    [_motionRecords addObject:motionRecord];
}

- (void)addLocationRecord:(Location *)locationRecord
{
    [_locationRecords addObject:locationRecord];
}

- (void)saveAndZipMotionRecords
{
    if ([_motionRecords count] != 0) {
        
        self.motionRecordsCount = [NSNumber numberWithInt:[_motionRecords count]];
        
        // Create the path, where the data should be saved
        NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *filename = [NSString stringWithFormat:@"%@-motion-data.csv.zip", self.filename];
        NSString *localPath = [rootPath stringByAppendingPathComponent:self.filepath];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:localPath])
            [[NSFileManager defaultManager] createDirectoryAtPath:localPath withIntermediateDirectories:NO attributes:nil error:nil];
        
        localPath = [localPath stringByAppendingPathComponent:filename];
        
        // Create data string
        NSMutableString *dataString = [[NSMutableString alloc] initWithCapacity:240000];
        
        [dataString appendString:[Motion csvHeader]];
        
        for (Motion *motionRecord in _motionRecords) {
            
            // Append to data string
            [dataString appendString:[motionRecord csvDescription]];
        }
        
        // Zip data
        ZZMutableArchive *archive = [ZZMutableArchive archiveWithContentsOfURL:[NSURL fileURLWithPath:localPath]];
        [archive updateEntries:
         @[
         [ZZArchiveEntry archiveEntryWithFileName:[NSString stringWithFormat:@"%@-motion-data.csv", self.filename]
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

- (void)saveAndZipLocationRecords
{
    if ([_locationRecords count] != 0) {
        
        self.locationRecordsCount = [NSNumber numberWithInt:[_locationRecords count]];
        
        // Save *.kml
        // Create the path, where the data should be saved
        NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *filename = [NSString stringWithFormat:@"%@-location-data.kml.zip", self.filename];
        NSString *localPath = [rootPath stringByAppendingPathComponent:self.filepath];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:localPath])
            [[NSFileManager defaultManager] createDirectoryAtPath:localPath withIntermediateDirectories:NO attributes:nil error:nil];
        
        localPath = [localPath stringByAppendingPathComponent:filename];
        
        // Create data string
        NSMutableString *dataString = [[NSMutableString alloc] initWithCapacity:240000];
        [dataString appendString:[Location kmlHeader]];
        
        for (Location *locationRecord in _locationRecords) {
            
            // Append to data string
            [dataString appendString:[locationRecord kmlDescription]];
        }
        
        [dataString appendString:[Location kmlFooter]];
        
        // Zip data
        ZZMutableArchive *archive = [ZZMutableArchive archiveWithContentsOfURL:[NSURL fileURLWithPath:localPath]];
        [archive updateEntries:
         @[
         [ZZArchiveEntry archiveEntryWithFileName:[NSString stringWithFormat:@"%@-location-data.kml", self.filename]
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
    }
}

@end
