#import "CBAppDelegate.h"
#import "CBRootViewController.h"
#import "CBSettingsViewController.h"
#import "CBDetailViewController.h"
#import "CBCleanManager.h"
#import "CBSettings.h"
#import "CBTheme.h"

@implementation CBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	(void)CBSettingsDefaults();
	self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];

	CBRootViewController *apps = [CBRootViewController new];
	self.appsNav = [[UINavigationController alloc] initWithRootViewController:apps];
	self.appsNav.navigationBar.prefersLargeTitles = YES;
	self.appsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"清理"
															image:[UIImage systemImageNamed:@"internaldrive"]
													selectedImage:[UIImage systemImageNamed:@"internaldrive.fill"]];

	CBSettingsViewController *settings = [[CBSettingsViewController alloc] initWithStyle:UITableViewStyleInsetGrouped];
	self.settingsNav = [[UINavigationController alloc] initWithRootViewController:settings];
	self.settingsNav.navigationBar.prefersLargeTitles = YES;
	self.settingsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"设置"
																image:[UIImage systemImageNamed:@"gearshape"]
														selectedImage:[UIImage systemImageNamed:@"gearshape.fill"]];

	self.tabBar = [[UITabBarController alloc] init];
	self.tabBar.viewControllers = @[self.appsNav, self.settingsNav];

	if (@available(iOS 15.0, *)) {
		// 系统材质导航：清晰可读，带轻微玻璃感，不做全透明脏糊
		UITabBarAppearance *tab = [UITabBarAppearance new];
		[tab configureWithDefaultBackground];
		self.tabBar.tabBar.standardAppearance = tab;
		self.tabBar.tabBar.scrollEdgeAppearance = tab;

		UINavigationBarAppearance *nav = [UINavigationBarAppearance new];
		[nav configureWithDefaultBackground];
		nav.shadowColor = UIColor.clearColor;
		nav.largeTitleTextAttributes = @{
			NSFontAttributeName: [UIFont systemFontOfSize:34 weight:UIFontWeightBold],
		};
		nav.titleTextAttributes = @{
			NSFontAttributeName: [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold],
		};
		// scroll edge 更通透一点
		UINavigationBarAppearance *scroll = [nav copy];
		[scroll configureWithTransparentBackground];
		scroll.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
		scroll.shadowColor = UIColor.clearColor;
		scroll.largeTitleTextAttributes = nav.largeTitleTextAttributes;
		scroll.titleTextAttributes = nav.titleTextAttributes;

		UINavigationBar.appearance.standardAppearance = nav;
		UINavigationBar.appearance.scrollEdgeAppearance = scroll;
		UINavigationBar.appearance.compactAppearance = nav;
		UINavigationBar.appearance.prefersLargeTitles = YES;
	}

	self.window.tintColor = CBTheme.accent;
	self.window.rootViewController = self.tabBar;
	[self.window makeKeyAndVisible];
	CBApplyAppearance();

	NSURL *url = launchOptions[UIApplicationLaunchOptionsURLKey];
	if (url) {
		dispatch_async(dispatch_get_main_queue(), ^{ [self handleURL:url]; });
	}
	return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
	return [self handleURL:url];
}

- (BOOL)handleURL:(NSURL *)url {
	if (!url) return NO;
	if (![url.scheme.lowercaseString isEqualToString:@"cleanbox"]) return NO;
	NSString *host = (url.host ?: @"").lowercaseString;
	NSURLComponents *c = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
	NSMutableDictionary *q = [NSMutableDictionary dictionary];
	for (NSURLQueryItem *item in c.queryItems) {
		if (item.name && item.value) q[item.name] = item.value;
	}
	NSString *bundle = q[@"bundle"] ?: q[@"id"];

	if ([host isEqualToString:@"settings"]) {
		self.tabBar.selectedIndex = 1;
		return YES;
	}
	if ([host isEqualToString:@"list"] || host.length == 0) {
		self.tabBar.selectedIndex = 0;
		[self.appsNav popToRootViewControllerAnimated:YES];
		return YES;
	}
	if (([host isEqualToString:@"app"] || [host isEqualToString:@"clean"]) && bundle.length) {
		CBAppInfo *info = [CBCleanManager.shared appInfoForBundleID:bundle];
		if (info) {
			self.tabBar.selectedIndex = 0;
			[self.appsNav popToRootViewControllerAnimated:NO];
			CBDetailViewController *vc = [[CBDetailViewController alloc] initWithApp:info];
			[self.appsNav pushViewController:vc animated:YES];
			return YES;
		}
	}
	return YES;
}

@end
