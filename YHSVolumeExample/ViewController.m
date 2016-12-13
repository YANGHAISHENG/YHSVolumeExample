//
//  ViewController.m
//  YHSVolumeExample
//
//  Created by YANGHAISHENG on 2016/12/12.
//  Copyright © 2016年 YANGHAISHENG. All rights reserved.
//

#import "ViewController.h"
#import "YHSVolumeUtil.h"
#import <MediaPlayer/MediaPlayer.h>


@interface ViewController ()
@property (nonnull, nonatomic, strong) UILabel *label;
@property (nonnull, nonatomic, strong) UISlider *slider;
@end


@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 标题
    self.title = @"声音控制";
    
    // 当前系统音量
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
    NSNumber *nowVolume = [NSNumber numberWithFloat:musicPlayer.volume];
#pragma clang diagnostic pop
    
    
    // 滑块控件
    self.slider = ({
        CGFloat screen_width = [[UIScreen mainScreen] bounds].size.width;
        CGRect sliderFrame = CGRectMake(20, 100, screen_width - 40, 50); // 这里无论高度设为多少，都按其自己的默认高度显示
        UISlider * slider = [[UISlider alloc] initWithFrame:sliderFrame];
        [self.view addSubview:slider];
        [slider setMinimumValue:0.0f]; // 设置最小值
        [slider setMaximumValue:1.0f]; // 设置最大值
        [slider setValue:nowVolume.floatValue]; // 设置默认值
        [slider setContinuous:YES]; //默认YES；如果设置为NO，则每次滑块停止移动后才触发事件
        [slider addTarget:self action:@selector(sliderChange:) forControlEvents:UIControlEventValueChanged];
        
        slider;
    });
    
    
    // 音量提示
    self.label = ({
        CGFloat screen_width = [[UIScreen mainScreen] bounds].size.width;
        CGRect labelFrame = CGRectMake(20, CGRectGetMaxY(self.slider.frame)+30, screen_width - 40, 50);
        UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
        [self.view addSubview:label];
        [label setText:[NSString stringWithFormat:@"音量：%f", nowVolume.floatValue]];
        
        label;
    });

}



- (void) sliderChange:(id)sender
{
    if ([sender isKindOfClass:[UISlider class]]) {
        UISlider * slider = sender;
        //NSLog(@"音量：%f", slider.value);
        [self.label setText:[NSString stringWithFormat:@"音量：%f", slider.value]];
        [[YHSVolumeUtil shareInstance] setSystemVolumeStepByStep:slider.value];
    }
}


@end


