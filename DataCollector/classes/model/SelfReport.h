//
//  SelfReport.h
//  DataCollector
//
//  Created by Simon Bogutzky on 15.07.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session;

@interface SelfReport : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * responses;
@property (nonatomic, retain) Session *session;

@end
