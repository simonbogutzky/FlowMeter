//
//  PrefsTableViewController.h
//  DataCollector
//
//  Created by Simon Bogutzky on 19.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import <WFConnector/WFConnector.h>

@interface PrefsTableViewController : UITableViewController <WFSensorConnectionDelegate, UITextFieldDelegate>

@end
