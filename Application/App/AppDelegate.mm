#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

// return bool, name func application, gets UIApplication* and NSDictionary*
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[UIApplication sharedApplication] setStatusBarHidden:YES]; // hide top status bar

    UIStoryboard *mainStroyboard = [UIStoryboard storyboardWithName:kCameraStoryboardName bundle:nil];
    UIViewController *tmpVC = [mainStroyboard instantiateInitialViewController];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = tmpVC;
    [self.window makeKeyAndVisible];

    return YES;
}

@end
