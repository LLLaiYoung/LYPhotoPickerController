//
//  LYPhotoSmallCell.m
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import "LYPhotoSmallCell.h"
#import "LYPhotoPickerCategory.h"
#import "LYPhotoHelper.h"

@implementation LYPhotoSmallSelectedBtn

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    CGSize size = CGSizeMake(20, 20);
    CGFloat widht = contentRect.size.width;
    return CGRectMake((widht - size.width)/2, (widht - size.height)/2, size.width, size.height);
}

@end

@interface LYPhotoSmallCell()
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UILabel *indexLabel;
@end

@implementation LYPhotoSmallCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        [self.contentView addSubview:self.imgView];
        [self.contentView addSubview:self.selectBtn];
        [self.contentView addSubview:self.indexLabel];
    }
    return self;
}

# pragma mark - Custom Accessors
- (UIImageView *)imgView
{
    if (!_imgView) {
        _imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height)];
        _imgView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _imgView;
}

- (LYPhotoSmallSelectedBtn *)selectBtn {
    if (!_selectBtn) {
        _selectBtn = [[LYPhotoSmallSelectedBtn alloc] initWithFrame:CGRectMake(self.width - 30, 3, 25, 25)];
        [_selectBtn setImage:[UIImage imageNamed:@"ic_non_select"] forState:UIControlStateNormal];
        [_selectBtn setImage:[UIImage imageNamed:@"ic_selected"] forState:UIControlStateSelected];
        [_selectBtn addTarget:self action:@selector(clickedSelectBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _selectBtn;
}

- (UILabel *)indexLabel {
    if (!_indexLabel) {
        _indexLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, self.width-20, self.height)];
        _indexLabel.textColor  = [UIColor redColor];
        _indexLabel.font = [UIFont systemFontOfSize:40.0f];
    }
    return _indexLabel;
}

#pragma mark - Setter Methods

- (void)setAsset:(PHAsset *)asset {
    _asset = asset;
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGFloat width = self.width * scale;
    CGFloat height = self.height * scale;
    @weakify(self)
    [[LYPhotoHelper shareInstance] fetchImageInAsset:asset makeSize:CGSizeMake(width, height) makeResizeMode:PHImageRequestOptionsResizeModeExact callBackQueue:dispatch_get_main_queue() smallImage:YES completion:^(UIImage *assetImage, NSString *imageFileName) {
        @strongify(self)
        if (assetImage && [self.identifier isEqualToString:imageFileName]) {
            self.imgView.image = assetImage;
        }
    }];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    if (selectedIndex != -1) {
        _selectedIndex = selectedIndex;
        self.indexLabel.text = [NSString stringWithFormat:@"%li",(long)selectedIndex];
    } else {
        self.indexLabel.text = nil;
    }
}

# pragma mark - IBActions

- (void)clickedSelectBtn:(LYPhotoSmallSelectedBtn *)sender {
    if ([self.delegate respondsToSelector:@selector(didClickedSelectButton:indexPath:)]) {
        [self.delegate didClickedSelectButton:sender indexPath:self.indexPath];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.selectBtn.selected = NO;
    self.indexLabel.text = nil;
}
# pragma mark - Public

# pragma mark - Private

# pragma mark - Protocol conformance

# pragma mark - UITextFieldDelegate

# pragma mark - UITableViewDataSource

# pragma mark - UITableViewDelegate

# pragma mark - NSCopying

# pragma mark - NSObject

@end
