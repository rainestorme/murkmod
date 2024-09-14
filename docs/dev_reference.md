# murkmod Developer Reference

murkmod is a complex piece of software and as such, it has a lot of things to be documented. This reference manual aims to document the more obscure functionality of murkmod, and utilities that are not entirely surface-level for users.

## Hidden and Developer Menu Options

> Note that these only apply when using unlocked mush, if a password was set.

At the main menu, you have the option to enter a number corresponding to a menu option. The following is a list of all functionality that is not in the list of options:

- `26`: Developer update - Updates murkmod from an alternate branch instead of `main`
- `101` and `111`: Hard-enable and hard-disable extensions (respectively) without killing extension processes. This was done because it also kills the murkmod helper extension, which prevents the whole process from finishing.
- `112`: Purge extension processes - Kills all extension processes.
- `113`: Prints a list of installed plugins and their individual metadata.
- `114` and `115`: Legacy install/uninstall plugin - Readline-based plugin management for easier interface from the helper extension.
- `2**`: Interface for the JS plugin filesystem access API (see `class MurkmodFsAccess`)

The murkmod installation script (murkmod.sh, **not** the VT2 installer!) reads an environment variable called `MURKMOD_BRANCH` - it is normally set by option `26`, but it can be set by hand by using the following command:

```bash
MURKMOD_BRANCH="YOUR_BRANCH_HERE" bash <(curl -SLk https://raw.githubusercontent.com/rainestorme/murkmod/main/murkmod.sh)
```

## File Flags

Flags can either be files or directories. Directories are primarily used so that a user can creat a folder in their downloads to trigger certain behavior if other parts of murkmod fail.

The following flags can be used on a murkmodded system:

- `/sshd_staged` (file) - Marks that sshd has been configured at setup. Upon deletion and a reboot, it will regenerate the sshd config.
- `/population_required` (file) - Deleted upon checking at boot (one-time). Marks that crossystem.sh population should be performed. Upon creation and a reboot, it will update crossystem.sh to reflect the latest values of crossystem.old.
- `/stateful_unfucked` (file) - Marks that stateful has been unfucked (formatted at setup). Upon deletion and a reboot, stateful will be wiped.
- `/logkeys/active` (file) - Marks that logkeys is active and should be started during boot. Requires logkeys to be installed in `/logkeys/`.
- `/home/chronos/user/Downloads/disable-extensions` (dir) - Marks that extensions should be soft-disabled in a loop to allow temporary access to mush.
- `/home/chronos/user/Downloads/fix-mush` (dir) - Replaces a bricked mush with an emergency shell, which can allow bricked murkmod development installs to be saved.
- `/mnt/stateful_partition/restore-emergency-backup` (file) - Restores opposite kernel and rootfs to a backup stored on stateful. Upon creation, flashing will begin, but if flashing is interrupted, the flag will remain until it succeeds.
