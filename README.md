# NetworkPolicy

you can just automate policies via CLI.   for example , syntax that allow access to mysql app label from specific CIDR (except: 10.100.0.1) and specific app label only.

./NetworkPolicy.sh -A mysql  -c 10.100.0.0/24 -e 10.100.0.1/24 -m "app: apache" -p 3036 -P TCP -n default  -y my.sql.yaml -T ingress -E execute
 
##################  NETWORK-POLICY CREATED ##################
mysql <<<<<<<<<<<<<<<<<<<< TCP 3036 ingress <<<<<<<<<<<<<<<<<<<<<<<<< default 10.100.0.0/24 app: apache
 
kubectl get networkpolicy 
NAME                  POD-SELECTOR   AGE
Mysql-deny-all          app=mysql      90m
mysql-network-policy   app=mysql      90m
 
FW Rule:
 

 
 
NetworkPolicy.sh -h
[-A Source application] [optional: -a application allow] [optional: -n namespace allow . ,default value: default] [optional: -p port ] [optional: -P TCP/UDP ,TCP default protocol] [optional: -T ingress/egress ,ingress is the default type] [-E execute , if you want to force policy execution] [-y policy.name] [optional: -c 198.172.50.0/24  -e 192.172.50.1/24  , CIDR and IP exception] , [optional: -m app: apache ,any match-label ]
 
