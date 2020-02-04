echo "---------------START------------" > installation_java.log
echo "Please wait few minutes. You can see loggs here installation_java.log"
if ping -q -c 1 -W 1 8.8.8.8 >>installation_java.log; then
  echo ""
else
  echo "IPv4 is down"
  echo "Please set up internet"
  exit 
fi

service ufw stop >> installation_java.log
ufw disable >> installation_java.log
apt-get update >> installation_java.log
apt-get dist-upgrade -y >> installation_java.log

cd /opt
echo "Started downloading Java archive."
status=$(wget --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz 2>&1)
if [[ $status =~ "saved" ]]; then
  echo "Java successfuly downloaded"
else
  echo "Java is not downloaded"
  echo "Please download java manualy"
  exit 1
fi
mkdir /usr/lib/jvm >> installation_java.log  2>>installation_java.log
tar -xf /opt/jdk-8u131-linux-x64.tar.gz -C /usr/lib/jvm >> installation_java.log
ln -s /usr/lib/jvm/jdk1.8.0_131 /usr/lib/jvm/default-java >> installation_java.log
update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk1.8.0_131/bin/java 100 >> installation_java.log
update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/jdk1.8.0_131/bin/javac 100 >> installation_java.log
export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_131/
echo "JAVA_HOME=\"/usr/lib/jvm/jdk1.8.0_131\"" >> /etc/environment
version=$(java -version 2>&1)
if [[ $version =~ "1.8.0_131" ]]; then
  echo "Java successfuly installed"
else
  echo "Java is not installed"
  echo "Please install java manualy"
  exit 1
fi

