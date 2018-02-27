#include <stdlib.h>
#include <iostream>
#include "opencv2/opencv.hpp"
#include <dirent.h>
#include <fstream>

#include "line.cpp" //TODO h
#include "lineValue.cpp" //TODO h
#include "FASA.cpp" //TODO h
#include "connectedcomponents.h" //TODO h


using namespace cv;
using namespace std;


#define THRESHAOLD 0.35

#define AREA_BOUND_SMALL 0.33
#define AREA_BOUND_LARGE 0.69

#define SIGMA_SIZE 0.33
#define SIGMA_POINT 0.17

#define M_WT_SIZE 0.2
#define M_WT_ROT 1
#define M_WT_DIAG 1

#define M_WT_ROT_P 0.4
#define M_WT_ROT_LN 0.6



int pixelsValue(Mat& im, ConnectedComponent cc)
{
    int sum = 0;
    const vector<Point2i>* points = cc.getPixels().get();
    for(int i = 0; i < points->size(); i++)
    {
        sum += int(im.at<uchar>((*points)[i]));
    }
    return sum;
}

inline cv::Point calculateBlobCentroid(const std::vector<cv::Point> blob)
{
    cv::Moments mu = cv::moments(blob);
    cv::Point centroid = cv::Point (mu.m10/mu.m00 , mu.m01/mu.m00);

    return centroid;
}


// im is RGB
double getScore(Mat im)
{


    Mat grayScaleIm;
    cvtColor(im, grayScaleIm, COLOR_RGB2GRAY);
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
    double line_value,  line_info;
    getLineValue(endPoints, width, height, &line_value, &line_info);
    Mat rgbIm;
//   cvtColor(im,rgbIm,COLOR_RGB2GRAY);

    Mat SM = getFASA(im);
    Mat filterdImage;
    Mat kernel =  cv::getGaussianKernel(3, 163);
    Mat kernelT;
    transpose(kernel, kernelT);
    filter2D(SM, filterdImage, -1, kernelT);
    filter2D(filterdImage, filterdImage, -1, kernel);

    Mat highProb;
    threshold(filterdImage, highProb, 150, 255, THRESH_BINARY);
    vector<ConnectedComponent> cc;
    findCC(highProb, cc);

    vector<int> area;
//    vector<Rect> bBox;
    vector<float> objMean;
    vector<cv::Point> centroids;
    int multi_obj = 0;
    if(cc.size() > 1)
    {

        vector<int> tempAreas;
        for(int i = 0; i < cc.size(); i++)
        {
            tempAreas.push_back(cc[i].getBoundingBoxArea());
        }

        vector<int> sorted_area_idx;
        cv::sortIdx(tempAreas, sorted_area_idx, SORT_EVERY_COLUMN + CV_SORT_DESCENDING);
        if((tempAreas[sorted_area_idx[1]] / tempAreas[sorted_area_idx[0]]) < 0.15)
        {
            area.push_back(tempAreas[sorted_area_idx[0]]);
//            bBox.push_back(cc[sorted_area_idx[0]].getBoundingBox());
            int pixelsSum = pixelsValue(filterdImage, cc[sorted_area_idx[0]]);
            objMean.push_back(pixelsSum / tempAreas[sorted_area_idx[0]]);
            centroids.push_back(calculateBlobCentroid(*(cc[sorted_area_idx[0]]).getPixels()));
        }
        else
        {
            multi_obj = 1;
            for(int j = 0; j < cc.size(); j++)
            {
                area.push_back(tempAreas[sorted_area_idx[j]]);
//                bBox.push_back(cc[sorted_area_idx[j]].getBoundingBox());
                int pixelsSum = pixelsValue(filterdImage, cc[sorted_area_idx[j]]);
                objMean.push_back(pixelsSum / tempAreas[sorted_area_idx[j]]);
                centroids.push_back(calculateBlobCentroid(*(cc[sorted_area_idx[j]]).getPixels()));
            }
        }
    }
    else
    {
        area.push_back(cc[0].getBoundingBoxArea());
//        bBox.push_back(cc[0].getBoundingBox());
        int pixelsSum = pixelsValue(filterdImage, cc[0]);
        objMean.push_back(pixelsSum / cc[0].getBoundingBoxArea());
        centroids.push_back(calculateBlobCentroid(*(cc[0]).getPixels()));
    }


    // selient region size
    double objectAreaRatio = area[0] / areaImage;
    double temp_size = 0;

    if (objectAreaRatio <= AREA_BOUND_SMALL)
    {
        temp_size = std::pow(std::pow(objectAreaRatio-0.1, 2), 0.5);
    }
    else if(objectAreaRatio > AREA_BOUND_SMALL && objectAreaRatio <= AREA_BOUND_LARGE)
    {
        temp_size = std::pow(std::pow(objectAreaRatio-0.56, 2), 0.5);
    }
    else
    {
        temp_size = std::pow(std::pow(objectAreaRatio-0.8, 2), 0.5);
    }

    auto en_size = std::exp(-(temp_size*temp_size/2) / std::pow(SIGMA_SIZE, 2));

    // ROT
    // line based
    double line_based_score = 0;
    if(line_info == 0 || line_info == 1)
    {
        line_based_score = line_value;
    }

    // point based
    double dx = 0, dy = 0, dist = 0, weight = 0, weightSum = 0,
            point_based_score = 0;

    double ptx1 = (1./3) * width;
    double ptx2 = (2./3) * width;
    double pty1 = (1./3) * height;
    double pty2 = (2./3) * height;


    for (int i = 0; i < cc.size(); ++i)
    {
        weight = area[i] * objMean[i];
        dx = std::min(std::abs(centroids[i].x - ptx1), std::abs
                (centroids[i].x - ptx2));
        dy = std::min(std::abs(centroids[i].y - pty1), std::abs
                (centroids[i].y - pty2));
        weightSum += weight;
        auto tempDist = (dx / width) + (dy / height);
        dist = std::exp(-(std::pow(tempDist,2)/2)/std::pow(SIGMA_POINT,2));
        point_based_score += weight * dist;
    }

    point_based_score /= weightSum;
    double ROTScore = 0;
    if (point_based_score == 0 || line_based_score == 0)
    {
        ROTScore = point_based_score + line_based_score;
    }
    else
    {
        ROTScore = 1./((M_WT_ROT_P + M_WT_ROT_LN) * (M_WT_ROT_P *
                point_based_score + M_WT_ROT_LN * line_based_score));
    }


    // DIAG
    double diagScore = 0, bdiag = 0;
    if(line_info == 2 || line_info == 3)
    {
        diagScore = line_value;
        bdiag = 1;
    }

    // FINAL SCORE
    double finalScore = (M_WT_SIZE*en_size + M_WT_ROT*ROTScore +
            bdiag*M_WT_DIAG*diagScore) / (M_WT_SIZE + M_WT_ROT +
            bdiag*M_WT_DIAG);


    cout <<"Region " << en_size << endl;
    cout <<"ROT " << ROTScore << endl;
    cout <<"Diag " << diagScore << endl;
    cout <<"Total " << finalScore << endl;

    if (finalScore > 0.78)
    {
        cout <<"Good" << endl;
    }
    else if (finalScore < 0.62)
    {
        cout << "Bad" << endl;
    }
    else
    {
        cout <<"Not Bad" << endl;
    }

    return finalScore;
}

