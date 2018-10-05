//
//  BugseeOptions.h
//  Bugsee
//
//  Created by ANDREY KOVALEV on 13.09.2017.
//  Copyright © 2017 Bugsee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BugseeConstants.h"

@interface BugseeOptions : NSObject

+ (nullable BugseeOptions *) optionsFrom:(NSDictionary*_Nullable) options;
+ (nonnull BugseeOptions *) defaultOptions;

/**
 * Update with old style options.
 * example of usage:
 *
 * BugseeOptions * options = [BugseeOptions defaultOptions];
 * NSDictionary * dict =         options = @{BugseeMaxRecordingTimeKey   : @60,
                                             BugseeShakeToReportKey      : BugseeTrue,
                                             BugseeScreenshotToReportKey : BugseeTrue,
                                             BugseeStatusBarInfoKey      : BugseeTrue,
                                             ...
                                             BugseeCrashReportKey        : BugseeTrue
                                            };
 * [options updateWithOptions:dict];
 *
 * Keys for old style options you can find in BugseeConstants.h
 * Options documentation: https://docs.bugsee.com/sdk/ios/configuration/
 */
- (void)updateLaunchOptions:(nonnull NSDictionary*)dict;

/**
 * Use to change bugsee style to Light Dusk or Based on status bar
 * Default: BugseeStyleLight
 */
@property (nonatomic, assign) BugseeStyle bugseeStyle;

/**
 * Use this option to change frame rate to Low or High
 * Default: BugseeSeverityHigh
 */
@property (nonatomic, assign) BugseeFrameRate framerate;

/**
 * Priority for crashes
 * Default: BugseeSeverityBlocker
 */
@property (nonatomic, assign) BugseeSeverityLevel defaultCrashPriority;

/**
 * Priority for bugs
 * Default: BugseeSeverityHigh
 */
@property (nonatomic, assign) BugseeSeverityLevel defaultBugPriority;

/**
 * Shake gesture to trigger report
 * Default: NO
 */
@property (nonatomic, assign) BOOL shakeToReport;

/**
 * Screenshot key to trigger report
 * Default: YES
 */
@property (nonatomic, assign) BOOL screenshotToReport;

/**
 * Catch and report application crashes 
 * IOS allows only one crash detector to be active at a time, if you insist on using an 
 * alternative solution for handling crashes, you might want to use this option and disable 
 * Bugsee from taking over.
 * Default: YES
 */
@property (nonatomic, assign) BOOL crashReport;

/**
 * Detect abnormal termination | experimental method, read more - https://docs.bugsee.com/sdk/ios/app-kills |
 * Default: NO
 */
@property (nonatomic, assign) BOOL killDetection;

/**
 * Capture network traffic
 * Default: YES
 */
@property (nonatomic, assign) BOOL monitorNetwork;

/**
 * Capture web-sockets traffic
 * Default: YES
 */
@property (nonatomic, assign) BOOL monitorWebSocket;

/**
 * Info about pending reports and current recording state.
 * Default: NO
 */
@property (nonatomic, assign) BOOL statusBarInfo;

/**
 * Enable video recording
 * Default: YES
 */
@property (nonatomic, assign) BOOL videoEnabled;

/**
 * Screenshot that appears in report
 * Default: When videoEnabled it's true, but if videoEnabled == false it's false
 */
@property (nonatomic, assign) BOOL screenshotEnabled;

/**
 * experemental method may cause a deadlocks, be careful with using it.
 * Default: NO
 */
@property (nonatomic, assign) BOOL enableMachExceptions;

/**
 * Allow user to modify priority when reporting manual
 * Default: NO
 */
@property (nonatomic, assign) BOOL reportPrioritySelector;

/**
 * Automatically capture all console logs
 * Default: YES
 */
@property (nonatomic, assign) BOOL captureLogs;

/**
 * Maximum recording duration
 * Default: 60
 */
@property (nonatomic, assign) int maxRecordingTime;

/**
 * Bugsee network requests allowed only by wifi
 * Default: NO
 */
@property (nonatomic, assign) BOOL wifiOnlyUpload;

/**
 * Capture Device and wifi names.
 * They are shown on the issue screen.
 * Default: YES
 */
@property (nonatomic, assign) BOOL captureDeviceAndNetworkNames;

/**
 * Bugsee will avoid using more disk space than specified. <br/>
 * Option has value of int type and should be specified in Mb. Value should not be smaller than 10.
 * Default: 50
 */
@property (nonatomic, assign) int maxDataSize;

/**
 *  Name of the project target
 */
@property (nonatomic, strong) NSString * _Nullable buildTarget;

/**
 *  debug, release, etc...
 */
@property (nonatomic, strong) NSString * _Nullable buildType;

@property (nonatomic, assign) uint maxFramerate;
@property (nonatomic, assign) uint minFramerate;

/**
 * Increase or decrease quality of video
 * Default: 0 - means not used
 */
@property (nonatomic, assign) float videoScale;

- (int) maxBodyDataLength;
- (nullable NSDictionary*) dictionary;
- (nullable id)objectForKeyedSubscript:(nonnull NSString*)key;

@end
