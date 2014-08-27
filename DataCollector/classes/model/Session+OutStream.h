//
//  Session+OutStream.h
//  DataCollector
//
//  Created by Simon Bogutzky on 16.07.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "Session.h"

@interface Session (OutStream)

- (NSString *)writeOutSelfReports;
- (NSString *)zipSelfReports;
- (NSString *)writeOutHeartRateRecords;
- (NSString *)zipHeartRateRecords;

@end
