//
//  CBAVPlayerView.m
//  MyAVPlayer
//
//  Created by 这个夏天有点冷 on 2017/4/18.
//  Copyright © 2017年 YLT. All rights reserved.
//

#import "CBAVPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIImage+CBAVPlayer.h"

#define R_G_B(_r_,_g_,_b_)          \
[UIColor colorWithRed:_r_/255. green:_g_/255. blue:_b_/255. alpha:1.0]
#define R_G_B_A(_r_,_g_,_b_,_a_)    \
[UIColor colorWithRed:_r_/255. green:_g_/255. blue:_b_/255. alpha:_a_]

typedef NS_ENUM(NSUInteger, CBDirection) {
    CBDirectionNone = 0,
    CBDirectionHorizontal,      //  水平方向滚动
    CBDirectionVertical,        //  垂直方向滚动
};

@interface CBAVPlayerView ()

@property (strong, nonatomic) UIView *topView;
@property (strong, nonatomic) UIView *toolView;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) UISlider *progressSlider;
@property (strong, nonatomic) UILabel *currentTimeLabel;
@property (strong, nonatomic) UILabel *totalTimeLabel;
@property (strong, nonatomic) UIButton *playBtn;            //  播放/暂停按钮

@property (assign, nonatomic) CBDirection direction;
@property (assign, nonatomic) CGPoint startPoint;
@property (assign, nonatomic) CGFloat startVB;
@property (assign, nonatomic) CGFloat startVideoRate;
@property (assign, nonatomic) CGFloat dur;

@property (strong, nonatomic) MPVolumeView *volumeView;     //  控制音量的view
@property (strong, nonatomic) UISlider *volumeViewSlider;   //  控制音量
@property (strong, nonatomic) UISlider *brightnessSlider;   //  控制亮度

@end

@implementation CBAVPlayerView

- (MPVolumeView *)volumeView
{
    if (!_volumeView) {
        _volumeView = [[MPVolumeView alloc] init];
        _volumeView.transform = CGAffineTransformMakeRotation(M_PI*(-0.5));
        [_volumeView setShowsVolumeSlider:YES];
        [_volumeView setShowsRouteButton:NO];
        
        for (UIView *view in _volumeView.subviews) {
            if ([view.class.description isEqualToString:@"MPVolumeSlider"]) {
                self.volumeViewSlider = (UISlider *)view;
                [self.volumeViewSlider setThumbImage:[UIImage getRoundImageWithColor:[UIColor whiteColor] size:CGSizeMake(10, 10)] forState:UIControlStateNormal];
                break;
            }
        }
    }
    
    return _volumeView;
}

- (UISlider *)brightnessSlider
{
    if (_brightnessSlider) {
        _brightnessSlider = [[UISlider alloc] init];
        _brightnessSlider.transform = CGAffineTransformMakeRotation(M_PI*(-0.5));
        [_brightnessSlider setThumbImage:[UIImage getRoundImageWithColor:[UIColor whiteColor] size:CGSizeMake(10, 10)] forState:UIControlStateNormal];
    }
    
    return _brightnessSlider;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self createViewWithFrame:frame];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    
    return self;
}

- (void)playWithUrl:(NSString *)url
{
    //  加载视频资源的类
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:url]];
    
    //AVURLAsset 通过tracks关键字会将资源异步加载在程序的一个临时内存缓冲区中
    [asset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler:^{
        //能够得到资源被加载的状态
        AVKeyValueStatus status = [asset statusOfValueForKey:@"tracks" error:nil];
        
        //如果资源加载完成,开始进行播放
        if (status == AVKeyValueStatusLoaded) {
            //将加载好的资源放入AVPlayerItem 中，item中包含视频资源数据,视频资源时长、当前播放的时间点等信息
            AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
            self.player = [[AVPlayer alloc] initWithPlayerItem:item];
            
            //将播放器与播放视图关联
            [self setMyPlayer:self.player];
            [self.player play];
            
            //  需要时时显示播放的进度
            //根据播放的帧数、速率，进行时间的异步(在子线程中完成)获取
            __weak AVPlayer *weekPlayer  = self.player;
            __weak UISlider *weekSlider = self.progressSlider;
            __weak UILabel *weekCurrentTimeLabel = self.currentTimeLabel;
            __weak UILabel *weekTotalTimeLabel = self.totalTimeLabel;
            
            __weak typeof(self) ws = self;
            [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_global_queue(0, 0) usingBlock:^(CMTime time) {
                //获取当前播放时间
                NSInteger current = CMTimeGetSeconds(weekPlayer.currentItem.currentTime);
                //总时间
                ws.dur = CMTimeGetSeconds(weekPlayer.currentItem.duration);
                
                float pro = current * 1.0 / self.dur;
                if (pro >= 0.0 && pro <= 1.0) {
                    //  回到主线程刷新UI
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weekSlider.value = pro;
                        weekCurrentTimeLabel.text = [ws getTime:current];
                        weekTotalTimeLabel.text = [ws getTime:ws.dur];
                    });
                }
            }];
        }
        
    }];
}

- (void)pause
{
    [self playBtnClicked:self.playBtn];
}

#pragma mark - 创建相关UI
- (void)createViewWithFrame:(CGRect)frame
{
    self.backgroundColor = [UIColor blackColor];
    
    //  控制音量view
    self.volumeView.frame = CGRectMake(frame.size.width - 30, (frame.size.height - 100) / 2.0, 20, 100);
    self.volumeView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    self.volumeView.hidden = YES;
    [self addSubview:self.volumeView];
    
    //  控制亮度
    self.brightnessSlider.frame = CGRectMake(20, (frame.size.height - 100) / 2.0, 20, 100);
    self.brightnessSlider.minimumValue = 0.0;
    self.brightnessSlider.maximumValue = 1.0;
    self.brightnessSlider.hidden = YES;
    [self.brightnessSlider addTarget:self action:@selector(brightnessChanged:) forControlEvents:UIControlEventValueChanged];
    self.brightnessSlider.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:self.brightnessSlider];
    
    //  顶部view
    self.topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 44)];
    self.topView.backgroundColor = R_G_B_A(50, 50, 50, 0.5);
    self.topView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.topView];
    
    //  返回按钮
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(10, 13, 50, 18);
    backBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [backBtn setTitle:@" 返回" forState:UIControlStateNormal];
    [backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [backBtn setImage:[UIImage imageNamed:@"back_white_small"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:backBtn];
    
    //  全屏按钮
    UIButton *fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    fullScreenBtn.frame = CGRectMake(CGRectGetMaxX(self.topView.frame)-40, 15, 35, 20);
    fullScreenBtn.titleLabel.font = [UIFont systemFontOfSize:11];
    fullScreenBtn.layer.masksToBounds = YES;
    fullScreenBtn.layer.cornerRadius = 3.0f;
    fullScreenBtn.layer.borderWidth = 1;
    fullScreenBtn.layer.borderColor = R_G_B(200, 200, 200).CGColor;
    [fullScreenBtn setTitle:@"全屏" forState:UIControlStateNormal];
    [fullScreenBtn setTitle:@"还原" forState:UIControlStateSelected];
    [fullScreenBtn setTitleColor:R_G_B(200, 200, 200) forState:UIControlStateNormal];
    [fullScreenBtn addTarget:self action:@selector(fullScreenBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    fullScreenBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.topView addSubview:fullScreenBtn];
    [self addSubview:self.topView];
    
    //  底部toolView
    self.toolView = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height-40, frame.size.width, 40)];
    self.toolView.backgroundColor = R_G_B_A(50, 50, 50, 0.5);
    self.toolView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.toolView];
    
    //  播放/暂停按钮
    self.playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playBtn.frame = CGRectMake(5, 10, 20, 20);
    self.playBtn.selected = YES;
    [self.playBtn setBackgroundImage:[UIImage imageNamed:@"player_play"] forState:UIControlStateNormal];
    [self.playBtn setBackgroundImage:[UIImage imageNamed:@"player_pause"] forState:UIControlStateSelected];
    [self.playBtn addTarget:self action:@selector(playBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.toolView addSubview:self.playBtn];
    
    //  当前播放事件label
    self.currentTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.playBtn.frame), 10, 40, 20)];
    self.currentTimeLabel.text = @"00:00";
    self.currentTimeLabel.textColor = [UIColor whiteColor];
    self.currentTimeLabel.font = [UIFont systemFontOfSize:8];
    self.currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    [self.toolView addSubview:self.currentTimeLabel];
    
    //  进度条
    self.progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.currentTimeLabel.frame), 12.5, frame.size.width-CGRectGetMaxX(self.currentTimeLabel.frame)-40, 15)];
    self.progressSlider.minimumValue = 0.0;
    self.progressSlider.maximumValue = 1.0;
    [self.progressSlider addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [self.progressSlider addTarget:self action:@selector(touchChange:) forControlEvents:UIControlEventValueChanged];
    [self.progressSlider addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    [self.progressSlider setThumbImage:[UIImage getRoundImageWithColor:[UIColor whiteColor] size:CGSizeMake(15, 15)] forState:UIControlStateNormal];
    self.progressSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.toolView addSubview:self.progressSlider];
    
    //  总的时间label
    self.totalTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.progressSlider.frame), 10, 40, 20)];
    self.totalTimeLabel.text = @"00:00";
    self.totalTimeLabel.textColor = [UIColor whiteColor];
    self.totalTimeLabel.font = [UIFont systemFontOfSize:8];
    self.totalTimeLabel.textAlignment = NSTextAlignmentCenter;
    self.totalTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.toolView addSubview:self.totalTimeLabel];
    
    //  添加点击手势
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGes:)];
    [self addGestureRecognizer:tapGR];
}

#pragma mark - 点击手势响应<隐藏和显示顶部和底部View>
- (void)tapGes:(UITapGestureRecognizer *)sender
{
    [UIView animateWithDuration:0.5 animations:^{
        self.topView.hidden = !self.topView.hidden;
        self.toolView.hidden = !self.toolView.hidden;
    }];
}

#pragma mark - topView中控件
#pragma mark -亮度调整改变
- (void)brightnessChanged:(UISlider *)slider
{
    [[UIScreen mainScreen] setBrightness:slider.value];
}

#pragma mark -返回按钮点击
- (void)goBack:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(goBack)]) {
        [self.delegate goBack];
    }
}

#pragma mark -全屏/还原按钮点击
- (void)fullScreenBtnClicked:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(fullScreen:)]) {
        [self.delegate fullScreen:sender];
    }
}

#pragma mark - toolView中事件
#pragma mark -播放/暂停按钮点击
- (void)playBtnClicked:(UIButton *)sender
{
    if (!self.player) {
        return;
    }
    
    if (sender.selected) {      //  暂停
        [self.player pause];
        sender.selected = NO;
        return;
    } else {        //  播放
        [self.player play];
        sender.selected = YES;
    }
}

#pragma mark -进度条滑动开始
- (void)touchDown:(UISlider *)slider
{
    if (!self.player) {
        return;
    }
    
    [self.player pause];
    self.playBtn.selected = NO;
}

#pragma mark -进度条滑动
- (void)touchChange:(UISlider *)slider
{
    if (!self.player) {
        return;
    }
    
    CMTime dur = self.player.currentItem.duration;
    float current = self.progressSlider.value;
    self.currentTimeLabel.text = [self getTime:(NSInteger)(current * self.dur)];
    //  跳转到指定时间
    [self.player seekToTime:CMTimeMultiplyByFloat64(dur, current)];
}

//将秒数换算成具体时长
- (NSString *)getTime:(NSInteger)second
{
    NSString *time;
    if (second < 60) {
        time = [NSString stringWithFormat:@"00:%02ld",(long)second];
    }
    else {
        if (second < 3600) {
            time = [NSString stringWithFormat:@"%02ld:%02ld",second/60,second%60];
        }
        else {
            time = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",second/3600,(second-second/3600*3600)/60,second%60];
        }
    }
    return time;
}

#pragma mark -进度条滑动结束
- (void)touchUp:(UISlider *)slider
{
    if (!self.player) {
        return;
    }
    
    [self.player play];
    self.playBtn.selected = YES;
}

- (void)setMyPlayer:(AVPlayer *)myPlayer
{
    AVPlayerLayer *playerLayer = (AVPlayerLayer *)self.layer;
    [playerLayer setPlayer:myPlayer];
}

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

#pragma mark - 滑动手势处理,亮度/音量/进度
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    self.direction = CBDirectionNone;
    
    //  记录首次触摸坐标
    self.startPoint = point;
    //  检测用户是触摸的屏幕的左边还是右边，以此判断用户是要调节音量还是亮度，左边是亮度，右边是音量
    if (self.startPoint.x <= self.bounds.size.width / 2.0) {
        //  亮度
        self.startVB = [UIScreen mainScreen].brightness;
    } else {
        //  音量
        self.startVB = self.volumeViewSlider.value;
    }
    
    CMTime ctime = self.player.currentTime;
    self.startVideoRate = ctime.value /ctime.timescale/self.dur;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    CGPoint panPoint = CGPointMake(point.x - self.startPoint.x, point.y - self.startPoint.y);
    if (self.direction == CBDirectionNone) {        //  分析出用户滑动的方向
        if (fabs(panPoint.x) >= 30) {
            [self.player pause];
            self.direction = CBDirectionHorizontal;
        } else if (fabs(panPoint.y) >= 30) {
            self.direction = CBDirectionVertical;
        } else {
            return;
        }
    }
    
    if (self.direction == CBDirectionHorizontal) {
        CGFloat rate = self.startVideoRate + (panPoint.x * 180 / (self.bounds.size.width * self.dur));
        if (rate > 1) {
            rate = 1;
        } else if (rate < 0) {
            rate = 0;
        }
        
        self.progressSlider.value = rate;
        
        CMTime dur = self.player.currentItem.duration;
        self.currentTimeLabel.text = [self getTime:(NSInteger)(rate*self.dur)];
        [self.player seekToTime:CMTimeMultiplyByFloat64(dur, rate)];
    } else if (self.direction == CBDirectionVertical) {
        CGFloat value = self.startVB - (panPoint.y / self.bounds.size.height);
        
        if (value > 1) {
            value = 1;
        } else if (value < 0) {
            value = 0;
        }
        
        if (self.startPoint.x <=  self.frame.size.width / 2.0) {
            //  亮度
            self.brightnessSlider.hidden = NO;
            self.brightnessSlider.value = value;
            [[UIScreen mainScreen] setBrightness:value];
        } else {
            //  音量
            self.volumeView.hidden = NO;
            [self.volumeViewSlider setValue:value];
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    if (self.direction == CBDirectionHorizontal) {
        [self.player play];
    } else if (self.direction == CBDirectionVertical) {
        self.volumeView.hidden = YES;
        self.brightnessSlider.hidden = YES;
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    
    if (self.direction == CBDirectionHorizontal) {
        [self.player play];
    } else if (self.direction == CBDirectionVertical) {
        self.volumeView.hidden = YES;
        self.brightnessSlider.hidden = YES;
    }
}

#pragma mark - 视频播放完毕
- (void)moviePlayerDidEnd:(NSNotification *)notifacation
{
    NSLog(@"视频播放完毕！");
}

- (void)dealloc
{
    NSLog(@"playerView释放了");
}

#pragma mark - 销毁player
- (void)releasePlayer
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.player) {
        [self.player pause];
        self.player = nil;
    }
    
    for (UIView *view in self.toolView.subviews) {
        [view removeFromSuperview];
    }
}

- (void)removeFromSuperview
{
    [self releasePlayer];
    [super removeFromSuperview];
}

@end
