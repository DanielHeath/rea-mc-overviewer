#!/bin/bash
set -e
set -o pipefail

USERDATA=`cat fetch.sh | base64`

DEFAULT_CLASS="c3.large"
echo "Instance class? (default: $DEFAULT_CLASS)"
read INSTANCE_CLASS

if [ -z "$INSTANCE_CLASS" ] ; then
  INSTANCE_CLASS="$DEFAULT_CLASS"
fi

# Pricing
case $INSTANCE_CLASS in
c3.large)
  DEFAULT_PRICE="0.017"
  ;;
c3.xlarge)
  DEFAULT_PRICE="0.041"
  ;;
c3.2xlarge)
  DEFAULT_PRICE="0.081"
  ;;
c3.4xlarge)
  DEFAULT_PRICE="0.161"
  ;;
*)
  echo "I don't know about instance class $INSTANCE_CLASS "
  exit 1
  ;;
esac

echo "Price? (default: $DEFAULT_PRICE)"
read PRICE

if [ -z "$PRICE" ] ; then
  PRICE="$DEFAULT_PRICE"
fi

echo $INSTANCE_CLASS
echo $PRICE

SPOT_REQUEST_ID=`aws \
  ec2 \
  request-spot-instances \
  --instance-count 1 \
  --type one-time \
  --spot-price $PRICE \
  --query 'SpotInstanceRequests[0].SpotInstanceRequestId' \
  --launch-specification '{"SecurityGroups":["launch-wizard-1"],"KeyName":"minecraft-spot-instance-test-key", "IamInstanceProfile": {"Name": "minecraft"},"ImageId":"ami-71345a4b","InstanceType":"'"$INSTANCE_CLASS"'", "UserData": "'$USERDATA'"}' \
  | tr -d '"'
`

function getInstanceId {
  echo "Reading instance-id for spot request"
  INSTANCE_ID=`aws \
    ec2 \
    describe-spot-instance-requests \
    --spot-instance-request-ids $SPOT_REQUEST_ID \
    --query 'SpotInstanceRequests[0].InstanceId' \
    | tr -d '"'
  `
}

while [ -z $INSTANCE_ID ]
do
  getInstanceId
  sleep 10
done

echo "Network interface is:"
aws \
  ec2 \
  describe-instances \
  --instance-id $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].NetworkInterfaces[0].Association.PublicIp'

i-4eca5981
# Check if it's shut down yet
function status {
  aws \
    ec2 \
    describe-instances \
    --instance-id $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].State.Code'
}

# Known ec2 status codes:
# 0 : pending
# 16 : running
# 32 : shutting-down
# 48 : terminated
# 64 : stopping
# 80 : stopped
while [ `status` -lt "30" ]
do
  sleep 10
done


aws ec2 get-console-output \
  --instance-id $INSTANCE_ID
