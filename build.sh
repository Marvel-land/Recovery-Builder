#!/bin/bash

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

# export sync start time
SYNC_START=$(date +"%s")

echo "::group::Sync Recovery Source"
repo init -u $MANIFEST -b $MANIFEST_BRANCH --depth=1 --groups=all,-notdefault,-device,-darwin,-x86,-mips
repo sync -c --no-clone-bundle --no-tags --optimized-fetch --force-sync -j$(nproc --all)
git clone $DT_LINK --depth=1 --single-branch $DT_PATH
echo "::endgroup::"

# export sync end time and diff with sync start
SYNC_END=$(date +"%s")
SDIFF=$((SYNC_END - SYNC_START))

# setup TG message and build posts
telegram_message() {
	curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" -d chat_id="${TG_CHAT_ID}" \
	-d "parse_mode=Markdown" \
	-d text="$1"
}

# Send 'Build Triggered' message in TG along with sync time
telegram_message "
	*🌟 Build Triggered 🌟*
	*Date:* \`$(date +"%d-%m-%Y %T")\`
	*✅ Sync finished after $((SDIFF / 60)) minute(s) and $((SDIFF % 60)) seconds*"  &> /dev/null

# export build start time
BUILD_START=$(date +"%s")

echo "::group::Compile"
. build/envsetup.sh &&lunch omni_$DEVICE-$BUILD_TYPE && make $TARGET -j2 2>&1 | tee build.log
echo "::endgroup::"

# export sync end time and diff with build start
BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))

ls -a $(pwd)/out/target/product/$DEVICE/ # show /out contents
ZIP=$(find $(pwd)/out/target/product/$DEVICE/ -maxdepth 1 -name "*$DEVICE*.zip" | perl -e 'print sort { length($b) <=> length($a) } <>' | head -n 1)
ZIPNAME=$(basename $ZIP)
ZIPSIZE=$(du -sh $ZIP |  awk '{print $1}')
echo "$ZIP"

telegram_build() {
	curl --progress-bar -F document=@"$1" "https://api.telegram.org/bot$BOTTOKEN/sendDocument" \
	-F chat_id="$CHATID" \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=Markdown" \
	-F caption="$2"
}

telegram_post(){
 if [ -f $(pwd)/out/target/product/$DEVICE/$ZIPNAME ]; then
	rclone copy $ZIP MarvelMathesh:recovery -P
	MD5CHECK=$(md5sum $ZIP | cut -d' ' -f1)
	DWD=$DRIVE$ZIPNAME
	telegram_message "
	*✅ Build finished after $(($DIFF / 3600)) hour(s) and $(($DIFF % 3600 / 60)) minute(s) and $(($DIFF % 60)) seconds*
	*ROM:* \`$ZIPNAME\`
	*MD5 Checksum:* \`$MD5CHECK\`
	*Download Link:* [Tdrive]($DWD)
	*Size:* \`$ZIPSIZE\`
	*Date:*  \`$(date +"%d-%m-%Y %T")\`" &> /dev/null
 else
	BUILD_LOG=$(pwd)/build.log
	tail -n 10000 ${BUILD_LOG} >> $(pwd)/buildtrim.txt
	LOG1=$(pwd)/buildtrim.txt
	echo "CHECK BUILD LOG" >> $(pwd)/out/build_error
	LOG2=$(pwd)/out/build_error
	TRANSFER=$(curl --upload-file ${LOG1} https://transfer.sh/$(basename $LOG1))
	telegram_build $LOG2 "
	*❌ Build failed to compile after $(($DIFF / 3600)) hour(s) and $(($DIFF % 3600 / 60)) minute(s) and $(($DIFF % 60)) seconds*
	Build Log: $TRANSFER
	_Date:  $(date +"%d-%m-%Y %T")_" &> /dev/null
 fi
}

echo "::group::Disk Space After Build"
df -hlT /
echo "::endgroup::"

telegram_post
