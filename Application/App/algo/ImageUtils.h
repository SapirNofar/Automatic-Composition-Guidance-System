//
//  ImageUtils.h
//  CameraAppTemplate
//
//  Created by Temp2 on 4/11/18.
//  Copyright © 2018 ShadeApps. All rights reserved.
//

#include <opencv2/opencv.hpp>


#ifndef ImageUtils_h
#define ImageUtils_h
//
//  ImageUtils.m
//  CameraAppTemplate
//
//  Created by Temp2 on 4/11/18.
//  Copyright © 2018 ShadeApps. All rights reserved.
//
@interface ImageUtils: NSObject


+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;

+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;

+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image;

+ (UIImage*)blurImage:(UIImage*)image;
@end



#endif /* ImageUtils_h */
