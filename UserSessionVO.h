//
//  UserSessionVO.h
//  Client
//
//  Created by Simon Bogutzky on 05.04.12.
//  Copyright 2012 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WFConnector/WFConnector.h>
#import "CMDeviceMotion+TransformToReferenceFrame.h"

@interface UserSessionVO : NSObject 

@property (nonatomic, strong) NSNumber *objectId;
@property (nonatomic, strong) NSDate *created;
@property (nonatomic, strong) NSDate *modified;
@property (nonatomic, strong) NSString *udid;

- (void)createMotionStorage;
- (NSString *)appendMotionData:(CMDeviceMotion *)deviceMotion;
- (NSString *)appendMotionData2:(CMDeviceMotion *)deviceMotion;
- (NSData *)seriliazeAndZipMotionData;
- (void)createHrStorage;
- (void)appendHrData:(WFHeartrateData *)hrData;
- (void)seriliazeAndZipHrData;
- (int)hrCount;

//- (NSString *)xmlRepresentation;
//- (void)setWithPropertyDictionary:(NSDictionary *)propertyDictionary;

@end
