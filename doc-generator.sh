#!/bin/sh

#sourcekitten doc -- -project nugu-ios.xcodeproj -scheme NuguCore > NuguCore.json
#sourcekitten doc -- -project nugu-ios.xcodeproj -scheme NuguAgents > NuguAgents.json
#sourcekitten doc -- -project nugu-ios.xcodeproj -scheme NuguClientKit > NuguClientKit.json
#sourcekitten doc -- -project nugu-ios.xcodeproj -scheme NuguLoginKit > NuguLoginKit.json
#sourcekitten doc -- -project nugu-ios.xcodeproj -scheme NuguServiceKit > NuguServiceKit.json
#sourcekitten doc -- -project nugu-ios.xcodeproj -scheme NuguUIKit > NuguUIKit.json
#sourcekitten doc -- -project nugu-ios.xcodeproj -scheme KeenSense > KeenSense.json
#jazzy --sourcekitten-sourcefile NuguCore.json,NuguAgents.json,NuguClientKit.json,NuguLoginKit.json,NuguServiceKit.json,NuguUIKit.json,KeenSense.json
jazzy --podspec NuguCore.podspec -o docs/NuguCore
find ./docs/NuguCore -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"index.html\">NuguCore/<a href=\"..\/index.html\">NUGU SDK/'
find ./docs/NuguCore -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"..\/index.html\">NuguCore/<a href=\"..\/..\/index.html\">NUGU SDK/'
rm -rf ./docs/NuguCore/docsets

jazzy --podspec NuguAgents.podspec -o docs/NuguAgents
find ./docs/NuguAgents -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"index.html\">NuguAgents/<a href=\"..\/index.html\">NUGU SDK/'
find ./docs/NuguAgents -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"..\/index.html\">NuguAgents/<a href=\"..\/..\/index.html\">NUGU SDK/'
rm -rf ./docs/NuguAgents/docsets

jazzy --podspec NuguClientKit.podspec -o docs/NuguClientKit
find ./docs/NuguClientKit -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"index.html\">NuguClientKit/<a href=\"..\/index.html\">NUGU SDK/'
find ./docs/NuguClientKit -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"..\/index.html\">NuguClientKit/<a href=\"..\/..\/index.html\">NUGU SDK/'
rm -rf ./docs/NuguClientKit/docsets

jazzy --podspec NuguLoginKit.podspec -o docs/NuguLoginKit
find ./docs/NuguLoginKit -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"index.html\">NuguLoginKit/<a href=\"..\/index.html\">NUGU SDK/'
find ./docs/NuguLoginKit -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"..\/index.html\">NuguLoginKit/<a href=\"..\/..\/index.html\">NUGU SDK/'
rm -rf ./docs/NuguLoginKit/docsets

jazzy --podspec NuguServiceKit.podspec -o docs/NuguServiceKit
find ./docs/NuguServiceKit -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"index.html\">NuguServiceKit/<a href=\"..\/index.html\">NUGU SDK/'
find ./docs/NuguServiceKit -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"..\/index.html\">NuguServiceKit/<a href=\"..\/..\/index.html\">NUGU SDK/'
rm -rf ./docs/NuguServiceKit/docsets

jazzy --podspec NuguUIKit.podspec -o docs/NuguUIKit
find ./docs/NuguUIKit -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"index.html\">NuguUIKit/<a href=\"..\/index.html\">NUGU SDK/'
find ./docs/NuguUIKit -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"..\/index.html\">NuguUIKit/<a href=\"..\/..\/index.html\">NUGU SDK/'
rm -rf ./docs/NuguUIKit/docsets

jazzy --podspec KeenSense.podspec -o docs/KeenSense
find ./docs/KeenSense -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"index.html\">KeenSense/<a href=\"..\/index.html\">NUGU SDK/'
find ./docs/KeenSense -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"..\/index.html\">KeenSense/<a href=\"..\/..\/index.html\">NUGU SDK/'
rm -rf ./docs/KeenSense/docsets

jazzy --podspec JadeMarble.podspec -o docs/JadeMarble
find ./docs/JadeMarble -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"index.html\">JadeMarble/<a href=\"..\/index.html\">NUGU SDK/'
find ./docs/JadeMarble -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"..\/index.html\">JadeMarble/<a href=\"..\/..\/index.html\">NUGU SDK/'
rm -rf ./docs/JadeMarble/docsets

