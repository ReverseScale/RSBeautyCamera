//
//  ViewController.m
//  RSBeautyCamera
//
//  Created by WhatsXie on 2017/8/31.
//  Copyright © 2017年 StevenXie. All rights reserved.
//

#import "ViewController.h"
#import "GPUImageBeautyFilter.h"

#import <GPUImage.h>
#import <Masonry.h>

@interface ViewController ()
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, strong) UIButton *beautifyButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupVideoFilterView];
    [self setupSwitchButton];
}

- (void)setupVideoFilterView {
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    
    self.filterView = [[GPUImageView alloc] initWithFrame:self.view.frame];
    self.filterView.center = self.view.center;
    [self.view addSubview:self.filterView];
    
    [self.videoCamera addTarget:self.filterView];
    [self.videoCamera startCameraCapture];
}

- (void)setupSwitchButton {
    self.beautifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.beautifyButton.backgroundColor = [UIColor whiteColor];
    [self.beautifyButton setTitle:@"开启" forState:UIControlStateNormal];
    [self.beautifyButton setTitle:@"关闭" forState:UIControlStateSelected];
    [self.beautifyButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.beautifyButton addTarget:self action:@selector(beautify) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.beautifyButton];
    [self.beautifyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-20);
        make.width.equalTo(@100);
        make.height.equalTo(@40);
        make.centerX.equalTo(self.view);
    }];
}

- (void)beautify {
    if (self.beautifyButton.selected) {
        self.beautifyButton.selected = NO;
        [self.videoCamera removeAllTargets];
        
        [self.videoCamera addTarget:self.filterView];
    } else {
        self.beautifyButton.selected = YES;
        [self.videoCamera removeAllTargets];
        
        GPUImageBeautyFilter *beautifyFilter = [[GPUImageBeautyFilter alloc] init];
        [self.videoCamera addTarget:beautifyFilter];
        [beautifyFilter addTarget:self.filterView];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
