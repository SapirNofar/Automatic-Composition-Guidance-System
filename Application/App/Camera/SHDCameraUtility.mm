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
    
    dispatch_queue_t queue = dispatch_queue_create("Queue", NULL);
    [_stillImageOutput setSampleBufferDelegate: self queue: queue];
    
//    _stillImageOutput.minFrameDuration = CMTimeMake(1, 30);  // how to sample???
    
    // UNTIL HERE //
    
    //Preview Layer
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _videoPreviewLayer.frame = _videoLayerView.bounds;
    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.videoLayerView.layer insertSublayer:_videoPreviewLayer atIndex:0];
    
    //Start capture session
    [_captureSession startRunning];
    timer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                     target:self
                                   selector:@selector(callingOurAlgo)
                                   userInfo:nil
                                    repeats:YES];
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
    //    AVCaptureConnection *videoConnection = nil;
    //    for (AVCaptureConnection *connection in _stillImageOutput.connections)
    //    {
    //        for (AVCaptureInputPort *port in [connection inputPorts])
    //        {
    //            if ([[port mediaType] isEqual:AVMediaTypeVideo])
    //            {
    //                videoConnection = connection;
    //                break;
    //            }
    //        }
    //        if (videoConnection) { break; }
    //    }
    
    //    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error){
    //        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
    //        if (!imageData){
    //            //Error here! (wow!)
    //            return;
    //        }
    //
    //        UIImage *resultingImage = [UIImage imageWithData:imageData];
    //        resultingImage = [UIImage imageWithCGImage:[resultingImage CGImage] scale:[resultingImage scale] orientation:[self rotationNeededForImageCapturedWithDeviceOrientation:currentDeviceOrientation]];
    //
    //    //Save picture here (delegate)
    //        if ([self.delegate respondsToSelector:@selector(cameraUtilityDidTakePhoto:)]){
    //            [self.delegate cameraUtilityDidTakePhoto:resultingImage];
    //        }
    //    }];
    
    UIImage *resultingImage = [UIImage imageWithCGImage:[image CGImage] scale:[image scale] orientation:[self rotationNeededForImageCapturedWithDeviceOrientation:currentDeviceOrientation]];
    
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
    // Create a UIImage from the sample buffer data
    image = [self imageFromSampleBuffer:sampleBuffer];
    
//    NSLog(@"in capture");

    // add code here!
    
}

-(void) callingOurAlgo {
    for(int i = 0; i < 10000; i++)
    {
        //
    }

    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"title"
                              message:@"message"
                              delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:nil
                              ];
    [alertView show];
    [self performSelector:@selector(dismissAlert:)
               withObject:alertView
               afterDelay:5.0
     ];
//    NSLog(@"the %i time", counter);
//    counter ++;
    
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





@end

