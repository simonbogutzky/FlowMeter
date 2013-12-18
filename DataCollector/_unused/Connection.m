//
//  Connection.m
//  Client
//
//  Created by Simon Bogutzky on 03.04.12.
//  Copyright 2012 Simon Bogutzky. All rights reserved.
//

#import "Connection.h"

@implementation Connection

- (id)initWithHost:(NSString *)aHost
{
	self = [super init];
	if (self != nil) {
		_host = aHost;
        _queue = [[NSOperationQueue alloc] init];
	}
	return self;
}

- (void)aAddWithControllerPath:(NSString *)controllerPath bodyAsString:(NSString *)bodyAsString completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler {
    NSString *urlAsString = [NSString stringWithFormat:@"%@%@.xml", _host, controllerPath];
    NSURL *url = [NSURL URLWithString:urlAsString];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setTimeoutInterval:30.0f];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setHTTPBody:[[NSString stringWithFormat:@"%@%@", @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>", bodyAsString] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:_queue completionHandler:handler];
    NSLog(@"# Request sent");
}

- (void)aEditWithControllerPath:(NSString *)controllerPath objectId:(unsigned long)objectId bodyAsString:(NSString *)bodyAsString completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler {
    NSString *urlAsString = [NSString stringWithFormat:@"%@%@/%lu.xml", _host, controllerPath, objectId];
    NSURL *url = [NSURL URLWithString:urlAsString];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setTimeoutInterval:30.0f];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setHTTPBody:[[NSString stringWithFormat:@"%@%@", @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>", bodyAsString] dataUsingEncoding:NSUTF8StringEncoding]];;
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:_queue completionHandler:handler];
    NSLog(@"# Request sent");
}

- (void)aIndexWithControllerPath:(NSString *)controllerPath completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler{
    NSString *urlAsString = [NSString stringWithFormat:@"%@%@.xml", _host, controllerPath];
    NSURL *url = [NSURL URLWithString:urlAsString];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setTimeoutInterval:30.0f];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:_queue completionHandler:handler];
    NSLog(@"# Request sent");
}

- (void)aViewWithControllerPath:(NSString *)controllerPath bodyAsString:(NSString *)bodyAsString completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler {
    NSString *urlAsString = [NSString stringWithFormat:@"%@%@.xml", _host, controllerPath];
    NSURL *url = [NSURL URLWithString:urlAsString];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setTimeoutInterval:30.0f];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setHTTPBody:[[NSString stringWithFormat:@"%@%@", @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>", bodyAsString] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:_queue completionHandler:handler];
    NSLog(@"# Request sent");
}

- (void)aAttachFileWithControllerPath:(NSString *)controllerPath fileAsData:(NSData *)fileAsData contentDispositionName:(NSString *)contentDispositionName contentType:(NSString *)contentType completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler {
    NSString *urlAsString = [NSString stringWithFormat:@"%@%@.xml", _host, controllerPath];
    NSURL *url = [NSURL URLWithString:urlAsString];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setTimeoutInterval:30.0f];
    [urlRequest setHTTPMethod:@"POST"];
    
    NSString *boundary = @"---------------------------168072824752491622650073";
    NSString *cType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [urlRequest addValue:cType forHTTPHeaderField: @"Content-Type"];
    
    NSString *fileExtension = @"";
    if ([contentType isEqualToString:@"application/zip"]) {
        fileExtension = @"zip";
    }
    
    NSMutableData *postData = [NSMutableData data];
    [postData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"tmp.%@\"\r\n", contentDispositionName, fileExtension] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[[NSString stringWithFormat:@"Content-Type:%@ \r\n\r\n", contentType] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[NSData dataWithData:fileAsData]];
    [postData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [urlRequest setHTTPBody:postData];
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:_queue completionHandler:handler];
    NSLog(@"# Request sent");
}

@end
