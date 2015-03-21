//
//  DBManager.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 21.03.15.
//  Copyright (c) 2015 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBManager : NSObject

-(instancetype)initWithDatabaseFilename:(NSString *)dbFilename;
-(NSArray *)loadDataFromDB:(NSString *)query;
-(void)executeQuery:(NSString *)query;
-(NSString *)writeCSVFromQuery:(NSString *)query inFileWithFilename:(NSString *)filename andHeader:(NSString *)header;

@property (nonatomic, strong) NSMutableArray *arrColumnNames;
@property (nonatomic) int affectedRows;
@property (nonatomic) long long lastInsertedRowID;

@end
