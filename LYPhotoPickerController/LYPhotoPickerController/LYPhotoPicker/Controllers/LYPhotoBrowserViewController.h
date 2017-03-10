//
//  LYPhotoBrowserViewController.h
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LYPhotoBrowserViewController : UIViewController
/** 数据源 */
@property (nonatomic, strong) NSMutableArray *dataSource;
/** 该图在dataSource对应的index */
@property (nonatomic, assign) NSUInteger index;
/** 外界不用关心这个这个属性，这个只是在本地相册进行多选的时候使用 */
@property (nonatomic, copy) NSString *albumTitle;
/** 是不是预览模式，如果是预览模式，取消标注则要删除对应的LYPhotoAssetObject对象 */
@property (nonatomic, assign, getter=isPreviewModel) BOOL previewModel;
@end
