#!/bin/bash

# MongoDB连接信息
mongo_host="10.50.16.24"      # MongoDB主机地址
mongo_port="27017"            # MongoDB端口号
mongo_db="emgda"              # 数据库名称
mongo_username="emgda"        # MongoDB用户名
mongo_password="ShopWorx110T" # MongoDB密码

collection_array=("default" "features" "orders" "provisioing" "provisioning" "traceability" "order")

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

    # 创建新的集合
    create_collection_command='db.createCollection("'$value'")'
    mongo --host $mongo_host --port $mongo_port --authenticationDatabase $mongo_db -u $mongo_username -p $mongo_password $mongo_db --eval "$create_collection_command"

    # 查询数据并分批处理
    batchSize=100 # 每批处理的数据量
    total=$(mongo --host $mongo_host --port $mongo_port --authenticationDatabase $mongo_db -u $mongo_username -p $mongo_password $mongo_db --quiet --eval "db.$item.find({ 'elementName': '$value' }).count()")
    start=0

    while [ $start -lt $total ]; do
      end=$((start + batchSize))
      if [ $end -gt $total ]; then
        end=$total
      fi

      # 生成新的查询命令，添加分页参数
      mongo_find_command='printjson(db.'$item'.find({ "elementName": "'$value'" }).skip('$start').limit('$batchSize').toArray())'

      # 执行MongoDB查询并输出结果到标准输出
      query_result=$(mongo --host $mongo_host --port $mongo_port --authenticationDatabase $mongo_db -u $mongo_username -p $mongo_password $mongo_db --quiet --eval "$mongo_find_command")

      # 从标准输出中读取数据并进行适当的格式转换
      data=$(echo "$query_result" | tail -n +4 | head -n -2 | sed 's/ISODate(\(.*\))/new Date(\1)/; s/ObjectId("\(.*\)")/ObjectId("\1")/')

      # 将数据压缩为一行
      compressed_data=$(echo "$data" | tr -d '\n')

      # 构建插入操作
      insert_command="db.$value.insertMany("[{$compressed_data}]")"

      # 执行插入操作
      mongo --host $mongo_host --port $mongo_port --authenticationDatabase $mongo_db -u $mongo_username -p $mongo_password $mongo_db --eval "$insert_command" >/dev/null
      start=$end
    done

  done
done
