#!/bin/bash
nodes=""
while [ "$1" != "" ]; do
    case $1 in
         --nodesconf )          shift
                                nodes=$1
                                ;;
        -h | --help )           
								echo "Example how to run:"
								echo "bash install_zookeeper.sh --nodesconf <Node-ID>-<IP>,2-192.168.88.102  ----first IP and ID should be IP where will be install Zookeeper"
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done
if [[ $nodes == "" ]]; then
	echo "Please set arguments."
	echo "Help -h, --help"
	exit 0
fi

echo "---------------START------------" > installation_zookeeper.log
echo "Please wait few minutes. You can see loggs here installation_zookeeper.log"

cd /opt
echo "Started downloading Zookeeper archive."
status=$(wget  http://apache.cp.if.ua/zookeeper/zookeeper-3.5.6/apache-zookeeper-3.5.6-bin.tar.gz -P /opt 2>&1)
if [[ $status =~ "saved" ]]; then
  echo "Zookeeper successfuly downloaded"
else
  echo "Zookeeper is not downloaded"
  echo "Please download Zookeeper manualy"
  exit 1
fi
tar -xf /opt/apache-zookeeper-3.5.6-bin.tar.gz -C /opt >> installation_zookeeper.log
ln -s /opt/apache-zookeeper-3.5.6-bin /opt/zookeeper >> installation_zookeeper.log
adduser --disabled-password zookeeper --disabled-password -q >> installation_zookeeper.log
mkdir /var/{lib,log}/zookeeper >> installation_zookeeper.log
chown -R zookeeper:zookeeper /var/{lib,log}/zookeeper >> installation_zookeeper.log
cd /opt/zookeeper/conf
cp zoo_sample.cfg zoo.cfg
echo "tickTime=2000
initLimit=10
syncLimit=5
dataDir=/var/lib/zookeeper
clientPort=2181
autopurge.snapRetainCount=3
autopurge.purgeInterval=1" > zoo.cfg


IFS=',' # hyphen (-) is set as delimiter
read -ra ADDR <<< "$nodes"
IFS='-' # hyphen (-) is set as delimiter
read -ra id_ip <<< "${ADDR[0]}"

echo ${id_ip[0]} > /var/lib/zookeeper/myid
for i in "${ADDR[@]}"; do # access each element of array
    IFS='-' # hyphen (-) is set as delimiter
	read -ra id_ip <<< "$i"
	echo "server.${id_ip[0]}=${id_ip[1]}:2888:3888" >> zoo.cfg
done
IFS=' ' # reset to default value after usage

echo "ZOO_LOG_DIR=\"/var/lib/zookeeper\"" >> /etc/environment

echo "SERVER_JVMFLAGS=\"-Xms256m -Xmx256m -XX:+UseG1GC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCApplicationStoppedTime -XX:+PrintGCApplicationConcurrentTime -Xloggc:/var/lib/zookeeper/zookeeper_gc.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=7 -XX:GCLogFileSize=10M\"" >> /etc/environment


chown -R zookeeper:zookeeper /var/{lib,log}/zookeeper #just to be sure
/opt/zookeeper/bin/zkServer.sh stop >/dev/null 2>&1
status=$(/opt/zookeeper/bin/zkServer.sh start 2>&1)

if [[ $status =~ "STARTED" ]]; then
  echo "Zookeeper  started"
else
  echo "Zookeeper is not started"
  echo "Please start Zookeeper manualy"
  exit 1
fi
sleep 2
status=$(/opt/zookeeper/bin/zkServer.sh status 2>/dev/null)
echo "Zookeeper status:  $status"


