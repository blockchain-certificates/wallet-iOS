//
//  BugseeTheme.h
//  Bugsee
//
//  Created by ANDREY KOVALEV on 17.08.16.
//  Copyright © 2016 Bugsee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BugseeConstants.h"
#import <UIKit/UIKit.h>

#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a/255.0f]

@interface BugseeTheme : NSObject

+ (instancetype)shared;

@property (nonatomic, assign) BugseeStyle style;

/**
 *  UITableView cells background color
 */
@property (nonatomic, strong) UIColor * reportCellBackgroundColor;
/**
 *  UILabel with version number text color
 */
@property (nonatomic, strong) UIColor * reportVersionColor;
/**
 *  UILabels text color
 */
@property (nonatomic, strong) UIColor * reportTextColor;
@property (nonatomic, strong) UIColor * reportSendButtonColor;
/**
 *  UIInputFields placeholder color
 */
@property (nonatomic, strong) UIColor * reportPlaceholderColor;
@property (nonatomic, strong) UIColor * reportNavigationBarColor;
@property (nonatomic, strong) UIColor * reportBackgroundColor;
@property (nonatomic, strong) UIColor * reportCloseButtonColor;
/**
 *  Navigation bar and bottom bar color
 */
@property (nonatomic, strong) UIColor * feedbackBarsColor;
@property (nonatomic, strong) UIColor * feedbackBackgroundColor;
/**
 *  Incoming message bubble background color
 */
@property (nonatomic, strong) UIColor * feedbackIncomingBubbleColor;
/**
 *  Outgoing message bubble background color
 */
@property (nonatomic, strong) UIColor * feedbackOutgoingBubbleColor;
@property (nonatomic, strong) UIColor * feedbackIncomingTextColor;
@property (nonatomic, strong) UIColor * feedbackOutgoingTextColor;
/**
 *  UINavigationBar title color
 */
@property (nonatomic, strong) UIColor * feedbackTitleTextColor;
/**
 *  Ask for email popup skip button text color
 */
@property (nonatomic, strong) UIColor * feedbackEmailSkipColor;
/**
 *  Ask for email popup background color
 */
@property (nonatomic, strong) UIColor * feedbackEmailBackgroundColor;
/**
 *  Ask for email continue not active button background color
 */
@property (nonatomic, strong) UIColor * feedbackEmailContinueNotActiveColor;
/**
 *  Ask for email continue button background color
 */
@property (nonatomic, strong) UIColor * feedbackEmailContinueActiveColor;
@property (nonatomic, strong) UIColor * feedbackInputTextColor;
@property (nonatomic, strong) UIColor * feedbackCloseButtonColor;
@property (nonatomic, strong) UIColor * feedbackNavigationBarColor;

@property (nonatomic, strong, readonly) UIColor * mainBugseeColor;
@property (nonatomic, strong, readonly) UIColor * lowBugColor;
@property (nonatomic, strong, readonly) UIColor * mediumBugColor;
@property (nonatomic, strong, readonly) UIColor * dotSelectorColor;

@end
