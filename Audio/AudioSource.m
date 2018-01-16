//
//  Audio Plug-in
//  AudioSource.m
//
//  Created by Rob McBroom
//

#import "AudioSource.h"
#import "QSAudio.h"

@implementation QSAudioSource

#pragma mark Catalog Entry Methods

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry
{
	return NO;
}

- (NSArray *) objectsForEntry:(NSDictionary *)theEntry
{
	NSMutableArray *objects = [NSMutableArray arrayWithCapacity:1];
	QSObject *newObject;
	NSArray *devices = (NSArray *)GetDeviceArray();

	for (NSDictionary *devData in devices) {
		NSString *devName = devData[@"deviceName"];
		NSString *devType = devData[@"deviceType"];
		newObject = [QSObject makeObjectWithIdentifier:[NSString stringWithFormat:@"QSAudio:%@", devName]];
		[newObject setName:devName];
		[newObject setObject:devName forType:devType];
		[newObject setPrimaryType:devType];
		[objects addObject:newObject];
	}

	return objects;
}

- (BOOL)entryCanBeIndexed:(NSDictionary *)theEntry
{
	// make sure devices are rescanned on every launch, not read from disk
	return NO;
}
@end
