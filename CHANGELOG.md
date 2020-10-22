# CHANGELOG

* `2.2.20` Release - [2.2.20](#2210)
* `2.2.10` Release - [2.2.10](#2210)
* `2.2.00` Release - [2.2.00](#2200)
* `0.93.x` Releases - [0.93.0](#0930)
* `0.80.x` Releases - [0.80.0](#0800)
* `0.72.x` Releases - [0.72.0](#0720)
* `0.1.x` Releases - [0.1.0](#010)

## 2.2.200
#### Changes
* `EMP-15078` Add `onLicenceRenewed` event listener 

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
