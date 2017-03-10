//
//  LYPhotoBrowserScrollView.m
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import "LYPhotoBrowserScrollView.h"
#import "LYPhotoPickerCategory.h"
#import "LYPhotoMacro.h"

NSString *const longPressGRNotification = @"longPressGRNotification";

#pragma mark - LYPhotoBrowserImageView

@interface LYPhotoBrowserImageView ()
/** 双击，放大 */
@property (nonatomic, strong) UITapGestureRecognizer *scaleBigTapGR;

@end

@implementation LYPhotoBrowserImageView

#pragma mark -- Lifecycle --

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.userInteractionEnabled = YES;
        self.scaleBigTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scaleBigTap:)];
        self.scaleBigTapGR.numberOfTapsRequired = 2;
        self.scaleBigTapGR.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:self.scaleBigTapGR];
    }
    return self;
}

# pragma mark -- IBActions --

- (void)scaleBigTap:(UITapGestureRecognizer *)tapGR {
    if (self.imageViewDelegate && [self.imageViewDelegate respondsToSelector:@selector(photoBrowserImageView:doubleTapDetected:)]) {
        [self.imageViewDelegate photoBrowserImageView:self doubleTapDetected:tapGR];
    }
}

@end

#pragma mark - LYPhotoBrowserScrollView

@implementation LYPhotoBrowserScrollView

#pragma mark -- Lifecycle --

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        self.delegate = (id)self;
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        UILongPressGestureRecognizer *longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGR:)];
        [self addGestureRecognizer:longPressGR];
        
        //* 单击，消失 */
        UITapGestureRecognizer *dismissTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTap:)];
        dismissTapGR.numberOfTapsRequired = 1;
        dismissTapGR.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:dismissTapGR];
        
        self.imageView = [[LYPhotoBrowserImageView alloc] initWithFrame:frame];
        self.imageView.imageViewDelegate = (id)self;
        [self addSubview:self.imageView];
        
        //* 只能有一个手势存在 */
        [dismissTapGR requireGestureRecognizerToFail:self.imageView.scaleBigTapGR];
    }
    return self;
}

# pragma mark -- IBActions --

- (void)longPressGR:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan) {
        [[NSNotificationCenter defaultCenter] postNotificationName:longPressGRNotification object:longPress];
    }
}

- (void)dismissTap:(UITapGestureRecognizer *)tapGR {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissNotification" object:tapGR];
}

#pragma mark -- public --

- (void)reductionZoomScale {
    self.minimumZoomScale = 1;
    [self setZoomScale:self.minimumZoomScale animated:YES];
}


#pragma mark -- Layout --
//* 总是让图片居中显示 */
- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.imageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else {
        frameToCenter.origin.x = 0;
    }
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else {
        frameToCenter.origin.y = 0;
    }
    
    // Center
    if (!CGRectEqualToRect(self.imageView.frame, frameToCenter))
        self.imageView.frame = frameToCenter;
    
}

# pragma mark -- Private --

- (CGFloat)initialZoomScaleWithMinScale {
    CGFloat zoomScale = self.minimumZoomScale;
    if (self.imageView) {
        CGSize boundsSize = self.bounds.size;
        CGSize imageSize = self.imageView.image.size;
        CGFloat boundsAR = boundsSize.width / boundsSize.height;
        CGFloat imageAR = imageSize.width / imageSize.height;
        CGFloat xScale = boundsSize.width / imageSize.width;
        
        if (ABS(boundsAR - imageAR) < 0.17) {
            zoomScale = xScale;
        }
    }
    return zoomScale;
}

- (void)displayImage {
    UIImage *image = self.imageView.image;
    if (image) {
        //        CGSize boundSize = [UIScreen mainScreen].bounds.size;
        //        // * 宽高都未超过 */
        //        if (image.size.width < boundSize.width && image.size.height < boundSize.height) {
        //            if (image.size.height <= imageMinWidth_Height && image.size.width <= imageMinWidth_Height) {
        //                self.imageView.size = CGSizeMake(imageMinWidth_Height, imageMinWidth_Height);
        //            } else {
        //                self.imageView.size = image.size;
        //            }
        //        } else {//宽高都超过，或者宽或者高超过
        self.imageView.frame = [UIImageView setMaxMinZoomScalesForCurrentBoundWithImage:image];
        self.contentSize = self.imageView.frame.size;
        //        }
    }
    
    CGFloat zoomScale = 0;
    if (self.imageView.width < SCREEN_WIDTH) {
        zoomScale = SCREEN_WIDTH/self.imageView.width;
    }
    if (self.imageView.height < SCREEN_WIDTH) {
        zoomScale = SCREEN_HEIGHT/self.imageView.height;
    }
    
    self.minimumZoomScale = 1;
    self.maximumZoomScale = zoomScale < 2 ? 3 : zoomScale;
    [self layoutIfNeeded];
}

#pragma mark -- PhotoBrowserImageViewDelegate --
- (void)photoBrowserImageView:(LYPhotoBrowserImageView *)imageView doubleTapDetected:(UITapGestureRecognizer *)tapGR {
    CGPoint touchPoint = [tapGR locationInView:imageView];
    //* 还原，已经放大 */
    if (self.zoomScale != self.minimumZoomScale && self.zoomScale != [self initialZoomScaleWithMinScale]) {
        [self setZoomScale:self.minimumZoomScale animated:YES];
    } else {//* 放大 */
        CGFloat newZoomScale = ((self.maximumZoomScale + self.minimumZoomScale) / 1.5);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
    }
}

#pragma mark -- UIScrollViewDelegate --

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self layoutIfNeeded];
}


#pragma mark -- Setter Methods --
- (void)setImage:(UIImage *)image {
    _image = image;
    //reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    self.imageView.image = image;
    [self displayImage];
}

@end


#pragma mark - LYPhotoPickerAdd

@implementation UIImageView (LYPhotoPickerAdd)

+ (CGRect)setMaxMinZoomScalesForCurrentBoundWithImage:(UIImage *)image {
    if (!([image isKindOfClass:[UIImage class]]) || image == nil) {
        if (!([image isKindOfClass:[UIImage class]])) {
            return CGRectZero;
        }
    }
    
    CGSize boundsSize = [UIScreen mainScreen].bounds.size;
    CGSize imageSize = image.size;
    if (imageSize.width == 0 || imageSize.height == 0) {
        return CGRectZero;
    }
    
    CGFloat imageScale = image.size.height/image.size.width;
    
    CGRect frameToCenter = CGRectZero;
    CGFloat screenScale = SCREEN_HEIGHT/SCREEN_WIDTH;
    CGFloat height,width;
    if (imageScale > screenScale) {
        height = SCREEN_HEIGHT;
        width = SCREEN_HEIGHT/imageScale;
    } else {
        width = SCREEN_WIDTH;
        height = SCREEN_WIDTH * imageScale;
    }
    
    frameToCenter = CGRectMake(0, 0, width, height);
    
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else {
        frameToCenter.origin.x = 0;
    }
    
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else {
        frameToCenter.origin.y = 0;
    }
    
    return frameToCenter;
}

@end
