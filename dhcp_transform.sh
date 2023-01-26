#!/bin/sh

#本脚本用于解决在openwrt下使用adguardhome代替原dhcp后状态页面不显示租约问题
#adguardhome的租约文件
source_lease_file="/mnt/sda2/AdGuardHome/leases.db"
#openwrt的租约文件
destination_lease_file="/tmp/dhcp.leases"
transform_interval_sec=300

transform_ip(){
    echo "$1"|base64 -d|hexdump -e '4/1 "%-u."'|sed 's/.$//g'
}

transform_mac(){
    echo "$1"|base64 -d|hexdump -e '6/1 "%02x:"'|sed 's/:$//g'
}

transform(){
    source_lease=$(cat $source_lease_file)
    source_lease_length=$(echo "$source_lease"|jq length)
    index=0
    printf "">$destination_lease_file
    while [ $index -lt $source_lease_length ]
    do
        current_lease=$(echo "$source_lease"|jq .[$index])
        current_lease_mac=$(transform_mac $(echo "$current_lease"|jq -r .mac))
        current_lease_ip=$(transform_ip $(echo "$current_lease"|jq -r .ip))
        current_lease_host=$(echo "$current_lease"|jq -r .host)
        current_lease_exp=$(echo "$current_lease"|jq -r .exp)
        #echo "$current_lease_mac"
        #echo "$current_lease_ip"
        #echo "$current_lease_host"
        #echo "$current_lease_exp"
        if [ $current_lease_exp -eq 1 ]
        then
            current_lease_exp=0
        fi
        echo "$current_lease_exp $current_lease_mac $current_lease_ip $current_lease_host 01:$current_lease_mac">>$destination_lease_file
        index=$(($index+1))
    done
}

while true
do
    if [ -f $source_lease_file ]
    then
        transform
    fi
    sleep $transform_interval_sec
done
    




