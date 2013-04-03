//
//  Utility.m
//  DataCollector
//
//  Created by Simon Bogutzky on 15.03.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "Utility.h"

@implementation Utility

+ (double)quantileFromX:(NSArray *)x prob:(double)prob
{
    NSMutableArray *x1 = [[NSMutableArray alloc] initWithArray:x];
    
    // Sort array
    NSSortDescriptor *lowestToHighest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [x1 sortUsingDescriptors:[NSArray arrayWithObject:lowestToHighest]];
    
    // Formula (see "http://de.wikipedia.org/wiki/Quantil")
    double np = [x1 count] * prob;
    if ([self isInteger:np]) {
        int i1 = np - 1;
        int i2 = np;
        return 0.5 * ([[x1 objectAtIndex:i1] doubleValue] + [[x1 objectAtIndex:i2] doubleValue]);
    }
    int i = ceil(np) - 1;
    return [[x1 objectAtIndex:i] doubleValue];
}

+ (bool)isInteger:(double)k
{
    return floor(k) == k;
}

@end