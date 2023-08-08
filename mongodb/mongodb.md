# ----MongoDB File----
        功能: 在windows系统下，每天备份mongodb的数据；保留7天数据。能将备份出去的数据 恢复进另外的mongodb。
        1. autoClearHistoricalData.bat 此脚本是自动删除保存压缩的mongodb的dump文件，需要自行修改脚本中的保留天数。压缩文件命名格式: yyyy-MM-dd.zip
        2. mongodump.bat 此脚本是mongodb数据库的备份脚本，里面会把昨天的备份文件压缩，保留今天。
        3. mongorestore.bat 此脚本是mongodb数据库的恢复脚本。
        备份和恢复脚本需要输入mongodb的IP和端口号。

        功能：在Linux系统下，将一个mongodb数据库中的几张表中，其中一个固定字段，将这个固定字段创建一个新集合，还要把数据插入进去。
        1. linux_part_collection_mongodump.sh 此脚本是遍历固定表，再去重遍历特定字段，再固定条件mongodump出数据。
        2. linux_part_collection_mongorestore.sh 此脚本是遍历固定表，再去重遍历特定字段，再mongorestore恢复数据。