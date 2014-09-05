//
//  SelfReport.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 29.08.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session;

@interface SelfReport : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * flow;
@property (nonatomic, retain) NSNumber * flowSD;
@property (nonatomic, retain) NSNumber * fluency;
@property (nonatomic, retain) NSNumber * fluencySD;
@property (nonatomic, retain) NSNumber * absorption;
@property (nonatomic, retain) NSNumber * absorptionSD;
@property (nonatomic, retain) NSNumber * fit;
@property (nonatomic, retain) NSNumber * fitSD;
@property (nonatomic, retain) NSNumber * anxiety;
@property (nonatomic, retain) NSNumber * anxietySD;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) Session *session;

@end
