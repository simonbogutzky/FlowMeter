//
//  User.h
//  DataCollector
//
//  Created by Simon Bogutzky on 06.05.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session;

@interface User : NSManagedObject

@property (nonatomic, strong) NSString * firstName;
@property (nonatomic, strong) NSNumber * isActive;
@property (nonatomic, strong) NSString * lastName;
@property (nonatomic, strong) NSString * username;
@property (nonatomic, strong) NSSet *sessions;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addSessionsObject:(Session *)value;
- (void)removeSessionsObject:(Session *)value;
- (void)addSessions:(NSSet *)values;
- (void)removeSessions:(NSSet *)values;

@end
