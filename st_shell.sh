

#1.首先是在压力测试过程用于收集cpu，memory以及db连接数的脚本

#script running in stress test to grep the memory, cpu, dbconnection
#1: ENV:qa
#2: APP : cpu\memory\db
#3: inteval in loop
#4: LONGINTEVAL for and db
#5: core/xtt
#6: core/rmi/ws/...

#get env arguements
ENV=$1
echo "ENV:$ENV"

APP=$2
echo "APP:$APP"

INTEVAL=$3
echo "INTEVAL:$INTEVAL"

LONGINTEVAL=$4

dbtype=$5

echo "ENV is $1, APP is $2, INTEVAL is $3, LONGINTEVAL is $4, dbtype is $5"

MEMORYLOOP=10000

#set output path
OUTPUTPATH=/xxxx/xxx/xxxx

#if none in $1 set default value = qa
if [ $ENV -n ]; then
    ENV='qa'
    echo "use default ENV:qa"
else
    echo "use input ENV: $ENV"
fi

#if none in $2 set default value = cpu
if [ $APP -n ]; then
    APP='cpu'
    echo "use default APP:cpu"
else
    echo "use input APP: $APP"
fi

#if none in $3 set default value = 5  fetch metrix in 5 seconds for cpu and memory
if [ $INTEVAL -n ]; then
    INTEVAL=5
    echo "use default INTEVAL:5"
else
    echo "use input INTEVAL: $INTEVAL"
fi

#if none in $4 set default value = 5  fetch metrix in 5 seconds for cpu and memory
if [ $LONGINTEVAL -n ]; then
    LONGINTEVAL=5
    echo "use default LONGINTEVAL:5"
else
    echo "use input LONGINTEVAL: $LONGINTEVAL"
fi


#conllect the data in qa ubuntu system
case "$ENV" in
        qa)      
    case "$APP" in
            cpu)
                rm $OUTPUTPATH/cpu/cpu.file
                #conllect the data in qa cpu
                mkdir -p $OUTPUTPATH/cpu
                echo "create output file path for cpu : $OUTPUTPATH/cpu"

                echo "entry qa start dump the cpu"
                echo "out put file name is $OUTPUTPATH/cpu/cpu.file"
                for i in `seq $MEMORYLOOP`
                    do  
                         iostat |awk 'NR==4 {print $1}' >> $OUTPUTPATH/jvm/jstack.dump
                         echo "out put file name is $OUTPUTPATH/cpu/cpu.file ; and try sleep 5 seconds"
                         sleep 5
                    done
                ;;
                 
            memory)               
                #conllect the data in qa memory
                rm  $OUTPUTPATH/memory/memory.file 
                mkdir -p $OUTPUTPATH/memory
                echo "create output file path for cpu : $OUTPUTPATH/memory"
                echo "entry qa start dump the memory"    
                
                for i in `seq $MEMORYLOOP`
                do
                    result=`free |awk 'NR==2{print $2 ,$3}'`
                    echo "memory : $result "
                    echo "out put file name is $OUTPUTPATH/memory/memory.file ; and try sleep 5 seconds"
                    echo $result >> $OUTPUTPATH/memory/memory.file
                    sleep 5
                done
                ;;

            db)
                rm $OUTPUTPATH/db/dbconn.file
                mkdir -p $OUTPUTPATH/db
                echo "create output file path for cpu : $OUTPUTPATH/db"
                for i in `seq 100`
                do
                   #GET DBCONN -
                   #please execute next commond in postgresql first 
                   #create user currentname with password 'currentpassword' superuser; 
                   if [ $dbtype = 'core' ]; then
                        DBCONN=$(psql -d newotmscore -c "SELECT count(1) from pg_stat_activity where state='active';"|awk 'NR==3{print}')
                   else
                        DBCONN=$(psql -d newotmscor -c "SELECT count(1) from pg_stat_activity where state='active';"|awk 'NR==3{print}')
                   fi
                   echo "DBCONN : $DBCONN"
                   echo $DBCONN >> $OUTPUTPATH/db/dbconn.file
                   echo "dump the dbconnection to $OUTPUTPATH/db/dbconn.file, and sleep $LONGINTEVAL seconds"
                   sleep $LONGINTEVAL   
                done
                ;;
            *)
                echo "Usage :stat.sh qa {cpu , memory ,db }"
                ;;
    esac
    ;;
esac
exit 0  

#2.第二个是用于收集完数据后，统计数据的脚本

#set output path
OUTPUTPATH=/xx/xxxx/xxxxx



#script to get statistical result for stress test
#cpu 
ACTION=$1

case "$ACTION" in
	cpu)
		cat $OUTPUTPATH/cpu/cpu.file |sed '/^$/d'|awk '{sum+=$1}END{print sum/NR}'
		;;

	memory)
		averageused=`cat $OUTPUTPATH/memory/memory.file |sed '/^$/d'|awk '{sum+=$2}END{print sum/NR}'`
		echo "averageused : $averageused"
		echo "total: `free |awk 'NR==2{print $2}'`"
		;;
	db)
		echo "average dbconn"
		cat $OUTPUTPATH/db/dbconn.file |sed '/^$/d' |awk '{sum+=$1}END{print sum/NR}'
	*)
		echo "Usage :statresult.sh {cpu ,memory ,db}"
        ;;
esac
exit 0 