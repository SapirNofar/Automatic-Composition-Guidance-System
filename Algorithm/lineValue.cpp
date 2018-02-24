#include <iostream>
#include <stdlib.h>
#include <math.h>
#include "opencv2/opencv.hpp"


using namespace std;
using namespace cv;

int getLineValue(Mat &endPoints, int w, int h, double* line_value, double* line_info)
{

    Mat thirds_line = (Mat)Mat::zeros(4, 4, CV_64F);
    thirds_line.at<double>(0,0) = 0;
    thirds_line.at<double>(0,1) = (1./3)*h;
    thirds_line.at<double>(0,2) = w;
    thirds_line.at<double>(0,3) = (1./3)*h;
    thirds_line.at<double>(1,0) = 0;
    thirds_line.at<double>(1,1) = (2./3)*h;
    thirds_line.at<double>(1,2) = w;
    thirds_line.at<double>(1,3) = (2./3)*h;
    thirds_line.at<double>(2,0) = (1./3)*w;
    thirds_line.at<double>(2,1) = 0;
    thirds_line.at<double>(2,2) = (1./3)*w;
    thirds_line.at<double>(2,3) = h;
    thirds_line.at<double>(3,0) = (2./3)*w;
    thirds_line.at<double>(3,1) = 0;
    thirds_line.at<double>(3,2) = (2./3)*w;
    thirds_line.at<double>(3,3) = h;

    Mat thirds_center = (Mat)Mat::zeros(4, 2, CV_64F);
    thirds_center.at<double>(0,0) = 0.5*w;
    thirds_center.at<double>(0,1) = (1./3)*h;
    thirds_center.at<double>(1,0) = 0.5*w;
    thirds_center.at<double>(1,1) = (2./3)*h;
    thirds_center.at<double>(2,0) = (1./3)*w;
    thirds_center.at<double>(2,1) = 0.5*h;
    thirds_center.at<double>(3,0) = (2./3)*w;
    thirds_center.at<double>(3,1) = 0.5*h;

    double sigma_line = 0.17;
    int line_idx = 1;

    double len = sqrt(pow(thirds_line.at<double>(0,2)-thirds_line.at<double>(0,0), 2)+
                              pow(thirds_line.at<double>(0,3)-thirds_line.at<double>(0,1), 2));
    double d1 = (((thirds_line.at<double>(0,3) - thirds_line.at<double>(0,1)) * endPoints.at<double>(0,0)
                  - (thirds_line.at<double>(0,2) - thirds_line.at<double>(0,0)) * endPoints.at<double>(0,1)
                  + thirds_line.at<double>(0,2) * thirds_line.at<double>(0,1)
                  - thirds_line.at<double>(0,0) * thirds_line.at<double>(0,3)))/len;
    double d2 = (((thirds_line.at<double>(0,3) - thirds_line.at<double>(0,1)) * endPoints.at<double>(1,0)
                  - (thirds_line.at<double>(0,2) -thirds_line.at<double>(0,0)) * endPoints.at<double>(1,1)
                  + thirds_line.at<double>(0,2) * thirds_line.at<double>(0,1)
                  - thirds_line.at<double>(0,0) * thirds_line.at<double>(0,3)))/len;

    double temp;
    if (d1*d2 >= 0)
    {
        temp = abs(d1+d2)/2;
    }
    else
    {
        temp = (double)(0.5*(pow(d1, 2) + pow(d2, 2)) / abs(d1-d2));
    }


    for(int i=1; i<= 3; i++)
    {
        len = (double)sqrt(pow(thirds_line.at<double>(i,2)-thirds_line
                .at<double>(i,0), 2) +
                   pow(thirds_line.at<double>(i,3)-thirds_line.at<double>(i,1), 2));
        d1 = (((thirds_line.at<double>(i,3)-thirds_line.at<double>(i,1))
               * endPoints.at<double>(0,0)
               - (thirds_line.at<double>(i,2)-thirds_line.at<double>(i,0))*endPoints.at<double>(0,1)
               + thirds_line.at<double>(i,2)*thirds_line.at<double>(i,1)
               - thirds_line.at<double>(i,0)*thirds_line.at<double>(i,3)))/len;
        d2 = (((thirds_line.at<double>(i,3) - thirds_line.at<double>(i,1)) * endPoints.at<double>(1,0)
               - (thirds_line.at<double>(i,2) -thirds_line.at<double>(i,0)) * endPoints.at<double>(1,1)
               + thirds_line.at<double>(i,2) * thirds_line.at<double>(i,1)
               - thirds_line.at<double>(i,0) * thirds_line.at<double>(i,3)))/len;

        double line_distance;
        if (d1*d2 >= 0)
        {
            line_distance = abs(d1+d2)/2;
        }

        else
        {
            line_distance = (double)(0.5*(pow(d1, 2) + pow(d2, 2)) / abs(d1-d2));
        }

        if (line_distance < temp)
        {
            temp = line_distance;
            line_idx = i;
        }
    }

    double x1 = endPoints.at<double>(0,0);
    double y1 = endPoints.at<double>(0,1);
    double x2 = endPoints.at<double>(1,0);
    double y2 = endPoints.at<double>(1,1);
    double k = abs((y2-y1) / (x2-x1));
    double image_center_x = 0.5 * w;
    double image_center_y = 0.5 * h;

    Mat targetPoint = (Mat)Mat::zeros(1, 2, CV_64F);

    if((line_idx == 1) || (line_idx == 2))
    {
        double tanTheta = h/w;
        double tanTheta1 = 0.25 * tanTheta;
        double tanTheta2 = 0.75 * tanTheta;

        if (k < tanTheta1)
        {
            targetPoint.at<double>(0, 0) = thirds_center.at<double>(line_idx, 0);
            targetPoint.at<double>(0, 1) = thirds_center.at<double>(line_idx, 1);
            line_info = 0; // HORIZONTALLINE
        }
        else
        {
            Mat centers;
            hconcat(image_center_x, image_center_y, centers);
            targetPoint = (centers);
            *line_info = 2;
            if((x2-x1) == 0)
            {
                *line_info = 1;
            }
        }

        double dist = abs(targetPoint.at<double>(0,1)-(y1+y2)*0.5)/w + abs(targetPoint.at<double>(0,0)-(x1+x2)*0.5)/h;
        double line_value = (double)exp(-dist*dist*0.5/pow(sigma_line,2));
    }

    else if((line_idx == 3) || (line_idx == 4))
    {
        k = 1/k;
        double tanTheta = w/h;
        double tanTheta1 = 0.25 * tanTheta;
        double tanTheta2 = 0.75 * tanTheta;

        if ((k < tanTheta1) || ((x2-x1) == 0))
        {
            targetPoint.at<double>(0, 0) = thirds_center.at<double>(line_idx, 0);
            targetPoint.at<double>(0, 1) = thirds_center.at<double>(line_idx, 1);
            *line_info = 1; // VERTICALLINE
        }
        else
        {
            Mat centers;
            hconcat(image_center_x, image_center_y, centers);
            targetPoint = (centers);
            *line_info = 3;
        }
        double dist = abs(targetPoint.at<double>(0,0)-(x1+x2)*0.5)/w + abs(targetPoint.at<double>(0,1)-(y1+y2)*0.5)/h;
        *line_value = (double)exp(-dist*dist*0.5/pow(sigma_line,2));
    }

    return 0;
}
