//
//  OFAHomeViewController.m
//  OneForAll
//
//  Created by Kira on 2018/8/6.
//  Copyright © 2018 Kira. All rights reserved.
//

#import "OFAHomeViewController.h"
#import "OFAHomeCell.h"
#import "OFACameraViewController.h"

@interface OFAHomeViewController ()<
UICollectionViewDelegate,
UICollectionViewDataSource
>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray * dataArray;

@end

@implementation OFAHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self initUI];
}

- (void)initData {
    self.dataArray = @[@"相机",@"实验室"];
    
}

- (void)initUI {
    [self collectionView];
    [self.navigationController.navigationBar setHidden:YES];
}

#pragma mark get - set
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        [layout setScrollDirection:UICollectionViewScrollDirectionVertical];
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = RGBAHEX(0x000000, 0.3);
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.alwaysBounceVertical = YES;
        
        [_collectionView registerNib:[UINib nibWithNibName:@"OFAHomeCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"OFAHomeCell"];
        [self.view addSubview:_collectionView];
        [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
    return _collectionView;
}


#pragma mark ColletionViewDelegate

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.dataArray count];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(OFAHomeCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"OFAHomeCell";
    OFAHomeCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    if (indexPath.row == 0) {
        cell.iconImage.image = [UIImage imageNamed:@"btn_home_camera"];
        cell.bgImageView.image = [UIImage imageNamed:@"img_home_camera"];
    }
    if (indexPath.row == 1) {
        cell.iconImage.image = [UIImage imageNamed:@"btn_home_lab"];
        cell.bgImageView.image = [UIImage imageNamed:@"img_home_lab"];
    }
    
    cell.funcName.text = (NSString *)[self.dataArray objectAtIndex:indexPath.row];
    cell.backgroundColor = [UIColor randomColor];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(345, 207);
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(20, 20, 20, 20);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        OFACameraViewController *cameraViewController = [[OFACameraViewController alloc] init];
        [self presentViewController:cameraViewController animated:NO completion:nil];
//        [self.navigationController pushViewController:cameraViewController animated:YES];
    }
}

@end
