//
//  MotionRecord+Description.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 21.01.15.
//  Copyright (c) 2015 Simon Bogutzky. All rights reserved.
//

#import "MotionRecord+Description.h"

@implementation MotionRecord (Description)

- (NSString *)csvDescription
{
    return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f\n",
            self.timestamp,
            self.userAccelerationX,
            self.userAccelerationY,
            self.userAccelerationZ,
            self.gravityX,
            self.gravityY,
            self.gravityZ,
            self.rotationRateX,
            self.rotationRateY,
            self.rotationRateZ,
            self.attitudePitch,
            self.attitudeRoll,
            self.attitudeYaw
            ];
}

- (NSString *)csvHeader
{
    return [NSMutableString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@\n",
                               NSLocalizedString(@"Zeitstempel (s)", @"Zeitstempel (s)"),
                               NSLocalizedString(@"Benutzerbeschleunigung X (Gs)", @"Benutzerbeschleunigung X (Gs)"),
                               NSLocalizedString(@"Benutzerbeschleunigung Y (Gs)", @"Benutzerbeschleunigung Y (Gs)"),
                               NSLocalizedString(@"Benutzerbeschleunigung Z (Gs)", @"Benutzerbeschleunigung Z (Gs)"),
                               NSLocalizedString(@"Gravitation X (Gs)", @"Gravitation X (Gs)"),
                               NSLocalizedString(@"Gravitation Y (Gs)", @"Gravitation Y (Gs)"),
                               NSLocalizedString(@"Gravitation Z (Gs)", @"Gravitation Z (Gs)"),
                               NSLocalizedString(@"Rotationsrate X (rad/s)", @"Rotationsrate X (rad/s)"),
                               NSLocalizedString(@"Rotationsrate Y (rad/s)", @"Rotationsrate Y (rad/s)"),
                               NSLocalizedString(@"Rotationsrate Z (rad/s)", @"Rotationsrate Z (rad/s)"),
                               NSLocalizedString(@"Pitch (rad)", @"Pitch (rad)"),
                               NSLocalizedString(@"Roll (rad)", @"Roll (rad)"),
                               NSLocalizedString(@"Yaw (rad)", @"Yaw (rad)")
                               ];
}

@end
