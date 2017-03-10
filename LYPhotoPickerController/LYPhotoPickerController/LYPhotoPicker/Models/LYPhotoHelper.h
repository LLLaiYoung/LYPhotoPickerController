//
//  LYPhotoHelper.h
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "LYPhotoMacro.h"

#pragma mark - LYPhotoObject

@interface LYPhotoObject : NSObject
<
NSCopying
>
/** 图片文件名 */
@property (nonatomic, copy) NSString *imageFileName;
/** 图片字节 */
@property (nonatomic, assign) NSUInteger imageByte;
/** 原图分辨率 */
@property (nonatomic, assign) CGSize originalImageSize;
/** 缩略图分辨率 */
@property (nonatomic, assign) CGSize thumbnailImageSize;
/** 原图 */
@property (nonatomic, strong) NSData *originalImageData;
/** 缩略图 */
@property (nonatomic, strong) NSData *thumbnailImageData;
/** 原图 */
@property (nonatomic, assign) BOOL originalImage;
@end

#pragma mark - LYPhotoAssetObject

@interface LYPhotoAssetObject : NSObject
/** 图片名称 */
@property (nonatomic, copy) NSString *imageFileName;

@property (nonatomic, copy, readonly) NSString *burstIdentifier;
/** 选择的index */
@property (nonatomic, assign) NSUInteger selectedIndex;
/** 下一个节点 */
@property (nonatomic, assign) NSUInteger nextIndex;
/** 选择的indexPath */
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@property (nonatomic, strong) PHAsset *asset;
/** 相册标题，用于判断是否同一个相册（排序） */
@property (nonatomic, copy) NSString *albumTitle;

@end

#pragma mark - LYPhotoListObject

@interface LYPhotoListObject : NSObject
/** 相册标题 */
@property (nonatomic, copy) NSString *photoTitle;
/** list唯一标识符 */
@property (nonatomic, copy) NSString *listIdentifier;
/** 该相册的照片总数 */
@property (nonatomic, assign) NSUInteger photoCount;
/** 该相册第一张图 */
@property (nonatomic, strong) PHAsset *firstAsset;
/** 通过该属性可以取得该相册的所有照片 */
@property (nonatomic, strong) PHAssetCollection *assetCollection;

@end

typedef NS_OPTIONS(NSUInteger, LYPhotoCollectionType) {
    LYPhotoCollectionTypeAlbum = 1 << 0,
    LYPhotoCollectionTypeSmartAlbum = 1 << 1,
    LYPhotoCollectionTypeMoment = 1 << 2,
    LYPhotoCollectionTypeAny = LYPhotoCollectionTypeAlbum | LYPhotoCollectionTypeSmartAlbum | LYPhotoCollectionTypeMoment
};

#pragma mark - LYPhotoHelper

@interface LYPhotoHelper : NSObject

+ (instancetype)shareInstance;

/** 获取所有相册列表,默认 UserAlbum SmartAlbum */
- (NSArray <LYPhotoListObject *> *)fetchAllPhotoList;

/** 获取所有相册列表 */
- (NSArray <LYPhotoListObject *> *)fetchAllPhotoListWithCollectionType:(LYPhotoCollectionType)collectionType;

/**
 根据 PHAsset 获取对应的 image
 
 @param size 要生成图片大小(要乘屏幕比例)／原图 PHImageManagerMaximumSize
 @param resizeMode 控制照片尺寸
 @param queue 回调线程
 @param small YES小图，NO大图，用于缓存
 @param completion 返回对应尺寸的image和文件名
 */
-(void)fetchImageInAsset:(PHAsset *)asset
                makeSize:(CGSize)size
          makeResizeMode:(PHImageRequestOptionsResizeMode)resizeMode
           callBackQueue:(dispatch_queue_t)queue
              smallImage:(BOOL)small
              completion:(void (^)(UIImage *assetImage,NSString *imageFileName))completion;


/**
 根据 PHAsset 获取对应的 imageData，原图
 
 @param resizeMode 控制照片尺寸
 @param queue 回调线程
 @param completion 返回对应的imageData和文件名
 */
-(void)fetchImageDataInAsset:(PHAsset *)asset
              makeResizeMode:(PHImageRequestOptionsResizeMode)resizeMode
               callBackQueue:(dispatch_queue_t)queue
                  completion:(void (^)(NSData *assetImageData,NSString *imageFileName))completion;

/** 获取指定相册的所有照片 */
- (NSArray <LYPhotoAssetObject *>*)fetchLYPhotoAssetObjectInAssetCollection:(PHAssetCollection *)assetCollection ascending:(BOOL)ascending;

/** 根据 PHFetchResult 获取 照片*/
- (NSArray <LYPhotoAssetObject *>*)fetchLYPhotoAssetObjectWithFetchResult:(PHFetchResult *)result;

/** 根据 assetCollection 获取这个相册里面所有文件的文件名 */
- (NSArray <NSString *> *)fetchAllCollectionFilenameWithCollection:(PHAssetCollection *)assetCollection;

/** 获取所有的list的唯一标识符 */
- (NSArray <NSString *> *)fetchAllListObjectIdentifier;

/** 根据 AssetCollection 获取 Assets */
- (PHFetchResult *)fetchResultAssetsInAssetCollection:(PHAssetCollection *)assetCollection ascending:(BOOL)ascending;

/** 获取所有相册列表里面的所有图片名称，用于相册内容发生改变（删除） */
- (NSSet *)fetchAllImageNamesInPhotoList;

/** 将 LYPhotoAssetObject 转换成 LYPhotoObjects , 支持原图才有 0 原图，1 非原图，不支持原图就只有非原图 */
- (NSArray <LYPhotoObject *> *)transformLYAssetPhoto:(LYPhotoAssetObject *)lyAssetObject;

/** 根据照片获取字节大小 */
- (void)fetchImageBytesInAssets:(NSArray <PHAsset *>*)assets bytes:(void(^)(NSString *bytes))handler;

/** 转换图片大小 */
- (NSString *)transformSizeStringWithDataLength:(NSInteger)length;

/** 相册权限 */
-(BOOL)albumAuthority;

/** 相机权限 */
-(BOOL)cameraAuthority;

/** 判断Asset是存储在iCloud */
- (BOOL)judgeAssetisInICloud:(PHAsset *)asset;

/** 清空缓存 */
- (void)didReceiveMemoryWarning;

/** 根据 asset 计算图片的比例 */
- (CGSize)calculateSizeWithAsset:(PHAsset *)asset;

@end
