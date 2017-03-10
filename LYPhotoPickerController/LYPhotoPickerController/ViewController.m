//
//  ViewController.m
//  LYPhotoPickerController
//
//  Created by LaiYoung_ on 2017/3/10.
//  Copyright © 2017年 LaiYoung_. All rights reserved.
//

#import "ViewController.h"
#import "LYPhotoPickerController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)showPhotoPickerController:(UIButton *)sender {
    void(^senderBlock)(NSArray <LYPhotoObject *>* objects) = ^ (NSArray <LYPhotoObject *>* objects) {
        
    };
    LYPhotoPickerController *photoPicker = [[LYPhotoPickerController alloc] init];
    photoPicker.maxCount = 9;
    photoPicker.senderBlock = senderBlock;
    photoPicker.saveSelected = NO;
    photoPicker.lineCount = 3;
    photoPicker.spacing = 3.0f;
    [self presentViewController:photoPicker animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
