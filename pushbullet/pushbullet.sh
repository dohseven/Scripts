#!bin/sh
#
# Utility to send push events through Pushbullet
# Next to the script, you should have a "config"
# containing:
# - a token.key file, with your account token 
#   on first line
# - a device.id file, with your device id 
#   on first line
#   (to get it: curl --header 'Authorization: Bearer <your_access_token_here>' -X GET https://api.pushbullet.com/v2/devices)
#
# Usage: pushbullet.sh "Title" "Body"
# - first parameter:  note title
# - second parameter: note body
#
# Doc: see https://docs.pushbullet.com/
#------------------------------------------------

#------------------------------------------------
# Function to get the token
#------------------------------------------------
get_token(){
    CONFIG_DIR=$(dirname $0)"/config"
    
    if [ ! -d "$CONFIG_DIR" ]; then
        echo "Unable to find config directory"
	exit 1
    fi
    
    TOKEN_FILE="$CONFIG_DIR/token.key"

    if [ ! -f "$TOKEN_FILE" ]; then
        echo "Unable to find token file"
	exit 2
    fi

    read TOKEN < $TOKEN_FILE
}

#------------------------------------------------
# Function to get the device id
#------------------------------------------------
get_device(){
    CONFIG_DIR=$(dirname $0)"/config"
    
    if [ ! -d "$CONFIG_DIR" ]; then
        echo "Unable to find config directory"
	exit 1
    fi
    
    DEVICE_FILE="$CONFIG_DIR/device.id"

    if [ ! -f "$DEVICE_FILE" ]; then
        echo "Unable to find device file"
	exit 2
    fi

    read DEVICE < $DEVICE_FILE
}  

#------------------------------------------------
# Main program
#------------------------------------------------

# Check number of arguments
EXPECTED_ARGS=2
if [ $# -ne $EXPECTED_ARGS ]
then
  echo "Usage: Title Body"
  exit
fi

# Retrieve token
get_token
# Retrieve device id
get_device

# Get command line arguments
TITLE=$1
BODY=$2

# Send request
CURL=`curl -s --header 'Authorization: Bearer '$TOKEN -X POST https://api.pushbullet.com/v2/pushes --header 'Content-Type: application/json' --data-binary '{"device_iden": "'$DEVICE'", "type": "note", "title": "'"$TITLE"'", "body": "'"$BODY"'"}'`

#echo "$CURL"


