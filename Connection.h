//
//  Connection.h
//  Client
//
//  Created by Simon Bogutzky on 03.04.12.
//  Copyright 2012 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Connection : NSObject <NSXMLParserDelegate>

@property (nonatomic, copy) NSString *host;
@property (nonatomic, strong) NSOperationQueue *queue;

- (id)initWithHost:(NSString *)host;
- (void)aAddWithControllerPath:(NSString *)controllerPath bodyAsString:(NSString *)bodyAsString completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler;
- (void)aEditWithControllerPath:(NSString *)controllerPath objectId:(unsigned long)objectId bodyAsString:(NSString *)bodyAsString completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler;
- (void)aIndexWithControllerPath:(NSString *)controllerPath completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler;
- (void)aViewWithControllerPath:(NSString *)controllerPath bodyAsString:(NSString *)bodyAsString completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler;
- (void)aAttachFileWithControllerPath:(NSString *)controllerPath fileAsData:(NSData *)fileAsData contentDispositionName:(NSString *)contentDispositionName contentType:(NSString *)contentType completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler;

@end
