//
//  UIImage+CBAVPlayer.m
//  MyAVPlayer
//
//  Created by 这个夏天有点冷 on 2017/4/18.
//  Copyright © 2017年 YLT. All rights reserved.
//

#import "UIImage+CBAVPlayer.h"

@implementation UIImage (CBAVPlayer)

+ (UIImage *)getRoundImageWithColor:(UIColor*)color size:(CGSize)size
{
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillEllipseInRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
