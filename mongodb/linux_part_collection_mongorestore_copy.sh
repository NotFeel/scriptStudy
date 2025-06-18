#!/bin/bash

# MongoDB连接信息
mongo_host="127.0.0.1"      # MongoDB主机地址
mongo_port="27017"            # MongoDB端口号
mongo_db="emgda"              # 数据库名称
mongo_collection="orders"     # 集合名称
mongo_username="emgda"        # MongoDB用户名
mongo_password="ShopWorx110T" # MongoDB密码

elementName=(
    "process_substation-381" "process_substation-384" "rework" "process_substation-360" "checkin"
    "process_substation-371" "process_substation-358" "process_substation-367" "process_substation-366"
    "process_substation-372" "process_substation-382" "process_substation-383" "process_substation-353"
    "process_substation-364" "process_substation-351" "process_substation-368" "process_substation-369"
    "process_substation-354" "process_substation-355"
)


for value in "${elementName[@]}"; do
    # 在循环中处理每个值，你可以添加其他逻辑处理
    echo "Processing value: $value"

    # 创建新的集合
    create_collection_command='db.createCollection("'$value'")'
    mongo --host $mongo_host --port $mongo_port --authenticationDatabase $mongo_db -u $mongo_username -p $mongo_password $mongo_db --eval "$create_collection_command"

    # 使用mongodump数据
    backup_folder="/opt/collection/${value}/$mongo_db"
    mongorestore --gzip --host $mongo_host --port $mongo_port --username $mongo_username --password $mongo_password -d $mongo_db --dir "$backup_folder" --nsFrom="$mongo_db.default" --nsTo="$mongo_db.$value" --drop

done


