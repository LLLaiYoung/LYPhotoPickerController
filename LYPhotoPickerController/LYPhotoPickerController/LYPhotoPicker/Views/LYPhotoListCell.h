//
//  LYPhotoListCell.h
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LYPhotoListObject;
@interface LYPhotoListCell : UITableViewCell
@property (nonatomic, strong) LYPhotoListObject *listObject;
/** 0不显示 */
@property (nonatomic, assign) NSInteger count;
@end
