//
//  MotionRecord+Description.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 21.01.15.
//  Copyright (c) 2015 Simon Bogutzky. All rights reserved.
//

#import "MotionRecord+Description.h"

@implementation MotionRecord (Description)

+ (NSString *)csvHeader
{
    return [NSString stringWithFormat:@"%@ \n\n%@,%@,%@,%@,%@,%@,%@,%@,%@,%@\n",
                               NSLocalizedString(@"Bewegungsdaten", @"Bewegungsdaten"),
                               NSLocalizedString(@"Zeitstempel (s)", @"Zeitstempel (s)"),
                               NSLocalizedString(@"Benutzerbeschleunigung X (Gs)", @"Benutzerbeschleunigung X (Gs)"),
                               NSLocalizedString(@"Benutzerbeschleunigung Y (Gs)", @"Benutzerbeschleunigung Y (Gs)"),
                               NSLocalizedString(@"Benutzerbeschleunigung Z (Gs)", @"Benutzerbeschleunigung Z (Gs)"),
                               NSLocalizedString(@"Gravitation X (Gs)", @"Gravitation X (Gs)"),
                               NSLocalizedString(@"Gravitation Y (Gs)", @"Gravitation Y (Gs)"),
                               NSLocalizedString(@"Gravitation Z (Gs)", @"Gravitation Z (Gs)"),
                               NSLocalizedString(@"Rotationsrate X (rad/s)", @"Rotationsrate X (rad/s)"),
                               NSLocalizedString(@"Rotationsrate Y (rad/s)", @"Rotationsrate Y (rad/s)"),
                               NSLocalizedString(@"Rotationsrate Z (rad/s)", @"Rotationsrate Z (rad/s)")
                               ];
}

@end
