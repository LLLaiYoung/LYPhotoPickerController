//
//  UIViewController+LYPhotoPicker.h
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LYPhotoPickerController.h"

@interface UIViewController (LYPhotoPicker)

+ (UIViewController *)currentViewController;

+ (UINavigationController*)currentNavigationViewController;

+ (LYPhotoPickerController *)photoPickerController;

@end
