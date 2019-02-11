//
//  Bugsee.h
//  Bugsee
//
//  Created by Dmitry Fink on 11.10.15.
//  Copyright © 2016 Bugsee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>
#import <UIKit/UIKit.h>
#import "BugseeLogger.h"
#import "BugseeConstants.h"
#import "BugseeAttachment.h"
#import "BugseeReport.h"
#import "BugseeNetworkEvent.h"
#import "BugseeOptions.h"
#import "BugseeLogEvent.h"
#import "BugseeTheme.h"

#define BUGSEE_ASSERT(condition, description) \
if (!condition) {[Bugsee logAssert:description withLocation:[NSString stringWithFormat:@"%s (%@:%d)", __PRETTY_FUNCTION__, [[NSString stringWithFormat:@"%s", __FILE__] lastPathComponent], __LINE__]]; }

@class Bugsee;
@protocol BugseeDelegate <NSObject>

@optional
/**
 *  Use this delegate to filter network events and their properties.
 *
 *  Example:
 *  - (void) bugseeFilterNetworkEvent:(BugseeNetworkEvent *)event completionHandler:(BugseeNetworkFilterDecisionBlock)decisionBlock
 *  {
 *      //Do all your stuff
 *
 *      //Decision block can receive nil as argument, if you need to remove event.
 *      decisionBlock(event);
 *  }
 *
 *  @param event         network event with properties
 *  @param decisionBlock pass event into this block, you also can pass nil as argument to remove event
 */
-(void) bugseeFilterNetworkEvent:(nonnull BugseeNetworkEvent *)event completionHandler:(nonnull BugseeNetworkFilterDecisionBlock)decisionBlock;

/**
 *  This delegate allows you, to attach 3 files less than 1 MB each to a report.
 *
 *  @param report       report about to be sent
 *  @return pass array of attachments here.
 */
-(nonnull NSArray<BugseeAttachment* >*) bugseeAttachmentsForReport:(nonnull BugseeReport *)report;

/**
 *  This delegate allows you, to attach 3 files less than 1 MB each to a report.
 *
 *  Example:
 *  - (void) bugseeAttachmentsForReport:(nonnull BugseeReport *)report completionHandler:(nonnull BugseeAttachmentsDecisionBlock)decisionBlock
 *  {
 *      NSMutableArray<BugseeAttachment*>* attachments = ...
 *      //Do all your stuff
 *
 *      //Decision block can receive nil as argument.
 *      decisionBlock(attachments);
 *  }
 *
 *  @param report        report about to be sent
 *  @param decisionBlock pass attachments into this block, you also can pass nil.
 */
-(void) bugseeAttachmentsForReport:(nonnull BugseeReport *)report completionHandler:(nonnull BugseeAttachmentsDecisionBlock)decisionBlock;
/**
 *  Use this delegate to hanle new feedback messages in your app.
 *
 *  @param messages  text messages in array
 */
-(void) bugsee:(nonnull Bugsee *)bugsee didReceiveNewFeedback:(nonnull NSArray<NSString *> *)messages;

/**
 *  Use this delegate to filter console logs that will sended with report.
 *
 *  @param log BugseeLogEvent object with log message and parameters
 *  @param decisionBlock pass BugseeLogEvent into this block, you also can pass nil as argument to remove log
 */
-(void) bugseeFilterLog:(nonnull BugseeLogEvent *) log completionHandler:(nonnull BugseeLogFilterDecisionBlock)decisionBlock;

@end

@interface Bugsee : NSObject

@property (weak, nonatomic) id _Nullable delegate;
@property (assign, nonatomic, readonly) BOOL launched;

+ (nullable Bugsee *)sharedInstance;
+ (nullable Bugsee *)launchWithToken:(nonnull NSString* )appToken NS_SWIFT_NAME(launch(token:));
+ (nullable Bugsee *)launchWithToken:(nonnull NSString*)appToken andOptions:( NSDictionary * _Nullable) options NS_SWIFT_NAME(launch(token:options:));
+ (nullable Bugsee *)launchWithToken:(nonnull NSString*)appToken options:(BugseeOptions * _Nullable) options NS_SWIFT_NAME(launch(token:options:));

+ (void) showReportController;
+ (void) showReportControllerWithSummary:(nonnull NSString *)summ description:(nonnull NSString*)descr severity:(BugseeSeverityLevel)level NS_SWIFT_NAME(showReportController(summary:description:severity:));

+ (nullable NSDictionary *)getLaunchOptions;

+ (nonnull NSString *) getDeviceId;

/**
 *  Pause bugsee video and loggers
 */
+ (void) pause;
/**
 *  Resume bugsee video and loggers
 */
+ (void) resume;
/**
 *  Stop Bugsee.
 *  After this call you can launchWithToken:andOptions: again
 *  new token and options will be applied
 *  @param completion bugsee is stopped completion block, can be nil
 */
+ (void) stop:(void (^_Nullable)(void))completion;

+ (void)relaunchWithDictionaryOptions:(NSDictionary * _Nullable) options NS_SWIFT_NAME(relaunch(options:));
+ (void)relaunchWithOptions:(BugseeOptions * _Nullable) options NS_SWIFT_NAME(relaunch(options:));

+ (void) traceKey:(nonnull NSString*)traceKey withValue:(nonnull id)value NS_SWIFT_NAME(trace(key:value:));

+ (void) registerEvent:(nonnull NSString*)eventName NS_SWIFT_NAME(event(_:));
+ (void) registerEvent:(nonnull NSString*)eventName withParams:(nonnull NSDictionary*)params NS_SWIFT_NAME(event(_:params:));

+ (void) uploadWithSummary:(nonnull NSString*)summary description:(nonnull NSString*)descr severity:(BugseeSeverityLevel)severity NS_SWIFT_NAME(upload(summary:description:severity:));

+ (void) logError:(nonnull NSError *)error NS_SWIFT_NAME(logError(error:));

+ (void) logAssert:(nonnull NSString *)description withLocation:(nonnull NSString*)location NS_SWIFT_NAME(logAssert(description:location:));

+ (void) log:(nonnull NSString*)message NS_SWIFT_NAME(log(_:));

+ (void) log:(nonnull NSString*)message level:(BugseeLogLevel)level NS_SWIFT_NAME(log(_:level:));

+ (void) log:(nonnull NSString*)message level:(BugseeLogLevel)level timestamp:(int64_t)timestamp NS_SWIFT_NAME(log(_:level:timestamp:));

/**
 *  Show feedback controller for contacting the user
 */
+ (void) showFeedbackController;

/**
 *  Use this method to filter network events and their properties.
 *
 *  Always call removeNetworkEventFilter method if you deallocate
 *  class where setNetworkEventFilter: was called Bugsee.removeNetworkEventFilter();
 *
 *  @param filterBlock pass BugseeNetworkEvent into this block
 */
+ (void) setNetworkEventFilter:(nonnull BugseeNetworkEventFilterBlock)filterBlock;

/**
 *  Use this method to send info about your network event with bugsee report
 *
 *  @param event BugseeNetworkEvent 
 *  @see BugseeNetworkEvent
 */
+ (void) registerNetworkEvent:(nonnull BugseeNetworkEvent *)event;

/**
 *  Use this method to send info about your network event with bugsee report
 *
 *  @param event BugseeNetworkEvent
 *  @param event event will go trough filter block if YES
 *  @see BugseeNetworkEvent
 */
+ (void) registerNetworkEvent:(nonnull BugseeNetworkEvent *)event
            needsToBeFiltered:(BOOL)needsToBeFiltered;

+ (void) setDefaultFeedbackGreeting:(nonnull NSString *)greeting;

/**
 *  Remove exists filter that was setup with setNetworkEventFilter: method
 */
+ (void) removeNetworkEventFilter;

+ (nonnull NSString*) accessToken;

/**
 *  Set reporter's email
 *
 *  @param email string with email
 *  @return YES on success, NO on falure
 */
+ (BOOL) setEmail:(nonnull NSString *)email NS_SWIFT_NAME(setEmail(_:));

/**
 *  Get reporter's email
 *
 *  @return NSString* with email on success, or nil on failure
 */
+ (nullable NSString *) getEmail;

/**
 *  Clear reporter's email
 *
 *  @return YES on success, NO on falure
 */
+ (BOOL) clearEmail;

/**
 *  Set user attribute by ket
 *
 *  @param key string with unique key to set
 *  @param value object to set (may be string, number of boolean)
 *  @return YES on success, NO on falure
 */
+ (BOOL) setAttribute:(NSString*_Nonnull)key withValue:(id _Nonnull )value NS_SWIFT_NAME(setAttribute(_:value:));

/**
 *  Get specific user attribute by key
 *
 *  @param key string with unique key to get
 *  @return object or nil on failure
 */
+ (id _Nullable ) getAttribute:(NSString*_Nonnull)key NS_SWIFT_NAME(getAttribute(_:));

/**
 *  Clear specific user attribute by key
 *
 *  @param key string with unique key to clear
 *  @return NSString* with email on success, or nil on failure
 */
+ (BOOL) clearAttribute:(NSString*_Nonnull)key NS_SWIFT_NAME(clearAttribute(_:));

/**
 *  Clear all user attributes
 *
 *  @return YES on success, NO on falure
 */
+ (BOOL) clearAllAttributes NS_SWIFT_NAME(clearAllAttribute());

/**
 *  Hides your view on video same thing you can get from Bugsee+UIView category
 *  view.bugseeProtectedView
 *
 *  @param view     view that you need to protect
 *  @param isHidden bool value
 */
+ (void) setView:(nonnull UIView *)view asHidden:(BOOL) isHidden NS_SWIFT_NAME(setView(_:asHidden:));
+ (BOOL) isViewHidden:(nonnull UIView *) view NS_SWIFT_NAME(isViewHidden(_:));


+ (void) setDefaultCrashPriority:(BugseeSeverityLevel) level;
+ (void) setDefaultBugPriority:(BugseeSeverityLevel) level;

/**
 *  Hides your keyboard, actualy we make it automaticaly for private fields.
 *
 *  @param isHidden YES to hide keyboard, by default is NO
 */
+ (void) hideKeyboard:(BOOL) isHidden;

/**
 *  Hides part of the screen under the Rect, maximum is 10 rects
 *
 *  @param rect Hidden Rect
 *  @return YES on success, NO on falure (you add already hidden Rect)
 */
+ (BOOL) addSecureRect:(CGRect)rect;

/**
 *  Remove secure rect, if it exist
 *
 *  @param rect Hidden Rect
 *  @return YES on success, NO on falure (Rect does't exist)
 */
+ (BOOL) removeSecureRect:(CGRect)rect;

/**
 *  Remove all secure rects, can be added by [Bugsee addSecureRect:]
 */
+ (void) removeAllSecureRects;

/**
 *  Get all Rects in array of NSValue
 *
 *  @return [arr[idx] CGRectValue] to get CGRect from array.
 */
+ (NSArray * _Nullable) getAllSecureRects;

/**
 *  Crash simulators.
 */
+ (void) testExceptionCrash;
+ (void) testSignalCrash;

/**
 *  Log managed excetpions.
 *  @param name     Name
 *  @param reason   Reason
 *  @param frames   Arrays of strings, string for each frame
 *  @param type     "xamarin", "unity", "cordova"
 *  @param handled  bool value
 *  @param synchronous do it in main thread
 */
+ (void) logException:(nonnull NSString *)name reason:(nonnull NSString*)reason frames:(nonnull NSArray*)frames type:(nonnull NSString*)type handled:(BOOL)handled synchronous:(BOOL)synchronous;

/**
 *  Log managed excetpions.
 *  @param name     Name
 *  @param reason   Reason
 *  @param frames   Arrays of strings, string for each frame
 *  @param type     "xamarin", "unity", "cordova"
 *  @param handled  bool value
 */
+ (void) logException:(nonnull NSString *)name reason:(nonnull NSString*)reason frames:(nonnull NSArray*)frames type:(nonnull NSString*)type handled:(BOOL)handled NS_SWIFT_NAME(logException(name:reason:frames:type:handled:));

/**
 *  Log managed excetpions.
 *  @param exception nonnull exception here
 */
+ (void) logException:(nonnull NSException *)exception  NS_SWIFT_NAME(logException(exception:));

/**
 *  Customize bugsee colors here.
 *  @return multiply methods for color customization
 */
+ (nonnull BugseeTheme *) appearance;

@end

@interface UIView (Bugsee)

/**
 *  Hides your view on video
 */
@property (nonatomic, assign) BOOL bugseeProtectedView;

@end
