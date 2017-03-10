//
//  LYPhotoBrowserViewController.m
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import "LYPhotoBrowserViewController.h"
#import "LYPhotoHelper.h"
#import "LYPhotoSmallViewController.h"
#import "LYPhotoBrowserCell.h"
#import "LYPhotoPickerCategory.h"

static CGFloat const photoBrowserLineSpacing = 30.0f;

@interface LYPhotoMarkButton : UIButton

@end

@implementation LYPhotoMarkButton

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    return CGRectMake(0, 0, contentRect.size.width, contentRect.size.height);
}

@end

@interface LYPhotoBrowOrigianlButton : UIButton

@end

@implementation LYPhotoBrowOrigianlButton

static CGFloat const spaceing = 5;
static CGFloat const width = 40/2.0f;

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    CGFloat y = (contentRect.size.height - width)/2;
    return CGRectMake(0, y, width, width);
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
    CGFloat x = spaceing + 20;
    CGFloat width = contentRect.size.width;
    return CGRectMake(x, 0, width, contentRect.size.height);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

@end

@interface LYPhotoBrowserViewController ()
@property (nonatomic, strong) UICollectionView *browserCollectionView;
@property (nonatomic, assign) NSUInteger currentPage;
@property (nonatomic, weak) LYPhotoSmallViewController *smallVC;
//* --------------------------当前预览的----------------------------- */
/** 处理相册发生改变 */
@property (nonatomic, copy) NSString *imageName;

@property (nonatomic, strong) UIView *bottomContainerView;
@property (nonatomic, strong) LYPhotoBrowOrigianlButton *originalBtn;
@property (nonatomic, strong) UIButton *senderBtn;
@property (nonatomic, strong) NSIndexPath *currentIndexPath;
@property (nonatomic, strong) LYPhotoMarkButton *markBtn;


@end

@implementation LYPhotoBrowserViewController {
    BOOL statusBarHidden;
}

#pragma mark - life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setRightBarButtonItem];
    [self initSubviews];
    [self resetSendBtnTitle];
    [self registerNotification];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _currentIndexPath = [NSIndexPath indexPathForRow:_index inSection:0];
    [self reloadData];
    [self checkMarkSelectedWithIndex:self.index];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - LayoutSubviews

- (void)initSubviews {
    self.view.backgroundColor = [UIColor blackColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.extendedLayoutIncludesOpaqueBars = YES;//设置self.view不偏移，navigationBar直接盖在self.view上面
    [self.view addSubview:self.browserCollectionView];
    [self.view addSubview:self.bottomContainerView];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)setRightBarButtonItem {
    self.markBtn = [[LYPhotoMarkButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [self.markBtn setImage:[UIImage imageNamed:@"ic_non_select"] forState:UIControlStateNormal];
    [self.markBtn setImage:[UIImage imageNamed:@"ic_or_selected"] forState:UIControlStateSelected];
    [self.markBtn addTarget:self action:@selector(clickedMarkBtn:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.markBtn];
}

#pragma mark - Override

- (BOOL)prefersStatusBarHidden {
    return statusBarHidden;
}


# pragma mark - Custom Accessors

- (LYPhotoSmallViewController *)smallVC {
    if (!_smallVC) {
        for (UIViewController *viewController in self.navigationController.viewControllers) {
            if ([viewController isKindOfClass:[LYPhotoSmallViewController class]]) {
                return (LYPhotoSmallViewController *)viewController;
            }
        }
    }
    return nil;
}

- (UICollectionView *)browserCollectionView {
    if (!_browserCollectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = self.view.bounds.size;
        flowLayout.minimumLineSpacing = photoBrowserLineSpacing;
        flowLayout.minimumInteritemSpacing = 0.0f;
        flowLayout.sectionInset = UIEdgeInsetsMake(0, photoBrowserLineSpacing/2, 0, photoBrowserLineSpacing/2);
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _browserCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(-photoBrowserLineSpacing/2, 0, SCREEN_WIDTH + photoBrowserLineSpacing, SCREEN_HEIGHT) collectionViewLayout:flowLayout];
        _browserCollectionView.dataSource = (id)self;
        _browserCollectionView.delegate = (id)self;
        _browserCollectionView.showsVerticalScrollIndicator = NO;
        _browserCollectionView.showsHorizontalScrollIndicator = NO;
        _browserCollectionView.pagingEnabled = YES;
        _browserCollectionView.backgroundColor = [UIColor clearColor];
        _browserCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_browserCollectionView registerClass:[LYPhotoBrowserCell class] forCellWithReuseIdentifier:NSStringFromClass(self.class)];
        
    }
    return _browserCollectionView;
}

- (UIView *)bottomContainerView {
    if (!_bottomContainerView) {
        CGFloat y = SCREEN_HEIGHT - 40.0f;
        _bottomContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, y, SCREEN_WIDTH, 40)];
        [_bottomContainerView addSubview:self.originalBtn];
        [_bottomContainerView addSubview:self.senderBtn];
        _bottomContainerView.backgroundColor = [UIColor whiteColor];
    }
    return _bottomContainerView;
}

- (LYPhotoBrowOrigianlButton *)originalBtn {
    if (!_originalBtn) {
        _originalBtn = [[LYPhotoBrowOrigianlButton alloc] initWithFrame:CGRectMake(50, 0, SCREEN_WIDTH/2.0f - 50, self.bottomContainerView.height)];
        [_originalBtn setImage:[UIImage imageNamed:@"ic_or_non_select"] forState:UIControlStateNormal];
        [_originalBtn setImage:[UIImage imageNamed:@"ic_or_selected"] forState:UIControlStateSelected];
        [_originalBtn setTitle:@"原图" forState:UIControlStateNormal];
        _originalBtn.titleLabel.font = [UIFont systemFontOfSize:18.0f];
        [_originalBtn setTitleColor:blueColor forState:UIControlStateNormal];
        [_originalBtn addTarget:self action:@selector(clickedOriginalBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _originalBtn;
}

- (UIButton *)senderBtn {
    if (!_senderBtn) {
        _senderBtn = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 50 - 100, 0, 100, self.bottomContainerView.height)];
        [_senderBtn setTitle:@"发送" forState:UIControlStateNormal];
        _senderBtn.titleLabel.font = [UIFont systemFontOfSize:18.0f];
        [_senderBtn setTitleColor:blueColor forState:UIControlStateNormal];
        [_senderBtn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        [_senderBtn addTarget:self action:@selector(clickedSenderBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _senderBtn;
}

# pragma mark - IBActions

- (void)clickedMarkBtn:(LYPhotoMarkButton *)sender {
    LYPhotoAssetObject *assetObject = [self fetchCurrentIndexAssetObject];
    PHAssetCollection *currentSelectedAssecCollection = [[UIViewController photoPickerController] valueForKey:KVC_CurrentSelectedAssecCollection];
    if (!sender.selected) {
        BOOL success = [self.smallVC operationSelectedPhotoObjectsWithLYAssetObject:assetObject identifier:currentSelectedAssecCollection.localIdentifier remove:NO showTip:YES];
        if (!success) {
            return;
        }
    } else {
        [self.smallVC operationSelectedPhotoObjectsWithLYAssetObject:assetObject identifier:currentSelectedAssecCollection.localIdentifier remove:YES showTip:YES];
    }
    [self resetSendBtnTitle];
    //* 这里是计算的所有选择的图片的字节大小 */
    if (self.originalBtn.selected) {
        @weakify(self)
        [[LYPhotoHelper  shareInstance] fetchImageBytesInAssets:self.smallVC.selectedAssets bytes:^(NSString *bytes) {
            @strongify(self)
            if ([bytes isEqualToString:@"0B"]) {
                [self.originalBtn setTitle:[NSString stringWithFormat:@"原图"] forState:UIControlStateNormal];
            } else {
                [self.originalBtn setTitle:[NSString stringWithFormat:@"原图(%@)",bytes] forState:UIControlStateNormal];
            }
        }];
    }
    
    if (self.isPreviewModel) {
        [self setNavigationTitle];
        [self removeObjectWithLYPhotoAssetObject:assetObject];
        if (self.smallVC.selectedAlbumCount == 0) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        [self.browserCollectionView reloadData];
    } else {
        if (!sender.selected) {
            [sender.layer addAnimation:GetBtnStatusChangedAnimation() forKey:nil];
        }
        sender.selected = !sender.selected;
    }
}

/** 总开关，选择一次原图之后全是原图，如果这张图没有被选择，那么选择原图之后这张图就自动被选中，取消原图这张图不会被取消选中 */
- (void)clickedOriginalBtn:(LYPhotoBrowOrigianlButton *)sender {
    if (!sender.selected) {
        LYPhotoBrowserCell *photoBrowserCell = (LYPhotoBrowserCell *)[self.browserCollectionView cellForItemAtIndexPath:_currentIndexPath];
        LYPhotoAssetObject *assetObject = self.dataSource[_currentIndexPath.row];
        [photoBrowserCell loadOrigLYPhotoAssetObject:assetObject onICloud:[[LYPhotoHelper shareInstance] judgeAssetisInICloud:assetObject.asset] handle:^(BOOL success) {
            sender.selected = !sender.selected;
            assetObject.albumTitle = _albumTitle;
            assetObject.selectedIndexPath = _currentIndexPath;
            PHAssetCollection *currentSelectedAssecCollection = [[UIViewController photoPickerController] valueForKey:KVC_CurrentSelectedAssecCollection];
            BOOL success_ = [self.smallVC operationSelectedPhotoObjectsWithLYAssetObject:assetObject identifier:currentSelectedAssecCollection.localIdentifier remove:NO showTip:NO];
            if (success_) {
                self.markBtn.selected = YES;
                [self resetSendBtnTitle];
            }
            [[LYPhotoHelper  shareInstance] fetchImageBytesInAssets:self.smallVC.selectedAssets bytes:^(NSString *bytes) {
                [sender setTitle:[NSString stringWithFormat:@"原图(%@)",bytes] forState:UIControlStateNormal];
            }];
        }];
    } else {
        [sender setTitle:@"原图" forState:UIControlStateNormal];
        sender.selected = !sender.selected;
        [self.browserCollectionView reloadItemsAtIndexPaths:@[self.currentIndexPath]];
    }
    [sender layoutIfNeeded];
}

- (void)clickedSenderBtn:(UIButton *)sender {
    if (self.smallVC.selectedAlbumCount < 9 && !sender.selected) {//当选择的张数小于9张，并且当前这张没有选择才发送
        PHAssetCollection *currentSelectedAssecCollection = [[UIViewController photoPickerController] valueForKey:KVC_CurrentSelectedAssecCollection];
        [self.smallVC operationSelectedPhotoObjectsWithLYAssetObject:[self fetchCurrentIndexAssetObject] identifier:currentSelectedAssecCollection.localIdentifier remove:NO showTip:YES];
    }
    [self.smallVC clickedSenderWithOriginal:self.originalBtn.isSelected];
}

# pragma mark - Public

# pragma mark - Private

- (void)registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissNotification) name:@"dismissNotification" object:nil];
}

- (void)reloadData {
    if (_currentPage <= 0) {
        _currentPage = _index;
    } else {
        _currentPage--;
    }
    
    if (_currentPage >= _dataSource.count) {
        _currentPage = _dataSource.count - 1;
    }
    [self setNavigationTitle];
    
    [self.browserCollectionView layoutIfNeeded];
    
    self.browserCollectionView.contentOffset = CGPointMake(_currentPage * self.browserCollectionView.frame.size.width, self.browserCollectionView.contentOffset.y);
}

- (void)setNavigationTitle {
    if (_currentPage == self.dataSource.count && self.dataSource.count != 1) {
        _currentPage = self.dataSource.count - 1;
    }
    
    if (self.isPreviewModel) {
        _currentPage = self.smallVC.selectedAlbumCount == 1?0:_currentPage;
    }
    CGFloat navigationBarHeight = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, navigationBarHeight)];
    titleLabel.text = [NSString stringWithFormat:@"%lu/%li",_currentPage + 1,(unsigned long)self.dataSource.count];
    self.navigationItem.titleView = titleLabel;
    if (self.dataSource.count != 0) {
        LYPhotoAssetObject *assetObject = self.dataSource[_currentPage];
        self.imageName = assetObject.imageFileName;
    }
}

- (void)checkMarkSelectedWithIndex:(NSUInteger)index {
    LYPhotoAssetObject *currentAssetObject = _dataSource[index];
    self.markBtn.selected = [self.smallVC isExistsLYPhotoAssetObject:currentAssetObject];
    //    if (self.bottomContainerView.originalBtn.selected) {
    //        if (!isNull(currentAssetObject)) {
    //            [self resetOriginalBtnTitleWithAssetObject:currentAssetObject];
    //        }
    //    }
}

/** 删除dataSource中对应的LYPhotoAssetObject */
- (void)removeObjectWithLYPhotoAssetObject:(LYPhotoAssetObject *)photoAssetObject {
    for (NSUInteger index = 0; index < self.dataSource.count; index++ ) {
        LYPhotoAssetObject *object = self.dataSource[index];
        if ([object.imageFileName isEqualToString:photoAssetObject.imageFileName]) {
            [self.dataSource removeObjectAtIndex:index];
            break;
        }
    }
}

/** 获取当前indexPath的LYPhotoAssetObject对象 */
- (LYPhotoAssetObject *)fetchCurrentIndexAssetObject {
    LYPhotoAssetObject *assetObject = self.dataSource[_currentIndexPath.row];
    assetObject.albumTitle = _albumTitle;
    assetObject.selectedIndexPath = _currentIndexPath;
    return assetObject;
}

- (void)resetSendBtnTitle {
    if (self.smallVC.selectedAlbumCount != 0) {
        NSString *string = [NSString stringWithFormat:@"发送(%li)",self.smallVC.selectedAlbumCount];
        [self.senderBtn setTitle:string forState:UIControlStateNormal];
    } else {
        [self.senderBtn setTitle:@"发送" forState:UIControlStateNormal];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LYPhotoBrowserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(self.class) forIndexPath:indexPath];
    LYPhotoAssetObject *assetObject = self.dataSource[indexPath.item];
    cell.identifier = assetObject.imageFileName;
    cell.showOriginalImage = self.originalBtn.selected;
    cell.assetObject = assetObject;
    
    return cell;
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSUInteger currentIndex = scrollView.contentOffset.x/self.browserCollectionView.width;
    _currentIndexPath = [NSIndexPath indexPathForRow:currentIndex inSection:0];//此处需要重新记录currentIndexPath
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    NSUInteger currentIndex = targetContentOffset->x/self.browserCollectionView.width;
    if (currentIndex != _currentPage) {
        _currentPage = currentIndex;
        
        LYPhotoBrowserCell *cell = (LYPhotoBrowserCell *)[self.browserCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0]];
        [cell.scrollView reductionZoomScale];
        [self setNavigationTitle];
        [self checkMarkSelectedWithIndex:currentIndex];
    }
}

# pragma mark - NSNotificationCenter

- (void)dismissNotification {
    statusBarHidden = !statusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
    [self.navigationController setNavigationBarHidden:statusBarHidden animated:YES];
    
    if (statusBarHidden) {
        CGRect frame = self.bottomContainerView.frame;
        frame.origin.y += frame.size.height;
        [UIView animateWithDuration:.3 animations:^{
            self.bottomContainerView.frame = frame;
        }];
    } else {
        CGRect frame = self.bottomContainerView.frame;
        frame.origin.y -= frame.size.height;
        [UIView animateWithDuration:.3 animations:^{
            self.bottomContainerView.frame = frame;
        }];
    }
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
