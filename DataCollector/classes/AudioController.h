//
//  AudioController.h
//  DataCollector
//
//  Created by Simon Bogutzky on 22.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PdAudioController.h"
#import "PdDispatcher.h"

@interface AudioController : NSObject

@property (nonatomic, strong) PdAudioController *audioController;
@property (nonatomic, strong) PdDispatcher *dispatcher;
@property (nonatomic, assign) void *patch;

+ (AudioController *)sharedAudioController;

- (void)playE;
- (void)playB;
- (void)playNote:(int)n;

@end
