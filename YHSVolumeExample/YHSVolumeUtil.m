//
//  YHSVolumeUtil.m
//  YHSVolumeExample
//
//  Created by YANGHAISHENG on 2016/12/12.
//  Copyright © 2016年 YANGHAISHENG. All rights reserved.
//

#import "YHSVolumeUtil.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>


@interface YHSVolumeUtil ()

@property (nonatomic, strong) MPVolumeView *mpVolumeView;

@property (nonatomic, strong) UISlider *slider;

@end


@implementation YHSVolumeUtil

@synthesize volumeValue = _volumeValue;


#pragma mark 通知：铃声/音量改变
NSString * const AVSystemController_SystemVolumeDidChangeNotification  = @"AVSystemController_SystemVolumeDidChangeNotification";
#pragma mark 自定义通知：系统音量改变
NSString * const Notification_Volume_Change  = @"Notification_Volume_Change";



#pragma mark public methods
+ (YHSVolumeUtil *)shareInstance
{
    static YHSVolumeUtil *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        if (nil == _instance) {
            _instance = [[super allocWithZone:NULL] init];
        }
    });
    return _instance;
}


+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return [[self class] shareInstance];
}


- (id)copyWithZone:(struct _NSZone *)zone
{
    return [[self class] shareInstance];
}


- (void)loadMPVolumeView
{
    // 将 MPVolumeView 加入 window.subview 的形式，提前将MPVolumeView加入视图，作为全局的一个视图
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self.mpVolumeView];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];
}


- (void)registerVolumeChangeEvent
{
    NSError *error;
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(volumeChangedNotification:)
                                                 name:AVSystemController_SystemVolumeDidChangeNotification
                                               object:nil];
}


- (void)unregisterVolumeChangeEvent
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVSystemController_SystemVolumeDidChangeNotification
                                                  object:nil];
}


#pragma mark private methods
- (void)generateMPVolumeSlider
{
    for (UIView *view in [self.mpVolumeView subviews]) {
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            self.slider = (UISlider*)view;
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            [window addSubview:self.slider];
            break;
        }
    }
}


#pragma mark - Setters
- (void)setVolumeValue:(CGFloat) newValue
{
    _volumeValue = newValue;
    
    // 确保self.slider ！= nil
    if (!self.slider) {
        [self generateMPVolumeSlider];
    }
    // change system volume, the value is between 0.0f and 1.0f
    [self.slider setValue:newValue animated:NO];
    // send UI control event to make the change effect right now.
    [self.slider sendActionsForControlEvents:UIControlEventTouchUpInside];
}


#pragma mark - Getters
- (CGFloat)volumeValue
{
    // 确保self.slider ！= nil
    if (!self.slider) {
        [self generateMPVolumeSlider];
    }
    return self.slider.value;
}


- (MPVolumeView *)mpVolumeView
{
    if (!_mpVolumeView) {
        _mpVolumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-1000, -1000, 100, 100)];
        _mpVolumeView.hidden = NO;
        // 将 MPVolumeView 加入 window.subview 的形式，提前将MPVolumeView加入视图，作为全局的一个视图
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        [window addSubview:self.mpVolumeView];
    }
    return _mpVolumeView;
}


#pragma mark - NSNotification
- (void)volumeChangedNotification:(NSNotification *)notification
{
    /**
     通知：铃声改变
     "AVSystemController_AudioCategoryNotificationParameter" = Ringtone;    // 铃声改变
     "AVSystemController_AudioVolumeChangeReasonNotificationParameter" = ExplicitVolumeChange; // 改变原因
     "AVSystemController_AudioVolumeNotificationParameter" = "0.0625";  // 当前值
     "AVSystemController_UserVolumeAboveEUVolumeLimitNotificationParameter" = 0; 最小值
     
     通知：音量改变
     "AVSystemController_AudioCategoryNotificationParameter" = "Audio/Video"; // 音量改变
     "AVSystemController_AudioVolumeChangeReasonNotificationParameter" = ExplicitVolumeChange; // 改变原因
     "AVSystemController_AudioVolumeNotificationParameter" = "0.3";  // 当前值
     "AVSystemController_UserVolumeAboveEUVolumeLimitNotificationParameter" = 0; 最小值
     */
    
    NSString * style = [notification.userInfo objectForKey:@"AVSystemController_AudioCategoryNotificationParameter"];
    CGFloat value = [[notification.userInfo objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] doubleValue];
    if ([style isEqualToString:@"Ringtone"]) {
        NSLog(@"铃声改变");
    } else if ([style isEqualToString:@"Audio/Video"]) {
        NSLog(@"音量改变，当前值:%f", value);
    }
    
    self.volumeValue = value;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:Notification_Volume_Change object:nil];
}


#pragma mark - 循序渐进设置系统音量[0.0f ~ 1.0f]，否则会弹出音量提示框
- (void)setSystemVolumeStepByStep:(CGFloat)maxVolume
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
    NSNumber *currentVolume = [NSNumber numberWithFloat:musicPlayer.volume];
#pragma clang diagnostic pop
    
    // 系统音量需要待续渐近的变化
    {
        __block CGFloat volumeValue = currentVolume.floatValue;
        __block NSInteger timeCount = 0;
        __block BOOL isAddVolume = YES;
        if (currentVolume.floatValue <= maxVolume) {
            isAddVolume = YES;
            timeCount = (maxVolume-volumeValue) / 0.1f;
        } else {
            isAddVolume = NO;
            timeCount = (volumeValue-maxVolume) / 0.1f;
        }
        
        // 执行队列
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        // 计时器 dispatch_source_set_timer 自动生成
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 0.0 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(timer, ^{
            if (timeCount < 0) {
                dispatch_source_cancel(timer);
            } else {
                NSLog(@"Volume Change %ld times", timeCount);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (isAddVolume) {
                        if (volumeValue <= maxVolume) {
                            NSLog(@"Volume Change value => %f", volumeValue);
                            [[YHSVolumeUtil shareInstance] setVolumeValue:volumeValue];
                            volumeValue += 0.1;
                        }
                    } else {
                        if (volumeValue >= maxVolume) {
                            NSLog(@"Volume Change value => %f", volumeValue);
                            [[YHSVolumeUtil shareInstance] setVolumeValue:volumeValue];
                            volumeValue -= 0.1;
                        }
                    }
                });
                timeCount--;
            }
        });
        dispatch_resume(timer);
    } // 系统音量需要待续渐近的变化
    
}




@end



