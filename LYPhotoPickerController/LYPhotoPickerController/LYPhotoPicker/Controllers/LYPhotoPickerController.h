//
//  LYPhotoPickerController.h
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "LYPhotoMacro.h"
#import "LYGCD.h"

extern NSString *const kAssetCollectionChangeNotification;
extern NSString *const kPhotoListChangeNotification;
extern NSString *const kAfter;
extern NSString *const kKey;
extern NSString *const kDeleteIdentifier;

extern NSString *const KVC_CurrentSelectedAssecCollection;
extern NSString *const KVC_SelectCollectionResultDict;
extern NSString *const KVC_ItemWidth_Number;


typedef NS_ENUM(NSUInteger, LYPhotoListSelectMarkType) {
    LYPhotoListSelectMarkTypeNumber = 1,
    LYPhotoListSelectMarkTypeRedDot,
    LYPhotoListSelectMarkTypeNon,
};

@class LYPhotoObject;
@interface LYPhotoPickerController : UINavigationController
/** 最多能选择多少张 */
@property (nonatomic, assign) NSUInteger maxCount;

/** 一行显示多少个，默认3个，最多4个, */
@property (nonatomic, assign) NSUInteger lineCount;

/** 缓存个数，默认 50 个,0 不限制 */
@property (nonatomic, assign) NSUInteger cacheCount;

/** 间距，行列都一样，默认 5.0f，最大 10.0f，最小 2.0f */
@property (nonatomic, assign) CGFloat spacing;

@property (nonatomic, copy) void(^senderBlock)(NSArray <LYPhotoObject *>* objects);
/** list标注类型，如果 saveSelected 为 NO，那么此属性无效。默认 LYPhotoListSelectMarkTypeNumber  */
@property (nonatomic, assign) LYPhotoListSelectMarkType markType;
/** 是否保存选择的，返回到listViewController的时候，默认YES */
@property (nonatomic, assign) BOOL saveSelected;

@end
