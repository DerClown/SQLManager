//
//  ViewController.m
//  SQLDemo
//
//  Created by Dong on 11/13/14.
//  Copyright (c) 2014 liuxudong. All rights reserved.
//

#import "ViewController.h"
#import "SQLManager.h"
#import "SQLObject.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[SQLManager manager] createObjectTable];
    
    SQLObject *object = [SQLObject new];
    object.objectId = 100;
    object.objHeight = 160.5;
    object.name = @"小mm";
    object.password = @"987654";
    [[SQLManager manager] updateObject:object];
    
    NSMutableArray *array = [[SQLManager manager] getAllObjects];
    NSLog(@"%@", array);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
