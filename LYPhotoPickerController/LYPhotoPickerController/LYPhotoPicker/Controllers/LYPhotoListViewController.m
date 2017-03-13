//
//  LYPhotoListViewController.m
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import "LYPhotoListViewController.h"
#import "LYPhotoListCell.h"
#import "LYPhotoHelper.h"
#import "LYPhotoSmallViewController.h"
#import "LYPhotoPickerCategory.h"

@interface LYPhotoListViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *photoList;
@end

@implementation LYPhotoListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initSubviews];
    [self registerNotification];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.photoList = [[LYPhotoHelper shareInstance] fetchAllPhotoListWithCollectionType:[UIViewController photoPickerController].collectionType];
    [self.tableView reloadData];
    //* 解决TableViewCell左侧会有默认15像素的空白 */
    if ([_tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [_tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if (![UIViewController photoPickerController].saveSelected) {
        [[[LYPhotoSmallViewController alloc] init] removeAllObjects];
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
    self.title = @"相册";
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(clickedCancelItem:)];
    self.navigationItem.rightBarButtonItem = cancelItem;
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
}

# pragma mark - Custom Accessors

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.dataSource = (id)self;
        _tableView.delegate = (id)self;
        _tableView.tableFooterView = [[UIView alloc] init];
        [_tableView registerClass:[LYPhotoListCell class] forCellReuseIdentifier:NSStringFromClass(self.class)];
        /** iPad 适配 */
        if ([_tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
            _tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
    }
    return _tableView;
}

# pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.photoList.count;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(LYPhotoListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([UIViewController photoPickerController].saveSelected && [UIViewController photoPickerController].markType != LYPhotoListSelectMarkTypeNon) {
        LYPhotoListObject *listObject = self.photoList[indexPath.row];
        if ([UIViewController photoPickerController].markType == LYPhotoListSelectMarkTypeNumber) {
            if ([UIViewController photoPickerController].markType == LYPhotoListSelectMarkTypeNumber) {
                cell.count = [self selectedItemCountWithKey:listObject.photoTitle];
            }
        } else if ([UIViewController photoPickerController].markType == LYPhotoListSelectMarkTypeRedDot) {
            cell.showRedDot = [self.containsPhotoListNames containsObject:listObject.photoTitle];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LYPhotoListCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(self.class) forIndexPath:indexPath];
    LYPhotoListObject *listObject = self.photoList[indexPath.row];
    
    cell.listObject = listObject;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

# pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    LYPhotoSmallViewController *smallVC = [[LYPhotoSmallViewController alloc] init];
    LYPhotoListObject *listObject = self.photoList[indexPath.row];
    smallVC.smallTitle = listObject.photoTitle;
    [MBProgressHUD showLargeHUD:@"正在加载..."];
    @weakify(self)
    [LYGCDQueue executeInGlobalQueue:^{
        smallVC.fetchLYSmallAsset = [[LYPhotoHelper shareInstance] fetchLYPhotoAssetObjectInAssetCollection:listObject.assetCollection ascending:YES];
        [[UIViewController photoPickerController] setValue:listObject.assetCollection forKey:KVC_CurrentSelectedAssecCollection];
        dispatch_async_on_main_queue(^{
            [MBProgressHUD dismissHUD];
            void(^selectedAlbumTitlesAndNumberBlock)(NSDictionary <NSString *, NSNumber *> *albumTitlesAndNumberDict) = ^(NSDictionary <NSString *, NSNumber *> *albumTitlesAndNumberDict) {
                @strongify(self)
                self.selectedAlbumTitlesAndNumberDict = albumTitlesAndNumberDict;
            };
            void(^containsPhotoListNamesBlock)(NSSet <NSString *> *containsPhotoListNames) = ^ (NSSet <NSString *> *containsPhotoListNames) {
                @strongify(self)
                self.containsPhotoListNames = containsPhotoListNames;
            };
            @strongify(self)
            smallVC.selectedAlbumTitlesAndNumberBlock = selectedAlbumTitlesAndNumberBlock;
            smallVC.containsPhotoListNamesBlock = containsPhotoListNamesBlock;
            [self.navigationController pushViewController:smallVC animated:YES];
        });
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

# pragma mark - IBActions

- (void)clickedCancelItem:(UIBarButtonItem *)sender {
    [[[LYPhotoSmallViewController alloc] init] removeAllObjects];
    [self dismissViewControllerAnimated:YES completion:^{
        [[LYPhotoHelper shareInstance] didReceiveMemoryWarning];
    }];
}

# pragma mark - Public

# pragma mark - Private

/** 根据key，获取选中的个数 */
- (NSInteger)selectedItemCountWithKey:(NSString *)key {
    return self.selectedAlbumTitlesAndNumberDict[key].integerValue;
}

- (void)registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoListChangeNotification:) name:kPhotoListChangeNotification object:nil];
}

#pragma mark - Notification

- (void)photoListChangeNotification:(NSNotification *)noti {
    if (![[UIViewController currentViewController] isKindOfClass:[self class]]) return;
    self.photoList = [[LYPhotoHelper shareInstance] fetchAllPhotoListWithCollectionType:[UIViewController photoPickerController].collectionType];
    if (self.photoList.count == 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"无相册列表可选择" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self dismissViewControllerAnimated:YES completion:NULL];
        }];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:NULL];
    } else {
        [self.tableView reloadData];
    }
}


# pragma mark - Protocol conformance

# pragma mark - UITextFieldDelegate

# pragma mark - UITableViewDataSource

# pragma mark - UITableViewDelegate

# pragma mark - NSCopying

# pragma mark - NSObject


@end
