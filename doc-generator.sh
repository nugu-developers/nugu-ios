#!/bin/sh

#sourcekitten doc -- -project nugu-ios.xcodeproj -scheme NuguCore > NuguCore.json
#sourcekitten doc -- -project nugu-ios.xcodeproj -scheme NuguAgents > NuguAgents.json
#sourcekitten doc -- -project nugu-ios.xcodeproj -scheme NuguClientKit > NuguClientKit.json
#sourcekitten doc -- -project nugu-ios.xcodeproj -scheme NuguLoginKit > NuguLoginKit.json
#sourcekitten doc -- -project nugu-ios.xcodeproj -scheme NuguServiceKit > NuguServiceKit.json
#sourcekitten doc -- -project nugu-ios.xcodeproj -scheme NuguUIKit > NuguUIKit.json
#sourcekitten doc -- -project nugu-ios.xcodeproj -scheme KeenSense > KeenSense.json
#jazzy --sourcekitten-sourcefile NuguCore.json,NuguAgents.json,NuguClientKit.json,NuguLoginKit.json,NuguServiceKit.json,NuguUIKit.json,KeenSense.json
jazzy --config NuguCore/.jazzy.yaml
find ./docs/NuguCore -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"index.html\">NuguCore/<a href=\"..\/index.html\">NUGU SDK/'
find ./docs/NuguCore -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"..\/index.html\">NuguCore/<a href=\"..\/..\/index.html\">NUGU SDK/'
rm -rf ./docs/NuguCore/docsets

jazzy --config NuguAgents/.jazzy.yaml
find ./docs/NuguAgents -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"index.html\">NuguAgents/<a href=\"..\/index.html\">NUGU SDK/'
find ./docs/NuguAgents -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"..\/index.html\">NuguAgents/<a href=\"..\/..\/index.html\">NUGU SDK/'
rm -rf ./docs/NuguAgents/docsets

jazzy --config NuguClientKit/.jazzy.yaml
find ./docs/NuguClientKit -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"index.html\">NuguClientKit/<a href=\"..\/index.html\">NUGU SDK/'
find ./docs/NuguClientKit -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"..\/index.html\">NuguClientKit/<a href=\"..\/..\/index.html\">NUGU SDK/'
rm -rf ./docs/NuguClientKit/docsets

jazzy --config NuguLoginKit/.jazzy.yaml
find ./docs/NuguLoginKit -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"index.html\">NuguLoginKit/<a href=\"..\/index.html\">NUGU SDK/'
find ./docs/NuguLoginKit -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"..\/index.html\">NuguLoginKit/<a href=\"..\/..\/index.html\">NUGU SDK/'
rm -rf ./docs/NuguLoginKit/docsets

jazzy --config NuguServiceKit/.jazzy.yaml
find ./docs/NuguServiceKit -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"index.html\">NuguServiceKit/<a href=\"..\/index.html\">NUGU SDK/'
find ./docs/NuguServiceKit -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"..\/index.html\">NuguServiceKit/<a href=\"..\/..\/index.html\">NUGU SDK/'
rm -rf ./docs/NuguServiceKit/docsets

jazzy --config NuguUIKit/.jazzy.yaml
find ./docs/NuguUIKit -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"index.html\">NuguUIKit/<a href=\"..\/index.html\">NUGU SDK/'
find ./docs/NuguUIKit -name '*.html' -type f -print0 | xargs -0 \
sed -i '' 's/<a href=\"..\/index.html\">NuguUIKit/<a href=\"..\/..\/index.html\">NUGU SDK/'
rm -rf ./docs/NuguUIKit/docsets
