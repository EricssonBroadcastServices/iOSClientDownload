[![Swift](https://img.shields.io/badge/Swift-5.x-orange?style=flat-square)](https://img.shields.io/badge/Swift-5.3_5.4_5.5-Orange?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-iOS_tvOS-yellowgreen?style=flat-square)](https://img.shields.io/badge/Platforms-macOS_iOS_tvOS_watchOS_Linux_Windows-Green?style=flat-square)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Alamofire.svg?style=flat-square)](https://img.shields.io/cocoapods/v/Alamofire.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat-square)](https://github.com/Carthage/Carthage)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)


# Download

* [Features](#features)
* [License](https://github.com/EricssonBroadcastServices/iOSClientDownload/blob/master/LICENSE)
* [Requirements](#requirements)
* [Installation](#installation)
* Usage
    - [Getting Started](#getting-started)
    - [Selecting Preferred Bitrate](#selecting-preferred-bitrate)
    - [FairPlay Protection](#fairplay-protection)
    - [Analytics Hook-in](#analytics-hook)
    - [Responding to Download Events](#responding-to-download-events)
    - [Task Preparation](#task-preparation)
    - [Asset Management](#asset-management)
    - [Background Downloads](#background-downloads)
    - [Error Handling](#error-handling)
* [Release Notes](#release-notes)
* [Upgrade Guides](#upgrade-guides)
* [Roadmap](#roadmap)
* [Contributing](#contributing)


## Features
- [x] Easy task management
- [x] `FairPlay` DRM protection (requires `iOS` 10.0+)
- [x] Background downloads
- [x] Event publishing and progress tracking
- [x] Task restoration and recovery
- [x] Download quality selection
- [x] Complementary subtitle and audio selections
- [x] Analytics Hook-in

## Requirements

* `iOS` 11.0+ (`FairPlay` requires `iOS` 10.0+)
* `Swift` 5.0+
* `Xcode` 10.2+

## Installation

### Swift Package Manager

The Swift Package Manager is a tool for automating the distribution of Swift code and is integrated into the swift compiler.
Once you have your Swift package set up, adding `iOSClientDownload` as a dependency is as easy as adding it to the dependencies value of your Package.swift.

```sh
dependencies: [
    .package(url: "https://github.com/EricssonBroadcastServices/iOSClientDownload", from: "3.0.0")
]
```

### CocoaPods
CocoaPods is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate `iOSClientDownload` into your Xcode project using CocoaPods, specify it in your Podfile:

```sh
pod 'iOSClientDownload', '~>  3.0.0'
```

### Carthage
[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependency graph without interfering with your `Xcode` project setup. `CI` integration through [fastlane](https://github.com/fastlane/fastlane) is also available.

Install *Carthage* through [Homebrew](https://brew.sh) by performing the following commands:

```sh
$ brew update
$ brew install carthage
```

Once *Carthage* has been installed, you need to create a `Cartfile` which specifies your dependencies. Please consult the [artifacts](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md) documentation for in-depth information about `Cartfile`s and the other artifacts created by *Carthage*.

```sh
github "EricssonBroadcastServices/iOSClientDownload"
```

Running `carthage update --use-xcframeworks` will fetch your dependencies and place them in `/Carthage/Checkouts`. You either build the `.framework`s and drag them in your `Xcode` or attach the fetched projects to your `Xcode workspace`.

Finaly, make sure you add the `.framework`s to your targets *General -> Embedded Binaries* section.

## Usage

### Getting Started
With `iOS` 9.0, *Apple* introduced new functionality to support downloading of  `HLS` assets. Starting with `iOS` 10.0, offline support for `FairPlay` was added.
`Download` module provides an enhanced API simplifying the most common tasks and encapsulating the functionality into a set of core classes. In addition to this, the module adds event publishing and analytics hook-ins as well as `FairPlay` request management. These API's are developed to be backend agnostic and should be fairly easy to adopt and extend.
For a complete integration with the *EMP* backend, please see [`Exposure`](https://github.com/EricssonBroadcastServices/iOSClientExposure) and [`Analytics`](https://github.com/EricssonBroadcastServices/iOSClientAnalytics).
`Download` builds upon modern *Apple* APIs and allow tight integration with system-wide functionality such as network usage and battery life policies.

`Task` and `SessionManager` provide an entrypoint though which *client applications* perform downloads. `SessionManager<Task>` encapsulates a download session, its associated tasks, the session configuration and relevant delegate callbacks. The later are central in a *background download* scenario. Behind the scenes, `iOS` keeps background tasks alive through a strong reference, continuously updating its status.

```swift
let manager = SessionManager<Task>()

let task = manager.download(mediaLocator: someUrl,
                            assetId: "amazingAssetToDownload")
```

The  `assetId` supplied above is of special importance and must be a **unique identifier** for the particular media. This *id* is how `Download` tracks assets throughout delegates and event publising. Further more, background and state restoration requires this id to be unique.

### Selecting Preferred Bitrate
Bitrate selection allows the lowest media bitrate greater than or equal to a specified value to be configured. If no suitable media bitrate is found for the requested bitrate, the highest media bitrate will be selected. Making no selection will default the download to use the highest bitrate required.

```swift
task.use(bitrate: 16000)
```

### FairPlay protection
In order to use `DRM` protected offline assets through `FairPlay`, *client applications* need to implement a `FairplayRequester` to handle the *certificate* and *license* proceedure.  This functionality will be solution specific.  This protocol extends the *Apple* supplied `AVAssetResourceLoaderDelegate` protocol. **EMP** provides an out of the box implementation for *offline* `FairPlay` protection through the [Exposure module](https://github.com/EricssonBroadcastServices/iOSClientExposure) which integrates seamlessly with the rest of the platform.

```swift
let fairplayRequester = SolutionSpecifiFairplayRequester()
let fairplayTask = manager.download(mediaLocator: someFairplayUrl,
assetId: "fairPlayAsset",
using: fairplayRequester)
```

Securing offline `HLS` assets with `FairPlay` protection is a multi-step process not described in details here. Key aspects include vending a persistable `CKC` (Content Key Context) which contains the correct `TLLV` tags together with a master playlist which exposes the `EXT-X-SESSION-KEY` tag detailing relevant content keys. For an in depth guide, please see *Apple's* *Offline HLS guide with FPS* documentation.

### Analytics Hook

### Responding to Download Events
`EventPublisher` protocol defines an interface describing download related events such as *task preparation*, *completion* or *cancellation*.  `Task` adopts this protocol  allowing *client applications* a way to register triggered callbacks.


```swift
task.onResumed{ task in
        // Toggle pause/resume button
    }
    .onProgress{ task, progress in
        // Update progress bar
    }
```


```swift
task.onCanceled{ task, destinationUrl in
        // Delete the media located at the returned destinationUrl
    }
    .onCompleted{ task, destinationUrl
        // Store a reference to the returned destinationUrl.
    }
    .onError{ task, destinationUrl, error
        // Handle error and clean up media at destinationUrl.
    }
```

### Task Preparation
A `Task` created by supplying a `mediaLocator` and a unique `assetId` is not yet fully realized. This only happens once the task in question is prepared and started. This is to ensure consistency with background downloads.

```swift
task.onPrepared{ task in
        // The task has now been prepared, either through restoring a previous task with the specified assetId or creating a new task.
    }
    .prepate(lazily: true)
```

Preparation of a `Task` through `SessionManager` is an *asynchronous* operation. This is caused by the fact that a task with a specific

### Asset Management
The `Download` module provides an interface for configuring and tracking a download `Task`, it does not manage offline media. *Client applications* are responsible for managing *persisted keys*, *offline media assets* and associated metadata. This includes presenting the *user* with appropriate UI for listing offline content as well as removing it.

### Background Downloads
Register the completion handler received from the `UIApplicationDelegate` callback
```swift
func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
    if identifier == SessionConfigurationIdentifier.default.rawValue {
        let sessionManager = SessionManager<Task>()
        sessionManager.backgroundCompletionHandler = completionHandler

        sessionManager.restoreTasks {
            $0.forEach {
                // Restore state
            }
        }
    }
}
```

Respond to `DownloadTask` events, storing `URL`s on success or deleting local media on failure etc.


### Error Handling

## Release Notes
Release specific changes can be found in the [CHANGELOG](https://github.com/EricssonBroadcastServices/iOSClientDownload/blob/master/CHANGELOG.md).

## Upgrade Guides
The procedure to apply when upgrading from one version to another depends on what solution your client application has chosen to integrate `Download`.

Major changes between releases will be documented with special [Upgrade Guides](https://github.com/EricssonBroadcastServices/iOSClientDownload/blob/master/UPGRADE_GUIDE.md).

### Carthage
Updating your dependencies is done by running  `carthage update` with the relevant *options*, such as `--use-submodules`, depending on your project setup. For more information regarding dependency management with `Carthage` please consult their [documentation](https://github.com/Carthage/Carthage/blob/master/README.md) or run `carthage help`.

## Roadmap
No formalised roadmap has yet been established but an extensive backlog of possible items exist. The following represent an unordered *wish list* and is subject to change.

- [ ] Expanded Event Publishing
- [x] Analytics Hook
- [x] Unit testing

## Contributing

