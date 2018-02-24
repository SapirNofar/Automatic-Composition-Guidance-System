#include <stdlib.h>
#include <iostream>
#include "opencv2/opencv.hpp"
#include <dirent.h>
#include <fstream>
#include <stdio.h>
#include <math.h>
#include "lineValue.cpp"
#include "line.cpp"



using namespace std;
using namespace cv;


int main()
{    //

//    vector<int> a = vector<int>{1,2};
//    cout<<a[0]<<endl;
    Mat im = imread("/cs/usr/sapirh/Desktop/Project/test/beeg.jpg", 0);
    cout << getLine(im) << endl;
//    int rows = im.rows;
//    int cols = im.cols;
//    Mat e = Mat(2, 2, CV_32F);
//    e.at<int>(0, 0) = 800;
//    e.at<int>(0, 1) = 1;
//    e.at<int>(1, 0) = 784;
//    e.at<int>(1, 1) = 906;
//
//    double value, info;
//    getLineValue(e, cols, rows, &value, &info);
//    cout <<  value << "    " << info<< endl;

//    Mat a = (Mat_<int>(1, 2) << 1, 2);
//    cout << Mat_<int>(1, 2) << (Mat_<int>(1,1) << 1, Mat_<int>(1,1) << 2)<<endl;


//    cout << cvRound(-1.1) << endl;
//    cout << cvRound(1.5) << endl;
//    cout << cvRound(1.6) << endl;
//    Mat src = imread("/cs/usr/sapirh/Desktop/Project/test/beeg.jpg", 0);
//
//    Mat dst, cdst;
//    Canny(src, dst, 100, 200, 3);
//    cvtColor(dst, cdst, CV_GRAY2BGR);
//    vector<Vec2f> lines;
//    HoughLines(dst, lines, 0.9, CV_PI/180, 100, 0, 0 );
//    cout << lines.size() << endl;
////
//    for( size_t i = 0; i < lines.size(); i++ )
//    {
//     float rho = lines[i][0], theta = lines[i][1];
//     Point pt1, pt2;
//     double a = cos(theta), b = sin(theta);
//     double x0 = a*rho, y0 = b*rho;
//     pt1.x = cvRound(x0 + 1000*(-b));
//     pt1.y = cvRound(y0 + 1000*(a));
//     pt2.x = cvRound(x0 - 1000*(-b));
//     pt2.y = cvRound(y0 - 1000*(a));
//     line( cdst, pt1, pt2, Scalar(0,0,255), 3, CV_AA);
//    }
//////
////    imshow("source", src);
//    imshow("detected lines", cdst);
//
//    waitKey();

//cv::Mat im = cv::imread("/cs/usr/sapirh/Desktop/Project/coupe"
//                                ".composition-score-calculator-master/Composition Score Calculator/image/10_Copyrighted_Image_Reuse_Prohibited_962499.jpg",
//                            CV_LOAD_IMAGE_COLOR);

//    cv::Mat grey;
//    grey.push_back(1);
//    grey.push_back(4);
//
//    cv::Mat g;
//    g.push_back(2);
//    g.push_back(3);
//
//    cv::Mat d;
//    cv::hconcat(grey, g, d);
//    cout << d << endl;

//    cv::cvtColor(im, grey, cv::COLOR_RGB2GRAY);
//    cv::Mat m, s;
//    cv::meanStdDev(im, m, s);
//    cout << m << endl;
//    cout << s << endl;

//    cout << grey.rows << endl;
//    cout << grey.cols << endl;
//    cout << im.channels() << endl;

//    cv::Mat plains[3];


//    cv::Mat g =  cv::getGaussianKernel(5, 5);
//    cv::mulTransposed(g,g,false);
//    cout << g << endl;


    return 0;
}
