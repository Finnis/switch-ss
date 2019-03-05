#!/bin/bash

# Colors
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

#Protocal
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

#All script runs in this 'while'
while true
do
    files=$(ls $path | grep json)
    cur_ss=$(ps -aux | grep shadowsocks | grep nobody)
    cur_ss=${cur_ss##*/}
    cur_ss=${cur_ss%%.*}
    [ -z $cur_ss ] && cur_ss=NONE

    #Show origin Menus
    showChoice(){
        clear
#        echo -e " ${purple}Current Server: ${green}${highlight}$cur_ss ${plain}"
        i=0
        node[0]=NO_DATA
        printf "${red}%-4s %-18s %-17s %-10s %-12s${plain}\n" Seq ServerName IPAddress Ping HttpsConnect
        for filename in $files
        do
            ((i++))
            node[$i]=${filename%%.*}
            nodeIpTmp=$(cat ${path}${node[$i]}.json | grep '"server":')
            nodeIpTmp=${nodeIpTmp%\"*}; nodeIp[$i]=${nodeIpTmp##*\"}
            if [ $cur_ss = ${node[$i]} ]; then
                printf "${highlight}%3s|  %-12s|  %-16s |%8s  |  %9s ${plain}\n" ${i}. ${node[$i]} ${nodeIp[$i]} ${pingValues[$i]} ${httpsValues[$i]}
            else
                printf "%3s|  %-12s|  %-16s |%8s  |  %9s \n" ${i}. ${node[$i]} ${nodeIp[$i]} ${pingValues[$i]} ${httpsValues[$i]}
            fi
        done
        printf "%-50s\n" -----------------------------------------------------------------
        echo -e " ${yellow}Make Your Choice: ${plain}"
        echo -e "${purple} 0: ${purple}Restart current server ${plain}"
        echo -e "${blue} a: ${blue}Add  servers.${plain}"
        echo -e "${blue} d: ${blue}Del  servers.${plain}"
        echo -e "${blue} t: ${blue}Test servers.${plain}"
        echo -e "${blue} e: ${blue}Edit servers.${plain}"
        echo -e "${red} x: Exit.${plain}"
    }

    #Show Menus and Get user input
    #node[*] is a array means available server in /etc/shadowsocks/
    #cur_ss means the current choice of servers
    while true
    do
        showChoice
        read -p "[Default:0] " sel
        [[ -z $sel ]] && sel="0"
#        [[ ! $sel =~ ^[0-9]+$ ]] && echo -e "${red}[Error!] Please try again. ${plain}" && sleep 0.7 && continue
        if [[ $sel =~ ^[0-9]+$ && $sel -le $i || $sel = "a" || $sel = "d" || $sel = "e" || $sel = "t" || $sel = "x" ]] >/dev/null 2>&1; then
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
            read yn2
            [ -z $yn2 ] && yn2="y"
            if [[ $yn2 = "Y" || $yn2="y" ]]; then
                sudo  tee ${path}${filename}.json<<-EOF
{
    "server":"${server}",
    "server_port":${server_port},
    "local_address":"${local_address}",
    "local_port":${local_port},
    "password":"${password}",
    "timeout":300,
    "method":"${chipers[$protocal]}",
    "fast_open":true,
    "mode":"tcp_and_udp"
}
EOF
                echo -e "${green}File created successfully.${yellow}Press ENTER to exit.${plain} \c"
                read yn1
                break
            elif [[$yn2 = "N" || $yn2="n" ]]; then
                echo -e "${red}Cancelled. Exiting...${plain}"
                sleep 0.5
                break
            else
                echo -e "${red}Invalid input. Try again.${plain}"
            fi
        done
    elif [ $sel = "d" ]; then
        echo -e "${yellow}Choose servers to delete [Use backspace for more]:${plain}"
        while true
        do
            echo -e "${yellow}[Default ${red}n ${yellow}to cancel.]${plain} \c"
            read del1
            [[ ! $del1 ]] && del1="n"
            delCount=0
            for delFile1 in $del1
            do
                if [[ $delFile1 =~ ^[0-9]+$ && $delFile1 -le $i && $delFile1 -ne 0 ]];then
                    delSure[$delCount]=$delFile1
                    ((delCount++))
                elif [[ ! $delFile1 || $delFile1 = "n" || $delFile1 = "N" ]]; then
                    echo -e "${yellow}You cancel this.${plain}"
                    break 2
                else
                    echo -e "${red}No such server. Try aigin.${plain}"
                    unset delSure
                    continue 2
                fi
            done

            for delFile2 in ${delSure[*]}
            do
                echo "${delFile2}"
                if [ $cur_ss = ${node[$delFile2]} ]; then
                    echo -e "${purple}[Warning]${yellow}Server ${red}$cur_ss ${yellow}is running. [y/N]"
                    while true
                    do
                        read del2
                        if [[ $del2 = "Y" || $del2 = "y" ]];then
                            sudo systemctl stop shadowsocks-libev@${cur_ss}
                            echo -e "${yellow}Stoping server ${cur_ss} ${yellow}..."
                            break
                        elif [[ $del2 = "N" || $del2 = "n" || -z $del2 ]]; then
                            echo -e "${yellow}You cancel this.${plain}"
                            break 2
                        else
                            echo -e "${red}Invalid input! Try again.${plain}"
                        fi
                    done                 
                fi
                sudo rm -f ${path}${node[$delFile2]}.json
                if [ ! -e ${path}${node[$delFile2]}.json ]; then
                    echo -e "${green}Delete server ${node[$delFile2]} successfully.${plain}"
                else
                    echo -e "${red}Delete server ${node[$delFile2] failed.}${plain}"
                fi
            done
            unset pingValues
            unset httpsValues
            break
        done        
    elif [ $sel = "x" ]; then 
        echo -e "${purple}Byebye~~~${plain}"
        sleep 0.5
        clear
        exit 0
    elif [ $sel = "t" ]; then
        unset httpsValues; unset pingValues
        printf "${yellow}Testing...${plain}"
        for ((l=0;l<2;l++))
        do
            {
                if [ $l -eq 0 ]; then
                    for((j=1;j<=$i;j++))
                    do
                        pingReturn=$(ping ${nodeIp[$j]} -q -c 3 -i 0.3 -W 3)
                        pingValue=${pingReturn%/*}; pingValue=${pingValue%/*}; pingValue=${pingValue##*/}            
                        for test1 in ${pingReturn[*]}
                        do
                            {
                                if [ test1 = "100%" ]; then
                                    pingValue="------"
                                    break
                                fi
                            }&
                        done
                        [ $pingValue != "------" ] && pingValue=`printf "%.2f" ${pingValue}` && echo "${j}:ping:${node[$j]}:${pingValue}" >> ~/.ssHttpTmp
                        [ $pingValue = "------" ] && echo "${j}:ping:${node[$j]}:${pingValue}" >> ~/.ssHttpTmp 
                    done
                else
                    for((k=1;k<=$i;k++))
                    do
                        {
                            if [ ${node[$k]} != ${cur_ss} ]; then
                                let portTmp[$k]=k+33333
                                /usr/bin/ss-local  -c  ${path}${node[$k]}.json -l ${portTmp[$k]} >/dev/null 2>&1 &
                                httpsReturn[$k]=$(curl -w "TCP handshake: %{time_connect}, SSL handshake: %{time_appconnect}\n" -so /dev/null https://www.google.com --socks5 127.0.0.1:${portTmp[$k]} --connect-timeout 7)
                                pkill -f ${node[$k]}.json
                            else
                                catPort[$k]=$(cat ${path}${cur_ss}.json | grep "local_port")
                                catPort[$k]=${catPort[$k]#*\:}; cur_port[$k]=${catPort[$k]%\,*}
                                httpsReturn[$k]=$(curl -w "TCP handshake: %{time_connect}, SSL handshake: %{time_appconnect}\n" -so /dev/null https://www.google.com --socks5 127.0.0.1:${cur_port[$k]} --connect-timeout 7)
                            fi
                            httpsReturn1[$k]=${httpsReturn[$k]#*\:}
                            httpsTCP[$k]=${httpsReturn1[$k]%\,*} ;
                            httpsSSL[$k]=${httpsReturn[$k]##*\:} ;
                            if [ ${httpsSSL[$k]} = "0.000000" ]; then
                                echo "${k}:${node[$k]}:timeout" >> ~/.ssHttpTmp
                            else
                                httpsValue[$k]=`echo "(${httpsTCP[$k]} + ${httpsSSL[$k]})*1000" | bc`
                                httpsValue[$k]=`printf "%.2f" ${httpsValue[$k]}`
                                echo "${k}:${node[$k]}:${httpsValue[$k]}" >> ~/.ssHttpTmp
                            fi
                        }&
                    done
                    wait
                fi
            }&
        done
        wait
        for ((j=1;j<=$i;j++))
        do
            pingValueTmp=$(cat ~/.ssHttpTmp | grep "${j}:ping:${node[$j]}:")
            pingValues[$j]=${pingValueTmp##*\:}
        done
        for ((j=1;j<=$i;j++))
        do
            httpsValueTmp=$(cat ~/.ssHttpTmp | grep "${j}:${node[$j]}:")
            httpsValues[$j]=${httpsValueTmp##*\:}
        done
        rm -f ~/.ssHttpTmp
        continue
    elif [ $sel = "e" ]; then
        echo -e "${yellow}Select a server to edit:[n]${plain} \c"
        while true
        do
            read editFile
            if [[ $editFile =~ ^[0-9]+$ && $editFile -le $i && $editFile -ne 0 ]];then
                serverEdi=$(cat ${path}${node[$editFile]}.json | grep '"server":'); serverEdi=${serverEdi%\"*}; serverEdi=${serverEdi##*\"}
                serverPortEdi=$(cat ${path}${node[$editFile]}.json | grep '"server_port":'); serverPortEdi=${serverPortEdi%\,*} ; serverPortEdi=${serverPortEdi##*\:}
                localAddressEdi=$(cat ${path}${node[$editFile]}.json | grep '"local_address":'); localAddressEdi=${localAddressEdi%\"*}; localAddressEdi=${localAddressEdi##*\"}
                localPortEdi=$(cat ${path}${node[$editFile]}.json | grep '"local_port":'); localPortEdi=${localPortEdi%\,*}; localPortEdi=${localPortEdi##*\:}
                passwordEdi=$(cat ${path}${node[$editFile]}.json | grep 'password'); passwordEdi=${passwordEdi%\"*}; passwordEdi=${passwordEdi##*\"}
                timeoutEdi=$(cat ${path}${node[$editFile]}.json | grep '"timeout":'); timeoutEdi=${timeoutEdi%\,*}; timeoutEdi=${timeoutEdi##*\:}
                methodEdi=$(cat ${path}${node[$editFile]}.json | grep '"method":'); methodEdi=${methodEdi%\"*}; methodEdi=${methodEdi##*\"}
                fastopenEdi=$(cat ${path}${node[$editFile]}.json | grep '"fast_open":'); fastopenEdi=${fastopenEdi%\,*}; fastopenEdi=${fastopenEdi##*\:}
                modeEdi=$(cat ${path}${node[$editFile]}.json | grep '"mode":'); modeEdi=${modeEdi%\"*}; modeEdi=${modeEdi##*\"}

                while true
                do
                    clear
                    echo -e "${red}w:save and quit  q:quit without save${plain}"
                    echo "********************************************"
                    echo -e "${yellow}The ${green}${node[$editFile]}.json ${yellow}is now as follows:${plain}"
                    echo "--------------------------------------------"
                    printf "${red}1.${plain}${blue}%12s${plain} : ${purple}%-25s${plain}\n" server ${serverEdi}
                    printf "${red}2.${plain}${blue}%12s${plain} : ${purple}%-25s${plain}\n" server_port ${serverPortEdi}
                    printf "${red}3.${plain}${blue}%12s${plain} : ${purple}%-25s${plain}\n" local_addr ${localAddressEdi}
                    printf "${red}4.${plain}${blue}%12s${plain} : ${purple}%-25s${plain}\n" local_port ${localPortEdi}
                    printf "${red}5.${plain}${blue}%12s${plain} : ${purple}%-25s${plain}\n" password ${passwordEdi}
                    printf "${red}6.${plain}${blue}%12s${plain} : ${purple}%-25s${plain}\n" timeout ${timeoutEdi}
                    printf "${red}7.${plain}${blue}%12s${plain} : ${purple}%-25s${plain}\n" method ${methodEdi}
                    printf "${red}8.${plain}${blue}%12s${plain} : ${purple}%-25s${plain}\n" fast_open ${fastopenEdi}
                    printf "${red}9.${plain}${blue}%12s${plain} : ${purple}%-25s${plain}\n" mode ${modeEdi}
                    echo "--------------------------------------------"
                    echo -e "${yellow}Select a parameter. ${plain}${red}[q] to back.${plain}\c"
                    read paraSel
                    if [[ $paraSel =~ ^[0-9]+$ && $paraSel -le 9 && $paraSel -ne 0 ]];then
                        if [ $paraSel -eq 1 ]; then
                            echo -e "${yellow}Enter new server address:${plain}\c"
                            read paraInput
                            [ ! -z $paraInput ] && serverEdi=$paraInput
                            [ -z $paraInput ] && echo -e "${red}Nothing to change!${plain}" && sleep 0.5
                        elif [ $paraSel -eq 2 ]; then
                            echo -e "${yellow}Enter new server port:${plain}\c"
                            read paraInput
                            [ ! -z $paraInput ] && serverPortEdi=$paraInput
                            [ -z $paraInput ] && echo -e "${red}Nothing to change!${plain}" && sleep 0.5
                        elif [ $paraSel -eq 3 ]; then
                            echo -e "${yellow}Enter new local address:${plain}\c"
                            read paraInput
                            [ ! -z $paraInput ] && localAddressEdi=$paraInput
                            [ -z $paraInput ] && echo -e "${red}Nothing to change!${plain}" && sleep 0.5
                        elif [ $paraSel -eq 4 ]; then
                            echo -e "${yellow}Enter new local port:${plain}\c"
                            read paraInput
                            [ ! -z $paraInput ] && localPortEdi=$paraInput
                            [ -z $paraInput ] && echo -e "${red}Nothing to change!${plain}" && sleep 0.5
                        elif [ $paraSel -eq 5 ]; then
                            echo -e "${yellow}Enter new password:${plain}\c"
                            read paraInput
                            [ ! -z $paraInput ] && passwordEdi=$paraInput
                            [ -z $paraInput ] && echo -e "${red}Nothing to change!${plain}" && sleep 0.5
                        elif [ $paraSel -eq 6 ]; then
                            echo -e "${yellow}Enter new timeout:${plain}\c"
                            read paraInput
                            [ ! -z $paraInput ] && timeoutEdi=$paraInput
                            [ -z $paraInput ] && echo -e "${red}Nothing to change!${plain}" && sleep 0.5
                        elif [ $paraSel -eq 7 ]; then
                            clear
                            echo "********************************************"
                            echo -e "${yellow}Select a protocal.${plain}"
                            for ((j=0;j<17;j++))
                            do
                                echo -e "${red}${j}.${plain} ${blue}${chipers[$j]}${plain}"
                            done
                            echo "********************************************"
                            echo -e "${yellow}Select a protocal:${plain} \c"
                            read paraInput
                            if [[ $paraInput -lt 17 && $paraInput -ge 0 ]]; then
                                methodEdi=${chipers[$paraInput]}
                            else
                                echo -e "${red}[Error] No such protocal.${plain}"
                                sleep 0.5
                            fi
                        elif [ $paraSel -eq 8 ]; then
                            echo -e "${yellow}fastopen:[${purple}true${plain} or ${purple}false${plain}${yellow}]${plain}\c"
                            read paraInput
                            [[ $paraInput != "true" || $paraInput != "false" ]] && echo -e "${red}Nothing to change!${plain}" && sleep 0.5 && continue
                            fastopenEdi=$paraInput
                        else
                            echo -e "${yellow}Enter new mode:${plain}"
                            echo -e "${purple}[ tcp_and_udp | tcp_only | udp_only ] ${plain}\c"
                            read paraInput
                            [[ $paraInput != "tcp_and_udp" && $paraInput != "tcp_only" && ${paraInput} != "udp_only" ]] && echo -e "${red}Nothing to change!${plain}" && sleep 0.5 && continue
                            modeEdi=$paraInput
                            continue
                        fi
                    elif [[ $paraSel = "q" || -z $paraSel ]]; then
                        echo -e "${yellow}Exting...${plain}"
                        sleep 0.5
                        break 2
                    elif [ $paraSel = "w" ]; then
                        sudo  tee ${path}${node[$editFile]}.json<<-EOF
{
    "server":"${serverEdi}",
    "server_port":${serverPortEdi},
    "local_address":"${localAddressEdi}",
    "local_port":${localPortEdi},
    "password":"${passwordEdi}",
    "timeout":${timeoutEdi},
    "method":"${methodEdi}",
    "fast_open":${fastopenEdi},
    "mode":"${modeEdi}"
}
EOF
                        echo -e "Changes saved. Exiting..."
                        break 2
                    else
                        echo -e "${red}[Error] No such parameter.[n]${plain}\c"
                        sleep 0.7
                    fi
                done
            elif [[ $editFile = "n" || -z $editFile ]]; then
                echo -e "${yellow}You cancel this.${plain}"
                sleep 0.5
                continue 2
            else
                echo -e "${red}[Error] No such server.[n]  \c${plain}"
                sleep 0.7
            fi
        done
        continue
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
    unset cur_ss
    unset delSure
    unset i
    sleep 0.7
done