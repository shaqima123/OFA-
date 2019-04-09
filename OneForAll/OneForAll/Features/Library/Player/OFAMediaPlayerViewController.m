//
//  OFAMediaPlayerViewController.m
//  OneForAll
//
//  Created by Kira on 2019/4/9.
//  Copyright © 2019 Kira. All rights reserved.
//

#import "OFAMediaPlayerViewController.h"
#import "OFAMediaDecoder.h"

@interface OFAMediaPlayerViewController ()

@end

@implementation OFAMediaPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    OFAMediaDecoder *decoder = [[OFAMediaDecoder alloc] init];
    NSString *mp4Path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    
    decoder.errorBlock = ^(NSError * _Nonnull error) {
        NSLog(@"error occurs: %@",error.description);
    };
    NSLog(@"start decode");
    [decoder openFile:[NSURL URLWithString:mp4Path] parameter:nil];
    [decoder decodeFrame:10];
}
@end
