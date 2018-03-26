//
//  line.h
//  CameraAppTemplate
//
//  Created by Temp2 on 3/21/18.
//  Copyright © 2018 ShadeApps. All rights reserved.
//

#include <stdlib.h>
#include <iostream>
#include "opencv2/opencv.hpp"
#include <dirent.h>
#include <fstream>

#ifndef line_h
#define line_h

cv::Mat getLine (cv::Mat im);
void getLineValue(cv::Mat &endPoints, int w, int h, double *line_value, double *line_info);

#endif /* line_h */
