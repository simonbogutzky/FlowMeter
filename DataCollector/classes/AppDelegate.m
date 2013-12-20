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


@interface AppDelegate ()
{
    CMMotionManager *_motionManager;
    CLLocationManager *_locationManager;
    DBRestClient *_dbRestClient;
}
@end

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

#pragma mark -
#pragma mark - Singletons

- (CMMotionManager *)sharedMotionManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _motionManager = [[CMMotionManager alloc] init];
    });
    return _motionManager;
}

- (CLLocationManager *)sharedLocationManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _locationManager = [[CLLocationManager alloc] init];
    });
    return _locationManager;
}

- (DBRestClient *)sharedDbRestClient
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dbRestClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _dbRestClient.delegate = self;
    });
    return _dbRestClient;
}

#pragma mark -
#pragma mark - UIApplicationDelegate implementation

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    //Testflight
//#define TESTING 1
//#ifdef TESTING
//    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
//#endif
//    
//    // TestFlight takeoff
//    [TestFlight takeOff:@"9a7d3926-e38a-4359-85f6-717248228a37"];
    
    // Dropbox
    DBSession *dbSession = [[DBSession alloc] initWithAppKey:@"tvd64fwxro7ck60" appSecret:@"2azrb93xdsddgx2" root:kDBRootAppFolder];
    [DBSession setSharedSession:dbSession];
    
    // Try to sync unsync sessions
    [self syncSessions];
    
    // Allocate a reachability object and register notifier
    _reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
    [_reachability startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    // Observe notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:@"MotionDataAvailable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:@"LocationDataAvailable" object:nil];
    
    // Audio Session with mixing    
//    NSError *setCategoryErr = nil;
//    NSError *activationErr  = nil;
//    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error:&setCategoryErr];
//    [[AVAudioSession sharedInstance] setActive:YES error:&activationErr];
    
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
        
        NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        if ([session.motionRecordsCount intValue] != 0) {
            NSString *filename = [NSString stringWithFormat:@"%@-motion-data.csv.zip", [session valueForKey:@"filename"]];
            NSString *localPath = [rootPath stringByAppendingPathComponent:[session valueForKey:@"filepath"]];
            localPath = [localPath stringByAppendingPathComponent:filename];
            [self uploadFile:filename localPath:localPath];
        }
        
        if ([session.locationRecordsCount intValue] != 0) {
            NSString *filename = [NSString stringWithFormat:@"%@-location-data.kml.zip", [session valueForKey:@"filename"]];
            NSString *localPath = [rootPath stringByAppendingPathComponent:[session valueForKey:@"filepath"]];
            localPath = [localPath stringByAppendingPathComponent:filename];
            [self uploadFile:filename localPath:localPath];
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

- (void)setSessionSyncedByFilename:(NSString *)filename
{
    NSManagedObject *object = [self fetchUnsyncedSessionByFilename:filename];
    if (object != nil) {
        [object setValue:@1 forKey:@"isSynced"];
        [self saveContext];
    }
}

- (NSManagedObject *)fetchUnsyncedSessionByFilename:(NSString *)filename
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *filenamePredicate = [NSPredicate predicateWithFormat:@"filename == %@ && isSynced == %@", filename, @0];
    [fetchRequest setPredicate:filenamePredicate];
    
    NSError *error = nil;
    NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy];
    if (mutableFetchResults == nil || [mutableFetchResults count] == 0) {
        return nil;
    }
    return mutableFetchResults[0];
}

- (void)dataAvailable:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSString *localPath = userInfo[@"localPath"];
    NSString *filename = userInfo[@"filename"];
    
    NSLog(@"' %@", localPath);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self uploadFile:filename localPath:localPath];
    });
}

#pragma mark -
#pragma mark - Dropbox convenient methods

- (void)uploadFile:(NSString *)filename localPath:(NSString *)localPath
{
    if (_reachability.isReachableViaWiFi && [[DBSession sharedSession] isLinked]) {
        NSPredicate *isActivePredicate = [NSPredicate predicateWithFormat:@"isActive == %@", @1];
        User *user = [self activeUserWithPredicate:isActivePredicate];
        
        NSString *destDir = [NSString stringWithFormat:@"/%@", user.username];
        [[self sharedDbRestClient] uploadFile:filename toPath:destDir withParentRev:nil fromPath:localPath];
    }
}

#pragma mark -
#pragma mark - DBRestClientDelegate methods

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata
{
    NSLog(@"# File uploaded successfully to path: %@", metadata.path);
    NSError *error = nil;
   
    // Delete zip file
    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *localPath = [rootPath stringByAppendingPathComponent:metadata.filename];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:localPath error:&error];
    
    // Set data entry synced
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@" \\(.+\\)" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *filename = [regex stringByReplacingMatchesInString:metadata.filename options:0 range:NSMakeRange(0, [metadata.filename length]) withTemplate:@""];
    regex = [NSRegularExpression regularExpressionWithPattern:@"(-motion-data|-location-data).(csv|kml).zip" options:NSRegularExpressionCaseInsensitive error:&error];
    filename = [regex stringByReplacingMatchesInString:filename options:0 range:NSMakeRange(0, [filename length]) withTemplate:@""];
    NSLog(@"# Sync session with filename: %@", filename);
    [self setSessionSyncedByFilename:filename];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    NSLog(@"# File upload failed with error - %@", error);
}

#pragma mark -
#pragma mark - DBRestClientDelegate methods

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@"# event code: %d", eventCode);
}

#pragma mark -
#pragma mark - Convient methods

- (User *)activeUserWithPredicate:(NSPredicate *)predicate
{
    User *user = nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setPredicate:predicate];
    
    NSArray *fetchedObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects == nil) {
        // Handle the error.
    }
    
    if ([fetchedObjects count] == 0) {
        user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:_managedObjectContext];
    } else {
        user = fetchedObjects[0];
    }
    
    return user;
}

@end
