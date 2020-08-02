#!/bin/bash

#################################################
#
# Lazy rclone sync
# Version 1.0
# Copyright 2020, Veit <git@brnk.de>
#
# Tested: 02.08.2020
#
#################################################

##
##  Usage: ./lazy_rclone.sh <server> <minimal/full>
##

###################  Config  ####################


  string="$@"

  mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  myname=$(basename $0)

  . $mydir/src/design.cfg
  . $mydir/cfg/rclone.cfg 


### ### ### ### ### ### ### ### ### ### ### ### ##


  # server name : my personal syntax for backups: 
  # <date>_<server>_<minimal/full>.tar.bz2
  backup_server="$1"


######### DO NOT EDIT BELOW THIS LINE  ##########


backup_options() {
  if [ "$2" = minimal ]; then
    backup_kind="minimal"
    clean_time="${delete_minimal}d"
  elif [ "$2" = full ]; then
    backup_kind="full"
    clean_time="${delete_full}d"
  else
    echo ""
    echo -e "[${red}Error${nc}] Usage: ${mydir}/${myname} <server> <minimal/full>"
    echo ""
    exit 1
  fi

  now=$(date +%Y-%m-%d)
  backup_file="${backup_server}_${backup_kind}"
  remote_dir="${rclone_cfg}:${remote_root}/${backup_server}/${backup_kind}"

}


backup_start() {
  $mydir/lazy_backup.sh -e ${backup_server}_${backup_kind}.cfg
}

backup_upload() {
  rclone copy ${backup_dir}/${now}_${backup_file}.tar.bz2  $remote_dir
}

clean_local() {
  rm ${backup_dir}/${now}_${backup_file}.tar.bz2
}

clean_rclone() {
  rclone delete --min-age $clean_time $remote_dir
}


#################### RUN   ######################

do_sync() {
  backup_options $string
  backup_start
  backup_upload
  clean_local
  clean_rclone
}

do_sync

