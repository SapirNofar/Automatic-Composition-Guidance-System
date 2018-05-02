#import "SHDCameraUtility.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreImage/CoreImage.h>
#import <UIKit/UIKitDefines.h>
#import <UIKit/UIColor.h>
#import <UIKit/UIGeometry.h>
#import "ImageUtils.h"
#import <CoreMotion/CoreMotion.h>
#import "JPSVolumeButtonHandler.h"
#import <MediaPlayer/MPVolumeView.h>

#define FACTOR 1./18
#define FACTORC 17./18
#define SHOW 8./9
#define NOSHOW 1./9


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
    UIView *viewDownn;
    UIView *viewRightt;
    UIView *viewLeftt;
    UIView *viewUpp;
    
    UIView *viewGridH1;
    UIView *viewGridH2;
    UIView *viewGridW1;
    UIView *viewGridW2;
    NSArray *grid;

    
    dispatch_group_t group;
    dispatch_queue_t fasaQueue;
    dispatch_queue_t lineQueue;
    CMMotionManager *motionManager;
    int w;
    int h;
    JPSVolumeButtonHandler *volumeButtonHandler;
    
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
        group = dispatch_group_create();
        fasaQueue = dispatch_queue_create("FASAQueue", NULL);
        lineQueue = dispatch_queue_create("LineQueue", NULL);
        CGRect rect = CGRectMake(-500, -500, 0, 0);
        MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame: rect];
        volumeView.showsRouteButton = NO;
        [self.videoLayerView addSubview: volumeView];
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

-(void) setupGyro{
    motionManager = [[CMMotionManager alloc] init];
    motionManager.accelerometerUpdateInterval = .1;
    motionManager.gyroUpdateInterval = .1;
    
    [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                                 [self outputAccelertionData:accelerometerData.acceleration];
                                                 if(error){
                                                     
                                                     NSLog(@"%@", error);
                                                 }
                                             }
     ];
    
    [motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue]
                                    withHandler:^(CMGyroData *gyroData, NSError *error) {
                                        [self outputRotationData:gyroData.rotationRate];
                                    }
     ];
}


-(void)outputAccelertionData:(CMAcceleration)acceleration
{
//    NSLog(@"accX: %.2fg",acceleration.x);
//
//    NSLog(@"accY: %.2fg",acceleration.y);
//
//    NSLog(@"accZ: %.2fg",acceleration.z);
}

-(void)outputRotationData:(CMRotationRate)rotation
{
//    NSLog(@"rotX: %.2fg",rotation.x);
//
//    NSLog(@"rotY: %.2fg",rotation.y);
//
//    NSLog(@"rotZ: %.2fg",rotation.z);
}

- (void) setupBorder{
    h = self.videoLayerView.bounds.size.height;
    w = self.videoLayerView.bounds.size.width;
  
    CGRect frameUpLeft1 = CGRectMake(0.0, 0.0, ceil(0.25*w), ceil(FACTOR*h));
    CGRect frameUpLeft2 = CGRectMake(0.0, 0.0, ceil(FACTOR*w), floor(0.25*h));

    CGRect frameUp = CGRectMake(floor(0.25*w), 0.0, ceil(0.5*w), ceil(FACTOR*h));

    CGRect frameUpRight1 = CGRectMake(floor(0.25*w)+ceil(0.5*w), 0.0, floor(0.25*w), ceil(FACTOR*h));
    CGRect frameUpRight2 = CGRectMake(floor(FACTORC*w), 0.0, ceil(FACTOR*w), floor(0.25*h));

    CGRect frameLeft = CGRectMake(0.0, floor(0.25*h), ceil(FACTOR*w), ceil(0.5*h));

    CGRect frameRight = CGRectMake(floor(FACTORC*w), floor(0.25*h), ceil(FACTOR*w), ceil(0.5*h));

    CGRect frameDownLeft1 = CGRectMake(0.0, floor(0.25*h)+ceil(0.5*h), ceil(FACTOR*w), ceil(0.25*h));
    CGRect frameDownLeft2 = CGRectMake(0.0, floor(FACTORC*h), floor(0.25*w), ceil(FACTOR*h));

    CGRect frameDown = CGRectMake(floor(0.25*w), floor(FACTORC*h), ceil(0.5*w), ceil(FACTOR*h));

    CGRect frameDownRight1 = CGRectMake(floor(FACTORC*w), floor(0.75*h), ceil(FACTOR*w), ceil(0.25*h));
    CGRect frameDownRight2 = CGRectMake(floor(0.25*w)+ceil(0.5*w), floor(FACTORC*h), ceil(0.25*w), ceil(FACTOR*h));

    float jump = 2.0;
    CGRect up =  CGRectMake(ceil(FACTOR*w) - jump, ceil(FACTOR*h) - jump, floor((8./9)*w) + 2*jump, jump);

    CGRect down =  CGRectMake(ceil(FACTOR*w) - jump, floor(FACTORC*h), floor((8./9)*w) + 2*jump, jump);

    CGRect right =  CGRectMake(floor(FACTORC*w), ceil(FACTOR*h) - jump, jump, floor((8./9)*h) + 2*jump);

    CGRect left =  CGRectMake(ceil(FACTOR*w) - jump, ceil(FACTOR*h) - jump, jump, floor((8./9)*h) + 2*jump);

    
//    CGRect frameUpLeft1 = CGRectMake(0.0, 0.0, 94.0, 31.0);
//    CGRect frameUpLeft2 = CGRectMake(0.0, 0.0, 21.0, 138.0);
//
//    CGRect frameUp = CGRectMake(94.0, 0.0, 187.0, 31.0);
//
//    CGRect frameUpRight1 = CGRectMake(281.0, 0.0, 94.0, 31.0);
//    CGRect frameUpRight2 = CGRectMake(354.0, 0.0, 21.0, 138.0);
//
//    CGRect frameLeft = CGRectMake(0.0, 138.0, 21.0, 247.0);
//
//    CGRect frameRight = CGRectMake(354.0, 138.0, 21.0, 247.0);
//
//    CGRect frameDownLeft1 = CGRectMake(0.0, 385.0, 21.0, 138.0);
//    CGRect frameDownLeft2 = CGRectMake(0.0, 519.0, 94.0, 31.0);
//
//    CGRect frameDown = CGRectMake(94.0, 519.0, 187.0, 31.0);
//
//    CGRect frameDownRight1 = CGRectMake(354.0, 385.0, 21.0, 138.0);
//    CGRect frameDownRight2 = CGRectMake(281.0, 519.0, 94.0, 31.0);
//
//    float jump = 2.0;
//    CGRect up =  CGRectMake(21.0 - jump, 31.0 - jump, 333.0 + 2*jump, jump);
//
//    CGRect down =  CGRectMake(21.0 - jump, 519.0, 333.0 + 2*jump, jump);
//
//    CGRect right =  CGRectMake(354.0, 31.0-jump, jump, 488.0 + 2*jump);
//
//    CGRect left =  CGRectMake(21.0 - jump, 31.0 - jump, jump, 488.0 + 2*jump);
    
    
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
    
    viewUpp = [[UIView alloc] initWithFrame:up];
    [viewUpp setBackgroundColor:[UIColor blackColor]];
    
    viewDownn = [[UIView alloc] initWithFrame:down];
    [viewDownn setBackgroundColor:[UIColor blackColor]];

    viewRightt = [[UIView alloc] initWithFrame:right];
    [viewRightt setBackgroundColor:[UIColor blackColor]];

    viewLeftt = [[UIView alloc] initWithFrame:left];
    [viewLeftt setBackgroundColor:[UIColor blackColor]];
    

    
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
    
    [self.videoLayerView addSubview:viewUpp];
    [self.videoLayerView addSubview:viewDownn];
    [self.videoLayerView addSubview:viewRightt];
    [self.videoLayerView addSubview:viewLeftt];
    



}

-(void) setupGrid{
    float i = w*SHOW / 3;
    float j = h*SHOW / 3;

    CGRect gridH1 = CGRectMake(FACTOR*w+i, FACTOR*h, 2, SHOW*h);
    CGRect gridH2 = CGRectMake(FACTOR*w+ 2*i, FACTOR*h, 2, SHOW*h);
    CGRect gridW1 = CGRectMake(FACTOR*w, FACTOR*w+j, SHOW*w, 2);
    CGRect gridW2 = CGRectMake(FACTOR*w, FACTOR*w+ 2*j, SHOW*w, 2);

    viewGridH1 = [[UIView alloc] initWithFrame:gridH1];
    viewGridH2 = [[UIView alloc] initWithFrame:gridH2];
    viewGridW1 = [[UIView alloc] initWithFrame:gridW1];
    viewGridW2 = [[UIView alloc] initWithFrame:gridW2];
    
    grid = @[viewGridH1, viewGridH2, viewGridW1, viewGridW2];

    [grid setValue:[UIColor grayColor] forKey:@"backgroundColor"];
    [grid setValue:[NSNumber numberWithFloat:0.5] forKey:@"alpha"];
    [grid setValue: [NSNumber numberWithBool:YES] forKey:@"hidden"];

    
    [self.videoLayerView addSubview:viewGridH1];
    [self.videoLayerView addSubview:viewGridH2];
    [self.videoLayerView addSubview:viewGridW1];
    [self.videoLayerView addSubview:viewGridW2];


}

-(void) showGrid
{
    [grid setValue: [NSNumber numberWithBool:NO] forKey:@"hidden"];
}

-(void) hideGrid
{
    [grid setValue: [NSNumber numberWithBool:YES] forKey:@"hidden"];
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
    
//    _stiloulImageOutput.minFrameDuration = CMTimeMake(1, 30);  // how to sample???
    
    // UNTIL HERE //
    
    //Preview Layer
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _videoPreviewLayer.frame = _videoLayerView.bounds;
    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
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

    volumeButtonHandler = [JPSVolumeButtonHandler volumeButtonHandlerWithUpBlock:^{
        // Volume Up Button Pressed
        NSLog(@"+++++++++++++++++++++++++++++++++++++++");
        [self showGrid];

    } downBlock:^{
        // Volume Down Button Pressed
        NSLog(@"---------------------------------------");
        [self hideGrid];

    }];
    
    [volumeButtonHandler startHandler:YES];


    //Start capture session
    [_captureSession startRunning];
    aTimer = CreateDispatchTimer(2ull,1ull,algoQueue, ^{ [self callingOurAlgo]; });
    [self setupBorder];
    [self setupGyro];
    [self setupGrid];
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
    CGRect cropRect = CGRectMake(FACTOR*w, FACTOR*h ,imgWidth,imgHeight);
    
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
    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
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
    image = nil;
    // Create a UIImage from the sample buffer data here!!!!!!!! take care
//    NSLog(@"in capture");

    image = [self imageFromSampleBuffer:sampleBuffer];
//    NSLog(@"in capture");

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

        cv::Mat img = [ImageUtils cvMatFromUIImage:image];
        //double score = getScore(img);
        NSArray *borders = @[viewUpp, viewLeftt, viewRightt, viewDownn];

        dispatch_sync(dispatch_get_main_queue(), ^{

            [borders setValue:[UIColor yellowColor] forKey:@"backgroundColor"];

//            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionRepeat animations:^{
//                [UIView setAnimationRepeatCount:1];
//                [borders setValue:[UIColor blackColor] forKey:@"backgroundColor"];
//
//            } completion:nil];
        });

        int zone = getImageScore(img, group, fasaQueue, lineQueue); // from nofar
        NSLog(@"finished algo");
        img.release();
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
                buttons = @[viewUpLeft1, viewUpLeft2, viewUp, viewUpRight1, viewUpRight2, viewLeft, viewRight, viewDownLeft1, viewDownLeft2, viewDown, viewDownRight1, viewDownRight2];

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

        dispatch_sync(dispatch_get_main_queue(), ^{
            [borders setValue:[UIColor blackColor] forKey:@"backgroundColor"];
            [UIView animateWithDuration:0.2 delay:0.15 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
                [UIView setAnimationRepeatCount:1];
                [buttons setValue:[UIColor whiteColor] forKey:@"backgroundColor"];
            } completion:^(BOOL finished){ [UIView animateWithDuration:0.2 delay:0.1 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [UIView setAnimationRepeatCount:1];
                [buttons setValue:[UIColor blackColor] forKey:@"backgroundColor"];
            } completion:nil];}];
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
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Create an image object from the Quartz image
    UIImage *im = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    
    return im;
}



@end
