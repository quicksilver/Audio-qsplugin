//
//  QSAudio.h
//  Audio
//
//  Created by Rob McBroom on 2018/01/15.
//

#include <CoreAudio/CoreAudio.h>
#include <Cocoa/Cocoa.h>

#define QSAudioInputType @"QSAudioInputType"
#define QSAudioOutputType @"QSAudioOutputType"
#define QSAudiosystemType @"QSAudioSystemType"
#define kQSAudioDeviceIdentifier @"deviceIdentifier"
#define kQSAudioDeviceUID @"deviceUID"
#define kQSAudioDeviceType @"deviceType"
#define kQSAudioDeviceName @"deviceName"
#define kQSAudioDeviceManufacturer @"deviceManufacturer"
#define kQSAudioSampleRates @"sampleRates"

typedef enum {
	kQSAudioDeviceTypeUnknown = 0,
	kQSAudioDeviceTypeInput   = 1,
	kQSAudioDeviceTypeOutput  = 2,
	kQSAudioDeviceTypeSystemOutput = 3
} QSAudioDeviceType;

NSArray *GetDeviceArray();
void selectDevice(AudioObjectID newDeviceID, QSAudioDeviceType deviceType);
void setSampleRate(AudioObjectID deviceID, Float32 newRate);
