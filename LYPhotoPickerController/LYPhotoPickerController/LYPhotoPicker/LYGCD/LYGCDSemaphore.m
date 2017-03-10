//
//  LYGCDSemaphore.m
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import "LYGCDSemaphore.h"

@interface LYGCDSemaphore()

@property (nonatomic, strong)  dispatch_semaphore_t dispatchSemaphore;

@end

@implementation LYGCDSemaphore

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.dispatchSemaphore = dispatch_semaphore_create(0);
    }
    return self;
}

- (instancetype)initWithValue:(long)value {
    self = [super init];
    if (self) {
        self.dispatchSemaphore = dispatch_semaphore_create(value);
    }
    return self;
}

- (BOOL)signal {
    return dispatch_semaphore_signal(self.dispatchSemaphore) != 0;
}

- (void)wait {
    dispatch_semaphore_wait(self.dispatchSemaphore, DISPATCH_TIME_FOREVER);
}

- (BOOL)wait:(int64_t)delta {
    return dispatch_semaphore_wait(self.dispatchSemaphore, dispatch_time(DISPATCH_TIME_NOW, delta)) == 0;
}

@end
