//
//  Utility.h
//  DataCollector
//
//  Created by Simon Bogutzky on 15.03.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utility : NSObject

+ (double)quantileWithX:(NSArray *)x prob:(double)prob;

@end
