#!/bin/bash

latestReleaseInRepository() {
    result=$(gh release list --repo $1 --limit 1 | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [ -z "${result}" ]; then echo "0.0.0"; else echo $result; fi
}

withTemporaryDirectory() {
    # create temporary folder to clone the project
    tempFolder=$(mktemp -d -t TemporaryDirectory)
    if [[ $debug ]]; then open $tempFolder; fi

    # At the end of the operation cleanup the temporary folder
    trap "if [[ \$debug ]]; then read -p \"\"; fi; rm -rf \"$scratch\"" EXIT
}

# Configuration params
debug=$(echo $@ || "" | grep debug) # open the directory on finder

# Git repositories to use
sentry_repository="git@github.com:getsentry/sentry-cocoa.git"
xcframeworks_repo="git@github.com:malcommac/sentry-cocoa-sdk-xcframeworks.git"

workingPath="$PWD"

# Name of the framework and destination path
frameworkName="Sentry.xcframework"
frameworkPath="$workingPath/$frameworkName"

# START

# Get the latest release on Sentry official repository
remoteVersion=$(latestReleaseInRepository $sentry_repository)
echo "Latest sentry-cocoa version available is ${remoteVersion}"
# Get our latest mirrored release
localVersion=$(latestReleaseInRepository $xcframeworks_repo)
echo "Latest built xcframework version is ${localVersion}"

# the name of the branch created to host the new release
# it will be removed automatically at the end of the release process
branch="release/$remoteVersion"

if [[ $remoteVersion != $localVersion || debug ]]; then
    echo "$localVersion is out of date. Updating for Sentry SDK v$remoteVersion..."

    withTemporaryDirectory
    (
        # move to our temporary directory and get the latest release from the site
        cd $tempFolder
        echo "  Downloading latest release of SentrySDK..."
        gh release download --pattern $frameworkName.zip --repo $sentry_repository
        
        # Unzip the sentry framework package created for Chartage distribution
        echo "  Unzipping package..."
        unzip -q Sentry.xcframework.zip

        # Deploy to repository
        cd $workingPath 
        git push -u origin main # ensure the clean state of main (this is not necessary in fact)

        echo "  Creating branch $branch..."
        git checkout -b $branch main

        echo "  Moving Sentry.xcframework in place...";
        rm -fR $frameworkPath
        mv "$tempFolder/Carthage/Build/$frameworkName" "$frameworkPath"
        
        echo "  Committing changes to remote..."
        git add .
        git commit -m"Updated Package.swift and sources for Sentry v.$version"
        git push -u origin $branch # push branch on remote
    
        echo "  Creating new tag for $remoteVersion..."
        git checkout $branch
        git tag $remoteVersion
        git push origin --tags

         # Deploy
        echo "  Creating a new release..."
        gh release create $remoteVersion --target $branch --notes "Updated SPM pre-built xcframework package for Sentry SDK v$remoteVersion"

        echo "  Final clean-up..."
        git checkout main
        git branch -d $branch
        git push origin --delete $branch
        
        echo "Published release $remoteVersion on this mirror"
    )
else
    echo "Package is up-to-date."
fi

echo "Done."
