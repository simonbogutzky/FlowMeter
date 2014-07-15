//
//  SelfReport+Description.m
//  DataCollector
//
//  Created by Simon Bogutzky on 27.01.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "SelfReport.h"

@implementation SelfReport (Description)

- (NSString *)csvDescription
{
    return [NSString stringWithFormat:@"%f,%@\n",
            [self.date timeIntervalSince1970],
            self.responses
            ];
}

- (NSString *)csvHeader
{
    NSMutableString *header = [NSMutableString stringWithString:@"\"Timestamp\","];
    
    for (int i = 1; i <= [self.numberOfItems intValue]; i++) {
        [header appendFormat:@"\"Item %d\",", i + 1];
    }
    return header;
}

@end
