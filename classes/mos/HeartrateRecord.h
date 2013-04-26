//
//  HeartrateRecord.h
//  DataCollector
//
//  Created by Simon Bogutzky on 26.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session;

@interface HeartrateRecord : NSManagedObject

@property (nonatomic, retain) NSNumber * accumBeatCount;
@property (nonatomic, retain) NSNumber * timestamp;
@property (nonatomic, retain) Session *session;

@end
