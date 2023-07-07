#!/bin/bash
ps a|grep [/]bin/bash|grep pts|awk '{print $1}'|tr '\n' ' '|awk '{print "kill -SIGURG " $0 " &>/dev/null"}'|/bin/bash
