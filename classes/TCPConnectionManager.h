//
//  TCPConnectionManager.h
//  DataCollector
//
//  Created by Simon Bogutzky on 03.05.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCPConnectionManager : NSObject

@property (nonatomic, weak) id<NSStreamDelegate> delegate;
@property (nonatomic) BOOL isStreamOpen;

- (id)initWithDelegate:(id<NSStreamDelegate>)delegate;
- (void)openStreamsWithHost:(NSString *)host port:(NSNumber *)port;
- (void)closeStreams;
- (void)sendMessage:(NSString *)msg;

@end

