//
//  LYPhotoBrowserScrollView.h
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const longPressGRNotification;

@class LYPhotoBrowserImageView;
@protocol LYPhotoBrowserImageViewDelegate <NSObject>
- (void)photoBrowserImageView:(LYPhotoBrowserImageView *)imageView doubleTapDetected:(UITapGestureRecognizer *)tapGR;
@optional

@end

#pragma mark - LYPhotoBrowserImageView

@interface LYPhotoBrowserImageView : UIImageView
@property (nonatomic, weak) id<LYPhotoBrowserImageViewDelegate> imageViewDelegate;
@end

#pragma mark - LYPhotoBrowserScrollView

@interface LYPhotoBrowserScrollView : UIScrollView
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) LYPhotoBrowserImageView *imageView;
/** 还原scale */
- (void)reductionZoomScale;
@end

#pragma mark - LYPhotoPickerAdd

@interface UIImageView  (LYPhotoPickerAdd)

+ (CGRect)setMaxMinZoomScalesForCurrentBoundWithImage:(UIImage *)image;

@end
