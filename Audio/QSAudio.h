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

typedef enum {
	kQSAudioDeviceTypeUnknown = 0,
	kQSAudioDeviceTypeInput   = 1,
	kQSAudioDeviceTypeOutput  = 2,
	kQSAudioDeviceTypeSystemOutput = 3
} QSAudioDeviceType;

NSArray *GetDeviceArray();
void selectDevice(AudioObjectID newDeviceID, QSAudioDeviceType deviceType);
