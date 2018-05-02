#include "ScoreCalculation.h"

#define JUMP 10
using namespace std;

cv::Mat calc9(cv::Mat& im, cv::Point startPoint, int range_height, int range_width, dispatch_group_t group, dispatch_queue_t fasaQueue, dispatch_queue_t lineQueue)
{
//    cout << "image size:" << "\t" << im.cols << "\t" << im.rows << endl;

    cv::Mat scores = (cv::Mat)cv::Mat::zeros(3, 3, CV_64F);
    cv::Mat i = im(cv::Range(startPoint.y, startPoint.y + range_height), cv::Range(startPoint.x, startPoint.x + range_width));
    scores.at<double>(1,1) = getScore(i, group, fasaQueue, lineQueue);
                                         
    if(startPoint.x - JUMP >= 0 && startPoint.y - JUMP >= 0)
    {
        i = im(cv::Range(startPoint.y - JUMP, startPoint.y - JUMP + range_height), cv::Range(startPoint.x - JUMP, startPoint.x - JUMP + range_width));
        scores.at<double>(0,0) = getScore(i, group, fasaQueue, lineQueue);
    }
    
    if(startPoint.x - JUMP >= 0)
    {
        i = im(cv::Range(startPoint.y, startPoint.y + range_height), cv::Range(startPoint.x - JUMP, startPoint.x - JUMP + range_width));
        scores.at<double>(1,0) = getScore(i, group, fasaQueue, lineQueue);
    }
    
    if(startPoint.x - JUMP >= 0 && startPoint.y + JUMP + range_height < im.rows)
    {
        i = im(cv::Range(startPoint.y + JUMP, startPoint.y + JUMP + range_height), cv::Range(startPoint.x - JUMP, startPoint.x - JUMP + range_width));
        scores.at<double>(2,0) = getScore(i, group, fasaQueue, lineQueue);
    }
    
    if(startPoint.y - JUMP >= 0)
    {
        i = im(cv::Range(startPoint.y - JUMP, startPoint.y - JUMP + range_height), cv::Range(startPoint.x, startPoint.x + range_width));
        scores.at<double>(0,1) = getScore(i, group, fasaQueue, lineQueue);
    }
    
    if(startPoint.y + JUMP + range_height < im.rows)
    {
        i = im(cv::Range(startPoint.y + JUMP, startPoint.y + JUMP + range_height), cv::Range(startPoint.x, startPoint.x + range_width));
        scores.at<double>(2,1) = getScore(i, group, fasaQueue, lineQueue);
    }
    
    if(startPoint.x + JUMP + range_width < im.cols && startPoint.y - JUMP >= 0)
    {
        i = im(cv::Range(startPoint.y - JUMP, startPoint.y - JUMP + range_height), cv::Range(startPoint.x + JUMP, startPoint.x + JUMP + range_width));
        scores.at<double>(0,2) = getScore(i, group, fasaQueue, lineQueue);
    }
    
    if(startPoint.x + JUMP + range_width < im.cols)
    {
        i = im(cv::Range(startPoint.y, startPoint.y + range_height), cv::Range(startPoint.x + JUMP, startPoint.x + JUMP + range_width));
        scores.at<double>(1,2) = getScore(i, group, fasaQueue, lineQueue);
    }
    
    if(startPoint.x + JUMP + range_width < im.cols && startPoint.y + JUMP + range_height < im.rows)
    {
        i = im(cv::Range(startPoint.y + JUMP, startPoint.y + JUMP + range_height), cv::Range(startPoint.x + JUMP, startPoint.x + JUMP + range_width));
        scores.at<double>(2,2) = getScore(i, group, fasaQueue, lineQueue);
    }
    i.release();
    return scores;
}


int getImageScore(cv::Mat& im, dispatch_group_t group, dispatch_queue_t fasaQueue, dispatch_queue_t lineQueue)
{
    int height = im.rows;
    int width = im.cols;
    
    cout << "image size:" << "\t" << height << "\t" << width << endl;
    if(height == 0 || width == 0)
    {
        return -1;
    }
    int range_height = int(height * (8./9));
    int range_width = int(width * (8./9));
    int height1 = JUMP;
    int width1 = JUMP;
    // TODO what is the best range for jump??
//        int height1 = int(range_height * (1./3));
//        int width1 = int(range_width * (1./3));
//    int height2 = int(range_height * (2./3));
//    int width2 = int(range_width * (2./3));
    
    cv::Point min_loc, max_loc;
    double min, max, middleScore;
    
    cv::Point startPoint(int(width * (1./18)), int(height * (1./18)));
    cv::Point initialPoint(int(width * (1./18)), int(height * (1./18)));
    cv::Mat i = im(cv::Range(startPoint.x , startPoint.x + range_height),
                   cv::Range(startPoint.y, startPoint.y + range_width));
    max = getScore(i, group, fasaQueue, lineQueue);
    middleScore = 0;
//    cout << "start point:" << "\t" << startPoint << endl;
//    cout << "start score:" << "\t" << max << endl;
//    cout << height1 << "\t" << height2 << endl;
//    cout << width1 << "\t" << width2 << endl;
    cv::Mat tempScore9;
    while(max > middleScore)
    {
//            cout << "start point:" << "\t" << startPoint << endl;
        tempScore9 = calc9(im, startPoint, range_height, range_width, group, fasaQueue, lineQueue);
        middleScore = tempScore9.at<double>(1,1);
        cv::minMaxLoc(tempScore9, &min, &max, &min_loc, &max_loc);
//                cout << tempScore9 << endl;
        if(max_loc.x == 0 && max_loc.y == 0)
        {
            startPoint = cv::Point(startPoint.x - JUMP, startPoint.y - JUMP);
//            cout << "UP LEFT" << endl;
        }
        else if(max_loc.x == 1 && max_loc.y == 0)
        {
            startPoint = cv::Point(startPoint.x, startPoint.y - JUMP);
//            cout << "UP" << endl;
        }
        else if(max_loc.x == 2 && max_loc.y == 0)
        {
            startPoint = cv::Point(startPoint.x + JUMP, startPoint.y - JUMP);
//            cout << "UP RIGHT" << endl;
        }
        else if(max_loc.x == 0 && max_loc.y == 1)
        {
            startPoint = cv::Point(startPoint.x - JUMP, startPoint.y);
//            cout << "LEFT" << endl;
        }
        else if(max_loc.x == 2 && max_loc.y == 1)
        {
            startPoint = cv::Point(startPoint.x + JUMP, startPoint.y);
//            cout << "RIGHT" << endl;
        }
        else if(max_loc.x == 0 && max_loc.y == 2)
        {
            startPoint = cv::Point(startPoint.x - JUMP, startPoint.y + JUMP);
//            cout << "DOWN LEFT" << endl;
        }
        else if(max_loc.x == 1 && max_loc.y == 2)
        {
            startPoint = cv::Point(startPoint.x, startPoint.y + JUMP);
//            cout << "DOWN" << endl;
        }
        else if(max_loc.x == 2 && max_loc.y == 2)
        {
            startPoint = cv::Point(startPoint.x + JUMP, startPoint.y + JUMP);
//            cout << "DOWN RIGHT" << endl;
        }
//        else
//        {
//            cout << "STAY" <<  endl;
//        }
        
//        cout << "new point: " << "\t" << startPoint << endl;
    }
//    cout << "FINAL SCORE\t" << max <<endl;
//    cout << "FINAL POINT" << endl;
    cv::Point delta = initialPoint - startPoint;

    i.release();
    tempScore9.release();

    if((std::abs(delta.x) > width1 && delta.x > 0) && (std::abs(delta.y) > height1 && delta.y > 0))
    {
//        cout << "UP LEFT" << endl;
        return 0;
    }
    else if((std::abs(delta.x) < width1) && (std::abs(delta.y) > height1 && delta.y > 0))
    {
//        cout << "UP" << endl;
        return 1;
    }
    else if((std::abs(delta.x) > width1 && delta.x < 0) && (std::abs(delta.y) > height1 && delta.y > 0))
    {
//        cout << "UP RIGHT" << endl;
        return 2;
    }
    else if((std::abs(delta.x) > width1 && delta.x > 0) && (std::abs(delta.y) < height1))
    {
//        cout << "LEFT" << endl;
        return 3;
    }
    else if((std::abs(delta.x) > width1 && delta.x < 0) && (std::abs(delta.y) < height1))
    {
//        cout << "RIGHT" << endl;
        return 5;
    }
    else if((std::abs(delta.x) > width1 && delta.x > 0) && (std::abs(delta.y) > height1 && delta.y < 0))
    {
//        cout << "DOWN LEFT" << endl;
        return 6;
    }
    else if((std::abs(delta.x) < width1) && (std::abs(delta.y) > height1 && delta.y < 0))
    {
//        cout << "DOWN" << endl;
        return 7;
    }
    else if((std::abs(delta.x) > width1 && delta.x < 0) && (std::abs(delta.y) > height1 && delta.y < 0))
    {
//        cout << "DOWN RIGHT" << endl;
        return 8;
    }
    else
    {
//        cout << "STAY" <<  endl;
        return 4;
    }
    
    
}
