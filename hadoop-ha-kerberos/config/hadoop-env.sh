export HADOOP_OPTS="-Djava.net.preferIPv4Stack=true"
export HADOOP_HEAPSIZE=1024
export HADOOP_NAMENODE_OPTS="${HADOOP_NAMENODE_OPTS} -Ddfs.namenode.kerberos.principal=nn/_HOST@EXAMPLE.COM -Ddfs.namenode.keytab.file=/keytabs/nn.keytab"
export HADOOP_DATANODE_OPTS="${HADOOP_DATANODE_OPTS} -Ddfs.datanode.kerberos.principal=dn/_HOST@EXAMPLE.COM -Ddfs.datanode.keytab.file=/keytabs/dn.keytab"