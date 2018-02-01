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
	// always ignore scheduled indexing - QSAudioDeviceListener should keep it fresh
	return YES;
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry
{
	NSMutableArray *objects = [NSMutableArray arrayWithCapacity:1];
	QSObject *newObject;
	NSArray *devices = GetDeviceArray();

	for (NSDictionary *devData in devices) {
		NSString *devName = devData[kQSAudioDeviceName];
		NSString *devType = devData[kQSAudioDeviceType];
		NSString *details = [
			NSString stringWithFormat:@"Audio %@ Device from %@",
			([devType isEqualToString:QSAudioInputType]) ? @"Input" : @"Output",
			devData[kQSAudioDeviceManufacturer]
		];
		newObject = [QSObject makeObjectWithIdentifier:devData[kQSAudioDeviceUID]];
		[newObject setName:devName];
		[newObject setDetails:details];
		[newObject setObject:devName forType:devType];
		[newObject setPrimaryType:devType];
		[newObject setObject:devData[kQSAudioDeviceIdentifier] forMeta:kQSAudioDeviceIdentifier];
		[newObject setObject:devData[kQSAudioSampleRates] forMeta:kQSAudioSampleRates];
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
