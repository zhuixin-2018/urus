---
HNS，海思网络子系统（Hisilicon Network Subsystem），主要是验证设备上网口的性能。
本用例验证的是业务网口收发队列个数查询。

Hardware platform: D03 D05  
Software Platform: CentOS Ubuntu Debian 
Author: Vasily Fang <fangyuanzheng3@huawei.com>  
Date: 2017-11-16
Categories: Estuary Documents  
Remark:
---

# Dependency
```
  1.单板启动正常
  2.所有网口各模块加载正常
```

# Test Procedure
```
  1.网口正常初始化后，多次输入查询命令(ethtool -l)，查询到的信息正确
  2.网口up，多次输入查询命令，查询到的信息正确
  3.网口down，多次输入查询命令，查询到的信息正确
  4.重复步骤2-3多次
```

# Expected Result
```
  信息查询正确
```
