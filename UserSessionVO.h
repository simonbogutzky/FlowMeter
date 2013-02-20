//
//  UserSessionVO.h
//  Client
//
//  Created by Simon Bogutzky on 05.04.12.
//  Copyright 2012 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserSessionVO : NSObject 

@property (nonatomic, strong) NSNumber *objectId;
@property (nonatomic, strong) NSDate *created;
@property (nonatomic, strong) NSDate *modified;
@property (nonatomic, strong) NSString *udid;


- (NSString *)xmlRepresentation;
- (void)setWithPropertyDictionary:(NSDictionary *)propertyDictionary;
- (void)seriliazeAsXML;
- (NSData *)seriliazeAndZipAsXML;
- (NSString*)textRepresentation;
- (NSData *)seriliazeAndZipAsText;
- (void)seriliazeAsText;

@end
