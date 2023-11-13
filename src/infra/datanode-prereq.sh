#! /bin/bash

sudo apt-get update && sudo apt-get install -y build-essential unzip python3 python3-pip openjdk-8-jdk
pip3 install mrjob

wget https://archive.apache.org/dist/hadoop/common/hadoop-3.2.1/hadoop-3.2.1.tar.gz
tar -xzvf hadoop-3.2.1.tar.gz
sudo mv hadoop-3.2.1 /usr/local/hadoop


sudo tee /etc/environment > /dev/null << EOL
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/local/hadoop/bin:/usr/local/hadoop/sbin"
JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
HADOOP_HOME="/usr/local/hadoop"
EOL

source /etc/environment


sudo tee -a /etc/hosts >> /dev/null << EOL
10.1.0.20 namenode
10.1.0.21 datanode1
10.1.0.22 datanode2
10.1.0.23 datanode3
EOL

sudo tee /usr/local/hadoop/etc/hadoop/hdfs-site.xml > /dev/null << EOL
<configuration>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>/usr/local/hadoop/data/nameNode</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>/usr/local/hadoop/data/dataNode</value>
  </property>
  <property>
    <name>dfs.replication</name>
    <value>2</value>
  </property>
</configuration>
EOL

sudo tee /usr/local/hadoop/etc/hadoop/core-site.xml > /dev/null << EOL
<configuration>
  <property>
    <name>fs.default.name</name>
    <value>hdfs://namenode:9000</value>
  </property>
</configuration>
EOL

sudo tee /usr/local/hadoop/etc/hadoop/yarn-site.xml > /dev/null << EOL
<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
      <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
      <value>org.apache.hadoop.mapred.ShuffleHandler</value>
  </property>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>namenode</value>
  </property>
  <property>
    <name>yarn.nodemanager.vmem-check-enabled</name>
    <value>false</value>
  </property>
</configuration>
EOL

sudo tee /usr/local/hadoop/etc/hadoop/mapred-site.xml > /dev/null << EOL
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>yarn.app.mapreduce.am.env</name>
        <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
    </property>
    <property>
        <name>mapreduce.map.env</name>
        <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
    </property>
    <property>
        <name>mapreduce.reduce.env</name>
        <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
    </property>
    <property> 
      <name>mapreduce.application.classpath</name>
      <value>$HADOOP_HOME/share/hadoop/mapreduce/*,$HADOOP_HOME/share/hadoop/mapreduce/lib/*,$HADOOP_HOME/share/hadoop/common/*,$HADOOP_HOME/share/hadoop/common/lib/*,$HADOOP_HOME/share/hadoop/yarn/*,$HADOOP_HOME/share/hadoop/yarn/lib/*,$HADOOP_HOME/share/hadoop/hdfs/*,$HADOOP_HOME/share/hadoop/hdfs/lib/*</value>
    </property>
</configuration>
EOL

sudo tee /usr/local/hadoop/etc/hadoop/workers > /dev/null << EOL
datanode1
datanode2
datanode3
EOL

sudo tee /usr/local/hadoop/etc/hadoop/masters > /dev/null << EOL
namenode
EOL

sudo chmod 777 -R /usr/local/hadoop/


