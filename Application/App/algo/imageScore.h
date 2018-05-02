#include <stdlib.h>
#include <iostream>
#include "opencv2/opencv.hpp"
#include <dirent.h>
#include <fstream>
//#include <pthread.h>
#include "line.h" //TODO h
#include "FASA.h" //TODO h
#include "ImageUtils.h"
#import <opencv2/imgcodecs/ios.h>


#ifndef imageScore_h
#define imageScore_h

double getScore(cv::Mat& im, dispatch_group_t group, dispatch_queue_t fasaQueue, dispatch_queue_t lineQueue);

#endif /* imageScore_h */
