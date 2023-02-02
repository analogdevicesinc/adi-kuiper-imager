#!/bin/bash
set -e
cd build
# mkdir -p ./kuiper-imager.app/Contents/Frameworks

# ## Bundle some known dependencies
# # -ns == no signing
# sudo echo "/usr/local/lib" | dylibbundler -ns -od -b -x ./kuiper-imager.app/Contents/MacOS/kuiper-imager -d ./kuiper-imager.app/Contents/Frameworks/ -p @executable_path/../Frameworks/ >/dev/null

if command -v brew ; then
	QT_PATH="$(brew --prefix ${QT_FORMULAE})/bin"
	export PATH="${QT_PATH}:$PATH"
fi

# ## Bundle the Qt libraries
# sudo macdeployqt kuiper-imager.app

# curl -o /tmp/macdeployqtfix.py https://raw.githubusercontent.com/aurelien-rainone/macdeployqtfix/master/macdeployqtfix.py
# sudo python /tmp/macdeployqtfix.py ./kuiper-imager.app/Contents/MacOS/kuiper-imager ${QT_PATH}
# sudo python /tmp/macdeployqtfix.py ./kuiper-imager.app/Contents/MacOS/kuiper-imager ./kuiper-imager.app/Contents/Frameworks/

sudo macdeployqt kuiper-imager.app -dmg

