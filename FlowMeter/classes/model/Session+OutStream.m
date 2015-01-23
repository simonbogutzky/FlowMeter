//
//  Session+OutStream.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 16.07.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "Session+OutStream.h"
#import "User.h"
#import "Activity.h"

#import "SelfReport+Description.h"
#import "HeartRateRecord+Description.h"
#import "MotionRecord+Description.h"
#import "ZipKit/ZipKit.h"

@implementation Session (OutStream)

- (NSArray *)writeOut
{
    NSMutableArray *txtFileNames = [[NSMutableArray alloc] initWithCapacity:3];
    
    if ([self.selfReportCount intValue] > 0) {
        
        // Create archive data
        NSMutableData *data = [NSMutableData dataWithCapacity:0];
        
        // Append header
        [data appendData:[[self fileHeader] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        
        [data appendData:[[NSString stringWithFormat:@"%@ \n\n", NSLocalizedString(@"Flow-Messungen", @"Flow-Messungen")] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        
        // Order by timestamp
        NSArray *selfReports = [self.selfReports sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]]];
        [data appendData:[[[selfReports lastObject] csvHeader] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        
        // Append data
        for (SelfReport *selfReport in selfReports) {
            [data appendData:[[selfReport csvDescription] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        }
        
        // Write in file with filename
        NSDateFormatter *dateTimeFormatter = [[NSDateFormatter alloc] init];
        [dateTimeFormatter setDateFormat:@"yyyy-MM-dd--HH-mm-ss"];
        NSString *filename = [NSString stringWithFormat:@"%@-%@-%@-%@-questionaire.txt",[dateTimeFormatter stringFromDate:self.date], [self removeSpecialCharactersFromString:[self.user.lastName lowercaseString]], [self removeSpecialCharactersFromString:[self.user.firstName lowercaseString]], [self removeSpecialCharactersFromString:[self.activity.name lowercaseString]]];
        
        [txtFileNames addObject:[self writeData:data withFilename:filename]];
    }
    
    
    if ([self.heartRateRecords count] > 0) {
        
        // Create archive data
        NSMutableData *data = [NSMutableData dataWithCapacity:0];
        
        // Append header
        [data appendData:[[self fileHeader] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        
        [data appendData:[[NSString stringWithFormat:@"%@ \n\n", NSLocalizedString(@"HR-Messungen", @"HR-Messungen")] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        
        // Order by timestamp
        NSArray *heartRateRecords = [self.heartRateRecords sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]]];
        [data appendData:[[[heartRateRecords lastObject] csvHeader] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        
        // Append data
        for (HeartRateRecord *heartRateRecord in heartRateRecords) {
            [data appendData:[[heartRateRecord csvDescription] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        }
        
        // Write in file with filename
        NSDateFormatter *dateTimeFormatter = [[NSDateFormatter alloc] init];
        [dateTimeFormatter setDateFormat:@"yyyy-MM-dd--HH-mm-ss"];
        NSString *filename = [NSString stringWithFormat:@"%@-%@-%@-%@-heart.txt",[dateTimeFormatter stringFromDate:self.date], [self removeSpecialCharactersFromString:[self.user.lastName lowercaseString]], [self removeSpecialCharactersFromString:[self.user.firstName lowercaseString]], [self removeSpecialCharactersFromString:[self.activity.name lowercaseString]]];
        
        [txtFileNames addObject:[self writeData:data withFilename:filename]];
    }
    
    if ([self.motionRecords count] > 0) {
        
        // Create archive data
        NSMutableData *data = [NSMutableData dataWithCapacity:0];
        
        // Append header
        [data appendData:[[self fileHeader] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        
        [data appendData:[[NSString stringWithFormat:@"%@ \n\n", NSLocalizedString(@"Bewegungsdaten", @"Bewegungsdaten")] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        
        // Order by timestamp
        NSArray *motionRecords = [self.motionRecords sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]]];
        [data appendData:[[[motionRecords lastObject] csvHeader] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        
        // Append data
        for (MotionRecord *motionRecord in motionRecords) {
            [data appendData:[[motionRecord csvDescription] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        }
        
        // Write in file with filename
        NSDateFormatter *dateTimeFormatter = [[NSDateFormatter alloc] init];
        [dateTimeFormatter setDateFormat:@"yyyy-MM-dd--HH-mm-ss"];
        NSString *filename = [NSString stringWithFormat:@"%@-%@-%@-%@-motion.txt",[dateTimeFormatter stringFromDate:self.date], [self removeSpecialCharactersFromString:[self.user.lastName lowercaseString]], [self removeSpecialCharactersFromString:[self.user.firstName lowercaseString]], [self removeSpecialCharactersFromString:[self.activity.name lowercaseString]]];
        
        [txtFileNames addObject:[self writeData:data withFilename:filename]];
    }
    
    
    return txtFileNames;
}

- (NSString *)writeOutArchive
{
    NSArray *fileNames = [self writeOut];
    
    NSString *filename = [self zipFilesWithFilenames:fileNames];
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

- (NSString *)zipFilesWithFilenames:(NSArray *)filenames
{
    // Write in file with filename
    NSDateFormatter *dateTimeFormatter = [[NSDateFormatter alloc] init];
    [dateTimeFormatter setDateFormat:@"yyyy-MM-dd--HH-mm-ss"];
    NSString *filename = [NSString stringWithFormat:@"%@-%@-%@-%@",[dateTimeFormatter stringFromDate:self.date], [self removeSpecialCharactersFromString:[self.user.lastName lowercaseString]], [self removeSpecialCharactersFromString:[self.user.firstName lowercaseString]], [self removeSpecialCharactersFromString:[self.activity.name lowercaseString]]];
    
    NSString *achiveName = [NSString stringWithFormat:@"%@.zip", filename];
    NSString *achivePath = [self.userDirectory stringByAppendingPathComponent:achiveName];
    
    // Delete files
    NSMutableArray *filePaths = [[NSMutableArray alloc] initWithCapacity:filenames.count];
    for (NSString *filename in filenames) {
        [filePaths addObject:[self.userDirectory stringByAppendingPathComponent:filename]];
    }
    
    // Create archive
    ZKDataArchive *archive = [ZKDataArchive new];
    
    if ([archive deflateFiles:filePaths relativeToPath:self.userDirectory usingResourceFork:NO] == zkSucceeded) {
        if ([archive.data writeToFile:achivePath atomically:YES]) {
            
            NSError *error = nil;
            
            // Delete files
            for (NSString *filePath in filePaths) {
                NSFileManager *fileManager = [NSFileManager defaultManager];
                [fileManager removeItemAtPath:filePath error:&error];
            }
            
            return achiveName;
        }
    }
    return nil;
}

- (NSString *)fileHeader
{
    NSString *dateString = [self.dateFormatter stringFromDate:self.date];
    NSString *timeString = [self.timeFormatter stringFromDate:self.date];
    NSString *durationString = [self stringFromTimeInterval:[self.duration doubleValue]];
    
    NSMutableString *header = [NSMutableString stringWithFormat:@"%@: %@ \n%@: %@ \n%@: %@ \n%@: %@ \n%@: %@ \n\n\n", NSLocalizedString(@"Datum", @"Datum"), dateString, NSLocalizedString(@"Beginn", @"Beginn"), timeString, NSLocalizedString(@"Dauer", @"Dauer"), durationString, NSLocalizedString(@"Person", @"Person"), [NSString stringWithFormat:@"%@ %@", self.user.firstName, self.user.lastName], NSLocalizedString(@"Aktivität", @"Aktivität"), self.activity.name];
    return header;
}

- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    return dateFormatter;
}

- (NSDateFormatter *)timeFormatter
{
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterNoStyle;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return dateFormatter;
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval
{
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ldh %02ldm %02lds", (long)hours, (long)minutes, (long)seconds];
}

- (NSString *)removeSpecialCharactersFromString:(NSString *)string
{
    string = [string stringByReplacingOccurrencesOfString:@"ü" withString:@"ue"];
    string = [string stringByReplacingOccurrencesOfString:@"Ü" withString:@"Ue"];
    string = [string stringByReplacingOccurrencesOfString:@"ä" withString:@"ae"];
    string = [string stringByReplacingOccurrencesOfString:@"Ä" withString:@"Ae"];
    string = [string stringByReplacingOccurrencesOfString:@"ö" withString:@"oe"];
    string = [string stringByReplacingOccurrencesOfString:@"Ö" withString:@"Oe"];
    string = [string stringByReplacingOccurrencesOfString:@"ß" withString:@"ss"];
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    
    NSCharacterSet *notAllowedChars = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-"] invertedSet];
    return [[string componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
}

@end
