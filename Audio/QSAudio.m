//
//  Audio.c
//  Audio Plugin
//
//  Created by Rob McBroom on 2018/01/16.
//  Borrowing heavily from https://stackoverflow.com/questions/4575408/audioobjectgetpropertydata-to-get-a-list-of-input-devices
// and https://developer.apple.com/library/content/samplecode/HALExamples/Listings/ConfigDefaultOutput_c.html
//
// TODO https://stackoverflow.com/questions/26012341/os-x-respond-to-new-audio-device

#include "QSAudio.h"

NSArray *GetDeviceArray()
{
	AudioObjectPropertyAddress propertyAddress = {
		kAudioHardwarePropertyDevices,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster
	};
	
	UInt32 dataSize = 0;
	OSStatus status = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &dataSize);
	if (kAudioHardwareNoError != status) {
		fprintf(stderr, "AudioObjectGetPropertyDataSize (kAudioHardwarePropertyDevices) failed: %i\n", status);
		return NULL;
	}
	
	UInt32 deviceCount = (UInt32)(dataSize / sizeof(AudioObjectID));
	
	AudioObjectID *audioDevices = (AudioObjectID *)(malloc(dataSize));
	if (NULL == audioDevices) {
		fputs("Unable to allocate memory", stderr);
		return NULL;
	}
	
	status = AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &dataSize, audioDevices);
	if (kAudioHardwareNoError != status) {
		fprintf(stderr, "AudioObjectGetPropertyData (kAudioHardwarePropertyDevices) failed: %i\n", status);
		free(audioDevices); audioDevices = NULL;
		return NULL;
	}
	
	// collect data about each device
	NSMutableArray *audioDeviceData = [NSMutableArray array];
	propertyAddress.mScope = kAudioDevicePropertyScopeInput;
	for (UInt32 i = 0; i < deviceCount; ++i) {
		// Query device UID
		CFStringRef deviceUID = NULL;
		dataSize = sizeof(deviceUID);
		propertyAddress.mSelector = kAudioDevicePropertyDeviceUID;
		status = AudioObjectGetPropertyData(audioDevices[i], &propertyAddress, 0, NULL, &dataSize, &deviceUID);
		if (kAudioHardwareNoError != status) {
			fprintf(stderr, "AudioObjectGetPropertyData (kAudioDevicePropertyDeviceUID) failed: %i\n", status);
			continue;
		}
		
		// Query device bitrate
		CFStringRef BitRate = NULL;
		dataSize = sizeof(BitRate);
		propertyAddress.mSelector = kAudioDevicePropertyAvailableNominalSampleRates;
		AudioObjectGetPropertyDataSize(audioDevices[i], &propertyAddress, 0, NULL, &dataSize);
		int rateCount = dataSize / sizeof(AudioValueRange) ;
		
		printf("Available %d Sample Rates\n", rateCount) ;
		
		AudioValueRange sampleRates[rateCount];
		
		AudioObjectGetPropertyData(audioDevices[i], &propertyAddress, 0, NULL, &dataSize, sampleRates);
		
		NSMutableArray *availableSampleRates = [NSMutableArray arrayWithCapacity:rateCount];
		for(UInt32 i = 0 ; i < rateCount ; ++i)
		{
			printf("Available Sample Rate value : %f\n", sampleRates[i].mMinimum);
			[availableSampleRates addObject:[NSNumber numberWithFloat:sampleRates[i].mMinimum]];
		}
		
		// Query device name
		CFStringRef deviceName = NULL;
		dataSize = sizeof(deviceName);
		propertyAddress.mSelector = kAudioDevicePropertyDeviceNameCFString;
		status = AudioObjectGetPropertyData(audioDevices[i], &propertyAddress, 0, NULL, &dataSize, &deviceName);
		if (kAudioHardwareNoError != status) {
			fprintf(stderr, "AudioObjectGetPropertyData (kAudioDevicePropertyDeviceNameCFString) failed: %i\n", status);
			continue;
		}
		
		// Query device manufacturer
		CFStringRef deviceManufacturer = NULL;
		dataSize = sizeof(deviceManufacturer);
		propertyAddress.mSelector = kAudioDevicePropertyDeviceManufacturerCFString;
		status = AudioObjectGetPropertyData(audioDevices[i], &propertyAddress, 0, NULL, &dataSize, &deviceManufacturer);
		if (kAudioHardwareNoError != status) {
			fprintf(stderr, "AudioObjectGetPropertyData (kAudioDevicePropertyDeviceManufacturerCFString) failed: %i\n", status);
			continue;
		}
		
		// Determine if the device is an input device (it is an input device if it has input channels)
		dataSize = 0;
		propertyAddress.mSelector = kAudioDevicePropertyStreamConfiguration;
		status = AudioObjectGetPropertyDataSize(audioDevices[i], &propertyAddress, 0, NULL, &dataSize);
		if (kAudioHardwareNoError != status) {
			fprintf(stderr, "AudioObjectGetPropertyDataSize (kAudioDevicePropertyStreamConfiguration) failed: %i\n", status);
			continue;
		}
		
		AudioBufferList *bufferList = (AudioBufferList *)(malloc(dataSize));
		if (NULL == bufferList) {
			fputs("Unable to allocate memory", stderr);
			break;
		}
		
		status = AudioObjectGetPropertyData(audioDevices[i], &propertyAddress, 0, NULL, &dataSize, bufferList);
		NSString *deviceType;
		if (kAudioHardwareNoError != status || 0 == bufferList->mNumberBuffers) {
			deviceType = @"QSAudioOutputType";
		} else {
			deviceType = @"QSAudioInputType";
		}
		free(bufferList); bufferList = NULL;
		
		// Add a dictionary for this device to the array of input devices
		NSDictionary *deviceData = @{
			@"deviceIdentifier": [NSNumber numberWithInteger:audioDevices[i]],
			@"deviceUID": (__bridge NSString *)deviceUID,
			@"deviceType": deviceType,
			@"deviceName": (__bridge NSString *)deviceName,
			@"deviceManufacturer": (__bridge NSString *)deviceManufacturer,
			@"sampleRates": [availableSampleRates copy],
		};
		[audioDeviceData addObject:deviceData];
	}
	
	free(audioDevices); audioDevices = NULL;
	
	// return an immutable copy of the array
	return [audioDeviceData copy];
}
