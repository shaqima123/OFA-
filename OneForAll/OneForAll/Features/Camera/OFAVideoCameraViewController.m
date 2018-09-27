//
//  OFAVideoCameraViewController.m
//  OneForAll
//
//  Created by Kira on 2018/9/27.
//  Copyright © 2018 Kira. All rights reserved.
//

#import "OFAVideoCameraViewController.h"
#import "OFAVideoCamera.h"

@interface OFAVideoCameraViewController ()
<
OFAVideoCameraDelegate
>
{
    BOOL shouldResumeCamera;
    BOOL isRecording;
}
@property (nonatomic, strong) OFAVideoCamera *camera;
@property (nonatomic, strong) OFACameraPreviewView *preview;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *rotateBtn;

@property (nonatomic, strong) UIView *recordButton;
@property (nonatomic, strong) CAShapeLayer *circleLayer;
@property (nonatomic, strong) CAShapeLayer *recordLayer;

@property (nonatomic, strong) UIImageView *maskView;

@property (nonatomic, strong) NSURL *videoURL;


@end

@implementation OFAVideoCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.camera = [[OFAVideoCamera alloc] init];
    self.camera.delegate = self;
    [self.camera configureSession];
    self.preview.session = self.camera.session;
    [self initUI];
    [self initData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    switch (self.camera.setupResult)
    {
        case OFACameraSetupResultSuccess:
        {
            [self addObservers];
            [self.camera startCamera];
            break;
        }
        case OFACameraSetupResultNotAuthorized:
        {
            dispatch_async( dispatch_get_main_queue(), ^{
                NSString *message = NSLocalizedString( @"AVCam doesn't have permission to use the camera, please change privacy settings", nil );
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"OneForAll" message:message preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", nil ) style:UIAlertActionStyleCancel handler:nil];
                [alertController addAction:cancelAction];
                // Provide quick access to Settings.
                UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", nil ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                }];
                [alertController addAction:settingsAction];
                [self presentViewController:alertController animated:YES completion:nil];
            } );
            break;
        }
        case OFACameraSetupResultFailed:
        {
            dispatch_async( dispatch_get_main_queue(), ^{
                NSString *message = NSLocalizedString( @"Unable to capture media", nil );
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"OneForAll" message:message preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", nil ) style:UIAlertActionStyleCancel handler:nil];
                [alertController addAction:cancelAction];
                [self presentViewController:alertController animated:YES completion:nil];
            } );
            break;
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self removeObservers];
}

#pragma mark private methods
- (void)initUI {
    [self maskView];
    [self backBtn];
    [self rotateBtn];
    [self recordButton];
}

- (void)initData {
    
}

- (void)actionBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)actionRotate {
    [self.camera rotateCamera];
}

- (void)recordVideo {
    [self drawRecordButtonWithState:!isRecording];
    if (!isRecording) {
        [self.camera startRecord];
    } else {
        [self.camera endRecord];
    }
}

- (void)drawRecordButtonWithState:(BOOL)isRecording {
    if (isRecording) {
        self.recordLayer = [CAShapeLayer layer];
        UIBezierPath * bezierpath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(25.f, 25.f, 20.f, 20.f) cornerRadius:4.f];
        self.recordLayer.path = bezierpath.CGPath;
        self.recordLayer.fillColor = [UIColor redColor].CGColor;
        [self.circleLayer addSublayer:self.recordLayer];
    } else {
        [self.recordLayer removeFromSuperlayer];
        self.recordLayer = nil;
    }
}

#pragma mark get - set

- (OFACameraPreviewView *)preview {
    if (!_preview) {
        _preview = [[OFACameraPreviewView alloc] initWithFrame:CGRectZero];
        [self.view addSubview:_preview];
        [_preview mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
    return _preview;
}


- (UIButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [[UIButton alloc] init];
        [_backBtn setImage:[UIImage imageNamed:@"btn_camera_quite"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(actionBack) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_backBtn];
        [_backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(10 + Height_Top_Addtion);
            make.left.equalTo(self.view).offset(10);
            make.height.width.mas_equalTo(48.f);
        }];
    }
    return _backBtn;
}

- (UIButton *)rotateBtn {
    if (!_rotateBtn) {
        _rotateBtn = [[UIButton alloc] init];
        [_rotateBtn setImage:[UIImage imageNamed:@"btn_camera_switch"] forState:UIControlStateNormal];
        [_rotateBtn addTarget:self action:@selector(actionRotate) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_rotateBtn];
        [_rotateBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(10 + Height_Top_Addtion);
            make.right.equalTo(self.view).offset(-10);
            make.height.width.mas_equalTo(48.f);
        }];
    }
    return _rotateBtn;
}


- (UIView *)recordButton {
    if (!_recordButton) {
        _recordButton = [[UIView alloc] initWithFrame:CGRectZero];
        [_recordButton setUserInteractionEnabled:YES];
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(recordVideo)];
        [_recordButton addGestureRecognizer:tap];
        
        //给按钮增加毛玻璃效果
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
        UIVisualEffectView* effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        effectView.userInteractionEnabled = NO;
        [_recordButton addSubview:effectView];
        
        self.circleLayer = [CAShapeLayer layer];
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        CGPoint center = CGPointMake(35.f, 35.f);
        CGFloat currentRadius = 33.f;
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:currentRadius startAngle:0 endAngle:M_PI * 2 clockwise:YES];
        self.circleLayer.path = path.CGPath;
        self.circleLayer.lineWidth = 6;
        self.circleLayer.strokeColor = [UIColor whiteColor].CGColor;
        self.circleLayer.fillColor = [UIColor clearColor].CGColor;
        
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithArcCenter:center radius:currentRadius + 2 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
        maskLayer.path = maskPath.CGPath;
        
        [_recordButton.layer addSublayer:self.circleLayer];
        [_recordButton.layer setMask:maskLayer];
        [self.view addSubview:_recordButton];
        
        [_recordButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.bottom.equalTo(self.view).offset(IS_IPHONE_X ? -35 : -85);
            make.height.width.mas_equalTo(70.f);
        }];
        
        [effectView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self->_recordButton);
            make.width.height.mas_equalTo(112.f);
        }];
    }
    return _recordButton;
}

#pragma mark observers
- (void)addObservers
{
    [self.camera.session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.camera.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.camera.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:self.camera.session];
    
}

- (void)removeObservers
{
    [self.camera.session removeObserver:self forKeyPath:@"running" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"running"]) {
        BOOL isRunning = ((AVCaptureSession *)object).running;
        if (isRunning) {
            NSLog(@"Session is Running...");
        } else {
            NSLog(@"Session Stop running!");
        }
    }
}

- (void)sessionRuntimeError:(NSNotification *)notification
{
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    NSLog( @"Capture session runtime error: %@", error );
    
    if ( error.code == AVErrorMediaServicesWereReset ) {
        [self.camera startCamera];
    }
}

- (void)sessionWasInterrupted:(NSNotification *)notification
{
    AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
    NSLog( @"Capture session was interrupted with reason %ld", (long)reason );
    
    if ( reason == AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient ||
        reason == AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient ) {
        shouldResumeCamera = YES;
    }
    else if ( reason == AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps ) {
        shouldResumeCamera = YES;
    }
}

- (void)sessionInterruptionEnded:(NSNotification *)notification
{
    NSLog( @"Capture session interruption ended" );
    shouldResumeCamera = NO;
}

#pragma mark OFAVideoCameraDelegate

- (void)didStartRecordingToOutputFileAtURL:(NSURL *)fileURL {
    isRecording = YES;
}

- (void)didFinishRecordingToOutputFileAtURL:(NSURL *)fileURL {
    isRecording = NO;
    self.videoURL = fileURL;
}

@end
