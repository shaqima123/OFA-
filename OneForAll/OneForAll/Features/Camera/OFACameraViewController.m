//
//  OFACameraViewController.m
//  OneForAll
//
//  Created by Kira on 2018/8/11.
//  Copyright © 2018 Kira. All rights reserved.
//

#import "OFACameraViewController.h"
#import "OFAStillCamera.h"
#import "OFACameraPreviewView.h"

@interface OFACameraViewController ()
{
    BOOL shouldResumeCamera;
}
@property (nonatomic, strong) OFAStillCamera *camera;
@property (nonatomic, strong) OFACameraPreviewView *preview;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIView *captureButton;

@end

@implementation OFACameraViewController

#pragma mark Life Circle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.camera = [[OFAStillCamera alloc] init];
    [self.camera configureSession];
    //configure内部异步初始化session，这里马上setpreview的session会不会有问题
    self.preview.session = self.camera.session;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    [tap addTarget:self action:@selector(tapToFocus:)];
    [self.preview addGestureRecognizer:tap];
    
    [self initUI];
    
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
    [self backBtn];
    [self captureButton];
}

- (void)actionBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tapToFocus:(UITapGestureRecognizer *)tap {
    CGPoint devicePoint = [self.preview.videoPreviewLayer captureDevicePointOfInterestForPoint:[tap locationInView:tap.view]];
    [self.camera focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

- (void)capturePhoto {
    [self.camera capturePhoto];
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
        [_backBtn setBackgroundColor:[UIColor redColor]];
        [_backBtn addTarget:self action:@selector(actionBack) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_backBtn];
        [_backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(10 + Height_Top_Addtion);
            make.left.equalTo(self.view).offset(10);
            make.height.width.mas_equalTo(48.f);
        }];
    }
    return  _backBtn;
}

- (UIView *)captureButton {
    if (!_captureButton) {
        _captureButton = [[UIView alloc] initWithFrame:CGRectZero];
        [_captureButton setUserInteractionEnabled:YES];
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(capturePhoto)];
        [_captureButton addGestureRecognizer:tap];
    
//        UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(actionPanInCaptureButton:)];
//        pan.delegate = self;
//        [_captureButton addGestureRecognizer:pan];
        
        //给按钮增加毛玻璃效果
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
        UIVisualEffectView* effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        effectView.userInteractionEnabled = NO;
        [_captureButton addSubview:effectView];
        
        CAShapeLayer *circleLayer = [CAShapeLayer layer];
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        CGPoint center = CGPointMake(35.f, 35.f);
        CGFloat currentRadius = 33.f;
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:currentRadius startAngle:0 endAngle:M_PI * 2 clockwise:YES];
        circleLayer.path = path.CGPath;
        circleLayer.lineWidth = 6;
        circleLayer.strokeColor = [UIColor whiteColor].CGColor;
        circleLayer.fillColor = [UIColor clearColor].CGColor;
        
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithArcCenter:center radius:currentRadius + 2 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
        maskLayer.path = maskPath.CGPath;
        
        [_captureButton.layer addSublayer:circleLayer];
        [_captureButton.layer setMask:maskLayer];
        [self.view addSubview:_captureButton];
        
        [_captureButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.bottom.equalTo(self.view).offset(IS_IPHONE_X ? -35 : -85);
            make.height.width.mas_equalTo(70.f);
        }];
        
        [effectView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self->_captureButton);
            make.width.height.mas_equalTo(112.f);
        }];
        
        //        [_captureButton bringSubviewToFront:_captureButton.imageView];
    }
    return _captureButton;
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

@end
