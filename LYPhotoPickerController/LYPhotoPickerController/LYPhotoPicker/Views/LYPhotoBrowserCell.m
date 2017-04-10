//
//  LYPhotoBrowserCell.m
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import "LYPhotoBrowserCell.h"
#import "LYPhotoHelper.h"

@interface LYPhotoBrowserCell()

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation LYPhotoBrowserCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.scrollView = [[LYPhotoBrowserScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [self.contentView addSubview:self.scrollView];
    }
    return self;
}

- (void)initActivityIndicatorView {
    CGFloat x = (SCREEN_WIDTH - 100)/2.0f;
    CGFloat y = (SCREEN_HEIGHT - 100)/2.0f;
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(x, y, 100, 100)];
    self.activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [self.contentView addSubview:self.activityIndicatorView];
    [self.activityIndicatorView startAnimating];
}


#pragma mark - Setter Methods

- (void)setAssetObject:(LYPhotoAssetObject *)assetObject {
    _assetObject = assetObject;
    BOOL iCloud = [[LYPhotoHelper shareInstance] judgeAssetisInICloud:assetObject.asset];
    if (iCloud) {
        [self initActivityIndicatorView];
    }
    [self loadImageWithLYPhotoAssetObject:assetObject onICloud:iCloud];
}

# pragma mark - Private

- (void)loadImageWithLYPhotoAssetObject:(LYPhotoAssetObject *)assetObject onICloud:(BOOL)iCloud{
    if (self.showOriginalImage) {
        [self loadOrigLYPhotoAssetObject:assetObject onICloud:iCloud handle:nil];
    } else {
        [self loadNonOrigLYPhotoAssetObject:assetObject];
    }
}

/** 加载原图 LYPhotoAssetObject  */
- (void)loadOrigLYPhotoAssetObject:(LYPhotoAssetObject *)assetObject onICloud:(BOOL)iCloud handle:(void (^)(BOOL success))handle {
    @weakify(self)
    if (!iCloud) {
        [[LYPhotoHelper shareInstance] fetchImageDataInAsset:assetObject.asset makeResizeMode:PHImageRequestOptionsResizeModeExact callBackQueue:dispatch_get_main_queue() completion:^(NSData *assetImageData,NSString *imageFileName) {
            @strongify(self)
            if ([self.identifier isEqualToString:imageFileName]) {
                UIImage *image = [UIImage imageWithData:assetImageData];
                if (!isNull(image)) {
                    [self setImageWithImage:image];
                    if (handle) {
                        handle(YES);
                    }
                }
            }
        }];
    } else {
        [[LYPhotoHelper shareInstance] fetchImageInAsset:assetObject.asset makeSize:PHImageManagerMaximumSize makeResizeMode:PHImageRequestOptionsResizeModeExact callBackQueue:dispatch_get_main_queue() smallImage:NO completion:^(UIImage *assetImage, NSString *imageFileName) {
            @strongify(self)
            if ([self.identifier isEqualToString:imageFileName]) {
                if (!isNull(assetImage)) {
                    [self setImageWithImage:assetImage];
                    if (handle) {
                        handle(YES);
                    }
                }
            }
        }];
    }
}

/** 加载非原图 LYPhotoAssetObject  */
- (void)loadNonOrigLYPhotoAssetObject:(LYPhotoAssetObject *)assetObject {
    @weakify(self)
    CGSize size = [[LYPhotoHelper shareInstance] calculateSizeWithAsset:assetObject.asset];
    [[LYPhotoHelper shareInstance] fetchImageInAsset:assetObject.asset makeSize:size makeResizeMode:PHImageRequestOptionsResizeModeFast callBackQueue:dispatch_get_main_queue() smallImage:NO completion:^(UIImage *assetImage,NSString *imageFileName) {
        @strongify(self)
        if ([self.identifier isEqualToString:imageFileName]) {
            if (!isNull(assetImage)) {
                [self setImageWithImage:assetImage];
            }
        }
    }];
}

- (void)setImageWithImage:(UIImage *)image {
    if (self.activityIndicatorView) {
        [self.activityIndicatorView removeFromSuperview];
    }
    if (image) {
        [self.scrollView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO modes:@[NSRunLoopCommonModes]];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.scrollView.imageView.image = nil;
    [self.activityIndicatorView removeFromSuperview];
}

@end

