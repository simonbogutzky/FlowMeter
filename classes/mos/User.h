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

@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSSet *sessions;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addSessionsObject:(Session *)value;
- (void)removeSessionsObject:(Session *)value;
- (void)addSessions:(NSSet *)values;
- (void)removeSessions:(NSSet *)values;

@end
