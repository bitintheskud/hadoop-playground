#! /bin/bash
#
# Author : @bitintheskud
# Date   : 4 oct 2017
#
# run as root on freshly install test server with centos > 7.4
# this is lab script to play around with hadoop.
# DO NOT RUN that in production or you'll be damn for eternity (and surely fired).
#
#***************************************************************
#
# /!\ THIS SCRIPT IS STILL IN DEVELOPMENT. DO NOT USE /!\
#
# To do :
# 1. create an autoextract script. see https://github.com/megastep/makeself
# 2. add copie etc/*.xml to hadoop conf dir
# 3. test
#***************************************************************

JAVA_VERS="1.8.0"
HADOOP_VERS="2.7.4"
# Usename to create and configure under hadoop
USERNAME="billytheskid"
INSTALL_DIR="$(pwd)"
BASENAME="$(basename $0)"
APACHE_MIRROR_URL="http://mirrors.standaloneinstaller.com/apache/hadoop/common/hadoop-${HADOOP_VERS}/"

# do not change the hostname. It will be use later for hdfs command.
hostnamectl set-hostname "hadoopnode0"

# Update and install package
yum update -y
yum install -y wget sudo curl firewalld

#  Disable SELinux (this is known to cause issues with Hadoop):
cp /etc/selinux/config /etc/selinux/config.orig
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

sestatus | grep enable
if [ $? -eq 0 ] ; then
    echo "Please disable selinux manually.."
    echo "bye..."
    exit 1
fi

#  Disable IPv6 (this is also known to cause issues with Hadoop)
cp /etc/sysctl.conf /etc/sysctl.conf.orig
sed -i "\$anet.ipv6.conf.all.disable_ipv6 = 1" /etc/sysctl.conf
sed -i "\$anet.ipv6.conf.default.disable_ipv6 = 1" /etc/sysctl.conf
sysctl -p

# Install Java. We will install the OpenJDK, which will install both a JDK and JRE
yum install -y java-${JAVA_VERS}-openjdk-devel

# Test that Java has been successfully installed by running the following command
java -version > /dev/null
if [ $? -ne 0 ] ; then
    echo "java is not working as exepected. Please check"
    echo "command :  java -version"
    echo "bye..."
    exit 1
fi

# Locate the installation path for Java, and set the JAVA_HOME environment variable
JAVA_BIN="$(readlink /etc/alternatives/java)"
export JAVA_HOME="$(dirname ${JAVA_BIN%/*})"
echo "export JAVA_HOME=${JAVA_HOME}" >> /root/.bashrc

# Download Hadoop pkg
#
TMP_FILE="/tmp/hadoop-${HADOOP_VERS}.tar.gz" 
FILE_TO_DOWNLOAD="${APACHE_MIRROR_URL}/hadoop-${HADOOP_VERS}.tar.gz"
if [ -f /tmp/hadoop-${HADOOP_VERS}.tar.gz ] ; then
    echo "File exist, skip downloading"
else
    echo "Downloading package hadoop...wait (timeout is 120s)"
    wget -O "${TMP_FILE}" --timeout=120 -q "${FILE_TO_DOWNLOAD}" 
fi

#  Unpack the Hadoop release, move it into a system directory
#  set an environment variable from the Hadoop home directory
if [ -f "${TMP_FILE}" ] ; then
    (cd /tmp ; tar -xf "${TMP_FILE}")
    (cd /tmp ; mv hadoop-${HADOOP_VERS} /usr/share/)
    ln -s /usr/share/hadoop-${HADOOP_VERS} /usr/share/hadoop && export HADOOP_HOME="/usr/share/hadoop"
    echo "Done : download & untar hadoop in ${HADOOP_HOME}"
else
    echo "wget has failed. Try manualy : "
    echo "    wget "${APACHE_MIRROR_URL}"/hadoop-${HADOOP_VERS}.tar.gz"
    exit 1
fi


# Create a directory which we will use as an alternative to the Hadoop configuration directory
mkdir -p /etc/hadoop/conf

#  Create a mapred-site.xml file (I will discuss this later) in the Hadoop configuration directory
cp ${HADOOP_HOME}/etc/hadoop/mapred-site.xml.template ${HADOOP_HOME}/etc/hadoop/mapred-site.xml


#  Add JAVA_HOME environment variable to hadoop-env.sh
cp ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh.orig
sed -i "\$aexport JAVA_HOME=/${JAVA_HOME}/"  ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh

#  Create a symbolic link between the Hadoop configuration directory and the /etc/hadoop /conf directory created in Step 10.
ln -s $HADOOP_HOME/etc/hadoop/* /etc/hadoop/conf/

# Create a logs directory for Hadoop:
mkdir $HADOOP_HOME/logs

#  Create users and groups for HDFS and YARN:
groupadd hadoop
useradd -g hadoop hdfs
useradd -g hadoop yarn

# Change the group and permissions for the Hadoop release files:
chgrp -R hadoop /usr/share/hadoop
chmod -R 777 /usr/share/hadoop

#  Run the built in Pi Estimator example included with the Hadoop release.
echo "Runnning a map reduce job as root to check installation before resuming configuration.."
${HADOOP_HOME}/bin/hadoop jar "${HADOOP_HOME}/share/hadoop/mapreduce/hadoop-mapreduce-examples-${HADOOP_VERS}.jar" pi 16 1000 > /dev/null 2>&1
if [ $? -eq 0 ] ; then
  echo "Hadoop test successfully tested !"
else
  echo "Hadoop test has failed. exiting..."
  exit 1
fi

for FILE in core-site.xml mapred-site.xml hdfs-site.xml yarn-site.xml ; do
  cp ${INSTALL_DIR}/etc/${FILE} /etc/hadoop/conf/
  if [ $? -ne 0 ] ; then
    echo "error while copying ${FILE} in /etc/hadoop/conf/"
    exit 1
  fi
done

echo "Format HDFS on the NameNode."
sudo -u hdfs ${HADOOP_HOME}/bin/hdfs namenode -format > /dev/null 2>&1
if [ $? -ne 0 ] ; then
    echo "fail to format hdfs : sudo -u hdfs ${HADOOP_HOME}/bin/hdfs namenode -format"
    exit 1
fi

echo "Start the NameNode and DataNode (HDFS) daemons."
sudo -u hdfs ${HADOOP_HOME}/sbin/hadoop-daemon.sh start namenode
sudo -u hdfs ${HADOOP_HOME}/sbin/hadoop-daemon.sh start datanode

echo "Start the ResourceManager and NodeManager (YARN) daemons"
sudo -u yarn ${HADOOP_HOME}/sbin/yarn-daemon.sh start resourcemanager
sudo -u yarn ${HADOOP_HOME}/sbin/yarn-daemon.sh start nodemanager

# Use the jps command included with the Java JDK to see the Java processes that are running:
echo "Checking daemons status."
sudo jps | egrep 'DataNode|Jps|NameNode|RessourceManager|NodeManager' > /dev/null 2>&1
if [ $? -ne 0 ] ; then
  echo "Something wrong with the output of the jps command."
  echo "run the command jps to check which one has not started and debug :("
else
  echo "All deamons are started...great !"
fi

# Create user directories and a tmp directory in HDFS and set the appropriate permissions and ownership
echo "Creating user directory for ${USERNAME}"
sudo -u hdfs ${HADOOP_HOME}/bin/hadoop fs -mkdir -p /user/${USERNAME}
sudo -u hdfs ${HADOOP_HOME}/bin/hadoop fs -chown ${USERNAME}: /user/${USERNAME}
sudo -u hdfs ${HADOOP_HOME}/bin/hadoop fs -mkdir /tmp
sudo -u hdfs ${HADOOP_HOME}/bin/hadoop fs -chmod 777 /tmp

# Now run the same Pi Estimator example you ran in Step 16. This will now run in pseudo-distributed mode:
echo "Running another pi mapreduce test..."
sudo -u hdfs ${HADOOP_HOME}/bin/hadoop jar ${HADOOP_HOME}/share/hadoop/mapreduce/hadoop-mapreduce-examples-${HADOOP_VERS}.jar pi 16 1000 > /dev/null 2>&1
if [ $? -eq 0 ] ; then
  echo "Ok hadoop seems to be successfully installed !"
  echo "Yarn available on port <your ip>:8088"
else
  echo "Something went wrong during installation. Please check"
fi
