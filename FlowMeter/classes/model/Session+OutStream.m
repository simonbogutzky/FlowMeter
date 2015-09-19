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
#import "LocationRecord+Description.h"
#import "ZipKit/ZipKit.h"
#import "DBManager.h"


@implementation Session (OutStream)

- (NSArray *)writeOut
{
    // Load object pk
    NSManagedObjectID *sessionID = self.objectID;
    int sessionPK = [[sessionID URIRepresentation].absoluteString.lastPathComponent substringFromIndex:1].intValue;
    
    // Initialize the dbManager object
    DBManager *dbManager = [[DBManager alloc] initWithDatabaseFilename:@"FlowMeter.sqlite"];
    
    // Create date prefix
    NSDateFormatter *dateTimeFormatter = [[NSDateFormatter alloc] init];
    dateTimeFormatter.dateFormat = @"yyyy-MM-dd--HH-mm-ss";
    
    // Array to store filenames
    NSMutableArray *filenames = [[NSMutableArray alloc] initWithCapacity:5];
    
    // Query self reports
    NSString *query = [NSString stringWithFormat:@"SELECT printf(\"%%.3f\",ZTIMESTAMP),printf(\"%%.3f\",ZDURATION),printf(\"%%.3f\",ZFLOW),printf(\"%%.3f\",ZFLOWSD),printf(\"%%.3f\",ZFLUENCY),printf(\"%%.3f\",ZFLUENCYSD),printf(\"%%.3f\",ZABSORPTION),printf(\"%%.3f\",ZABSORPTIONSD),printf(\"%%.3f\",ZANXIETY),printf(\"%%.3f\",ZANXIETYSD),printf(\"%%.3f\",ZFIT),printf(\"%%.3f\",ZFITSD) FROM ZSELFREPORT WHERE ZSESSION = %d ORDER BY ZTIMESTAMP ASC", sessionPK];
    NSString *filename = [NSString stringWithFormat:@"%@-%@-%@-%@-%@",[dateTimeFormatter stringFromDate:self.date], [self removeSpecialCharactersFromString:(self.user.lastName).lowercaseString], [self removeSpecialCharactersFromString:(self.user.firstName).lowercaseString], [self removeSpecialCharactersFromString:(self.activity.name).lowercaseString], @"questionaire.txt"];
    NSString *header = [NSString stringWithFormat:@"%@%@", [self fileHeader], [SelfReport csvHeader]];
    filename = [dbManager writeCSVFromQuery:query inFileWithFilename:filename andHeader:header];
    if (filename != nil) {
        [filenames addObject:filename];
    }
    
    // Query heart rate record
    query = [NSString stringWithFormat:@"SELECT printf(\"%%.3f\",ZTIMESTAMP),printf(\"%%.3f\",ZRRINTERVAL) FROM ZHEARTRATERECORD WHERE ZSESSION = %d ORDER BY ZTIMESTAMP ASC", sessionPK];
    filename = [NSString stringWithFormat:@"%@-%@-%@-%@-%@",[dateTimeFormatter stringFromDate:self.date], [self removeSpecialCharactersFromString:(self.user.lastName).lowercaseString], [self removeSpecialCharactersFromString:(self.user.firstName).lowercaseString], [self removeSpecialCharactersFromString:(self.activity.name).lowercaseString], @"heart.txt"];
    header = [NSString stringWithFormat:@"%@%@", [self fileHeader], [HeartRateRecord csvHeader]];
    filename = [dbManager writeCSVFromQuery:query inFileWithFilename:filename andHeader:header];
    if (filename != nil) {
        [filenames addObject:filename];
    }

    // Query motion records
    query = [NSString stringWithFormat:@"SELECT printf(\"%%.3f\",ZTIMESTAMP),printf(\"%%.3f\",ZUSERACCELERATIONX),printf(\"%%.3f\",ZUSERACCELERATIONY),printf(\"%%.3f\",ZUSERACCELERATIONZ),printf(\"%%.3f\",ZGRAVITYX),printf(\"%%.3f\",ZGRAVITYY),printf(\"%%.3f\",ZGRAVITYZ),printf(\"%%.3f\",ZROTATIONRATEX),printf(\"%%.3f\",ZROTATIONRATEY),printf(\"%%.3f\",ZROTATIONRATEZ,printf(\"%%.3f\",ZATTITUDEPITCH),printf(\"%%.3f\",ZATTITUDEROLL),printf(\"%%.3f\",ZATTITUDEYAW)) FROM ZMOTIONRECORD WHERE ZSESSION = %d ORDER BY ZTIMESTAMP ASC", sessionPK];
    filename = [NSString stringWithFormat:@"%@-%@-%@-%@-%@",[dateTimeFormatter stringFromDate:self.date], [self removeSpecialCharactersFromString:(self.user.lastName).lowercaseString], [self removeSpecialCharactersFromString:(self.user.firstName).lowercaseString], [self removeSpecialCharactersFromString:(self.activity.name).lowercaseString], @"motion.txt"];
    header = [NSString stringWithFormat:@"%@%@", [self fileHeader], [MotionRecord csvHeader]];
    filename = [dbManager writeCSVFromQuery:query inFileWithFilename:filename andHeader:header];
    if (filename != nil) {
        [filenames addObject:filename];
    }
    
    // Fetch location records
    filename = [self fetchAndWriteDataForEntityName:@"LocationRecord" sortDescriptorKey:@"date" filenameSuffix:@"location.txt" headerDescription:NSLocalizedString(@"Orte", @"Orte")];
    if (filename != nil) {
        [filenames addObject:filename];
    }
    
    filename = [self fetchAndWriteKMLDataForEntityName:@"LocationRecord" sortDescriptorKey:@"date" filenameSuffix:@"location.kml"];
    if (filename != nil) {
        [filenames addObject:filename];
    }

    return filenames;
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

- (NSString *)writeData:(NSData *)data withFilename:(NSString *)filename append:(BOOL)append
{
    NSString *filePath = [self.userDirectory stringByAppendingPathComponent:filename];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath])
    {
        [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    } else if(!append) {
        [fileManager removeItemAtPath:filePath error:NULL];
        [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    }
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:data];
    [fileHandle synchronizeFile];// Flush any data in memory to disk
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
    dateTimeFormatter.dateFormat = @"yyyy-MM-dd--HH-mm-ss";
    NSString *filename = [NSString stringWithFormat:@"%@-%@-%@-%@",[dateTimeFormatter stringFromDate:self.date], [self removeSpecialCharactersFromString:(self.user.lastName).lowercaseString], [self removeSpecialCharactersFromString:(self.user.firstName).lowercaseString], [self removeSpecialCharactersFromString:(self.activity.name).lowercaseString]];
    
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
    NSString *durationString = [self stringFromTimeInterval:self.duration];
    
    NSString *header = [NSMutableString stringWithFormat:@"%@: %@ \n%@: %@ \n%@: %@ \n%@: %@ \n%@: %@ \n\n\n", NSLocalizedString(@"Datum", @"Datum"), dateString, NSLocalizedString(@"Beginn", @"Beginn"), timeString, NSLocalizedString(@"Dauer", @"Dauer"), durationString, NSLocalizedString(@"Person", @"Person"), [NSString stringWithFormat:@"%@ %@", self.user.firstName, self.user.lastName], NSLocalizedString(@"Aktivität", @"Aktivität"), self.activity.name];
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
    
    NSCharacterSet *notAllowedChars = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-"].invertedSet;
    return [[string componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
}

- (NSString *)fetchAndWriteDataForEntityName:(NSString *)entityName sortDescriptorKey:(NSString *)sortDescriptorKey filenameSuffix:(NSString *)filenameSuffix headerDescription:(NSString *)headerDescription
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = entity;
    
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"session == %@", self];
    fetchRequest.predicate = predicate;
    
    NSError *error = nil;
    NSInteger fetchRequestCount = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
    
    if (fetchRequestCount > 0) {
        
        // Create file name
        NSDateFormatter *dateTimeFormatter = [[NSDateFormatter alloc] init];
        dateTimeFormatter.dateFormat = @"yyyy-MM-dd--HH-mm-ss";
        NSString *filename = [NSString stringWithFormat:@"%@-%@-%@-%@-%@",[dateTimeFormatter stringFromDate:self.date], [self removeSpecialCharactersFromString:(self.user.lastName).lowercaseString], [self removeSpecialCharactersFromString:(self.user.firstName).lowercaseString], [self removeSpecialCharactersFromString:(self.activity.name).lowercaseString], filenameSuffix];
        
        // Create header data object
        NSMutableData *header = [NSMutableData dataWithCapacity:0];
        [header appendData:[[self fileHeader] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        [header appendData:[[NSString stringWithFormat:@"%@ \n\n", headerDescription] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        [self writeData:header withFilename:filename append:NO];
        
        // Fetch data sequential
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortDescriptorKey ascending:YES];
        fetchRequest.sortDescriptors = @[sortDescriptor];
        
        NSInteger fetchLimit = 10000;
        NSInteger fetchOffset = 0;
        BOOL appendCSVHeader = YES;
        while (fetchOffset < fetchRequestCount) {
            //@autoreleasepool {
                NSMutableData *data = [NSMutableData dataWithCapacity:0];
                
                fetchRequest.fetchLimit = fetchLimit;
                fetchRequest.fetchOffset = fetchOffset;
                NSError *error = nil;
                NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
                
                // Loop through all records
                for (id fetchedObject in fetchedObjects) {
                    if (appendCSVHeader) {
                        [data appendData:[[fetchedObject csvHeader] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                        appendCSVHeader = NO;
                    }
                    
                    // Append data
                    [data appendData:[[fetchedObject csvDescription] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                }
                fetchOffset += fetchLimit;
                [self writeData:data withFilename:filename append:YES];
                data = nil;
                fetchedObjects = nil;
          
            //}
        }
        return filename;
    }
    return nil;
}

- (NSString *)fetchAndWriteKMLDataForEntityName:(NSString *)entityName sortDescriptorKey:(NSString *)sortDescriptorKey filenameSuffix:(NSString *)filenameSuffix
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = entity;
    
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"session == %@", self];
    fetchRequest.predicate = predicate;
    
    NSError *error = nil;
    NSInteger fetchRequestCount = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
    
    if (fetchRequestCount > 0) {
        
        // Create file name
        NSDateFormatter *dateTimeFormatter = [[NSDateFormatter alloc] init];
        dateTimeFormatter.dateFormat = @"yyyy-MM-dd--HH-mm-ss";
        NSString *filename = [NSString stringWithFormat:@"%@-%@-%@-%@-%@",[dateTimeFormatter stringFromDate:self.date], [self removeSpecialCharactersFromString:(self.user.lastName).lowercaseString], [self removeSpecialCharactersFromString:(self.user.firstName).lowercaseString], [self removeSpecialCharactersFromString:(self.activity.name).lowercaseString], filenameSuffix];
        
        // Fetch data sequential
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortDescriptorKey ascending:YES];
        fetchRequest.sortDescriptors = @[sortDescriptor];
        
        NSInteger fetchLimit = 10000;
        NSInteger fetchOffset = 0;
        BOOL appendKMLHeader = YES;
        while (fetchOffset < fetchRequestCount) {
            //@autoreleasepool {
                NSMutableData *data = [NSMutableData dataWithCapacity:0];
                fetchRequest.fetchLimit = fetchLimit;
                fetchRequest.fetchOffset = fetchOffset;
                NSError *error = nil;
                NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
                
                // Loop through all records
                for (id fetchedObject in fetchedObjects) {
                    if (appendKMLHeader) {
                        [data appendData:[[fetchedObject kmlHeader] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                        [data appendData:[[fetchedObject kmlTimelineHeader] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                        
                        appendKMLHeader = NO;
                    }
                    
                    // Append data
                    [data appendData:[[fetchedObject kmlTimelineDescription] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                }
                fetchOffset += fetchLimit;
                if (fetchOffset > fetchRequestCount) {
                    [data appendData:[[fetchedObjects.lastObject kmlTimelineFooter] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                }
                [self writeData:data withFilename:filename append:YES];
                data = nil;
                fetchedObjects = nil;
            //}
        }
        
        // Fetch data sequential
        fetchLimit = 10000;
        fetchOffset = 0;
        appendKMLHeader = YES;
        while (fetchOffset < fetchRequestCount) {
            @autoreleasepool {
                NSMutableData *data = [NSMutableData dataWithCapacity:0];
                fetchRequest.fetchLimit = fetchLimit;
                fetchRequest.fetchOffset = fetchOffset;
                NSError *error = nil;
                NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
                
                // Loop through all records
                for (id fetchedObject in fetchedObjects) {
                    if (appendKMLHeader) {
                        [data appendData:[[fetchedObject kmlPathHeader] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                        appendKMLHeader = NO;
                    }
                    
                    // Append data
                    [data appendData:[[fetchedObject kmlPathDescription] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                }
                fetchOffset += fetchLimit;
                if (fetchOffset > fetchRequestCount) {
                    [data appendData:[[fetchedObjects.lastObject kmlPathFooter] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                    [data appendData:[[fetchedObjects.lastObject kmlFooter] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                }
                [self writeData:data withFilename:filename append:YES];
                data = nil;
                fetchedObjects = nil;
            }
        }

        return filename;
    }
    return nil;
}

@end
