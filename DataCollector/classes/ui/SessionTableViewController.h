//
//  SessionTableViewController.h
//  DataCollector
//
//  Created by Simon Bogutzky on 23.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import "MBProgressHUD.h"

@interface SessionTableViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIActionSheetDelegate, DBRestClientDelegate, MBProgressHUDDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end
