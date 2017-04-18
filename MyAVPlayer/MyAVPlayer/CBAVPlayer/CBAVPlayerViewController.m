//
//  CBAVPlayerViewController.m
//  MyAVPlayer
//
//  Created by 这个夏天有点冷 on 2017/4/18.
//  Copyright © 2017年 YLT. All rights reserved.
//

#import "CBAVPlayerViewController.h"
#import "CBAVPlayerView.h"
#import <CoreMotion/CoreMotion.h>

#define CB_SCREEN_BOUNDS  [UIScreen mainScreen].bounds

@interface CBAVPlayerViewController () <CBAVPlayerViewDelegate>

@property (copy, nonatomic) NSString *strUrl;
@property (strong, nonatomic) CBAVPlayerView *playerView;

@end

@implementation CBAVPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initCurrentPlayerView];
}

- (instancetype)initWithVideoUrl:(NSString *)videoUrl
{
    self = [super init];
    
    if (self) {
        self.strUrl = videoUrl;
    }
    
    return self;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)initCurrentPlayerView
{
    //  设备旋转
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    //监听横竖屏切换
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    //监听程序进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:)name:UIApplicationWillResignActiveNotification object:nil];
    
    //  创建View
    [self createViews];
}

- (void)createViews
{
    self.playerView = [[CBAVPlayerView alloc] initWithFrame:self.view.bounds];
    self.playerView.delegate = self;
    [self.playerView playWithUrl:self.strUrl];
    [self.view addSubview:self.playerView];
}

- (void)orientationChanged:(NSNotification *)notification
{
    if (!self.playerView) {
        return;
    }
    
//    UIDeviceOrientation currentOrientation = [UIDevice currentDevice].orientation;
//    if (currentOrientation == UIDeviceOrientationFaceUp) {
//        return;
//    }
//    
//    static CGFloat rotation;
//    if (currentOrientation == UIDeviceOrientationLandscapeLeft) {
//        rotation = 0.5;
//        self.playerView.fullScreenBtn.selected = YES;
//    } else if (currentOrientation == UIDeviceOrientationLandscapeRight) {
//        rotation = -0.5;
//        self.playerView.fullScreenBtn.selected = YES;
//    } else {
//        rotation = 0;
//        self.playerView.fullScreenBtn.selected = NO;
//    }
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//       [UIView animateWithDuration:0.25 animations:^{
//           self.view.transform = CGAffineTransformMakeRotation(M_PI*(rotation));
//           self.view.frame = CB_SCREEN_BOUNDS;
//           self.playerView.frame = self.view.bounds;
//       }];
//    });
    
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    
    UIInterfaceOrientation ori = (UIInterfaceOrientation)orientation;
    
    switch (ori) {
        case UIInterfaceOrientationPortrait:
            NSLog(@"正竖屏");
            self.playerView.fullScreenBtn.selected = NO;
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            NSLog(@"逆竖屏");
            self.playerView.fullScreenBtn.selected = NO;
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            NSLog(@"左横屏");
            self.playerView.fullScreenBtn.selected = YES;
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            NSLog(@"右横屏");
            self.playerView.fullScreenBtn.selected = YES;
            break;
            
        case UIInterfaceOrientationUnknown:
            return;
            break;
            
        default:
            break;
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self.playerView pause];
}

#pragma mark - CBAVPlayerViewDelegate
- (void)goBack
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)fullScreen:(UIButton *)btn
{
    UIInterfaceOrientation orientation = (UIInterfaceOrientation)[UIDevice currentDevice].orientation;
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        
        [self changeCurrentOprentation:UIInterfaceOrientationPortrait];
    } else {
        [self changeCurrentOprentation:UIInterfaceOrientationLandscapeRight];
    }
    
    CGFloat rotation;
    if (btn.selected) {
        rotation = 0;
        btn.selected = NO;
    } else {
        rotation = 0.5;
        btn.selected = YES;
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        self.view.frame = CB_SCREEN_BOUNDS;
        self.playerView.frame = self.view.bounds;
    }];
    
}

#pragma mark - 改变屏幕方向
- (void)changeCurrentOprentation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL seletor = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:seletor]];
        [invocation setSelector:seletor];
        [invocation setTarget:[UIDevice currentDevice]];
        [invocation setArgument:&interfaceOrientation atIndex:2];
        [invocation invoke];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
