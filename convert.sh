#!/bin/bash
KeyConverter=""
ValueConverter=""

function getValueConverter()  {
    case $1 in
        avro)
            ValueConverter="\"value.converter\": \"io.confluent.connect.avro.AvroConverter\",\"value.converter.schema.registry.url\": \"http://schema-registry:8081\",\"value.converter.schemas.enable\":false"
            ;;
        json)
            ValueConverter="\"value.converter\": \"org.apache.kafka.connect.json.JsonConverter\",\"value.converter.schemas.enable\":false"
            ;;
        string)
            ValueConverter="\"value.converter\": \"org.apache.kafka.connect.storage.StringConverter\""
            ;;  
    
    esac
}
function getKeyConverter()  {
    case $1 in
        avro)
            KeyConverter="\"key.converter\": \"io.confluent.connect.avro.AvroConverter\",\"key.converter.schema.registry.url\": \"http://schema-registry:8081\""
            ;;
        json)
            KeyConverter="\"key.converter\": \"org.apache.kafka.connect.json.JsonConverter\",\"key.converter.schemas.enable\":false"
            ;;
        string)
            KeyConverter="\"key.converter\": \"org.apache.kafka.connect.storage.StringConverter\""
            ;;       
    esac
}

while getopts “:dlawc” OPTION
do
     case $OPTION in
         d)
            if [ "$2" = "source" ] ;
            then
              curl -X DELETE localhost:8083/connectors/mongo-source-stockdata
              echo "Deleted MongoDB Source Connector"
              exit 1
            fi
            if [ "$2" = "sink" ] ;
            then
              curl -X DELETE localhost:8083/connectors/mongo-atlas-sink
              echo "Deleted MongoDB Sink Connector"
              exit 1
            fi
            if [ "$2" = "all" ] ;
            then
              curl -X DELETE localhost:8083/connectors/mongo-source-stockdata
              sleep 2
              curl -X DELETE localhost:8083/connectors/mongo-atlas-sink
              echo "Deleted MongoDB Source & Sink Connector"
              exit 1
            fi

             ;;
        l)
            curl -X GET localhost:8083/connectors
            exit 1
            ;;
        a)
            if [ "$2" = "source" ] ;
            then
                echo "\nSetting Source\n\n"
                v="{\"name\": \"mongo-source-stockdata\",\"config\": {\"connector.class\":\"com.mongodb.kafka.connect.MongoSourceConnector\",\"tasks.max\":\"1\","
                getKeyConverter "$3"
                v+=$KeyConverter
                v+=","
                getValueConverter "$4"
                v+=$ValueConverter
                v+=",\"publish.full.document.only\": true,\"connection.uri\":\"mongodb://mongo1:27017,mongo2:27017,mongo3:27017\",\"topic.prefix\":\"stockdata\",\"database\":\"Stocks\",\"collection\":\"StockData\"}}"
                echo $v
                curl -X POST -H "Content-Type: application/json" --data "$v" http://localhost:8083/connectors -w "\n"
                exit 1;
            fi
            if [ "$2" = "sink" ] ;
            then
                echo "\nSetting Sink\n\n"
                v="{\"name\": \"mongo-atlas-sink\",\"config\": {\"connector.class\":\"com.mongodb.kafka.connect.MongoSinkConnector\",\"tasks.max\":\"1\",\"topics\":\"stockdata.Stocks.StockData\","
                getKeyConverter "$3"
                v+=$KeyConverter
                v+=","
                getValueConverter "$4"
                v+=$ValueConverter
                v+=",\"connection.uri\":\"$5\","
                v+="\"database\":\"Stocks\",\"collection\":\"StockData\"}}"
                echo $v
                curl -X POST -H "Content-Type: application/json" --data "$v" http://localhost:8083/connectors -w "\n"
                exit 1;
            fi
            ;;
        w)
            echo "Writing 1 document to local MongoDB cluster"
            c="db.StockData.insert({\"MyLongNumber\":NumberLong("
            c+=$(( $RANDOM % 10 ))
            c+="),\"AString\":\"sdfsdfs\", \"An ISODate\":ISODate(\"2020-05-01T04:00Z\"), \"Anew Timestamp\":new Timestamp()})"
            echo "$c"
            mongo localhost/Stocks --eval "$c"
            #'db.StockData.insert({"MyLongNumber":NumberLong(' + $x +'), "AString":"sdfsdfs", "An ISODate":ISODate("2020-05-01T04:00Z"), "Anew Timestamp":new Timestamp()})'
            exit 1
            ;;
        c)
            echo "Clearing topic (restarting kafka)"
            docker stop zookeeper
            sleep 5
            docker stop broker
            sleep 5
            docker start zookeeper
            sleep 5
            docker start broker
            sleep 5
            exit 1
            ;;
     esac
    
done
echo "Usage:\n\n convert\n\n\t[-d] (source|sink|all)\tdeletes connector\n\t[-l]\tlists connectors installe\n\t[-a] (source|sink) (avro|json|string) (avro|json|string) (atlas connection if sink)\tAdd connector with type key value atlas\n\t[-w]\tWrite one document to local MongoDB\n\t[-c]\tClear the topic (restart kafka)\n\n"



 #  {"name": "mongo-source-stockdata",
 #  "config": {
 #    "tasks.max":"1",
 #    "connector.class":"com.mongodb.kafka.connect.MongoSourceConnector",
 #    "key.converter":"org.apache.kafka.connect.json.JsonConverter",
 #    "key.converter.schemas.enable":false,
#   "value.converter":"org.apache.kafka.connect.json.JsonConverter",
#     "value.converter.schemas.enable":false,
#     "publish.full.document.only": true,
#     "connection.uri":"mongodb://mongo1:27017,mongo2:27017,mongo3:27017",
#     "topic.prefix":"stockdata",
#     "database":"Stocks",
#     "collection":"StockData"
#}}