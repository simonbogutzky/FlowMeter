//
//  Session.m
//  DataCollector
//
//  Created by Simon Bogutzky on 25.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "Session.h"
#import "MotionRecord.h"

#import <zipzap/zipzap.h>

@implementation Session

@dynamic isSynced;
@dynamic timestamp;
@dynamic filename;
@dynamic motionRecords;

- (void)saveAndZipMotionRecords
{
    if ([self.motionRecords count] != 0) {
        
        // Create the path, where the data should be saved
        NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *filename = [NSString stringWithFormat:@"%@.zip", self.filename];
        NSString *localPath = [rootPath stringByAppendingPathComponent:filename];
        
        // Create data string
        NSMutableString *dataString = [[NSMutableString alloc] initWithCapacity:240000];
        [dataString appendFormat:@"\"%@\",\"%@\"\n",
         @"timestamp",
         @"rotationRateX"
         ];
        
        // Sort data
        NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
        NSArray *motionRecords = [self.motionRecords sortedArrayUsingDescriptors:@[timestampDescriptor]];
        
        // Get first timestamp
        NSNumber *timestamp = ((MotionRecord *)[motionRecords objectAtIndex:0]).timestamp;
        
        for (MotionRecord *motionRecord in motionRecords) {
            // Append to data string
            [dataString appendFormat:@"%f,%f\n",
             [motionRecord.timestamp doubleValue] - [timestamp doubleValue],
             [motionRecord.rotationRateX doubleValue]
             ];
        }
        
        // Zip data
        ZZMutableArchive *archive = [ZZMutableArchive archiveWithContentsOfURL:[NSURL fileURLWithPath:localPath]];
        [archive updateEntries:
         @[
         [ZZArchiveEntry archiveEntryWithFileName:self.filename
                                         compress:YES
                                        dataBlock:^(NSError** error)
          {
              return [dataString dataUsingEncoding:NSUTF8StringEncoding];
          }]
         ]
                         error:nil];
        
        // Send notification
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:@[localPath, filename] forKeys:@[@"localPath", @"filename"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MotionDataAvailable" object:self userInfo:userInfo];
    }
}


@end
