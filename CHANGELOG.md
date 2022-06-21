# CHANGELOG

* `3.0.20` Release - [3.0.200](#30200)
* `3.0.10` Release - [3.0.100](#30100)
* `3.0.00` Release - [3.0.000](#30000)
* `2.2.50` Release - [2.2.500](#22500)
* `2.2.40` Release - [2.2.400](#22400)
* `2.2.30` Release - [2.2.300](#22100)
* `2.2.20` Release - [2.2.200](#22200)
* `2.2.10` Release - [2.2.100](#22100)
* `2.2.00` Release - [2.2.000](#22000)
* `0.93.x` Releases - [0.93.0](#09300)
* `0.80.x` Releases - [0.80.0](#08000)
* `0.72.x` Releases - [0.72.0](#07200)
* `0.1.x` Releases - [0.1.0](#010)

## 3.0.200
#### Bug Fixes
* `EMP-18319` Bug fix : Player freeze when seek on offline assets

## 3.0.000
#### Features
* `EMP-17893` Add support to SPM & Cocoapods

## 2.2.500
#### Bug Fixes
* `EMP-1580` Migrate the SDK download task from `AVAssetDownloadTask` to `AVAggregateAssetDownloadTask`
* `EMP-1580` Fix mutiple file downloads when specifying `audios & subtitles` by using `AVAggregateAssetDownloadTask`.


## 2.2.400
#### Bug Fixes
* `EMP-15755` Cancel all dowload tasks when `NSURLErrorCancelledReasonUserForceQuitApplication` error occured.

## 2.2.300
#### Changes
* `EMP-15078` Add `onLicenceRenewed` event listener 


## 2.2.200
#### Bug Fixes
* Add `-weak_framework AVfoundation` to fix Xcode compile errors


## 2.2.100
#### Features
* `EMP-14806` Update support for downloading additional media : audio & subtitles

#### Changes
* `EMP-14806`  Updated to Swift 5
* `EMP-14806`  Now the download module support iOS 11 & up versions 


## 2.2.000
#### Features
* `EMP-14376` Update support for downloads 

## 0.108.0

#### Changes
* `EMP-12783`  Updated to Swift 4.2

## 0.93.0

#### Changes
* submodules no longer added through ssh

## 0.80.0,

#### Changes
* `EMP-11156` Standardized error messages and introduced an `info` variable

## 0.72.0
* Build pipe improvements

## 0.1.0
Released 10 Nov 2017

#### Features

* `EMP-10327` Initial download functionality added.
* `EMP-10445` Download functionality with Session management.
* `EMP-10474` Persist and retrieve `FairPlay` content keys in download and offline scenarios.
* `EMP-10478` Preparation of `DownloadTask`s now occur once `resume()` is called.
* `SessionManager` manages generic `DownloadTaskType` allowing for easy extensibility.
*`EMP-10609` Analytics event dispatch.

#### Changes
* `EMP-10486` Removed `Downloader` in favour of using `SessionManager` directly.

#### Bug Fixes
* `DownloadTask`s restored from a completed state with error now forwards that error.
    

#### Known Limitations
* Apple confirmed `iOS` `10.3 beta 3` fixes a bug (possibly introduced in `iOS 10.2.1`) where *suspending/resuming* a download multiple times (*3*) causes the `AVAssetDownloadTask` to enter a freezed state. More importantly, once this occurs it is impossible to start new downloading tasks unless a the affected device is *restarted*.
    - [Developer forum thread](https://forums.developer.apple.com/message/188168#188168)
    - Referenced bug report: `31049921`
* `iOS` `9.0` provides limited support for download and offline playback using `unencrypted` assets only. Offline `FairPlay` with persistent content keys is available from `iOS` `10.0+`.
