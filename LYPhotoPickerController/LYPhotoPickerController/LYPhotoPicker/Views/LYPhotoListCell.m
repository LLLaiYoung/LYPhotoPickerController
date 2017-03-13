//
//  LYPhotoListCell.m
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import "LYPhotoListCell.h"
#import "LYPhotoHelper.h"
#import "LYPhotoPickerCategory.h"

static CGFloat const kSpacing = 5.0f;
static CGFloat const kRedDotWidth = 10.0f;

@interface LYPhotoListCell()
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) CAShapeLayer *redDotLayer;
@end

@implementation LYPhotoListCell

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.contentView addSubview:self.imgView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.countLabel];
    [self.contentView.layer addSublayer:self.redDotLayer];
}

# pragma mark - Custom Accessors

- (UIImageView *)imgView
{
    if (!_imgView) {
        _imgView = [[UIImageView alloc] initWithFrame:CGRectMake(kSpacing, kSpacing, self.height - kSpacing * 2, self.height - kSpacing * 2)];
        _imgView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imgView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        CGFloat imgViewMaxX = CGRectGetMaxX(self.imgView.frame);
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(imgViewMaxX + kSpacing * 2, 0, 0, self.height)];
        _titleLabel.font = [UIFont systemFontOfSize:17.0f];
        _titleLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _titleLabel;
}

- (UILabel *)countLabel {
    if (!_countLabel) {
        CGFloat x = self.contentView.width - 50;
        _countLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, 20, self.height)];
        _countLabel.textColor = [UIColor redColor];
    }
    return _countLabel;
}

- (CAShapeLayer *)redDotLayer {
    if (!_redDotLayer) {
        _redDotLayer = [CAShapeLayer layer];
        CGFloat x = self.contentView.width - 20.0f;
        CGFloat y = (self.contentView.height - kRedDotWidth)/2.0f;
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, kRedDotWidth, kRedDotWidth) cornerRadius:kRedDotWidth/2.0f];
        _redDotLayer.path = bezierPath.CGPath;
        _redDotLayer.fillColor = [UIColor whiteColor].CGColor;
    }
    return _redDotLayer;
}

#pragma mark - Setter Methods

- (void)setListObject:(LYPhotoListObject *)listObject {
    _listObject = listObject;
    [self setTitleLabelStingWithLYPhotoListObject:listObject];
    CGFloat height = self.frame.size.height - kSpacing * 2;
    CGSize size = CGSizeMake(height, height);
    size.height *= [UIScreen mainScreen].scale;
    size.width *= [UIScreen mainScreen].scale;
    @weakify(self)
    [[LYPhotoHelper shareInstance] fetchImageInAsset:listObject.firstAsset makeSize:size makeResizeMode:PHImageRequestOptionsResizeModeExact callBackQueue:dispatch_get_main_queue() smallImage:YES completion:^(UIImage *assetImage, NSString *imageFileName) {
        if (assetImage) {
            @strongify(self)
            self.imgView.image = assetImage;
        }
    }];
}

- (void)setCount:(NSInteger)count {
    if (count != 0) {
        _count = count;
        self.countLabel.text = [NSString stringWithFormat:@"%li",(long)count];
    } else {
        self.countLabel.text = nil;
    }
}

- (void)setShowRedDot:(BOOL)showRedDot {
    _showRedDot = showRedDot;
    if (showRedDot) {
        self.redDotLayer.fillColor = [UIColor redColor].CGColor;
    } else {
        self.redDotLayer.fillColor = [UIColor whiteColor].CGColor;
    }
}

# pragma mark - IBActions

# pragma mark - Public

# pragma mark - Private

- (void)setTitleLabelStingWithLYPhotoListObject:(LYPhotoListObject *)listObject {
    NSMutableAttributedString *mutableAttrStr = [[NSMutableAttributedString alloc] initWithString:listObject.photoTitle attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17.0f],NSForegroundColorAttributeName:[UIColor blackColor]}];
    NSAttributedString *countAttrStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"（%lu）",(unsigned long)listObject.photoCount] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17.0f],NSForegroundColorAttributeName:[UIColor grayColor]}];
    [mutableAttrStr insertAttributedString:countAttrStr atIndex:listObject.photoTitle.length];
    self.titleLabel.attributedText = mutableAttrStr;
    [self.titleLabel sizeToFit];
    CGRect frame = self.titleLabel.frame;
    frame.origin.y = (self.height - self.titleLabel.height)/2.0f;
    frame.size = self.titleLabel.size;
    self.titleLabel.frame = frame;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.titleLabel.text = nil;
    self.imgView.image = nil;
}
# pragma mark - Protocol conformance

# pragma mark - UITextFieldDelegate

# pragma mark - UITableViewDataSource

# pragma mark - UITableViewDelegate

# pragma mark - NSCopying

# pragma mark - NSObject

@end
