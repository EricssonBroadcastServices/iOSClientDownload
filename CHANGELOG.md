# CHANGELOG

* `0.1.x` Releases - [0.1.0](#010)

## 0.1.0
NO RELEASE YET

#### Features

* `EMP-10327` Initial download functionality added.
* `EMP-10445` Download functionality with SessionManagement.

#### Known Limitations
* Apple confirmed `iOS` `10.3 beta 3` fixes a bug (possibly introduced in `iOS 10.2.1`) where *suspending/resuming* a download multiple times (*3*) causes the `AVAssetDownloadTask` to enter a freezed state. More importantly, once this occurs it is impossible to start new downloading tasks unless a the affected device is *restarted*.
    - [Developer forum thread](https://forums.developer.apple.com/message/188168#188168)
    - Referenced bug report: `31049921`
* `iOS` `9.0` provides limited support for download and offline playback using `unencrypted` assets only. Offline `FairPlay` with persistent content keys is available from `iOS` `10.0+`.
