//
//  HeartRateRecord.h
//  DataCollector
//
//  Created by Simon Bogutzky on 25.08.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session;

@interface HeartRateRecord : NSManagedObject

@property (nonatomic, retain) NSNumber * timeInterval;
@property (nonatomic, retain) Session *session;

@end
