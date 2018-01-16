//
//  Audio Plug-in
//  AudioAction.m
//
//  Created by Rob McBroom
//

#import "AudioAction.h"
#import "QSAudio.h"
#import "audio_switch.h"

@implementation QSAudioAction

#pragma mark Action Methods

- (QSObject *)selectAudioInput:(QSObject *)dObject
{
	NSString *devName = [dObject objectForType:QSAudioInputType];
	AudioDeviceID device = getRequestedDeviceID((char *)[devName UTF8String], kAudioTypeInput);
	setDevice(device, kAudioTypeInput);
	return nil;
}

- (QSObject *)selectAudioOutput:(QSObject *)dObject
{
	NSString *devName = [dObject objectForType:QSAudioOutputType];
	AudioDeviceID device = getRequestedDeviceID((char *)[devName UTF8String], kAudioTypeOutput);
	setDevice(device, kAudioTypeOutput);
	return nil;
}

#pragma mark Quicksilver Validation

// return an array of objects that are allowed in the third pane
- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject
{
	return nil;
}

// do some checking on the objects in the first pane
// if an action has `validatesObjects` enabled in Info.plist, this method must return the action's name or it will never appear
- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject
{
	return nil;
}

@end
