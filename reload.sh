#!/bin/bash

pkill qs

# export QT_LOGGING_RULES="qt.qpa.services.warning=false"
qs -p ~/Projects/quickshell/ &
