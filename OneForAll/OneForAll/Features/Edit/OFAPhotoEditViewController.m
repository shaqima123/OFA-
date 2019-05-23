//
//  OFAPhotoEditViewController.m
//  OneForAll
//
//  Created by 沙琪玛 on 2019/5/23.
//  Copyright © 2019 Kira. All rights reserved.
//

#import "OFAPhotoEditViewController.h"

@interface OFAPhotoEditViewController ()
@property (nonatomic, strong) UIButton *backBtn;

@end

@implementation OFAPhotoEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)setupUI {
    self.backBtn = ({
        UIButton *button = [[UIButton alloc] init];
        [button setImage:[UIImage imageNamed:@"btn_camera_quite"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(actionBack) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(10 + Height_Top_Addtion);
            make.left.equalTo(self.view).offset(10);
            make.height.width.mas_equalTo(48.f);
        }];
        button;
    });
}

- (void)actionBack {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
