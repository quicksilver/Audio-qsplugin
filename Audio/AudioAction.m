//
//  Audio Plug-in
//  AudioAction.m
//
//  Created by Rob McBroom
//

#import "AudioAction.h"
#import "QSAudio.h"

@implementation QSAudioAction

#pragma mark Helpers

QSObject *sampleRateQSObject(NSNumber *rate) {
	NSString *ident = [NSString stringWithFormat:@"QSAudioSampleRate:%@", rate];
	NSString *rateDisplayName = [NSString stringWithFormat:
		@"%.1f kHz",
		[rate floatValue] / 1000
	];
	QSObject *rateObject = [QSObject makeObjectWithIdentifier:ident];
	[rateObject setObject:rate forType:QSAudioSampleRateType];
	[rateObject setPrimaryType:QSAudioSampleRateType];
	[rateObject setName:rateDisplayName];
	return rateObject;
}

#pragma mark Action Methods

- (QSObject *)selectAudioInput:(QSObject *)dObject
{
	NSNumber *devID = [dObject objectForMeta:kQSAudioDeviceIdentifier];
	AudioObjectID device = (AudioObjectID)[devID integerValue];
	selectDevice(device, kQSAudioDeviceTypeInput);
	return nil;
}

- (QSObject *)selectAudioOutput:(QSObject *)dObject
{
	NSNumber *devID = [dObject objectForMeta:kQSAudioDeviceIdentifier];
	AudioObjectID device = (AudioObjectID)[devID integerValue];
	selectDevice(device, kQSAudioDeviceTypeOutput);
	return nil;
}

- (QSObject *)setAudioPropertyFor:(QSObject *)dObject sampleRate:(QSObject *)iObject
{
	NSNumber *devID = [dObject objectForMeta:kQSAudioDeviceIdentifier];
	AudioObjectID device = (AudioObjectID)[devID integerValue];
	NSNumber *sampleRate = [iObject objectForType:QSAudioSampleRateType];
	if ([[dObject objectForMeta:kQSAudioSampleRates] containsObject:sampleRate]) {
		setSampleRate(device, [sampleRate floatValue]);
	} else {
		NSLog(@"sample rate %@ is not supported by %@", sampleRate, dObject);
	}
	return nil;
}

#pragma mark Quicksilver Validation

// return an array of objects that are allowed in the third pane
- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject
{
	if ([action isEqualToString:@"QSSetAudioSampleRateAction"]) {
		NSMutableArray *rateOptions = [NSMutableArray array];
		for (NSNumber *sampleRate in [dObject objectForMeta:kQSAudioSampleRates]) {
			QSObject *rateObj = sampleRateQSObject(sampleRate);
			[rateOptions addObject:rateObj];
		}
		return [rateOptions copy];
	}
	return nil;
}

// do some checking on the objects in the first pane
// if an action has `validatesObjects` enabled in Info.plist, this method must return the action's name or it will never appear
- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject
{
	return nil;
}

@end
