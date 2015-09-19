//
//  LocationRecord+Description.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 06.02.15.
//  Copyright (c) 2015 Simon Bogutzky. All rights reserved.
//

#import "LocationRecord.h"

@interface LocationRecord (Description)

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *csvDescription;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *csvHeader;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *kmlPathHeader;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *kmlTimelineHeader;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *kmlPathFooter;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *kmlTimelineFooter;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *kmlPathDescription;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *kmlTimelineDescription;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *kmlHeader;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *kmlFooter;

@end
