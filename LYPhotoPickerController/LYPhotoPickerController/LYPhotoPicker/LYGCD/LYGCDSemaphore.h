//
//  LYGCDSemaphore.h
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LYGCDSemaphore : NSObject

@property (nonatomic, strong, readonly)  dispatch_semaphore_t dispatchSemaphore;

- (instancetype)initWithValue:(long)value;

- (BOOL)signal;

- (void)wait;

- (BOOL)wait:(int64_t)delta;

@end
