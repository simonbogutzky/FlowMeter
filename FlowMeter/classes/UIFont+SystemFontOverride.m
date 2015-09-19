//
//  UIFont+SystemFontOverride.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 19.09.15.
//  Copyright © 2015 Simon Bogutzky. All rights reserved.
//

#import "UIFont+SystemFontOverride.h"

@implementation UIFont (SystemFontOverride)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

+ (UIFont *)boldSystemFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"HelveticaNeue-Bold" size:fontSize];
}

+ (UIFont *)systemFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"HelveticaNeue" size:fontSize];
}

#pragma clang diagnostic pop

@end
