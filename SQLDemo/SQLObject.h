//
//  SQLObject.h
//  SQLDemo
//
//  Created by Dong on 11/13/14.
//  Copyright (c) 2014 liuxudong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SQLObject : NSObject

@property (nonatomic, assign) NSInteger objectId;
@property (nonatomic, assign) float objHeight;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *password;

@end
