//
//  OFACameraChooseViewController.m
//  OneForAll
//
//  Created by Kira on 2018/9/22.
//  Copyright © 2018 Kira. All rights reserved.
//

#import "OFACameraChooseViewController.h"
#import "OFACameraViewController.h"


@interface OFACameraChooseViewController ()<
    UITableViewDelegate,
    UITableViewDataSource
>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray * dataArray;

@end

@implementation OFACameraChooseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self initUI];
}

- (void)initData {
    self.dataArray = @[@[@"拍照"],@[@"摄像"]];
    
}

- (void)initUI {
    [self tableView];
    [self.navigationController.navigationBar setHidden:YES];
}

#pragma mark get - set

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.backgroundColor = RGBAHEX(0x000000, 1);
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.alwaysBounceVertical = YES;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kOFACameraChooseCell];
        [self.view addSubview:_tableView];
        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
    return _tableView;
}

#pragma mark TableViewDelegate && DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray * arr = [self.dataArray objectAtIndex:section];
    return arr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:kOFACameraChooseCell];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kOFACameraChooseCell];
    }
    cell.textLabel.text = self.dataArray[indexPath.section][indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            OFACameraViewController *cameraViewController = [[OFACameraViewController alloc] init];
            [self presentViewController:cameraViewController animated:NO completion:nil];
        }
    }
    if (indexPath.row == 1) {
        if (indexPath.row == 0) {
            
        }
    }
}

@end
