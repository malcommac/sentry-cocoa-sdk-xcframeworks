# Sentry-cocoa xcframework integration with SPM

This is a small mirror for the official [Sentry-cocoa](https://github.com/getsentry/sentry-cocoa) SDK for Apple platforms, to add support for using their binary dependencies (`.xcframework`) with SPM, aka Swift Package Manager.

This repo contains a [`Package.swift`](https://github.com/malcommac/sentry-cocoa-sdk-xcframeworks/blob/main/Package.swift) file, which uses a `binaryTarget` for `Sentry.xcframework` library (files are hosted in GitHub [Release](https://github.com/malcommac/sentry-cocoa-sdk-xcframeworks/releases) page).

## Official SPM Support

Sentry-cocoa currently supports SPM integration, see the official SDK integration instructions.  
**This repo is an alternative for integrating with their pre-built xcframeworks for faster build times.**

Pre-built framework is provided directly from Sentry-cocoa page (available for Chartage integration), so no re-build is made from this side.

## Automatic Update

This repository periodically check updates from the official Sentry-SDK (using GitHub Actions) in order to provide new releases of the framework as fast as possible ([script is here](https://github.com/malcommac/sentry-cocoa-sdk-xcframeworks/blob/main/.scripts/package.sh)).  

Each version is tagged automatically with the semver and a release is created automatically.  
You can use these versions in your import of the package.

## Installation

In order to install the pre-built xcframework from this repository in your target just add the dependency in your `Package.swift` file:

```swift
// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MyLibrary",
    platforms: [.iOS(.v11)],
    products: [
        .library(name: "MyLibrary", targets: ["MyLibraryTarget"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/malcommac/sentry-cocoa-sdk-xcframeworks",
            .exact("8.1.0")
        ),
    ],
    targets: [
        .target(
            name: "MyLibraryTarget",
            dependencies: [
                .product(name: "Sentry", package: "sentry-cocoa-sdk-xcframeworks")
            ]
        )
    ]
)
```

## How the package is generated

The `.script/package.sh` is used to update the repository with the latest version of Sentry SDK. The script perfors the following actions:

- Check the latest releases of the official SDK and our mirror by using the `gh` official tool
- When a new version is found it gets the `Sentry.xcframework.zip` package from the official release's sections'
- Create a new `release/<version>` branch and copy the framework into the root directory
- Commits changes on new branch
- Create a new tag with `<version>` you can use from SPM
- Create a new release in Releases section; the asset is the repository itself.

### Running the script locally

- Install github cli: `$ brew install gh`
- Generate the swift package: `$ cd .scripts && sh package.sh debug skip-release`

## Author

This small automation script and the repository was created by [Daniele Margutti](https://github.com/malcommac).

Sentry SDK is property of the Sentry and licensed under [MIT License](https://github.com/getsentry/sentry-cocoa/blob/main/LICENSE.md).
