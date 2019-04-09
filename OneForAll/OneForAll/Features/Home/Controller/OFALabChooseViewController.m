//
//  OFALabChooseViewController.m
//  OneForAll
//
//  Created by Kira on 2018/9/22.
//  Copyright © 2018 Kira. All rights reserved.
//

#import "OFALabChooseViewController.h"
#import "OFALabPickStarViewController.h"
#import "OFAMediaPlayerViewController.h"

@interface OFALabChooseViewController ()<
UITableViewDelegate,
UITableViewDataSource
>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray * dataArray;
@property (nonatomic, strong) NSArray * imageArray;

@end

@implementation OFALabChooseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self initUI];
}

- (void)initData {
    self.dataArray = @[@[@"摘下星星给你"],@[@"FFmpeg实践"]];
    self.imageArray = @[@[@"btn_home_camera"],@[@"btn_home_video"]];
}

- (void)initUI {
    [self tableView];
    [self.navigationController.navigationBar setHidden:YES];
}

#pragma mark get - set

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.backgroundColor = [UIColor DARK];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88.f;
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
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [UIColor GRAY08];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    [cell.textLabel setFont:[UIFont boldSystemFontOfSize:30]];
    cell.textLabel.text = self.dataArray[indexPath.section][indexPath.row];
    NSString * imageName = (NSString *)self.imageArray[indexPath.section][indexPath.row];
    [cell.imageView setBounds:CGRectMake(0, 0, 44, 44)];
    cell.imageView.image = [UIImage imageNamed:imageName];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            OFALabPickStarViewController *pickStarViewController = [[OFALabPickStarViewController alloc] init];
            [self presentViewController:pickStarViewController animated:YES completion:nil];
        }
    }
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            OFAMediaPlayerViewController *playerViewController = [[OFAMediaPlayerViewController alloc] init];
            [self presentViewController:playerViewController animated:YES completion:nil];
        }
    }
}



@end
