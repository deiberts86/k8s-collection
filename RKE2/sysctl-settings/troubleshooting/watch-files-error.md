# Error Failed to Watch File

[SUSE Link](https://www.suse.com/support/kb/doc/?id=000020048)

Check:
```bash
cat /proc/sys/fs/inotify/max_user_instances
cat /proc/sys/fs/inotify/max_user_watches
```

Implement:
```bash
sudo sysctl fs.inotify.max_user_instances=8192
sudo sysctl fs.inotify.max_user_watches=1048576
sudo sysctl -p
```