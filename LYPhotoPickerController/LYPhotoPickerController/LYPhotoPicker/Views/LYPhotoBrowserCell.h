//
//  LYPhotoBrowserCell.h
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LYPhotoBrowserScrollView.h"
@class LYPhotoAssetObject;
@interface LYPhotoBrowserCell : UICollectionViewCell
@property (nonatomic, strong) LYPhotoBrowserScrollView *scrollView;
@property (nonatomic, strong) LYPhotoAssetObject *assetObject;
@property (nonatomic, copy) NSString *identifier;
/** 是否显示原图 */
@property (nonatomic, assign) BOOL showOriginalImage;

/**
 加载原图
 
 @param iCloud 是否存储在iCloud
 @param handle 用于点击原图按钮，加载了原图，更改按钮的状态
 */
- (void)loadOrigLYPhotoAssetObject:(LYPhotoAssetObject *)assetObject onICloud:(BOOL)iCloud handle:(void (^)(BOOL success))handle;

@end

