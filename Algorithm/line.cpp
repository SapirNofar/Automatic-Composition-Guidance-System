#include <stdlib.h>
#include <iostream>
#include "opencv2/opencv.hpp"
#include <dirent.h>
#include <fstream>

using namespace cv;
using namespace std;


template<typename T>
bool inline find(T key, cv::Mat M)
{
    int pos = 0;
    std::vector<T> result;
    if(M.dims > 0) {
        std::for_each(M.begin<T>(), M.end<T>(), [&](T &m) {
            if (m == key) {
                result.push_back(key);
            }
            pos++;
        });
    }
    return result.size() == 0;
}


cv::Vec2f twoPoints2Polar(const cv::Vec4i& line)
{
    // Get points from the vector
    cv::Point2f p1(line[0], line[1]);
    cv::Point2f p2(line[2], line[3]);

    // Compute 'rho' and 'theta'
    float rho = abs(p2.x*p1.y - p2.y*p1.x) / cv::norm(p2 - p1);
    float theta = -atan2((p2.x - p1.x) , (p2.y - p1.y));

    // You can have a negative distance from the center
    // when the angle is negative
    if (theta < 0) {
        rho = -rho;
    }

    return cv::Vec2f(rho, theta);
}

Mat getLine (Mat im)
{
    int height = im.rows;
    int width = im.cols;
    Mat filterdImage, greyImage, cannyImage, lineImage;
    cv::Mat kernel =  cv::getGaussianKernel(5, 5);
    cv::mulTransposed(kernel, kernel, false);
    filter2D(im, filterdImage, -1, kernel);
    cvtColor(filterdImage, greyImage, COLOR_RGB2GRAY);

    Mat dst, cdst, cdstP;
    GaussianBlur(greyImage, cannyImage, Size(15,15), 2);
    Canny(cannyImage, dst, 50, 127);
//    imshow("canny", dst);
    cvtColor(dst, cdst, CV_GRAY2BGR);
    cdstP = cdst.clone(); //TODO

//    std::vector<Vec2f> lines;
//    HoughLines(dst, lines, 1, CV_PI/180.0, 100);
//    cout << lines.size() << endl;

//    vector<vector<Point>> pLines;
//    int threshold = 100;
//    double maxLen = 0;
//    double len;
    Mat rho, theta;
//    for( size_t i = 0; i < lines.size(); i++ )
//    {
//
//        float r = lines[i][0], t = lines[i][1];
//        if(r < 0)
//        {
//            r *= -1;
//            t += CV_PI;
//        }
//        if(find(t, theta))
//        {
//            rho.push_back(r);
//            theta.push_back(t);
////            cout << r << "\t" << t << endl;
//        }
//        Point pt1, pt2;
//        double a = cos(t), b = sin(t);
//        double x0 = a*r, y0 = b*r;
//        pt1.x = cvRound(x0 - 10*b);// + width / 2;
//        pt1.y = cvRound(y0 + 10*a);// + height / 2;
//        pt2.x = cvRound(x0 + 10*b);// + width / 2;
//        pt2.y = cvRound(y0 - 10*a);// + height / 2;
//        cout << pt1 << "\t" << pt2 << endl;
//        pLines.push_back(vector<Point>{pt1, pt2});
//        line(cdst, pt1, pt2, Scalar(0,0,255), 2);
//
//        len = norm(pt1 - pt2);
//        if(len > maxLen)
//        {
//            maxLen = len;
//        }
//    }
//
//    cout << rho.size() << endl;

    vector<Vec4i> lines;
    HoughLinesP(dst, lines, 1, CV_PI/180, 10, 50, 10);
//    cout << lines.size() << endl;
    for( size_t i = 0; i < lines.size(); i++)
    {
        Vec4i l = lines[i];
        Point pt1, pt2;
//        cout << l[0] << "\t" << l[1] << "\t" << l[2] << "\t" << l[3] << endl;
        Vec2f rhoTheta = twoPoints2Polar(lines[i]);
        rho.push_back(rhoTheta[0]);
        theta.push_back(rhoTheta[1]);
        line( cdstP, Point(l[0], l[1]), Point(l[2], l[3]), Scalar(0,0,255), 3, 16);
    }

//    imshow("hough", cdst);
//    waitKey(0);
//    imshow("hough1111", cdstP);
//    waitKey(0);

    Mat rm, tm, rs, ts;
    meanStdDev(rho, rm, rs);
    meanStdDev(theta, tm, ts);

    double rhoStd = rs.at<double>(0, 0);
    double rhoMean = rm.at<double>(0, 0);
    double thetaStd = ts.at<double>(0, 0);
    double thetaMean = tm.at<double>(0, 0);

    rho -= rhoMean;
    theta -= thetaMean;

    rho /= rhoStd;
    theta /= thetaStd;

    if(lines.size() == 0)
    {
        Mat res = (Mat)(Mat::ones(2, 2, CV_64F));
        res *= -1;
        return res;
    }

    if (rhoStd == 0 || thetaStd == 0)
    {
        return  (Mat)(Mat::zeros(2, 2, CV_64F));
    }
    else {
        int numCluster = std::min(5, rho.rows);
        Mat samples, labels, centers;
        hconcat(rho, theta, samples);
        kmeans(samples, numCluster, labels,
               cv::TermCriteria(CV_TERMCRIT_ITER, 10, 0.1), 1, KMEANS_PP_CENTERS,
               centers);
        Mat sum_line_length = (Mat) Mat::zeros(numCluster, 1, CV_64F);
        for (int i = 0; i < labels.rows; i++) {
            int j = labels.at<int>(i, 0);
            Point p1 = Point(lines[i][0], lines[i][1]);
            Point p2 = Point(lines[i][2], lines[i][3]);
            sum_line_length.at<double>(j, 0) += sqrt(pow(p1.x - p2.x, 2) +
                                                     pow(p1.y - p2.y, 2));
        }

        Mat sorted_line_length;
        cv::sortIdx(sum_line_length, sorted_line_length, SORT_EVERY_COLUMN + CV_SORT_DESCENDING);

        Mat ab = (Mat)Mat::zeros(1, 2, CV_64F);
        ab.at<double>(0,0) = centers.at<double>(0, 0) * rhoMean + rhoStd;
        ab.at<double>(0,1) = centers.at<double>(0, 1) * thetaMean + thetaStd;

        double rr = ab.at<double>(0);
        double tt = ab.at<double>(1);

        int height = im.rows;
        int width = im.cols;

        double a = (double) (rr - cos(tt)) / sin(tt);
        double b = (rr - width * cos(tt)) / sin(tt);
        double c = (rr - sin(tt)) / cos(tt);
        double d = (rr - height * sin(tt)) / cos(tt);
        double e = 1.0;
        Mat ips = (Mat)Mat::zeros(4, 2, CV_64F);
        ips.at<double>(0,0) = 1;
        ips.at<double>(0,1) = cvRound(a);
        ips.at<double>(1,0) = width;
        ips.at<double>(1,1) = cvRound(b);
        ips.at<double>(2,0) = cvRound(c);
        ips.at<double>(2,1) = 1;
        ips.at<double>(3,0) = cvRound(d);
        ips.at<double>(3,1) = height;

        Mat endPoints = (Mat) (Mat::zeros(2, 2, CV_64F));
        int j = 0;
        for (int i = 0; i < 4; i++) {
            Mat p(1, 2, CV_64F);
            p.at<double>(0,0) = ips.at<double>(i, 0);
            p.at<double>(0,1) = ips.at<double>(i, 1);

            if (p.at<double>(0, 0) > 0 && p.at<double>(0, 0) <= width
                && p.at<double>(0, 1) > 0 && p.at<double>(0, 1) <= height) {
                endPoints.at<double>(j,0) = p.at<double>(0, 0);
                endPoints.at<double>(j,1) = p.at<double>(0, 1);
                j++;
            }
        }
        return endPoints;
    }
}



