#!/bin/sh

PWD="$( cd "$( dirname "$0" )" && pwd -P )"
PROJECT_PATH="${PWD}/.."

VERSION=${1}
regex="^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)(\\-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"


if [[ ! $VERSION =~ $regex ]]; then
    echo "Invalid version string."
    echo "usage: versionUpdate.sh X.X.X"
    return
fi

echo "update version to $VERSION";

############# podspec update 

POD_VERSION_NAME="s.version ="

find ${PROJECT_PATH} -name "*.podspec" -maxdepth 1 -exec sed -i '' "s/${POD_VERSION_NAME} '.*'/${POD_VERSION_NAME} '${VERSION}'/g" {} \;

# find ./ -name "*.podspec" -maxdepth 1 -exec sed -i '' "s/${POD_VERSION_NAME} '.*'/${POD_VERSION_NAME} '${VERSION}'/g" {} \;

############# pbxproj update

MARKETING_VERSION_NAME="MARKETING_VERSION \="
PROJECT_NAME="nugu-ios"
PBXPROJ_PATH="${PROJECT_PATH}/${PROJECT_NAME}.xcodeproj/project.pbxproj"

sed -i '' "s/${MARKETING_VERSION_NAME} [^\;]*\;/${MARKETING_VERSION_NAME} ${VERSION};/" $PBXPROJ_PATH

############# nuguCore version

NUGU_SDK_VERSION_NAME="public let nuguSDKVersion ="
NUGU_CORE_FILE_NAME="NuguCore.swift"
NUGU_CORE_PATH="${PROJECT_PATH}/NuguCore/Sources/${NUGU_CORE_FILE_NAME}"

sed -i '' "s/${NUGU_SDK_VERSION_NAME} \".*\"/${NUGU_SDK_VERSION_NAME} \"${VERSION}\"/" $NUGU_CORE_PATH


