#import "CBSettings.h"

NSString * const CBSettingConfirmBeforeClean = @"confirmBeforeClean";
NSString * const CBSettingKillBeforeClean = @"killBeforeClean";
NSString * const CBSettingCleanWebKit = @"cleanWebKit";
NSString * const CBSettingCleanHTTPStorages = @"cleanHTTPStorages";
NSString * const CBSettingCleanGroupCaches = @"cleanGroupCaches";
NSString * const CBSettingShowSystemApps = @"showSystemApps";
NSString * const CBSettingShowUserApps = @"showUserApps";
NSString * const CBSettingAppearance = @"appearance";
NSString * const CBSettingSortMode = @"sortMode";
NSString * const CBSettingSortDescending = @"sortDescending";

NSUserDefaults *CBSettingsDefaults(void) {
	static NSUserDefaults *ud;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		ud = [[NSUserDefaults alloc] initWithSuiteName:@"com.o2ol.cleanbox.settings"];
		[ud registerDefaults:@{
			CBSettingConfirmBeforeClean: @YES,
			CBSettingKillBeforeClean: @YES,
			CBSettingCleanWebKit: @NO,
			CBSettingCleanHTTPStorages: @NO,
			CBSettingCleanGroupCaches: @YES,
			CBSettingShowSystemApps: @YES,
			CBSettingShowUserApps: @YES,
			CBSettingAppearance: @"system",
			CBSettingSortMode: @"size",
			CBSettingSortDescending: @YES,
		}];
	});
	return ud;
}

BOOL CBSettingsBool(NSString *key) {
	return [CBSettingsDefaults() boolForKey:key];
}

NSString *CBSettingsString(NSString *key) {
	return [CBSettingsDefaults() stringForKey:key] ?: @"";
}

void CBApplyAppearance(void) {
	NSString *mode = CBSettingsString(CBSettingAppearance);
	UIUserInterfaceStyle style = UIUserInterfaceStyleUnspecified;
	if ([mode isEqualToString:@"light"]) style = UIUserInterfaceStyleLight;
	else if ([mode isEqualToString:@"dark"]) style = UIUserInterfaceStyleDark;
	for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
		if (![scene isKindOfClass:UIWindowScene.class]) continue;
		for (UIWindow *w in ((UIWindowScene *)scene).windows) {
			w.overrideUserInterfaceStyle = style;
		}
	}
	UIWindow *key = UIApplication.sharedApplication.windows.firstObject;
	if (key) key.overrideUserInterfaceStyle = style;
}
