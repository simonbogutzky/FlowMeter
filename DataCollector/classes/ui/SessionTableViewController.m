//
//  SessionTableViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 23.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "SessionTableViewController.h"
#import "AppDelegate.h"
#import "Session+OutStream.h"
#import "SelfReport+Description.h"

@interface SessionTableViewController () {
    NSFetchedResultsController *_fetchedResultsController;
}

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) Session *selectedSession;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) NSString *filename;
@end

@implementation SessionTableViewController

#pragma mark -
#pragma mark - Getter

- (AppDelegate *)appDelegate
{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSError *error = nil;
        if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedSession = [_fetchedResultsController objectAtIndexPath:indexPath];
    if ([[DBSession sharedSession] isLinked]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Optionen", @"Optionen") delegate:self cancelButtonTitle:NSLocalizedString(@"Abbrechen", @"Abbrechen") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Auf Gerät speichern", @"Datei auf dem Gerät speichern"), NSLocalizedString(@"In die Dropbox laden", @"Datei in die Dropbox laden"), nil];
        [actionSheet showInView:self.view];
    } else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Optionen", @"Optionen") delegate:self cancelButtonTitle:NSLocalizedString(@"Abbrechen", @"Abbrechen") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Auf Gerät speichern", @"Datei auf dem Gerät speichern"), nil];
        [actionSheet showInView:self.view];
    }
    
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.appDelegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.appDelegate.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)fetchedResultsChangeType
{
    switch(fetchedResultsChangeType) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
 // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
 {
 // In the simplest, most efficient, case, reload the table view.
 [self.tableView reloadData];
 }
 */

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Session *session = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:NSLocalizedString(@"dd.MM.yy", @"dd.MM.yy")];
    NSString *dateString = [dateFormatter stringFromDate:session.date];
    [dateFormatter setDateFormat:NSLocalizedString(@"HH:mm", @"HH:mm")];
    NSString *timeString = [dateFormatter stringFromDate:session.date];
    cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ %@ Uhr", @"%@ %@ Uhr"), dateString, timeString];
//    cell.accessoryType = [session.selfReportsAreSynced boolValue] && [session.heartRateMonitorDataIsSynced boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

#pragma mark -
#pragma mark - UIAlertSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            NSLog(@"### Anzahl der Self-reports: %lu", (unsigned long)[self.selectedSession.selfReports count]);
            NSLog(@"### %@", [self.selectedSession writeOutSelfReports]);
            break;
            
        case 1: {
            if ([[DBSession sharedSession] isLinked]) {
                NSLog(@"### Anzahl der Self-reports: %lu", (unsigned long)[self.selectedSession.selfReports count]);
                if (self.appDelegate.reachability.isReachable) {
                    if (self.appDelegate.reachability.isReachableViaWiFi) {
                        NSString *filename = [self.selectedSession zipSelfReports];
                        [self uploadFileToDropbox:filename];
                    } else {
                        self.filename = [self.selectedSession zipSelfReports];
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information", @"Information") message:NSLocalizedString(@"Du hast zurzeit keine WLAN Internetverbindung. Möchtest du trotzdem die Daten hochladen?", @"Du hast zurzeit keine WLAN Internetverbindung. Möchtest du trotzdem die Daten hochladen?") delegate:self cancelButtonTitle:NSLocalizedString(@"Abbrechen", @"Abbrechen") otherButtonTitles:NSLocalizedString(@"Ok", @"Ok"), nil];
                        [alertView show];
                    }
                } else {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information", @"Information") message:NSLocalizedString(@"Du hast zurzeit keine Internetverbindung", @"Du hast zurzeit keine Internetverbindung") delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok") otherButtonTitles:nil];
                    [alertView show];
                }
             }
        }
        break;
            
        default:
            break;
    }
}

#pragma mark -
#pragma mark - Dropbox convenient methods

- (void)uploadFileToDropbox:(NSString *)filename
{
    self.filename = filename;
    NSString *destinationPath = @"/";
    self.appDelegate.dbRestClient.delegate = self;
    [self.appDelegate.dbRestClient loadMetadata:[NSString stringWithFormat:@"%@%@", destinationPath, filename]];
}

- (void)uploadFileToDropbox:(NSString *)filename withRev:(NSString *)rev
{
    
    NSString *sourcePath = [self.appDelegate.userDirectory stringByAppendingPathComponent:filename];
    NSString *destinationPath = @"/";
    [self.appDelegate.dbRestClient uploadFile:filename toPath:destinationPath withParentRev:rev fromPath:sourcePath];
        
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
    // Initialize MBProgressHUD - AnnularDeterminate
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.delegate = self;
    self.hud.mode = MBProgressHUDModeAnnularDeterminate;
}

#pragma mark -
#pragma mark - DBRestClientDelegate implementation

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata
{
    NSLog(@"# File uploaded successfully to path: %@", metadata.path);
    
    NSError *error = nil;
    
    // Delete file
    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *archivePath = [rootPath stringByAppendingPathComponent:metadata.filename];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:archivePath error:&error];
    
    // Change MBProgressHUD mode - CustomView
    self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checkmark"]];
    self.hud.mode = MBProgressHUDModeCustomView;
    [self.hud hide:YES afterDelay:2];
    
    self.filename = nil;
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    NSLog(@"# File upload failed with error - %@", error);
    [self.hud hide:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString*)destPath from:(NSString*)srcPath
{
    NSLog(@"# Progress - %f", progress);
    self.hud.progress = progress;
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@"# event code: %u", eventCode);
}

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    [self uploadFileToDropbox:metadata.filename withRev:metadata.rev];
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
    switch (error.code) {
        case 404:
            [self uploadFileToDropbox:self.filename withRev:nil];
            break;
            
        default:
            NSLog(@"# Load meta failed with error - %@", error);
            break;
    }
}

#pragma mark -
#pragma mark - UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 1:
            [self uploadFileToDropbox:self.filename];
            break;
            
        default: {
            
            NSError *error = nil;
            
            // Delete file
            NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
            NSString *archivePath = [rootPath stringByAppendingPathComponent:self.filename];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:archivePath error:&error];
            }
            
            break;
    }
    self.filename = nil;
}

@end
