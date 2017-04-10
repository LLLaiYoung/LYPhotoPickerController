//
//  UIDevice+Authority.h
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/4/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (Authority)
/** 相册权限 */
+ (BOOL)albumAuthority;

/** 相机权限 */
+ (BOOL)cameraAuthority;

@end
