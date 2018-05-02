#include "line.h"
using namespace std;
using namespace cv;

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



Mat getLine (Mat& im)
{
    int height = im.rows;
    int width = im.cols;
    Mat filterdImage, greyImage, cannyImage, lineImage;

    UIImage* uiImage = [ImageUtils UIImageFromCVMat:im];
    filterdImage = [ImageUtils cvMatGrayFromUIImage: [ImageUtils blurImage:uiImage]];

//    CGSize imageSize = uiImage.size;
//    CIImage *inputImage = [[CIImage alloc] initWithCGImage:uiImage.CGImage];
//    uiImage = nil;
//
//    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
//    [filter setValue:inputImage forKey:@"inputImage"];
//    [filter setValue:[NSNumber numberWithFloat:5] forKey:@"inputRadius"];
//
//    CIImage *result = [filter valueForKey:kCIOutputImageKey];
//    inputImage = nil;
//    float scale =  [[UIScreen mainScreen] scale];
//    CIImage *cropped=[result imageByCroppingToRect:CGRectMake(0, 0, imageSize.width*scale, imageSize.height*scale)];
//    CGRect extent = [cropped extent];
//
//    CIContext *context = [CIContext contextWithOptions:nil];
//    CGImageRef cgImage = [context createCGImage:cropped fromRect:extent];
//    filterdImage = [ImageUtils cvMatGrayFromUIImage: [UIImage imageWithCGImage:cgImage]];
//    CGImageRelease(cgImage);
//
//
    uiImage = nil;
//    context = nil;
//    filter = nil;
//    result = nil;
//    cropped = nil;
    
//    cv::Mat kernel =  cv::getGaussianKernel(5, 5);
//    cv::mulTransposed(kernel, kernel, false);
//    filter2D(im, filterdImage, -1, kernel);
//    cvtColor(filterdImage, greyImage, COLOR_RGB2GRAY);

    Mat dst, cdst, cdstP;
    GaussianBlur(greyImage, cannyImage, cv::Size(15,15), 2);
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
        cv::Point pt1, pt2;
//        cout << l[0] << "\t" << l[1] << "\t" << l[2] << "\t" << l[3] << endl;
        Vec2f rhoTheta = twoPoints2Polar(lines[i]);
        rho.push_back(rhoTheta[0]);
        theta.push_back(rhoTheta[1]);
        line( cdstP, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), cv::Scalar(0,0,255), 3, 16);
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
    
    Mat endPoints;
    
    if(lines.size() == 0)
    {
        endPoints = (Mat)(Mat::ones(2, 2, CV_64F));
        endPoints *= -1;
        return endPoints;
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
            cv::Point p1 = cv::Point(lines[i][0], lines[i][1]);
            cv::Point p2 = cv::Point(lines[i][2], lines[i][3]);
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

        endPoints = (Mat) (Mat::zeros(2, 2, CV_64F));
        int j = 0;
        Mat p(1, 2, CV_64F);
        for (int i = 0; i < 4; i++) {
            p.at<double>(0,0) = ips.at<double>(i, 0);
            p.at<double>(0,1) = ips.at<double>(i, 1);

            if (p.at<double>(0, 0) > 0 && p.at<double>(0, 0) <= width
                && p.at<double>(0, 1) > 0 && p.at<double>(0, 1) <= height) {
                endPoints.at<double>(j,0) = p.at<double>(0, 0);
                endPoints.at<double>(j,1) = p.at<double>(0, 1);
                j++;
            }
        }
        
        filterdImage.release();
        greyImage.release();
        cannyImage.release();
        lineImage.release();
        dst.release();
        cdst.release();
        cdstP.release();
        rho.release();
        theta.release();
        rm.release();
        tm.release();
        rs.release();
        ts.release();
        samples.release();
        labels.release();
        centers.release();
        sum_line_length.release();
        sorted_line_length.release();
        ab.release();
        ips.release();
        p.release();
        
        return endPoints;
    }
}

void getLineValue(Mat &endPoints, int w, int h, std::shared_ptr<double> line_value, std::shared_ptr<double>
                  line_info)
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
    Mat centers;
    
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
            hconcat(image_center_x, image_center_y, centers);
            targetPoint = (centers);
            *line_info = 3;
        }
        double dist = abs(targetPoint.at<double>(0,0)-(x1+x2)*0.5)/w + abs(targetPoint.at<double>(0,1)-(y1+y2)*0.5)/h;
        *line_value = (double)exp(-dist*dist*0.5/pow(sigma_line,2));
    }
    
    thirds_line.release();
    thirds_center.release();
    targetPoint.release();
    centers.release();
    
}




