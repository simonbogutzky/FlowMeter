//
//  EditViewController.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 03.05.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "EditViewController.h"
#import "AppDelegate.h"

@interface EditViewController ()

@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *barButtonItemDone;
@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSArray *option;

@end

@implementation EditViewController

#pragma mark -
#pragma mark - Getter

- (AppDelegate *)appDelegate
{
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

#pragma mark -
#pragma mark - UIViewControllerDelegate implementation

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.topItem.title = (self.itemDictionary)[kTitleKey];
    self.textField.text = @"";
    
    if ([[self.itemDictionary valueForKey:kValueKey] isKindOfClass:[NSNumber class]]) {
        self.textField.keyboardType = UIKeyboardTypeNumberPad;
        self.option = @[];
        self.tableView.hidden = YES;
        self.barButtonItemDone.enabled = YES;
        self.barButtonItemDone.tintColor = nil;
    } else {
        self.textField.placeholder = (self.itemDictionary)[kTitleKey];
        self.barButtonItemDone.enabled = NO;
        self.barButtonItemDone.tintColor = [UIColor clearColor];
        self.option = [self getDisplayNameStrings];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    [self.textField becomeFirstResponder];
}

#pragma mark -
#pragma mark - UITableViewDelegate implementation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.itemDictionary setValue:(self.option)[indexPath.row] forKey:kValueKey];
    [self dismissViewController];
}

#pragma mark -
#pragma mark - UITableViewDataSource implementation

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.option.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Option Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

#pragma mark -
#pragma mark - IBActions

- (IBAction)doneTouched:(id)sender
{
    if ([[self.itemDictionary valueForKey:kValueKey] isKindOfClass:[NSNumber class]]) {
        if (![self.textField.text isEqualToString:@""]) {
            [self.itemDictionary setValue:@((self.textField.text).intValue) forKey:kValueKey];
        }
    } else {
        [self.itemDictionary setValue:[self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] forKey:kValueKey];
        if ([self.textField.text isEqualToString:@""]) {
            [self.itemDictionary setValue:@" " forKey:kValueKey];
        }
    }
    [self.textField resignFirstResponder];
}

- (IBAction)cancelTouched:(id)sender
{
    [self dismissViewController];
}

#pragma mark -
#pragma mark - Convenient methods

- (void)keyboardDidHide:(NSNotification *)notification
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSArray *)getDisplayNameStrings
{
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:(self.itemDictionary)[kEntityKey] inManagedObjectContext:self.appDelegate.managedObjectContext];
    fetchRequest.entity = entity;
    
    NSArray *fetchedObjects = [self.appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects == nil) {
        return @[];
    }
    
    NSMutableArray *displayNameStrings = [NSMutableArray array];
    for (NSManagedObject *object in fetchedObjects) {
        [displayNameStrings addObject:[object valueForKey:(self.itemDictionary)[kPropertyKey]]];
    }
    
    return displayNameStrings;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.text = (self.option)[indexPath.row];
}

- (void)dismissViewController
{
    if (![self.textField isFirstResponder]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    [self.textField resignFirstResponder];
}

@end
