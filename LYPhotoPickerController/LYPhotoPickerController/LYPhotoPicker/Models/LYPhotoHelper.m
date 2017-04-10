//
//  LYPhotoHelper.m
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import "LYPhotoHelper.h"
#import "LYPhotoPickerCategory.h"
#import "LYGCD.h"

/** 图片质量 */
static CGFloat const photoCompressionQuality = 0.8;

#pragma mark - LYPhotoObject

@implementation LYPhotoObject

- (id)copyWithZone:(NSZone *)zone {
    LYPhotoObject *object = [[LYPhotoObject alloc] init];
    object.imageFileName = [_imageFileName copy];
    object.imageByte = _imageByte;
    object.originalImageSize = _originalImageSize;
    object.thumbnailImageSize = _thumbnailImageSize;
    object.originalImageData = _originalImageData;
    object.thumbnailImageData = _thumbnailImageData;
    object.originalImage = _originalImage;
    return object;
}

@end

#pragma mark - LYPhotoAssetObject

@interface LYPhotoAssetObject()

@property (nonatomic, copy) NSString *burstIdentifier;

@end

@implementation LYPhotoAssetObject

@end

#pragma mark - LYPhotoListObject

@implementation LYPhotoListObject


@end

#pragma mark - LYPhotoHelper

@interface LYPhotoHelper()
/** 原图缓存 */
@property (nonatomic, strong) NSCache *originalImageCache;
/** 非原图缓存 */
@property (nonatomic, strong) NSCache *imageCache;
/** 原图下载队列 */
@property (nonatomic, strong) NSMutableArray *downloadOrigList;
/** 非原图下载队列 */
@property (nonatomic, strong) NSMutableArray *downloadList;

@property (nonatomic, strong) NSArray *serialQueues;
/** 中间桥接 */
@property (nonatomic, copy) NSString *assetCollectionIdentifier;

@property (nonatomic, strong) NSArray *lyPhotoListCache;

@end

@implementation LYPhotoHelper

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self registerNotification];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public

+ (instancetype)shareInstance {
    static LYPhotoHelper *helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[self alloc] init];
    });
    return helper;
}

- (NSArray <LYPhotoListObject *> *)fetchAllPhotoListWithCollectionType:(LYPhotoCollectionType)collectionType {
    if (self.lyPhotoListCache.count != 0) {
        return self.lyPhotoListCache;
    } else {
        return [self fetchAllPhotoListNonGotoCacheWithCollectionType:collectionType];
    }
}

/** 不走缓存 */
- (NSArray <LYPhotoListObject *> *)fetchAllPhotoListNonGotoCacheWithCollectionType:(LYPhotoCollectionType)collectionType {
    __block NSMutableArray<LYPhotoListObject *> *photoList = @[].mutableCopy;
    LYGCDSemaphore *semphore = [[LYGCDSemaphore alloc] init];
    [LYGCDQueue executeInHighPriorityGlobalQueue:^{
        if (collectionType & LYPhotoCollectionTypeAlbum) {
            NSArray *smartAlbumList = [self fetchAssetCollectionWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular];
            if (smartAlbumList.count != 0) {
                [photoList addObjectsFromArray:smartAlbumList];
            }
        }
        if (collectionType & LYPhotoCollectionTypeSmartAlbum) {
            NSArray *userAlbumList = [self fetchAssetCollectionWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary];
            if (userAlbumList.count != 0) {
                [photoList addObjectsFromArray:userAlbumList];
            }
        }
        if (collectionType & LYPhotoCollectionTypeMoment) {
            NSArray *momentList = [self fetchAssetCollectionWithType:PHAssetCollectionTypeMoment subtype:PHAssetCollectionSubtypeAlbumRegular];
            if (momentList.count != 0) {
                [photoList addObjectsFromArray:momentList];
            }
        }
        [semphore signal];
    }];
    [semphore wait];
    _lyPhotoListCache = photoList;
    return photoList;
}

/** 根据 AssetCollection 获取 Assets */
- (PHFetchResult *)fetchResultAssetsInAssetCollection:(PHAssetCollection *)assetCollection ascending:(BOOL)ascending {
    if (isNull(assetCollection)) {
        return nil;
    }
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:ascending]];
    PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:assetCollection options:option];
    return result;
}

-(void)fetchImageInAsset:(PHAsset *)asset
                makeSize:(CGSize)size
          makeResizeMode:(PHImageRequestOptionsResizeMode)resizeMode
           callBackQueue:(dispatch_queue_t)queue
              smallImage:(BOOL)small
              completion:(void (^)(UIImage *assetImage,NSString *imageFileName))completion {
    if (isNull(asset) || queue == NULL) {
        return;
    }
    NSString *imageFileName = [asset valueForKey:@"filename"];
    UIImage *image = nil;
    BOOL originalImage = [self judgeOriginSize:size];
    if (originalImage) {//原图
        id cache = [self.originalImageCache objectForKey:imageFileName];
        if (![cache isKindOfClass:[UIImage class]]) {//是data
            image = [UIImage imageWithData:cache];
        }
    } else {
        image = [self.imageCache objectForKey:imageFileName];
    }
    if (small) {//当small为yes的时候重新请求小图
        [self requestImageInAsset:asset makeSize:size makeResizeMode:resizeMode smallImage:small completion:^(UIImage *assetImage, NSString *imageFileName) {
            if (completion) {
                dispatch_async(queue, ^{
                    completion(assetImage,imageFileName);
                });
            }
        }];
    } else {
        if (image && completion) {//有缓存
            dispatch_async(queue, ^{
                completion(image,imageFileName);
            });
        } else {//无缓存
            [self removeDownloadListObjectWihtImageFileName:imageFileName original:originalImage];
            BOOL request = [self judgeRequestWithImageFileName:imageFileName original:originalImage small:small];
            if (request) {
                [self requestImageInAsset:asset makeSize:size makeResizeMode:resizeMode smallImage:small completion:^(UIImage *assetImage, NSString *imageFileName) {
                    if (completion) {
                        dispatch_async(queue, ^{
                            completion(assetImage,imageFileName);
                        });
                    }
                }];
            }
        }
    }
}

-(void)fetchImageDataInAsset:(PHAsset *)asset
              makeResizeMode:(PHImageRequestOptionsResizeMode)resizeMode
               callBackQueue:(dispatch_queue_t)queue
                  completion:(void (^)(NSData *assetImageData,NSString *imageFileName))completion {
    if (isNull(asset) || queue == NULL) {
        return;
    }
    NSString *imageFileName = [asset valueForKey:@"filename"];
    id cache = [self.originalImageCache objectForKey:imageFileName];
    if (!isNull(cache)) {//有缓存
        if (![cache isKindOfClass:[NSData class]]) {//不是data类型数据,是image
            cache = UIImageJPEGRepresentation(cache, 1.0);
        }
        if (completion) {
            dispatch_async(queue, ^{
                completion((NSData *)cache,imageFileName);
            });
        }
    } else {//无缓存
        [self removeDownloadListObjectWihtImageFileName:imageFileName original:YES];
        [self requsetImageDataInAsset:asset makeResizeMode:resizeMode completion:^(NSData *assetImageData, NSString *imageFileName) {
            if (completion) {
                dispatch_async(queue, ^{
                    completion(assetImageData,imageFileName);
                });
            }
        }];
    }
}

/** 可优化，线程应该放在这里面来写 */
- (NSArray <LYPhotoAssetObject *>*)fetchLYPhotoAssetObjectInAssetCollection:(PHAssetCollection *)assetCollection ascending:(BOOL)ascending {
    if (isNull(assetCollection)) {
        return nil;
    }
    self.assetCollectionIdentifier = assetCollection.localIdentifier;
    PHFetchResult *result = [self fetchResultAssetsInAssetCollection:assetCollection ascending:ascending];
    return [self fetchLYPhotoAssetObjectWithFetchResult:result];
}

- (NSArray <LYPhotoAssetObject *>*)fetchLYPhotoAssetObjectWithFetchResult:(PHFetchResult *)result {
    if (result.count == 0) {
        return nil;
    }
    NSMutableArray <LYPhotoAssetObject *>* lyAssets = [NSMutableArray array];
    @weakify(self)
    [result enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        LYPhotoAssetObject *assetObject = [[LYPhotoAssetObject alloc] init];
        assetObject.imageFileName = [obj valueForKey:@"filename"];
        @strongify(self)
        assetObject.assetCollectionIdentifier = self.assetCollectionIdentifier;
        assetObject.burstIdentifier = obj.burstIdentifier;
        if ([assetObject.imageFileName containsString:@".PNG"]
            || [assetObject.imageFileName containsString:@".JPG"]) {
            assetObject.asset = obj;
            [lyAssets addObject:assetObject];
        }
    }];
    return lyAssets;
}

- (NSArray <NSString *> *)fetchAllCollectionFilenameWithCollection:(PHAssetCollection *)assetCollection {
    if (isNull(assetCollection)) {
        return nil;
    }
    NSMutableArray *fileNames = [NSMutableArray array];
    PHFetchResult *result = [self fetchResultAssetsInAssetCollection:assetCollection ascending:YES];
    [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [fileNames addObject:[obj valueForKey:@"filename"]];
    }];
    return fileNames.copy;
}

- (NSArray <NSString *> *)fetchAllCollectionLocalIdentifierWithCollection:(PHAssetCollection *)assetCollection {
    if (isNull(assetCollection)) {
        return nil;
    }
    NSMutableArray *fileNames = [NSMutableArray array];
    PHFetchResult *result = [self fetchResultAssetsInAssetCollection:assetCollection ascending:YES];
    [result enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [fileNames addObject:obj.localIdentifier];
    }];
    return fileNames.copy;
}

- (NSArray <NSString *> *)fetchAllListObjectIdentifierWithCollectionType:(LYPhotoCollectionType)collectionType {
   NSArray <LYPhotoListObject *> *list = [[LYPhotoHelper shareInstance] fetchAllPhotoListNonGotoCacheWithCollectionType:collectionType];
    NSMutableArray <NSString *> *listIdentifiers = [NSMutableArray array];
    for (LYPhotoListObject *listObject in list) {
        [listIdentifiers addObject:listObject.listIdentifier];
    }
    return listIdentifiers.copy;
}

- (NSSet *)fetchAllImageNamesInPhotoListWithCollectionType:(LYPhotoCollectionType)collectionType {
    NSMutableSet *allImageNames = [NSMutableSet set];
    NSMutableArray *allAssets = [NSMutableArray array];
    NSArray <LYPhotoListObject *> *photoList = [[LYPhotoHelper shareInstance] fetchAllPhotoListWithCollectionType:collectionType];
    for (LYPhotoListObject *listObject in photoList) {
        NSArray *assets_ = [[LYPhotoHelper shareInstance] fetchLYPhotoAssetObjectInAssetCollection:listObject.assetCollection ascending:YES];
        [allAssets addObject:assets_];
    }
    for (NSArray *asset in allAssets) {
        for (LYPhotoAssetObject *object in asset) {
            [allImageNames addObject:object.imageFileName];
        }
    }
    return allImageNames.copy;
}

- (NSArray <LYPhotoObject *> *)transformLYAssetPhoto:(LYPhotoAssetObject *)lyAssetObject {
    if (isNull(lyAssetObject)) {
        return nil;
    }
    NSMutableArray *array = @[].mutableCopy;
    
    //original
    [array addObject:[self originalPhotoObjectWithLYAssetPhoto:lyAssetObject]];
    //non original
    [array addObject:[self nonOriginalPhotoObjectWithLYAssetPhoto:lyAssetObject]];
    
    return array;
}

- (void)fetchImageBytesInAssets:(NSArray <PHAsset *>*)assets bytes:(void(^)(NSString *bytes))handler {
    if (assets.count == 0) {
        if (handler) {
            handler(@"0");
        } return;
    }
    __block NSUInteger allByte = 0;
    [LYGCDQueue executeInHighPriorityGlobalQueue:^{
        dispatch_group_t group = dispatch_group_create();
        for (PHAsset *asset in assets) {
            dispatch_group_enter(group);
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                allByte += imageData.length;
                dispatch_group_leave(group);
            }];
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        NSString *bytes = [self transformSizeStringWithDataLength:allByte];
        [LYGCDQueue executeInMainQueue:^{
            if (handler) {
                handler(bytes);
            }
        }];
    }];
}

- (NSString *)transformSizeStringWithDataLength:(NSInteger)length {
    if(length < 1024)
        return [NSString stringWithFormat:@"%ldB", (long)length];
    else if(length >= 1024 && length < 1024 * 1024)
        return [NSString stringWithFormat:@"%.0fK", (float)length/1024];
    else if(length >= 1024*1024 && length < 1024*1024*1024)
        return [NSString stringWithFormat:@"%.1fM", (float)length/(1024*1024)];
    else
        return [NSString stringWithFormat:@"%.1fG", (float)length/(1024*1024*1024)];
}

-(BOOL)albumAuthority {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusRestricted || status == PHAuthorizationStatusDenied) {
        return NO;
    }
    return YES;
}

-(BOOL)cameraAuthority {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusRestricted || status == AVAuthorizationStatusDenied) {
        return NO;
    }
    return YES;
}

- (BOOL)judgeAssetisInICloud:(PHAsset *)asset {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.networkAccessAllowed = NO;
    option.synchronous = YES;
    
    __block BOOL isICloud = YES;
    
    [[PHCachingImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        isICloud = !imageData ? YES : NO;
    }];
    return isICloud;
}

- (CGSize)calculateSizeWithAsset:(PHAsset *)asset {
    if (isNull(asset)) {
        return CGSizeZero;
    }
    CGFloat pixelWidth = asset.pixelWidth;
    CGFloat pixelHeight = asset.pixelHeight;
    
    CGFloat screenScale = [UIScreen mainScreen].scale;
    return CGSizeMake(SCREEN_WIDTH * screenScale, SCREEN_WIDTH * screenScale * pixelHeight/pixelWidth);
}

#pragma mark - Private

- (NSArray <LYPhotoListObject *>*)fetchAssetCollectionWithType:(PHAssetCollectionType)type subtype:(PHAssetCollectionSubtype)subtype {
    /** PHFetchOptions 的 predicate 过滤结果 */
    PHFetchResult *smartAlbum = [PHAssetCollection fetchAssetCollectionsWithType:type subtype:subtype options:nil];
    NSMutableArray<LYPhotoListObject *> * photoList = [NSMutableArray array];
    [smartAlbum enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL * _Nonnull stop) {
        //* 不是最近删除和视频,Recently Deleted , Videos */
        if (!([collection.localizedTitle isEqualToString:@"Recently Deleted"] || [collection.localizedTitle isEqualToString:@"Videos"] || [collection.localizedTitle isEqualToString:@"最近删除"] || [collection.localizedTitle isEqualToString:@"视频"]) ) {
            PHFetchResult * result = [self fetchResultAssetsInAssetCollection:collection ascending:NO];
            if (result.count > 0) {
                LYPhotoListObject * list = [[LYPhotoListObject alloc]init];
//                list.title = [self transformAblumTitle:collection.localizedTitle];
                list.photoTitle = collection.localizedTitle;
                list.photoCount = result.count;
                list.firstAsset = result.firstObject;
                list.assetCollection = collection;
                list.listIdentifier = collection.localIdentifier;
                list.result = result;
                [photoList addObject:list];
            }
        }
    }];
    return photoList;
}

- (void)requestImageInAsset:(PHAsset *)asset
                   makeSize:(CGSize)size
             makeResizeMode:(PHImageRequestOptionsResizeMode)resizeMode
                 smallImage:(BOOL)small
                 completion:(void (^)(UIImage *assetImage,NSString *imageFileName))completion {
    static PHImageRequestID requestID = -1;
    NSLog(@"requestBefore_Image %i",requestID);
    if (requestID >= 1) {
        [[PHCachingImageManager defaultManager] cancelImageRequest:requestID];
    }

    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = resizeMode;//控制照片尺寸
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;//控制照片质量
//    option.synchronous = YES;//NO 很模糊
    option.networkAccessAllowed = YES;
    
    NSString *imageFileName = [asset valueForKey:@"filename"];
    dispatch_queue_t queue = [self fetchSerialQueue];
    if (small) {
        option = nil;
    }
    @weakify(self)
    dispatch_async(queue, ^{
        requestID = [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFit options:option resultHandler:^(UIImage * _Nullable image, NSDictionary * _Nullable info) {
            @strongify(self)
            BOOL finined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey];
            if (finined) {
                if ([self judgeOriginSize:size]) {//原图
                    if ([self.downloadOrigList containsObject:imageFileName] && isNull(image)) {
                        [self.downloadOrigList removeObject:imageFileName];
                    }
                } else {
                    if ([self.downloadList containsObject:imageFileName] && isNull(image)) {//当下载队列包含的时候，如果image为nil，则删除队列里面的下载对象
                        [self.downloadList removeObject:imageFileName];
                    }
                }
                if (image && !small) {//当image有值并且small为NO（不是小图）的时候保存
                    if ([self judgeOriginSize:size]) {//原图
                        [self.originalImageCache setObject:image forKey:imageFileName];
                    } else {
                        [self.imageCache setObject:image forKey:imageFileName];
                    }
                }
                if (completion) {
                    completion(image,imageFileName);
                }
            }
        }];
    });
}

- (void)requsetImageDataInAsset:(PHAsset *)asset
                 makeResizeMode:(PHImageRequestOptionsResizeMode)resizeMode
                     completion:(void (^)(NSData *assetImageData,NSString *imageFileName))completion  {
    static PHImageRequestID requestID = -1;
    NSLog(@"requestBefore_Data %i",requestID);
    if (requestID >= 1) {
        [[PHCachingImageManager defaultManager] cancelImageRequest:requestID];
    }
    
    NSString *imageFileName = [asset valueForKey:@"filename"];
    if (![self.downloadOrigList containsObject:imageFileName]) {//没有在下载列表
        [self.downloadOrigList addObject:imageFileName];
        [LYGCDQueue executeInGlobalQueue:^{
            PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
            option.resizeMode = resizeMode;//控制照片尺寸
            //option.deliveryMode 在请求为 requestImageDataForAsset 的时候就被忽略了
            option.synchronous = YES;
            option.networkAccessAllowed = YES;
            requestID = [[PHCachingImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                BOOL finined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                if (finined) {
                    //当下载队列包含的时候，如果image为nil，则删除队列里面的下载对象
                    if ([self.downloadOrigList containsObject:imageFileName] && isNull(imageData)) {
                        [self.downloadOrigList removeObject:imageData];
                    }
                    if (imageData) {
                        [self.originalImageCache setObject:imageData forKey:imageFileName];
                    }
                    if (completion) {
                        completion(imageData,imageFileName);
                    }
                }
            }];
        }];
    }
}

/**
 删除下载队列中的对象
 
 @param imageFileName 文件名
 @param orig 是否原图
 */
- (void)removeDownloadListObjectWihtImageFileName:(NSString *)imageFileName original:(BOOL)orig {
    if (orig && [self.downloadOrigList containsObject:imageFileName]) {//是原图，没缓存，但是在下载列表，删除
        [self.downloadOrigList removeObject:imageFileName];
    } else {
        if ([self.downloadList containsObject:imageFileName]) {
            [self.downloadList removeObject:imageFileName];
        }
    }
}

/** 判断是否需要发起请求 */
- (BOOL)judgeRequestWithImageFileName:(NSString *)imageFileName original:(BOOL)orig small:(BOOL)small {
    if (orig) {//原图
        if (![self.downloadOrigList containsObject:imageFileName]) {
            [self.downloadOrigList addObject:imageFileName];
            return YES;
        }
    } else {
        if (![self.downloadList containsObject:imageFileName] && !small) {//没有在下载列表
            [self.downloadList addObject:imageFileName];
            return YES;
        }
    }
    return NO;
}

- (LYPhotoObject *)originalPhotoObjectWithLYAssetPhoto:(LYPhotoAssetObject *)lyAssetObject {
    LYPhotoObject *originalPhotoObject = [[LYPhotoObject alloc] init];
    originalPhotoObject.imageFileName = lyAssetObject.imageFileName;
    originalPhotoObject.originalImage = YES;
    
    LYGCDSemaphore *semaphore = [[LYGCDSemaphore alloc] init];
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    [[LYPhotoHelper shareInstance] fetchImageDataInAsset:lyAssetObject.asset makeResizeMode:PHImageRequestOptionsResizeModeExact callBackQueue:queue completion:^(NSData *assetImageData,NSString *imageFileName) {
        if (assetImageData) {
            UIImage *originalImage = [UIImage imageWithData:assetImageData];
            originalImage = [originalImage fixOrientation];//方向修正
            assetImageData = UIImageJPEGRepresentation(originalImage, 1.0);
            originalPhotoObject.originalImageData = assetImageData;
            originalPhotoObject.imageByte = assetImageData.length;
            originalPhotoObject.originalImageSize = originalImage.size;
            CGSize thumbnailImageSize = LYThumbnailImageSize(originalImage.size);
            UIImage *thumbnailImage = [originalImage thumbnailImage];
            originalPhotoObject.thumbnailImageSize = thumbnailImageSize;
            NSData *thumbanlImageData = UIImageJPEGRepresentation(thumbnailImage, 1.0);
            originalPhotoObject.thumbnailImageData = thumbanlImageData;
        }
        [semaphore signal];
    }];
    [semaphore wait];
    return originalPhotoObject;
}


- (LYPhotoObject *)nonOriginalPhotoObjectWithLYAssetPhoto:(LYPhotoAssetObject *)lyAssetObject {
    LYPhotoObject *nonOriginalPhotoObject = [[LYPhotoObject alloc] init];
    nonOriginalPhotoObject.imageFileName = lyAssetObject.imageFileName;
    nonOriginalPhotoObject.originalImage = NO;
    
    CGSize size = [self calculateSizeWithAsset:lyAssetObject.asset];
    
    LYGCDSemaphore *semaphore = [[LYGCDSemaphore alloc] init];
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    [[LYPhotoHelper shareInstance] fetchImageInAsset:lyAssetObject.asset makeSize:size makeResizeMode:PHImageRequestOptionsResizeModeFast callBackQueue:queue smallImage:NO completion:^(UIImage *assetImage,NSString *imageFileName) {
        if (assetImage) {
            NSData *assetImageData = UIImageJPEGRepresentation(assetImage, photoCompressionQuality);
            assetImage = [assetImage fixOrientation];//方向修正
            nonOriginalPhotoObject.originalImageData = assetImageData;
            nonOriginalPhotoObject.imageByte = assetImageData.length;
            nonOriginalPhotoObject.originalImageSize = assetImage.size;
            CGSize thumbnailImageSize = LYThumbnailImageSize(assetImage.size);
            UIImage *thumbnailImage = [assetImage thumbnailImage];
            nonOriginalPhotoObject.thumbnailImageSize = thumbnailImageSize;
            NSData *thumbanlImageData = UIImageJPEGRepresentation(thumbnailImage, photoCompressionQuality);
            nonOriginalPhotoObject.thumbnailImageData = thumbanlImageData;
        }
        [semaphore signal];
    }];
    [semaphore wait];
    return nonOriginalPhotoObject;
}

- (void)registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMemoryWarning)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
}

static NSInteger queueIndex = 0;
- (dispatch_queue_t)fetchSerialQueue {
    dispatch_queue_t queue = self.serialQueues[queueIndex];
    ++queueIndex;
    if (queueIndex>=self.serialQueues.count) {
        queueIndex = 0;
    }
    return queue;
}

/** 根据size判断是不是原图 */
- (BOOL)judgeOriginSize:(CGSize)size {
    if (size.width == -1 && size.height == -1 ) {//size = (width = -1, height = -1)表示原图尺寸
        return YES;
    }
    return NO;
}

#pragma mark - Notification

- (void)didReceiveMemoryWarning {
    [self.imageCache removeAllObjects];
    [self.originalImageCache removeAllObjects];
    [self.downloadOrigList removeAllObjects];
    [self.downloadList removeAllObjects];
    self.serialQueues = nil;
}

# pragma mark - Custom Accessors

- (NSMutableArray *)downloadOrigList {
    if (!_downloadOrigList) {
        _downloadOrigList = [NSMutableArray array];
    }
    return _downloadOrigList;
}

- (NSMutableArray *)downloadList {
    if (!_downloadList) {
        _downloadList = [NSMutableArray array];
    }
    return _downloadList;
}

- (NSCache *)imageCache {
    if (!_imageCache) {
        _imageCache = [[NSCache alloc] init];
        if ([UIViewController photoPickerController].cacheCount != 50) {
            _imageCache.countLimit = [UIViewController photoPickerController].cacheCount;
        } else {
            _imageCache.countLimit = 50;
        }
    }
    return _imageCache;
}

- (NSCache *)originalImageCache {
    if (!_originalImageCache) {
        _originalImageCache = [[NSCache alloc] init];
        if ([UIViewController photoPickerController].cacheCount != 50) {
            _originalImageCache.countLimit = [UIViewController photoPickerController].cacheCount;
        } else {
            _originalImageCache.countLimit = 50;
        }
    }
    return _originalImageCache;
}

- (NSArray *)serialQueues {
    if (!_serialQueues) {
        NSMutableArray *array = [NSMutableArray array];
        CGFloat itemWidth = ((NSNumber *)[[UIViewController photoPickerController] valueForKey:KVC_ItemWidth_Number]).floatValue;//转换一次，不然计算出来的结果不对
        NSUInteger count = ((SCREEN_HEIGHT - 64) / itemWidth) * [UIViewController photoPickerController].lineCount * 2;//2是两个屏幕
        for (NSUInteger index = 0; index < count; index++ ) {
            [array addObject:dispatch_queue_create("fetchImageQueue", DISPATCH_QUEUE_SERIAL)];
        }
        _serialQueues = array.copy;
    }
    return _serialQueues;
}

@end
