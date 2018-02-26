#include <stdlib.h>
#include <iostream>
#include "opencv2/opencv.hpp"
#include "connectedcomponents.h"

#include <dirent.h>
#include <fstream>
#include <stdio.h>
#include <math.h>
#include "lineValue.cpp"
#include "line.cpp"
#include "FASA.cpp"

#include <iostream>



using namespace std;
using namespace cv;

int main()
{

//    Mat im1 = (Mat)Mat::zeros(100, 100, CV_64F);
//    Mat im2 = (Mat)Mat::ones(100, 100, CV_64F);
//    Mat im3 = (Mat)Mat::ones(100, 100, CV_64F);
//    Mat im4 = (Mat)Mat::ones(100, 100, CV_64F);
//
//    for(int i=0; i < 100; i++)
//    {
//        im1.at<double>(48, i) = 1;
//        im1.at<double>(49, i) = 1;
//        im1.at<double>(50, i) = 1;
//        im1.at<double>(51, i) = 1;
//        im1.at<double>(52, i) = 1;
//
//        im2.at<double>(i, 48) = 0;
//        im2.at<double>(i, 49) = 0;
//        im2.at<double>(i, 50) = 0;
//        im2.at<double>(i, 51) = 0;
//        im2.at<double>(i, 52) = 0;
//
//        if(i > 0)
//        {
//            im3.at<double>(i, i) = 0;
//            im3.at<double>(i-1, i) = 0;
//            im3.at<double>(i, i-1) = 0;
//        }
//
//        im4.at<double>(i, 48) = 0;
//        im4.at<double>(i, 49) = 0;
//        im4.at<double>(i, 50) = 0;
//        im4.at<double>(i, 51) = 0;
//        im4.at<double>(i, 52) = 0;
//        im4.at<double>(i, i) = 0;
//        if(i > 0)
//        {
//            im4.at<double>(i-1, i) = 0;
//            im4.at<double>(i, i-1) = 0;
//        }
//    }
//
//    imwrite( "/cs/usr/sapirh/Desktop/Project/test/im1.jpg", im1 );
//    imwrite( "/cs/usr/sapirh/Desktop/Project/test/im2.jpg", im2 );
//    imwrite( "/cs/usr/sapirh/Desktop/Project/test/im3.jpg", im3 );
//    imwrite( "/cs/usr/sapirh/Desktop/Project/test/im4.jpg", im4 );
//
//    imshow("", im1);
//    imshow(" ", im2);
//    imshow("  ", im3);
//    imshow("   ", im4);
//    waitKey();

//    vector<int> a = vector<int>{1,2};
//    cout<<a[0]<<endl;
    Mat im = imread("/cs/engproj/compose/Project/test/beeg.jpg",
                    CV_LOAD_IMAGE_COLOR);

    cout << im << endl;
    Mat out, out2;
    cvtColor(im,out,COLOR_RGB2GRAY);
//    cvtColor(out, out2 ,COLOR_XYZ2RGB);
    imshow(" ", out);
    waitKey(0);
    cout << out << endl;
//    cvMerge(&im, &im, &im, |NULL, out);
    cout << "hhhere" << endl;

    Mat SM = getFASA(im);
    cout << "here" << endl;
//    Mat imU;
    vector<ConnectedComponent> cc;
//    im.convertTo(imU, CV_8U);
//    const uchar* prev_p = imU.ptr<uchar>(0);
//    cout << im.type() << endl;
//    std::string name = "/cs/engproj/compose/Project/test/beeg.jpg";
    imshow(" ", SM);
    waitKey(0);
    findCC(SM, cc);
//    imshow(" ", im);
//    waitKey(0);

//    Mat label;
//    int la = cv::connectedComponents(im, label, 8, CV_16U);
//
    cout << cc.size() << endl;
//
//    for(int i = 0; i < cc.size(); i++)
//    {
//        cout << cc.at(i).getBoundingBox() << endl;
//    }


//    cv::Mat label = Mat(im.size(),CV_16U);

//    int la = connectedComponents(im,label, 8,CV_16U);
//    imshow(" ", im);
//    waitKey();
//    cout << getLine(im) << endl;

//    int rows = im.rows;
//    int cols = im.cols;
//    Mat e = Mat(2, 2, CV_64F);
//    e.at<double>(0, 0) = 800;
//    e.at<double>(0, 1) = 1;
//    e.at<double>(1, 0) = 784;
//    e.at<double>(1, 1) = 906;
//    cout << e << endl;
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


