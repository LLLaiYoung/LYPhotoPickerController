//
//  LYPhotoSmallViewController.m
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import "LYPhotoSmallViewController.h"
#import "LYPhotoSmallCell.h"
#import "LYPhotoHelper.h"
#import "LYPhotoMacro.h"
#import "LYPhotoBrowserViewController.h"
#import "LYPhotoPickerCategory.h"

static CGFloat const bottomContainerViewHeight = 44.0f;

static NSUInteger maxCount;
/** key:PHAssetCollection.localIdentifier value:NSMutableArray 在删减的时候先匹配localIdentifier*/
static NSMutableDictionary <NSString *, NSMutableArray <LYPhotoAssetObject *> *> *selectedItemDict;
/** 选择的原图 */
static NSMutableArray <LYPhotoObject *> *selectedOrigianlPhotoObjects;
/** 选择的非原图 */
static NSMutableArray <LYPhotoObject *> *selectedNonOriginalPhotoPbjects;
/** key:PHAssetCollection.localIdentifier value:PHFetchResult，只增不删 */
static NSMutableDictionary <NSString *, PHFetchResult *> *selectedCollectionResultDict;

/** 相册改变 */
static PHAssetCollection *currentSelectedAssecCollection;

@interface LYPhotoSmallViewController ()
@property (nonatomic, strong) UICollectionView *smallCollectionView;
@property (nonatomic, strong) UIView *bottomContainerView;
@property (nonatomic, strong) UIButton *previewBtn;
@property (nonatomic, strong) UIButton *senderBtn;

@end

@implementation LYPhotoSmallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadData];
    [self initSubviews];
    [self resetSendBtnTitle];
    [self registerNotification];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSArray *visiableItems = [self.smallCollectionView indexPathsForVisibleItems];
    [self.smallCollectionView reloadItemsAtIndexPaths:visiableItems];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.selectedAlbumTitlesAndNumberBlock) {
        self.selectedAlbumTitlesAndNumberBlock([self selectedAlbumTitlesAndNumberDict]);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - LayoutSubviews
- (void)initSubviews {
    if (![[LYPhotoHelper shareInstance] albumAuthority]) {
        [self showAlertControllerWithAlertMsg:@"请在iPhone的\"设置-隐私-相册\"中允许访问相册" actionBlock:^{
            [[UIViewController currentViewController] dismissViewControllerAnimated:YES completion:NULL];
        }];
    } else {
        self.title = _smallTitle;
        UIBarButtonItem *cancelBtnItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(clickedCancelBtnItem:)];
        self.navigationItem.rightBarButtonItem = cancelBtnItem;
        self.view.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:self.smallCollectionView];
        [self.view addSubview:self.bottomContainerView];
    }
}

# pragma mark - Custom Accessors

- (UICollectionView *)smallCollectionView
{
    if (!_smallCollectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        NSNumber *itemWidth = [[UIViewController photoPickerController] valueForKey:KVC_ItemWidth_Number];
        flowLayout.itemSize = CGSizeMake(itemWidth.floatValue, itemWidth.floatValue);
        flowLayout.minimumLineSpacing = [UIViewController photoPickerController].spacing;
        flowLayout.minimumInteritemSpacing = [UIViewController photoPickerController].spacing;
        _smallCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - bottomContainerViewHeight) collectionViewLayout:flowLayout];
        _smallCollectionView.backgroundColor = [UIColor whiteColor];
        _smallCollectionView.delegate = (id)self;
        _smallCollectionView.dataSource = (id)self;
        [_smallCollectionView registerClass:[LYPhotoSmallCell class] forCellWithReuseIdentifier:NSStringFromClass(self.class)];
        _smallCollectionView.alwaysBounceVertical = YES;
    }
    return _smallCollectionView;
}

- (NSUInteger)selectedAlbumCount {
    return [self fetchAllSelectedLYPhotoAssetObjects].count;
}

- (NSArray<PHAsset *> *)selectedAssets {
    NSMutableArray *assets = @[].mutableCopy;
    NSArray *keys = selectedItemDict.allKeys;
    for (NSString *key in keys) {
       NSArray *lyAssetObjects = selectedItemDict[key];
        for (LYPhotoAssetObject *lyAssetObject in lyAssetObjects) {
            [assets addObject:lyAssetObject.asset];
        }
    }
    return assets.copy;
}

- (UIButton *)previewBtn {
    if (!_previewBtn) {
        CGFloat x = (SCREEN_WIDTH/2.0f - self.bottomContainerView.height)/2.0f;
        _previewBtn = [[UIButton alloc] initWithFrame:CGRectMake(x, 0, self.bottomContainerView.height, self.bottomContainerView.height)];
        [_previewBtn setTitle:@"预览" forState:UIControlStateNormal];
        _previewBtn.titleLabel.font = [UIFont systemFontOfSize:18.0f];
        [_previewBtn setTitleColor:blueColor forState:UIControlStateNormal];
        [_previewBtn setTitleColor:disableColor forState:UIControlStateDisabled];
        [_previewBtn addTarget:self action:@selector(clickedPreviewBtn:) forControlEvents:UIControlEventTouchUpInside];
        _previewBtn.enabled = NO;
    }
    return _previewBtn;
}

- (UIButton *)senderBtn {
    if (!_senderBtn) {
        CGFloat x = (SCREEN_WIDTH/2.0f - self.bottomContainerView.height)/2.0f + SCREEN_WIDTH/2.0f;
        _senderBtn = [[UIButton alloc] initWithFrame:CGRectMake(x, 0, 100, self.bottomContainerView.height)];
        [_senderBtn setTitle:@"发送" forState:UIControlStateNormal];
        _senderBtn.titleLabel.font = [UIFont systemFontOfSize:18.0f];
        [_senderBtn setTitleColor:blueColor forState:UIControlStateNormal];
        [_senderBtn setTitleColor:disableColor forState:UIControlStateDisabled];
        [_senderBtn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [_senderBtn addTarget:self action:@selector(clickedSenderBtn:) forControlEvents:UIControlEventTouchUpInside];
        _senderBtn.enabled = NO;
    }
    return _senderBtn;
}

- (UIView *)bottomContainerView {
    if (!_bottomContainerView) {
        CGFloat y = SCREEN_HEIGHT - 44.0f;
        _bottomContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, y, SCREEN_WIDTH, bottomContainerViewHeight)];
        _bottomContainerView.backgroundColor = [UIColor whiteColor];
        
        CALayer *lineLayer = [[CALayer alloc] init];
        lineLayer.borderColor = disableColor.CGColor;
        lineLayer.borderWidth = 1.0f;
        lineLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, 1.0f);
        [_bottomContainerView.layer addSublayer:lineLayer];
        [_bottomContainerView addSubview:self.previewBtn];
        [_bottomContainerView addSubview:self.senderBtn];
    }
    return _bottomContainerView;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _fetchLYSmallAsset.count;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(LYPhotoSmallCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    LYPhotoAssetObject *assetObject_ = _fetchLYSmallAsset[indexPath.item];
    for (LYPhotoAssetObject *lyAssetObject in [self fetchAllSelectedLYPhotoAssetObjects]) {
        if ([assetObject_.imageFileName isEqualToString:lyAssetObject.imageFileName]) {
            cell.selectBtn.selected = YES;
            cell.selectedIndex = lyAssetObject.selectedIndex;
            break;
        }
    }
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LYPhotoSmallCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(self.class) forIndexPath:indexPath];
    LYPhotoAssetObject *assetObject_ = _fetchLYSmallAsset[indexPath.item];
    cell.delegate = (id)self;
    cell.identifier = assetObject_.imageFileName;
    cell.indexPath = indexPath;
    cell.asset = assetObject_.asset;
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    LYPhotoBrowserViewController *browserVC = [[LYPhotoBrowserViewController alloc] init];
    browserVC.dataSource = _fetchLYSmallAsset.mutableCopy;
    browserVC.index = indexPath.row;
    browserVC.albumTitle = _smallTitle;
    [self.navigationController pushViewController:browserVC animated:YES];
}

# pragma mark - IBActions

- (void)clickedCancelBtnItem:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self removeAllObjects];
        [[LYPhotoHelper shareInstance] didReceiveMemoryWarning];
    }];
}

- (void)clickedPreviewBtn:(UIButton *)sender {
    LYPhotoBrowserViewController *browserVC = [[LYPhotoBrowserViewController alloc] init];
    browserVC.dataSource = [NSMutableArray arrayWithArray:[self fetchAllSelectedLYPhotoAssetObjects]];
    browserVC.albumTitle = _smallTitle;
    browserVC.previewModel = YES;
    [self.navigationController pushViewController:browserVC animated:YES];
}

- (void)clickedSenderBtn:(UIButton *)sender {
    [self clickedSenderWithOriginal:NO];
}

# pragma mark - Public

- (BOOL)isExistsLYPhotoAssetObject:(LYPhotoAssetObject *)object {
    for (LYPhotoAssetObject *assetObject in [self fetchAllSelectedLYPhotoAssetObjects]) {
        if ([object.imageFileName isEqualToString:assetObject.imageFileName]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)operationSelectedPhotoObjectsWithLYAssetObject:(LYPhotoAssetObject *)lyAssetObject
                                            identifier:(NSString *)identifier
                                                remove:(BOOL)remove
                                               showTip:(BOOL)show
{
    if (isNull(lyAssetObject) || isNullStr(identifier)) {
        return NO;
    }
    
    NSMutableArray <LYPhotoAssetObject *> *objects = selectedItemDict[identifier];
    if (!objects) {
        objects = [NSMutableArray array];
    }
    
    if (remove) {
        lyAssetObject = [self conversionLYPhotoAssetObject:lyAssetObject];
        [objects removeObject:lyAssetObject];
        
    } else {
        /** 没包含需要添加的对象，并且没有达到最大张数 */
        if (![self selectedItemsContainLYPhotoAssetObject:lyAssetObject] && [self fetchAllSelectedLYPhotoAssetObjects].count < maxCount) {
            [objects addObject:lyAssetObject];
            selectedItemDict[identifier] = objects;
        } else {
            if (show) {
                [self alert];
            }
            return NO;
        }
    }
    
    [self resetSendBtnTitle];
    
    [self reorder];
    
    return YES;
}

- (void)removeAllObjects {
    [selectedItemDict removeAllObjects];
    [selectedOrigianlPhotoObjects removeAllObjects];
    [selectedNonOriginalPhotoPbjects removeAllObjects];
    [selectedCollectionResultDict removeAllObjects];
    maxCount = 0;
}

- (void)showAlertControllerWithAlertMsg:(NSString *)alertMsg actionBlock:(dispatch_block_t)actionBlock {
    if (!isNullStr(alertMsg)) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:alertMsg preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (actionBlock) {
                actionBlock();
            }
        }];
        [alertController addAction:cancelAction];
        [[UIViewController currentViewController] presentViewController:alertController animated:YES completion:NULL];
    }
}

- (void)handlePhotoListChangeWithNotification:(NSNotification *)noti deleteHandle:(dispatch_block_t)deleteHandle {
    NSMutableSet *deleteOrAddIdentifierSet = noti.userInfo[kDeleteIdentifier];
    if (deleteOrAddIdentifierSet.count == 0) {//新增不管
        return;
    }
    NSArray <NSString *> *listIdentifiers = [[LYPhotoHelper shareInstance] fetchAllListObjectIdentifier];
    
    NSString *currentIdentifier = currentSelectedAssecCollection.localIdentifier;
    if (![listIdentifiers containsObject:currentIdentifier]) {//当前列表被删了
        if (deleteHandle) {
            deleteHandle();
        }
        [self showAlertControllerWithAlertMsg:@"该相册已被删除" actionBlock:^{
            [[UIViewController currentNavigationViewController] popToRootViewControllerAnimated:YES];
        }];
        NSMutableSet *allAssetImageNames = [NSMutableSet set];
        for (NSUInteger index = 0; index < maxCount; index++) {
            NSString *string = [NSString stringWithFormat:@"null+nil+error+%lu",index];
            [allAssetImageNames addObject:string];
        }
        [self handleDeleteDevicePhotoObjects:allAssetImageNames key:currentIdentifier];
        [deleteOrAddIdentifierSet removeObject:currentIdentifier];
    }
    //其他列表，其中可能含有已经选中的，不使用else 是因为deleteOrAddIdentifierSet可能是很多个，如果在当前列表中，走了if，那么在其他被删的列表中，选中的就不会处理
    for (NSString *deleteIdentifier in deleteOrAddIdentifierSet) {
        NSMutableSet *allAssetImageNames = [NSMutableSet set];
        for (NSUInteger index = 0; index < maxCount; index++) {
            NSString *string = [NSString stringWithFormat:@"null+nil+error+%lu",index];
            [allAssetImageNames addObject:string];
        }
        [self handleDeleteDevicePhotoObjects:allAssetImageNames key:deleteIdentifier];
    }
}

# pragma mark - Private

- (void)loadData {
    if (isNull(selectedItemDict)) {
        selectedItemDict = @{}.mutableCopy;
        selectedOrigianlPhotoObjects = @[].mutableCopy;
        selectedNonOriginalPhotoPbjects = @[].mutableCopy;
        selectedCollectionResultDict = @{}.mutableCopy;
    }
    if (maxCount==0) {
        maxCount = [UIViewController photoPickerController].maxCount;
    }
    currentSelectedAssecCollection = [[UIViewController photoPickerController] valueForKey:KVC_CurrentSelectedAssecCollection];
}

- (void)registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetCollectionChangeNotification:) name:kAssetCollectionChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoListChangeNotification:) name:kPhotoListChangeNotification object:nil];
}

/** 获取所以已经选择的LYPhotoAssetObject */
- (NSArray <LYPhotoAssetObject *>*)fetchAllSelectedLYPhotoAssetObjects {
    NSMutableArray *assetObjects = @[].mutableCopy;
    NSArray *keys = selectedItemDict.allKeys;
    for (NSString *key in keys) {
        NSArray <LYPhotoAssetObject *> *assetObjects_ = selectedItemDict[key];
        if (assetObjects_.count != 0) {
            [assetObjects addObjectsFromArray:assetObjects_];
        }
    }
    return assetObjects;
}

/** 从 _fetchLYSmallAsset 里面的 LYPhotoAssetObject 对象找到存放在 selectedItems 里面对应的 LYPhotoAssetObject 对象，然后根据这个对象去删除 */
- (LYPhotoAssetObject *)conversionLYPhotoAssetObject:(LYPhotoAssetObject *)assetObject {
    for (LYPhotoAssetObject *object in [self fetchAllSelectedLYPhotoAssetObjects]) {
        if ([assetObject.imageFileName isEqualToString:object.imageFileName]) {
            return object;
        }
    }
    return nil;
}

- (BOOL)selectedItemsContainLYPhotoAssetObject:(LYPhotoAssetObject *)lyAssetObject {
    for (LYPhotoAssetObject *object in [self fetchAllSelectedLYPhotoAssetObjects]) {
        if ([object.imageFileName isEqualToString:lyAssetObject.imageFileName]) {
            return YES;
        }
    }
    return NO;
}


- (NSDictionary <NSString *, NSNumber *> *)selectedAlbumTitlesAndNumberDict {
    NSMutableSet *titleSet = [NSMutableSet set];
    NSMutableArray *operationArray = [NSMutableArray array];
    for (LYPhotoAssetObject *assetObject in [self fetchAllSelectedLYPhotoAssetObjects]) {
        [titleSet addObject:assetObject.albumTitle];
        [operationArray addObject:assetObject.albumTitle];
    }
    NSMutableDictionary <NSString *,NSNumber *> *titlesAndNumberDict = [NSMutableDictionary dictionary];
    for (NSString *title in titleSet) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF == %@", title];
        NSArray *filteredArray = [operationArray filteredArrayUsingPredicate:predicate];
        [titlesAndNumberDict setObject:@(filteredArray.count) forKey:title];
    }
    
    return titlesAndNumberDict.copy;
}

//- (void)ss {
//    NSArray *titles = [self selectedAlbumTitlesAndNumberDict].allKeys;
//    NSArray *lists = [[LYPhotoHelper shareInstance] fetchAllPhotoList];
//    for (LYPhotoListObject *listObject in lists) {
//       NSArray *collectionFilenames = [[LYPhotoHelper shareInstance] fetchAllCollectionFilenameWithCollection:listObject.assetCollection];
//
//    }
//}

/** 如果超过 maxCount 就弹出提示框（在 !selected 的时候判断 ），返回 YES return */
- (BOOL)alert {
    if ([self fetchAllSelectedLYPhotoAssetObjects].count >= maxCount) {
        NSString *alertString = [NSString stringWithFormat:@"一次最多选择%li张照片",(unsigned long)maxCount];
        [self showAlertControllerWithAlertMsg:alertString actionBlock:^{
            [[UIViewController currentViewController] dismissViewControllerAnimated:YES completion:NULL];
        }];
        return YES;
    }
    return NO;
}

- (void)resetSendBtnTitle {
    //获取当前选择的 PHAssetCollection
    if (isNull(currentSelectedAssecCollection)) {
        return;
    }
    //获取当前选择的 PHFetchResult
    PHFetchResult *result = [[LYPhotoHelper shareInstance] fetchResultAssetsInAssetCollection:currentSelectedAssecCollection ascending:YES];
    NSArray *allLYPhotoAssetObjects = [self fetchAllSelectedLYPhotoAssetObjects];
    if (allLYPhotoAssetObjects.count != 0) {
        _previewBtn.enabled = YES;
        _senderBtn.enabled = YES;
        //新增一个 PHFetchResult
        [selectedCollectionResultDict setValue:result forKey:currentSelectedAssecCollection.localIdentifier];
        
        NSString *string = [NSString stringWithFormat:@"发送(%li)",allLYPhotoAssetObjects.count];
        [self.senderBtn setTitle:string forState:UIControlStateNormal];
    } else {
        _previewBtn.enabled = NO;
        _senderBtn.enabled = NO;
        [self.senderBtn setTitle:@"发送" forState:UIControlStateNormal];
    }
    
    //更新选择的 PHFetchResult
    [[UIViewController photoPickerController] setValue:selectedCollectionResultDict forKey:KVC_SelectCollectionResultDict];
}

- (void)clickedSenderWithOriginal:(BOOL)original {
    if ([UIViewController photoPickerController].senderBlock) {
        [MBProgressHUD showSmallHUD];
        @weakify(self)
        [LYGCDQueue executeInGlobalQueue:^{
            //* 模型转换 */
            for (LYPhotoAssetObject *assetObject in [self fetchAllSelectedLYPhotoAssetObjects]) {
                NSArray <LYPhotoObject *> *photoObjects = [[LYPhotoHelper shareInstance] transformLYAssetPhoto:assetObject];
                [selectedOrigianlPhotoObjects addObject:photoObjects.firstObject];
                [selectedNonOriginalPhotoPbjects addObject:photoObjects.lastObject];
            }
            
            //* 将数据深拷贝一份，防止数据还没发送出去,原始数据就被删除了 */
            NSArray *objects = nil;
            if (original) {
                objects = [[NSArray alloc] initWithArray:selectedOrigianlPhotoObjects.copy copyItems:YES];
            } else {
                objects = [[NSArray alloc] initWithArray:selectedNonOriginalPhotoPbjects.copy copyItems:YES];
            }
            
            dispatch_async_on_main_queue(^{
                @strongify(self)
                [UIViewController photoPickerController].senderBlock(objects);
                [MBProgressHUD dismissHUD];
                [[UIViewController currentViewController] dismissViewControllerAnimated:YES completion:^{
                    [self removeAllObjects];
                    [[LYPhotoHelper shareInstance] didReceiveMemoryWarning];
                }];
            });
        }];
    }
}

/** 判断这个相册里是否含有这个对象 */
- (BOOL)containerLYPhotoObject:(LYPhotoAssetObject *)assetObject {
    for (LYPhotoAssetObject *object in _fetchLYSmallAsset) {
        if ([object.imageFileName isEqualToString:assetObject.imageFileName]) {
            return YES;
        }
    }
    return NO;
}

/** 根据 LYPhotoAssetObject 获取它在这个相册中的IndexPath */
- (NSIndexPath *)lyAssetObjectIndexPathWithLYPhotoAssetObject:(LYPhotoAssetObject *)lyAssetObject {
    for (NSUInteger index = 0; index < _fetchLYSmallAsset.count; index++ ) {
        LYPhotoAssetObject *object = _fetchLYSmallAsset[index];
        if ([lyAssetObject.imageFileName isEqualToString:object.imageFileName]) {
            return [NSIndexPath indexPathForRow:index inSection:0];
        }
    }
    return nil;
}

/** 重新排序 */
- (void)reorder {
    //无序数组
    NSMutableArray <LYPhotoAssetObject *> *allSelectedLYAssetObject = [NSMutableArray arrayWithArray:[self fetchAllSelectedLYPhotoAssetObjects]];
    if (allSelectedLYAssetObject.count == 0) {
        return;
    }
    //有序数组
    NSMutableArray <LYPhotoAssetObject *> *orderlyAssetObjects = [NSMutableArray array];
    
    NSArray *allLYPhotoAssetObjects = [self fetchAllSelectedLYPhotoAssetObjects];
    for (NSUInteger index_ = 0; index_ < allLYPhotoAssetObjects.count; index_++ ) {
        //找最小的selectIndex
        LYPhotoAssetObject *minAssetObject = allSelectedLYAssetObject.firstObject;
        for (NSUInteger index = 1; index < allSelectedLYAssetObject.count; index++ ) {
            LYPhotoAssetObject *assetObject  = allSelectedLYAssetObject[index];
            if (assetObject.selectedIndex < minAssetObject.selectedIndex) {
                minAssetObject = assetObject;
            }
        }
        //* 同一个相册或者这个相册含有这个对象才排序 */
        if ([minAssetObject.albumTitle isEqualToString:_smallTitle] || [self containerLYPhotoObject:minAssetObject]) {
            NSIndexPath *indexPath = nil;
            LYPhotoSmallCell *selectedCell = nil;
            //不是同一个相册，需要先查找到这个对象在这个相册中的位置
            if (![minAssetObject.albumTitle isEqualToString:_smallTitle]) {
                indexPath = [self lyAssetObjectIndexPathWithLYPhotoAssetObject:minAssetObject];
                selectedCell = (LYPhotoSmallCell *)[self.smallCollectionView cellForItemAtIndexPath:indexPath];
            } else {
                selectedCell = (LYPhotoSmallCell *)[self.smallCollectionView cellForItemAtIndexPath:minAssetObject.selectedIndexPath];
            }
            
            LYPhotoAssetObject *maxAssetObject = orderlyAssetObjects.lastObject;
            if (isNull(maxAssetObject)) {//为空，构造数据
                maxAssetObject = [[LYPhotoAssetObject alloc] init];
                maxAssetObject.selectedIndex = 0;
                maxAssetObject.nextIndex = 1;
            }
            
            //如果是最小的，加入有序数组，从无序数组中删除，如果不是，就该成最小的，在再加有序数组，从无序数组删除
            if (minAssetObject.selectedIndex != maxAssetObject.nextIndex) {
                minAssetObject.selectedIndex = maxAssetObject.nextIndex;
                minAssetObject.nextIndex = minAssetObject.selectedIndex + 1;
            }
            selectedCell.selectedIndex = minAssetObject.selectedIndex;
        }
        [orderlyAssetObjects addObject:minAssetObject];
        [allSelectedLYAssetObject removeObject:minAssetObject];
    }
}

#pragma mark - LYPhotoSmallCellDelegate

- (void)didClickedSelectButton:(LYPhotoSmallSelectedBtn *)sender indexPath:(NSIndexPath *)indexPath {
    LYPhotoSmallCell *cell = (LYPhotoSmallCell *)[self.smallCollectionView cellForItemAtIndexPath:indexPath];
    if (cell) {
        if (!cell.selectBtn.selected) {
            if ([self alert]) {
                return ;
            }
        }
        
        if (!cell.selectBtn.selected) {
            [sender.layer addAnimation:GetBtnStatusChangedAnimation() forKey:nil];
        }
        cell.selectBtn.selected = !cell.selectBtn.selected;
        cell.selectedIndex = -1;
        LYPhotoAssetObject *lyAssetObject = self.fetchLYSmallAsset[indexPath.row];
        lyAssetObject.albumTitle = _smallTitle;
        lyAssetObject.selectedIndexPath = indexPath;
        if (cell.selectBtn.selected) {
            lyAssetObject.selectedIndex = [self fetchAllSelectedLYPhotoAssetObjects].count + 1;
            lyAssetObject.nextIndex = lyAssetObject.selectedIndex + 1;
            [self operationSelectedPhotoObjectsWithLYAssetObject:lyAssetObject identifier:currentSelectedAssecCollection.localIdentifier remove:NO showTip:YES];
        } else {
            [self operationSelectedPhotoObjectsWithLYAssetObject:lyAssetObject identifier:currentSelectedAssecCollection.localIdentifier remove:YES showTip:NO];
        }
    }
}

#pragma mark - Notification

- (void)assetCollectionChangeNotification:(NSNotification *)noti {
    PHFetchResult *afterResult = noti.userInfo[kAfter];
    NSString *key = noti.userInfo[kKey];
    self.fetchLYSmallAsset = [[LYPhotoHelper shareInstance] fetchLYPhotoAssetObjectInAssetCollection:currentSelectedAssecCollection ascending:YES];
    //要先reload
    [self.smallCollectionView reloadData];
    if (self.fetchLYSmallAsset.count == 0) {
        [self showAlertControllerWithAlertMsg:@"该相册无照片" actionBlock:^{
            [[UIViewController currentNavigationViewController] popViewControllerAnimated:YES];
        }];
    } else {
        if ([currentSelectedAssecCollection.localIdentifier isEqualToString:key]) {//是当前才滚动到最后
            [self.smallCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.fetchLYSmallAsset.count-1 inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        }
        
    }
    [self handleDeleteDevicePhotoObjectWithAfterResult:afterResult key:key];
}
- (void)photoListChangeNotification:(NSNotification *)noti {
    if (![[UIViewController currentViewController] isKindOfClass:[self class]]) return;
    @weakify(self)
    [self handlePhotoListChangeWithNotification:noti deleteHandle:^{
        @strongify(self)
        self.fetchLYSmallAsset = nil;
        [self.smallCollectionView reloadData];
    }];
}

#pragma mark - 处理通过设备的“照片”形式删除的对象

/** 处理通过设备的“照片”形式删除的对象 */
- (void)handleDeleteDevicePhotoObjectWithAfterResult:(PHFetchResult *)afterResult key:(NSString *)key {
    if ([self fetchAllSelectedLYPhotoAssetObjects].count == 0 || isNullStr(key) || isNull(afterResult)) {
        return;
    }
    
    PHFetchResult *result = selectedCollectionResultDict[key];
    NSArray <LYPhotoAssetObject *> *fetchLYSmallAsset = [[LYPhotoHelper shareInstance] fetchLYPhotoAssetObjectWithFetchResult:result];
    NSArray <LYPhotoAssetObject *> *afterLYSmallAsset = [[LYPhotoHelper shareInstance] fetchLYPhotoAssetObjectWithFetchResult:afterResult];
    if (afterLYSmallAsset.count == fetchLYSmallAsset.count) {
        return;
    }
    NSMutableSet *allAssetImageNames = [NSMutableSet set];
    for (LYPhotoAssetObject *object in afterLYSmallAsset) {
        [allAssetImageNames addObject:object.imageFileName];
    }
    if (allAssetImageNames.count == 0) {//即这个相册已经被删完了,构造假数据
        for (NSUInteger index = 0; index < maxCount; index++) {
            NSString *string = [NSString stringWithFormat:@"null+nil+error+%lu",index];
            [allAssetImageNames addObject:string];
        }
    }
    
    [self handleDeleteDevicePhotoObjects:allAssetImageNames key:key];
}

- (void)handleDeleteDevicePhotoObjects:(NSSet *)objects key:(NSString *)key {
    if (objects.count == 0 || isNullStr(key)) {
        return;
    }
    
    NSMutableArray <LYPhotoAssetObject *> *assetObjects = [NSMutableArray arrayWithArray:selectedItemDict[key]];
    
    NSUInteger selectedIndex = 0;
    NSUInteger count = objects.count > assetObjects.count ? objects.count : assetObjects.count;
    for (NSUInteger index = 0; index < count; index++) {
        if (assetObjects.count == 0) {//没数据了直接返回
            return;
        }
        NSString *imageName = assetObjects[selectedIndex].imageFileName;
        if (![objects containsObject:imageName]) {//被删了
            LYPhotoAssetObject *object = [[LYPhotoAssetObject alloc] init];
            object.imageFileName = imageName;//构造LYPhotoAssetObject对象，在operationSelectedPhotoObjectsWithLYAssetObject，是根据imageFileName去找对应的对象
            BOOL success = [self operationSelectedPhotoObjectsWithLYAssetObject:object identifier:key remove:YES showTip:NO];
            if (success) {
                [assetObjects removeObjectAtIndex:selectedIndex];
            }
        } else {
            ++selectedIndex;
            if (selectedIndex > assetObjects.count - 1) {
                break;
            }
        }
    }
    
    /** 重新排序 */
    [self reorder];
}

# pragma mark - Protocol conformance

# pragma mark - UITextFieldDelegate

# pragma mark - UITableViewDataSource

# pragma mark - UITableViewDelegate

# pragma mark - NSCopying

# pragma mark - NSObject
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
