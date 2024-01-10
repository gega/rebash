# rebash
Save and restore interactive bash environment

# setup

1. add the provided bashrc extract to the local bashrc and make sure that the bashrc is restricted for interactive shells

2. copy the save-envs.sh script to some place and make it executable

3. add the crontab extract to the user (or optionally global) crontab (tested with fcron but should work with any standard cron)

# restore

- open an empty terminal window or tab
- source the proper shell save file:

  ```$ . ~/.SHELL_ab1b11056174abdf62dea5e7cfed4631a59067bf.sh```


# how it works

The cron will signal all interactive shells in regular intervals with
SIGURG which is ignored by default. The shells with the environment
management capability has a trap for that signal and they will execute the
env_save() function when receiving the signal. The env_save() can be
executed by hand too if needed. (for instance before planned reboot)
On restore, open up the same number of shells and source the proper saved
environment on each of them.

# what is preserved

- history
- environment variables
- directory stack
- window title
