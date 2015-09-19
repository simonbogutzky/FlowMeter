//
//  Session+OutStream.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 16.07.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "Session.h"

@interface Session (OutStream)

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *writeOut;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *writeOutArchive;

@end
