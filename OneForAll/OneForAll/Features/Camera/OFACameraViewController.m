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
}

- (void)actionBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tapToFocus:(UITapGestureRecognizer *)tap {
    CGPoint devicePoint = [self.preview.videoPreviewLayer captureDevicePointOfInterestForPoint:[tap locationInView:tap.view]];
    [self.camera focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
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
