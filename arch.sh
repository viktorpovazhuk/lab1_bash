#!/bin/bash

# global variables
DIR=.
NUM_DAYS=1
IS_DELETE_FILES=0
ARCHIVER=tar
COMPRESSOR=gzip

# functions
usage() {
    cat << EOF
Usage: ${0##*/} [-h | -t TARGET_DIRECTORY -n MIN_NUM_DAYS -r]

-h                     Show usage of script
-t                     Directory where to search files for archive.
                       By default, it is current working directory.
-n                     Only files older than number of days set with
                       this parameter will be archived.
-r                     Remove archived files from target directory.
EOF
}

err_exit() {
    err_echo "Usage: ${0##*/} [-h | -t TARGET_DIRECTORY -n MIN_NUM_DAYS -r]"
    exit 1
}

err_echo() {
    >&2 echo ${@}
}

# parse parameters
while getopts ":t:n:rh" optname;
do
    case ${optname} in
        h)
            usage
            exit
            ;;
        t)
            if [ -d ${OPTARG} ];
            then
                DIR=${OPTARG};
            else
                err_echo "Error: ${OPTARG} is not a correct directory."
                err_exit
            fi
            ;;
        n)
            int_re='^[0-9]+$'
            if [[ ${OPTARG} =~ ${int_re} ]];
            then
                NUM_DAYS=${OPTARG};
            else
                err_echo "Error: number of days must be >= 0."
                err_exit
            fi
            ;;
        r)
            IS_DELETE_FILES=1
            ;;
        :)
            err_echo "Error: -${OPTARG} requires an argument."
            err_exit
            ;;
        ?)
            err_echo "Error: invalid option."
            err_exit
            ;;
    esac
done

# create archive name
archive_name=$(date "+%Y-%m-%d-%H-%M-%S").tar
if [ ${DIR} == "." ];
then
    archive_name="${PWD##*/}-${archive_name}";
else
    archive_name="${DIR}/${DIR##*/}-${archive_name}";
fi

# add to archive
now=$(date +%s)
min_diff=$((${NUM_DAYS}*(3600*24)))
for f_path in ${DIR}/*
do
    f_time=$(date -r ${f_path} +%s)
    diff=$((${now}-${f_time}))
    if [ -f ${f_path} -a ${diff} -gt ${min_diff} ]
    then
        ${ARCHIVER} -r -f ${archive_name} -C ${DIR} ${f_path##*/}
        
        if [ ${IS_DELETE_FILES} -eq 1 ];
        then
            rm ${f_path}
        fi
    fi
done

# zip
if [ -a ${archive_name} ];
then
    ${COMPRESSOR} ${archive_name}
    echo "Archive created."
else
    echo "No files suits criterias to archive."
fi