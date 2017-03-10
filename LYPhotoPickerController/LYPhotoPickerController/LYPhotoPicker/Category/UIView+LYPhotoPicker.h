//
//  UIView+LYPhotoPicker.h
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (LYPhotoPicker)
@property (nonatomic) CGFloat left;
@property (nonatomic) CGFloat top;
@property (nonatomic) CGFloat right;
@property (nonatomic) CGFloat bottom;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat centerX;
@property (nonatomic) CGFloat centerY;
@property (nonatomic) CGPoint origin;
@property (nonatomic) CGSize  size;
@property (nonatomic, readonly) CGPoint middlePoint;
@property (nonatomic, readonly) CGFloat middleX;
@property (nonatomic, readonly) CGFloat middleY;
@end

@interface UIImage (LYPhotoPicker)

- (UIImage *)fixOrientation;

- (UIImage *)thumbnailImage;

@end
