//
//  SQLManager.h
//  SQLDemo
//
//  Created by Dong on 11/13/14.
//  Copyright (c) 2014 liuxudong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "SQLObject.h"

@interface SQLManager : NSObject {
    sqlite3 *m_sqlite;
}

+ (SQLManager *)manager;

- (void)createObjectTable;

- (void)insertObject:(SQLObject *)object;

- (void)deleteObject:(SQLObject *)object;

- (void)updateObject:(SQLObject *)object;

- (NSMutableArray *)getAllObjects;

@end
