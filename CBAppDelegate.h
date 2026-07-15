#import <UIKit/UIKit.h>
@interface CBAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UITabBarController *tabBar;
@property (nonatomic, strong) UINavigationController *appsNav;
@property (nonatomic, strong) UINavigationController *settingsNav;
@end
