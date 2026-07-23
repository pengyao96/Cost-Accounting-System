# 第二炼轧厂 B/S 原型

这套原型以 `第二炼轧厂\ZXCBXT` 和《第二炼轧厂精量化成本核算系统》说明书为分析入口，把原 WinForms 系统按业务域拆成一个可直接打开的 B/S 版本骨架。

当前版本的目标不是“把所有窗体逐个搬到网页”，而是先把以后最难替换的部分搭起来：

- 前端页面与模块导航
- 后端 API 边界
- 仓储接口与 Mock 数据源分离
- 成本核算、标准成本、时刻表的可替换服务入口

## 目录结构

- [index.html](D:\Code\精量化成本核算系统\第二炼轧厂-bs\index.html)
  - 浏览器入口页
- [assets/app.js](D:\Code\精量化成本核算系统\第二炼轧厂-bs\assets\app.js)
  - 前端页面逻辑
- [assets/styles.css](D:\Code\精量化成本核算系统\第二炼轧厂-bs\assets\styles.css)
  - 页面样式
- [backend/server.ps1](D:\Code\精量化成本核算系统\第二炼轧厂-bs\backend\server.ps1)
  - 本地静态文件服务 + Mock API
- [backend/providers/repository.ps1](D:\Code\精量化成本核算系统\第二炼轧厂-bs\backend\providers\repository.ps1)
  - 仓储入口，后续可切换到真实数据库
- [backend/providers/mock-repository.ps1](D:\Code\精量化成本核算系统\第二炼轧厂-bs\backend\providers\mock-repository.ps1)
  - 当前伪数据实现
- [backend/seed-data.ps1](D:\Code\精量化成本核算系统\第二炼轧厂-bs\backend\seed-data.ps1)
  - 伪数据种子
- [open-bs.ps1](D:\Code\精量化成本核算系统\第二炼轧厂-bs\open-bs.ps1)
  - 一键启动
- [stop-bs.ps1](D:\Code\精量化成本核算系统\第二炼轧厂-bs\stop-bs.ps1)
  - 停止服务

## 当前模块映射

### 1780 精量化成本

- 钢种与系列
- 厚度规则
- 宽度规则
- 计划价、试样加工费/包装费
- 准发、轧制、改判与回收实绩
- 按钢种、厚度索引、宽度索引的成本计算

### 炉卷 精量化成本

- 消耗产品与分摊规则
- 计划价、试样加工费、综合信息与轧制实绩
- 固定消耗、节拍参数与排程模拟

### 炼钢 精量化成本

- 钢种基础、路径、消耗产品与计划价
- 转炉、精炼、连铸等工序实绩与固定消耗
- 炼钢水平附加，供1780、炉卷板坯成本修正使用

### 成本与标准成本

- 标准成本条件
- 平均标准成本
- 标准成本提炼结果

## 数据访问策略

当前所有“原本直接访问数据库”的位置，都没有继续直连数据库，而是改成：

1. 前端调用 API
2. API 调用仓储对象
3. 仓储对象目前由 `mock-repository.ps1` 提供伪数据
4. 后续再把 `repository.ps1` 切到 SQL Server 实现

当前 Mock 仓储会把在线维护的数据保存到 `backend/data/mock-state.json`。服务重启时会恢复这份状态文件；该文件不存在或无法读取时则回退到种子数据。后续接入 SQL Server 时，只需新增 `sql-repository.ps1` 并实现与 Mock 仓储一致的方法，不需要重写前端 API 或页面。

## SQL Server 初始化

1. 复制 `backend/config.example.ps1` 为 `backend/config.local.ps1`，填写 SQL 身份验证连接串。
2. 运行 `powershell -ExecutionPolicy Bypass -File .\backend\initialize-sql.ps1` 创建 `SecondRollingCost`、用户组表和用户表。
3. 运行 `powershell -ExecutionPolicy Bypass -File .\open-bs.ps1 -Provider sqlserver` 以 SQL 用户模块启动系统。

也就是说，未来如果要接真库，优先改这里：

- [backend/providers/repository.ps1](D:\Code\精量化成本核算系统\第二炼轧厂-bs\backend\providers\repository.ps1)
- 新增 `sql-repository.ps1`

而不是回头重写前端页面。

## API 边界

- `GET /api/health`
  - 服务健康检查
- `GET /api/bootstrap`
  - 返回系统信息、模块信息、数据集元数据
- `GET /api/datasets/{name}`
  - 获取某个数据集
- `POST /api/datasets/{name}`
  - 保存或新增一条记录
- `DELETE /api/datasets/{name}/{id}`
  - 删除记录
- `POST /api/datasets/{name}/collect`
  - 对实绩类数据执行一次模拟采集
- `POST /api/cost/run`
  - 执行成本核算
- `GET /api/cost/detail?detailKey=...`
  - 获取成本明细
- `POST /api/standard-cost/run`
  - 生成标准成本与平均标准成本结果
- `POST /api/schedules/run`
  - 生成炉卷或热连轧时刻表模拟结果

## 启动方式

推荐直接运行：

```cmd
open-bs.cmd
```

或运行：

```powershell
./open-bs.ps1
```

如果本机 PowerShell 执行策略限制脚本运行，可以用：

```powershell
powershell -ExecutionPolicy Bypass -File .\open-bs.ps1
```

如果只想先起服务、不自动弹浏览器，可以用：

```powershell
powershell -ExecutionPolicy Bypass -File .\open-bs.ps1 -NoBrowser
```

默认地址：

```text
http://127.0.0.1:8091/
```

停止：

```powershell
./stop-bs.ps1
```

或：

```cmd
stop-bs.cmd
```

## 下一步建议

1. 先恢复 `第二炼轧厂\数据库\ljzxcb20170719.bak`
2. 按“参数表 / 实绩表 / 中间表 / 结果表”梳理数据库
3. 逐步把 `RC\ChengBenJiSuanClass.cs`、`SC\StardarCountClass.cs` 的流程迁到真实服务层
4. 新增 `sql-repository.ps1`，先替换只读查询，再替换写入逻辑
