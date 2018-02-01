//
//  QSAudioEvents.m
//  Audio Plugin
//
//  Created by Rob McBroom on 2018/02/01.
//

#import "QSAudioEvents.h"
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
	NSDictionary *info;
	if ([after count] > [before count]) {
		// device added
		[after minusSet:before];
		info = @{@"object": [after anyObject]};
		[[NSNotificationCenter defaultCenter] postNotificationName:@"QSEventNotification" object:@"QSAudioDeviceAddedEvent" userInfo:info];
	} else {
		// device removed
		[before minusSet:after];
		info = @{@"object": [before anyObject]};
		[[NSNotificationCenter defaultCenter] postNotificationName:@"QSEventNotification" object:@"QSAudioDeviceRemovedEvent" userInfo:info];
	}
	return noErr;
}

@implementation QSAudioEvents

- (void)addObserverForEvent:(NSString *)audioDeviceEvent trigger:(QSTrigger *)trigger
{
	AudioObjectPropertyAddress propertyAddress = {
		kAudioHardwarePropertyDevices,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster
	};
	AudioObjectAddPropertyListener(kAudioObjectSystemObject, &propertyAddress, QSAudioDeviceListener, NULL);
	NSLog(@"START listening for audio devices");
}

- (void)removeObserverForEvent:(NSString *)audioDeviceEvent trigger:(QSTrigger *)trigger
{
	AudioObjectPropertyAddress propertyAddress = {
		kAudioHardwarePropertyDevices,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster
	};
	AudioObjectRemovePropertyListener(kAudioObjectSystemObject, &propertyAddress, QSAudioDeviceListener, NULL);
	NSLog(@"STOP listening for audio devices");
}

@end
