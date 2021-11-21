#!/usr/bin/env bash

echo "::group::Setup Rclone"
curl https://rclone.org/install.sh | sudo bash
mkdir -p ~/.config/rclone
echo "$RCLONE" > ~/.config/rclone/rclone.conf
echo "::endgroup::"

echo "::group::Installation Of Latest make and ccache"
mkdir -p /home/runner/extra &>/dev/null
{
    cd /home/runner/extra || exit 1
    wget -q https://ftp.gnu.org/gnu/make/make-4.3.tar.gz
    tar xzf make-4.3.tar.gz && cd make-*/ || exit
    ./configure && bash ./build.sh && sudo install ./make /usr/local/bin/make
    cd /home/runner/extra || exit 1
    git clone -q https://github.com/ccache/ccache.git
    cd ccache && git checkout -q v4.2
    mkdir build && cd build || exit
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DZSTD_FROM_INTERNET=ON ..
    make -j$(nproc --all) && sudo make install
} &>/dev/null
cd /home/runner || exit 1
rm -rf /home/runner/extra
echo "::endgroup::"

echo "::group::Doing Some Random Stuff"
if [ -e /lib/x86_64-linux-gnu/libncurses.so.6 ] && [ ! -e /usr/lib/x86_64-linux-gnu/libncurses.so.5 ]; then
    ln -s /lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
fi
export \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    USE_CCACHE=1 CCACHE_COMPRESS=1 CCACHE_COMPRESSLEVEL=8 CCACHE_DIR=/opt/ccache \
    TERM=xterm-256color
. /home/runner/.bashrc 2>/dev/null
echo "::endgroup::"

echo "::group::Setting ccache"
mkdir -p /opt/ccache &>/dev/null
sudo chown runner:docker /opt/ccache
CCACHE_DIR=/opt/ccache ccache -M 10G &>/dev/null
printf "All Preparation Done.\nReady To Build Recoveries...\n"
echo "::endgroup::"

# cd To An Absolute Path
mkdir -p /home/runner/builder &>/dev/null
cd /home/runner/builder || exit 1

echo "::group::Sync Recovery Source"
repo init -u $MANIFEST -b $MANIFEST_BRANCH --depth=1 --groups=all,-notdefault,-device,-darwin,-x86,-mips
repo sync -c --no-clone-bundle --no-tags --optimized-fetch --force-sync -j$(nproc --all)
git clone $DT_LINK --depth=1 --single-branch $DT_PATH
echo "::endgroup::"

echo "::group::Compile"
. build/envsetup.sh &&lunch omni_$DEVICE-$BUILD_TYPE && make $TARGET -j2 2>&1 | tee build.log
echo "::endgroup::"
