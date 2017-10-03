# This is the second part. 


17. Use the vi editor to update the core-site.xml file, which contains important information about the cluster, specifically the location of the namenode:

$ sudo vi /etc/hadoop/conf/core-site.xml

# add the following config between the <configuration>

# and </configuration> tags:

<property>

<name>fs.defaultFS</name>

<value>hdfs://hadoopnode0:8020</value>

</property>

Note that the value for the fs.defaultFS configuration parameter needs to be set to hdfs://HOSTNAME:8020, where the HOSTNAME is the name of the NameNode host, which happens to be the localhost in this case.

18. Adapt the instructions in Step 17 to similarly update the hdfs-site.xml file, which contains information specific to HDFS, including the replication factor, which is set to 1 in this case as it is a pseudo-distributed mode cluster:

sudo vi /etc/hadoop/conf/hdfs-site.xml

# add the following config between the <configuration>

# and </configuration> tags:

<property>

<name>dfs.replication</name>

<value>1</value>

</property>

19. Adapt the instructions in Step 17 to similarly update the yarn-site.xml file, which contains information specific to YARN. Importantly, this configuration file contains the address of the resourcemanager for the cluster—in this case it happens to be the localhost, as we are using pseudo-distributed mode:

$ sudo vi /etc/hadoop/conf/yarn-site.xml

# add the following config between the <configuration>

# and </configuration> tags:

<property>

<name>yarn.resourcemanager.hostname</name>

<value>hadoopnode0</value>

</property>

<property>

<name>yarn.nodemanager.aux-services</name>

<value>mapreduce_shuffle</value>

</property>

20. Adapt the instructions in Step 17 to similarly update the mapred-site.xml file, which contains information specific to running MapReduce applications using YARN:

$ sudo vi /etc/hadoop/conf/mapred-site.xml

# add the following config between the <configuration>

# and </configuration> tags:

<property>

<name>mapreduce.framework.name</name>

<value>yarn</value>

</property>

21. Format HDFS on the NameNode:

$ sudo -u hdfs bin/hdfs namenode -format

Enter [Y] to re-format if prompted.

22. Start the NameNode and DataNode (HDFS) daemons:

$ sudo -u hdfs sbin/hadoop-daemon.sh start namenode

$ sudo -u hdfs sbin/hadoop-daemon.sh start datanode

23. Start the ResourceManager and NodeManager (YARN) daemons:

$ sudo -u yarn sbin/yarn-daemon.sh start resourcemanager

$ sudo -u yarn sbin/yarn-daemon.sh start nodemanager

24. Use the jps command included with the Java JDK to see the Java processes that are running:

$ sudo jps

You should see output similar to the following:

2374 DataNode

2835 Jps

2280 NameNode

2485 ResourceManager

2737 NodeManager

25. Create user directories and a tmp directory in HDFS and set the appropriate permissions and ownership:

$ sudo -u hdfs bin/hadoop fs -mkdir -p /user/<your_user>

$ sudo -u hdfs bin/hadoop fs -chown <your_user>:<your_user> /user/<your_user>

$ sudo -u hdfs bin/hadoop fs -mkdir /tmp

$ sudo -u hdfs bin/hadoop fs -chmod 777 /tmp

26. Now run the same Pi Estimator example you ran in Step 16. This will now run in pseudo-distributed mode:

$ bin/hadoop jar \

share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.2.jar \

pi 16 1000

The output you will see in the console will be similar to that in Step 16. Open a browser and go to localhost:8088. You will see the YARN ResourceManager Web UI (which I discuss in Hour 6, “Understanding Data Processing in Hadoop”) (Figure 3.1):
