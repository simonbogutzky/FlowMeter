//
//  AppDelegate.m
//  DataCollector
//
//  Created by Simon Bogutzky on 16.01.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "AppDelegate.h"
#import "Session.h"
#import "User.h"
#import "LikertScaleViewController.h"

@interface AppDelegate ()
@property (strong, nonatomic, readonly) DBRestClient *dbRestClient;
@property (strong, nonatomic, readonly) Reachability *reachability;
@end

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize motionManager = _motionManager;
@synthesize locationManager = _locationManager;
@synthesize heartRateMonitorManager = _heartRateMonitorManager;
@synthesize dbRestClient = _dbRestClient;

#pragma mark -
#pragma mark - Getter (Lazy-Instantiation)

- (CMMotionManager *)motionManager
{
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    return _motionManager;
}

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    return _locationManager;
}

- (HeartRateMonitorManager *)heartRateMonitorManager {
    if (!_heartRateMonitorManager) {
        _heartRateMonitorManager = [[HeartRateMonitorManager alloc] init];
    }
    return _heartRateMonitorManager;
}

- (DBRestClient *)dbRestClient
{
    if (!_dbRestClient) {
        _dbRestClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _dbRestClient.delegate = self;
    }
    return _dbRestClient;
}

#pragma mark -
#pragma mark - UIApplicationDelegate implementation

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    
    NSLog(@"# HeartRateMonitor State: %ld", self.heartRateMonitorManager.state);
    
    // TestFlight takeoff
//    [TestFlight takeOff:@"f73deffe-10d8-4f69-a5dd-096197db5a7e"];
    
    // Dropbox
    DBSession *dbSession = [[DBSession alloc] initWithAppKey:@"tvd64fwxro7ck60" appSecret:@"2azrb93xdsddgx2" root:kDBRootAppFolder];
//    DBSession *dbSession = [[DBSession alloc] initWithAppKey:@"e0j2mxziwyk196j" appSecret:@"9n3zo6omw06kgd2" root:kDBRootAppFolder];
    [DBSession setSharedSession:dbSession];
    
    // Allocate a reachability object and register notifier
    _reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
    [_reachability startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    // Observe notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:@"MotionDataAvailable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:@"HeartRateMonitorDataAvailable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:@"LocationDataAvailable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:@"SubjectiveResponseDataAvailable" object:nil];
    
    // Audio Session with mixing
    NSError *setCategoryErr = nil;
    NSError *activationErr  = nil;
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error:&setCategoryErr];
    [[AVAudioSession sharedInstance] setActive:YES error:&activationErr];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DataCollector" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"DataCollector.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully with Dropbox");
            // At this point you can start making API calls
        
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DB_CONNECTION_CANCELLED object:self];
        }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
}

#pragma mark - 
#pragma mark - Data sync

- (void)reachabilityChanged:(NSNotification *)notification
{
    if(_reachability.isReachableViaWiFi && [[DBSession sharedSession] isLinked]) {
        [self syncSessions];
    }
}

- (void)syncSessions
{
    NSMutableArray *objects = [self fetchUnsyncSessions];
    for (Session *session in objects) {
        
        BOOL isZipped = [[session valueForKey:@"isZipped"] boolValue];
        
        if ([session.motionDataCount intValue] != 0 && ![session.motionDataIsSynced boolValue]) {
            NSString *filename = [NSString stringWithFormat:@"%@-motion-data.csv%@", [session valueForKey:@"identifier"], isZipped ? @".zip" : @""];
            [self uploadFile:filename];
        }
        
        if ([session.locationDataCount intValue] != 0 && ![session.locationDataIsSynced boolValue]) {
            NSString *filename = [NSString stringWithFormat:@"%@-location-data.csv%@", [session valueForKey:@"identifier"], isZipped ? @".zip" : @""];
            [self uploadFile:filename];
        }
        
        if ([session.heartRateMonitorDataCount intValue] != 0 && ![session.heartRateMonitorDataIsSynced boolValue]) {
            NSString *filename = [NSString stringWithFormat:@"%@-rr-interval-data.csv%@", [session valueForKey:@"identifier"], isZipped ? @".zip" : @""];
            [self uploadFile:filename];
        }
        
        if ([session.subjectiveResponseDataCount intValue] != 0 && ![session.subjectiveResponseDataIsSynced boolValue]) {
            NSString *filename = [NSString stringWithFormat:@"%@-subjective-response-data.csv%@", [session valueForKey:@"identifier"], isZipped ? @".zip" : @""];
            [self uploadFile:filename];
        }
    }
}

- (NSMutableArray *)fetchUnsyncSessions
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
   
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSPredicate *isNotSyncedPredicate = [NSPredicate predicateWithFormat:@"isSynced == %@", @0];
    [fetchRequest setPredicate:isNotSyncedPredicate];
    
    NSError *error = nil;
    NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy];
    if (mutableFetchResults == nil) {
        return nil;
    }
    return mutableFetchResults;
}

- (Session *)setDataSyncedByIdentifier:(NSString *)identifier andKey:(NSString *)key
{
    Session *session = (Session *)[self fetchUnsyncedSessionByIdentifier:identifier];
    if (session != nil) {
        [session setValue:@1 forKey:key];
    }
    return session;
}

- (void)syncSession:(Session *)session
{
    if (session != nil) {
        [session setValue:@1 forKey:@"isSynced"];
    }
}

- (NSManagedObject *)fetchUnsyncedSessionByIdentifier:(NSString *)identifier
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *identifierPredicate = [NSPredicate predicateWithFormat:@"identifier == %@ && isSynced == %@", identifier, @0];
    [fetchRequest setPredicate:identifierPredicate];
    
    NSError *error = nil;
    NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy];
    if (mutableFetchResults == nil || [mutableFetchResults count] == 0) {
        return nil;
    }
    return mutableFetchResults[0];
}

- (void)dataAvailable:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self saveContext];
        NSDictionary *userInfo = [notification userInfo];
        NSString *filename = userInfo[@"filename"];
        [self uploadFile:filename];
    });
}

#pragma mark -
#pragma mark - Dropbox convenient methods

- (void)uploadFile:(NSString *)filename
{
    if (_reachability.isReachableViaWiFi && [[DBSession sharedSession] isLinked]) {
        NSPredicate *isActivePredicate = [NSPredicate predicateWithFormat:@"isActive == %@", @1];
        User *user = [self activeUserWithPredicate:isActivePredicate];
        
        NSString *sourcePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        sourcePath = [sourcePath stringByAppendingPathComponent:user.username];
        sourcePath = [sourcePath stringByAppendingPathComponent:filename];
        
        NSString *destinationPath = [NSString stringWithFormat:@"/%@", user.username];
        [self.dbRestClient uploadFile:filename toPath:destinationPath withParentRev:nil fromPath:sourcePath];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
}

#pragma mark -
#pragma mark - DBRestClientDelegate methods

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata
{
    NSLog(@"# File uploaded successfully to path: %@", metadata.path);
    
    NSPredicate *isActivePredicate = [NSPredicate predicateWithFormat:@"isActive == %@", @1];
    User *user = [self activeUserWithPredicate:isActivePredicate];
    
    NSError *error = nil;
   
    // Delete file
    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    rootPath = [rootPath stringByAppendingPathComponent:user.username];
    NSString *archivePath = [rootPath stringByAppendingPathComponent:metadata.filename];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:archivePath error:&error];
    
    
    // Set data entry synced
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@" \\(.+\\)" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *temp = [regex stringByReplacingMatchesInString:metadata.filename options:0 range:NSMakeRange(0, [metadata.filename length]) withTemplate:@""];
    
    regex = [NSRegularExpression regularExpressionWithPattern:@"(-motion-data|-location-data|-rr-interval-data|-subjective-response-data).(csv|gpx|kml)(.zip)?" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *identifier = [regex stringByReplacingMatchesInString:temp options:0 range:NSMakeRange(0, [temp length]) withTemplate:@""];
    
    Session *session = nil;
    regex = [NSRegularExpression regularExpressionWithPattern:@"-motion-data.csv(.zip)?" options:NSRegularExpressionCaseInsensitive error:&error];
    if ([regex numberOfMatchesInString:temp options:0 range:NSMakeRange(0, [temp length])] > 0) {
        session = [self setDataSyncedByIdentifier:identifier andKey:@"motionDataIsSynced"];
    }
    
    regex = [NSRegularExpression regularExpressionWithPattern:@"-location-data.(csv|gpx|kml)(.zip)?" options:NSRegularExpressionCaseInsensitive error:&error];
    if ([regex numberOfMatchesInString:temp options:0 range:NSMakeRange(0, [temp length])] > 0) {
        session = [self setDataSyncedByIdentifier:identifier andKey:@"locationDataIsSynced"];
    }
    
    regex = [NSRegularExpression regularExpressionWithPattern:@"-rr-interval-data.csv(.zip)?" options:NSRegularExpressionCaseInsensitive error:&error];
    if ([regex numberOfMatchesInString:temp options:0 range:NSMakeRange(0, [temp length])] > 0) {
        session = [self setDataSyncedByIdentifier:identifier andKey:@"heartRateMonitorDataIsSynced"];
    }
    
    regex = [NSRegularExpression regularExpressionWithPattern:@"-subjective-response-data.csv(.zip)?" options:NSRegularExpressionCaseInsensitive error:&error];
    if ([regex numberOfMatchesInString:temp options:0 range:NSMakeRange(0, [temp length])] > 0) {
        session = [self setDataSyncedByIdentifier:identifier andKey:@"subjectiveResponseDataIsSynced"];
    }
    
    if ([session.motionDataIsSynced boolValue] && [session.locationDataIsSynced boolValue] && [session.heartRateMonitorDataIsSynced boolValue] && [session.subjectiveResponseDataIsSynced boolValue]) {
        NSLog(@"# Sync session with identifier: %@", identifier);
        [self syncSession:session];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
    
    [self saveContext];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    NSLog(@"# File upload failed with error - %@", error);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString*)destPath from:(NSString*)srcPath
{
    NSLog(@"# Progress - %f", progress);
}

#pragma mark -
#pragma mark - DBRestClientDelegate methods

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@"# event code: %lu", eventCode);
}

#pragma mark -
#pragma mark - Convient methods

- (User *)activeUserWithPredicate:(NSPredicate *)predicate
{
    User *user = nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setPredicate:predicate];
    
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects == nil) {
        // Handle the error.
    }
    
    if ([fetchedObjects count] == 0) {
        user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:self.managedObjectContext];
    } else {
        user = fetchedObjects[0];
    }
    
    return user;
}

@end
