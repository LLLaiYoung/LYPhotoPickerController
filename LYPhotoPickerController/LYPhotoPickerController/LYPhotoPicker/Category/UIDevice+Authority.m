//
//  UIDevice+Authority.m
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/4/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import "UIDevice+Authority.h"
#import <Photos/Photos.h>

@implementation UIDevice (Authority)

+ (BOOL)albumAuthority {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusRestricted || status == PHAuthorizationStatusDenied) {
        return NO;
    }
    return YES;
}

+ (BOOL)cameraAuthority {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusRestricted || status == AVAuthorizationStatusDenied) {
        return NO;
    }
    return YES;
}


@end
