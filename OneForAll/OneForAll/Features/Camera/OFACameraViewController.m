//
//  OFACameraViewController.m
//  OneForAll
//
//  Created by Kira on 2018/8/11.
//  Copyright © 2018 Kira. All rights reserved.
//

#import "OFACameraViewController.h"
#import "OFAStillCamera.h"
#import <GLKit/GLKView.h>
#import <OpenGLES/ES2/gl.h>

//View
#import "OFAPhotoMiniView.h"

@interface OFACameraViewController ()<
OFAStillCameraDelegate,
OFAPhotoMiniViewDelegate
>
{
    BOOL shouldResumeCamera;
}
@property (nonatomic, strong) OFAStillCamera *camera;

@property (nonatomic, strong) CIContext *ciContext;
@property (nonatomic, strong) EAGLContext *glContext;
@property (nonatomic, strong) GLKView *glView;

@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *rotateBtn;

@property (nonatomic, strong) UIView *captureButton;
@property (nonatomic, strong) OFAPhotoMiniView *miniView;

@property (strong, nonatomic)  CAShapeLayer *focuslayer1;
@property (strong, nonatomic)  CAShapeLayer *focuslayer2;

@end

@implementation OFACameraViewController

#pragma mark Life Circle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.camera = [[OFAStillCamera alloc] init];
    self.camera.delegate = self;
    [self.camera configureSession];
    self.glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.ciContext = [CIContext contextWithEAGLContext:self.glContext];
    
    self.glView = [[GLKView alloc] initWithFrame:self.view.bounds context:self.glContext];
    self.glView.bounds = CGRectMake(0,0,self.view.frame.size.width, self.view.frame.size.height);
    self.glView.layer.position = CGPointMake(self.view.frame.size.width * 0.5, self.view.frame.size.height * 0.5);
//    self.glView.layer.affineTransform = CGAffineTransformMakeRotation(M_PI * 0.5);
    
    [self.view addSubview:self.glView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    [tap addTarget:self action:@selector(tapToFocus:)];
    [self.view addGestureRecognizer:tap];
    
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
    [self rotateBtn];
    [self captureButton];
}

- (void)actionBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)actionRotate {
    [self.camera rotateCamera];
}

- (void)tapToFocus:(UITapGestureRecognizer *)tap {
    CGPoint touchPoint = [tap locationInView:tap.view];
    switch (self.camera.currentDevicePosition) {
        case AVCaptureDevicePositionUnspecified:
            break;
        case AVCaptureDevicePositionBack:
        {
            touchPoint = CGPointMake( touchPoint.y / self.view.bounds.size.height ,1-touchPoint.x/self.view.bounds.size.width);
        }
            break;
        case AVCaptureDevicePositionFront:
        {
            touchPoint = CGPointMake(touchPoint.y / self.view.bounds.size.height ,touchPoint.x/self.view.bounds.size.width);
        }
            break;
        default:
            break;
    }
    [self.camera focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:touchPoint monitorSubjectAreaChange:YES];
    [self layerAnimationWithPoint:[tap locationInView:tap.view]];
    UIImpactFeedbackGenerator *impactFeedBack = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [impactFeedBack prepare];
    [impactFeedBack impactOccurred];
}

- (void)capturePhoto {
    [self.camera capturePhoto];
}

- (void)layerAnimationWithPoint:(CGPoint)point {
    if (_focuslayer1) {
        [_focuslayer1 removeFromSuperlayer];
        _focuslayer1 = nil;
    }
    if (_focuslayer2) {
        [_focuslayer2 removeFromSuperlayer];
        _focuslayer2 = nil;
    }
    _focuslayer1 = [CAShapeLayer layer];
    _focuslayer2 = [CAShapeLayer layer];
    
    _focuslayer1.position = point;
    CGFloat width = 40.f;
    _focuslayer1.bounds = CGRectMake(point.x - width/2, point.y - width/2, width, width);
    UIBezierPath *path1 = [UIBezierPath bezierPathWithArcCenter:point radius:width/2 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    _focuslayer1.path = path1.CGPath;
    _focuslayer1.lineWidth = 2;
    _focuslayer1.strokeColor = [UIColor colorWithWhite:1 alpha:0.3].CGColor;
    _focuslayer1.fillColor = [UIColor clearColor].CGColor;
    [self.view.layer addSublayer:_focuslayer1];
    
    _focuslayer2.position = point;
    CGFloat width2 = 14.f;
    _focuslayer2.bounds = CGRectMake(point.x - width/2, point.y - width/2, width, width);
    UIBezierPath *path2 = [UIBezierPath bezierPathWithArcCenter:point radius:width2/2 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    _focuslayer2.path = path2.CGPath;
    _focuslayer2.lineWidth = 2;
    _focuslayer2.strokeColor = [UIColor whiteColor].CGColor;
    _focuslayer2.fillColor = [UIColor clearColor].CGColor;
    [self.view.layer addSublayer:_focuslayer2];
    
    CABasicAnimation *anim = [CABasicAnimation animation];
    anim.keyPath = @"opacity";
    anim.toValue = @(0);
    anim.autoreverses = YES;
    anim.repeatCount = 2;
    anim.removedOnCompletion = NO;
    anim.fillMode = kCAFillModeForwards;
    anim.delegate = self;
    
    CASpringAnimation* anim2 = [CASpringAnimation animationWithKeyPath:@"transform"];
    NSMutableArray *values = [NSMutableArray array];
    anim2.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.5f, 1.5f, 1.0f)];
    anim2.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0f, 1.0f, 1.0f)];
    anim2.mass = 1;
    anim2.stiffness = 100;
    anim2.damping = 10;
    anim2.initialVelocity = 10;
    anim2.duration = anim2.settlingDuration;
    anim2.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    [_focuslayer2 addAnimation:anim forKey:nil];
    [_focuslayer1 addAnimation:anim2 forKey:nil];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (flag) {
        [self resetFocusLayerIfNeeded];
    }
}

- (void)resetFocusLayerIfNeeded {
    if (_focuslayer1) {
        [_focuslayer1 removeFromSuperlayer];
        _focuslayer1 = nil;
    }
    if (_focuslayer2) {
        [_focuslayer2 removeFromSuperlayer];
        _focuslayer2 = nil;
    }
}


#pragma mark get - set

- (OFAPhotoMiniView *)miniView {
    if (!_miniView) {
        _miniView = [[OFAPhotoMiniView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 70, SCREEN_HEIGHT - 300, 60, 105)];
        _miniView.delegate = self;
        [self.view addSubview:_miniView];
    }
    return _miniView;
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

#pragma mark OFAStillCameraDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CIImage *result = [CIImage imageWithCVPixelBuffer:imageBuffer];
        
        CIFilter * hudAdjust  = [CIFilter filterWithName:@"CIHueAdjust"];
        [hudAdjust setDefaults];
        [hudAdjust setValue:result forKey:@"inputImage"];
        [hudAdjust setValue:[NSNumber numberWithFloat:8.094] forKey: @"inputAngle"];
        result = hudAdjust.outputImage;

        CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(result.extent.size, CGRectMake(0, 0, self.glView.drawableWidth, self.glView.drawableHeight));
        
        if (self.glContext != EAGLContext.currentContext) {
            glFlush();
            [EAGLContext setCurrentContext:self.glContext];
        }
        
        [self.glView bindDrawable];
        glClearColor(0, 0, 0, 1);
        
        glEnable(0x0BE2);
        glBlendFunc(1, 0x0303);
        [self.ciContext drawImage:result inRect:cropRect fromRect:result.extent];
        [self.glView display];
    }
}

- (void)captureDidFinishProcessingPhotoAsJPEGImage:(nullable UIImage *)photo error:(nullable NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^(){
        [self.miniView updatePhoto:photo];
    });
}

- (void)captureAnimation {
    dispatch_async( dispatch_get_main_queue(), ^{
        self.view.layer.opacity = 0.0;
        [UIView animateWithDuration:0.2 animations:^{
            self.view.layer.opacity = 1.0;
        }];
    } );
}

#pragma mark OFAPhotoMiniViewDelegate

- (void)miniViewPanEnded {
    [UIView animateWithDuration:0.3 animations:^{
        [self.miniView setCenter:CGPointMake(SCREEN_WIDTH + self.miniView.bounds.size.width/2, self.miniView.center.y)];
    } completion:^(BOOL finished) {
        [self.miniView removeFromSuperview];
        self.miniView = nil;
    }];
}

- (void)miniViewTapped {
    NSLog(@"MiniView Tapped");
}

@end
