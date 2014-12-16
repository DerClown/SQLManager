//
//  SQLManager.m
//  SQLDemo
//
//  Created by Dong on 11/13/14.
//  Copyright (c) 2014 liuxudong. All rights reserved.
//

#import "SQLManager.h"

#define kSQLFileName   @"data.sqlite"

@implementation SQLManager

+ (SQLManager *)manager {
    static dispatch_once_t onceTocken;
    static SQLManager *instance = nil;
    dispatch_once(&onceTocken, ^{
        instance = [[SQLManager alloc] init];
    });
    return instance;
}

- (id)init {
    if (self = [super init]) {
        m_sqlite = nil;
    }
    return self;
}

//数据库文件保存路径
- (NSString *)filePath {
    NSString *filePath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", kSQLFileName];
    return filePath;
}

/**
 *  判断表是否存在 (p_p*----*  这里有点点小小的误差，这里只是使用了数据查询；如果查询的条数为0就判断这个表不存在，其实表有可能已经存在；但这个也不碍事，如果表已经创建了，再调用创建表方法，也不会再创建一次  *----*q_q)。
 *
 *  @param tableName 数据库表
 *
 *  @return YES 表示表已经存在 NO 表有可能存在，此时表的没有数据；表不存在
 */
- (BOOL)isExistsTableWithTableName:(NSString *)tableName {
    if (![self connectSQL]) {
        return NO;
    }
    
    //1. sqlite句柄,对数据的一些绑定查询操作（eg：如果不用句柄，那也不需要用到数据库编译语句；直接使用sqlite3_exce语法操作数据库)
    sqlite3_stmt *stmt = nil;
    
    NSString *checkSql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = '%@'", tableName];
    
    //将sql语句编译解析到sqlite句柄
    int res = sqlite3_prepare_v2(m_sqlite, [checkSql UTF8String], -1, &stmt, nil);
    if (res != SQLITE_OK) {
        [self closeSQL];
        NSLog(@"Error: failed to prepare stmt.");
        return NO;
    }
    
    res = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    [self closeSQL];
    
    if (res != SQLITE_ERROR) {
        NSLog(@"table %@ has values", tableName);
        return YES;
    }
    
    
    /**************2. 使用sqlite执行语法*******************/
    //    char *errorMsg;
    //    res = sqlite3_exec(m_sqlite, [checkSql UTF8String], NULL, NULL, &errorMsg);
    //    if (res != SQLITE_OK) {
    //        NSLog(@"执行查询sqlite语句失败。");
    //    } else {
    //        NSLog(@"执行查询成功");
    //    }
    //    //最后关闭数据库
    //    [self closeSQL];
    /***************************************************/
    
    return NO;
}

//打开数据库
- (BOOL)connectSQL {
    NSString *dbFilePath = [self filePath];
    //如果数据库文件不存在，会自动创建；创建了就不会再创建
    if (sqlite3_open([dbFilePath UTF8String], &m_sqlite) != SQLITE_OK) {
        NSLog(@"failed to open m_sqlite.");
        [self closeSQL];
        return NO;
    }
    
    return YES;
}

/**
 *  创建表
 */
- (void)createObjectTable {
    if (![self connectSQL]) {
        return;
    }
    sqlite3_stmt *stmt = nil;
    
    //创建语句，第一个id是自增关键key字段，同时还需要为字段知名类型(text integer double int)
    NSString *createSql = @"CREATE TABLE IF NOT EXISTS Object(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, uniqueId INTEGER DEFAULT 0, height DOUBLE DEFAULT 0.0, username TEXT, password TEXT)";
    
    //将sql语句编译到句柄
    int res = sqlite3_prepare_v2(m_sqlite, [createSql UTF8String], -1, &stmt, nil);
    if (res != SQLITE_OK) {
        NSLog(@"Error: failed to prepare stmt");
        [self closeSQL];
        return;
    }
    
    //执行sql
    int success = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    [self closeSQL];
    
    if (success != SQLITE_DONE) {
        NSLog(@"Error: failed to dehydrate: create table Object");
    }
}


/**
 *  插入数据
 *
 *  @param object 数据对象
 */
- (void)insertObject:(SQLObject *)object {
    if (![self connectSQL]) {
        return;
    }
    
    sqlite3_stmt *stmt = nil;
    
    NSString *insertSql = @"INSERT INTO Object(uniqueId, height, username, password)VALUES(?, ?, ?, ?)";
    
    int res = sqlite3_prepare_v2(m_sqlite, [insertSql UTF8String], -1, &stmt, nil);
    
    if (res != SQLITE_OK) {
        NSLog(@"Error: failed to insert Object table.");
        [self closeSQL];
        return;
    }
    
    //将对应的数据绑定到句柄上（绑定的数据类型也要和创建表时的数据类型一致），1，2，3，4表示第几个问好,上面是用来占位符
    sqlite3_bind_int(stmt, 1, (int)object.objectId);
    sqlite3_bind_double(stmt, 2, object.objHeight);
    sqlite3_bind_text(stmt, 3, [object.name UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 4, [object.password UTF8String], -1, SQLITE_TRANSIENT);
    
    res = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    [self closeSQL];
    
    if (res == SQLITE_ERROR) {
        NSLog(@"Error: failed to insert into the data with message.");
    }
}

- (void)updateObject:(SQLObject *)object {
    if (![self isExistsTableWithTableName:@"Object"]) {
        return;
    }
    
    if (![self connectSQL]) {
        return;
    }
    
    sqlite3_stmt *stmt = nil;
    //更新某一行数据的值，通过条件也可以更新一序列
    //语法：UPDATE +YOU_TABLE_NAME+ SET YOU_COLUMN_NAME WHERE +YOU_CANDICATION+
    //更新一序列 UPDATE Object SET password = ? username = ?, height = ? WHERE uniqueId LIKE '100';
    NSString *updateSql = @"UPDATE Object SET password=?,username=?,height=? WHERE uniqueId=?";
    int res = sqlite3_prepare_v2(m_sqlite, [updateSql UTF8String], -1, &stmt, nil);
    if (res != SQLITE_OK) {
        NSLog(@"Error: failed to update Object table.");
        [self closeSQL];
        return;
    }
    
    sqlite3_bind_text(stmt, 1, [object.password UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, [object.name UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_double(stmt, 3, object.objHeight);
    sqlite3_bind_int(stmt, 4, (int)object.objectId);
    
    res = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    [self closeSQL];
    
    if (res == SQLITE_ERROR) {
        NSLog(@"Error: failed to update the database with message.");
    }
}

- (void)deleteObject:(SQLObject *)object {
    if (![self connectSQL]) {
        return;
    }
    
    sqlite3_stmt *stmt = nil;
    //删除某一行的数据 通过条件判断也可以删除一序列的值
    //语法：DELETE FROM +YOU_TABLE_NAME+ WHERE +YOU_CANDICATION+
    //删除一序列eg：DELETE FROM Object WHERE uniqueId LIKE '100'
    char *deleteSql = "DELETE FROM Object WHERE uniqueId = ?";
    
    int success = sqlite3_prepare_v2(m_sqlite, deleteSql, -1, &stmt, nil);
    if (success != SQLITE_OK) {
        NSLog(@"Error: failed to delete object");
        [self closeSQL];
        return;
    }
    
    sqlite3_bind_int(stmt, 1, (int)object.objectId);
    
    success = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    [self closeSQL];
    
    if (success == SQLITE_ERROR) {
        NSLog(@"Error: failed to delete the database with message.");
    }
}
/**
 *  查询数据库
 *
 *  @return 返回查找的所有数据
 */
- (NSMutableArray *)getAllObjects {
    if (![self connectSQL]) {
        return nil;
    }
    
    //查询无语就要用到句柄了
    sqlite3_stmt *stmt = nil;
    NSString *query = @"SELECT * FROM Object";
    /*
     * 其他方式的查找语句; @"SELECT 这里可以指定你要查找的字段名 FROM +YOU_TABLE_NAME+ WHERE +YOU_SEARCH_CANDICATION+"
     * eg: "SELECT username, password FROM Object WHERE uniqueId LIKE '小'" ...
     */
    
    //将sql语句编译到句柄中.
    int success = sqlite3_prepare_v2(m_sqlite, [query UTF8String], -1, &stmt, nil);
    
    //失败就关闭数据库，返回一个nil值
    if (success != SQLITE_OK) {
        NSLog(@"Error: failed to prepare statement with message:get all objects.");
        [self closeSQL];
        return nil;
    }
    
    //这里进行查找了...sqlite3_step 这个就是MYSQL中的游标了，查找好一条数据，将游标指向下一条数据
    int result = sqlite3_step(stmt);
    
    NSMutableArray *allObjects = [NSMutableArray array];
    //判断行数是不是有,没有就不继续查找了获取数据了.
    while (result == SQLITE_ROW) {
        SQLObject *object = [SQLObject new];
        //这里的0，1，2，3必须和你的创建表的字段的位置对上，不然数据会错乱.
        object.objectId = sqlite3_column_int(stmt, 0);
        object.objHeight = sqlite3_column_double(stmt, 1);
        
        char *name = (char *)sqlite3_column_text(stmt, 2);
        char *password = (char *)sqlite3_column_text(stmt, 3);
        object.name = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        object.password = [NSString stringWithCString:password encoding:NSUTF8StringEncoding];
        
        [allObjects addObject:object];
        
        result = sqlite3_step(stmt);
    }
    
    sqlite3_finalize(stmt);
    [self closeSQL];
    
    return allObjects;
}

- (void)closeSQL {
    if (m_sqlite) {
        sqlite3_close(m_sqlite);
    }
}

@end
