#!/bin/bash

# MongoDB连接信息
mongo_host="10.50.16.24"      # MongoDB主机地址
mongo_port="27017"            # MongoDB端口号
mongo_db="emgda"              # 数据库名称
mongo_username="emgda"        # MongoDB用户名
mongo_password="ShopWorx110T" # MongoDB密码

collection_array=("default" "order" "features" "provisioing" "provisioning" "traceability" "orders")

for item in "${collection_array[@]}"; do
    # MongoDB查询命令
    mongo_group_command='db.'$item'.aggregate([
    		{
        $group: {
            _id: "$elementName"
        }
    		}
	])'

    # 执行MongoDB查询并将输出保存到变量
    group_output=$(mongo --host $mongo_host --port $mongo_port --authenticationDatabase $mongo_db -u $mongo_username -p $mongo_password $mongo_db --eval "$mongo_group_command")

    # 循环遍历group_output中的值
    IFS=$'\n'
    for value in $(echo "$group_output" | grep -o '"_id" : "[^"]*' | grep -o '[^"]*$'); do
        # 在循环中处理每个值，你可以添加其他逻辑处理
        echo "Processing value: $value"

        # 使用mongodump数据
        backup_folder="/opt/collection/${value}"
        mongodump --gzip --host $mongo_host --port $mongo_port --username $mongo_username --password $mongo_password --db $mongo_db --collection $item --query "{ 'elementName': '$value' }" --out "$backup_folder"

    done
done
