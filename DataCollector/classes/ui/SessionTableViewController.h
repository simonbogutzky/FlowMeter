//
//  SessionTableViewController.h
//  DataCollector
//
//  Created by Simon Bogutzky on 23.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SessionTableViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end
