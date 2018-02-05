//
//  Audio Plug-in
//  AudioSource.m
//
//  Created by Rob McBroom
//

#import "AudioSource.h"
#import "QSAudio.h"

OSStatus QSAudioDeviceListener(AudioObjectID inObjectID, UInt32 inNumberAddresses, const AudioObjectPropertyAddress inAddresses[], void* inClientData)
{
	QSCatalogEntry *audioEntry = [QSLib entryForID:@"QSAudioDevicesPreset"];
	NSMutableSet *before = [NSMutableSet setWithArray:[audioEntry contents]];
	[audioEntry scanForced:YES];
	NSDate *giveUp = [NSDate dateWithTimeIntervalSinceNow:5.0];
	while ([audioEntry isScanning] && [[NSDate date] isLessThan:giveUp]) {
		// wait up to 5 seconds for the rescan to complete
		sleep(0.1);
	}
	NSMutableSet *after = [NSMutableSet setWithArray:[audioEntry contents]];
	NSDictionary *info = nil;
	if ([after count] > [before count]) {
		// device added
		[after minusSet:before];
		if ([after count]) {
			info = @{@"object": [after anyObject]};
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:@"QSEventNotification" object:@"QSAudioDeviceAddedEvent" userInfo:info];
	} else {
		// device removed
		[before minusSet:after];
		if ([before count]) {
			info = @{@"object": [before anyObject]};
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:@"QSEventNotification" object:@"QSAudioDeviceRemovedEvent" userInfo:info];
	}
	return noErr;
}

@implementation QSAudioSource

- (instancetype)init
{
	self = [super init];
	if (self) {
		AudioObjectPropertyAddress propertyAddress = {
			kAudioHardwarePropertyDevices,
			kAudioObjectPropertyScopeGlobal,
			kAudioObjectPropertyElementMaster
		};
		AudioObjectAddPropertyListener(kAudioObjectSystemObject, &propertyAddress, QSAudioDeviceListener, NULL);
	}
	return self;
}

- (void)dealloc
{
	AudioObjectPropertyAddress propertyAddress = {
		kAudioHardwarePropertyDevices,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster
	};
	AudioObjectRemovePropertyListener(kAudioObjectSystemObject, &propertyAddress, QSAudioDeviceListener, NULL);
	[super dealloc];
}

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
	NSArray *devices = getDeviceArray();

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
