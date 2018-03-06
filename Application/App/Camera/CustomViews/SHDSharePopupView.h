#import <UIKit/UIKit.h>

@class SHDSharePopupView;

@protocol SHDSharePopupViewDelegate <NSObject>

- (void)sharePopupBtnDoneTapped:(SHDSharePopupView *)senderView;

@end

@interface SHDSharePopupView : UIView
@property (nonatomic, weak) id <SHDSharePopupViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIView *container;

@end
