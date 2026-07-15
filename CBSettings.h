#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString * const CBSettingConfirmBeforeClean;
FOUNDATION_EXPORT NSString * const CBSettingKillBeforeClean;
FOUNDATION_EXPORT NSString * const CBSettingCleanWebKit;
FOUNDATION_EXPORT NSString * const CBSettingCleanHTTPStorages;
FOUNDATION_EXPORT NSString * const CBSettingCleanGroupCaches;
FOUNDATION_EXPORT NSString * const CBSettingShowSystemApps;
FOUNDATION_EXPORT NSString * const CBSettingShowUserApps;
FOUNDATION_EXPORT NSString * const CBSettingAppearance; // system|light|dark
/// name | size | reclaimable | type
FOUNDATION_EXPORT NSString * const CBSettingSortMode;
/// 1 = descending (大到小 / Z-A), 0 = ascending
FOUNDATION_EXPORT NSString * const CBSettingSortDescending;

FOUNDATION_EXPORT NSUserDefaults *CBSettingsDefaults(void);
FOUNDATION_EXPORT BOOL CBSettingsBool(NSString *key);
FOUNDATION_EXPORT NSString *CBSettingsString(NSString *key);
FOUNDATION_EXPORT void CBApplyAppearance(void);
