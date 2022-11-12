#!/usr/bin/bash

# Этот скрипт может выглядеть странно,
# но причина в том, что скрпиты сложнее
# "скопируй файлы и выполни команду"
# я предпочитаю писать на python
# а тут и спарсить файл, и выполнить
# проверку целостности, так что получилось
# как получилось

# setup variables

os_type=`uname`

archive_dir="./archive"

if [ -e $archive_dir ]; then
    :
else
    echo "Directory for archive not exists..."
    exit 1
fi

current_date=`date +%d_%m_%Y`

server_name="DEFAULTSERVERNAME"

if [ "$1" != "" ]; then
    server_name="$1"
fi

result_file_name=$server_name"_"$current_date'_running.out'

archive_file_name=$server_name"_"$current_date".zip"
archive_file_md5_name=$archive_file_name".md5"

if [ -e ./$result_file_name ]; then
    rm $result_file_name
fi

# create .out file

curl https://raw.githubusercontent.com/GreatMedivack/files/master/list.out --silent | while read string 
do
    if [[ "$string" == *" Running"* ]]; then
        service_name=($string)
        echo "$service_name" >> $result_file_name
    fi
done

# create archive and hash

zip $archive_file_name $result_file_name -qq

if [ $os_type == "Darwin" ]; then
    md5 -q $archive_file_name > $archive_file_md5_name
fi
if [ $os_type == "Linux" ]; then
    md5sum $archive_file_name > $archive_file_md5_name
fi

# archive integrity check

if [ -e $archive_dir/$archive_file_name ]; then
    
    old_writed_hash_sum=`cat $archive_dir/$archive_file_md5_name`

    old_dir=`pwd`
    cd $archive_dir
    if [ $os_type == "Darwin" ]; then
        old_real_hash_sum=`md5 -q $archive_file_name`
    fi
    if [ $os_type == "Linux" ]; then
        old_real_hash_sum=`md5sum $archive_file_name`
    fi
    cd $old_dir

    if [[ $old_writed_hash_sum == $old_real_hash_sum ]]; then
        echo "Archive correct."
        rm $archive_file_name
        rm $archive_file_md5_name 
        rm $result_file_name
        exit 0
    else
        echo "Archive incorrect."
        exit 1
    fi
fi

echo "Move files to archive folder."

mv "$archive_file_name" "$archive_dir/$archive_file_name"
mv "$archive_file_md5_name" "$archive_dir/$archive_file_md5_name"

rm $result_file_name

exit 0
