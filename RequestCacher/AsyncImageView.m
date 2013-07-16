//
//  AsyncImageView.m
//  RequestCacher
//
//  Created by Alin Gorgan on 1/7/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import "AsyncImageView.h"
#import "RequestBuilder.h"
#import "RequestConductor.h"
#import "ResponseCart.h"

@interface AsyncImageView()

@property (nonatomic, strong) NSString* requestTicket;

@end

@implementation AsyncImageView

@synthesize photoURL = _photoURL;
@synthesize photoURLParams = _photoURLParams;
@synthesize requestTicket = _requestTicket;
@synthesize shouldDisplayActivityIndicator = _shouldDisplayActivityIndicator;

#pragma ------------------------------------------------------------------------------------------------------
#pragma Load data for the requested image url and params (if any)
#pragma ------------------------------------------------------------------------------------------------------
-(void)loadImageWithURL:(NSURL*)photoURL{
    [self loadImageWithURL:photoURL withParams:nil];
}

-(void)loadImageWithURL:(NSURL*)photoURL withParams:(NSString*)urlParams{
    
    self.image = nil;
    self.photoURL = photoURL;
    self.photoURLParams = urlParams;
    
    RequestBuilder *requestBuilder = [[RequestBuilder alloc] initWithRequestURL:self.photoURL];
    
    if (self.photoURLParams != nil){
        requestBuilder.requestType = RequestUsingPost;
        requestBuilder.paramsString = urlParams;
    }
    
    self.requestTicket = [RequestConductor performRequest:requestBuilder
                                       andCompletionBlock:^void(ResponseCart** responseCart) {
                                           
                                           (*responseCart).shouldCache = YES;
                                           (*responseCart).cacheTimeout = 60;
       
                                           dispatch_sync(dispatch_get_main_queue(), ^{
                                               if ([self.requestTicket isEqualToString:(*responseCart).ticket]){
                                                   [self setImageUsingData:(*responseCart).responseData];
                                               }
                                           });
   }];
}

#pragma ------------------------------------------------------------------------------------------------------
#pragma Sets the image data to the UI
#pragma ------------------------------------------------------------------------------------------------------
-(void)setImageUsingData:(NSData*)downloadedData{
    self.image = [UIImage imageWithData:downloadedData];
}

@end
