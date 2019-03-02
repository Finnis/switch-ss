#!/bin/bash

plain='\033[0m'
red='\033[31m'
yellow='\033[33m'
black='\033[30m'
green='\033[32m'
blue='\033[34m'
purple='\033[35m'
skyblue='\033[36m'
white='\033[37m'

whiteinblack='\033[40;37m'
whiteinpurple='\033[45;37m'

blink='\033[05m'
highlight='\033[01m'

path='/etc/shadowsocks/'
files=$(ls $path | grep json)
cur_ss=$(ps -aux | grep shadowsocks | grep nobody)
cur_ss=${cur_ss##*/}
cur_ss=${cur_ss%%.*}
[ -z $cur_ss ] && cur_ss=NONE

showChoice(){
    clear
    echo -e " ${purple}Current Server: ${green}${highlight}$cur_ss ${plain}"
    echo -e " ${yellow}Make Your Choice: ${plain}"
    i=1
    node[0]=NO_DATA
    for filename in $files
    do
        node[$i]=${filename%%.*}
        if [ "$cur_ss" = "${node[$i]}" ]
        then
            echo -e "${blink}${red} ${i}: ${skyblue}${node[$i]} ${plain}"
        else
            echo -e "${red} ${i}: ${skyblue}${node[$i]} ${plain}"
        fi
        ((i++))   
    done
echo -e "${red}${highlight} 0: ${skyblue}Restart current server ${plain}"
}

while true
do
    showChoice
    read -p "[Default:0] " sel
    [ -z $sel ] && sel=0
    if [ $sel -lt $i ] >/dev/null 2>&1
    then
        break
    else
        echo -e "${red}[Error!] Please try again. ${plain}"
        sleep 1
    fi
done

if [ "${node[$sel]}" = "$cur_ss" ]
then
    echo -e "${yellow}You select current server. It means exit. ByeBye~~${plain}"
    exit 0
elif [ $sel -eq 0 ]
then
    if [ "$cur_ss" = "NONE" ]
    then
        echo -e "${yellow}There is no shadowsocks running.${plain}"
    else
        echo -e "${yellow}Restarting server ${red}${cur_ss}...${plain}"
        sudo systemctl stop shadowsocks-libev@${cur_ss}
        sleep 1
        sudo systemctl start shadowsocks-libev@${cur_ss}
        cur_ss_pid=$(pgrep -f shadowsocks)
        if [ -n "$cur_ss_pid" ]
        then 
        echo -e "${green}Restart server ${red}${cur_ss} ${green}successfully. ${plain}"
        else
            echo -e "${red}Start server $cur_ss failed. Check config file in '/etc/shadowsocks'. ${plain}"
        fi
    fi
else
    if [ "$cur_ss" != "NONE" ]
    then
        echo -e "${yellow}Stoping server ${red}${cur_ss}... ${plain}"
        sudo systemctl stop shadowsocks-libev@${cur_ss}
        sleep 1
    fi
    sudo systemctl start shadowsocks-libev@${node[$sel]}
    sleep 0.5
    cur_ss_pid=$(pgrep -f shadowsocks)
    if [ -n "$cur_ss_pid" ]
    then
        echo -e "${green}Start server ${red}${node[$sel]} ${green}successfully. ${plain}"
        cur_ss=${node[$sel]}
    else
        echo -e "${red}Start server ${node[$sel]} failed. Check config file in '/etc/shadowsocks'. ${plain}"
    fi
fi