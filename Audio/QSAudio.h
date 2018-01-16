//
//  QSAudio.h
//  Audio
//
//  Created by Rob McBroom on 2018/01/15.
//

#include <CoreAudio/CoreAudio.h>

#define QSAudioInputType @"QSAudioInputType"
#define QSAudioOutputType @"QSAudioOutputType"
#define QSAudiosystemType @"QSAudioSystemType"

CFArrayRef GetDeviceArray();
