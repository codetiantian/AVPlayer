//
//  ViewController.m
//  MyAVPlayer
//
//  Created by 这个夏天有点冷 on 2017/4/18.
//  Copyright © 2017年 YLT. All rights reserved.
//

#import "ViewController.h"
#import "CBAVPlayerViewController.h"

@interface ViewController ()

- (IBAction)playButtonClicked:(UIButton *)sender;

@property (copy, nonatomic) NSString *strUrl;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"rzjt" ofType:@"MP4"];
    self.strUrl = filePath;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)playButtonClicked:(UIButton *)sender {
    CBAVPlayerViewController *videoPlayerVC = [[CBAVPlayerViewController alloc] initWithVideoUrl:self.strUrl];
    [self presentViewController:videoPlayerVC animated:YES completion:nil];
    
}

@end
