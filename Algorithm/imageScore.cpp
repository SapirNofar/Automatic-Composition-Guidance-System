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
#define SIGMA_VB 0.2

#define M_WT_SIZE 0.2
#define M_WT_ROT 1
#define M_WT_DIAG 1
#define M_WT_VB 0.3

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

    int areaImage = height * width;
    double balanceCenterX = 0.5 * width;
    double balanceCenterY = 0.5 * height;

    Mat endPoints = getLine(im);
//    cout << endPoints << endl;
    double line_value,  line_info;
    getLineValue(endPoints, width, height, &line_value, &line_info);
    Mat rgbIm;

    Mat SM = getFASA(im);
//    imshow("FASA", SM);
    Mat filterdImage;
    Mat kernel =  cv::getGaussianKernel(3, 163);
    Mat kernelT;
    transpose(kernel, kernelT);
    filter2D(SM, filterdImage, -1, kernelT);
    filter2D(filterdImage, filterdImage, -1, kernel);

    Mat highProb;
    threshold(filterdImage, highProb, 150, 255, THRESH_BINARY);
//    imshow("filtered FASA", highProb);
    vector<ConnectedComponent> cc;
    cc.clear();
    findCC(highProb, cc);

    vector<int> area;
//    vector<Rect> bBox;
    vector<float> objMean;
    vector<cv::Point> centroids;
    if(cc.size() > 1)
    {

        vector<int> tempAreas;
        for(int i = 0; i < cc.size(); i++)
        {
//            cout << cc[i].getPixelCount() << endl;
            tempAreas.push_back(cc[i].getPixelCount());
        }

        vector<int> sorted_area_idx;
        cv::sortIdx(tempAreas, sorted_area_idx, CV_SORT_DESCENDING);
//        for (int k = 0; k < sorted_area_idx.size(); ++k) {
//            cout << tempAreas[sorted_area_idx[k]] << endl;
//        }

        if((tempAreas[sorted_area_idx[1]] / tempAreas[sorted_area_idx[0]]) < 0.15)
        {

            area.push_back(tempAreas[sorted_area_idx[0]]);
            int pixelsSum = pixelsValue(filterdImage, cc[sorted_area_idx[0]]);
            objMean.push_back(pixelsSum / tempAreas[sorted_area_idx[0]]);
            centroids.push_back(calculateBlobCentroid(*(cc[sorted_area_idx[0]]).getPixels()));
        }
        else
        {
            for(int j = 0; j < cc.size(); j++)
            {
                area.push_back(tempAreas[sorted_area_idx[j]]);
                int pixelsSum = pixelsValue(filterdImage, cc[sorted_area_idx[j]]);
                objMean.push_back(pixelsSum / tempAreas[sorted_area_idx[j]]);
                centroids.push_back(calculateBlobCentroid(*(cc[sorted_area_idx[j]]).getPixels()));
            }
        }
    }
    else
    {
        area.push_back(cc[0].getPixelCount());
        int pixelsSum = pixelsValue(filterdImage, cc[0]);
        objMean.push_back(pixelsSum / cc[0].getPixelCount());
        centroids.push_back(calculateBlobCentroid(*(cc[0]).getPixels()));
    }


    // selient region size
    double objectAreaRatio = (1.0 * area[0]) / areaImage;
    double temp_size = 0;

    if (objectAreaRatio <= AREA_BOUND_SMALL)
    {
        temp_size = std::pow(std::pow(objectAreaRatio-0.1, 2), 0.5);
    }
    else if(objectAreaRatio > AREA_BOUND_SMALL && objectAreaRatio <= AREA_BOUND_LARGE)
    {
        temp_size = std::pow(std::pow(objectAreaRatio-0.56, 2), 0.5);
    }
    else if (objectAreaRatio > AREA_BOUND_LARGE)
    {
        temp_size = std::pow(std::pow(objectAreaRatio-0.82, 2), 0.5);
    }

    double en_size = std::exp(-(std::pow(temp_size, 2) / 2) /  std::pow(SIGMA_SIZE, 2));



    // VB

    double weight = 0, weightSum = 0, x = 0, y = 0, d = 0;
    for (int k = 0; k < area.size(); ++k) {
//        cout << area[k] << endl;
        weight = area[k] * objMean[k];
        x += weight * centroids[k].x;
        y += weight * centroids[k].y;
        weightSum += weight;
    }

    x = (x / weightSum) - balanceCenterX;
    y = (y / weightSum) - balanceCenterY;
    x /= width;
    y /= height;
    double temp_d = std::abs(x) + std::abs(y);
    d = std::exp(-(std::pow(temp_d, 2) / 2) / std::pow(SIGMA_VB, 2));

    double vbScore = d;

    // ROT
    // line based
    double line_based_score = 0;
    if(line_info == 0 || line_info == 1)
    {
        line_based_score = line_value;
    }

    // point based
    double dx = 0, dy = 0, dist = 0,
            point_based_score = 0;
    weight = 0, weightSum = 0;

    double ptx1 = (1./3) * width;
    double ptx2 = (2./3) * width;
    double pty1 = (1./3) * height;
    double pty2 = (2./3) * height;
//    cout << ptx1 << "\t" << pty1 << endl;

    for (int i = 0; i < area.size(); ++i)
    {
        weight = area[i] * objMean[i];
        dx = std::min(std::abs(centroids[i].x - ptx1), std::abs(centroids[i].x - ptx2));
        dy = std::min(std::abs(centroids[i].y - pty1), std::abs(centroids[i].y - pty2));
        weightSum += weight;
        auto tempDist = (dx / width) + (dy / height);
        dist = std::exp(-(std::pow(tempDist,2)/2)/std::pow(SIGMA_POINT,2));
        point_based_score += weight * dist;
    }

//    cout << "weight " << weight << endl;
//    cout << "dx " << dx << endl;
//    cout << "dy " << dy << endl;
//    cout << "weightSum " << weightSum << endl;
//    cout << "dist " << dist << endl;
//    cout << "point_based_score1 " << point_based_score << endl;

    point_based_score /= weightSum;
//    cout << "point_based_score " << point_based_score << endl;
//    cout << "line_based_score " << line_based_score << endl;

    double ROTScore = 0;
    if (point_based_score == 0 || line_based_score == 0)
    {
        ROTScore = point_based_score + line_based_score;
    }
    else
    {
        ROTScore = (1./(M_WT_ROT_P + M_WT_ROT_LN)) * (M_WT_ROT_P * point_based_score + M_WT_ROT_LN * line_based_score);
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
            M_WT_VB*vbScore + bdiag*M_WT_DIAG*diagScore) /
            (M_WT_SIZE + M_WT_ROT + M_WT_VB + bdiag*M_WT_DIAG);



    cout <<"ROT " << ROTScore << endl;
    cout <<"VB " << vbScore << endl;
    cout <<"Diag " << diagScore << endl;
    cout <<"Size " << en_size << endl;
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

