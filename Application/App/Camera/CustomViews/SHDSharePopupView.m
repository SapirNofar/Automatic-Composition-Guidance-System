#import "SHDSharePopupView.h"

@interface SHDSharePopupView ()
@property (weak, nonatomic) IBOutlet UIButton *btnDone;
@property (weak, nonatomic) IBOutlet UIView *photoSavedcontainerView;
@property (weak, nonatomic) IBOutlet UIView *shareContainerView;
@property (weak, nonatomic) IBOutlet UILabel *lblSharePrompt;

@end

@implementation SHDSharePopupView

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self == nil) return nil;
    [self initalizeSubviews];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self == nil) return nil;
    [self initalizeSubviews];
    return self;
}

- (void)initalizeSubviews{
    if (self.subviews.count == 0){
        NSString *nibName = NSStringFromClass([self class]);
        [[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
        self.bounds = self.container.bounds;
        [self addSubview:self.container];
        
        [self stretchToSuperView:self.container];
    }
}

// make picture bigger
- (void) stretchToSuperView:(UIView*) view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *bindings = NSDictionaryOfVariableBindings(view);
    NSString *formatTemplate = @"%@:|[view]|";
    for (NSString * axis in @[@"H",@"V"]) {
        NSString * format = [NSString stringWithFormat:formatTemplate,axis];
        NSArray * constraints = [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:nil views:bindings];
        [view.superview addConstraints:constraints];
    }
    [self.btnDone makeViewRoundWithLayerColor:nil andWidth:0.0 useHeight:YES];
}


#pragma mark - Button Actions

- (IBAction)sharePopupBtnDoneTapped:(id)sender{
    if ([self.delegate respondsToSelector:@selector(sharePopupBtnDoneTapped:)] && self.delegate !=nil){
        [self.delegate sharePopupBtnDoneTapped:self];
    }
}

@end
