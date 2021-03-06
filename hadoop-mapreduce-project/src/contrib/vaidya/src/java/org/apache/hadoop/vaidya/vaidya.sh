#!/bin/sh
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

this="$0"
while [ -h "$this" ]; do
  ls=`ls -ld "$this"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '.*/.*' > /dev/null; then
    this="$link"
  else
    this=`dirname "$this"`/"$link"
  fi
done

# convert relative path to absolute path
bin=`dirname "$this"`
script=`basename "$this"`
bin=`cd "$bin"; pwd`
this="$bin/$script"

# Check if HADOOP_HOME AND JAVA_HOME is set.
if [ -z "$HADOOP_HOME" ] && [ -z "$HADOOP_PREFIX" ] ; then
  echo "HADOOP_HOME or HADOOP_PREFIX environment variable should be defined"
  exit -1;
fi

if [ -z "$JAVA_HOME" ] ; then
  echo "JAVA_HOME environment variable not defined"
  exit -1;
fi

if [ -z "$HADOOP_PREFIX" ]; then
  hadoopVersion=`$HADOOP_HOME/bin/hadoop version | awk 'BEGIN { RS = "" ; FS = "\n" } ; { print $1 }' | awk '{print $2}'`
else
  hadoopVersion=`$HADOOP_PREFIX/bin/hadoop version | awk 'BEGIN { RS = "" ; FS = "\n" } ; { print $1 }' | awk '{print $2}'`
fi

# so that filenames w/ spaces are handled correctly in loops below
IFS=

# for releases, add core hadoop jar to CLASSPATH
if [ -e $HADOOP_PREFIX/share/hadoop/hadoop-core-* ]; then
  for f in $HADOOP_PREFIX/share/hadoop/hadoop-core-*.jar; do
    CLASSPATH=${CLASSPATH}:$f;
  done

  # add libs to CLASSPATH
  for f in $HADOOP_PREFIX/share/hadoop/lib/*.jar; do
    CLASSPATH=${CLASSPATH}:$f;
  done
else
  # tarball layout
  if [ -e $HADOOP_HOME/hadoop-core-* ]; then
    for f in $HADOOP_HOME/hadoop-core-*.jar; do
      CLASSPATH=${CLASSPATH}:$f;
    done
  fi
  if [ -e $HADOOP_HOME/build/hadoop-core-* ]; then 
    for f in $HADOOP_HOME/build/hadoop-core-*.jar; do
      CLASSPATH=${CLASSPATH}:$f;
    done
  fi
  for f in $HADOOP_HOME/lib/*.jar; do
    CLASSPATH=${CLASSPATH}:$f;
  done

  if [ -d "$HADOOP_HOME/build/ivy/lib/Hadoop/common" ]; then
    for f in $HADOOP_HOME/build/ivy/lib/Hadoop/common/*.jar; do
      CLASSPATH=${CLASSPATH}:$f;
    done
  fi
fi

# Set the Vaidya home
if [ -d "$HADOOP_PREFIX/share/hadoop/contrib/vaidya/" ]; then
  VAIDYA_HOME=$HADOOP_PREFIX/share/hadoop/contrib/vaidya/
fi
if [ -d "$HADOOP_HOME/contrib/vaidya" ]; then
  VAIDYA_HOME=$HADOOP_HOME/contrib/vaidya/
fi
if [ -d "$HADOOP_HOME/build/contrib/vaidya" ]; then
  VAIDYA_HOME=$HADOOP_HOME/build/contrib/vaidya/
fi

# add user-specified CLASSPATH last
if [ "$HADOOP_USER_CLASSPATH_FIRST" = "" ] && [ "$HADOOP_CLASSPATH" != "" ]; then
  CLASSPATH=${CLASSPATH}:${HADOOP_CLASSPATH}
fi

# restore ordinary behaviour
unset IFS

echo "$CLASSPATH"

$JAVA_HOME/bin/java -Xmx1024m -classpath $VAIDYA_HOME/hadoop-vaidya-${hadoopVersion}.jar:${CLASSPATH} org.apache.hadoop.vaidya.postexdiagnosis.PostExPerformanceDiagnoser $@
