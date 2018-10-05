//
//  BugseeLogEvent.h
//  Bugsee
//
//  Created by ANDREY KOVALEV on 20.12.2017.
//  Copyright © 2017 Bugsee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BugseeConstants.h"
#import "BugseeLogger.h"

@interface BugseeLogEvent : NSObject

@property (nonatomic, strong) NSString * text;
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, assign) BugseeLogLevel level;

@end
