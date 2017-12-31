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
    filter2D(im, filterdImage, -1, kernel);
    cvtColor(filterdImage, greyImage, COLOR_RGB2GRAY);
    Canny(greyImage, cannyImage, 0.2, 0.5);

    vector<Vec2f> lines;
    vector<vector<Point>> pLines;
    int threshold = 100;
    HoughLines(cannyImage, lines, 5, CV_PI/180, threshold, 0, 0); //TODO check
    // threshold
    double maxLen = 0;
    double len;
    Mat rho, theta;
    for( size_t i = 0; i < lines.size(); i++ )
    {
        float r = lines[i][0], t = lines[i][1];
        rho.push_back(r);
        theta.push_back(t);

        Point pt1, pt2;
        double a = cos(t), b = sin(t);
        double x0 = a*r, y0 = b*r;
        pt1.x = cvRound(x0 + pow(threshold, 2)*(-b));
        pt1.y = cvRound(y0 + pow(threshold, 2)*(a));
        pt2.x = cvRound(x0 - pow(threshold, 2)*(-b));
        pt2.y = cvRound(y0 - pow(threshold, 2)*(a));
        pLines.push_back(vector<Point>(pt1, pt2));
        len = norm(pt1 - pt2);
        if(len > maxLen)
        {
            maxLen = len;
        }
    }

    Mat rm, tm, rs, ts;
    meanStdDev(rho, rm, rs);
    double rhoStd = rs.at<double>(0, 0);
    double rhoMean = rm.at<double>(0, 0);
    double thetaStd = ts.at<double>(0, 0);
    double thetaMean = tm.at<double>(0, 0);

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
    else
    {
        int numCluster = std::min(5, rho.rows);
        Mat samples, labels, centers;;
        hconcat(rho, theta, samples);
        kmeans(samples, numCluster, labels,
               cv::TermCriteria(CV_TERMCRIT_ITER, 10, 0.1), 1, KMEANS_PP_CENTERS,
               centers);
        Mat sum_line_length = (Mat)Mat::zeros(numCluster, 1, CV_64F);
        for(int i = 0; i < labels.size; i++)
        {
            int j = labels.at<int>(i, 0);
            Point p1 = pLines[j][0];
            Point p2 = pLines[j][1];
            sum_line_length.at<double>(j, 0) += sqrt(pow(p1.x - p2.x, 2) +
                                                          pow(p1.y - p2.y, 2));
        }

        std::sort(sum_line_length.begin(), sum_line_length.end(), [](const double
                                            a, const double b) { return a>b;});


        Mat ab = Mat_<double>(1, 2)  << (centers.at<double>(0) *  (Mat_<double>
                (1, 2) << rhoStd, thetaStd) + (Mat_<double>(1, 2) << rhoMean, thetaMean));
        auto rr = ab.at<double>(0);
        auto tt = deg2rad(ab.at<double>(1));

        int height = im.rows;
        int width = im.cols;
        Mat ips = Mat_<int>(4, 2) << 1, (rho - cos(theta)) / sin(theta),
                width, (rho - width*cos(theta)) / sin(theta),
                (rho-sin(theta))/cos(theta), 1, (rho - height*sin(theta)) /
                cos(theta), height;
        Mat endPoints = (Mat)(Mat::zeros(2, 2, CV_64F));

        int j = 1;
        for( int i = 0 ; i < 4; i++)
        {
            Mat p = ips.at<Mat>(i);
            if(p.at<int>(0, 0) > 0 && p.at<int>(0, 0) <= width
               && p.at<int>(1, 0) > 0 && p.at<int>(1, 0) <= height)
            {
                endPoints.at<Mat>(j) = p;
                j++;
            }
        }
        return endPoints;
    }


}
