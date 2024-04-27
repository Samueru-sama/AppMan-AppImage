#!/bin/sh

APP=AppMan
APPDIR=AppMan.AppDir

if [ -z "$APP" ]; then exit 1; fi
mkdir -p ./"$APP/$APPDIR" && cd ./"$APP/$APPDIR" || exit 1

# MAKE AND INSTALL WGET AND ZSYNC HERE
CURRENTDIR="$(readlink -f "$(dirname "$0")")" # DO NOT MOVE THIS
wget "http://ftp.gnu.org/gnu/wget/wget-latest.tar.gz"
tar fx ./*tar* && cd ./wget* && ./configure --prefix="$CURRENTDIR" LDFLAGS="-static" && make && make install && cd .. && rm -rf ./wget* ./*tar* || exit 1

"$CURRENTDIR/bin/wget" "http://zsync.moria.org.uk/download/zsync-0.6.2.tar.bz2" # This also tests that this wget works
tar fx ./*tar* && cd ./zsync* && ./configure --prefix="$CURRENTDIR"  && make && make install && cd .. && rm -rf ./zsync* ./*tar* || exit 1

find ./bin/* -type f -executable -exec sed -i -e "s|/usr|././|g" {} \; # Patch binaries

# GET APPMAN
wget -q "https://raw.githubusercontent.com/ivan-hc/AM/main/APP-MANAGER" -O ./appman && chmod a+x ./appman && mv ./appman ./bin/appman || exit 1

# GET THE GUN I MEAN GUM
mkdir ./tmp && cd ./tmp || exit 1
REPO="charmbracelet/gum"
version=$(wget -q https://api.github.com/repos/"$REPO"/releases -O - | grep browser_download_url | grep -i nux_x86_64.tar.gz | cut -d '"' -f 4 | head -1)
wget "$version" -O download.tar.gz && tar fx ./*tar* && cd .. && mv ./tmp/gum ./bin/gum && rm -rf ./tmp || exit 1

# GET TUI
wget -q "https://raw.githubusercontent.com/ivan-hc/AM/7d7f82fa49b4c021611ce052f13879dd74be8537/apptui" -O ./apptui && chmod a+x ./apptui && mv ./apptui ./bin/apptui || exit 1

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh

CURRENTDIR="$(readlink -f "$(dirname "$0")")"
export PATH="$CURRENTDIR/bin:$PATH"
export XDG_DATA_DIRS="$CURRENTDIR/share:$XDG_DATA_DIRS"

version0=$(wget -q https://api.github.com/repos/Samueru-sama/AppMan-AppImage/releases -O - | grep -i continuous | grep browser_download_url | awk -F - '{print $(NF-1)}')
version=$(cat $CURRENTDIR/version)
if [ "$version" != "$version0" ]; then
	ping -q -c1 github.com >/dev/null 2>&1 && echo '------WARNING APPMAN IS OUTDATED, RUN >>> appman -u <<< TO UPDATE/!------'
fi

if [ "$1" = "--TUI" ] || [ "$1" = "--tui" ]; then
	"$CURRENTDIR/bin/apptui"
else
	"$CURRENTDIR/bin/appman" "$@"
fi
EOF
chmod a+x ./AppRun
APPVERSION=$(./bin/appman -v)
if [ -z "$APPVERSION" ]; then echo "Failed to get version from appman"; exit 1; fi
echo "$APPVERSION" >> ./version

# DESKTOP & ICON
touch ./DirIcon ./AppMan.png # THIS IS A DUMMY BECAUSE APPMAN DOESN'T HAVE AN OFFICIAL ICON YET I THINK
cat >> ./"$APP".desktop << 'EOF'
[Desktop Entry]
Name=AppMan
Comment=The rootless side of "AM" to manage all your apps locally
Exec=AppMan
Icon=AppMan
Terminal=true
Type=Application
Categories=Utility;
EOF

# MAKE APPIMAGE
APPIMAGETOOL=$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | grep -v zsync | grep -i continuous | grep -i appimagetool | grep -i x86_64 | grep browser_download_url | cut -d '"' -f 4 | head -1)
cd .. && wget -q "$APPIMAGETOOL" -O ./appimagetool && chmod a+x ./appimagetool || exit 1

# Do the thing!
ARCH=x86_64 VERSION="$APPVERSION" ./appimagetool -s ./"$APPDIR"
ls ./*.AppImage || { echo "appimagetool failed to make the appimage"; exit 1; }
if [ -z "$APP" ]; then exit 1; fi # Being extra safe lol
mv ./*.AppImage .. && cd .. && rm -rf "./$APP"
echo "All Done!"
