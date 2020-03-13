#!/bin/bash
set -e
set -u
set -o pipefail
while getopts 'y:E:m:e:N:T:A:p:n:P:l:c:h' OPTION; do
  case "$OPTION" in

     y)
     value="$OPTARG"
     np=$(echo "$OPTARG")
     ;;

     E)
     value="$OPTARG"
     execute=$(echo "$OPTARG")
     ;;

     m)
     value="$OPTARG"
     ml=$(echo "$OPTARG")
     ;;

     e)
     value="$OPTARG"
     except=$(echo "$OPTARG")
     ;;
    N)
     value="$OPTARG"
     namespace=$(echo "$OPTARG")
     ;;
    T)
     value="$OPTARG"
     traffictype=$(echo "$OPTARG")
     ;;

    A)
     value="$OPTARG"
     APP=$(echo "$OPTARG")
     ;;
    p)
     value="$OPTARG"
     port=$(echo "$OPTARG")
     ;;

    n)
     value="$OPTARG"
     ns=$(echo "$OPTARG")
     ;;

    P)
      value="$OPTARG"
      protocol=$(echo "$OPTARG")
      ;;

    l)
      avalue="$OPTARG"
      label=$(echo "$OPTARG")
      ;;

    c)
      avalue="$OPTARG"
      cidr=$(echo "$OPTARG")
      ;;

    h)
echo "[-A Source application] [optional: -a application allow] [optional: -n namespace allow . ,default value: default] [optional: -p port ] [optional: -P TCP/UDP ,TCP default protocol] [optional: -T ingress/egress ,ingress is the default type] [-E execute , if you want to force policy execution] [-y policy.name] [optional: -c 198.172.50.0/24  -e 192.172.50.1/24  , CIDR and IP exception] , [optional: -m "app: apache" ,any match-label ]" >&2
echo "example:  ./policy  -A mysql  -c 10.3.3.0/24 -e 10.3.3.5/24 -m "app: apache" -p 3036 -P TCP -n default -E execute -y mynetwork.yaml -T ingress " >&2 
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"



if [ -z ${namespace+x} ]
then
  namespace=default
  echo "namespace set to default"
fi

if [ -z ${traffictype+x} ]
then
  traffictype=ingress
  echo "traffictype set to ingress"
fi


if [ -z ${APP+x} ]
then
  echo "-A (Source App) is mandatory"
  exit 1
fi

if [ -z ${np+x} ]
then
  np=network.default.policy.yaml
  echo "setting default policy NetworkPolcy.default.yaml"
fi

defaultp=deny
######### denay all #########

cat <<EOF > Deny.all.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: $APP$defaultp
spec:
  podSelector:
   matchLabels:
      app: $APP
EOF

kubectl create -f Deny.all.yaml

######### create yaml template ########

cat <<EOF > $np
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: $APP$traffictype
  namespace: $namespace
spec:
  podSelector:
    matchLabels:
      app: $APP
  policyTypes:
  - Ingress
  - Egress
  $traffictype:
EOF

######### modify "from" values #########
if [ "$traffictype" == "ingress" ]; then
   echo "  - from:" >> $np
else
   echo "  - to:" >> $np
fi


if [ -z ${cidr+x} ]
then
  echo "cidr not set"
else
  echo "    - ipBlock:" >> $np
  echo "       cidr: $cidr" >> $np
fi


if [ -z ${except+x} ]
then
  echo "expect ip was not set"
else
  echo "       except:" >> $np
  echo "       - $except" >> $np
fi

if [ -z ${ns+x} ]
then
  echo "namespace not set"
else
  echo "    - namespaceSelector:" >> $np
  echo "       matchLabels:  " >> $np
  echo "         namespace: $ns" >> $np
fi

if [ -z ${ml+x} ]
then
  echo "match label not set"
else
  echo "    - podSelector:" >> $np
  echo "       matchLabels:" >> $np
  echo "         $ml" >> $np
fi

if [ -z ${port+x} ]
then
  echo "no port set"
else
  echo "    ports:" >> $np 
  echo "    - protocol: $protocol" >> $np
  echo "      port: $port" >> $np
fi

######### ececute yaml if -E ######### 
if [ -z ${execute+x} ]
then
  echo "execution not set"
  kubectl delete networkpolicy default-deny
else
  kubectl create -f $np
fi

if [ "$traffictype" == "ingress" ]; then
  echo "##################  NETWORK-POLICY CREATED ##################"
  echo $APP "<<<<<<<<<<<<<<<<<<<<" $protocol $port $traffictype "<<<<<<<<<<<<<<<<<<<<<<<<<" $ns $cidr $ml 
else
  echo "##################  NETWORK-POLICY CREATED ##################"
  echo $APP ">>>>>>>>>>>>>>>>>>>>" $protocol $port $traffictype ">>>>>>>>>>>>>>>>>>>>" $ns $cidr $ml
fi


#cat $np
