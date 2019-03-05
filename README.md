# switch-ss
This is a shell script which I use to switch shadowsocks-libev servers on my Arch Linux.
## Prepare to use
- This script is used on Arch Linux. For other linux version, it cannot be used directory. But I am sure with little modify, it can alos work.
- You should install shadowsocks-libev on your linux, for other shadowsocks version, some change need to be done.     
For example, the default config file path for shadowsocks-libev is `/etc/shadowsocks/`; default start user is 'nobody'; there are more protocal methods in ss-libev than other versions.
- For mathematics, install 'bc'.
## How to use
Just copy the 'ss' file to 'usr/local/bin'. Than type ss in command line. I won't give more details about how to use, because I believe that I've tried my best to make it easy to use.
## Why write it
I can't find a manage-friendly shadowsocks client on linux. So I decide to write one. The most considerable reasion is that I'm learning Linux shell!
## On my way
I will continue learn shell. And this script could be updated at any time. In following, I want to add server node testing function.

--- 
Mar 3, 2019