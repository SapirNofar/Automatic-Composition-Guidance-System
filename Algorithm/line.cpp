#include <stdlib.h>
#include <iostream>
#include "opencv2/opencv.hpp"
#include <dirent.h>
#include <fstream>

using namespace cv;
using namespace std;

double deg2rad(double degrees)
{
    return degrees * 4.0 * atan(1.0) / 180.0;
}

Mat getLine (Mat im)
{
    Mat filterdImage, greyImage, cannyImage, lineImage;
    cv::Mat kernel =  cv::getGaussianKernel(5, 5);
    cv::mulTransposed(kernel, kernel, false);
    filter2D(im, filterdImage, -1, kernel); //TODO check if color channels are not oposite order

//    bee
    Mat dst, cdst;
    Canny(filterdImage, dst, 50, 127);
    cvtColor(dst, cdst, CV_GRAY2BGR);
    vector<Vec2f> lines;
    HoughLines(dst, lines, 7, CV_PI/180, 100);

////    bird
//    Canny(filterdImage, dst, 120, 300, 3);
//    cvtColor(dst, cdst, CV_GRAY2BGR);
//    vector<Vec2f> lines;
//    HoughLines(dst, lines, 4, CV_PI/180, 100, 0, 0 );

    vector<vector<Point>> pLines;
    int threshold = 100;
    double maxLen = 0;
    double len;
    Mat rho, theta;
    for( size_t i = 0; i < lines.size(); i++ )
    {
        float r = cvRound(lines[i][0]), t = lines[i][1];
        if(r < 0)
        {
            r *= -1;
            t += CV_PI;
        }
        rho.push_back(r);
        theta.push_back(t);

        Point pt1, pt2;
        double a = cos(t), b = sin(t);
        double x0 = a*r, y0 = b*r;
        pt1.x = cvRound(x0 + 10*(-b));
        pt1.y = cvRound(y0 + 10*(a));
        pt2.x = cvRound(x0 - 10*(-b));
        pt2.y = cvRound(y0 - 10*(a));
        pLines.push_back(vector<Point>{pt1, pt2});

        len = norm(pt1 - pt2);
        if(len > maxLen)
        {
            maxLen = len;
        }
    }


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
            Point p1 = pLines[i][0];
            Point p2 = pLines[i][1];
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



