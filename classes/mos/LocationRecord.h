//
//  LocationRecord.h
//  DataCollector
//
//  Created by Simon Bogutzky on 26.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session;

@interface LocationRecord : NSManagedObject

@property (nonatomic, retain) NSNumber * timestamp;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * altitude;
@property (nonatomic, retain) NSNumber * speed;
@property (nonatomic, retain) Session *session;

@end
