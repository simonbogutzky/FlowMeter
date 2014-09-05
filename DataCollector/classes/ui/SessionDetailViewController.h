//
//  SessionDetailViewController.h
//  DataCollector
//
//  Created by Simon Bogutzky on 04.09.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import "MBProgressHUD.h"
#import "Session+OutStream.h"

@interface SessionDetailViewController : UIViewController <UIActionSheetDelegate, UIAlertViewDelegate, DBRestClientDelegate, MBProgressHUDDelegate>

@property (strong, nonatomic) Session *session;

@end
