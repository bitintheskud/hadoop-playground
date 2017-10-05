#! /bin/bash
#
# Author : @bitintheskud
# Date   : 4 oct 2017
# largely inspired from the book "Sams Teach Yourself Hadoop in 24 Hours"
# Thanks to Jeffrey Aven :)
#
# run as root on freshly install test server with centos > 7.4
# this is lab script to play around with hadoop.
# DO NOT RUN that in production or you'll be damn for eternity (and surely fired).


***************************************************************
#
# /!\ THIS SCRIPT IS STILL IN DEVELOPMENT. DO NOT USE /!\
#
# To do :
# 1. create an autoextract script. see https://github.com/megastep/makeself
# 2. add copie etc/*.xml to hadoop conf dir
# 3. test
***************************************************************

java_vers="1.8.0"
hadoop_vers="2.7.4"
username="billythekid"


# do not change the hostname. It will be use later for hdfs command.
hostnamectl set-hostname hadoopnode0

# Update

yum update -y
yum install -y wget sudo

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

yum install -y java-${java_vers}

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

# Download Hadoop
#
apache_mirror_url="http://mirrors.standaloneinstaller.com/apache/hadoop/common/hadoop-${hadoop_vers}/"
wget -q "${apache_mirror_url}"/hadoop-${hadoop_vers}.tar.gz

#  Unpack the Hadoop release, move it into a system directory
#  set an environment variable from the Hadoop home directory

if [ -f hadoop-${hadoop_vers}.tar.gz ] ; then
    tar -xf hadoop-${hadoop_vers}.tar.gz
    mv hadoop-${hadoop_vers} /usr/share/
    ln -s /usr/share/hadoop-${hadoop_vers} /usr/share/hadoop && export HADOOP_HOME=/usr/share/hadoop
    echo "Done : download & untar hadoop in ${HADOOP_HOME}"
else
    echo "wget has failed. Try manualy : "
    echo "    wget "${apache_mirror_url}"/hadoop-${hadoop_vers}.tar.gz"
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

cd ${HADOOP_HOME}

sudo -u hdfs bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-${hadoop_vers}.jar pi 16 1000 | grep 'Estimated value of Pi is 3.142' > /dev/null 2>&1
if [ $? -ne 0 ] ; then
  echo "Hadoop test successfully tested !"
else
  echo "Hadoop test has failed. exiting..."
  exit 1
fi

# Format HDFS on the NameNode:

sudo -u hdfs bin/hdfs namenode -format

# Start the NameNode and DataNode (HDFS) daemons:

sudo -u hdfs sbin/hadoop-daemon.sh start namenode
sudo -u hdfs sbin/hadoop-daemon.sh start datanode

# Start the ResourceManager and NodeManager (YARN) daemons

sudo -u yarn sbin/yarn-daemon.sh start resourcemanager
sudo -u yarn sbin/yarn-daemon.sh start nodemanager

# Use the jps command included with the Java JDK to see the Java processes that are running:

sudo jps | egrep 'DataNode|Jps|NameNode|RessourceManager|NodeManager'
if [ $? -ne 0 ] ; then
  echo "Something wrong with the output of the jps command."
  echo "run jps and see by yourself"
fi

# Create user directories and a tmp directory in HDFS and set the appropriate permissions and ownership:

sudo -u hdfs bin/hadoop fs -mkdir -p /user/${username}
sudo -u hdfs bin/hadoop fs -chown ${username}: /user/${username}
sudo -u hdfs bin/hadoop fs -mkdir /tmp
sudo -u hdfs bin/hadoop fs -chmod 777 /tmp

# Now run the same Pi Estimator example you ran in Step 16. This will now run in pseudo-distributed mode:

bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.2.jar pi 16 1000

# The output you will see in the console will be similar to that in Step 16. Open a browser and go to localhost:8088. You will see the YARN ResourceManager Web UI (which I discuss in Hour 6, “Understanding Data Processing in Hadoop”)
