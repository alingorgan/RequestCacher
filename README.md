RequestCacher
===========

A ready to use data caching module for iOS5+

RequestCacher automatically does the following, for you:
- caches data, fast
- creates a local database to keep track of stored data
- stores data on the local storage
- refetches data, if necessary
- self maintainable


Practically a no brainer set-up
- Add the files to your project
- Use the custom UIImageView control
- Give it an url or an array of them
- Done

Takes care of:
- Cache file managing
- Database managing
- Expired data checking, which may need to be refetched
- Automatically cleans data, if the cache size exceedes a specified size limit
- Internet connectivity issues.
- Multitheading
- Managing multiple ongoing and unfinished requests.
- GETing or POSTing data.
- Async data downloading

