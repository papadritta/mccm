#!/bin/bash

get_input() {
  printf "$1: " "$2" >&2; read -r answer
  if [ -z "$answer" ]; then echo "$2"; else echo "$answer"; fi
}

get_answer() {
  printf "%s (y/n): " "$*" >&2; read -n1 -r answer
  while : 
  do
    case $answer in
    [Yy]*)
      return 0;;
    [Nn]*)
      return 1;;
    *) printf "%s" "Please enter 'y' or 'n' to continue: " >&2; read -n1 -r answer
    esac
  done
}

cat << "EOF"
 #   #                       #                                   ###           ##     ##            #                  
 ## ##   ###    ###   # ##   ####    ###    ####  ## #          #   #   ###     #      #     ####  ####    ###   # ##  
 # # #  #   #  #   #  ##  #  #   #  #####  #   #  # # #         #      #   #    #      #    #   #   #     #   #  ##    
 # # #  #   #  #   #  #   #  #   #  #      #  ##  # # #         #   #  #   #    #      #    #  ##   #     #   #  #     
 #   #   ###    ###   #   #  ####    ###    ## #  #   #          ###    ###    ###    ###    ## #    ##    ###   #     
                                                                                                                       
  ###                                        #     #                   #   #                  #     #                     #                 
 #   #   ###   ## #   ## #   #   #  # ##          ####   #   #         ## ##   ###   # ##          ####    ###   # ##          # ##    #### 
 #      #   #  # # #  # # #  #   #  ##  #    #     #     #   #         # # #  #   #  ##  #    #     #     #   #  ##       #    ##  #  #   # 
 #   #  #   #  # # #  # # #  #  ##  #   #    #     #      ####         # # #  #   #  #   #    #     #     #   #  #        #    #   #   #### 
  ###    ###   #   #  #   #   ## #  #   #    #      ##       #         #   #   ###   #   #    #      ##    ###   #        #    #   #      # 
                                                          ###                                                                          ###  
EOF
echo; echo;

cat << "EOF"

 

BASIC LINUX SERVER MONITORING


Basic -> just the stuff you need near time alerting on

Simple -> just standard Linux command line tools

Essential -> everything you need, nothing more
    - block production warning
    - collator service status
    - loss of network connectivity
    - disk space
    - nvme heat, lifespan, and selftest
    - cpu load average

Free -> backend alerting contributed by True Staking (we use it for our own servers, we might as well share)

You will need:
    1.  your node (validator/collator) public address
    2.  your telegram user name or email address.

EOF
echo;echo

if ! get_answer "Do you wish to install and configure MCCM?"; then exit; fi

echo;echo
##### Is My validator/collator producing blocks? #####
COLLATOR_ADDRESS=$(get_input "Please enter your node public address. Paste and press <ENTER> "); echo; echo
if get_answer "Do you want to be alerted if your node has failed to produce a block in the normal time window? "
    then MONITOR_PRODUCING_BLOCKS='true'
    else MONITOR_PRODUCING_BLOCKS='false'
fi

echo; echo

##### Does my validator/collator still have network connectivity? #####
if get_answer "Do you want to be alerted if your collator goes offline or loses network connectivity? "
    then MONITOR_IS_ALIVE='true'
    else MONITOR_IS_ALIVE='false'
fi
echo; echo

##### Is the validator/collator process still running? #####
if get_answer "Do you want to be alerted if your validator/collator service stops running?"
    then 
        service=$(get_input "Please enter the service name you want to monitor? This is usually moonriver or moonbeam but we didn't see those running: ")
        if (sudo systemctl -q is-active $service)
            then MONITOR_PROCESS=$service
            else 
                MONITOR_PROCESS='false'
                echo "\"systemctl is-active $service\" failed, please check service name and rerun setup."
                exit;exit
        fi
    else MONITOR_PROCESS='false'
fi
##### Is my CPU going nuts? #####
if get_answer "Do you want to be alerted if your CPU load average is high?"
    then MONITOR_CPU='true'
        if ! sudo apt list --installed 2>/dev/null | grep -qi util-linux
            then sudo apt install util-linux
        fi
        if ! sudo apt list --installed 2>/dev/null | grep -qi ^bc\/
            then sudo apt install bc
        fi
    else MONITOR_CPU='false'
fi

##### Are my NVME drives running hot? #####
if get_answer "Do you want to be alerted for NVME drive high temperatures? "
    then MONITOR_NVME_HEAT='true'
    else MONITOR_NVME_HEAT='false'
fi
echo; echo

##### Are NVME drives approaching end of life? #####
if get_answer "Do you want to be alerted when NVME drives reach 80% anticipated lifespan?"
    then MONITOR_NVME_LIFESPAN='true'
    else MONITOR_NVME_LIFESPAN='false'
fi
echo; echo

##### Are NVME drives failing the selftest? #####
if get_answer "Do you want to be alerted when an NVME drives fails the self-assessment check? "
    then MONITOR_NVME_SELFTEST='true'
    else MONITOR_NVME_SELFTEST='false'
fi
echo; echo

##### Are any of the disks at 90%+ capacity? #####
if get_answer "Do you want to be alerted when any drive reaches 90% capacity?"
    then MONITOR_DRIVE_SPACE='true'
    else MONITOR_DRIVE_SPACE='false'
fi
echo; echo
##### Do we need to install NVME utilities? #####
if echo $MONITOR_NVME_HEAT,$MONITOR_NVME_LIFESPAN,$MONITOR_NVME_SELFTEST | grep -qi true
    then
        echo "checking for NVME utilities..."
        if ! sudo apt list --installed 2>/dev/null | grep -qi nvme-cli
            then
                echo "installing nvme-cli.."
                sudo apt install nvme-cli
                echo; echo
        fi
        if ! sudo apt list --installed 2>/dev/null | grep -qi smartmontools
            then
                echo "installing smartmontools..."
                sudo apt install smartmontools
                echo; echo
        fi
fi
##### ALert me via email? #####
if get_answer "Do you want to receive collator alerts via email?" 
    then EMAIL_USER=$(get_input "Please enter an email address for receiving alerts ")
    else EMAIL_USER=''
fi
echo; echo
##### Alert me via TG #####
TELEGRAM_USER="";
if get_answer "Do you want to receive collator alerts via Telegram?"
    then TELEGRAM_USER=$(get_input "Please enter your telegram username ")
    else TELEGRAM_USER=''
    echo; echo "IMPORTANT: Please enter a telegram chat with our bot and message 'hi!' LINK: https://t.me/moonbeamccm_bot"
    read -p "After you say "hi" to the mccm bot press <enter>." echo; echo
fi
##### check that we have at least one valide alerting mechanism #####
if ! ( [[ $EMAIL_USER =~ [\@] ]] || [[ $TELEGRAM_USER =~ [a-zA-Z0-9] ]] )
then
  logger "BLSM requires either email or telegram for alerting, bailing out of setup."  
  echo "BLSM requires either email or telegram for alerting. Rerun setup to provide email or telegram alerting.Bailing out."
  exit
fi

##### register with truestaking alert server #####

API="$('/usr/bin/curl' -s -X POST -H 'Content-Type: application/json' -d '{"chain": "movr", "address": "'$COLLATOR_ADDRESS'", "telegram_username": "'$TELEGRAM_USER'", "email_username": "'$EMAIL_USER'", "monitor": {"process": "'$MONITOR_PROCESS'", "nvme_heat": '$MONITOR_NVME_HEAT', "nvme_lifespan": '$MONITOR_NVME_LIFESPAN', "nvme_selftest": '$MONITOR_NVME_SELFTEST', "drive_space": '$MONITOR_DRIVE_SPACE', "cpu": '$MONITOR_CPU', "is_alive": '$MONITOR_IS_ALIVE', "producing_blocks": '$MONITOR_PRODUCING_BLOCKS'}}' https://monitor.truestaking.com/register)"
if ! [[ $API =~ "OK" ]]
then
  logger "BLSM failed to obtain API KEY"
  #echo "Fatal Error: MCCM failed to obtain API KEY. Configuration aborted. Please ensure you have network connectivity to https://monitor.truestaking.com"
  echo $API
  exit
else
   API_KEY=$(echo $API | cut -f 2 -d  " " )
fi

echo -n "Please do not exit the chat with our telegram bot. If you do, you will not be able to receive alerts about your system. If you leave the chat please run mccm_update_monitor.sh"; echo ; echo
sudo mkdir -p /opt/moonbeam/blsm 2>&1 >/dev/null
sudo echo -ne "##### MCCM user variables #####\n### Uncomment the next line to set your own peak_load_avg value or leave it undefined to use the MCCM default\n#peak_load_avg=\n\n##### END MCCM user variables #####\n\n#### DO NOT EDIT BELOW THIS LINE! #####\nAPI_KEY=$API_KEY\nMONITOR_PRODUCING_BLOCKS=$MONITOR_PRODUCING_BLOCKS\nMONITOR_IS_ALIVE=$MONITOR_IS_ALIVE\nMONITOR_PROCESS=$MONITOR_PROCESS\nMONITOR_CPU=$MONITOR_CPU\nMONITOR_DRIVE_SPACE=$MONITOR_DRIVE_SPACE\nMONITOR_NVME_HEAT=$MONITOR_NVME_HEAT\nMONITOR_NVME_LIFESPAN=$MONITOR_NVME_LIFESPAN\nMONITOR_NVME_SELFTEST=$MONITOR_NVME_SELFTEST\nEMAIL_USER=$EMAIL_USER\nTELEGRAM_USER=$TELEGRAM_USER\nCOLLATOR_ADDRESS=$COLLATOR_ADDRESS" > /opt/moonbeam/blsm/env

echo "installing blsm.service"
## curl mccm.service
sudo cp ./blsm.service /etc/systemd/system/blsm.service
sudo systemctl enable blsm.service
echo "installing blsm.timer"
## curl mccm.timer
sudo cp ./blsm.timer /etc/systemd/system/blsm.timer
sudo cp ./monitor.sh /opt/moonbeam/blsm/
sudo cp ./update_monitor.sh /opt/moonbeam/blsm/
sudo systemctl enable blsm.timer
echo
echo "Starting blsm service"
sudo systemctl start blsm.timer

