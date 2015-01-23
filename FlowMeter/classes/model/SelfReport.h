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

@property (nonatomic, assign) double timestamp;
@property (nonatomic, assign) float flow;
@property (nonatomic, assign) float flowSD;
@property (nonatomic, assign) float fluency;
@property (nonatomic, assign) float fluencySD;
@property (nonatomic, assign) float absorption;
@property (nonatomic, assign) float absorptionSD;
@property (nonatomic, assign) float fit;
@property (nonatomic, assign) float fitSD;
@property (nonatomic, assign) float anxiety;
@property (nonatomic, assign) float anxietySD;
@property (nonatomic, assign) float duration;
@property (nonatomic, retain) Session *session;

@end
