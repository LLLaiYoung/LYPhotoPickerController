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
#import "LYPhotoHelper.h"

/** ---------------------Notification------------------------------- */
/** List发生变化通知 */
extern NSString *const kPhotoListChangeNotification;
/** AssetCollection 发生变化通知 */
extern NSString *const kAssetCollectionChangeNotification;

/** ---------------------NotificationKey----------------------------- */
/** 需要pop到listVC */
extern NSString *const kPopToListVCKey;
/** 新增的List对象(数组) */
extern NSString *const kAddListObjectsKey;
/** 被删除的list对象(数组) */
extern NSString *const kDeleteListObjectsKey;
/** 发生变化的AssetCollection的identifiers(数组) */
extern NSString *const KChangeAssetCollectionIdentifiersKey;
/** 已经选择了，被删除的对象的identifier（数组） */
extern NSString *const kSelectedDeleteObjectIdentifiersKey;
/** 当前选择collection被删除的对象的identifier（数组） */
extern NSString *const kCollectionDeleteObjectIdentifiersKey;
/** 当前选择collection新增的对象的identifier（数组） */
extern NSString *const kCollectionAddObjectIdentifiersKey;
/** 如果为YES，需要重新获取数据，并刷新collectionView，为NO只resetSendTitle（BOOL） */
extern NSString *const kNeedReloadDataKey;

/** ---------------------KVC_Key----------------------------- */
extern NSString *const KVC_CurrentSelectedAssecCollection;
extern NSString *const KVC_SelectCollectionResultDict;
extern NSString *const KVC_ItemWidth_Number;
extern NSString *const KVC_PhotoListIdentifiers;


typedef NS_ENUM(NSUInteger, LYPhotoListSelectMarkType) {
    LYPhotoListSelectMarkTypeNon = 1,
    LYPhotoListSelectMarkTypeRedDot,
    LYPhotoListSelectMarkTypeNumber
};

@class LYPhotoObject;
@interface LYPhotoPickerController : UINavigationController
/** 最多能选择多少张 */
@property (nonatomic, assign) NSUInteger maxCount;

/** 一行显示多少个，默认3个，最多4个, */
@property (nonatomic, assign) NSUInteger lineCount;

/** 缓存大小限制，默认不限制 */
@property (nonatomic, assign) NSUInteger cacheTotalCostLimit;

/** 间距，行列都一样，默认 5.0f，最大 10.0f，最小 2.0f */
@property (nonatomic, assign) CGFloat spacing;

@property (nonatomic, copy) void(^senderBlock)(NSArray <LYPhotoObject *>* objects);

/** list标注类型，如果 saveSelected 为 NO，那么此属性无效。默认 LYPhotoListSelectMarkTypeNumber  */
@property (nonatomic, assign) LYPhotoListSelectMarkType markType;

/** 相册集合类型，默认LYPhotoCollectionTypeAlbum|LYPhotoCollectionTypeSmartAlbum */
@property (nonatomic, assign) LYPhotoCollectionType collectionType;//待完成

/** 是否保存选择的，返回到listViewController的时候，默认YES */
@property (nonatomic, assign) BOOL saveSelected;

/** 是否支持多选，默认 YES */
@property (nonatomic, assign) BOOL supportMultiSelect;//待完成

/** 当选择“原图”的时候，是否加载原图，默认NO */
@property (nonatomic, assign) BOOL loadOriginalImage;//待完成

@end
