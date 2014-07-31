//
//  Session+OutStream.m
//  DataCollector
//
//  Created by Simon Bogutzky on 16.07.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "Session+OutStream.h"
#import "SelfReport+Description.h"
#import "ZipKit/ZipKit.h"

@implementation Session (OutStream)

- (NSString *)writeOutSelfReports
{
    if ([self.selfReports count] > 0) {
        
        // Create archive data
        NSMutableData *data = [NSMutableData dataWithCapacity:0];
        
        // Order by date
        NSArray *selfReports = [self.selfReports sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];
        
        // Append header
        [data appendData:[[[selfReports lastObject] csvHeader] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        
        // Append data
        for (SelfReport *selfReport in selfReports) {
            [data appendData:[[selfReport csvDescription] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        }
        
        // Write in file with filename
        NSDateFormatter *dateTimeFormatter = [[NSDateFormatter alloc] init];
        [dateTimeFormatter setDateFormat:@"yyyy-MM-dd--HH-mm-ss"];
        NSString *filename = [NSString stringWithFormat:@"%@-%@",[dateTimeFormatter stringFromDate:self.date], @"self-reports.csv"];
        return [self writeData:data withFilename:filename];
    }
    return @"";
}

- (NSString *)zipSelfReports
{
    NSString *filename = [self writeOutSelfReports];
    filename = [self zipFileWithFilename:filename];
    return filename;
}

#pragma mark -
#pragma mark - Convient methods

- (NSString *)userDirectory
{
    return  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
}

- (NSString *)writeData:(NSData *)data withFilename:(NSString *)filename
{
    NSString *filePath = [self.userDirectory stringByAppendingPathComponent:filename];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath])
    {
        [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    } else {
        [fileManager removeItemAtPath:filePath error:NULL];
        [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    }
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:data];
    [fileHandle closeFile];
    
    return filename;
}

- (NSString *)zipFileWithFilename:(NSString *)filename
{
    NSString *userDirectory = self.userDirectory;
    NSString *filePath = [userDirectory stringByAppendingPathComponent:filename];
    NSString *achiveName = [NSString stringWithFormat:@"%@.zip", filename];
    NSString *achivePath = [userDirectory stringByAppendingPathComponent:achiveName];
    
    // Create archive
    ZKDataArchive *archive = [ZKDataArchive new];
    
    if ([archive deflateFile:filePath relativeToPath:userDirectory usingResourceFork:NO] == zkSucceeded) {
        if ([archive.data writeToFile:achivePath atomically:YES]) {
            
            NSError *error = nil;
            
            // Delete file
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:filePath error:&error];
            
            return achiveName;
        }
    }
    return filename;
}

@end
