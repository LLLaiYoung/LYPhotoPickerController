//
//  LYGCDQueue.h
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LYGCDQueue : NSObject

@property (nonatomic, strong, readonly)  dispatch_queue_t dispatchQueue;

+ (LYGCDQueue *)mainQueue;
+ (LYGCDQueue *)globalQueue;

+ (void)executeInMainQueue:(dispatch_block_t)block;
+ (void)executeInGlobalQueue:(dispatch_block_t)block;
+ (void)executeInHighPriorityGlobalQueue:(dispatch_block_t)block;


@end
