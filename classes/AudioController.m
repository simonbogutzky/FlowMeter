//
//  AudioController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 22.04.13.
//  Copyright (c) 2013 Simon Bogutzky. All rights reserved.
//

#import "AudioController.h"

@implementation AudioController

+ (AudioController *)sharedAudioController
{
    static AudioController *_sharedAudioController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedAudioController = [[AudioController alloc] init];
        _sharedAudioController.audioController = [[PdAudioController alloc] init];
        if ([_sharedAudioController.audioController configurePlaybackWithSampleRate:44100 numberChannels:2 inputEnabled:NO mixingEnabled:YES] != PdAudioOK) {
            NSLog(@"failed to initialize audio components");
        } else {
            _sharedAudioController.dispatcher = [[PdDispatcher alloc]init];
            [PdBase setDelegate:_sharedAudioController.dispatcher];
            _sharedAudioController.patch = [PdBase openFile:@"tuner.pd"
                                 path:[[NSBundle mainBundle] resourcePath]];
            if (!_sharedAudioController.patch) {
                NSLog(@"Failed to open patch!"); // Gracefully handle failure...
            }
        }
    });
    return _sharedAudioController;
}

- (void)playE
{
    // E-string (high)
    [self playNote:64];
}

- (void)playB
{
    // B-string
    [self playNote:59];
}

- (void)playNote:(int)n
{
    [PdBase sendFloat:n toReceiver:@"midinote"];
    [PdBase sendBangToReceiver:@"trigger"];
}

@end
