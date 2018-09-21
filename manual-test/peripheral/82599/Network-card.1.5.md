---
计算机与外界局域网的连接是通过主机箱内插入一块网络接口板，这块网络接口板的简称就是网卡，我们主要验证的是PCIe 82599网卡在我们服务器上的性能。
本用例验证的是服务器硬复位对82599网卡的影响。

Hardware platform: D03 D05  
Software Platform: CentOS Ubuntu Debian 
Author: Vasily Fang <fangyuanzheng3@huawei.com>  
Date: 2017-11-07
Categories: Estuary Documents  
Remark:
---

# Dependency
```
  1.服务器1台且能正常启动系统
  2.82599网卡一块
```

# Test Procedure
```bash
  1.系统起来后拔插电源
  2.服务器起来后系统还能识别网卡
  3.重复以上步骤5次
```

# Expected Result
```bash
  1.掉电多次后系统还能正常启动
  2.系统还能正常识别网卡
```
