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

#define kPickerAnimationDuration    0.40   // duration for the animation to slide the date picker into view
#define kDatePickerTag              99     // view tag identifiying the date picker view

#define kTitleKey       @"title"   // key for obtaining the data source item's title
#define kDateKey        @"date"    // key for obtaining the data source item's date value
#define kValueKey       @"value"   // key for obtaining the data source item's value

// keep track of which sections and rows have picker cells
#define kFlowShortScaleSwitchSection   2
#define kFlowShortScaleSwitchRow   0
#define kTimeIntervalSection   2
#define kTimeIntervalRow   1
#define kTimeIntervalDummySection   2
#define kTimeIntervalDummyRow   2

#define EMBEDDED_DATE_PICKER (DeviceSystemMajorVersion() >= 7)

static NSString *kDateCellID = @"dateCell";     // the cells with the start or end date
static NSString *kDatePickerID = @"datePicker"; // the cell containing the date picker
static NSString *kOtherCell = @"valueCell";     // the remaining cells at the end
static NSString *kSwitchCell = @"switchCell";     // the remaining cells at the end
static NSString *kDummyCell = @"dummyCell";     // the remaining cells at the end

@interface SessionPrefsTableViewController ()

@property (nonatomic, strong) NSArray *dataArray;

// keep track which indexPath points to the cell with UIDatePicker
@property (nonatomic, strong) NSIndexPath *datePickerIndexPath;

@property (assign) NSInteger pickerCellRowHeight;

@property (nonatomic, strong) IBOutlet UIDatePicker *pickerView;

// this button appears only when the date picker is shown (iOS 6.1.x or earlier)
@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;

@property (weak, nonatomic) IBOutlet UIButton *startButton;

@property (assign) BOOL flowShortScalePropertiesHidden;

@end

@implementation SessionPrefsTableViewController

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setup our data source
    NSMutableDictionary *itemOne = [@{ kTitleKey : NSLocalizedString(@"Vorname", @"Vorname"), kValueKey : @" "} mutableCopy];
    NSMutableDictionary *itemTwo = [@{ kTitleKey : NSLocalizedString(@"Nachname", @"Nachname"), kValueKey : @" "} mutableCopy];
    NSArray *sectionOne = @[itemOne, itemTwo];
    NSMutableDictionary *itemThree = [@{ kTitleKey : NSLocalizedString(@"Aktivität", @"Aktivität"), kValueKey : @" "} mutableCopy];
    NSArray *sectionTwo = @[itemThree];
    NSMutableDictionary *itemFour = [@{ kTitleKey : NSLocalizedString(@"Flow Kurzskala", @"Flow Kurzskala"), kValueKey : @1} mutableCopy];
    NSMutableDictionary *itemFive = [@{ kTitleKey : @"Zeitinterval",
                                        kDateKey : [NSNumber numberWithDouble:60 * 60.0] } mutableCopy];
    NSMutableDictionary *itemSix = [@{ kTitleKey : @"dummy", kValueKey : @""} mutableCopy];
    NSArray *sectionThree = @[itemFour, itemFive, itemSix];
    self.dataArray = @[sectionOne, sectionTwo, sectionThree];
    
    // obtain the picker view cell's height, works because the cell was pre-defined in our storyboard
    UITableViewCell *pickerViewCellToCheck = [self.tableView dequeueReusableCellWithIdentifier:kDatePickerID];
    self.pickerCellRowHeight = CGRectGetHeight(pickerViewCellToCheck.frame);
}

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
            CAKeyframeAnimation *shakeAnimation = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
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
#pragma mark - UITableViewDataSource implementation

- (UIView *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @[NSLocalizedString(@"Benutzer", @"Benutzer"), NSLocalizedString(@"Aktivität", @"Aktivität"), NSLocalizedString(@"Selbsteinsätzung", @"Selbsteinsätzung")][section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self indexPathHasPicker:indexPath]) {
        return self.pickerCellRowHeight;
    } else if ([self indexPathHasDummy:indexPath]) {
        return 0.0;
    } else if ([self indexPathHasSwitch:indexPath]) {
        return 44.0;
    }
    return self.tableView.rowHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 2 && self.flowShortScalePropertiesHidden) {
        return 1;
    }
    
    if ([self isInlineDatePickerInSection:section])
    {
        // we have a date picker, so allow for it in the number of rows in this section
        NSInteger numRows = [self.dataArray[section] count];
        return ++numRows;
    }
    
    return [self.dataArray[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    NSString *cellID = kOtherCell;
    
    if ([self indexPathHasPicker:indexPath])
    {
        // the indexPath is the one containing the inline date picker
        cellID = kDatePickerID;     // the current/opened date picker cell
    }
    else if ([self indexPathHasDate:indexPath])
    {
        // the indexPath is one that contains the date information
        cellID = kDateCellID;       // the start/end date cells
    } else if ([self indexPathHasDummy:indexPath]) {
        cellID = kDummyCell;
    } else if ([self indexPathHasSwitch:indexPath]) {
        cellID = kSwitchCell;
    }

    cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
//    if (indexPath.row == 0)
//    {
//        // we decide here that first cell in the table is not selectable (it's just an indicator)
//        cell.selectionStyle = UITableViewCellSelectionStyleNone;
//    }
    
    // if we have a date picker open whose cell is above the cell we want to update,
    // then we have one more cell than the model allows
    //
    NSInteger modelRow = indexPath.row;
    if (self.datePickerIndexPath != nil && self.datePickerIndexPath.section == indexPath.section && self.datePickerIndexPath.row <= indexPath.row)
    {
        modelRow--;
    }
    
    NSDictionary *itemData = self.dataArray[indexPath.section][modelRow];
    
    // proceed to configure our cell
    if ([cellID isEqualToString:kDateCellID])
    {
        // we have either start or end date cells, populate their date field
        //
        cell.textLabel.text = [itemData valueForKey:kTitleKey];
        cell.detailTextLabel.text = [self stringFromTimeInterval:[[itemData valueForKey:kDateKey] doubleValue]];
    }
    else if ([cellID isEqualToString:kOtherCell])
    {
        // this cell is a non-date cell, just assign it's text label
        //
        cell.textLabel.text = [itemData valueForKey:kTitleKey];
        cell.detailTextLabel.text = [itemData valueForKey:kValueKey];
    } else if ([cellID isEqualToString:kSwitchCell]) {
        ((LabelAndSwitchTableViewCell * )cell).label.text = [itemData valueForKey:kTitleKey];
        ((LabelAndSwitchTableViewCell * )cell).contentswitch.on = [[itemData valueForKey:kValueKey] boolValue];
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
    if ([self isInlineDatePickerInSection:indexPath.section])
    {
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.datePickerIndexPath.row inSection:indexPath.section]]
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

/*! Reveals the UIDatePicker as an external slide-in view, iOS 6.1.x and earlier, called by "didSelectRowAtIndexPath".
 
 @param indexPath The indexPath used to display the UIDatePicker.
 */
- (void)displayExternalDatePickerForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // first update the date picker's date value according to our model
    NSDictionary *itemData = self.dataArray[indexPath.section][indexPath.row];
    [self.pickerView setDate:[itemData valueForKey:kDateKey] animated:YES];
    
    // the date picker might already be showing, so don't add it to our view
    if (self.pickerView.superview == nil)
    {
        CGRect startFrame = self.pickerView.frame;
        CGRect endFrame = self.pickerView.frame;
        
        // the start position is below the bottom of the visible frame
        startFrame.origin.y = CGRectGetHeight(self.view.frame);
        
        // the end position is slid up by the height of the view
        endFrame.origin.y = startFrame.origin.y - CGRectGetHeight(endFrame);
        
        self.pickerView.frame = startFrame;
        
        [self.view addSubview:self.pickerView];
        
        // animate the date picker into view
        [UIView animateWithDuration:kPickerAnimationDuration animations: ^{ self.pickerView.frame = endFrame; }
                         completion:^(BOOL finished) {
                             // add the "Done" button to the nav bar
                             self.navigationItem.rightBarButtonItem = self.doneButton;
                         }];
    }
}

#pragma mark -
#pragma mark - UITableViewDelegate implementation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.reuseIdentifier == kDateCellID)
    {
        if (EMBEDDED_DATE_PICKER)
            [self displayInlineDatePickerForRowAtIndexPath:indexPath];
        else
            [self displayExternalDatePickerForRowAtIndexPath:indexPath];
    }
    else
    {
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
        //
        targetedCellIndexPath = [NSIndexPath indexPathForRow:self.datePickerIndexPath.row - 1 inSection:self.datePickerIndexPath.section];
    }
    else
    {
        // external date picker: update the current "selected" cell's date
        targetedCellIndexPath = [self.tableView indexPathForSelectedRow];
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:targetedCellIndexPath];
    UIDatePicker *targetedDatePicker = sender;
    
    // update our data model
    NSMutableDictionary *itemData = self.dataArray[targetedCellIndexPath.row];
    [itemData setValue:[NSNumber numberWithDouble:targetedDatePicker.countDownDuration] forKey:kDateKey];
    
    // update the cell's date string
    cell.detailTextLabel.text = [self stringFromTimeInterval:targetedDatePicker.countDownDuration];
    [self.dataArray[targetedCellIndexPath.section][targetedCellIndexPath.row] setObject:[NSNumber numberWithDouble:targetedDatePicker.countDownDuration] forKey:kDateKey];
}

- (IBAction)switchChangeAction:(UISwitch *)sender
{
    CGPoint center = sender.center;
    CGPoint rootViewPoint = [sender.superview convertPoint:center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    
    // update our data model
    NSMutableDictionary *itemData = self.dataArray[indexPath.section][indexPath.row];
    [itemData setValue:[NSNumber numberWithBool:sender.on] forKey:kValueKey];
    
    if (kFlowShortScaleSwitchSection == indexPath.section && kFlowShortScaleSwitchRow == indexPath.row) {
        self.flowShortScalePropertiesHidden = !sender.on;
        NSArray *indexPaths = nil;
        if ([self hasPickerForIndexPath:[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]]){
            indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section], [NSIndexPath indexPathForRow:indexPath.row + 2 inSection:indexPath.section], [NSIndexPath indexPathForRow:indexPath.row + 3 inSection:indexPath.section]];
        } else {
            indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section], [NSIndexPath indexPathForRow:indexPath.row + 2 inSection:indexPath.section]];
        }
        
        if (!sender.on){
            [self.tableView deleteRowsAtIndexPaths:indexPaths
                                  withRowAnimation:UITableViewRowAnimationFade];
            self.datePickerIndexPath = nil;
        }
        else
        {
            [self.tableView insertRowsAtIndexPaths:indexPaths
                                  withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    [self.tableView reloadData];
}


/*! User chose to finish using the UIDatePicker by pressing the "Done" button
    (used only for "non-inline" date picker, iOS 6.1.x or earlier)
 
 @param sender The sender for this action: The "Done" UIBarButtonItem
 */
- (IBAction)doneAction:(id)sender
{
    CGRect pickerFrame = self.pickerView.frame;
    pickerFrame.origin.y = CGRectGetHeight(self.view.frame);
     
    // animate the date picker out of view
    [UIView animateWithDuration:kPickerAnimationDuration animations: ^{ self.pickerView.frame = pickerFrame; }
                     completion:^(BOOL finished) {
                         [self.pickerView removeFromSuperview];
                     }];
    
    // remove the "Done" button in the navigation bar
	self.navigationItem.rightBarButtonItem = nil;
    
    // deselect the current table cell
	NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark - Convenient methods

/*! Returns the major version of iOS, (i.e. for iOS 6.1.3 it returns 6)
 */
NSUInteger DeviceSystemMajorVersion()
{
    static NSUInteger _deviceSystemMajorVersion = -1;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _deviceSystemMajorVersion =
        [[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."][0] integerValue];
    });
    
    return _deviceSystemMajorVersion;
}

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
            NSDictionary *itemData = self.dataArray[self.datePickerIndexPath.section][self.datePickerIndexPath.row - 1];
            [targetedDatePicker setCountDownDuration:[[itemData valueForKey:kDateKey] doubleValue]];
        }
    }
}

/*! Determines if the UITableViewController has a UIDatePicker in any of its cells.
 */
- (BOOL)isInlineDatePickerInSection:(NSInteger)section
{
    return (self.datePickerIndexPath != nil && self.datePickerIndexPath.section == section);
}

/*! Determines if the given indexPath points to a cell that contains the UIDatePicker.
 
 @param indexPath The indexPath to check if it represents a cell with the UIDatePicker.
 */
- (BOOL)indexPathHasPicker:(NSIndexPath *)indexPath
{
    return ([self isInlineDatePickerInSection:indexPath.section] && self.datePickerIndexPath.row == indexPath.row);
}

/*! Determines if the given indexPath points to a cell that contains the start/end dates.
 
 @param indexPath The indexPath to check if it represents start/end date cell.
 */

- (BOOL)indexPathHasSwitch:(NSIndexPath *)indexPath
{
    BOOL hasSwitch = NO;
    
    if (indexPath.section == kFlowShortScaleSwitchSection && indexPath.row == kFlowShortScaleSwitchRow) {
        hasSwitch = YES;
    }
    
    return hasSwitch;
}

- (BOOL)indexPathHasDate:(NSIndexPath *)indexPath
{
    BOOL hasDate = NO;
    
    if (indexPath.section == kTimeIntervalSection && indexPath.row == kTimeIntervalRow) {
        hasDate = YES;
    }
    
    return hasDate;
}

- (BOOL)indexPathHasDummy:(NSIndexPath *)indexPath
{
    BOOL hasDummy = NO;
    
    if ((indexPath.section == kTimeIntervalDummySection && indexPath.row == kTimeIntervalDummyRow) || ([self isInlineDatePickerInSection:indexPath.section] && indexPath.row == kTimeIntervalDummyRow + 1 && indexPath.section == kTimeIntervalDummySection)) {
        hasDummy = YES;
    }
    
    return hasDummy;
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

