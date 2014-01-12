//
//  Session.m
//  DataCollector
//
//  Created by Simon Bogutzky on 25.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "Session.h"
#import "CLLocation+Descriptions.h"
#import "Motion.h"
#import "User.h"

#import "ZipKit/ZKDefs.h"
#import "ZipKit/ZKDataArchive.h"

#define CAPACITY 6000
#define LOCATION_EXT 2

@interface Session ()

@property (nonatomic, strong, readonly) NSString *userDirectory;
@property (nonatomic, strong) NSMutableArray *motionData;
@property (nonatomic, strong) NSMutableArray *locationData;
@property (nonatomic, strong) NSMutableArray *heartRateMonitorData;

@end

@implementation Session

@dynamic identifier;
@dynamic isSynced;
@dynamic isZipped;
@dynamic timestamp;
@dynamic motionDataCount;
@dynamic locationDataCount;
@dynamic heartRateMonitorDataCount;
@dynamic user;

@synthesize motionData = _motionData;
@synthesize locationData = _locationData;
@synthesize heartRateMonitorData = _heartRateMonitorData;

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

- (NSMutableArray *)motionData {
    if (!_motionData) {
        _motionData = [NSMutableArray arrayWithCapacity:CAPACITY];
    }
    return _motionData;
}

- (NSMutableArray *)locationData {
    if (!_locationData) {
        _locationData = [NSMutableArray arrayWithCapacity:CAPACITY];
    }
    return _locationData;
}

- (NSMutableArray *)heartRateMonitorData {
    if (!_heartRateMonitorData) {
        _heartRateMonitorData = [NSMutableArray arrayWithCapacity:CAPACITY];
    }
    return _heartRateMonitorData;
}

- (void)addMotionData:(Motion *)motion
{
    [self.motionData addObject:motion];
        
    if ([self.motionData count] >= CAPACITY) {
        NSArray *motions = [NSArray arrayWithArray:self.motionData];
        self.motionData = nil;
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [self storeMotions:motions];
        });
    }
}

- (void)addLocationData:(CLLocation *)location
{
    [self.locationData addObject:location];
    
    if ([self.locationData count] >= CAPACITY) {
        NSArray *locations = [NSArray arrayWithArray:self.locationData];
        self.locationData = nil;
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [self storeLocations:locations];
        });
    }
}

- (void)addHeartRateMonitorData:(HeartRateMonitorData *)heartRateMonitorData
{
    [self.heartRateMonitorData addObject:heartRateMonitorData];
    
    if ([self.heartRateMonitorData count] >= CAPACITY) {
        NSArray *heartRates = [NSArray arrayWithArray:self.heartRateMonitorData];
        self.heartRateMonitorData = nil;
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [self storeHeartRateMonitorData:heartRates];
        });
    }
}

- (NSString *)storeMotions
{
    NSString *newFilename = nil;
//    if ([self.motionDataCount intValue] > 0 || [self.motionData count] > 0) {
        newFilename = [self storeMotions:self.motionData];
    
        if ([self.isZipped boolValue]) {
            newFilename = [self zipFileWithFilename:newFilename];
        }
    
        // Send notification
        NSDictionary *userInfo = @{@"filename": newFilename};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MotionDataAvailable" object:nil userInfo:userInfo];
//    }
    return newFilename;
}

- (NSString *)storeLocations
{
    NSString *newFilename = nil;
//    if ([self.locationDataCount intValue] > 0 || [self.locationData count] > 0) {
        newFilename = [self storeLocations:self.locationData];
    
    switch (LOCATION_EXT) {
        case 0:
            newFilename = [self writeData:[[CLLocation gpxFooter] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES] withFilename:newFilename];
            break;
            
        case 1:
            newFilename = [self writeData:[[CLLocation kmlFooter] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES] withFilename:newFilename];
            break;
        
        case 2:
            break;
            
        default:
            break;
    }
    
    
        if ([self.isZipped boolValue]) {
            newFilename = [self zipFileWithFilename:newFilename];
        }
        
        // Send notification
        NSDictionary *userInfo = @{@"filename": newFilename};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationDataAvailable" object:nil userInfo:userInfo];
//    }
    return newFilename;
}

- (NSString *)storeHeartRateMonitorData
{
    NSString *newFilename = nil;
    if ([self.heartRateMonitorDataCount intValue] > 0 || [self.heartRateMonitorData count] > 0) {
        newFilename = [self storeHeartRateMonitorData:self.heartRateMonitorData];
        
        if ([self.isZipped boolValue]) {
            newFilename = [self zipFileWithFilename:newFilename];
        }
        
        // Send notification
        NSDictionary *userInfo = @{@"filename": newFilename};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HeartRateMonitorDataAvailable" object:nil userInfo:userInfo];
    }
    return newFilename;
}

- (NSString *)storeMotions:(NSArray *)motions
{
    // Create archive data
    NSMutableData *data = [NSMutableData dataWithCapacity:0];
    
    if ([self.motionDataCount intValue] == 0) {
        [data appendData:[[Motion csvHeader] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    }
    
    self.motionDataCount = [NSNumber numberWithInt:[self.motionDataCount intValue] + [motions count]];
    
    for (Motion *motion in motions) {
        [data appendData:[[motion csvDescription] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    }
    
    NSString *filename = [NSString stringWithFormat:@"%@-%@", self.identifier, @"motion-data.csv"];
    return [self writeData:data withFilename:filename];
}

- (NSString *)storeLocations:(NSArray *)locations
{
    // Create archive data
    NSMutableData *data = [NSMutableData dataWithCapacity:0];
    
    if ([self.locationDataCount intValue] == 0) {
        
        switch (LOCATION_EXT) {
            case 0:
                [data appendData:[[CLLocation gpxHeader] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                break;
                
            case 1:
                [data appendData:[[CLLocation kmlHeader] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                break;
                
            case 2:
                [data appendData:[[CLLocation csvHeader] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                break;
                
            default:
                break;
        }
    }
    
    self.locationDataCount = [NSNumber numberWithInt:[self.locationDataCount intValue] + [locations count]];
    
    for (CLLocation *location in locations) {
        switch (LOCATION_EXT) {
            case 0:
                [data appendData:[[location gpxDescription] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                break;
                
            case 1:
                [data appendData:[[location kmlDescription] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                break;
                
            case 2:
                [data appendData:[[location csvDescription] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                break;
                
            default:
                break;
        }
    }
    
    NSString *filename = nil;
    switch (LOCATION_EXT) {
        case 0:
            filename = [NSString stringWithFormat:@"%@-%@", self.identifier, @"location-data.gpx"];;
            break;
            
        case 1:
            filename = [NSString stringWithFormat:@"%@-%@", self.identifier, @"location-data.kml"];
            break;
            
        case 2:
            filename = [NSString stringWithFormat:@"%@-%@", self.identifier, @"location-data.csv"];
            break;
            
        default:
            break;
    }
    
    return [self writeData:data withFilename:filename];
}

- (NSString *)storeHeartRateMonitorData:(NSArray *)heartRateMonitorDataArray
{
    // Create archive data
    NSMutableData *data = [NSMutableData dataWithCapacity:0];
    
    if ([self.heartRateMonitorDataCount intValue] == 0) {
        [data appendData:[@"Timestamp, RRInterval\n" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    }
    
    self.heartRateMonitorDataCount = [NSNumber numberWithInt:[self.heartRateMonitorDataCount intValue] + [heartRateMonitorDataArray count]];
    
    for (HeartRateMonitorData *heartRateMonitorData in heartRateMonitorDataArray) {
        for (NSNumber *rrInterval in heartRateMonitorData.rrIntervals) {
            [data appendData:[[NSString stringWithFormat:@"%f,%d\n", heartRateMonitorData.timestamp, [rrInterval intValue]] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        }
    }
    
    NSString *filename = [NSString stringWithFormat:@"%@-%@", self.identifier, @"rr-interval-data.csv"];
    return [self writeData:data withFilename:filename];
}

- (NSString *)writeData:(NSData *)data withFilename:(NSString *)filename
{
    NSString *filePath = [self.userDirectory stringByAppendingPathComponent:filename];
    
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
