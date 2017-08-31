//
//  GPUImageBeautyFilter.h
//  RSBeautyCamera
//
//  Created by WhatsXie on 2017/8/31.
//  Copyright © 2017年 StevenXie. All rights reserved.
//

#import <GPUImage/GPUImage.h>

@class GPUImageCombinationFilter;

@interface GPUImageBeautyFilter : GPUImageFilterGroup {
    GPUImageBilateralFilter *bilateralFilter;
    GPUImageCannyEdgeDetectionFilter *cannyEdgeFilter;
    GPUImageCombinationFilter *combinationFilter;
    GPUImageHSBFilter *hsbFilter;
}

@end
