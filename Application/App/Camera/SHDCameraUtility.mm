#import "SHDCameraUtility.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreImage/CoreImage.h>
#import <UIKit/UIKitDefines.h>
#import <UIKit/UIColor.h>
#import <UIKit/UIGeometry.h>


@interface SHDCameraUtility () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) UIView *videoLayerView;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
//@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *stillImageOutput;
@end

@implementation SHDCameraUtility{
    BOOL canSavePicture;
    BOOL flashIsOn;
    AVCaptureDeviceInput *currentInput;
    UIVisualEffectView *blurView;
    UIImage *image;
    int counter;
    NSTimer *timer;
    BOOL busy;
    dispatch_source_t aTimer;
    UIView *viewUpLeft1;
    UIView *viewUpLeft2;
    UIView *viewUp;
    UIView *viewUpRight1;
    UIView *viewUpRight2;
    UIView *viewLeft;
    UIView *viewRight;
    UIView *viewDownLeft1;
    UIView *viewDownLeft2;
    UIView *viewDown;
    UIView *viewDownRight1;
    UIView *viewDownRight2;


}

#pragma mark - Lifecycle

- (instancetype)init{
    return [self initWithView:nil andDelegate:nil];
}

- (instancetype)initWithView:(UIView *)sourceView andDelegate:(id)delegate{
    if (self = [super init]){
        self.delegate = delegate;
        self.videoLayerView = sourceView;
        blurView = [self visualEffectsViewWithFrame:[[[UIApplication sharedApplication] delegate] window].bounds];
        [self.videoLayerView addSubview:blurView];
        [self setupSession];
    }
    return self;
}

- (void)selfDestruct{
}

#pragma mark - Internal methods

- (UIVisualEffectView *)visualEffectsViewWithFrame:(CGRect)frame{
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *newView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    newView.frame = frame;
    return newView;
}

- (void)setupSession{
    NSLog(@" %f, %f", _videoLayerView.frame.size.width, _videoPreviewLayer.frame.size.height);
    counter = 0;
    //Capture Session
    _captureSession = [[AVCaptureSession alloc]init];
    _captureSession.sessionPreset = AVCaptureSessionPresetPhoto; // full resolution of stream
    
    //Input
    currentInput = [AVCaptureDeviceInput deviceInputWithDevice:[self rearCamera] error:nil];
    if (!currentInput){
        if ([self.delegate respondsToSelector:@selector(cameraUtilityDidStartVideoOutput:)]){
            [self.delegate cameraUtilityDidStartVideoOutput:[NSError errorWithDomain:@"SHDCameraError" code:404 userInfo:@{@"description" : kNoAccessErrorDescription}]];
        }
        return;
    }
    
    [_captureSession addInput:currentInput];
    
    //Output
    //    _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    //    [_stillImageOutput setOutputSettings:outputSettings];
    //    [_captureSession addOutput:_stillImageOutput];
    
    // ADDED //
    _stillImageOutput = [[AVCaptureVideoDataOutput alloc] init];
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: kCVPixelFormatType_32BGRA] forKey: (id)kCVPixelBufferPixelFormatTypeKey];
    _stillImageOutput.videoSettings = outputSettings;
    [_captureSession addOutput:_stillImageOutput];
    
    dispatch_queue_t sampleQueue = dispatch_queue_create("SamppleQueue", NULL);
    [_stillImageOutput setSampleBufferDelegate: self queue: sampleQueue];
    
//    _stillImageOutput.minFrameDuration = CMTimeMake(1, 30);  // how to sample???
    
    // UNTIL HERE //
    
    //Preview Layer
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _videoPreviewLayer.frame = _videoLayerView.bounds;
    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResize;
    [self.videoLayerView.layer insertSublayer:_videoPreviewLayer atIndex:0];
    dispatch_queue_t algoQueue = dispatch_queue_create("AlgoQueue", NULL);
    
//    CGRect frameUpLeft = CGRectMake(0.0, 31.0, 21.0, 31.0);
//    CGRect frameUp = CGRectMake(21.0, 31.0, 333.0, 31.0);
//    CGRect frameUpRight = CGRectMake(354.0, 31.0, 21.0, 31.0);
//    CGRect frameLeft = CGRectMake(0.0, 479.0, 21.0, 448.0);
//    CGRect frameRight = CGRectMake(354.0, 479.0, 21.0, 448.0);
//    CGRect frameDownLeft = CGRectMake(0.0, 550.0, 21.0, 31.0);
//    CGRect frameDown = CGRectMake(21.0, 550.0, 333.0, 31.0);
//    CGRect frameDownRight = CGRectMake(354.0, 550.0, 21.0, 31.0);

    CGRect frameUpLeft1 = CGRectMake(0.0, 0.0, 94.0, 31.0);
    CGRect frameUpLeft2 = CGRectMake(0.0, 0.0, 21.0, 138.0);
    
    CGRect frameUp = CGRectMake(94.0, 0.0, 187.0, 31.0);
    
    CGRect frameUpRight1 = CGRectMake(281.0, 0.0, 94.0, 31.0);
    CGRect frameUpRight2 = CGRectMake(354.0, 0.0, 21.0, 138.0);
    
    CGRect frameLeft = CGRectMake(0.0, 138.0, 21.0, 247.0);
    
    CGRect frameRight = CGRectMake(354.0, 138.0, 21.0, 247.0);
    
    CGRect frameDownLeft1 = CGRectMake(0.0, 385.0, 21.0, 138.0);
    CGRect frameDownLeft2 = CGRectMake(0.0, 519.0, 94.0, 31.0);
    
    CGRect frameDown = CGRectMake(94.0, 519.0, 187.0, 31.0);
    
    CGRect frameDownRight1 = CGRectMake(354.0, 385.0, 21.0, 138.0);
    CGRect frameDownRight2 = CGRectMake(281.0, 519.0, 94.0, 31.0);

    
//    CGRect frame = CGRectMake(0.0, 500.0, 50.0, 50.0);
//    UIView* view = [[UIView alloc] initWithFrame:frame];
//    [view setBackgroundColor:[UIColor greenColor]];
//    [self.videoLayerView addSubview:view];


    
    viewUpLeft1 = [[UIView alloc] initWithFrame:frameUpLeft1];
    [viewUpLeft1 setBackgroundColor:[UIColor blackColor]];
    
    viewUpLeft2 = [[UIView alloc] initWithFrame:frameUpLeft2];
    [viewUpLeft2 setBackgroundColor:[UIColor blackColor]];
    
    viewUp = [[UIView alloc] initWithFrame:frameUp];
    [viewUp setBackgroundColor:[UIColor blackColor]];
    
    viewUpRight1 = [[UIView alloc] initWithFrame:frameUpRight1];
    [viewUpRight1 setBackgroundColor:[UIColor blackColor]];
    
    viewUpRight2 = [[UIView alloc] initWithFrame:frameUpRight2];
    [viewUpRight2 setBackgroundColor:[UIColor blackColor]];
    
    viewLeft = [[UIView alloc] initWithFrame:frameLeft];
    [viewLeft setBackgroundColor:[UIColor blackColor]];
    
    viewRight = [[UIView alloc] initWithFrame:frameRight];
    [viewRight setBackgroundColor:[UIColor blackColor]];
    
    viewDownLeft1 = [[UIView alloc] initWithFrame:frameDownLeft1];
    [viewDownLeft1 setBackgroundColor:[UIColor blackColor]];
    
    viewDownLeft2 = [[UIView alloc] initWithFrame:frameDownLeft2];
    [viewDownLeft2 setBackgroundColor:[UIColor blackColor]];
    
    viewDown = [[UIView alloc] initWithFrame:frameDown];
    [viewDown setBackgroundColor:[UIColor blackColor]];
    
    viewDownRight1 = [[UIView alloc] initWithFrame:frameDownRight1];
    [viewDownRight1 setBackgroundColor:[UIColor blackColor]];
    
    viewDownRight2 = [[UIView alloc] initWithFrame:frameDownRight2];
    [viewDownRight2 setBackgroundColor:[UIColor blackColor]];
    
    
//    UIView *view11 = [[UIView alloc] initWithFrame:frame11];
//    [view1 setBackgroundColor:[UIColor orangeColor]];
    
//    UIView *view2 = [[UIView alloc] initWithFrame:frame2];
//    [view2 setBackgroundColor:[UIColor orangeColor]];
    
//
//    UIView *view3 = [[UIView alloc] initWithFrame:frame3];
//    [view3 setBackgroundColor:[UIColor grayColor]];
    
//    [self.videoLayerView addSubview:view3];
//    [self.videoLayerView addSubview:view2];
//    [self.videoLayerView addSubview:view11];
    [self.videoLayerView addSubview:viewUpLeft1];
    [self.videoLayerView addSubview:viewUpLeft2];
    [self.videoLayerView addSubview:viewUp];
    [self.videoLayerView addSubview:viewUpRight1];
    [self.videoLayerView addSubview:viewUpRight2];
    [self.videoLayerView addSubview:viewLeft];
    [self.videoLayerView addSubview:viewRight];
    [self.videoLayerView addSubview:viewDownLeft1];
    [self.videoLayerView addSubview:viewDownLeft2];
    [self.videoLayerView addSubview:viewDown];
    [self.videoLayerView addSubview:viewDownRight1];
    [self.videoLayerView addSubview:viewDownRight2];



    //Start capture session
    [_captureSession startRunning];
    aTimer = CreateDispatchTimer(2ull,1ull,algoQueue, ^{ [self callingOurAlgo]; });

    busy = NO;
//    timer = [NSTimer scheduledTimerWithTimeInterval:2.0
//                                     target:self
//                                   selector:@selector(callingOurAlgo)
//                                   userInfo:nil
//                                    repeats:YES];
}

dispatch_source_t CreateDispatchTimer(uint64_t interval,
                                      uint64_t leeway,
                                      dispatch_queue_t queue,
                                      dispatch_block_t block)
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer)
    {
//        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 *NSEC_PER_SEC)), interval * NSEC_PER_SEC, leeway * NSEC_PER_SEC);
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval * NSEC_PER_SEC, leeway * NSEC_PER_SEC);
        
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}



// frontCamera, rearCamera - choose one of the camera
- (AVCaptureDevice *)frontCamera{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) return device;
    }
    return nil;
}

- (AVCaptureDevice *)rearCamera{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) return device;
    }
    return nil;
}

- (void)captureImage{
    [self blinkScreen];
    UIDeviceOrientation currentDeviceOrientation = UIDevice.currentDevice.orientation;
    float imgHeight = 666.0f; //Any according to requirement
    float imgWidth = 976.0f; //Any according to requirement
    CGRect cropRect = CGRectMake(21.0f, 31.0f ,imgWidth,imgHeight);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
    // or use the UIImage wherever you like
    UIImage *croppedImg = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    

    
    UIImage *resultingImage = [UIImage imageWithCGImage:[croppedImg CGImage] scale:[croppedImg scale] orientation:[self rotationNeededForImageCapturedWithDeviceOrientation:currentDeviceOrientation]];
    
    if ([self.delegate respondsToSelector:@selector(cameraUtilityDidTakePhoto:)]){
        [self.delegate cameraUtilityDidTakePhoto:resultingImage];
    }
}

// blur when switching between cameras
- (void)hideBlurViewAnimated:(BOOL)animated{
    CGFloat duration = 0.0;
    if (animated) duration = 1.0;
    
    [UIView animateWithDuration:duration animations:^{
        blurView.alpha = 0.0;
    }completion:^(BOOL finished){
        [blurView removeFromSuperview];
        blurView.alpha = 1.0;
    }];
}

// blink when taking a photo
- (void)blinkScreen{
    AppDelegate *appDel = (AppDelegate *)[UIApplication sharedApplication].delegate;
    UIView *wholeWhiteView = [[UIView alloc] initWithFrame:appDel.window.bounds];
    wholeWhiteView.backgroundColor = [UIColor whiteColor];
    [appDel.window addSubview:wholeWhiteView];
    
    [UIView animateWithDuration:0.2 animations:^{
        wholeWhiteView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [wholeWhiteView removeFromSuperview];
    }];
}

#pragma mark - External methods

-(void)finalizeLoadWithView:(UIView *)sourceView{
    _videoPreviewLayer.frame = sourceView.bounds;
    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResize;
    [self hideBlurViewAnimated:YES];
}

- (void)switchCameraPosition{
    [self.videoLayerView addSubview:blurView];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        AVCaptureDevice *desiredDevice = (currentInput.device.position == AVCaptureDevicePositionBack) ? [self frontCamera] : [self rearCamera];
        [self.captureSession beginConfiguration];
        currentInput = [AVCaptureDeviceInput deviceInputWithDevice:desiredDevice error:nil];
        if (currentInput){
            for (AVCaptureInput *oldInput in self.captureSession.inputs){
                [self.captureSession removeInput:oldInput];
            }
            [self.captureSession addInput:currentInput];
            [self.captureSession commitConfiguration];
        }else{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(cameraUtilityDidStartVideoOutput:)]){
                    [self.delegate cameraUtilityDidStartVideoOutput:[NSError errorWithDomain:@"SHDCameraError" code:404 userInfo:@{@"description" : kNoAccessErrorDescription}]];
                }
            });
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self hideBlurViewAnimated:YES];
        });
    });
}

- (void)switchFlash{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]){
        [device lockForConfiguration:nil];
        if (flashIsOn) {
            flashIsOn = NO;
            [device setTorchMode:AVCaptureTorchModeOff];
        }else{
            flashIsOn = YES;
            [device setTorchMode:AVCaptureTorchModeOn];
        }
        [device unlockForConfiguration];
    }
}

// here come algo!!! - need change to return algo's output
- (void)touchDown{
    canSavePicture = YES;
}

- (void)touchUp{
    if (canSavePicture){
        canSavePicture = NO;
        [self captureImage];
    }
}

// return the UIImageOrientation needed for an image captured with a specific deviceOrientation
- (UIImageOrientation)rotationNeededForImageCapturedWithDeviceOrientation:(UIDeviceOrientation)deviceOrientation{
    UIImageOrientation rotationOrientation;
    switch (deviceOrientation) {
        case UIDeviceOrientationPortraitUpsideDown: {
            rotationOrientation = UIImageOrientationLeft;
        } break;
            
        case UIDeviceOrientationLandscapeRight: {
            rotationOrientation = UIImageOrientationDown;
        } break;
            
        case UIDeviceOrientationLandscapeLeft: {
            rotationOrientation = UIImageOrientationUp;
        } break;
            
        case UIDeviceOrientationPortrait:
        default: {
            rotationOrientation = UIImageOrientationRight;
        } break;
    }
    return rotationOrientation;
}

// Delegate routine that is called when a sample buffer was written
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // Create a UIImage from the sample buffer data
    image = [self imageFromSampleBuffer:sampleBuffer];
    
//    NSLog(@"in capture");
//    NSLog(@"busy %i", busy);

    // add code here!
    
}

-(void) callingOurAlgo {

    NSLog(@"in algo");
    //TODO move?
    if (!busy)
    {
        busy = YES;
        cv::Mat img = [self cvMatFromUIImage];
        //double score = getScore(img);
        
        int zone = getImageScore(img); // from nofar
        
        NSString *msg;
        NSArray *buttons = nil;
        switch(zone)
        {
            case 0 :
                msg = @"UP LEFT";
                buttons = @[viewUpLeft1, viewUpLeft2];
                break;
            case 1 :
                msg = @"UP";
                buttons = @[viewUp];
                break;
            case 2 :
                msg = @"UP RIGHT";
                buttons = @[viewUpRight1, viewUpRight2];
                break;
            case 3 :
                msg = @"LEFT";
                buttons = @[viewLeft];
                break;
            case 4 :
                msg = @"STAY";
                break;
            case 5 :
                msg = @"RIGHT";
                buttons = @[viewRight];
                break;
            case 6 :
                msg = @"DOWN LEFT";
                buttons = @[viewDownLeft1, viewDownLeft2];
                break;
            case 7 :
                msg =@"DOWN";
                buttons = @[viewDown];
                break;
            case 8 :
                msg = @"DOWN RIGHT";
                buttons = @[viewDownRight1, viewDownRight2];
                break;
            default :
                msg = @"Invalid";
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            
            [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
                [UIView setAnimationRepeatCount:1];
                [buttons setValue:[UIColor whiteColor] forKey:@"backgroundColor"];
            } completion:^(BOOL finished){ [UIView animateWithDuration:0.5 delay:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [UIView setAnimationRepeatCount:1];
                [buttons setValue:[UIColor blackColor] forKey:@"backgroundColor"];
            } completion:nil];}];
            
//            [buttons setValue:[UIColor blackColor] forKey:@"backgroundColor"];
            
            
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"zone"
                                      message:msg
                                      delegate:nil
                                      cancelButtonTitle:nil
                                      otherButtonTitles:nil
                                      ];
            [alertView show];
            [self performSelector:@selector(dismissAlert:)
                       withObject:alertView
                       afterDelay:1.0
             ];

            
        });
        
        busy = NO;
    }
}

- (void)dismissAlert:(UIAlertView *)alertView
{
    [alertView dismissWithClickedButtonIndex:0 animated:YES];
}

// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

- (cv::Mat)cvMatFromUIImage
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits percomponent
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}



@end
