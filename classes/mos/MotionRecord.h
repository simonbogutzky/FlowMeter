//
//  MotionRecord.h
//  DataCollector
//
//  Created by Simon Bogutzky on 25.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session;

@interface MotionRecord : NSManagedObject

@property (nonatomic, retain) NSNumber * timestamp;
@property (nonatomic, retain) NSNumber * rotationRateX;
@property (nonatomic, retain) Session *session;

@end
