//
//  Audio Plug-in
//  AudioAction.m
//
//  Created by Rob McBroom
//

#import "AudioAction.h"
#import "QSAudio.h"
#import <objc/objc-runtime.h>

NSString *actionIDForSampleRate(NSNumber *sampleRate) {
	return [NSString stringWithFormat:@"QSSampleRateAction%@", sampleRate];
}

@implementation QSAudioAction

+ (void)loadPlugIn
{
	NSArray *sampleRates = @[
		@8000.0F, @11025.0F, @16000.0F, @22050.0F, @44100.0F, @48000.0F,
		@88200.0F, @96000.0F, @176400.0F, @192000.0F, @352800.0F, @384000.0F,
	];
	/*
	 dynamically create repetitive sample rate actions

	 This will result in a bunch of actions such as
	 - (QSObject *)setSampleRate8000:(QSObject *)dObject
	 - (QSObject *)setSampleRate11025:(QSObject *)dObject
	 etc.
	 */
	for (NSNumber *sampleRate in sampleRates) {
		QSObject *(^actionBlock)(id, QSObject *) = ^ QSObject *(id _self, QSObject *dObject) {
			NSNumber *devID = [dObject objectForMeta:kQSAudioDeviceIdentifier];
			AudioObjectID device = (AudioObjectID)[devID integerValue];
			if (![[dObject objectForMeta:kQSAudioSampleRates] containsObject:sampleRate]) {
				NSLog(@"sample rate %@ is not supported by %@", sampleRate, dObject);
				return nil;
			}
			setSampleRate(device, [sampleRate floatValue]);
			return nil;
		};
		IMP sampleRateAction = imp_implementationWithBlock(actionBlock);
		NSString *selName = [NSString stringWithFormat:@"setSampleRate%@:", sampleRate];
		SEL actionSelector = NSSelectorFromString(selName);
		BOOL actionAvailable = class_addMethod(
			[self class],
			actionSelector,
			sampleRateAction,
			"@@:@"
		);
		if (actionAvailable)
		{
			NSString *actionID = actionIDForSampleRate(sampleRate);
			NSString *actionName = [NSString stringWithFormat:
				@"Set Sample Rate to %g kHz",
				[sampleRate floatValue] / 1000
			];
			NSString *commandFormat = [
				@"Set Sample Rate for %@ "
				stringByAppendingFormat:@"to %g kHz", [sampleRate floatValue] / 1000
			];
			QSAction *newAction = [[QSAction alloc] init];
			[newAction setIdentifier:actionID];
			[newAction setProvider:[self alloc]];
			[newAction setBundle:[NSBundle bundleWithIdentifier:@"com.qsapp.AudioPlugin"]];
			[newAction setName:actionName];
			[newAction setCommandFormat:commandFormat];
			[newAction setIcon:[QSResourceManager imageNamed:@"QSAudioSampleRate"]];
			[newAction setIconLoaded:YES];
			[newAction setAction:actionSelector];
			[newAction setPrecedence:0.5];
			[newAction setDirectTypes:@[QSAudioInputType, QSAudioOutputType]];
			[newAction setValidatesObjects:YES];
			[QSExec addAction:newAction];
		}
	}
}

#pragma mark Helpers

QSObject *sampleRateQSObject(NSNumber *rate) {
	NSString *ident = [NSString stringWithFormat:@"QSAudioSampleRate:%@", rate];
	NSString *rateDisplayName = [NSString stringWithFormat:
		@"%g kHz",
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

#pragma mark Quicksilver Validation

// return an array of objects that are allowed in the third pane
- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject
{
	return nil;
}

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject
{
	NSMutableArray *allowedSampleRates = [NSMutableArray array];
	for (NSNumber *sampleRate in [dObject objectForMeta:kQSAudioSampleRates]) {
		NSString *actionID = actionIDForSampleRate(sampleRate);
		[allowedSampleRates addObject:actionID];
	}
	return [allowedSampleRates copy];
}

@end
