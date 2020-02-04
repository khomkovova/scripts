
#!/bin/bash
nodes=""
while [ "$1" != "" ]; do
    case $1 in
         --nodesconf )          shift
                                nodes=$1
                                ;;
        -h | --help )           
								echo "Example how to run:"
								echo "bash install_kafka.sh --nodesconf <Node-ID>-<IP>,2-192.168.88.102  ----first IP and ID should be IP where will be install Zookeeper"
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
echo "---------------START------------" > installation_kafka.log
echo "Please wait few minutes. You can see loggs here installation_kafka.log"

echo "Started downloading Kafka archive."
status=$(wget https://www-eu.apache.org/dist/kafka/2.1.1/kafka_2.12-2.1.1.tgz -P /opt 2>&1)
if [[ $status =~ "saved" ]]; then
  echo "Kafka successfuly downloaded"
else
  echo "Kafka is not downloaded"
  echo "Please download Kafka manualy"
  exit 1
fi

tar -xf /opt/kafka_2.12-2.1.1.tgz -C /opt
ln -s /opt/kafka_2.12-2.1.1 /opt/kafka

useradd kafka
mkdir /var/{lib,log}/kafka
chown -R kafka:kafka /var/{lib,log}/kafka

echo "[Unit]
Description=Apache Kafka
Requires=network.target
After=network.target

[Service]
Type=simple
EnvironmentFile=/opt/kafka/config/kafka
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-failure
User=kafka
Group=kafka
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/kafka.service

echo "KAFKA_HEAP_OPTS=\"-Xms512m -Xmx512m\"" > /opt/kafka/config/kafka
mv /opt/kafka/config/server.properties /opt/kafka/config/server.properties.orig



IFS=',' # hyphen (-) is set as delimiter
read -ra ADDR <<< "$nodes"
IFS='-' # hyphen (-) is set as delimiter
read -ra id_ip <<< "${ADDR[0]}"

my_node_id=${id_ip[0]}
my_node_ip=${id_ip[1]}
confsample="#broker.if must be a unic number
broker.id=$my_node_id
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=/var/lib/kafka
num.partitions=1
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
#zookeeper.connect need to provide ip address of all three zookeeper server
zookeeper.connect="
ips=""
for i in "${ADDR[@]}"; do # access each element of array
    IFS='-' # hyphen (-) is set as delimiter
	read -ra id_ip <<< "$i"
	ips="$ips${id_ip[1]}:2181,"
done
IFS=' ' # reset to default value after usage
ips=${ips::-1}
confsample2="
listeners=PLAINTEXT://$my_node_ip:9092
zookeeper.connection.timeout.ms=6000
group.initial.rebalance.delay.ms=0
delete.topic.enable = true"

confsample=$confsample$ips$confsample2
echo $confsample > /opt/kafka/config/server.properties
echo "LOG_DIR=\"/var/log/kafka\"" > /etc/environment

systemctl daemon-reload >> installation_kafka.log
systemctl enable kafka >> installation_kafka.log
chown -R kafka:kafka /var/{lib,log}/kafka
systemctl start kafka >> installation_kafka.log
systemctl status kafka 
