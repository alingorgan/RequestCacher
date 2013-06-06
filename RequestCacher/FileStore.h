//
//  FileStore.h
//  RequestCacher
//
//  Created by Alin Gorgan on 1/8/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RequestBuilder.h"

@protocol FileStoreDelegate;

@interface FileStore : NSObject <NSURLConnectionDelegate>

#pragma Constants
#define kMegaByte 1000000

#pragma Enums
typedef enum StoreFileType{
    
    KStoreCacheNormalFile = 0,
    KStoreCacheImageFile = 1
    
} StoreFileType;

#pragma Properties
@property (nonatomic, strong)NSURL* fileURL;
@property (nonatomic, weak) id<FileStoreDelegate> delegate;

#pragma Constructor
-(id)initWithFileURL:(NSURL *)fileURL;

#pragma Methods
+ (void)setUp;
+ (NSURL *)applicationDocumentsDirectory;

-(void)startDownload;
-(void)stopDownload;

-(NSData*)dataUsingSyncDownload;
+(NSData*)dataUsingSyncDownloadForRequestBuilder:(RequestBuilder*)builder withTimeout:(NSTimeInterval)timeout;
+(NSData*)dataUsingSyncDownloadForRequestBuilder:(RequestBuilder*)requestBuilder;
+(NSData*)dataUsingFilePath:(NSString*)filePath;

+(NSString*)pathForNewFileUsingData:(NSData*)data andFileType:(StoreFileType)fileType;
-(NSString*)pathForNewFileUsingDownloadedDataAndFileType:(StoreFileType)fileType;

+(unsigned long long int)directorySizeForFileType:(StoreFileType)fileType;
+(unsigned long long int)fileSizeWithPath:(NSString*)filePath;

+(BOOL)deleteFileWithPath:(NSString*)filePath;

@end

#pragma Delegate
@protocol FileStoreDelegate <NSObject>

@required

-(void)fileStoreFinishedDownloadingWithData:(NSData*)data forURL:(NSURL*)fileURL;

@end
