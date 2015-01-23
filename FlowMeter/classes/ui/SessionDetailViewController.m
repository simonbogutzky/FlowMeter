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
#import "BEMSimpleLineGraphView.h"
#import "SelfReport+Description.h"
#import "PropertyTableViewCell.h"

@interface SessionDetailViewController () <BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) NSString *filename;
@property (strong, nonatomic) NSArray *dataSrc;

@property (weak, nonatomic) IBOutlet UILabel *labelDate;
@property (weak, nonatomic) IBOutlet UILabel *labelDisplayedProperty;
@property (weak, nonatomic) IBOutlet UILabel *labelDisplayedPropertyAverage;
@property (weak, nonatomic) IBOutlet UILabel *labelSelfReportCount;
@property (weak, nonatomic) IBOutlet UILabel *labelAverageFlow;
@property (weak, nonatomic) IBOutlet UILabel *labelDuration;
@property (weak, nonatomic) IBOutlet UILabel *labelAverageHeartrate;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet BEMSimpleLineGraphView *lineGraphView;
@property (strong, nonatomic) NSMutableArray *yValues;
@property (strong, nonatomic) NSMutableArray *xLabels;

@end

@implementation SessionDetailViewController

#pragma mark -
#pragma mark - Getter

- (AppDelegate *)appDelegate
{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (NSArray *)dataSrc
{
    if (_dataSrc == nil) {
        
        if ([self.session.averageHeartrate doubleValue] != 0) {
            _dataSrc = @[
                         [@{kTitleKey:NSLocalizedString(@"Flow", @"Name des Gesamt Faktors Flow in der Tabelle"), kEntityKey:@"selfReports", kValueKey:@"flow"} mutableCopy],
                         [@{kTitleKey:NSLocalizedString(@"Verlauf", @"Name des Faktors I Verlauf in der Tabelle"), kEntityKey:@"selfReports", kValueKey:@"fluency"} mutableCopy],
                         [@{kTitleKey:NSLocalizedString(@"Absorbiertheit", @"Name des Faktors II Absorbiertheit in der Tabelle"), kEntityKey:@"selfReports", kValueKey:@"absorption"} mutableCopy],
                         [@{kTitleKey:NSLocalizedString(@"Besorgnis", @"Name des Faktors III Besorgnis in der Tabelle"), kEntityKey:@"selfReports", kValueKey:@"anxiety"} mutableCopy],
                         [@{kTitleKey:NSLocalizedString(@"Passung", @"Name des Faktors Passung in der Tabelle"), kEntityKey:@"selfReports", kValueKey:@"fit"} mutableCopy],
                         [@{kTitleKey:NSLocalizedString(@"Herzrate", @"Herzrate in der Tabelle"), kEntityKey:@"heartRateRecords", kValueKey:@"heartRate"} mutableCopy]
                         ];
        } else {
            _dataSrc = @[
                         [@{kTitleKey:NSLocalizedString(@"Flow", @"Name des Gesamt Faktors Flow in der Tabelle"), kEntityKey:@"selfReports", kValueKey:@"flow"} mutableCopy],
                         [@{kTitleKey:NSLocalizedString(@"Verlauf", @"Name des Faktors I Verlauf in der Tabelle"), kEntityKey:@"selfReports", kValueKey:@"fluency"} mutableCopy],
                         [@{kTitleKey:NSLocalizedString(@"Absorbiertheit", @"Name des Faktors II Absorbiertheit in der Tabelle"), kEntityKey:@"selfReports", kValueKey:@"absorption"} mutableCopy],
                         [@{kTitleKey:NSLocalizedString(@"Besorgnis", @"Name des Faktors III Besorgnis in der Tabelle"), kEntityKey:@"selfReports", kValueKey:@"anxiety"} mutableCopy],
                         [@{kTitleKey:NSLocalizedString(@"Passung", @"Name des Faktors Passung in der Tabelle"), kEntityKey:@"selfReports", kValueKey:@"fit"} mutableCopy]
                         ];
        }
        
    }
    return _dataSrc;
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
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewRowAnimationTop];
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
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterLongStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
        NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
        timeFormatter.dateStyle = NSDateFormatterNoStyle;
        timeFormatter.timeStyle = NSDateFormatterShortStyle;
        
        self.labelDate.text = [NSString stringWithFormat:@"%@ - %@", [dateFormatter stringFromDate:self.session.date], [timeFormatter stringFromDate:self.session.date]];
        
        NSIndexPath *selectedIndexPath = self.tableView.indexPathsForSelectedRows[0];
        self.labelDisplayedProperty.text = [self.dataSrc[selectedIndexPath.row] objectForKey:kTitleKey];
        NSNumber *number = [self.session valueForKey:[NSString stringWithFormat:@"%@%@", @"average", [[self.dataSrc[selectedIndexPath.row] objectForKey:kValueKey] capitalizedString]]];
        self.labelDisplayedPropertyAverage.text = [NSString stringWithFormat:@"%.1f ⍉", [number doubleValue]];
        
        
        self.labelSelfReportCount.text = [NSString stringWithFormat:@"%d", [self.session.selfReportCount intValue]];
        self.labelAverageFlow.text = [NSString stringWithFormat:@"%.1f ⍉", [self.session.averageFlow doubleValue]];
        self.labelDuration.text = [self stringFromTimeInterval:[self.session.duration doubleValue]];
        self.labelAverageHeartrate.text = [NSString stringWithFormat:@"%d ⍉", [self.session.averageHeartrate intValue]];
        
        NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
        NSArray *managedObjects = [[self.session valueForKey:[self.dataSrc[selectedIndexPath.row] objectForKey:kEntityKey]] sortedArrayUsingDescriptors:@[timestampDescriptor]];
        
        if ([@"heartRate" isEqualToString:[self.dataSrc[selectedIndexPath.row] objectForKey:kValueKey]]) {
            
            self.yValues = [@[] mutableCopy];
            self.xLabels = [@[] mutableCopy];
            
            NSTimeInterval timestamp = [[managedObjects[0] valueForKey:@"timestamp"] doubleValue];
            NSTimeInterval nextTimestamp = timestamp + 60;
            
            NSMutableArray *yValues = [@[] mutableCopy];
            
            for (NSManagedObject *managedObject in managedObjects) {
                
                timestamp  = [[managedObject valueForKey:@"timestamp"] doubleValue];
                [yValues addObject:[managedObject valueForKey:[self.dataSrc[selectedIndexPath.row] objectForKey:kValueKey]]];
                
                if (nextTimestamp <= timestamp) {
                    
                    NSNumber *yValue = [NSNumber numberWithInt:0];
                    if (yValues.count > 0) {
                        NSExpression *expression = [NSExpression expressionForFunction:@"median:" arguments:@[[NSExpression expressionForConstantValue:yValues]]];
                        yValue = [expression expressionValueWithObject:nil context:nil];
                    }
                    [self.yValues addObject:yValue];
                    [self.xLabels addObject:[NSNumber numberWithDouble:timestamp]];
                    
                    yValues = [@[] mutableCopy];
                    nextTimestamp = timestamp + 60;
                }
            }
        } else {
            self.yValues = [NSMutableArray arrayWithCapacity:[managedObjects count]];
            self.xLabels = [NSMutableArray arrayWithCapacity:[managedObjects count]];
            for (NSManagedObject *managedObject in managedObjects) {
                [self.yValues addObject:[managedObject valueForKey:[self.dataSrc[selectedIndexPath.row] objectForKey:kValueKey]]];
                [self.xLabels addObject:[managedObject valueForKey:@"timestamp"]];
            }
        }
        
        // Customization of the graph
        UIColor *color = self.appDelegate.colors[selectedIndexPath.row % (self.appDelegate.colors.count + 1)];
        self.lineGraphView.colorLine = color;
        self.lineGraphView.colorPoint = color;
        
        NSString *propertyName = [self.dataSrc[selectedIndexPath.row] objectForKey:kValueKey];
        if (![@"heartRate" isEqualToString:propertyName]) {
            self.lineGraphView.yAxisMin = [NSNumber numberWithInt:2];
            self.lineGraphView.yAxisMax = [NSNumber numberWithInt:7];
            self.lineGraphView.paddingMax = 40;
            self.lineGraphView.enableBezierCurve = NO;
        } else {
            self.lineGraphView.yAxisMin = nil;
            self.lineGraphView.yAxisMax = nil;
            self.lineGraphView.paddingMax = 40;
            self.lineGraphView.enableBezierCurve = YES;
        }
    }
    
    // Customization of the graph
    self.lineGraphView.colorTop = [UIColor whiteColor];
    self.lineGraphView.colorBottom = [UIColor whiteColor];
    self.lineGraphView.colorBackgroundXaxis = [UIColor clearColor];
    self.lineGraphView.colorBackgroundYaxis = [UIColor clearColor];
    self.lineGraphView.colorXaxisLabel = [UIColor lightGrayColor];
    self.lineGraphView.colorYaxisLabel = [UIColor lightGrayColor];
    self.lineGraphView.widthLine = 3.0;
    self.lineGraphView.enableTouchReport = YES;
    self.lineGraphView.enablePopUpReport = YES;
    self.lineGraphView.enableYAxisLabel = YES;
    self.lineGraphView.autoScaleYAxis = YES;
    self.lineGraphView.alwaysDisplayDots = NO;
    self.lineGraphView.enableReferenceXAxisLines = YES;
    self.lineGraphView.enableReferenceYAxisLines = YES;
    self.lineGraphView.enableReferenceAxisFrame = YES;
    self.lineGraphView.animationGraphStyle = BEMLineAnimationDraw;
    
    [self.lineGraphView reloadGraph];
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval
{
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02d:%02d:%02d", (int)hours, (int)minutes, (int)seconds];
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
}

- (void)zipAndUploadData
{
    NSString *filename = [self.session writeOutArchive];
    [self uploadFileToDropbox:filename];
}

- (void)showUploadIndicator
{
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
        case 0:{
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSLog(@"### %@", [self.session writeOutArchive]);
            });
        }
            break;
            
        case 1: {
            if ([[DBSession sharedSession] isLinked]) {
                if (self.appDelegate.reachability.isReachable) {
                    if (self.appDelegate.reachability.isReachableViaWiFi) {
                        [self showUploadIndicator];
                        [self performSelector:@selector(zipAndUploadData) withObject:nil afterDelay:.1];
                    } else {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information", @"Information") message:NSLocalizedString(@"Du hast zurzeit keine WLAN Internetverbindung. Möchtest du trotzdem die Daten hochladen?", @"Du hast zurzeit keine WLAN Internetverbindung. Möchtest du trotzdem die Daten hochladen?") delegate:self cancelButtonTitle:NSLocalizedString(@"Abbrechen", @"Abbrechen") otherButtonTitles:NSLocalizedString(@"OK", @"OK"), nil];
                        [alertView show];
                    }
                } else {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information", @"Information") message:NSLocalizedString(@"Du hast zurzeit keine Internetverbindung", @"Du hast zurzeit keine Internetverbindung") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
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
        case 1: {
            [self showUploadIndicator];
            [self performSelector:@selector(zipAndUploadData) withObject:nil afterDelay:.1];
            break;
        }
        default:
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

#pragma mark -
#pragma mark - BEMSimpleLineGraphDataSource implementation

- (NSInteger)numberOfPointsInLineGraph:(BEMSimpleLineGraphView *)graph
{
    return [self.yValues count]; // Number of points in the graph.
}

- (CGFloat)lineGraph:(BEMSimpleLineGraphView *)graph valueForPointAtIndex:(NSInteger)index
{
    return [self.yValues[index] floatValue]; // The value of the point on the Y-Axis for the index.
}

- (NSString *)lineGraph:(BEMSimpleLineGraphView *)graph labelOnXAxisForIndex:(NSInteger)index
{
    return [NSString stringWithFormat:@"%0.f s", [self.xLabels[index] doubleValue]];
}

- (CGFloat)maxValueForLineGraph:(BEMSimpleLineGraphView *)graph
{
    return graph.yAxisMax == nil ? [[self calculateMaximumPointValue] floatValue] : [graph.yAxisMax floatValue];
}

- (CGFloat)minValueForLineGraph:(BEMSimpleLineGraphView *)graph
{
    return graph.yAxisMin == nil ? [[self calculateMinimumPointValue] floatValue] : [graph.yAxisMin floatValue];
}

- (NSInteger)numberOfYAxisLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph
{
    return 5;
}

- (NSInteger)numberOfGapsBetweenLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph
{
    if (self.yValues.count > 10000) {
        return 300;
    }
    if (self.yValues.count > 1000) {
        return 30;
    }
    if (self.yValues.count > 100) {
        return 3;
    }
    if (self.yValues.count > 33) {
        return 1;
    }
    return 0;
}

#pragma mark -
#pragma mark - UITableViewDelegate implementation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self configureView];
}

#pragma mark -
#pragma mark - UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSrc count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PropertyTableViewCell *cell = nil;
    NSString *cellID = @"Property Cell";
    cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    cell.labelPropertyName.text = [self.dataSrc[indexPath.row] objectForKey:kTitleKey];
    NSNumber *number = [self.session valueForKey:[NSString stringWithFormat:@"%@%@", @"average", [[self.dataSrc[indexPath.row] objectForKey:kValueKey] capitalizedString]]];
    
    cell.labelPropertyValue.text = [NSString stringWithFormat:@"%.1f ⍉", [number doubleValue]];
    
    cell.color = self.appDelegate.colors[indexPath.row % (self.appDelegate.colors.count + 1)];
    
    return cell;
}

- (NSNumber *)calculateMinimumPointValue {
    if (self.yValues.count > 0) {
        NSExpression *expression = [NSExpression expressionForFunction:@"min:" arguments:@[[NSExpression expressionForConstantValue:self.yValues]]];
        NSNumber *value = [expression expressionValueWithObject:nil context:nil];
        return value;
    } else return 0;
}

- (NSNumber *)calculateMaximumPointValue {
    NSExpression *expression = [NSExpression expressionForFunction:@"max:" arguments:@[[NSExpression expressionForConstantValue:self.yValues]]];
    NSNumber *value = [expression expressionValueWithObject:nil context:nil];
    
    return value;
}

@end
