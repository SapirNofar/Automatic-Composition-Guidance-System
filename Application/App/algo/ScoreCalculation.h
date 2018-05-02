#include "opencv2/opencv.hpp"
#include "imageScore.h"


#ifndef ScoreCalculation_h
#define ScoreCalculation_h


int getImageScore(cv::Mat& im, dispatch_group_t group, dispatch_queue_t fasaQueue, dispatch_queue_t lineQueue);

#endif /* ScoreCalculation_hpp */
