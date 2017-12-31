#include <stdlib.h>
#include <iostream>
#include "opencv2/opencv.hpp"
#include <dirent.h>
#include <fstream>

#include "line.cpp" //TODO h

using namespace cv;
using namespace std;


#define threshold 0.35
#define num 0
#define num_good 0
#define num_bad 0

#define areaBound_small 0.33
#define areaBound_large 0.69

#define sigma_size 0.33
#define sigma_vb 0.2
#define sigma_point 0.17

#define m_EnSize 0
#define m_EnROT 0
#define m_EnVB 0
#define m_EnDiag 0
#define m_sumEn 0

#define m_wtSize 0.2
#define m_wtROT 1
#define m_wtVB 0.3
#define m_wtDiag 1
#define m_bDiag 0

#define m_wtROTPt 0.4
#define m_wtROTLn 0.6

double getScore(Mat im)
{
    int height = im.rows;
    int width = im.cols;
    int colorsNum = im.channels();

    if(colorsNum == 1)
    {
        auto channels = std::vector<cv::Mat>{im, im, im};
        cv::merge(channels, im);
    }

    int areaImage = height * width;
    double balanceCenterX = 0.5 * width;
    double balanceCenterY = 0.5 * height;

    Mat endPoints = getLine(im);





    return 0;
}
