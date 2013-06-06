//
//  FileStore.m
//  RequestCacher
//
//  Created by Alin Gorgan on 1/8/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import "FileStore.h"
#import "HostReachability.h"
#import "RequestBuilder.h"

@interface FileStore ()

@property (nonatomic, strong) NSURLConnection* connection;
@property (nonatomic, strong) NSMutableData* downloadedData;

@end

@implementation FileStore

@synthesize fileURL = _fileURL;
@synthesize delegate = _delegate;

#define STORE_NORMAL_FILE_FOLDER_NAME @"FileStore"
#define STORE_IMAGE_CACHE_FOLDER_NAME @"ImageCache"
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

-(id)initWithFileURL:(NSURL *)fileURL{
    if (self = [super init]){
        ///custom initialization
        self.fileURL = fileURL;
    }
    return self;
}

#pragma ------------------------------------------------------------------------------------------------------
#pragma Set up the file store. This is peformed only once
#pragma ------------------------------------------------------------------------------------------------------
+ (void)setUp{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FileStore createStoreDirectories];
    });
}


#pragma ------------------------------------------------------------------------------------------------------
#pragma Download data from the web
#pragma ------------------------------------------------------------------------------------------------------

///sync download with retry timeout. To be used on a separate thread
+(NSData*)dataUsingSyncDownloadForRequestBuilder:(RequestBuilder*)builder withTimeout:(NSTimeInterval)timeout{
    
    /// check if the host is reachable
    if ([HostReachability isReachableHost:builder.url] == NO){
        NSLog(@"%@ is unreachable", builder.url);
        return nil;
    }
    
    NSDate* startDate = [NSDate date];
    
    if (timeout <= 0){
        NSLog(@"request timeout");
        return nil;
    }
    
    NSData *downloadedData = [FileStore dataUsingSyncDownloadForRequestBuilder:builder];
    
    if (downloadedData.length == 0){
        NSLog(@"retrying");
        NSTimeInterval newTimeout =  timeout + [startDate timeIntervalSinceNow];
        return [FileStore dataUsingSyncDownloadForRequestBuilder:builder withTimeout:newTimeout];
    }
    
    return downloadedData;
}

///sync download. To be used on a separate thread
+(NSData*)dataUsingSyncDownloadForRequestBuilder:(RequestBuilder*)requestBuilder{
        
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestBuilder.url
                                                           cachePolicy:NSURLCacheStorageNotAllowed
                                                       timeoutInterval:60.0];
    
    if (requestBuilder.requestType == RequestUsingPost){
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[requestBuilder.paramsString dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    NSData* downloadedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (error){
        NSLog(@"%@", [error description]);
    }

    return downloadedData;
}

-(NSData*)dataUsingSyncDownload{
    NSError* error = nil;
    self.downloadedData = [NSData dataWithContentsOfURL:self.fileURL options:NSDataReadingUncached error:&error];
    
    if (error){
        NSLog(@"%@", [error description]);
    }
    
    return self.downloadedData;
}

/// start an async download
-(void)startDownload{
    self.connection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:self.fileURL] delegate:self];
    NSLog(@"starting download of: %@", self.fileURL);
    [self.connection start];
}

/// stop an async download
-(void)stopDownload{
    [self.connection cancel];
    self.downloadedData = nil;
    [self fileDownloadFinished:nil];
}

/// used to notify a listner about the completion of a download
-(void)fileDownloadFinished:(NSError*)error{
    if (self.delegate){
        if ([self.delegate respondsToSelector:@selector(FileStoreFinishedWithData:forURL::)]){
            [self.delegate fileStoreFinishedDownloadingWithData:error == nil ? self.downloadedData : nil forURL:self.fileURL];
        }
    }
}

#pragma ------------------------------------------------------------------------------------------------------
#pragma Connection handlers (NSURLConnectionDelegate)
#pragma ------------------------------------------------------------------------------------------------------
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [self fileDownloadFinished:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [self.downloadedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    [self fileDownloadFinished:nil];
}

#pragma ------------------------------------------------------------------------------------------------------
#pragma Save/retrieve data to/from the local storage
#pragma ------------------------------------------------------------------------------------------------------

///
/// Save data at the specified file url
-(NSString*)pathForNewFileUsingDownloadedDataAndFileType:(StoreFileType)fileType{
    return [FileStore pathForNewFileUsingData:self.downloadedData andFileType:fileType];
}

///
/// Save data at a newly generated path
/// the new file name will be unique every time
+(NSString*)pathForNewFileUsingData:(NSData*)data andFileType:(StoreFileType)fileType{
    
    if (data == nil){
        return nil;
    }
    
    NSString* filePath = [FileStore pathForNewFileUsingType:fileType fileName:[FileStore newUniqueName]];
    NSLog(@"%@", filePath);
    NSError* error;
    if ([data writeToFile:filePath options:NSDataWritingFileProtectionNone error:&error]){
        /// the file was successfully created, return it's path
        return filePath;
    }
    
    if (error != nil){
        NSLog(@"error writing to file: %@", [error userInfo]);
    }
    
    return nil;
}

///
/// Retrieve data from the specidied file path
+(NSData*)dataUsingFilePath:(NSString*)filePath{
    NSLog(@"from file %@", filePath);
    return [NSData dataWithContentsOfFile:filePath];
}

///
/// Creates the cache directories, if necessary
+(void)createStoreDirectories{
    
    [FileStore createDirectoryForFileType:KStoreCacheNormalFile];
    [FileStore createDirectoryForFileType:KStoreCacheImageFile];
}

///
/// Create a specific directory for the given resource type 
+(void)createDirectoryForFileType: (StoreFileType)fileType{
    
    NSString* filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    switch (fileType) {
        case KStoreCacheNormalFile:
            filePath = [filePath stringByAppendingFormat:@"/%@", STORE_NORMAL_FILE_FOLDER_NAME];
            break;
        case KStoreCacheImageFile:
            filePath = [filePath stringByAppendingFormat:@"/%@", STORE_IMAGE_CACHE_FOLDER_NAME];
        default:
            break;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:&error];
        
        if (error){
            NSLog(@"error creating file store directory: %@", [error description]);
        }
    }
}

///
/// Delete a file with the specified path
+(BOOL)deleteFileWithPath:(NSString*)filePath{
    NSError *error = nil;
    if (![[NSFileManager defaultManager] removeItemAtPath:filePath error:&error]){
        NSLog(@"error deleting cached file: %@", [error description]);
        return NO;
    }
    return YES;
}

#pragma ------------------------------------------------------------------------------------------------------
#pragma Query for file/directory sizes
#pragma ------------------------------------------------------------------------------------------------------
///
/// Return the directory, in bytes, size for a specific cached resource type
+(unsigned long long int)directorySizeForFileType:(StoreFileType)fileType{
    NSString* directoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    switch (fileType) {
        case KStoreCacheNormalFile:
            directoryPath = [directoryPath stringByAppendingFormat:@"/%@", STORE_NORMAL_FILE_FOLDER_NAME];
            break;
        case KStoreCacheImageFile:
            directoryPath = [directoryPath stringByAppendingFormat:@"/%@", STORE_IMAGE_CACHE_FOLDER_NAME];
        default:
            break;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath]){
        
        return [self folderSizeWithPath: directoryPath];
    }
    return 0;
}

///
/// Returns the directory, in bytes, size for a given directory path
+ (unsigned long long int)folderSizeWithPath:(NSString *)folderPath {
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    unsigned long long int fileSize = 0;
    
    while (fileName = [filesEnumerator nextObject]) {
        fileSize += [FileStore fileSizeWithPath:[folderPath stringByAppendingPathComponent:fileName]];
    }
    
    return fileSize;
}

///
/// Returns the file size, in bytes, for a given file path
+(unsigned long long int)fileSizeWithPath:(NSString*)filePath{
    NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    return [fileDictionary fileSize];
}

#pragma ------------------------------------------------------------------------------------------------------
#pragma Path related methods
#pragma ------------------------------------------------------------------------------------------------------
///
/// Generate a new UUID
+(NSString *)newUniqueName
{
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")){
        return [[NSUUID UUID] UUIDString];
    }

    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    NSString * uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    CFRelease(newUniqueId);
    
    return uuidString;
}

///
// Returns the URL to the application's Documents directory.
+ (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

///
/// Returns a new full file name
+(NSString*)pathForNewFileUsingType:(StoreFileType)fileType fileName:(NSString*)fileName{
    
    NSString* filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    switch (fileType) {
        case KStoreCacheNormalFile:
            filePath = [filePath stringByAppendingFormat:@"/%@/%@.%@", STORE_NORMAL_FILE_FOLDER_NAME, fileName, @"tmp"];
            break;
        case KStoreCacheImageFile:
            filePath = [filePath stringByAppendingFormat:@"/%@/%@.%@", STORE_IMAGE_CACHE_FOLDER_NAME, fileName, @"jpg"];
        default:
            break;
    }
    
    return filePath;
}

@end
