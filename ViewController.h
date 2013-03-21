//
//  ViewController.h
//  DataCollector
//
//  Created by Simon Bogutzky on 16.01.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFConnector/WFConnector.h>
#import "PdDispatcher.h"

@interface ViewController : UIViewController <WFSensorConnectionDelegate>
{
    PdDispatcher *dispatcher;
    void *patch;

}
@end
