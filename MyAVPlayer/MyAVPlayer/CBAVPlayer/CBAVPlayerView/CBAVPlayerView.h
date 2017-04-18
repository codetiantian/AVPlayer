//
//  CBAVPlayerView.h
//  MyAVPlayer
//
//  Created by 这个夏天有点冷 on 2017/4/18.
//  Copyright © 2017年 YLT. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CBAVPlayerViewDelegate <NSObject>

@optional
- (void)goBack;
- (void)fullScreen:(UIButton *)btn;

@end

@interface CBAVPlayerView : UIView

@property (strong, nonatomic) UIButton *fullScreenBtn;
@property (weak, nonatomic) id<CBAVPlayerViewDelegate> delegate;

/**
 播放视频

 @param url 视频地址
 */
- (void)playWithUrl:(NSString *)url;

/**
 暂停
 */
- (void)pause;

@end
