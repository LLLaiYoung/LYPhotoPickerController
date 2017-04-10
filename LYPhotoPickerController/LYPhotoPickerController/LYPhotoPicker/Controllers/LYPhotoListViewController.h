//
//  LYPhotoListViewController.h
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LYPhotoObject;
@interface LYPhotoListViewController : UIViewController
/** 已经选择的照片的title及对应的选中张数 */
@property (nonatomic, copy) NSDictionary <NSString *, NSNumber *> *selectedAlbumTitlesAndNumberDict;
@property (nonatomic, copy) NSSet <NSString *> *containsPhotoListNames;

@end
