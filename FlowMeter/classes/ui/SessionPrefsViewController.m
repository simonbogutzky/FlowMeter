//
//  SessionPrefsViewController.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 03.05.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "SessionPrefsViewController.h"
#import "EditViewController.h"
#import "SessionRecordViewController.h"
#import "LabelAndSwitchTableViewCell.h"
#import "AppDelegate.h"

#define kPickerAnimationDuration    0.40   // duration for the animation to slide the date picker into view
#define kDatePickerTag              99     // view tag identifiying the date picker view

static NSString *kDateTimeCellID = @"dateTimeCell";     // the cells with date/time
static NSString *kDateTimePickerID = @"dateTimePicker"; // the cell containing the date/time picker
static NSString *kOptionSwitchCellID = @"optionSwitchCell";         // a cell with a switch
static NSString *kOtherCellID = @"otherCell";           // the remaining cells at the end
static NSString *kSwitchCellID = @"switchCell";

@interface SessionPrefsViewController ()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) NSArray *dataArray;
@property (nonatomic, strong) NSArray *dataHeaders;
@property (nonatomic, strong) NSMutableArray *heartRateMonitorDevices;

// keep track which indexPath points to the cell with UIDatePicker
@property (nonatomic, strong) NSIndexPath *datePickerIndexPath;

@property (nonatomic, assign) NSInteger pickerCellRowHeight;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *startButton;
@property (weak, nonatomic) IBOutlet UILabel *labelHeartRateMonitorDeviceName;
@property (weak, nonatomic) IBOutlet UILabel *labelHeartRateMonitorHasConnection;
@property (nonatomic, assign) BOOL varibilityAlertAlreadyShown;

@end

@implementation SessionPrefsViewController

@synthesize appDelegate = _appDelegate;

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self performSelector:@selector(scan) withObject:nil afterDelay:0.5];
    [self performSelector:@selector(checkHeartRateMonitorConnection) withObject:nil afterDelay:5];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [self checkHeartRateMonitorConnection];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (bool)prefersStatusBarHidden {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UITableViewCell *cell = sender;
    if ([segue.identifier isEqualToString:@"Edit value"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        EditViewController *editViewController = (EditViewController *) navigationController.topViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        editViewController.itemDictionary = self.dataArray[indexPath.section][indexPath.row];
        [((UITableViewCell *) sender) setSelected:NO animated:YES];
    }
    
    if ([segue.identifier isEqualToString:@"Start recording"]) {
        SessionRecordViewController *sessionStartViewController = (SessionRecordViewController *) segue.destinationViewController;
        sessionStartViewController.sessionData = self.dataArray;
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"Start recording"]) {
        BOOL canStartRecording = YES;
        if ([(self.dataArray[0][0])[kValueKey] isEqualToString:@" "] || [(self.dataArray[0][1])[kValueKey] isEqualToString:@" "] || [(self.dataArray[1][0])[kValueKey] isEqualToString:@" "]) {
            canStartRecording = NO;
        }
        if (!canStartRecording) {            
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:NSLocalizedString(@"Start nicht möglich", @"Start nicht möglich")
                                         message:NSLocalizedString(@"Vorname, Nachname und Aktivität müssen ausgefüllt werden", @"Vorname, Nachname und Aktivität müssen ausgefüllt werden")
                                         preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* okButton = [UIAlertAction
                                        actionWithTitle:@"OK"
                                        style:UIAlertActionStyleDefault
                                       handler:nil];
            [alert addAction:okButton];
            [self presentViewController:alert animated:YES completion:nil];
        }
        return canStartRecording;
    }
    return YES;
}

#pragma mark -
#pragma mark - Getter

- (AppDelegate *)appDelegate
{
    if (_appDelegate == Nil) {
        _appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    }
    return _appDelegate;
}

- (NSArray *)dataArray
{
    if (_dataArray == nil) {
        NSArray *section01 = @[
                               [@{kTitleKey:NSLocalizedString(@"Vorname", @"Vorname"), kValueKey:@" ", kEntityKey:@"User", kPropertyKey:@"firstName", kCellIDKey:kOtherCellID} mutableCopy],
                               [@{kTitleKey:NSLocalizedString(@"Nachname", @"Nachname"), kValueKey:@" ", kEntityKey:@"User", kPropertyKey:@"lastName", kCellIDKey:kOtherCellID} mutableCopy]
                               ];
        NSArray *section02 = @[
                               [@{kTitleKey:NSLocalizedString(@"Aktivität", @"Aktivität"), kValueKey:@" ", kEntityKey:@"Activity", kPropertyKey:@"name", kCellIDKey:kOtherCellID} mutableCopy],
                               [@{kTitleKey:NSLocalizedString(@"Countdown", @"Countdown"), kValueKey:@5.0, kUnitKey:NSLocalizedString(@"s", @"s"), kCellIDKey:kOtherCellID} mutableCopy]
                               ];
        NSArray *section03 = @[
                               [@{kTitleKey:NSLocalizedString(@"Mehrfach befragen", @"Mehrfach befragen"), kValueKey:@0, kCellIDKey:kOptionSwitchCellID} mutableCopy],
                               [@{kTitleKey:NSLocalizedString(@"Zeitintervall", @"Zeitintervall"), kValueKey:@(2 * 60.0 * 60.0), kCellIDKey:kDateTimeCellID} mutableCopy],
                               [@{kTitleKey:NSLocalizedString(@"Variablität", @"Variablität"), kValueKey:@(1 * 60.0 * 60.0), kCellIDKey:kDateTimeCellID} mutableCopy]
                               ];
        NSArray *section04 = @[
                               [@{kTitleKey:NSLocalizedString(@"GPS-Positionen", @"GPS-Positionen"), kValueKey:@0, kCellIDKey:kSwitchCellID} mutableCopy],
                               [@{kTitleKey:NSLocalizedString(@"Bewegungen", @"Bewegungen"), kValueKey:@0, kCellIDKey:kSwitchCellID} mutableCopy]
                               ];
                               
        
        _dataArray = @[section01, section02, section03, section04];
    }
    return _dataArray;
}

- (NSArray *)dataHeaders
{
    return @[NSLocalizedString(@"Benutzer", @"Benutzer"), NSLocalizedString(@"Aktivität", @"Aktivität"), NSLocalizedString(@"Flow Kurzskala", @"Flow Kurzskala"), NSLocalizedString(@"Datenaufnahme", @"Datenaufnahme")];
}

- (NSInteger)pickerCellRowHeight
{
    if (_pickerCellRowHeight == 0) {
        UITableViewCell *pickerViewCellToCheck = [self.tableView dequeueReusableCellWithIdentifier:kDateTimePickerID];
        _pickerCellRowHeight = CGRectGetHeight(pickerViewCellToCheck.frame);
    }
    return _pickerCellRowHeight;
}

#pragma mark -
#pragma mark - UITableViewDataSource implementation

- (UIView *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.dataHeaders[section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.datePickerIndexPath != nil && self.datePickerIndexPath.section == indexPath.section && self.datePickerIndexPath.row == indexPath.row) {
        return self.pickerCellRowHeight;
    }
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([(self.dataArray[section][0])[kCellIDKey] isEqualToString:kOptionSwitchCellID]) {
        if (![(self.dataArray[section][0])[kValueKey] boolValue]) {
            return 1;
        }
    }
    
    if (self.datePickerIndexPath != nil && self.datePickerIndexPath.section == section) {
        NSInteger numRows = [self.dataArray[section] count];
        return ++numRows;
    }
    
    return [self.dataArray[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (self.datePickerIndexPath != nil && self.datePickerIndexPath.section == indexPath.section && self.datePickerIndexPath.row == indexPath.row) {
        cell = [tableView dequeueReusableCellWithIdentifier:kDateTimePickerID];
        return cell;
    }
    
    NSInteger row = indexPath.row;
    if (self.datePickerIndexPath != nil && self.datePickerIndexPath.section == indexPath.section && self.datePickerIndexPath.row <= indexPath.row) {
        row--;
    }
    NSDictionary *dataItem = self.dataArray[indexPath.section][row];
    
    NSString *cellID = dataItem[kCellIDKey];
    cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    // proceed to configure our cell
    if ([cellID isEqualToString:kDateTimeCellID]) {
        cell.textLabel.text = [dataItem valueForKey:kTitleKey];
        cell.detailTextLabel.text = [self stringFromTimeInterval:[[dataItem valueForKey:kValueKey] doubleValue]];
    } else if ([cellID isEqualToString:kOtherCellID]) {
        cell.textLabel.text = [dataItem valueForKey:kTitleKey];
        
        if ([dataItem valueForKey:kUnitKey] != nil) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%@", [[dataItem valueForKey:kValueKey] description], [dataItem valueForKey:kUnitKey]];
        } else {
            cell.detailTextLabel.text = [[dataItem valueForKey:kValueKey] description];
        }
    } else if ([cellID isEqualToString:kSwitchCellID] || [cellID isEqualToString:kOptionSwitchCellID]) {
        ((LabelAndSwitchTableViewCell * )cell).label.text = [dataItem valueForKey:kTitleKey];
        ((LabelAndSwitchTableViewCell * )cell).contentswitch.on = [[dataItem valueForKey:kValueKey] boolValue];
    }
    
	return cell;
}

/*! Adds or removes a UIDatePicker cell below the given indexPath.
 
 @param indexPath The indexPath to reveal the UIDatePicker.
 */
- (void)toggleDatePickerForSelectedIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView beginUpdates];
    
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]];
                            
    // check if 'indexPath' has an attached date picker below it
    if ([self hasPickerForIndexPath:indexPath])
    {
        // found a picker below it, so remove it
        [self.tableView deleteRowsAtIndexPaths:indexPaths
                              withRowAnimation:UITableViewRowAnimationFade];
    }
    else
    {
        // didn't find a picker below it, so we should insert it
        [self.tableView insertRowsAtIndexPaths:indexPaths
                              withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [self.tableView endUpdates];
}

/*! Reveals the date picker inline for the given indexPath, called by "didSelectRowAtIndexPath".
 
 @param indexPath The indexPath to reveal the UIDatePicker.
 */
- (void)displayInlineDatePickerForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // display the date picker inline with the table content
    [self.tableView beginUpdates];
    
    BOOL before = NO;   // indicates if the date picker is below "indexPath", help us determine which row to reveal
    if ([self isInlineDatePickerInSection:indexPath.section])
    {
        before = self.datePickerIndexPath.row < indexPath.row && self.datePickerIndexPath.section == indexPath.section;
    }
    
    BOOL sameCellClicked = (self.datePickerIndexPath.row - 1 == indexPath.row && self.datePickerIndexPath.section == indexPath.section);
    
    // remove any date picker cell if it exists
    if (self.datePickerIndexPath != nil) {
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.datePickerIndexPath.row inSection:self.datePickerIndexPath.section]]
                              withRowAnimation:UITableViewRowAnimationFade];
        self.datePickerIndexPath = nil;
    }
    
    if (!sameCellClicked)
    {
        // hide the old date picker and display the new one
        NSInteger rowToReveal = (before ? indexPath.row - 1 : indexPath.row);
        NSIndexPath *indexPathToReveal = [NSIndexPath indexPathForRow:rowToReveal inSection:indexPath.section];
        
        [self toggleDatePickerForSelectedIndexPath:indexPathToReveal];
        self.datePickerIndexPath = [NSIndexPath indexPathForRow:indexPathToReveal.row + 1 inSection:indexPath.section];
    }
    
    // always deselect the row containing the start or end date
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.tableView endUpdates];
    
    // inform our date picker of the current date to match the current cell
    [self updateDatePicker];
}

#pragma mark -
#pragma mark - UITableViewDelegate implementation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.reuseIdentifier == kDateTimeCellID) {
        [self displayInlineDatePickerForRowAtIndexPath:indexPath];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark -
#pragma mark - IBActions

/*! User chose to change the date by changing the values inside the UIDatePicker.
 
 @param sender The sender for this action: UIDatePicker.
 */
- (IBAction)dateAction:(id)sender
{
    NSIndexPath *targetedCellIndexPath = nil;
    
    if (self.datePickerIndexPath != nil)
    {
        // inline date picker: update the cell's date "above" the date picker cell
        targetedCellIndexPath = [NSIndexPath indexPathForRow:self.datePickerIndexPath.row - 1 inSection:self.datePickerIndexPath.section];
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:targetedCellIndexPath];
    UIDatePicker *targetedDatePicker = sender;
    
    // update our data model
    NSMutableDictionary *dataItem = self.dataArray[targetedCellIndexPath.section][targetedCellIndexPath.row];
    [dataItem setValue:@(targetedDatePicker.countDownDuration) forKey:kValueKey];
    
    // update the cell's date string
    cell.detailTextLabel.text = [self stringFromTimeInterval:targetedDatePicker.countDownDuration];
    
    [self updateModelAtIndexPath:targetedCellIndexPath withValue:targetedDatePicker.countDownDuration];
}

- (void)updateModelAtIndexPath:(NSIndexPath *)indexPath withValue:(double)value
{
    // User will update interval
    if (indexPath.section == 2 && indexPath.row == 1) {
        double variabilityLimit = value / 2.0;
        double variability = [(self.dataArray[2][2])[kValueKey] doubleValue];
        
        if (variabilityLimit < variability) {
            (self.dataArray[2][2])[kValueKey] = @(variabilityLimit);
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:2]];
            cell.detailTextLabel.text = [self stringFromTimeInterval:variabilityLimit];
        }
    }
    
    // User will update variability
    if (indexPath.section == 2 && indexPath.row == 2) {
        double variabilityLimit = [(self.dataArray[2][1])[kValueKey] doubleValue] / 2.0;
        double variability = value;
        
        if (variabilityLimit < variability) {
            (self.dataArray[2][2])[kValueKey] = @(variabilityLimit);
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            cell.detailTextLabel.text = [self stringFromTimeInterval:variabilityLimit];
            
            if (!self.varibilityAlertAlreadyShown) {
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:NSLocalizedString(@"Information", @"Information")
                                             message:NSLocalizedString(@"Der Wert der Variabilität kann höchsten die Hälfe des Intervallwerts annehmen.", @"Der Wert der Variabilität kann höchsten die Hälfe des Intervallwerts annehmen.")
                                             preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* okButton = [UIAlertAction
                                           actionWithTitle:@"OK"
                                           style:UIAlertActionStyleDefault
                                           handler:nil];
                [alert addAction:okButton];
                [self presentViewController:alert animated:YES completion:nil];

                self.varibilityAlertAlreadyShown = YES;
            }
            
            
        }
    }
}

- (IBAction)switchChangeAction:(UISwitch *)sender
{
    CGPoint center = sender.center;
    CGPoint rootViewPoint = [sender.superview convertPoint:center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    // update our data model
    NSMutableDictionary *dataItem = self.dataArray[indexPath.section][indexPath.row];
    if ([dataItem[kValueKey] boolValue] != sender.on) {
       
        [dataItem setValue:@(sender.on) forKey:kValueKey];
        
        if ([cell.reuseIdentifier isEqual:kOptionSwitchCellID]) {
            NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
            unsigned long numberOfRows = [self.dataArray[indexPath.section] count];
            for (int i = 1; i < numberOfRows; i++) {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
            }
            
            if(self.datePickerIndexPath != nil && self.datePickerIndexPath.section == indexPath.section) {
                [indexPaths addObject:[NSIndexPath indexPathForRow:numberOfRows inSection:indexPath.section]];
            }
            
            if (!sender.on) {
                [self.tableView deleteRowsAtIndexPaths:indexPaths
                                      withRowAnimation:UITableViewRowAnimationFade];
                self.datePickerIndexPath = nil;
            } else {
                [self.tableView insertRowsAtIndexPaths:indexPaths
                                      withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    }
}

#pragma mark -
#pragma mark - Convenient methods

/*! Determines if the given indexPath has a cell below it with a UIDatePicker.
 
 @param indexPath The indexPath to check if its cell has a UIDatePicker below it.
 */
- (BOOL)hasPickerForIndexPath:(NSIndexPath *)indexPath
{
    BOOL hasDatePicker = NO;
    
    NSInteger targetedRow = indexPath.row;
    targetedRow++;
    
    NSInteger targetedSection = indexPath.section;
    
    UITableViewCell *checkDatePickerCell =
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:targetedRow inSection:targetedSection]];
    UIDatePicker *checkDatePicker = (UIDatePicker *)[checkDatePickerCell viewWithTag:kDatePickerTag];
    
    hasDatePicker = (checkDatePicker != nil);
    return hasDatePicker;
}

/*! Updates the UIDatePicker's value to match with the date of the cell above it.
 */
- (void)updateDatePicker
{
    if (self.datePickerIndexPath != nil)
    {
        UITableViewCell *associatedDatePickerCell = [self.tableView cellForRowAtIndexPath:self.datePickerIndexPath];
        
        UIDatePicker *targetedDatePicker = (UIDatePicker *)[associatedDatePickerCell viewWithTag:kDatePickerTag];
        if (targetedDatePicker != nil)
        {
            // we found a UIDatePicker in this cell, so update it's date value
            //
            NSDictionary *dataItem = self.dataArray[self.datePickerIndexPath.section][self.datePickerIndexPath.row - 1];
            targetedDatePicker.countDownDuration = [[dataItem valueForKey:kValueKey] doubleValue];
        }
    }
}

/*! Determines if the UITableViewController has a UIDatePicker in any of its cells.
 */
- (BOOL)isInlineDatePickerInSection:(NSInteger)section
{
    return (self.datePickerIndexPath != nil && self.datePickerIndexPath.section == section);
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval
{
    NSInteger ti = (NSInteger)interval;
    //NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ldh %02ldmin", (long)hours, (long)minutes];
}

#pragma mark -
#pragma mark - Convenient methods of the heart rate monitor

- (void)scan
{
    self.heartRateMonitorDevices = [[NSMutableArray alloc] initWithCapacity:1];
    self.appDelegate.heartRateMonitorManager.delegate = self;
    
    NSString *cause = nil;
    
    switch (self.appDelegate.heartRateMonitorManager.state) {
        case HeartRateMonitorManagerStatePoweredOn: {
            [self.appDelegate.heartRateMonitorManager scanForHeartRateMonitorDeviceWhichWereConnected:YES];
        }
            break;
            
        case HeartRateMonitorManagerStatePoweredOff: {
//            cause = NSLocalizedString(@"Überprüfe, ob Bluetooth eingeschaltet ist", @"Überprüfe, ob Bluetooth eingeschaltet ist");
            
        }
            break;
        case HeartRateMonitorManagerStateResetting: {
            cause = NSLocalizedString(@"Bluetooth Manager wird gerade zurückgesetzt", @"Bluetooth Manager wird gerade zurückgesetzt");
        }
            break;
        case HeartRateMonitorManagerStateUnauthorized: {
//            cause = NSLocalizedString(@"Überprüfe deine Sicherheitseinstellungen", @"Überprüfe deine Sicherheitseinstellungen");
        }
            break;
        case HeartRateMonitorManagerStateUnknown: {
            cause = NSLocalizedString(@"Ein unbekannter Fehler ist aufgetreten", @"Ein unbekannter Fehler ist aufgetreten");
        }
            break;
        case HeartRateMonitorManagerStateUnsupported: {
//            cause = NSLocalizedString(@"Gerät unterstützt kein Bluetooth LE", @"Gerät unterstützt kein Bluetooth LE");
            
        }
            break;
    }
    
    if (self.appDelegate.heartRateMonitorManager.state != HeartRateMonitorManagerStatePoweredOn && self.appDelegate.heartRateMonitorManager.state != HeartRateMonitorManagerStatePoweredOff) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:NSLocalizedString(@"Keine Bluetooth Verbindung möglich", @"Keine Bluetooth Verbindung möglich")
                                     message:cause
                                     preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"OK"
                                   style:UIAlertActionStyleDefault
                                   handler:nil];
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didDiscoverHeartrateMonitorDevices:(NSArray *)heartRateMonitorDevices
{
    [self.appDelegate.heartRateMonitorManager stopScanning];
    for (HeartRateMonitorDevice *heartRateMonitorDevice in heartRateMonitorDevices) {
        [self.heartRateMonitorDevices addObject:heartRateMonitorDevice];
    }
    
    if (self.heartRateMonitorDevices.count > 0) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            HeartRateMonitorDevice *heartRateMonitorDevice = (self.heartRateMonitorDevices).lastObject;
            [self.appDelegate.heartRateMonitorManager connectHeartRateMonitorDevice:heartRateMonitorDevice];
        });
    }
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didDisconnectHeartrateMonitorDevice:(CBPeripheral *)heartRateMonitorDevice
                          error:(NSError *)error
{
    if (error) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:NSLocalizedString(@"Verbindung wurde getrennt", @"Titel der Fehlermeldung: Verbindung wurde getrennt")
                                     message:NSLocalizedString(@"Die Verbindung zum HR-Brustgurt wurde unerwartet getrennt.", @"Beschreibung der Fehlermeldung: Verbindung wurde getrennt")
                                     preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"OK"
                                   style:UIAlertActionStyleDefault
                                   handler:nil];
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager
didFailToConnectHeartrateMonitorDevice:(CBPeripheral *)heartRateMonitorDevice
                          error:(NSError *)error
{    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:NSLocalizedString(@"Fehler beim Verbinden", @"Titel der Fehlermeldung: Fehler beim Verbinden")
                                 message:NSLocalizedString(@"Es konnte keine Verbindung zum HR-Brustgurt hergestellt werden.", @"Beschreibung der Fehlermeldung: Fehler beim Verbinden")
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:nil];
    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)checkHeartRateMonitorConnection
{
    if (self.appDelegate.heartRateMonitorManager.hasConnection) {
        self.labelHeartRateMonitorDeviceName.text = self.appDelegate.heartRateMonitorManager.connectedHeartRateMonitorDevice.name;
        self.labelHeartRateMonitorHasConnection.textColor = [UIColor redColor];
    }
    else {
        self.labelHeartRateMonitorHasConnection.textColor = [UIColor darkGrayColor];
    }
    self.labelHeartRateMonitorDeviceName.hidden = !self.appDelegate.heartRateMonitorManager.hasConnection;
}

@end

