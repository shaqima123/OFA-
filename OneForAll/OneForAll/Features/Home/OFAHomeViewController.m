//
//  OFAHomeViewController.m
//  OneForAll
//
//  Created by Kira on 2018/8/6.
//  Copyright © 2018 Kira. All rights reserved.
//

#import "OFAHomeViewController.h"

@interface OFAHomeViewController ()

@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation OFAHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero];
        
    }
    return _collectionView;
}
@end
