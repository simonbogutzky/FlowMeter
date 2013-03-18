//
//  Utility.m
//  DataCollector
//
//  Created by Simon Bogutzky on 15.03.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "Utility.h"

@implementation Utility

+ (double)quantileWithX:(NSMutableArray *)x prob:(double)prob
{
    // Sort array
    NSSortDescriptor *lowestToHighest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [x sortUsingDescriptors:[NSArray arrayWithObject:lowestToHighest]];
    
    // Formula (see "http://de.wikipedia.org/wiki/Quantil")
    double np = [x count] * prob;
    if ([self isInteger:np]) {
        int i1 = np - 1;
        int i2 = np;
        return 0.5 * ([[x objectAtIndex:i1] doubleValue] + [[x objectAtIndex:i2] doubleValue]);
    }
    int i = ceil(np) - 1;
    return [[x objectAtIndex:i] doubleValue];
}

+ (bool)isInteger:(double)k
{
    return floor(k) == k;
}

@end
