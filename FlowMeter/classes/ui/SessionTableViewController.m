//
//  SessionTableViewController.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 23.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "SessionTableViewController.h"
#import "AppDelegate.h"
#import "Session.h"
#import "User.h"
#import "Activity.h"
#import "SessionDetailViewController.h"

@interface SessionTableViewController ()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readonly) NSDateFormatter *dateFormatter;
@property (nonatomic, readonly) NSDateFormatter *dateFormatterDay;
@property (nonatomic, readonly) NSNumberFormatter *numberFormatter;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *deleteButton;
@end

@implementation SessionTableViewController

#pragma mark -
#pragma mark - Getter

- (AppDelegate *)appDelegate
{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

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
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.appDelegate.managedObjectContext sectionNameKeyPath:@"sectionTitle" cacheName:nil];
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

- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    return dateFormatter;
}

- (NSDateFormatter *)dateFormatterDay
{
    static NSDateFormatter *dateFormatterDay = nil;
    if (dateFormatterDay == nil) {
        dateFormatterDay = [[NSDateFormatter alloc] init];
        NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"EEEE" options:0 locale:[NSLocale currentLocale]];
        [dateFormatterDay setDateFormat:formatString];
    }
    return dateFormatterDay;
}

- (NSNumberFormatter *)numberFormatter
{
    static NSNumberFormatter *numberFormatter = nil;
    if (numberFormatter == nil) {
        numberFormatter = [[NSNumberFormatter alloc] init];
        numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        numberFormatter.alwaysShowsDecimalSeparator = YES;
        numberFormatter.minimumFractionDigits = 1;
        numberFormatter.maximumFractionDigits = 1;
    }
    return numberFormatter;
}

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    // make our view consistent
    [self updateButtonsToMatchTableState];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.fetchedResultsController != nil) {
        self.fetchedResultsController.delegate = self;
        
        NSError *error = nil;
        if (![self.fetchedResultsController performFetch:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        [self.tableView reloadData];
    }
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.fetchedResultsController.delegate = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Session Details"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Session *session = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        [(SessionDetailViewController *)[segue destinationViewController] setSession:session];
    }
}

#pragma mark -
#pragma mark - IBActions

- (IBAction)editAction:(id)sender
{
    [self.tableView setEditing:YES animated:YES];
    [self updateButtonsToMatchTableState];
}

- (IBAction)cancelAction:(id)sender
{
    [self.tableView setEditing:NO animated:YES];
    [self updateButtonsToMatchTableState];
}

- (IBAction)deleteAction:(id)sender
{
    // Open a dialog with just an OK button.
    NSString *actionTitle;
    if (([[self.tableView indexPathsForSelectedRows] count] == 1)) {
        actionTitle = NSLocalizedString(@"Bist du sicher, dass du diese Flow-Messung entfernen willst?", @"");
    }
    else
    {
        actionTitle = NSLocalizedString(@"Bist du sicher, dass du diese Flow-Messungen entfernen willst?", @"");
    }
    
    NSString *cancelTitle = NSLocalizedString(@"Abbrechen", @"Cancel title for item removal action");
    NSString *OKTitle = NSLocalizedString(@"OK", @"OK title for item removal action");
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:actionTitle
                                                             delegate:self
                                                    cancelButtonTitle:cancelTitle
                                               destructiveButtonTitle:OKTitle
                                                    otherButtonTitles:nil];
    
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    
    // Show from our table view (pops up in the middle of the table).
    [actionSheet showInView:self.view];
}

#pragma mark -
#pragma mark - UITableViewDelegate implementation

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];
    NSDate *date = [dateFormatter dateFromString:[self tableView:tableView titleForHeaderInSection:section]];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 24)];
    
    UILabel *labelDay = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, (tableView.frame.size.width / 2) - 10, 24)];
    [labelDay setFont:[UIFont boldSystemFontOfSize:12]];
    [labelDay setText:[self.dateFormatterDay stringFromDate:date]];
    [labelDay setTextColor:[UIColor colorWithRed:166/255.0 green:170/255.0 blue:169/255.0 alpha:1.0]];
    [view addSubview:labelDay];
    
    UILabel *labelDate = [[UILabel alloc] initWithFrame:CGRectMake(tableView.frame.size.width / 2, 0, (tableView.frame.size.width / 2) - 10, 24)];
    [labelDate setFont:[UIFont boldSystemFontOfSize:12]];
    [labelDate setText:[self.dateFormatter stringFromDate:date]];
    [labelDate setTextColor:[UIColor colorWithRed:166/255.0 green:170/255.0 blue:169/255.0 alpha:1.0]];
    [labelDate setTextAlignment:NSTextAlignmentRight];
    [view addSubview:labelDate];
    
    [view setBackgroundColor:[UIColor colorWithRed:236/255.0 green:241/255.0 blue:244/255.0 alpha:1.0]];
    
    labelDate.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    labelDay.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 24.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Update the delete button's title based on how many items are selected.
    [self updateDeleteButtonTitle];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Update the delete button's title based on how many items are selected.
    [self updateButtonsToMatchTableState];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    return !self.tableView.editing;
}

#pragma mark -
#pragma mark - UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[[self.fetchedResultsController sections] objectAtIndex:section] name];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Session Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
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

#pragma mark -
#pragma mark - NSFetchedResultsControllerDelegate implementation

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

#pragma mark -
#pragma mark - UIActionSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // The user tapped one of the OK/Cancel buttons.
    if (buttonIndex == 0)
    {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        
        // Delete what the user selected.
        NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
        BOOL deleteSpecificRows = selectedRows.count > 0;
        if (deleteSpecificRows)
        {
            for (NSIndexPath *selectionIndex in selectedRows)
            {
                [context deleteObject:[self.fetchedResultsController objectAtIndexPath:selectionIndex]];
            }
        }
        else
        {
            for (NSManagedObject *objects in [self.fetchedResultsController fetchedObjects]) {
                [context deleteObject:objects];
            }
        }
        
        NSError *error = nil;
        if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        // Exit editing mode after the deletion.
        [self.tableView setEditing:NO animated:YES];
        [self updateButtonsToMatchTableState];
    }
}

#pragma mark -
#pragma mark - Convenient methods

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Session *session = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    UILabel *labelFlowScore = (UILabel *)[cell viewWithTag:100];
    labelFlowScore.text = [self.numberFormatter stringFromNumber:session.averageFlow];
    
    UILabel *labelUsername = (UILabel *)[cell viewWithTag:101];
    labelUsername.text = [NSString stringWithFormat:@"%@ %@", session.user.firstName, session.user.lastName];
    
    UILabel *labelActivity = (UILabel *)[cell viewWithTag:102];
    labelActivity.text = session.activity.name;
    
    UILabel *labelSelfReportCount = (UILabel *)[cell viewWithTag:104];
    labelSelfReportCount.text = [NSString stringWithFormat:@"%d", [session.selfReportCount intValue]];
    
    UILabel *labelAverageHeartrate = (UILabel *)[cell viewWithTag:106];
    labelAverageHeartrate.text = [NSString stringWithFormat:@"%d", [session.averageHeartrate intValue]];
    
    UILabel *labelDuration = (UILabel *)[cell viewWithTag:107];
    labelDuration.text = [self stringFromTimeInterval:[session.duration doubleValue]];
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval
{
    NSInteger ti = (NSInteger)interval;
    //NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ldh %02ldm", (long)hours, (long)minutes];
}

#pragma mark -
#pragma mark - Updating button state

- (void)updateButtonsToMatchTableState
{
    if (self.tableView.editing)
    {
        // Show the option to cancel the edit.
        self.navigationItem.rightBarButtonItem = self.cancelButton;
        
        [self updateDeleteButtonTitle];
        
        // Show the delete button.
        self.navigationItem.leftBarButtonItem = self.deleteButton;
    }
    else
    {
        // Not in editing mode.
        self.navigationItem.leftBarButtonItem = nil;
        
        // Show the edit button, but disable the edit button if there's nothing to edit.
        if ([[self.fetchedResultsController sections] count] > 0)
        {
            self.editButton.enabled = YES;
        }
        else
        {
            self.editButton.enabled = NO;
        }
        self.navigationItem.rightBarButtonItem = self.editButton;
    }
}

- (void)updateDeleteButtonTitle
{
    // Update the delete button's title, based on how many items are selected
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    
    int rowCount = 0;
    for (id <NSFetchedResultsSectionInfo> sectionInfo in [self.fetchedResultsController sections]) {
        rowCount += [sectionInfo numberOfObjects];
    }
    
    BOOL allItemsAreSelected = selectedRows.count == rowCount;
    BOOL noItemsAreSelected = selectedRows.count == 0;
    
    if (allItemsAreSelected || noItemsAreSelected)
    {
        self.deleteButton.title = NSLocalizedString(@"Alle Löschen", @"");
    }
    else
    {
        NSString *titleFormatString =
        NSLocalizedString(@"Lösche (%d)", @"Title for delete button with placeholder for number");
        self.deleteButton.title = [NSString stringWithFormat:titleFormatString, selectedRows.count];
    }
}

@end
