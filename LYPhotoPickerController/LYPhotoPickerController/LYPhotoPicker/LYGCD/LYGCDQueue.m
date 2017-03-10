//
//  LYGCDQueue.m
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import "LYGCDQueue.h"

static LYGCDQueue *mainQueue;
static LYGCDQueue *globalQueue;
static LYGCDQueue *highPriorityGlobalQueue;

@interface LYGCDQueue()
@property (nonatomic, strong)  dispatch_queue_t dispatchQueue;
@end

@implementation LYGCDQueue


+ (void)initialize
{
    if (self == [LYGCDQueue class]) {
        mainQueue = [LYGCDQueue new];
        mainQueue.dispatchQueue = \
        dispatch_get_main_queue();
        
        globalQueue = [LYGCDQueue new];
        globalQueue.dispatchQueue = \
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        highPriorityGlobalQueue = [LYGCDQueue new];
        highPriorityGlobalQueue.dispatchQueue = \
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    }
}

+ (LYGCDQueue *)mainQueue {
    return mainQueue;
}

+ (LYGCDQueue *)globalQueue {
    return globalQueue;
}

+ (LYGCDQueue *)highPriorityGlobalQueue {
    return highPriorityGlobalQueue;
}

+ (void)executeInMainQueue:(dispatch_block_t)block {
    [[LYGCDQueue mainQueue] execute:^{
        block();
    }];
}

+ (void)executeInGlobalQueue:(dispatch_block_t)block {
    [[LYGCDQueue globalQueue] execute:^{
        block();
    }];
}

- (void)execute:(dispatch_block_t)block {
    dispatch_async(self.dispatchQueue, block);
}


+ (void)executeInHighPriorityGlobalQueue:(dispatch_block_t)block {
    [[LYGCDQueue highPriorityGlobalQueue] execute:^{
        block();
    }];
}



@end
