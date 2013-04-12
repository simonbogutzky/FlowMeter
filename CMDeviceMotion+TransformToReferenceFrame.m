//
//  CMDeviceMotion+TransformToReferenceFrame.m
//  DataCollector
//
//  Created by Simon Bogutzky on 11.02.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "CMDeviceMotion+TransformToReferenceFrame.h"
#import <GLKit/GLKit.h>

@implementation CMDeviceMotion (TransformToReferenceFrame)

-(CMAcceleration)userAccelerationInReferenceFrame
{
    // Get the attitude rotation matrix
    CMRotationMatrix rotationMatrix = self.attitude.rotationMatrix;
    GLKMatrix3 matrix = GLKMatrix3Make(rotationMatrix.m11, rotationMatrix.m12, rotationMatrix.m13, rotationMatrix.m21, rotationMatrix.m22, rotationMatrix.m23, rotationMatrix.m31, rotationMatrix.m32, rotationMatrix.m33);
    NSLog(@"%@", NSStringFromGLKMatrix3(matrix));
    
    // Compute the inverse matrix
    bool *isInvertible = NULL;
    GLKMatrix3 iMatrix = GLKMatrix3Invert(matrix, isInvertible);
    NSLog(@"%@", NSStringFromGLKMatrix3(iMatrix));
    NSLog(@"%@", isInvertible ? @"NO" : @"YES");
    
    // Multiplying the inverse matrix with user acceleration vector.
    CMAcceleration userAcceleration = self.userAcceleration;
    GLKVector3 vector = GLKVector3Make(userAcceleration.x, userAcceleration.y, userAcceleration.y);
    NSLog(@"%@", NSStringFromGLKVector3(vector));
    GLKVector3 rVector = GLKMatrix3MultiplyVector3(iMatrix, vector);
    NSLog(@"%@", NSStringFromGLKVector3(rVector));
    CMAcceleration relativeAcceleration;
    relativeAcceleration.x = rVector.x;
    relativeAcceleration.y = rVector.y;
    relativeAcceleration.z = rVector.z;
    
    return relativeAcceleration;
}

@end
