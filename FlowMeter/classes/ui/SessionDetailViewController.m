//
//  SessionDetailViewController.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 04.09.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "SessionDetailViewController.h"
#import "AppDelegate.h"
#import "User.h"
#import "Activity.h"

@interface SessionDetailViewController ()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) NSString *filename;

@end

@implementation SessionDetailViewController

#pragma mark -
#pragma mark - Getter

- (AppDelegate *)appDelegate
{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

#pragma mark -
#pragma mark - Setter

- (void)setSession:(Session *)newSession
{
    if (_session != newSession) {
        _session = newSession;
        
        // Update the view.
        [self configureView];
    }
}

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureView];
}

#pragma mark -
#pragma mark - IBActions

- (IBAction)actionTouched:(UIBarButtonItem *)sender
{
    if ([[DBSession sharedSession] isLinked]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Aktionen", @"Aktionen") delegate:self cancelButtonTitle:NSLocalizedString(@"Abbrechen", @"Abbrechen") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Auf Gerät speichern", @"Datei auf dem Gerät speichern"), NSLocalizedString(@"In die Dropbox laden", @"Datei in die Dropbox laden"), nil];
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    } else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Aktionen", @"Aktionen") delegate:self cancelButtonTitle:NSLocalizedString(@"Abbrechen", @"Abbrechen") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Auf Gerät speichern", @"Datei auf dem Gerät speichern"), nil];
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    }
}

#pragma mark -
#pragma mark - Convenient methods

- (void)configureView
{
    if (self.session) {
        self.navigationItem.title = [NSString stringWithFormat:@"%@. %@ - %@", [self.session.user.firstName substringToIndex:1], self.session.user.lastName, self.session.activity.name];
    }
}

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
#pragma mark - UIAlertSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            NSLog(@"### %@", [self.session writeOut]);
            break;
            
        case 1: {
            if ([[DBSession sharedSession] isLinked]) {
                if (self.appDelegate.reachability.isReachable) {
                    if (self.appDelegate.reachability.isReachableViaWiFi) {
                        NSString *filename = [self.session writeOutArchive];
                        [self uploadFileToDropbox:filename];
                    } else {
                        self.filename = [self.session writeOutArchive];
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
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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

@end
