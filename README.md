RequestCacher [![Build Status](https://travis-ci.org/alingorgan/RequestCacher.png)](https://travis-ci.org/alingorgan/RequestCacher)
===========

<p>A ready to use data caching module for iOS5+</p>

![screenshot](https://raw.github.com/alingorgan/RequestCacher/master/requestcacher.png)

# Description

<p>RequestCacher was built initially for caching image files but I've extended it to handle any type of request responses.
RequestCacher is an alternative to Apple's native caching system (NSURLCache), but provides a greater level of control on how data is cached and for how long to cache it.
Generally, for image caching, it's very easy to use within your project, just provide an url for the image.</p>

RequestCacher automatically does the following, for you:
- Caches data, fast
- Creates a local database to keep track of stored data
- Stores data on the local storage
- Refetches data, if necessary
- Self maintainable

Takes care of:
- Cache data file managing
- Database managing
- Expired data checking, which may need to be refetched
- Automatically cleans data, if the cache size exceedes a specified size limit
- Internet connectivity issues.
- Multitheading
- Managing multiple ongoing and unfinished requests.
- GETing or POSTing data.
- Async data downloading


# Usage

Practically a no brainer set-up (ex: image caching):
- Add the files to your project
- Use the custom UIImageView control for image caching
- Give it an url or an array of them
- Done


## Using the custom UIImageView control is dead simple</p>
```objective-c
[imageViewControl loadImageWithURL:[NSURL URLWithString:[some_url_string]]];
```


## Do it yourself
```objective-c
RequestBuilder *requestBuilder = [[RequestBuilder alloc] initWithRequestURL:self.photoURL];
    
    [RequestConductor performRequest: requestBuilder
                  andCompletionBlock: ^void(ResponseCart** responseCart) {
                        
                        ///Still on another thread                   
                        (*responseCart).shouldCache = YES;
                        (*responseCart).cacheTimeout = 60;
       
                        dispatch_sync(dispatch_get_main_queue(), ^{
                                 ///Update the UI, on the main thread, with the downloaded data
                        });
   }];
```

<p>Take advantage of the test project. It's ready to use, so just run it, and see the advantages of RequestCacher.</p>
 

# Benefits

In detail, RequestCacher integrates the following features:
- Allows you control how long a request is cached. 
- Allows you control control the cache storage size. 
  If the cache storage excedes a specified amount of megabytes, it automatically runs a maintenance cycle to remove data (old data first), until the cache size is below the maximum limit by a margin.
- Choose whether a cached response is invalid and needs to be refetched from the server. For instance, if you have requested a photo, which was cached some time ago, and you know that the response photo (returned by the same request) is likely to change frequently, you can choose to dismiss the cached version and have the RequestCacher fetch the latest data.
- Manages multiple unfinished ongoing requests. When continuously scrolling a TableView, up and down, if cells need to display photos off an online source, you might end up with multiple ongoing and unfinished requests for the same content and you might download the same content multiple times. RequestCacher handles that, and queues multiple identical requests, so after the first one is finished, the rest will get data from cache, instantly.
- Allows you control control the number of retries and timeouts
- Retrieves data via GET or POST
- Uses CoreData in a multithreaded environment
- Detects internet connectivity


# Contribute (MIT LICENSE)

This is my contribution to the open source comunity, and feel free to contribute yourself.
If you just want to use it, go ahead, no strings attached.


