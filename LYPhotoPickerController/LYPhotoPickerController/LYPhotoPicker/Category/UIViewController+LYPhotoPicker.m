//
//  UIViewController+LYPhotoPicker.m
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import "UIViewController+LYPhotoPicker.h"

@implementation UIViewController (LYPhotoPicker)

+ (LYPhotoPickerController *)photoPickerController {
    UIViewController* currentViewController = self.currentViewController;
    return (LYPhotoPickerController *)currentViewController.navigationController;
}

+ (UIViewController*)currentViewController {
    UIViewController* rootViewController = self.applicationDelegate.window.rootViewController;
    return [self currentViewControllerFrom:rootViewController];
}

// 通过递归拿到当前控制器
+ (UIViewController*)currentViewControllerFrom:(UIViewController*)viewController {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController *)viewController;
        return [self currentViewControllerFrom:navigationController.viewControllers.lastObject];
    } else if([viewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController *)viewController;
        return [self currentViewControllerFrom:tabBarController.selectedViewController];
    } else if(viewController.presentedViewController != nil) {
        return [self currentViewControllerFrom:viewController.presentedViewController];
    } else {
        return viewController;
    }
}

+ (id<UIApplicationDelegate>)applicationDelegate {
    return [UIApplication sharedApplication].delegate;
}


@end
