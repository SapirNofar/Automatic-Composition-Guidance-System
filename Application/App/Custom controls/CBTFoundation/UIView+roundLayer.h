#import <UIKit/UIKit.h>

@interface UIView (roundLayer)

- (void)makeViewRoundWithLayerColor:(UIColor *)color andWidth:(CGFloat)lineWidth;

- (void)makeViewRoundWithLayerColor:(UIColor *)color andWidth:(CGFloat)lineWidth useHeight:(BOOL)useH;

- (void)drawViewLayerWithLayerColor:(UIColor *)color andWidth:(CGFloat)lineWidth andCornerRadius:(CGFloat)radius;

@end
