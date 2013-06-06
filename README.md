RequestCacher [![Build Status](https://travis-ci.org/alingorgan/RequestCacher.png)](https://travis-ci.org/alingorgan/RequestCacher)
===========

A ready to use data caching module for iOS5+

RequestCacher automatically does the following, for you:
- Caches data, fast
- Creates a local database to keep track of stored data
- Stores data on the local storage
- Refetches data, if necessary
- Self maintainable


Practically a no brainer set-up (ex: image caching):
- Add the files to your project
- Use the custom UIImageView control for image caching
- Give it an url or an array of them
- Done

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

