VPN_NAME="vpn-dms"

VPN_ID=$(aws ec2 describe-vpn-connections \
  --region ap-northeast-2 \
  --filters "Name=tag:Name,Values=$VPN_NAME" \
  --query "VpnConnections[0].VpnConnectionId" \
  --output text)

echo $VPN_ID


# 1. 두 개의 키를 배열로 저장
KEYS=($(aws ec2 describe-vpn-connections --region ap-northeast-2 --vpn-connection-ids $VPN_ID --query 'VpnConnections[0].CustomerGatewayConfiguration' --output text | grep '<pre_shared_key>' | awk -F'</?pre_shared_key>' '{print $2}'))

# 2. 각각 변수로 꺼내 쓰기 (배열 인덱스는 0부터 시작합니다)
TUNNEL1_KEY=${KEYS[0]}
TUNNEL2_KEY=${KEYS[1]}

# 3. 확인 출력
echo "터널 1 키: $TUNNEL1_KEY"
echo "터널 2 키: $TUNNEL2_KEY"

export TF_VAR_aws_vpn_tunnel1_preshared_key=$TUNNEL1_KEY
export TF_VAR_aws_vpn_tunnel2_preshared_key=$TUNNEL2_KEY
