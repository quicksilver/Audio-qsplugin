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
		UInt32 rateCount = dataSize / sizeof(AudioValueRange) ;
		AudioValueRange sampleRates[rateCount];
		AudioObjectGetPropertyData(audioDevices[i], &propertyAddress, 0, NULL, &dataSize, sampleRates);
		NSMutableArray *availableSampleRates = [NSMutableArray arrayWithCapacity:rateCount];
		for(UInt32 i = 0 ; i < rateCount ; ++i)
		{
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
			kQSAudioDeviceIdentifier: [NSNumber numberWithInteger:audioDevices[i]],
			kQSAudioDeviceUID: (__bridge NSString *)deviceUID,
			kQSAudioDeviceType: deviceType,
			kQSAudioDeviceName: (__bridge NSString *)deviceName,
			kQSAudioDeviceManufacturer: (__bridge NSString *)deviceManufacturer,
			kQSAudioSampleRates: [availableSampleRates copy],
		};
		[audioDeviceData addObject:deviceData];
	}
	
	free(audioDevices); audioDevices = NULL;
	
	// return an immutable copy of the array
	return [audioDeviceData copy];
}

void selectDevice(AudioObjectID newDeviceID, QSAudioDeviceType deviceType) {
	UInt32 dataSize = sizeof(newDeviceID);
	AudioObjectPropertyAddress propertyAddress = {
		kAudioHardwarePropertyDevices,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster
	};
	switch(deviceType) {
		case kQSAudioDeviceTypeInput:
			propertyAddress.mSelector = kAudioHardwarePropertyDefaultInputDevice;
			AudioObjectSetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, dataSize, &newDeviceID);
			break;
		case kQSAudioDeviceTypeOutput:
			propertyAddress.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
			AudioObjectSetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, dataSize, &newDeviceID);
			break;
		case kQSAudioDeviceTypeSystemOutput:
			propertyAddress.mSelector = kAudioHardwarePropertyDefaultSystemOutputDevice;
			AudioObjectSetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, dataSize, &newDeviceID);
			break;
		default: break;
	}
}

void setSampleRate(AudioObjectID deviceID, Float32 newRate) {
	AudioValueRange data;
	AudioObjectPropertyAddress propertyAddress = {
		kAudioDevicePropertyNominalSampleRate,
		kAudioObjectPropertyScopeOutput,
		kAudioObjectPropertyElementMaster
	};
	CFStringRef BitRate = NULL;
	UInt32 dataSize = sizeof(BitRate);
	AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, NULL, &dataSize, &data);
	if (data.mMinimum == newRate) {
		// no change in sample rate
		return;
	}
	dataSize = sizeof(AudioValueRange);
	data.mMinimum = newRate;
	data.mMaximum = newRate;
	AudioObjectSetPropertyData(deviceID, &propertyAddress, 0, NULL, dataSize, &data);
}
