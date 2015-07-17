#!/bin/bash
#usage: memprof.sh cmd args...

USAGE="Usage : $0 filename cmd [args]"


if [ "$#" -eq "0" ] 
then
   echo $USAGE
   exit 1
fi


DATE=`date +%Y%m%d_%H_%M_%S`
NAME=$1_${DATE}

MEMPROF_DIR=`dirname $1`
NAME=`basename $1`
mkdir -p $MEMPROF_DIR

#echo "Dir = $MEMPROF_DIR"
#echo "NAME= $NAME"

#Throw argument away
shift;

# launch cmd
#echo "cmd: [ $@ ]"
$@ &
PROCESS_PID=$!

NODE=`uname -n`;
NODE_FILE="${MEMPROF_DIR}/memprof-$NAME-$NODE.csv"
LOG_FILE="${MEMPROF_DIR}/memprof-$NAME.csv"
TMP_FILE="/tmp/memprof-${PROCESS_PID}.tmp"
TMP_FILE2=${TMP_FILE}.2
LOG_FILE2=${LOG_FILE}.2


echo "jobid: $PBS_JOBID" > $LOG_FILE
echo "node: `uname -n`" >> $LOG_FILE
echo "# CPUs: `cat /proc/cpuinfo | grep processor | wc | awk '{print $1}'`" >> $LOG_FILE
echo "time: `date`" >> $LOG_FILE
echo "cmd: $@" >> $LOG_FILE
echo "ElapsedTime(s),Threads(#),%CPU,VmSize(kB),VmRSS(kB),rchar(bytes),wchar(bytes)" >> $LOG_FILE

PERIOD=1 # seconds
IO_READ_LAST=0
IO_WRITE_LAST=0

ELAPSED_TIME=`date +%s`

# Monitor memory and IO usage until cmd exits
while [ -f /proc/$PROCESS_PID/exe ]
do
   CPU=`top -b -p $PROCESS_PID -n 1 | grep $PROCESS_PID | awk '{print $9}'`
   cat /proc/$PROCESS_PID/status /proc/$PROCESS_PID/io > $TMP_FILE

   N_THREADS=`grep Threads $TMP_FILE | awk '{ print $2 }'`
   VM_SIZE=`grep VmSize $TMP_FILE | awk '{ print $2 }'`
   VM_RSS=`grep VmRSS $TMP_FILE | awk '{ print $2 }'`
   IO_READ=`grep rchar $TMP_FILE | awk '{ print $2 }'`
   IO_WRITE=`grep wchar $TMP_FILE | awk '{ print $2 }'`

   IO_READ_ACTUAL=`expr $IO_READ - $IO_READ_LAST`
   IO_WRITE_ACTUAL=`expr $IO_WRITE - $IO_WRITE_LAST`

   echo "$ELAPSED_TIME,$N_THREADS,$CPU,$VM_SIZE,$VM_RSS,$IO_READ_ACTUAL,$IO_WRITE_ACTUAL" >> $LOG_FILE
   echo `free -g -o | head -n2 | tail -n1` >> $NODE_FILE

   IO_READ_LAST=$IO_READ
   IO_WRITE_LAST=$IO_WRITE
   
   CURRENT_TIME=`date +%s`
   while [ `expr $CURRENT_TIME - $ELAPSED_TIME` -lt 1 ]
   do
       sleep 1;
       CURRENT_TIME=`date +%s`;
   done

   ELAPSED_TIME=$CURRENT_TIME
done

if [ ! -f "$TMP_FILE" ]; then
    rm $TMP_FILE 
fi

#exit $?


