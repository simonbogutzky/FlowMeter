//
//  SessionPrefsTableViewController.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 03.05.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "SessionPrefsTableViewController.h"
#import "EditViewController.h"
#import "SessionViewController.h"
#import "LabelAndSwitchTableViewCell.h"
#import "AppDelegate.h"

#define kPickerAnimationDuration    0.40   // duration for the animation to slide the date picker into view
#define kDatePickerTag              99     // view tag identifiying the date picker view

static NSString *kDateTimeCellID = @"dateTimeCell";     // the cells with date/time
static NSString *kDateTimePickerID = @"dateTimePicker"; // the cell containing the date/time picker
static NSString *kSwitchCellID = @"switchCell";         // a cell with a switch
static NSString *kOtherCellID = @"otherCell";           // the remaining cells at the end

@interface SessionPrefsTableViewController ()

@property (nonatomic, strong) NSArray *dataArray;
@property (nonatomic, strong) NSArray *dataHeaders;

// keep track which indexPath points to the cell with UIDatePicker
@property (nonatomic, strong) NSIndexPath *datePickerIndexPath;

@property (nonatomic, assign) NSInteger pickerCellRowHeight;

@property (nonatomic, strong) IBOutlet UIDatePicker *pickerView;
@property (weak, nonatomic) IBOutlet UIButton *startButton;

@end

@implementation SessionPrefsTableViewController

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
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
        SessionViewController *sessionStartViewController = (SessionViewController *) segue.destinationViewController;
        sessionStartViewController.sessionData = self.dataArray;
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"Start recording"]) {
        BOOL canStartRecording = YES;
        if ([[self.dataArray[0][0] objectForKey:kValueKey] isEqualToString:@" "] || [[self.dataArray[0][1] objectForKey:kValueKey] isEqualToString:@" "] || [[self.dataArray[1][0] objectForKey:kValueKey] isEqualToString:@" "]) {
            canStartRecording = NO;
        }
        if (!canStartRecording) {
            CAKeyframeAnimation *shakeAnimation = [ CAKeyframeAnimation animationWithKeyPath:@"transform"];
            shakeAnimation.values = @[ [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-10.0f, 0.0f, 0.0f)], [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f)]];
            shakeAnimation.autoreverses = YES;
            shakeAnimation.repeatCount = 3.0f;
            shakeAnimation.duration = 0.07f;
            [self.startButton.layer addAnimation:shakeAnimation forKey:nil];
            return canStartRecording;
        }
    }
    return YES;
}

#pragma mark -
#pragma mark - Getter

- (NSArray *)dataArray
{
    if (_dataArray == nil) {
        NSArray *section01 = @[
                               [@{kTitleKey:NSLocalizedString(@"Vorname", @"Vorname"), kValueKey:@" ", kEntityKey:@"User", kPropertyKey:@"firstName", kCellIDKey:kOtherCellID} mutableCopy],
                               [@{kTitleKey:NSLocalizedString(@"Nachname", @"Nachname"), kValueKey:@" ", kEntityKey:@"User", kPropertyKey:@"lastName", kCellIDKey:kOtherCellID} mutableCopy]
                               ];
        NSArray *section02 = @[
                               [@{kTitleKey:NSLocalizedString(@"Aktivität", @"Aktivität"), kValueKey:@" ", kEntityKey:@"Activity", kPropertyKey:@"name", kCellIDKey:kOtherCellID} mutableCopy],
                               [@{kTitleKey:NSLocalizedString(@"Countdown", @"Countdown"), kValueKey:[NSNumber numberWithDouble:5.0], kCellIDKey:kDateTimeCellID} mutableCopy]
                               ];
        NSArray *section03 = @[
                               [@{kTitleKey:NSLocalizedString(@"Flow Kurzskala", @"Flow Kurzskala"), kValueKey:@1, kCellIDKey:kSwitchCellID} mutableCopy],
                               [@{kTitleKey:NSLocalizedString(@"Zeitinterval", @"Zeitinterval"), kValueKey:[NSNumber numberWithDouble:2 * 60.0], kCellIDKey:kDateTimeCellID} mutableCopy],
                               [@{kTitleKey:NSLocalizedString(@"Variablität", @"Variablität"), kValueKey:[NSNumber numberWithDouble:1 * 60.0], kCellIDKey:kDateTimeCellID} mutableCopy]
                               ];
                               
        
        _dataArray = @[section01, section02, section03];
    }
    return _dataArray;
}

- (NSArray *)dataHeaders
{
    return @[NSLocalizedString(@"Benutzer", @"Benutzer"), NSLocalizedString(@"Aktivität", @"Aktivität"), NSLocalizedString(@"Selbsteinsätzung", @"Selbsteinsätzung")];
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
    return self.tableView.rowHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.dataArray[section][0] objectForKey:kCellIDKey] isEqualToString:kSwitchCellID]) {
        if (![[self.dataArray[section][0] objectForKey:kValueKey] boolValue]) {
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
    
    NSString *cellID = [dataItem objectForKey:kCellIDKey];
    cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    // proceed to configure our cell
    if ([cellID isEqualToString:kDateTimeCellID]) {
        cell.textLabel.text = [dataItem valueForKey:kTitleKey];
        cell.detailTextLabel.text = [self stringFromTimeInterval:[[dataItem valueForKey:kValueKey] doubleValue]];
    } else if ([cellID isEqualToString:kOtherCellID]) {
        cell.textLabel.text = [dataItem valueForKey:kTitleKey];
        cell.detailTextLabel.text = [dataItem valueForKey:kValueKey];
    } else if ([cellID isEqualToString:kSwitchCellID]) {
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
    [dataItem setValue:[NSNumber numberWithDouble:targetedDatePicker.countDownDuration] forKey:kValueKey];
    
    // update the cell's date string
    cell.detailTextLabel.text = [self stringFromTimeInterval:targetedDatePicker.countDownDuration];
    [self.dataArray[targetedCellIndexPath.section][targetedCellIndexPath.row] setObject:[NSNumber numberWithDouble:targetedDatePicker.countDownDuration] forKey:@"value"];
}

- (IBAction)switchChangeAction:(UISwitch *)sender
{
    CGPoint center = sender.center;
    CGPoint rootViewPoint = [sender.superview convertPoint:center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    
    // update our data model
    NSMutableDictionary *dataItem = self.dataArray[indexPath.section][indexPath.row];
    [dataItem setValue:[NSNumber numberWithBool:sender.on] forKey:kValueKey];
    
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    int numberOfRows = [self.dataArray[indexPath.section] count];
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
    [self.tableView reloadData];
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
            [targetedDatePicker setCountDownDuration:[[dataItem valueForKey:kValueKey] doubleValue]];
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

@end

