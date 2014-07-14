//
//  SelfReport.m
//  DataCollector
//
//  Created by Simon Bogutzky on 27.01.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "SelfReport.h"

@implementation SelfReport

- (id)initWithTimestamp:(double)timestamp itemResponses:(NSArray *)itemResponses
{
    self = [super init];
    if (self) {
        self.timestamp = timestamp;
        self.responses = itemResponses;
    }
    return self;
}

- (NSString *)csvDescription
{
    return [NSString stringWithFormat:@"%f,%@\n",
            self.timestamp,
            [self.responses componentsJoinedByString:@","]
            ];
}

- (NSString *)csvHeader
{
    NSMutableString *header = [NSMutableString stringWithString:@"\"Timestamp\","];
    
    for (int i = 0; i < [self.responses count] - 1; i++) {
        [header appendFormat:@"\"Item %d\",", i + 1];
    }
    
    [header appendFormat:@"\"Item %d\"\n", [self.responses count]];
    return header;
}

@end
