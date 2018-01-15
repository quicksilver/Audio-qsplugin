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
	NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
	QSObject *newObject;
	
	UInt32 propertySize;
	AudioDeviceID dev_array[64];
	int numberOfDevices = 0;
	ASDeviceType device_type;
	char deviceName[256];
	
	AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &propertySize, NULL);
	
	AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &propertySize, dev_array);
	numberOfDevices = (propertySize / sizeof(AudioDeviceID));
	
	for (int i = 0; i < numberOfDevices; ++i) {
		AudioDeviceID dev = dev_array[i];
		getDeviceName(dev, deviceName);
		NSString *devName = [NSString stringWithUTF8String:deviceName];
		NSString *devType;
		if (isAnInputDevice(dev)) {
			devType = QSAudioInputType;
		} else if (isAnOutputDevice(dev)) {
			devType = QSAudioOutputType;
		} else {
			devType = QSAudiosystemType;
		}
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
