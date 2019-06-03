//
//  LYPhotoPickerController.m
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import "LYPhotoPickerController.h"
#import "LYPhotoListViewController.h"
#import "LYPhotoSmallViewController.h"
#import "LYPhotoPickerCategory.h"
#import "LYPhotoHelper.h"
#import "LYGCD.h"

NSString *const kPhotoListChangeNotification            = @"kPhotoListChangeNotification";
NSString *const kAssetCollectionChangeNotification      = @"kAssetCollectionChangeNotification";
NSString *const kPopToListVCKey                         = @"kPopToListVCKey";
NSString *const kAddListObjectsKey                      = @"kAddListObjectsKey";
NSString *const kDeleteListObjectsKey                   = @"kDeleteListObjectsKey";
NSString *const KChangeAssetCollectionIdentifiersKey    = @"KChangeAssetCollectionIdentifiersKey";
NSString *const kSelectedDeleteObjectIdentifiersKey     = @"kSelectedDeleteObjectIdentifiersKey";
NSString *const kCollectionDeleteObjectIdentifiersKey   = @"kCollectionDeleteObjectIdentifiersKey";
NSString *const kCollectionAddObjectIdentifiersKey      = @"kCollectionAddObjectIdentifiersKey";
NSString *const kNeedReloadDataKey                      = @"kNeedReloadDataKey";


NSString *const KVC_CurrentSelectedAssecCollection  = @"currentSelectedAssecCollection";
NSString *const KVC_SelectCollectionResultDict      = @"selectCollectionResultDict";
NSString *const KVC_ItemWidth_Number                = @"itemWidth";
NSString *const KVC_PhotoListIdentifiers            = @"photoListIdentifiers";

@interface LYPhotoPickerController ()
<
PHPhotoLibraryChangeObserver
>

@property (nonatomic, strong) NSMutableDictionary <NSString */*photoListObject.localIdentifier*/,NSMutableArray <LYPhotoAssetObject *> *> *selectedItemInfo;

/** 记录 AssetCollection 改变 */
@property (nonatomic, strong) NSMutableDictionary <NSString */*listObjectIdentifier*/,NSArray <NSString */*listObject对应集合里面的LYPhotoAssetObject.identifier.*/>*> *currentSelectedListInfo;

/** 相册改变，存所有list的identifier，当 list 个数发生改变 找到被删的，如果是新增的话就发空对象（不包含元素的对象），在收到通知的时候，如果收到的对象不为空的话，就遍历处理，为空的话就不刷新 */
@property (nonatomic, strong) NSArray <NSString *> *photoListIdentifiers;

@property (nonatomic, strong) NSNumber *itemWidth;

@end

@implementation LYPhotoPickerController

# pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _saveSelected = YES;
        _supportMultiSelect = YES;
        _markType = LYPhotoListSelectMarkTypeNumber;
        _collectionType = LYPhotoCollectionTypeAlbum|LYPhotoCollectionTypeSmartAlbum;
        _selectedItemInfo = [NSMutableDictionary dictionary];
        _currentSelectedListInfo = [NSMutableDictionary dictionary];
        
        _lineCount = 3;
        _spacing = 5.0f;
        _cacheTotalCostLimit = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self authorization];
    [self registerNotification];
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark - Private Methods

- (void)authorization {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status) {
        case PHAuthorizationStatusNotDetermined:
            [self requestAuthorization];
            break;
        case PHAuthorizationStatusAuthorized:
            [self fetchDataAndLoadVC];
            break;
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted: {
            self.navigationItem.title = @"Error";
            UILabel *tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100.0f, SCREEN_WIDTH, 100.0f)];
            tipLabel.textColor = [UIColor redColor];
            tipLabel.text = @"请在iPhone的\"设置-隐私-相册\"中允许访问相册";
            tipLabel.font = [UIFont systemFontOfSize:28.0f];
            tipLabel.numberOfLines = 0;
            tipLabel.textAlignment = NSTextAlignmentCenter;
            [self.view addSubview:tipLabel];
            
            CGFloat x = (SCREEN_WIDTH - 100.0f)/2.0f;
            CGFloat y = CGRectGetMaxY(tipLabel.frame);
            UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(x, y + 50.0f, 100.0f, 50.0f)];
            [btn setTitle:@"确定" forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont systemFontOfSize:30.0f];
            [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(clickedDismissBtn:) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:btn];
            
        }
            break;
        default:
            break;
    }
}

- (void)registerNotification {
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

/** 请求权限 */
- (void)requestAuthorization {
    @weakify(self)
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        //在子线程
        if (status == PHAuthorizationStatusAuthorized) {
            dispatch_async_on_main_queue(^{
                @strongify(self)
                [self fetchDataAndLoadVC];
                
            });
        } else if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {//未允许
            dispatch_async_on_main_queue(^{
                @strongify(self)
                LYPhotoSmallViewController *smallVC = [[LYPhotoSmallViewController alloc] init];
                self.viewControllers = @[smallVC];
                
            });
        }
    }];
}

- (void)fetchDataAndLoadVC {
    NSArray *photoList_ = [[LYPhotoHelper shareInstance] fetchAllPhotoListWithCollectionType:self.collectionType];
    
    NSMutableArray *listIdentifiers = [NSMutableArray array];
    for (LYPhotoListObject *listObject in photoList_) {
        [listIdentifiers addObject:listObject.listIdentifier];
    }
    self.photoListIdentifiers = listIdentifiers;
    
    LYPhotoListViewController *listVC = [[LYPhotoListViewController alloc] init];
    LYPhotoSmallViewController *smallVC = [[LYPhotoSmallViewController alloc] init];
    
    @weakify(listVC)
    void(^selectedAlbumTitlesAndNumberBlock)(NSDictionary <NSString *, NSNumber *> *albumTitlesAndNumberDict) = ^(NSDictionary <NSString *, NSNumber *> *albumTitlesAndNumberDict) {
        @strongify(listVC)
        listVC.selectedAlbumTitlesAndNumberDict = albumTitlesAndNumberDict;
    };
    
    void(^containsPhotoListNamesBlock)(NSSet <NSString *> *containsPhotoListNames) = ^ (NSSet <NSString *> *containsPhotoListNames) {
        @strongify(listVC)
        listVC.containsPhotoListNames = containsPhotoListNames;
    };
    
    smallVC.selectedAlbumTitlesAndNumberBlock = selectedAlbumTitlesAndNumberBlock;
    smallVC.containsPhotoListNamesBlock = containsPhotoListNamesBlock;
    
    LYPhotoListObject *list_ = nil;
    for (LYPhotoListObject *list in photoList_) {
        if ([list.photoTitle isEqualToString:@"Camera Roll"] || [list.photoTitle isEqualToString:@"相机胶卷"] || [list.photoTitle isEqualToString:@"所有照片"] || [list.photoTitle isEqualToString:@"All Photos"]) {
            list_ = list;
            break;
        }
    }
    if (!list_) {
        list_ = photoList_.firstObject;
    }
    
    smallVC.smallTitle = list_.photoTitle;
    [MBProgressHUD showLargeHUD:@"正在加载..."];
    @weakify(self)
    [LYGCDQueue executeInGlobalQueue:^{
        smallVC.fetchLYSmallAsset = [[LYPhotoHelper shareInstance] fetchLYPhotoAssetObjectInAssetCollection:list_.assetCollection ascending:YES];
        self.currentSelectedListInfo[list_.listIdentifier] = [[LYPhotoHelper shareInstance] fetchImageDataInAsset:<#(PHAsset *)#> makeResizeMode:<#(PHImageRequestOptionsResizeMode)#> callBackQueue:<#(dispatch_queue_t)#> completion:<#^(NSData *assetImageData, NSString *imageFileName)completion#>]
        dispatch_async_on_main_queue(^{
            [MBProgressHUD dismissHUD];
            @strongify(self)
            self.viewControllers = @[listVC,smallVC];
        });
    }];
}

# pragma mark - IBActions

- (void)clickedDismissBtn:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)authorizationStatusDenied {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"请在iPhone的\"设置-隐私-相册\"中允许访问相册" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }];
    [alertController addAction:cancelAction];
    [[UIViewController currentViewController] presentViewController:alertController animated:YES completion:NULL];
}

#pragma mark - Custom Getter

- (NSNumber *)itemWidth {
    if (_lineCount > 4) _lineCount  = 4;
    if (_lineCount < 3) _lineCount = 3;

    if (_spacing < 2) _spacing = 2;
    if (_spacing > 10) _spacing = 10;

   return  @((SCREEN_WIDTH - _spacing * _lineCount - 1)/_lineCount);
}

#pragma mark - Change Handling

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
   
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
