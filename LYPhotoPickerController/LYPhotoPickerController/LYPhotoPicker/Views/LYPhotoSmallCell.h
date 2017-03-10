//
//  LYPhotoSmallCell.h
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PHAsset,LYPhotoSmallCell;

@interface LYPhotoSmallSelectedBtn : UIButton

@end

@protocol LYPhotoSmallCellDelegate <NSObject>

- (void)didClickedSelectButton:(LYPhotoSmallSelectedBtn *)sender indexPath:(NSIndexPath *)indexPath;

@end

@interface LYPhotoSmallCell : UICollectionViewCell

@property (nonatomic, weak) id<LYPhotoSmallCellDelegate> delegate;

@property (nonatomic, strong) PHAsset *asset;

@property (nonatomic, copy) NSString *identifier;

@property (nonatomic, strong) LYPhotoSmallSelectedBtn *selectBtn;

@property (nonatomic, strong) NSIndexPath *indexPath;
/** 选择的index，-1（没有选择） */
@property (nonatomic, assign) NSInteger selectedIndex;

@end
