# Recovery Builder #

#### What this is ? ####

This is an easy way for recovery maintainers or anyone who's interested in building recoveries to finish their dream without a server.

This works with GitHub actions, thank GitHub not me.

#### How to use ####

Here are some useful notes to using this tool brewed with black magic.

1. Fork the repo anywhere.

2. Set the secrets, as listed below.

```MANIFEST : Link to your recovery manifest, Google it if you don't know what this is.```

```MANIFEST_BRANCH : Branch of recovery manifest```

```DEVICE : Most likely your device codename, e.g. land, rosy, sakura, curtana, etc.```

```DT_LINK : Link to your recovery device tree.```

```DT_PATH : Path to clone your device tree, e.g. device/xiaomi/land ```

```TARGET : recoveryimage or bootimage, depending on if your phone has a recovery partition or not ```

```TG_TOKEN : your telegram Bot Token ```

```TG_CHAT_ID : your telegram Chat ID ```

```BUILD_TYPE : eng, user or userdebug ```

```TZ : your timezone, e.g. Asia/Kolkata ```

```COMMAND : use it to clone if anything else needed, e.g. Theme, kernel, etc ```

```RCLONE : your rclone config ```

```DRIVE : Link to your Index or Drive ```

3. Go to actions tab, enable workflows.

4. Select Recovery-builder workflow.

5. Run workflow.

If you don't know any of these, **Ask [Google](https://www.google.com) or someone who builds recoveries**, I don't provide TWRP building support.

You'd also like to do edits on your recovery device tree first if your recovery needs that (e.g. SHRP, PBRP, etc.)

Enjoy buildbotting.
