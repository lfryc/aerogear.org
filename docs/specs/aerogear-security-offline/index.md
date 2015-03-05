---
layout: post
section: docs
title: Offline Storage Specification (OSS)
---

# Status: Experimental (0.0.1)

**Note**: This document is a working progress if you strongly disagree with something, feedback is welcome.

# Authors

- [Bruno Oliveira](http://blog.abstractj.org/contact/)
- Daniel Passos

# Goals

- Permit users to authenticate when the server is offline
- Encrypt the local storage and the temporary cached data to protect user's privacy

# Introduction

Offline storage is still a challenging subject for mobile development, because it's a wild environment where developers don't have any control over it. Users can have their devices stolen, borrowed by someone or infected with whatever kind of malware is available. There is no magic, most part of the time you can just hope for the best and try to conciliate security and usability.

The [previous release](https://issues.jboss.org/browse/AGSEC-156?jql=fixVersion%20%3D%20%221.3.0%22%20AND%20project%20%3D%20AGSEC) our major concern was to create the bare minimum of code needed for future growth. This documentation will discuss: caching and offline storage, how to protect both and some possibilities for data sync.

## Caching

Temporally store information like documents, images or presentations — sometimes is required to improve the user experience. That doesn't mean they are less significant or critical, we never know which kind of file will be there.

By default we chose [LRU (*Least Recently Used*)](http://en.wikipedia.org/wiki/Cache_algorithms#Least_Recently_Used) as our caching mechanism. Based on the state of data that have been used recently. The API knows that most frequent used data will probably be used again in the future.

### Policy

The API will attempt to retrieve data from the cache — if of course, data was previously cached — otherwise, a request is sent to the remote resource. All the cached resources stay in memory while the application is opened. Once the application is closed, objects in memory must be persisted to the file system.

![](http://photon.abstractj.org/cdraw_429439_pixels_20140505_115014_20140505_115017.jpg)

Each and every idea will be evaluated to make sure that it works in every platform, including: iOS, Android and JavaScript.

### Configuration

The initial configuration will come in two flavors combined for better performance: memory (faster) and disk (slowly). Developers will be allowed to choose, although by default it will come like was described at policy section.

### Implementation details

Each platform has its own specific implementation details. All we can do is our best to keep the symmetry between APIs, but behind the scenes is almost impossible to have identical technical details.

#### Android

Android already implements its own [LruCache](http://developer.android.com/reference/android/util/LruCache.html). The missing bits are related with the caching policy and testing to make sure that performance won't be a problem.

A PoC to validate some concepts was created: [AeroGear Android Offline](https://github.com/danielpassos/aerogear-android-offline) and [AeroGear Android Offline Demo](https://github.com/danielpassos/aerogear-android-offline-demo).

- Related Jiras:

    * [AGDROID-238](https://issues.jboss.org/browse/AGDROID-238)


#### API overview

- CacheManager: A factory and provider for different cache implementations.

- Cache: Interface for multiple caching support like memory and disk.

- CacheTypes: Enum types with values MEMORY and DISK.

- CacheConfig: Caching configuration parameters like size, type and encryption

#### How to use it

##### Creating

Developers can implement their own *caching configuration* strategy if they want to. This way users are free to choose whatever library best fits
their needs.

    public class MyCacheConfig extends CacheConfig<MyCacheConfig> {
        public <K, V> MyCrazyCache<K, V> createMyCrazyCache() {
            return new MyCrazyCache<String, URL>()
        }
    }

Otherwise, people just willing to cache their resources can stick with defaults.

    CacheManager cacheManager = new CacheManager();

    //Internally instantiates a default cache config in Memory
    Cache<String, File> cache = cacheManager.cache("fileMemoryCache");

    cache.init(new Callback<Cache>() {
        @Override
        public void onSuccess(Cache cache) {
            //do something amazing
        }

        @Override
        public void onFailure(Exception e) {
            //name the names responsible for this
        }
    });


Or specify some of the caching types already existent.

    //Inform an specific caching configuration
    CacheConfig cacheConfig = new CacheConfig(CacheTypes.MEMORY);

    Cache<String, File> cache = cacheManager.cache("fileMemoryCache", cacheConfig);

    cache.init(new Callback<Cache>() {
        @Override
        public void onSuccess(Cache cache) {
            //do something amazing
        }

        @Override
        public void onFailure(Exception e) {
            //name the names responsible for this
        }
    });


##### Caching

Include a new file is supposed to be dead simple, just invoke *put* to save or update the data with *key* name and *file* as argument. Behind the scenes file will be added to the cache previously initialized.

    File file = //some file coming from Universe
    cache.put(fileDownloaded.getName(), fileDownloaded);

##### Retrieval

Before sending any requests to the server, might be interesting to check if the data already exists locally. This method allows to retrieve the data based on the *key* provided.

**Note**: Maybe for the next releases we could implement some additional policies like automatically check the cache before sending requests to the server.

    myCache.get(fileDownloaded.getName());

##### Removing

The removal of local cache on logout is not planned for this release, but is possible to include on the list of policies for further release. The current API allows developers to purge objects from disk, once the equivalent *key* is provided.

    myCache.remove(fileDownloaded.getName());


#### iOS

##### TBD

- Some ideas from Christos
  * Core data plus the implementation of adapters for Memory and Disk.

#### JavaScript

##### AppCache or Server

JavaScript is a completely different environment from native platforms. Implementing caching on the client side would be silly since solutions for caching have existed for years. Developers willing to cache data with JavaScript, must stick with Server Caching or AppCache — even if it's [a douchebag](http://alistapart.com/article/application-cache-is-a-douchebag).

## Encrypted Storage

The API must allow the local storage to be self-encrypted, by that we mean once **KeyStore/KeyChain** is opened, any data inserted was supposed to be properly encrypted.

## Offline storage

AeroGear already comes with several options for offline storage, thankfully to our team. Here comes some options:

- Android: Memory, SQLite
- iOS: Memory, SQLite
- JavaScript: Memory, Session Local, Indexed DB and WebSQL

All the storage mechanisms already support password-based encryption with *AES-GCM*.

## Offline Authentication

Server-side authentication is easy compared to offline, because we don't need to worry about how passwords will be kept on the server (from the client- side perspective). When the device goes offline some critical problem will emerge like users will lose their access to the application, sensitive data being exposed to attackers or data loss.

On the bright side the solution in theory is simple at first glance. The application requests users to provide their
credentials the first time the application is started, but the password **can't** be kept on device. That would represent a risk if device is stolen, lost, borrowed or infected with malware.

The proposed solution is to make use of cryptographic functions in an attempt to slow down an adversary in case the user's device is compromised.

### Password registration

![](http://photon.abstractj.org/cdraw_368448_pixels_20140502_162611_20140502_162614.jpg)

### Offline authentication

![](http://photon.abstractj.org/cdraw_284352_pixels_20140502_163240_20140502_163242.jpg)

## Data encryption

### Storage

![](http://photon.abstractj.org/cdraw_343526_pixels_20140502_163918_20140502_163920.jpg)

### Remote storage

If the data must be stored in another infrastructure, the server should never have access to user's data, instead, the application must send the data encrypted as well the public keys for data sync. Once some data is added on the server side, it should be encrypted with the public key provided and sent back to the client.

**Note:** To not lose our focus here, *offline storage*, anything related with *data sync* will be proposed in a separated document

## API symmetry

### Android

The Android platform make use of [AeroGear Crypto](https://github.com/aerogear/aerogear-crypto-java) plus the [support added for the KeyStore management](https://github.com/aerogear/aerogear-android/blob/247009a1a729952bae964e34551c7cb92846a132/src/org/jboss/aerogear/android/impl/security/PasswordEncryptionServices.java#L74)  AeroGear Android providing an easy to use functionality to extract the private and public key.

    KeyManager keyManager = new KeyManager();
    PasswordProtectedKeystoreCryptoConfig keystoreCryptoConfig = new PasswordProtectedKeystoreCryptoConfig();
    keystoreCryptoConfig.setAlias("offline");

    //Derive the password with a KDF function
    keystoreCryptoConfig.setPassword(password.getText().toString());
    try {
          EncryptionService encryptionService = keyManager.encryptionService("key", keystoreCryptoConfig,
                LoginActivity.this);
            startActivity(new Intent(LoginActivity.this, DocumentsActivity.class));
    } catch (RuntimeException e) {
            Toast.makeText(LoginActivity.this, e.getMessage(), Toast.LENGTH_LONG).show();
    }

### JavaScript

- It must be discussed, about how the encrypted cache should work in scenarios where passwords are not provided.
TBD

### iOS

The iOS platform will make use of [AeroGear Crypto iOS](https://github.com/aerogear/aerogear-crypto-ios) library for the generation of public/private keys and encryption. Further, since the Keychain in iOS can be compromised, the key pairs generated would be further encrypted using the key generated by the KDF passphrase and stored using an appropriate protection class (_kSecAttrAccessibleWhenUnlockedThisDeviceOnly_).


	AGKeyManager *keyManager = [AGKeyManager manager];

	AGPasswordProtectedKeychainCryptoConfig *keychainCryptoConfig = [[AGPasswordProtectedKeychainCryptoConfig alloc] init];
    [keychainCryptoConfig setAlias:@"offline"];

    //Derive the password with a KDF function
    [keychainCryptoConfig setPassword:password.text];

     // initialize the encryption service passing the config
    id<AGEncryptionService> encryptionService = [keyManager encryptionService:keychainCryptoConfig];

For caching functionalities, research the feasibility of using [NSCache](https://github.com/gnustep/gnustep-base/blob/master/Source/NSCache.m#L195)


## Demo application

- https://github.com/danielpassos/aerogear-offline-android-demo/

## Planned Jiras

### Offline Storage
component: offline, crypto, storage

- AGSEC-XXX: Queries on encrypted database

*Description*: Currently for the local storage we encrypt and decrypt the whole database, which makes the solution impractical in scenarios where 1GB of data is provided

- AGSEC-XXX: Key management based on device unlock

*Description*: Investigate if is possible to derive the key based on device unlock or PIN

### Encrypted Cache
component: offline, crypto, cache

- AGSEC-XXX: R&D about LRU

*Description*: Currently is necessary to investigate better if LRU is the best politic for JS, iOS and Android for the sake of API symmetry

- AGSEC-XXX: Add data caching support for mobile devices

*Description*: Allow developers to choose when they want to cache the data

* AGSEC-XXX: Add cache encryption support for mobile devices

*Description*: Allow developers to choose when they want their cache encrypted

### Remote Storage
component: crypto, sync

- AGSEC-XXX: Device registration

*Description*: Device registration and management on the server side

- AGSEC-XXX: Revoke capability

*Description*: Adds the ability to revoke the key stored on device using another authorized device

- AGSEC-XXX: Remote wipe a mobile device

*Description*: Removal of the data when the user is online including offline storage and cache

- AGSEC-XXX: Add Public Key to Remote Server

*Description*: Send the public key to the server. The key provided will be used to encrypt data and verify digital signatures. Ex. Thinking about data sync when user include a record the server should be able to encrypt the data with the user's public key and sent it back to the device.

- AGSEC-XXX: Public key authentication

*Description*: As an additional level of security each user will have her own digital signature to provide authentication and data integrity, ensuring that the origin is legit. Pretty similar to the SSH scheme, but we want to keep the password into this situation.

# Next steps

- This document is something completely under development, but before we move forward would be nice some feedback to guarantee that everyone is on the same page.
- File Jiras
- Implement it :)
