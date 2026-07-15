#import "CBCleanManager.h"
#import "CBSettings.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation CBAppInfo
@end

@implementation CBCategoryStat
@end

@interface CBCleanManager ()
@end

@implementation CBCleanManager

+ (instancetype)shared {
	static CBCleanManager *s;
	static dispatch_once_t once;
	dispatch_once(&once, ^{ s = [self new]; });
	return s;
}

/// 必须是绝对路径且像 App 容器，避免相对路径落到净匣自己的目录 → 所有 App 显示同一体积
- (BOOL)isValidContainerPath:(NSString *)path {
	if (path.length < 12) return NO;
	if (![path hasPrefix:@"/"]) return NO;
	if ([path hasPrefix:@"/var/"] || [path hasPrefix:@"/private/var/"] || [path hasPrefix:@"/Users/"]) return YES;
	// 其它绝对路径也允许，但拒绝明显相对/异常
	if ([path containsString:@".."]) return NO;
	return YES;
}

- (NSString *)absoluteExistingPath:(NSString *)path {
	if (![self isValidContainerPath:path]) return nil;
	BOOL isDir = NO;
	if (![NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDir]) return nil;
	return path;
}


#pragma mark - LS helpers

- (Class)workspaceClass { return NSClassFromString(@"LSApplicationWorkspace"); }
- (Class)proxyClass { return NSClassFromString(@"LSApplicationProxy"); }

- (UIImage *)roundedIcon:(UIImage *)img size:(CGFloat)side {
	if (!img) return nil;
	CGFloat scale = UIScreen.mainScreen.scale;
	CGSize sz = CGSizeMake(side, side);
	UIGraphicsBeginImageContextWithOptions(sz, NO, scale);
	UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, side, side) cornerRadius:side * 0.2237];
	[path addClip];
	[img drawInRect:CGRectMake(0, 0, side, side)];
	UIImage *out = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return out ?: img;
}

- (UIImage *)iconFromBundlePath:(NSString *)bundlePath {
	// 轻量：只试 Info.plist 声明的几个名字，禁止全包递归（会卡死）
	if (!bundlePath.length) return nil;
	NSFileManager *fm = NSFileManager.defaultManager;
	NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[bundlePath stringByAppendingPathComponent:@"Info.plist"]];
	NSMutableArray *tryList = [NSMutableArray array];
	NSArray *iconFiles = info[@"CFBundleIcons"][@"CFBundlePrimaryIcon"][@"CFBundleIconFiles"];
	if (![iconFiles isKindOfClass:NSArray.class]) iconFiles = info[@"CFBundleIconFiles"];
	if ([iconFiles isKindOfClass:NSArray.class]) {
		for (NSString *base in iconFiles) {
			if (![base isKindOfClass:NSString.class]) continue;
			[tryList addObject:[base stringByAppendingString:@"@3x.png"]];
			[tryList addObject:[base stringByAppendingString:@"@2x.png"]];
			[tryList addObject:[base stringByAppendingString:@".png"]];
			[tryList addObject:base];
		}
	}
	NSString *one = info[@"CFBundleIconFile"];
	if ([one isKindOfClass:NSString.class]) {
		[tryList addObject:one];
		[tryList addObject:[one stringByAppendingString:@".png"]];
		[tryList addObject:[one stringByAppendingString:@"@2x.png"]];
	}
	[tryList addObjectsFromArray:@[
		@"AppIcon60x60@3x.png", @"AppIcon60x60@2x.png",
		@"Icon-60@3x.png", @"Icon-60@2x.png", @"Icon@2x.png", @"Icon.png"
	]];
	// 最多尝试 20 个路径
	NSInteger n = 0;
	for (NSString *name in tryList) {
		if (++n > 20) break;
		NSString *p = [bundlePath stringByAppendingPathComponent:name];
		if ([fm fileExistsAtPath:p]) {
			UIImage *img = [UIImage imageWithContentsOfFile:p];
			if (img) return [self roundedIcon:img size:58];
		}
	}
	return nil;
}

- (UIImage *)iconForProxy:(id)proxy {
	@try {
		// 1) private icon data
		for (NSString *selName in @[@"iconDataForVariant:", @"iconDataForVariant:withOptions:"]) {
			SEL sel = NSSelectorFromString(selName);
			if (![proxy respondsToSelector:sel]) continue;
			NSData *data = nil;
			if ([selName isEqualToString:@"iconDataForVariant:"]) {
				data = ((id (*)(id, SEL, NSInteger))objc_msgSend)(proxy, sel, 2);
			} else {
				data = ((id (*)(id, SEL, NSInteger, NSInteger))objc_msgSend)(proxy, sel, 2, 0);
			}
			if ([data isKindOfClass:NSData.class] && data.length > 100) {
				UIImage *img = [UIImage imageWithData:data scale:UIScreen.mainScreen.scale];
				if (img) return [self roundedIcon:img size:58];
			}
		}
	} @catch (__unused NSException *e) {}

	NSURL *bundleURL = [self urlProp:proxy sel:@selector(bundleURL)];
	UIImage *fromBundle = [self iconFromBundlePath:bundleURL.path];
	if (fromBundle) return fromBundle;
	return nil;
}

- (unsigned long long)ullProp:(id)obj selName:(NSString *)selName {
	SEL sel = NSSelectorFromString(selName);
	if (!obj || ![obj respondsToSelector:sel]) return 0;
	@try {
		// 优先当对象取 NSNumber（LS 的 diskUsage 是 NSNumber*）
		id v = ((id (*)(id, SEL))objc_msgSend)(obj, sel);
		if ([v isKindOfClass:NSNumber.class]) {
			unsigned long long u = [v unsignedLongLongValue];
			// 过滤异常：> 512GB 当无效
			if (u > (512ULL * 1024 * 1024 * 1024)) return 0;
			return u;
		}
	} @catch (__unused NSException *e) {}
	return 0;
}

- (NSString *)stringProp:(id)obj sel:(SEL)sel {
	if (![obj respondsToSelector:sel]) return nil;
	id v = ((id (*)(id, SEL))objc_msgSend)(obj, sel);
	return [v isKindOfClass:NSString.class] ? v : nil;
}

- (NSURL *)urlProp:(id)obj sel:(SEL)sel {
	if (![obj respondsToSelector:sel]) return nil;
	id v = ((id (*)(id, SEL))objc_msgSend)(obj, sel);
	if ([v isKindOfClass:NSURL.class]) return v;
	if ([v isKindOfClass:NSString.class]) return [NSURL fileURLWithPath:v];
	return nil;
}

- (void)fillGroups:(CBAppInfo *)info fromProxy:(id)proxy {
	NSMutableDictionary *groups = [NSMutableDictionary dictionary];
	if ([proxy respondsToSelector:NSSelectorFromString(@"groupContainerURLs")]) {
		NSDictionary *g = ((id (*)(id, SEL))objc_msgSend)(proxy, NSSelectorFromString(@"groupContainerURLs"));
		if ([g isKindOfClass:NSDictionary.class]) {
			[g enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				NSString *gid = [key isKindOfClass:NSString.class] ? key : [key description];
				NSString *path = nil;
				if ([obj isKindOfClass:NSURL.class]) path = [(NSURL *)obj path];
				else if ([obj isKindOfClass:NSString.class]) path = obj;
				if (gid.length && path.length) groups[gid] = path;
			}];
		}
	}
	info.groupPaths = groups.count ? [groups copy] : nil;
}

- (BOOL)isSystemProxy:(id)proxy bundlePath:(NSString *)bundlePath appType:(NSString *)appType {
	if ([appType.lowercaseString isEqualToString:@"system"]) return YES;
	if ([bundlePath hasPrefix:@"/Applications/"] || [bundlePath hasPrefix:@"/private/var/staged_system_apps/"] ||
		[bundlePath hasPrefix:@"/System/"] || [bundlePath containsString:@"/System/Library/CoreServices/"]) {
		return YES;
	}
	// user apps typically under Containers/Bundle/Application
	if ([bundlePath containsString:@"/Containers/Bundle/Application/"]) return NO;
	// default: treat com.apple.* as system-ish
	NSString *bid = [self stringProp:proxy sel:@selector(applicationIdentifier)];
	if ([bid hasPrefix:@"com.apple."]) return YES;
	return NO;
}


- (void)loadIconForApp:(CBAppInfo *)app {
	if (!app || app.icon) return;
	@try {
		Class proxyCls = [self proxyClass];
		id proxy = nil;
		if (proxyCls && [proxyCls respondsToSelector:NSSelectorFromString(@"applicationProxyForIdentifier:")]) {
			proxy = ((id (*)(id, SEL, id))objc_msgSend)(proxyCls, NSSelectorFromString(@"applicationProxyForIdentifier:"), app.bundleID);
		}
		UIImage *img = proxy ? [self iconForProxy:proxy] : [self iconFromBundlePath:app.bundlePath];
		if (img) app.icon = img;
	} @catch (__unused NSException *e) {}
}

- (void)ensureGroupsForApp:(CBAppInfo *)app {
	if (!app || app.groupPaths.count) return;
	@try {
		Class proxyCls = [self proxyClass];
		if (!proxyCls || ![proxyCls respondsToSelector:NSSelectorFromString(@"applicationProxyForIdentifier:")]) return;
		id proxy = ((id (*)(id, SEL, id))objc_msgSend)(proxyCls, NSSelectorFromString(@"applicationProxyForIdentifier:"), app.bundleID);
		if (proxy) [self fillGroups:app fromProxy:proxy];
	} @catch (__unused NSException *e) {}
}

- (NSArray<CBAppInfo *> *)listApps {
	NSMutableArray<CBAppInfo *> *result = [NSMutableArray array];
	Class wsClass = [self workspaceClass];
	if (!wsClass) return result;
	id ws = ((id (*)(id, SEL))objc_msgSend)(wsClass, @selector(defaultWorkspace));
	NSArray *apps = nil;
	if ([ws respondsToSelector:NSSelectorFromString(@"allInstalledApplications")]) {
		apps = ((id (*)(id, SEL))objc_msgSend)(ws, NSSelectorFromString(@"allInstalledApplications"));
	}
	if (!apps.count) return result;

	NSString *selfID = NSBundle.mainBundle.bundleIdentifier ?: @"com.o2ol.cleanbox";
	BOOL showSystem = CBSettingsBool(CBSettingShowSystemApps);
	BOOL showUser = CBSettingsBool(CBSettingShowUserApps);

	for (id proxy in apps) {
		@autoreleasepool {
			NSString *bid = [self stringProp:proxy sel:@selector(applicationIdentifier)];
			if (!bid.length || [bid isEqualToString:selfID]) continue;
			// skip hidden placeholders
			if ([bid hasPrefix:@"com.apple.webapp"] ) continue;

			NSString *name = [self stringProp:proxy sel:@selector(localizedName)] ?: bid;
			NSURL *dataURL = [self urlProp:proxy sel:@selector(dataContainerURL)];
			if (!dataURL) dataURL = [self urlProp:proxy sel:@selector(containerURL)];
			NSString *dataPath = dataURL.path;
			if (![self isValidContainerPath:dataPath]) {
				continue;
			}

			NSURL *bundleURL = [self urlProp:proxy sel:@selector(bundleURL)];
			NSString *bundlePath = bundleURL.path;
			NSString *appType = [self stringProp:proxy sel:@selector(applicationType)];
			BOOL isSystem = [self isSystemProxy:proxy bundlePath:bundlePath appType:appType];

			if (isSystem && !showSystem) continue;
			if (!isSystem && !showUser) continue;

			CBAppInfo *info = [CBAppInfo new];
			info.bundleID = bid;
			info.name = name;
			info.dataPath = dataPath;
			info.bundlePath = bundlePath;
			info.appType = appType.length ? appType : (isSystem ? @"System" : @"User");
			info.isSystem = isSystem;
			// 列表阶段不读图标、不扫 Group（避免启动卡死）；占用只用系统 API
			info.icon = nil;
			info.groupPaths = nil;
			unsigned long long dyn = [self ullProp:proxy selName:@"dynamicDiskUsage"];
			if (!dyn) dyn = [self ullProp:proxy selName:@"diskUsage"];
			unsigned long long sta = [self ullProp:proxy selName:@"staticDiskUsage"];
			info.staticDiskBytes = sta;
			if (dyn > 0) {
				info.totalContainerBytes = dyn;
			}
			// fileExists 在部分路径上很慢，已有 dataContainerURL 就信任
			[result addObject:info];
		}
	}

	[result sortUsingComparator:^NSComparisonResult(CBAppInfo *a, CBAppInfo *b) {
		return [a.name localizedStandardCompare:b.name];
	}];
	return result;
}

- (CBAppInfo *)appInfoForBundleID:(NSString *)bundleID {
	for (CBAppInfo *a in [self listApps]) {
		if ([a.bundleID isEqualToString:bundleID]) return a;
	}
	return nil;
}

#pragma mark - Size / delete

- (unsigned long long)directorySizePublic:(NSString *)path {
	return [self directorySize:path maxFiles:0]; // 0 = unlimited (清理/扫描可清理目录用)
}

- (unsigned long long)directorySizeApprox:(NSString *)path {
	// 列表补测用：最多 8000 个文件，防止微信等容器把 App 卡死
	return [self directorySize:path maxFiles:8000];
}

- (unsigned long long)directorySize:(NSString *)path {
	return [self directorySize:path maxFiles:0];
}

- (BOOL)isLoginRiskName:(NSString *)name {
	if (!name.length) return NO;
	NSString *low = name.lowercaseString;
	if ([low isEqualToString:@"webkit"] || [low hasPrefix:@"com.apple.webkit"] || [low containsString:@"webkit"]) return YES;
	if ([low isEqualToString:@"cookies"] || [low isEqualToString:@"credentials"] || [low isEqualToString:@"httpstorages"]) return YES;
	if ([low containsString:@"account"] || [low containsString:@"login"] || [low containsString:@"session"] || [low containsString:@"token"]) return YES;
	return NO;
}

- (unsigned long long)directorySize:(NSString *)path maxFiles:(NSInteger)maxFiles {
	return [self directorySize:path maxFiles:maxFiles skipLoginRisk:NO];
}

/// skipLoginRisk=YES：统计/清理口径一致，Caches 内跳过 WebKit 等
- (unsigned long long)directorySize:(NSString *)path maxFiles:(NSInteger)maxFiles skipLoginRisk:(BOOL)skipLoginRisk {
	if (!path.length) return 0;
	NSFileManager *fm = NSFileManager.defaultManager;
	BOOL isDir = NO;
	if (![fm fileExistsAtPath:path isDirectory:&isDir]) return 0;
	if (!isDir) {
		NSNumber *sz = nil;
		NSURL *u = [NSURL fileURLWithPath:path];
		[u getResourceValue:&sz forKey:NSURLFileSizeKey error:nil];
		return sz.unsignedLongLongValue;
	}

	// Caches 顶层：按子项统计，跳过掉登录目录
	BOOL isCachesDir = [path.lastPathComponent isEqualToString:@"Caches"] || [path hasSuffix:@"/Library/Caches"];
	if (skipLoginRisk && isCachesDir) {
		unsigned long long total = 0;
		NSArray *children = [fm contentsOfDirectoryAtPath:path error:nil];
		for (NSString *name in children ?: @[]) {
			@autoreleasepool {
				if ([self isLoginRiskName:name]) continue;
				NSString *full = [path stringByAppendingPathComponent:name];
				total += [self directorySize:full maxFiles:maxFiles skipLoginRisk:YES];
			}
		}
		return total;
	}

	NSURL *root = [NSURL fileURLWithPath:path isDirectory:YES];
	NSArray *keys = @[NSURLIsRegularFileKey, NSURLFileSizeKey];
	NSDirectoryEnumerator *en = [fm enumeratorAtURL:root
	                     includingPropertiesForKeys:keys
	                                        options:(NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants)
	                                   errorHandler:^BOOL(NSURL *url, NSError *error) { return YES; }];
	unsigned long long total = 0;
	NSInteger count = 0;
	for (NSURL *fileURL in en) {
		@autoreleasepool {
			if (maxFiles > 0 && ++count > maxFiles) break;
			if (skipLoginRisk) {
				NSString *p = fileURL.path ?: @"";
				if ([p.lowercaseString containsString:@"/webkit"] || [p.lowercaseString containsString:@"/httpstorages"] || [p.lowercaseString containsString:@"/cookies"]) {
					continue;
				}
			}
			NSNumber *isReg = nil;
			[fileURL getResourceValue:&isReg forKey:NSURLIsRegularFileKey error:nil];
			if (!isReg.boolValue) continue;
			NSNumber *sz = nil;
			[fileURL getResourceValue:&sz forKey:NSURLFileSizeKey error:nil];
			total += sz.unsignedLongLongValue;
		}
	}
	return total;
}

- (unsigned long long)cleanableSizeAtPath:(NSString *)path {
	return [self directorySize:path maxFiles:0 skipLoginRisk:YES];
}

- (unsigned long long)deleteContentsOfDirectory:(NSString *)path keepDirectory:(BOOL)keep error:(NSError **)error {
	NSFileManager *fm = NSFileManager.defaultManager;
	BOOL isDir = NO;
	if (![fm fileExistsAtPath:path isDirectory:&isDir]) return 0;
	unsigned long long freed = 0;
	if (!isDir) {
		freed = [self directorySize:path];
		[fm removeItemAtPath:path error:error];
		return freed;
	}
	NSArray *children = [fm contentsOfDirectoryAtPath:path error:nil];
	// 清 Caches 时跳过可能含会话的子目录
	BOOL isCachesDir = [path.lastPathComponent isEqualToString:@"Caches"] || [path hasSuffix:@"/Library/Caches"];
	for (NSString *name in children) {
		@autoreleasepool {
			if ([name isEqualToString:@".com.apple.mobile_container_manager.metadata.plist"]) continue;
			if (isCachesDir && [self isLoginRiskName:name]) continue;
			NSString *full = [path stringByAppendingPathComponent:name];
			unsigned long long sz = [self directorySize:full];
			NSError *e = nil;
			if ([fm removeItemAtPath:full error:&e]) {
				freed += sz;
			}
		}
	}
	if (!keep) {
		[fm removeItemAtPath:path error:nil];
	}
	return freed;
}

- (unsigned long long)deletePathIfExists:(NSString *)path {
	if (!path.length) return 0;
	if (![NSFileManager.defaultManager fileExistsAtPath:path]) return 0;
	unsigned long long sz = [self directorySize:path];
	NSError *e = nil;
	if ([NSFileManager.defaultManager removeItemAtPath:path error:&e]) return sz;
	// fallback: clear contents
	return [self deleteContentsOfDirectory:path keepDirectory:YES error:nil];
}

#pragma mark - Categories

- (NSString *)titleForCategory:(CBCleanCategory)cat {
	switch (cat) {
		case CBCleanCategoryCaches: return @"缓存 Caches";
		case CBCleanCategoryTmp: return @"临时文件 tmp";
		case CBCleanCategoryLogs: return @"日志 Logs";
		case CBCleanCategoryWebKit: return @"WebKit 网站数据";
		case CBCleanCategoryHTTPStorages: return @"HTTP 存储";
		case CBCleanCategorySnapshots: return @"快照 / 状态";
		case CBCleanCategoryGroupCaches: return @"App Group 缓存";
		default: return @"未知";
	}
}

- (NSArray<NSString *> *)relativePathsForCategory:(CBCleanCategory)cat {
	switch (cat) {
		case CBCleanCategoryCaches:
			return @[@"Library/Caches"];
		case CBCleanCategoryTmp:
			return @[@"tmp"];
		case CBCleanCategoryLogs:
			return @[@"Library/Logs", @"Library/Caches/Logs"];
		case CBCleanCategoryWebKit:
			return @[@"Library/WebKit", @"Library/Caches/WebKit", @"Library/Caches/com.apple.WebKit.Networking", @"Library/Caches/com.apple.WebKit.WebContent"];
		case CBCleanCategoryHTTPStorages:
			return @[@"Library/HTTPStorages"];
		case CBCleanCategorySnapshots:
			return @[@"Library/SplashBoard", @"Library/Saved Application State", @"Library/Caches/Snapshots"];
		case CBCleanCategoryGroupCaches:
			return @[]; // special
		default:
			return @[];
	}
}

- (BOOL)categoryAllowed:(CBCleanCategory)cat {
	// 会掉登录/会话的一律不允许清理
	if (cat == CBCleanCategoryWebKit || cat == CBCleanCategoryHTTPStorages) return NO;
	return YES;
}

- (BOOL)categoryEnabledByDefault:(CBCleanCategory)cat {
	if (![self categoryAllowed:cat]) return NO;
	switch (cat) {
		case CBCleanCategoryCaches:
		case CBCleanCategoryTmp:
		case CBCleanCategoryLogs:
		case CBCleanCategorySnapshots:
			return YES;
		case CBCleanCategoryGroupCaches:
			return CBSettingsBool(CBSettingCleanGroupCaches);
		default:
			return NO;
	}
}

- (BOOL)categoryRisky:(CBCleanCategory)cat {
	// 保留接口；允许的分类均视为安全
	return ![self categoryAllowed:cat];
}

- (NSArray<CBCategoryStat *> *)emptyCategoryStats {
	NSMutableArray *list = [NSMutableArray array];
	for (NSInteger i = 0; i < CBCleanCategoryCount; i++) {
		if (![self categoryAllowed:(CBCleanCategory)i]) continue;
		CBCategoryStat *st = [CBCategoryStat new];
		st.category = (CBCleanCategory)i;
		st.title = [self titleForCategory:(CBCleanCategory)i];
		st.enabledByDefault = [self categoryEnabledByDefault:(CBCleanCategory)i];
		st.risky = NO;
		st.paths = @[];
		st.bytes = 0;
		st.detail = @"计算中…";
		[list addObject:st];
	}
	return list;
}

- (NSArray<CBCategoryStat *> *)scanCategoriesForApp:(CBAppInfo *)app {
	[self ensureGroupsForApp:app];
	NSMutableArray<CBCategoryStat *> *list = [NSMutableArray array];
	NSString *root = app.dataPath;
	for (NSInteger i = 0; i < CBCleanCategoryCount; i++) {
		CBCleanCategory cat = (CBCleanCategory)i;
		if (![self categoryAllowed:cat]) continue;
		CBCategoryStat *st = [CBCategoryStat new];
		st.category = cat;
		st.title = [self titleForCategory:cat];
		st.enabledByDefault = [self categoryEnabledByDefault:cat];
		st.risky = NO;
		NSMutableArray *paths = [NSMutableArray array];
		unsigned long long bytes = 0;

		if (cat == CBCleanCategoryGroupCaches) {
			__block unsigned long long gbytes = 0;
			[app.groupPaths enumerateKeysAndObjectsUsingBlock:^(NSString *gid, NSString *gpath, BOOL *stop) {
				if (![self isValidContainerPath:gpath]) return;
				for (NSString *rel in @[@"Library/Caches", @"tmp", @"Library/Logs"]) {
					NSString *p = [self absoluteExistingPath:[gpath stringByAppendingPathComponent:rel]];
					if (!p) continue;
					[paths addObject:p];
					gbytes += [self cleanableSizeAtPath:p];
				}
			}];
			bytes = gbytes;
			st.detail = paths.count ? [NSString stringWithFormat:@"%lu 个 Group 路径", (unsigned long)paths.count] : @"无 Group 缓存";
		} else {
			if ([self isValidContainerPath:root]) {
				for (NSString *rel in [self relativePathsForCategory:cat]) {
					NSString *p = [self absoluteExistingPath:[root stringByAppendingPathComponent:rel]];
					if (!p) continue;
					[paths addObject:p];
					bytes += [self cleanableSizeAtPath:p];
				}
			}
			st.detail = @"安全清理项";
		}
		st.paths = paths;
		st.bytes = bytes;
		[list addObject:st];
	}
	return list;
}

- (unsigned long long)scanReclaimableForApp:(CBAppInfo *)app {
	return [self scanReclaimableForApp:app measureContainer:NO];
}

- (NSArray<NSString *> *)reclaimPathsForApp:(CBAppInfo *)app categories:(NSIndexSet *)cats {
	// 只收集要扫的绝对路径；Caches 已启用时跳过位于 Caches 下的 WebKit 子路径，避免重复递归
	BOOL cachesOn = [cats containsIndex:CBCleanCategoryCaches];
	NSMutableArray<NSString *> *paths = [NSMutableArray array];
	NSMutableSet<NSString *> *seen = [NSMutableSet set];
	void (^add)(NSString *) = ^(NSString *p) {
		NSString *abs = [self absoluteExistingPath:p];
		if (!abs || [seen containsObject:abs]) return;
		[seen addObject:abs];
		[paths addObject:abs];
	};

	NSString *root = app.dataPath ?: @"";
	if (![self isValidContainerPath:root]) return @[];
	for (NSInteger i = 0; i < CBCleanCategoryCount; i++) {
		if (![cats containsIndex:i]) continue;
		CBCleanCategory cat = (CBCleanCategory)i;
		if (![self categoryAllowed:cat]) continue;
		if (cat == CBCleanCategoryGroupCaches) {
			[app.groupPaths enumerateKeysAndObjectsUsingBlock:^(NSString *gid, NSString *gpath, BOOL *stop) {
				for (NSString *rel in @[@"Library/Caches", @"tmp", @"Library/Logs"]) {
					add([gpath stringByAppendingPathComponent:rel]);
				}
			}];
			continue;
		}
		for (NSString *rel in [self relativePathsForCategory:cat]) {
			// Caches 全量已扫时，不必再扫其下 WebKit 子目录
			if (cachesOn && cat == CBCleanCategoryWebKit && [rel hasPrefix:@"Library/Caches/"]) {
				continue;
			}
			add([root stringByAppendingPathComponent:rel]);
		}
	}
	return paths;
}

- (unsigned long long)scanReclaimableForApp:(CBAppInfo *)app measureContainer:(BOOL)measureContainer {
	if (![self isValidContainerPath:app.dataPath]) {
		app.reclaimableBytes = 0;
		return 0;
	}
	NSIndexSet *defs = [self defaultCategoryIndexSet];
	if ([defs containsIndex:CBCleanCategoryGroupCaches]) {
		[self ensureGroupsForApp:app];
	}
	unsigned long long total = 0;
	NSMutableSet *seen = [NSMutableSet set];
	for (NSString *p in [self reclaimPathsForApp:app categories:defs]) {
		if ([seen containsObject:p]) continue;
		[seen addObject:p];
		total += [self cleanableSizeAtPath:p];
	}
	// 可清不应大于已知占用（防统计异常）
	if (app.totalContainerBytes > 0 && total > app.totalContainerBytes * 2 && app.totalContainerBytes > 1024 * 1024) {
		// 允许可清略大于占用（占用 API 可能滞后），但离谱时以分类和为准仍保留；仅当可清远大于占用时截断
		if (total > app.totalContainerBytes * 5) {
			total = app.totalContainerBytes;
		}
	}
	app.reclaimableBytes = total;
	if (measureContainer) {
		// 详情页测整容器用上限，避免卡死
		app.totalContainerBytes = [self directorySize:app.dataPath maxFiles:50000];
	}
	return total;
}

- (void)scanApps:(NSArray<CBAppInfo *> *)apps
		progress:(CBProgressBlock)progress
	  completion:(void (^)(unsigned long long totalReclaimable))completion {
	if (!apps.count) {
		if (completion) completion(0);
		return;
	}
	dispatch_queue_t work = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
	dispatch_async(work, ^{
		// 有限并发：比串行快，又避免上百路同时狂扫磁盘
		dispatch_queue_t pool = dispatch_queue_create("com.o2ol.cleanbox.scan", DISPATCH_QUEUE_CONCURRENT);
		dispatch_semaphore_t limit = dispatch_semaphore_create(4);
		dispatch_group_t group = dispatch_group_create();
		__block unsigned long long sum = 0;
		__block NSInteger done = 0;
		NSInteger n = (NSInteger)apps.count;
		NSObject *lock = [NSObject new];

		for (CBAppInfo *app in apps) {
			dispatch_group_enter(group);
			dispatch_async(pool, ^{
				dispatch_semaphore_wait(limit, DISPATCH_TIME_FOREVER);
				unsigned long long r = 0;
				@try {
					r = [self scanReclaimableForApp:app measureContainer:NO];
				} @catch (__unused NSException *e) {}
				NSInteger cur;
				
				@synchronized (lock) {
					sum += r;
					done += 1;
					cur = done;
				}
				if (progress) {
					double p = n ? ((double)cur / (double)n) : 1;
					NSString *msg = [NSString stringWithFormat:@"%@ · %@  (%ld/%ld)",
									 app.name, [self humanSize:r], (long)cur, (long)n];
					dispatch_async(dispatch_get_main_queue(), ^{ progress(msg, p); });
				}
				dispatch_semaphore_signal(limit);
				dispatch_group_leave(group);
			});
		}

		dispatch_group_notify(group, dispatch_get_main_queue(), ^{
			if (completion) completion(sum);
		});
	});
}

- (NSIndexSet *)defaultCategoryIndexSet {
	NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
	for (NSInteger i = 0; i < CBCleanCategoryCount; i++) {
		if ([self categoryEnabledByDefault:(CBCleanCategory)i]) {
			[set addIndex:i];
		}
	}
	return set;
}

#pragma mark - Clean

- (void)cleanApp:(CBAppInfo *)app
	  categories:(NSIndexSet *)categories
		progress:(CBProgressBlock)progress
	  completion:(CBDoneBlock)completion {
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
		// 强制移除会掉登录的分类
		NSMutableIndexSet *safeCats = [(categories ?: [NSIndexSet indexSet]) mutableCopy];
		[safeCats removeIndex:CBCleanCategoryWebKit];
		[safeCats removeIndex:CBCleanCategoryHTTPStorages];
		NSIndexSet *catsToClean = safeCats;

		if (CBSettingsBool(CBSettingKillBeforeClean)) {
			if (progress) {
				dispatch_async(dispatch_get_main_queue(), ^{ progress(@"正在结束后台进程…", 0.05); });
			}
			[self terminateApp:app.bundleID error:nil];
			[NSThread sleepForTimeInterval:0.35];
		}

		NSArray<CBCategoryStat *> *stats = [self scanCategoriesForApp:app];
		unsigned long long freed = 0;
		NSInteger idx = 0;
		NSInteger count = catsToClean.count ?: 1;
		for (CBCategoryStat *st in stats) {
			if (![catsToClean containsIndex:st.category]) continue;
			idx++;
			double p = 0.1 + 0.85 * ((double)idx / (double)count);
			if (progress) {
				NSString *msg = [NSString stringWithFormat:@"清理 %@ · %@", app.name, st.title];
				dispatch_async(dispatch_get_main_queue(), ^{ progress(msg, p); });
			}
			for (NSString *path in st.paths) {
				// For directory targets we clear contents of Caches/tmp but keep the folder
				BOOL isDir = NO;
				[NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDir];
				if (isDir) {
					// Prefer clearing contents so app can recreate structure
					NSString *base = path.lastPathComponent;
					BOOL keep = ([base isEqualToString:@"Caches"] || [base isEqualToString:@"tmp"] ||
								 [base isEqualToString:@"Logs"] || [base isEqualToString:@"WebKit"] ||
								 [base isEqualToString:@"HTTPStorages"] || [base isEqualToString:@"SplashBoard"]);
					if (keep) {
						freed += [self deleteContentsOfDirectory:path keepDirectory:YES error:nil];
					} else {
						freed += [self deletePathIfExists:path];
					}
				} else {
					freed += [self deletePathIfExists:path];
				}
			}
		}
		if (progress) {
			dispatch_async(dispatch_get_main_queue(), ^{ progress(@"完成", 1.0); });
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			if (completion) completion(nil, freed);
		});
	});
}

- (void)cleanApps:(NSArray<CBAppInfo *> *)apps
	   categories:(NSIndexSet *)categories
		 progress:(CBProgressBlock)progress
	   completion:(CBDoneBlock)completion {
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
		unsigned long long totalFreed = 0;
		NSInteger n = apps.count;
		for (NSInteger i = 0; i < n; i++) {
			CBAppInfo *app = apps[i];
			if (progress) {
				NSString *msg = [NSString stringWithFormat:@"(%ld/%ld) %@", (long)(i + 1), (long)n, app.name];
				double p = n ? ((double)i / (double)n) : 1;
				dispatch_async(dispatch_get_main_queue(), ^{ progress(msg, p); });
			}
			dispatch_semaphore_t sem = dispatch_semaphore_create(0);
			__block unsigned long long freed = 0;
			[self cleanApp:app categories:categories progress:nil completion:^(NSError *err, unsigned long long fb) {
				freed = fb;
				dispatch_semaphore_signal(sem);
			}];
			// cleanApp already async — wait
			// Actually cleanApp dispatches async and calls completion on main; deadlock risk if we wait on main.
			// We're on background queue so OK, but completion is on main. semaphore still works.
			dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
			totalFreed += freed;
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			if (completion) completion(nil, totalFreed);
		});
	});
}

#pragma mark - Process control

- (BOOL)terminateApp:(NSString *)bundleID error:(NSError **)error {
	@try {
		// Prefer FrontBoard system service
		Class FBS = NSClassFromString(@"FBSSystemService");
		if (FBS && [FBS respondsToSelector:@selector(sharedService)]) {
			id svc = ((id (*)(id, SEL))objc_msgSend)(FBS, @selector(sharedService));
			SEL sel = NSSelectorFromString(@"terminateApplication:forReason:andReport:withDescription:");
			if ([svc respondsToSelector:sel]) {
				((void (*)(id, SEL, id, long long, BOOL, id))objc_msgSend)(svc, sel, bundleID, 1, NO, @"CleanBox");
				return YES;
			}
		}
		// LSApplicationWorkspace open/quit variants
		Class wsClass = [self workspaceClass];
		id ws = ((id (*)(id, SEL))objc_msgSend)(wsClass, @selector(defaultWorkspace));
		SEL tsel = NSSelectorFromString(@"terminateApplicationBundleIdentifier:withReason:andReport:withDescription:");
		if ([ws respondsToSelector:tsel]) {
			((void (*)(id, SEL, id, long long, BOOL, id))objc_msgSend)(ws, tsel, bundleID, 1, NO, @"CleanBox");
			return YES;
		}
		// Best-effort: no hard kill fallback (system() unavailable on iOS SDK)
		return YES;
	} @catch (NSException *ex) {
		if (error) *error = [NSError errorWithDomain:@"CleanBox" code:1 userInfo:@{NSLocalizedDescriptionKey: ex.reason ?: @"terminate failed"}];
		return NO;
	}
}

- (BOOL)openApp:(NSString *)bundleID error:(NSError **)error {
	@try {
		Class wsClass = [self workspaceClass];
		id ws = ((id (*)(id, SEL))objc_msgSend)(wsClass, @selector(defaultWorkspace));
		SEL osel = NSSelectorFromString(@"openApplicationWithBundleID:");
		if ([ws respondsToSelector:osel]) {
			((void (*)(id, SEL, id))objc_msgSend)(ws, osel, bundleID);
			return YES;
		}
	} @catch (NSException *ex) {
		if (error) *error = [NSError errorWithDomain:@"CleanBox" code:2 userInfo:@{NSLocalizedDescriptionKey: ex.reason ?: @"open failed"}];
	}
	return NO;
}

- (NSString *)humanSize:(unsigned long long)bytes {
	if (bytes < 1024ULL) return [NSString stringWithFormat:@"%llu B", bytes];
	double b = (double)bytes;
	if (b < 1024.0 * 1024.0) return [NSString stringWithFormat:@"%.1f KB", b / 1024.0];
	if (b < 1024.0 * 1024.0 * 1024.0) {
		double mb = b / (1024.0 * 1024.0);
		if (mb >= 100.0) return [NSString stringWithFormat:@"%.0f MB", mb];
		return [NSString stringWithFormat:@"%.1f MB", mb];
	}
	return [NSString stringWithFormat:@"%.2f GB", b / (1024.0 * 1024.0 * 1024.0)];
}

@end
