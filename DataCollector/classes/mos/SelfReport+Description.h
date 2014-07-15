//
//  SelfReport+Description.h
//  DataCollector
//
//  Created by Simon Bogutzky on 27.01.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "SelfReport.h"

@interface SelfReport (Description)

@property (nonatomic) double timestamp;
@property (strong, nonatomic) NSArray *responses;

- (id)initWithTimestamp:(double)timestamp itemResponses:(NSArray *)itemResponses;
- (NSString *)csvDescription;
- (NSString *)csvHeader;

@end
