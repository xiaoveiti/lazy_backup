#!/bin/bash

#################################################
#
# Lazy Backup
# Version 1.2
# Copyright 2020, Veit <git@brnk.de>
#
# Tested: xx.xx.xx
#
#################################################

##
##  Usage: ./lazy_backup.sh <option> <config>
##

###################  Config  ####################


  mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  myname=$(basename $0)

  . $mydir/src/design.cfg

  string="$@"


###############  Import Config  #################


   own_cfg=$mydir/cfg/$2


######### DO NOT EDIT BELOW THIS LINE  ##########


cmdline() {
    local arg=
    for arg
    do
        local delim=""
        case "$arg" in
            --export)         args="${args}-e ";;
            --import)         args="${args}-i ";;
            --help)           args="${args}-h ";;
            *) [[ "${arg:0:1}" == "-" ]] || delim="\""
                args="${args}${delim}${arg}${delim} ";;
        esac
    done
    eval set -- $args

    while getopts ":hei" option
    do
         case $option in
         h)
             usage
             exit 0
             ;;
         e)
             if [ -n "$2" ] && [ -e $own_cfg ]; then
               export_files $own_cfg
             else
               config_error
             fi
             exit 0
             ;;
         i)
             if [ -n "$2" ] && [ -e $own_cfg ]; then
               echo "import_files $own_cfg"
             else
               config_error
             fi
             exit 0
             ;;
        esac
    done
    return 0

}


usage() {
    cat <<- EOF

    ----------------------------------------------------

    Usage: $myname options

    Simple Script to backup and restore your server.
    For more information check https://github.com/gxf0/lazy_backup

    Please make sure to adjust the config file 

    Options:
       -e  --export <config>		export files
       -i  --import <config>		import files
       -h  --help       		show this help


    Examples:
       $myname -e <export.cfg>
       $myname --export <export.cfg>

EOF
}

script_start() {
   starttime=$(date +%s)
   echo ""
   echo -e "${blue}==============================================="
   echo -e "Begin to $1 your files (may take a while)"
   echo -e "===============================================${nc}"
}

script_stop() {
   endtime=$[$(date +%s)-$starttime]
   echo -e "${blue}==============================================="
   echo -e "Done (duration: $endtime seconds)"
   echo -e "===============================================${nc}"
   echo ""
}

config_error() {
   echo ""
   echo -e "[${red}Error${nc}] $own_cfg doesn't exist"
   echo ""
}

config_read_var() { #syntax <config.cfg> <section>
cfg_content=$(sed -n "/\[$2\]/,/\[end]/p" $1 | sed -r '/[^=]+=[^=]+/!d' | sed -r 's/\s+=\s/=/g')
for var in $cfg_content
  do
    export ${var//\"}
  done
}

config_read_dir() { #syntax <config.cfg> <section>
   cfg_content=$(sed -n "/\[$2\]/,/\[end]/p" $1)
   cfg_content=${cfg_content//\[$2\]/}
   cfg_content=${cfg_content//\[end\]/}
}


 # Export

export_prepare() {
  config_read_var $own_cfg basic
  now=$(date +%Y-%m-%d)
  backup_now="$backup_dir/$now"
  mkdir $backup_dir > /dev/null 2>&1
  mkdir $backup_now > /dev/null 2>&1
  echo -e "[${green}Ok${nc}] Prepare Backup"
}

export_dir() {
    config_read_dir $own_cfg dir
    mkdir $backup_now/dir > /dev/null 2>&1
    for dir in $cfg_content
    do
       base="${dir##*/}"
       tar cfvj $backup_now/dir/"${base}.tar.bz2" "$dir" > /dev/null 2>&1
    done
  echo -e "[${green}Ok${nc}] Export: Dir"
}

export_mysql() {
  config_read_var $own_cfg sql
  mkdir $backup_now/sql > /dev/null 2>&1
  mysql --skip-column-names -u $sql_user -p$sql_pw -e 'show databases' | while read dbname; do mysqldump --lock-all-tables -u $sql_user -p$sql_pw "$dbname" | gzip> $backup_now/sql/"$dbname".sql.gz; done > /dev/null 2>&1
  rm -f $backup_now/sql/information_schema.sql.gz $backup_now/sql/performance_schema.sql.gz > /dev/null 2>&1
  echo -e "[${green}Ok${nc}] Export: SQL"
}

export_compress() {
   cd $backup_dir/$now
   tar cfvj $backup_dir/"${now}_${backup_file}.tar.bz2" * > /dev/null 2>&1
   rm -rf $backup_dir/$now
  echo -e "[${green}Ok${nc}] Compress Backup"
 }

export_files() {
  script_start backup
  export_prepare
  export_dir
  export_mysql
  export_compress
  script_stop
 }


 # Import

import_prepare() {
  config_read_var $own_cfg basic
  mkdir $mydir/tmp > /dev/null 2>&1
  tar xfj ${backup_file}.tar.bz2 -C $mydir/tmp
  echo -e "[${green}Ok${nc}] Prepare Import"
}

import_dir() {
  cd $mydir/tmp/dir
  for file in `ls *.tar.bz2`; do
    tar -xf $file -C /
  done
  echo -e "[${green}Ok${nc}] Import: Dir"
}

import_mysql() {
  config_read_var $own_cfg sql
  cd $mydir/tmp/sql
  for filename in `ls *.sql.gz`; do
    gunzip $filename
  done
  for i in $(seq 1 $db_count)
  do
    vname="dbname_$i"; vname="${!vname}"
    vuser="dbuser_$i"; vuser="${!vuser}"
    vpass="userpass_$i"; vpass="${!vpass}"
    echo "CREATE DATABASE $vname;" | mysql -u $sql_user -p$sql_pw
    echo "CREATE USER '$vuser'@'localhost' IDENTIFIED BY '$vpass';" | mysql -u $sql_user -p$sql_pw
    echo "GRANT ALL PRIVILEGES ON $vname.* TO '$vuser'@'localhost';" | mysql -u $sql_user -p$sql_pw
    echo "FLUSH PRIVILEGES;" | mysql -u $sql_user -p$sql_pw
    mysql -u $vuser -p$vpass $vname < $mydir/tmp/sql/"$vname".sql
  done
  echo -e "[${green}Ok${nc}] Import: SQL"
}

import_files() {
  script_start import
  import_prepare
  import_dir
  import_mysql
  script_stop
}




#################### RUN   ######################


do_backup() {
   cmdline $string
   echo ""
   echo -e "${blue}Notice:${nc} please use $myname -e to export or -i to import your files"
   echo -e "        for help, please use $myname -h (--help)"
   echo ""
}

do_backup

