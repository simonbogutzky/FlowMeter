//
//  SplashScreenViewController.h
//  DataCollector
//
//  Created by Simon Bogutzky on 29.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <UIKit/UIKit.h>

// iPhone 5
#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

@interface SplashScreenViewController : UIViewController

@end
