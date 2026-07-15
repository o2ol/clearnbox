#import "CBStorageInfo.h"

@implementation CBStorageInfo

+ (instancetype)current {
	CBStorageInfo *info = [self new];
	[info refreshDevice];
	return info;
}

- (void)refreshDevice {
	unsigned long long total = 0, freeB = 0;
	// 优先 volume resource values（更接近系统「储存空间」）
	NSURL *home = [NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES];
	NSArray *keys = @[
		NSURLVolumeTotalCapacityKey,
		NSURLVolumeAvailableCapacityForImportantUsageKey,
		NSURLVolumeAvailableCapacityKey,
	];
	NSDictionary *vals = [home resourceValuesForKeys:keys error:nil];
	if ([vals[NSURLVolumeTotalCapacityKey] respondsToSelector:@selector(unsignedLongLongValue)]) {
		total = [vals[NSURLVolumeTotalCapacityKey] unsignedLongLongValue];
	}
	id important = vals[NSURLVolumeAvailableCapacityForImportantUsageKey];
	id available = vals[NSURLVolumeAvailableCapacityKey];
	if ([important respondsToSelector:@selector(longLongValue)] && [important longLongValue] >= 0) {
		freeB = (unsigned long long)MAX(0LL, [important longLongValue]);
	} else if ([available respondsToSelector:@selector(unsignedLongLongValue)]) {
		freeB = [available unsignedLongLongValue];
	}
	if (total == 0) {
		NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
		total = [attrs[NSFileSystemSize] unsignedLongLongValue];
		freeB = [attrs[NSFileSystemFreeSize] unsignedLongLongValue];
	}
	self.totalBytes = total;
	self.freeBytes = freeB;
	self.usedBytes = total > freeB ? total - freeB : 0;
}

- (unsigned long long)otherBytes {
	if (self.usedBytes > self.appBytes) return self.usedBytes - self.appBytes;
	return 0;
}

- (unsigned long long)appKeptBytes {
	if (self.appBytes > self.reclaimableBytes) return self.appBytes - self.reclaimableBytes;
	return self.appBytes;
}

@end
