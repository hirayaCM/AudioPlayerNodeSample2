//
//  BufferPlayerViewController.m
//  AVAudioPlayerNodeSample2
//
//  Created by hiraya.shingo on 2015/02/06.
//  Copyright (c) 2015年 Shingo Hiraya. All rights reserved.
//

#import "BufferPlayerViewController.h"

@import AVFoundation;

@interface BufferPlayerViewController ()

@property (nonatomic, strong) AVAudioEngine *engine;
@property (nonatomic, strong) AVAudioPlayerNode *audioPlayerNode;
@property (nonatomic, strong) AVAudioFile *audioFile;
@property (nonatomic, strong) AVAudioPCMBuffer *audioPCMBuffer;
@property (nonatomic, weak) IBOutlet UISwitch *loopSwitch;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation BufferPlayerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.engine = [AVAudioEngine new];
    
    // Prepare AVAudioFile
    NSString *path = [[NSBundle mainBundle] pathForResource:@"loop.m4a" ofType:nil];
    self.audioFile = [[AVAudioFile alloc] initForReading:[NSURL fileURLWithPath:path]
                                                   error:nil];
    
    // Prepare Buffer
    AVAudioFormat *audioFormat = self.audioFile.processingFormat;
    AVAudioFrameCount length = (AVAudioFrameCount)self.audioFile.length;
    self.audioPCMBuffer = [[AVAudioPCMBuffer alloc]initWithPCMFormat:audioFormat frameCapacity:length];
    [self.audioFile readIntoBuffer:self.audioPCMBuffer error:nil];
    
    // Prepare AVAudioPlayerNode
    self.audioPlayerNode = [AVAudioPlayerNode new];
    [self.engine attachNode:self.audioPlayerNode];
    
    // Connect Nodes
    AVAudioMixerNode *mixerNode = [self.engine mainMixerNode];
    [self.engine connect:self.audioPlayerNode
                      to:mixerNode
                  format:self.audioFile.processingFormat];
    
    // Start engine
    NSError *error;
    [self.engine startAndReturnError:&error];
    if (error) {
        NSLog(@"error:%@", error);
    }
}

#pragma mark - private methods

- (void)play
{
    // Schedule playing audio buffer 
    if (self.loopSwitch.isOn) {
        [self.audioPlayerNode scheduleBuffer:self.audioPCMBuffer
                                      atTime:nil
                                     options:AVAudioPlayerNodeBufferLoops
                           completionHandler:nil];
    } else {
        [self.audioPlayerNode scheduleBuffer:self.audioPCMBuffer
                                      atTime:nil
                                     options:AVAudioPlayerNodeBufferInterrupts
                           completionHandler:nil];
    }
    
    // Start playback
    [self.audioPlayerNode play];
}

- (IBAction)didTapPlayButton:(id)sender
{
    if (self.audioPlayerNode.isPlaying) {
        [self.audioPlayerNode stop];
        [self stopTimer];
    } else {
        [self play];
        [self startTimer];
    }
}

- (IBAction)didChangeVolumeSliderValue:(id)sender
{
    float value = ((UISlider *)sender).value;
    self.audioPlayerNode.volume = value;
}

- (IBAction)didChangePanSliderValue:(id)sender
{
    float value = ((UISlider *)sender).value;
    self.audioPlayerNode.pan = value;
}

- (void)startTimer
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                             target:self
                                                selector:@selector(updateSlider:)
                                           userInfo:nil
                                            repeats:YES];
}

- (void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)updateSlider:(id)sender
{
    // PlayerTime:停止するとゼロに戻る
    // NodeTime:トータルの秒数？
    
    // TODO: 一時停止するとどうなる?
    
    NSLog(@"PlayerTime: %.2f/%.2f   NodeTime  : %.2f/%.2f", self.currentTimeInSeconds, self.totalTimeInSeconds, self.currentNodeTimeInSeconds, self.totalTimeInSeconds);
}

- (NSTimeInterval)currentTimeInSeconds
{
    AVAudioTime *nodeTime = self.audioPlayerNode.lastRenderTime;
    AVAudioTime *playerTime = [self.audioPlayerNode playerTimeForNodeTime:nodeTime];
    
    NSTimeInterval seconds = (double)playerTime.sampleTime / playerTime.sampleRate;
    return seconds;
}

- (NSTimeInterval)currentNodeTimeInSeconds
{
    AVAudioTime *nodeTime = self.audioPlayerNode.lastRenderTime;
    NSTimeInterval seconds = (double)nodeTime.sampleTime / nodeTime.sampleRate;
    return seconds;
}

- (NSTimeInterval)totalTimeInSeconds
{
    NSTimeInterval seconds = self.audioFile.length / self.audioFile.fileFormat.sampleRate;
    return seconds;
}

@end
