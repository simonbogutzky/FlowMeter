//
//  TCPConnectionManager.m
//  DataCollector
//
//  Created by Simon Bogutzky on 03.05.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "TCPConnectionManager.h"

@interface TCPConnectionManager() {
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
}

@end

@implementation TCPConnectionManager 

- (id)initWithDelegate:(id<NSStreamDelegate>)delegate
{
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)openStreamsWithHost:(NSString *)host port:(NSNumber *)port
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, [port intValue], &readStream, &writeStream);
    _inputStream = (__bridge NSInputStream *)readStream;
    _outputStream = (__bridge NSOutputStream *)writeStream;
    
    [_inputStream setDelegate:_delegate];
    [_outputStream setDelegate:_delegate];
    
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_inputStream open];
    [_outputStream open];
    
    _isStreamOpen = YES;
}

- (void)closeStreams
{
    [_inputStream close];
    [_outputStream close];
    
    _isStreamOpen = NO;
}

- (void)sendMessage:(NSString *)msg
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_isStreamOpen) {
            NSLog(@"# %@", msg);
            NSString *response  = [NSString stringWithFormat:@"%@", msg];
            NSData *rdata = [[NSData alloc] initWithData:[response dataUsingEncoding:NSUTF8StringEncoding]];
            [_outputStream write:[rdata bytes] maxLength:[rdata length]];
        }
    });

}

@end
