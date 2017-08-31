# RSBeautyCamera
基于 GPUImage 的美颜功能

![](https://img.shields.io/badge/platform-iOS-red.svg) 
![](https://img.shields.io/badge/language-Objective--C-orange.svg) 
![](https://img.shields.io/badge/download-7MB-brightgreen.svg)
![](https://img.shields.io/badge/license-MIT%20License-brightgreen.svg) 

GPUImage 是一个开源的基于GPU的图片或视频的处理框架，其本身内置了多达120多种常见的滤镜效果。


## Advantage 框架的优势
* 1.文件少，代码简洁
* 2.基于<GPUImage>开发
* 3.具备较高自定义性


## Requirements 要求
* iOS 7+
* Xcode 8+


## Usage 使用方法
### 第一步 引入头文件
```
#import "GPUImageBeautyFilter.h"
#import <GPUImage.h>
```
### 第二步 属性声明
```
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *filterView;
```
### 第三步 创建布局
```
self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    
self.filterView = [[GPUImageView alloc] initWithFrame:self.view.frame];
self.filterView.center = self.view.center;
[self.view addSubview:self.filterView];
    
[self.videoCamera addTarget:self.filterView];
[self.videoCamera startCameraCapture];
```

### 第四步 施放遮罩
```
// 先移除所有遮罩
[self.videoCamera removeAllTargets];
        
GPUImageBeautyFilter *beautifyFilter = [[GPUImageBeautyFilter alloc] init];
[self.videoCamera addTarget:beautifyFilter];
[beautifyFilter addTarget:self.filterView];
```

## Introduce 介绍
### 磨皮

磨皮的本质实际上是模糊。而在图像处理领域，模糊就是将像素点的取值与周边的像素点取值相关联。而我们常见的高斯模糊 ，它的像素点取值则是由周边像素点求加权平均所得，而权重系数则是像素间的距离的高斯函数，大致关系是距离越小、权重系数越大。下图3.1是高斯模糊效果的示例:

![](http://og1yl0w9z.bkt.clouddn.com/17-8-31/11226513.jpg)

如果单单使用高斯模糊来磨皮，得到的效果是不尽人意的。原因在于，高斯模糊只考虑了像素间的距离关系，没有考虑到像素值本身之间的差异。举个例子来讲，头发与人脸分界处（颜色差异很大，黑色与人皮肤的颜色），如果采用高斯模糊则这个边缘也会模糊掉，这显然不是我们希望看到的。而双边滤波(Bilateral Filter) 则考虑到了颜色的差异，它的像素点取值也是周边像素点的加权平均，而且权重也是高斯函数。不同的是，这个权重不仅与像素间距离有关，还与像素值本身的差异有关，具体讲是，像素值差异越小，权重越大，也是这个特性让它具有了保持边缘的特性，因此它是一个很好的磨皮工具。下图3.2是双边滤波的效果示例：

![](http://og1yl0w9z.bkt.clouddn.com/17-8-31/34014238.jpg)

对比3.1和3.2，双边滤波效果确实在人脸细节部分保留得更好，因此我采用了双边滤波作为磨皮的基础算法。双边滤波在GPUImage中也有实现，是GPUImageBilateralFilter。

根据图3.2，可以看到图中仍有部分人脸的细节保护得不够，还有我们并不希望将人的头发也模糊掉（我们只需要对皮肤进行处理）。由此延伸出来的改进思路是结合双边滤波，边缘检测以及肤色检测。整体逻辑如下：

![](http://og1yl0w9z.bkt.clouddn.com/17-8-31/42425075.jpg)

Combination  Filter是我们自己定义的三输入的滤波器。三个输入分别是原图像A(x, y),双边滤波后的图像B(x, y），边缘图像C(x, y)。其中A,B,C可以看成是图像矩阵，(x,y)可以看成其中某一像素的坐标。Combination  Filter的处理逻辑如下图：

![](http://og1yl0w9z.bkt.clouddn.com/17-8-31/45186284.jpg)

主要功能实现代码：
```
NSString *const kGPUImageBeautifyFragmentShaderString = SHADER_STRING (
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 varying highp vec2 textureCoordinate3;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform sampler2D inputImageTexture3;
 uniform mediump float smoothDegree;
 
 void main() {
     highp vec4 bilateral = texture2D(inputImageTexture, textureCoordinate);
     highp vec4 canny = texture2D(inputImageTexture2, textureCoordinate2);
     highp vec4 origin = texture2D(inputImageTexture3,textureCoordinate3);
     highp vec4 smooth;
     lowp float r = origin.r;
     lowp float g = origin.g;
     lowp float b = origin.b;
     if (canny.r < 0.2 && r > 0.3725 && g > 0.1568 && b > 0.0784 && r > b && (max(max(r, g), b) - min(min(r, g), b)) > 0.0588 && abs(r-g) > 0.0588) {
         smooth = (1.0 - smoothDegree) * (origin - bilateral) + bilateral;
     } else {
         smooth = origin;
     }
     smooth.r = log(1.0 + 0.2 * smooth.r)/log(1.2);
     smooth.g = log(1.0 + 0.2 * smooth.g)/log(1.2);
     smooth.b = log(1.0 + 0.2 * smooth.b)/log(1.2);
     gl_FragColor = smooth;
 });

```

Combination Filter通过肤色检测和边缘检测，只对皮肤和非边缘部分进行处理。下面是采用这种方式进行磨皮之后的效果图:

![](http://og1yl0w9z.bkt.clouddn.com/17-8-31/47538010.jpg)
对比3.5与3.2，可以看到3.5对人脸细节的保护更好，同时对于面部磨皮效果也很好，给人感觉更加真实。

### 延伸

我所采用的磨皮算法是基于双边滤波的，主要是考虑到它同时结合了像素间空间距离以及像素值本身的差异。当然也不一定要采用双边滤波，也有通过改进高斯模糊（结合像素值差异）来实现磨皮的，甚至能取得更好的效果。另外GPUImageBeautifyFilter不仅仅具有磨皮功能，也实现了log曲线调色，亮度、饱和度的调整。

使用简单、效率高效、进程安全~~~如果你有更好的建议,希望不吝赐教!


## License 许可证
RSBeautyCamera 使用 MIT 许可证，详情见 LICENSE 文件。


## Contact 联系方式:
* WeChat : WhatsXie
* Email : ReverseScale@iCloud.com
* Blog : https://reversescale.github.io
