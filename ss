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
blackinwhite='\033[47;30m'
blink='\033[05m'
highlight='\033[01m'

chipers=(
aes-256-gcm
aes-192-gcm
aes-128-gcm
aes-256-ctr
aes-192-ctr
aes-128-ctr
aes-256-cfb
aes-192-cfb
aes-128-cfb
camellia-128-cfb
camellia-192-cfb
camellia-256-cfb
chacha20-ietf-poly1305
xchacha20-ietf-poly1305
chacha20-ietf
chacha20
rc4-md5
)

path='/etc/shadowsocks/'

while true
do
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
            if [ "$cur_ss" = "${node[$i]}" ]; then
                echo -e "${blink}${red} ${i}: ${skyblue}${node[$i]} ${plain}"
            else
                echo -e "${red} ${i}: ${skyblue}${node[$i]} ${plain}"
            fi
            ((i++))   
        done
    echo -e "${whiteinblack}${red} 0: ${skyblue}Restart current server ${plain}"
    echo -e "${whiteinblack}${red} a: ${skyblue}Add a config file.${plain}"
    }

    while true
    do
        showChoice
        read -p "[Default:0] " sel
        [ -z $sel ] && sel="0"
        [[ ! $sel =~ ^[0-9]+$ ]] && echo -e "${red}[Error!] Please try again. ${plain}" && sleep 0.7 && continue
        if [[ $sel -lt $i || $sel = "a" ]] >/dev/null 2>&1; then
            break
        else
            echo -e "${red}[Error!] Please try again. ${plain}"
            sleep 0.7
        fi
    done

    if [ ${node[$sel]} = $cur_ss ]; then
        echo -e "${yellow}You select current server. It means exit. ByeBye~~${plain}"
        exit 0
    elif [ $sel = "0" ]; then
        if [ "$cur_ss" = "NONE" ]; then
        echo -e "${yellow}There is no shadowsocks running.${plain}"
        else
            echo -e "${yellow}Restarting server ${red}${cur_ss}...${plain}"
            sudo systemctl stop shadowsocks-libev@${cur_ss}
            sleep 1
            sudo systemctl start shadowsocks-libev@${cur_ss}
            cur_ss_pid=$(pgrep -f shadowsocks)
            if [ -n "$cur_ss_pid" ]; then 
            echo -e "${green}Restart server ${red}${cur_ss} ${green}successfully. ${plain}"
            else
                echo -e "${red}Start server $cur_ss failed. Check config file in '/etc/shadowsocks'. ${plain}"
            fi
        fi
    elif [ $sel = "a" ]; then
        clear
        echo -e "${yellow}Select a chiper:${plain}"
        k=0
        for chiper in ${chipers[*]}
        do
            [ $k -le 9 ] && echo -e "${red} ${k}.${blackinwhite}${chiper}${plain}"
            [ $k -gt 9 ] && echo -e "${red}${k}.${blackinwhite}${chiper}${plain}"
            ((k++))
        done

        while true
        do
            echo -e "${yellow}[Default:12]${plain} \c"
            read protocal
            [ -z $protocal ] && protocal=12
            if [ $protocal -lt ${#chipers[@]} >/dev/null 2>&1 ]; then
                break
            else
                echo -e "${red}Invalid input! Try again.${plain}"
            fi
        done
        sleep 0.3
        while true
        do
            echo -e "${yellow}Enter filename.[No need to end with *.json]:${plain} \c"
            read filename
            [ -z $filename ] && continue
            for var in ${node[*]}
            do
                if [ $var = $filename ]; then
                    echo -e "${red}Filename exists! Try another one.${plain}"
                    continue 2
                fi
            done
            break
        done
        clear
        echo -e "${blue}filename:${plain}${filename}"
        echo -e "${purple}method:${plain}${chipers[$protocal]}"
        sleep 0.2
        echo -e "${purple}server:${plain} \c"
        read server
        sleep 0.2
        echo -e "${purple}server_port:${plain} \c"
        read server_port
        sleep 0.2
        echo -e "${purple}password:${plain} \c"
        read password
        sleep 0.2
        echo -e "${purple}local_address:${plain} \c"
        read -p "[127.0.0.1]" local_address
        [ -z $local_address ] && local_address=127.0.0.1
        sleep 0.2
        echo -e "${purple}local_port:${plain} \c"
        read -p "[1080]" local_port
        [ -z $local_port ] && local_port=1080
        sleep 0.2

        echo -e "${yellow}Will creat ${red}${filename}${yellow}. Continue? [Y/n] ${plain} \c"
        while true
        do
            read m
            [ -z $m ] && m="y"
            if [[ $m = "Y" || $m="y" ]]; then
                sudo  tee /etc/shadowsocks/${filename}.json<<-EOF
{
    "server":"${server}",
    "server_port":${server_port},
    "local_address":"${local_address}",
    "local_port":${local_port},
    "password":"${password}",
    "timeout":300,
    "user":"nobody",
    "method":"${chipers[$protocal]}",
    "fast_open":true,
    "mode":"tcp_and_udp"
}
EOF
                echo -e "${green}File created successfully.${yellow}Press any key to exit.${plain} \c"
                read m
                break
            elif [[$m = "N" || $m="n" ]]; then
                echo -e "${red}Cancelled. Exiting...${plain}"
                sleep 0.5
                break
            else
                echo -e "${red}Invalid input. Try again.${plain}"
            fi
        done
    else
        if [ $cur_ss != "NONE" ]; then
            echo -e "${yellow}Stoping server ${red}${cur_ss}... ${plain}"
            sudo systemctl stop shadowsocks-libev@${cur_ss}
            sleep 1
        fi
        sudo systemctl start shadowsocks-libev@${node[$sel]}
        sleep 0.5
        cur_ss_pid=$(pgrep -f shadowsocks)
        if [ -n "$cur_ss_pid" ]; then
            echo -e "${green}Start server ${red}${node[$sel]} ${green}successfully. ${plain}"
            cur_ss=${node[$sel]}
        else
            echo -e "${red}Start server ${node[$sel]} failed. Check config file in '/etc/shadowsocks'. ${plain}"
        fi
    fi
    sleep 1
done