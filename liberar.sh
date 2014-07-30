#!/bin/sh
# Eliminacion de memoria swap utilizada
swapoff -a
# Eliminacion de cache en ram
sync
sysctl -w vm.drop_caches=3
sleep 3
sysctl -w vm.drop_caches=0
