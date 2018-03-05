//
// Created by nofar.erez92 on 3/5/18.
//

#include "opencv2/opencv.hpp"
#include "imageScore.cpp"

#define JUMP 10

// image slicing:
//cv::Mat img = ...;
//cv::Mat subImg = img(cv::Range(0, 100), cv::Range(0, 100));

Mat getHeatMap(const Mat& im)
{
    int height = im.rows;
    int width = im.cols;

    cout << "height " << height << endl;
    cout << "width " << width << endl;

    int heat_height = int(height * (8./9));
    int heat_width = int(width * (8./9));

    cout << "heat_height " << heat_height << endl;
    cout << "heat_width " << heat_width << endl;

    int x_step = 0, y_step = 0;
    int cur_x = heat_width, cur_y = heat_height;

    while(cur_x < width)
    {
        x_step++;
        cur_x += JUMP;
    }

    while(cur_y < height)
    {
        y_step++;
        cur_y += JUMP;
    }

    cout << x_step << "\t" << y_step << endl;
    Mat heatMap = (Mat)Mat::zeros(y_step*10, x_step*10, CV_64F);

    cout << "heatMap size " << heatMap.size() << endl;

    Mat temp;
    double score;
    for (int i = 0; i < y_step; i++) {
        for (int j = 0; j < x_step; j++) {
            temp = im(cv::Range(JUMP*i, JUMP*i + heat_height), cv::Range(JUMP*j, JUMP*j + heat_width));
            score = getScore(temp);
            for (int k = 0; k < 10; ++k) {
                for (int l = 0; l < 10; ++l) {
                    heatMap.at<double>(i*JUMP+k,j*JUMP+l) = score;
                }
            }
        }
    }

//    imwrite( "/cs/engproj/compose/Project/test/test/hot_air_baloon.jpg", heatMap );
    resize(heatMap, heatMap, Size(heatMap.cols*5, heatMap.rows*5)); // to half size or even smaller
    namedWindow( "heat map",CV_WINDOW_AUTOSIZE);
    imshow("heat map", heatMap);



//    namedWindow("heat map",WINDOW_NORMAL);
//    resizeWindow("heat map", 600, 600);
    waitKey(0);
    return heatMap;
}