//
//  YHSVolumeUtil.h
//  YHSVolumeExample
//
//  Created by YANGHAISHENG on 2016/12/12.
//  Copyright © 2016年 YANGHAISHENG. All rights reserved.
//

#import <UIKit/UIKit.h>


#pragma mark 通知：铃声/音量改变
UIKIT_EXTERN NSString * const AVSystemController_SystemVolumeDidChangeNotification;
#pragma mark 自定义通知：系统音量改变
UIKIT_EXTERN NSString * const Notification_Volume_Change;


@interface YHSVolumeUtil : NSObject

@property (nonatomic, assign) CGFloat volumeValue;

+ (YHSVolumeUtil *)shareInstance;

- (void)loadMPVolumeView;

- (void)registerVolumeChangeEvent;

- (void)unregisterVolumeChangeEvent;

#pragma mark - 循序渐进设置系统音量[0.0f ~ 1.0f]，否则会弹出音量提示框
- (void)setSystemVolumeStepByStep:(CGFloat)volume_param;


@end
