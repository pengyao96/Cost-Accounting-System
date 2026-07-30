function Get-SqlRepositoryConfig {
    $path = Join-Path (Split-Path -Parent $PSScriptRoot) "config.local.ps1"
    if (-not (Test-Path $path -PathType Leaf)) {
        throw "SQL Server configuration is missing. Copy backend/config.example.ps1 to backend/config.local.ps1 and set ConnectionString."
    }
    return . $path
}

function Open-SqlConnection {
    param([Parameter(Mandatory = $true)][string]$ConnectionString)
    $connection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
    $connection.Open()
    return $connection
}

function Add-SqlParameter {
    param($Command, [string]$Name, $Value)
    $parameter = $Command.CreateParameter()
    $parameter.ParameterName = $Name
    if ($null -eq $Value) {
        $parameter.Value = [DBNull]::Value
    } else {
        $parameter.Value = $Value
    }
    [void]$Command.Parameters.Add($parameter)
}

function Invoke-SqlScalar {
    param([string]$ConnectionString, [string]$Sql, [hashtable]$Parameters = @{})
    $connection = Open-SqlConnection $ConnectionString
    try {
        $command = $connection.CreateCommand(); $command.CommandText = $Sql
        foreach ($key in $Parameters.Keys) { Add-SqlParameter -Command $command -Name $key -Value $Parameters[$key] }
        return $command.ExecuteScalar()
    } finally { $connection.Dispose() }
}

function Invoke-SqlNonQuery {
    param([string]$ConnectionString, [string]$Sql, [hashtable]$Parameters = @{})
    $connection = Open-SqlConnection $ConnectionString
    try {
        $command = $connection.CreateCommand(); $command.CommandText = $Sql
        foreach ($key in $Parameters.Keys) { Add-SqlParameter -Command $command -Name $key -Value $Parameters[$key] }
        [void]$command.ExecuteNonQuery()
    } finally { $connection.Dispose() }
}

function Invoke-SqlRows {
    param([string]$ConnectionString, [string]$Sql, [hashtable]$Parameters = @{})
    $connection = Open-SqlConnection $ConnectionString
    try {
        $command = $connection.CreateCommand(); $command.CommandText = $Sql
        foreach ($key in $Parameters.Keys) { Add-SqlParameter -Command $command -Name $key -Value $Parameters[$key] }
        $reader = $command.ExecuteReader(); $rows = @()
        try {
            while ($reader.Read()) {
                $row = [ordered]@{}
                for ($i = 0; $i -lt $reader.FieldCount; $i += 1) {
                    if ($reader.IsDBNull($i)) {
                        $row[$reader.GetName($i)] = ""
                    } else {
                        $value = $reader.GetValue($i)
                        $columnName = $reader.GetName($i)
                        if ($value -is [DateTime]) {
                            $row[$columnName] = $value.ToString("yyyy-MM-dd HH:mm:ss")
                        } elseif ($value -is [DateTimeOffset]) {
                            $row[$columnName] = $value.ToString("yyyy-MM-dd HH:mm:ss")
                        } elseif (($columnName -match '时间|时刻|开始|结束|time') -and ([string]$value -match '^\d{14}$')) {
                            $rawDate = [string]$value
                            $row[$columnName] = "{0}-{1}-{2} {3}:{4}:{5}" -f $rawDate.Substring(0,4), $rawDate.Substring(4,2), $rawDate.Substring(6,2), $rawDate.Substring(8,2), $rawDate.Substring(10,2), $rawDate.Substring(12,2)
                        } else {
                            $row[$columnName] = $value
                        }
                    }
                }
                $rows += ,$row
            }
        } finally { $reader.Dispose() }
        return $rows
    } finally { $connection.Dispose() }
}

function New-SqlPasswordRecord {
    param([Parameter(Mandatory = $true)][string]$Password)
    $salt = New-Object byte[] 16
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($salt)
    $iterations = 100000
    $derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $salt, $iterations)
    return @{ salt = $salt; iterations = $iterations; hash = $derive.GetBytes(32) }
}

function Test-SqlPassword {
    param([string]$Password, [byte[]]$Salt, [int]$Iterations, [byte[]]$Hash)
    $derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $Salt, $Iterations)
    $candidate = $derive.GetBytes(32)
    if ($candidate.Length -ne $Hash.Length) { return $false }
    $difference = 0
    for ($index = 0; $index -lt $candidate.Length; $index += 1) { $difference = $difference -bor ($candidate[$index] -bxor $Hash[$index]) }
    return $difference -eq 0
}

function Get-SqlUserRows {
    param([string]$ConnectionString, [string]$Account = "")
    $sql = "SELECT u.id, u.account, ISNULL(u.display_name, N'') AS name, ISNULL(u.phone, N'') AS phone, ISNULL(u.password_plain, N'需要重置') AS password_plain, g.group_name AS [group], u.password_hash, u.password_salt, u.password_iterations FROM dbo.sys_users u INNER JOIN dbo.sys_user_groups g ON g.id = u.group_id WHERE u.is_enabled = 1"
    $parameters = @{}
    if ($Account) { $sql += " AND u.account = @account"; $parameters["@account"] = $Account }
    return Invoke-SqlRows $ConnectionString $sql $parameters
}

function Get-SqlUserById {
    param([string]$ConnectionString, [int]$Id)
    return Invoke-SqlRows $ConnectionString "SELECT u.id, u.account, ISNULL(u.display_name, N'') AS name, ISNULL(u.phone, N'') AS phone, ISNULL(u.password_plain, N'需要重置') AS password_plain, g.group_name AS [group], u.password_hash, u.password_salt, u.password_iterations FROM dbo.sys_users u INNER JOIN dbo.sys_user_groups g ON g.id = u.group_id WHERE u.id = @id AND u.is_enabled = 1" @{ "@id" = $Id } | Select-Object -First 1
}

function Get-SqlSessionUser {
    param($Repository, [string]$Token)
    if (-not $Repository.AuthTokens.ContainsKey($Token)) { throw "请先登录系统" }
    $user = Get-SqlUserRows $Repository.SqlConnectionString $Repository.AuthTokens[$Token] | Select-Object -First 1
    if (-not $user) { throw "当前登录账户不存在" }
    return $user
}

function Assert-SqlPermission {
    param($Repository, [string]$Token, [string]$Module, [string]$Action)
    $user = Get-SqlSessionUser $Repository $Token
    if ($user.group -eq "系统管理员") { return $user }
    $column = switch ($Action) { "read" { "can_read" } "write" { "can_write" } "calculate" { "can_calculate" } "approve" { "can_approve" } default { throw "Unsupported permission action: $Action" } }
    $allowed = Invoke-SqlScalar $Repository.SqlConnectionString "SELECT p.$column FROM dbo.sys_permissions p INNER JOIN dbo.sys_user_groups g ON g.id=p.group_id WHERE g.group_name=@group AND p.module_code=@module" @{ "@group" = $user.group; "@module" = $Module }
    if ($null -eq $allowed -or -not [bool]$allowed) { throw "当前用户没有 $Action 权限" }
    return $user
}

function Write-SqlAudit {
    param([string]$ConnectionString, $User, [string]$Action, [string]$EntityType, [string]$EntityId, [string]$Detail)
    Invoke-SqlNonQuery $ConnectionString "INSERT dbo.sys_audit_logs(user_id, action, entity_type, entity_id, detail) VALUES(@userId, @action, @entityType, @entityId, @detail)" @{ "@userId" = [int]$User.id; "@action" = $Action; "@entityType" = $EntityType; "@entityId" = $EntityId; "@detail" = $Detail }
}

function Get-SqlHeatTreatmentDataset {
    param([string]$ConnectionString)
    $rows = Invoke-SqlRows $ConnectionString "SELECT id, rclyq, rclms FROM dbo.yclyq ORDER BY id"
    return [ordered]@{
        name = "heatTreatmentRequirements"
        rows = $rows
        meta = [ordered]@{
            title = "热处理要求"
            description = "热处理代码与要求说明"
            readonly = $false
            collectable = $false
            count = $rows.Count
            tableName = "yclyq"
            columns = @("id", "rclyq", "rclms")
        }
    }
}

function Get-SqlGradeDatasetDefinition {
    param([string]$Name)
    switch ($Name) {
        "slabGrades" { return @{ table = "lggrade"; title = "板坯钢种"; description = "板坯钢种、系列与品种" } }
        "plateGrades" { return @{ table = "ljgrade"; title = "钢板钢种"; description = "钢板钢种、品种与系列" } }
        "coilGrades" { return @{ table = "rzgrade"; title = "钢卷钢种"; description = "钢卷钢种、品种与系列" } }
        default { return $null }
    }
}

function Get-SqlGradeDataset {
    param([string]$ConnectionString, [string]$Name)
    $definition = Get-SqlGradeDatasetDefinition $Name
    if (-not $definition) { throw "Unsupported grade dataset: $Name" }
    $rows = Invoke-SqlRows $ConnectionString "SELECT id, [钢种], [品种], [系列] FROM dbo.$($definition.table) ORDER BY id"
    return [ordered]@{
        name = $Name
        rows = $rows
        meta = [ordered]@{ title = $definition.title; description = $definition.description; tableName = $definition.table; readonly = $false; collectable = $false; count = $rows.Count; columns = @("id", "钢种", "品种", "系列") }
    }
}

function Get-SqlThicknessDatasetDefinition {
    param([string]$Name)
    switch ($Name) {
        "slabThicknessIndexes" { return @{ table = "lgthick"; title = "板坯厚度索引"; description = "板坯厚度索引，当前按设计保持空表" } }
        "plateThicknessIndexes" { return @{ table = "ljthick"; title = "钢板厚度索引"; description = "钢板厚度索引" } }
        "coilThicknessIndexes" { return @{ table = "thick"; title = "钢卷厚度索引"; description = "钢卷厚度索引" } }
        default { return $null }
    }
}

function Get-SqlThicknessDataset {
    param([string]$ConnectionString, [string]$Name)
    $definition = Get-SqlThicknessDatasetDefinition $Name
    if (-not $definition) { throw "Unsupported thickness dataset: $Name" }
    $rows = Invoke-SqlRows $ConnectionString "SELECT id, [厚度索引], [厚度起], [厚度尾], [厚度范围] FROM dbo.$($definition.table) ORDER BY TRY_CONVERT(INT, [厚度索引]), id"
    return [ordered]@{
        name = $Name
        rows = $rows
        meta = [ordered]@{ title = $definition.title; description = $definition.description; tableName = $definition.table; readonly = $false; collectable = $false; count = $rows.Count; columns = @("id", "厚度索引", "厚度起", "厚度尾", "厚度范围") }
    }
}

function Get-SqlAdditionalBasicDatasetDefinition {
    param([string]$Name)
    switch ($Name) {
        "slabWidthIndexes" { return @{ table = "lgwidth"; title = "板坯宽度索引"; description = "板坯宽度索引，当前按设计保持空表"; columns = @("宽度索引", "起始", "结束") } }
        "plateWidthIndexes" { return @{ table = "ljwidth"; title = "钢板宽度索引"; description = "钢板宽度索引"; columns = @("宽度索引", "起始", "结束") } }
        "coilWidthIndexes" { return @{ table = "width"; title = "钢卷宽度索引"; description = "钢卷宽度索引"; columns = @("宽度索引", "起始", "结束") } }
        "slabLengthIndexes" { return @{ table = "lgslablen"; title = "板坯长度索引"; description = "板坯长度索引"; columns = @("序号", "长度起始", "长度终止") } }
        "plateLengthIndexes" { return @{ table = "ljpatlen"; title = "钢板长度索引"; description = "钢板长度索引"; columns = @("序号", "长度起始", "长度终止") } }
        "steelmakingPaths" { return @{ table = "lgpath"; title = "工艺路径"; description = "炼钢工艺路径"; columns = @("path_idx", "zlpath", "jlpath", "lzpath") } }
        "wageEquipmentCoefficients" { return @{ table = "lggongzishebeixishu"; title = "工资设备系数"; description = "区域工资与设备系数"; columns = @("区域", "工资系数", "设备系数") } }
        "steelmakingConsumptionTypes" { return @{ table = "lgxhlx"; title = "炼钢消耗类型"; description = "炼钢及连铸消耗类型"; columns = @("hno", "bno", "cp", "dj", "分摊类型", "区域", "列名") } }
        "rollingConsumptionTypes" { return @{ table = "xhlx"; title = "轧钢消耗类型"; description = "轧钢消耗类型"; columns = @("序号", "消耗类型") } }
        "rollingConsumableProducts" { return @{ table = "hccp"; title = "1780 耗材产品"; description = "1780 生产线耗材产品及分摊配置"; columns = @("hno", "bno", "cp", "日核算类型", "分摊类型", "列名") } }
        "steelmakingConsumableProducts" { return @{ table = "lghccp"; title = "炼钢耗材产品"; description = "炼钢耗材产品分类"; columns = @("bno", "消耗") } }
        "coilConsumableProducts" { return @{ table = "ljhccp"; title = "炉卷耗材产品"; description = "炉卷生产线耗材产品及分摊配置"; columns = @("hno", "bno", "cp", "日核算类型", "分摊类型", "列名") } }
        "electricityConfigurations" { return @{ table = "ljdianneng"; title = "电能配置表"; description = "电表按区域的分配配置"; columns = @("电表", "区域", "分配") } }
        "energyConfigurations" { return @{ table = "ljnengyuan"; title = "能源配置表"; description = "能源介质按区域的分配配置"; columns = @("mpname", "rankname", "区域", "分配") } }
        "rzSampleFees" { return @{ table = "sample"; title = "1780 试样加工费"; description = "1780 钢种试样加工费"; columns = @("钢种", "厚度索引", "宽度索引", "价格") } }
        "ljSampleFees" { return @{ table = "ljsample"; title = "炉卷试样加工费"; description = "炉卷钢种试样加工费"; columns = @("钢种", "厚度索引", "宽度索引", "价格") } }
        "alloyPlanPrices" { return @{ table = "lghjljiaoge"; title = "合金计划价"; description = "合金及原料计划价格"; columns = @("mat_code", "mat_name", "计划价", "价差", "价格", "列明", "hjtype") } }
        "rzSlabPlanPrices" { return @{ table = "jihuajia"; title = "1780 板坯计划价"; description = "1780 钢种板坯计划价"; columns = @("钢种", "价格", "市场价", "炼钢水平附加", "炼钢板坯价格") } }
        "ljSlabPlanPrices" { return @{ table = "ljjihuajia"; title = "炉卷板坯计划价"; description = "炉卷钢种板坯计划价"; columns = @("钢种", "计划价", "市场价", "炼钢水平附加", "炼钢实际价格") } }
        "rzSlabPlanPriceHistory" { return @{ table = "jihuajiahistory"; title = "1780 板坯历史计划价"; description = "1780 板坯历史计划价"; columns = @("钢种", "价格", "时间") } }
        "ljSlabPlanPriceHistory" { return @{ table = "ljjihuajiahistory"; title = "炉卷板坯历史计划价"; description = "炉卷板坯历史计划价，当前为空表"; columns = @("钢种", "价格", "时间") } }
        "plateSalePriceHistory" { return @{ table = "ljpatpricehistory"; title = "钢板历史销售价"; description = "钢板历史销售价，当前为空表"; columns = @("钢种", "厚度索引", "宽度索引", "价格", "时间") } }
        "coilSalePriceHistory" { return @{ table = "coilpricehistory"; title = "钢卷历史销售价"; description = "钢卷历史销售价"; columns = @("钢种", "厚度索引", "宽度索引", "价格", "时间") } }
        "internalSettlementPrices" { return @{ table = "ljhuishoufeiyong"; title = "内部结算价"; description = "内部结算单价配置"; columns = @("hno", "类型", "单价", "单价2", "单价3", "单价4") } }
        "packingFees" { return @{ table = "baozhuangfei"; title = "包装费"; description = "钢种包装费配置"; columns = @("钢种", "高度索引", "宽度索引", "价格") } }
        "steelmakingCastingConsumptions" { return @{ table = "lgxiaohao"; title = "炼钢连铸消耗"; description = "财务转账的炼钢与连铸消耗实绩"; columns = @("序号", "开始时间", "结束时间", "耗材序号", "区域", "产品", "量", "金额") } }
        "coilConsumptions" { return @{ table = "ljxiaohao"; title = "炉卷消耗"; description = "财务转账的炉卷消耗实绩"; columns = @("序号", "开始时间", "结束时间", "耗材序号", "产品", "量", "金额") } }
        "rollingConsumptions" { return @{ table = "xiaohao"; title = "1780 消耗"; description = "财务转账的1780消耗实绩"; columns = @("序号", "开始时间", "结束时间", "耗材序号", "产品", "量", "金额") } }
        "electricityActuals" { return @{ table = "dianhaoshiji"; title = "电耗实绩"; description = "按电路与日期记录的电能消耗实绩"; columns = @("circuitry", "日期", "zx_yg_z", "zx_yg_j", "zx_yg_f", "zx_yg_p", "zx_yg_g", "分配比例", "分配总量") } }
        "dailyElectricityConsumptions" { return @{ table = "dianhaodaily"; title = "每日电耗"; description = "按区域记录的每日电能消耗"; columns = @("hno", "measured", "日期", "区域", "zx_yg_j", "zx_yg_f", "zx_yg_p", "zx_yg_g", "量", "金额") } }
        "mediumConsumptions" { return @{ table = "tnengyuan"; title = "介质消耗"; description = "能源介质日消耗实绩"; columns = @("matname", "日期", "mpname", "balance2") } }
        "rzRejudgeActuals" { return @{ table = "tmmhr96"; title = "1780 改判"; description = "1780 钢卷改判实绩"; columns = @("创建时间", "钢卷号", "钢种", "原钢种", "钢卷厚度", "钢卷宽度", "钢卷长度", "钢卷重量", "价格", "原价格", "生产时间", "处理标记") } }
        "rzCoilActuals" { return @{ table = "tmmhr21"; title = "钢卷实绩"; description = "1780 钢卷生产实绩"; columns = @("cust_out_mat_no", "cust_in_mat_no", "in_mat_thick", "in_mat_width", "in_mat_len", "in_mat_wt", "mat_act_thick", "mat_act_width", "mat_act_len", "mat_act_wt", "prod_time") } }
        "ljRejudgeActuals" { return @{ table = "tmmhp96"; title = "炉卷改判实绩"; description = "炉卷钢板改判实绩"; columns = @("创建时间", "钢卷号", "钢种", "原钢种", "厚度", "宽度", "长度", "重量", "生产时间", "事件号", "flag", "厚度索引", "宽度索引", "roll_type", "cut_type") } }
        "ljProductionActuals" { return @{ table = "ljshiji"; title = "炉卷实绩"; description = "炉卷生产实绩"; columns = @("板坯号", "板坯厚度", "板坯宽度", "板坯长度", "板坯重量", "钢号", "班次", "班组", "生产时间", "母版号", "钢板实际厚度", "钢板实际宽度", "钢板实际长度", "钢板理论重量", "钢种", "加热时间", "轧制时间", "轧制方式", "切边毛边", "入库时间", "净重", "原钢种", "厚度索引", "宽度索引", "关联钢种", "品种", "系列", "标记", "gaipanliang", "fur_no", "成材率") } }
        "ljRollingActuals" { return @{ table = "tmmhp21"; title = "炉卷轧制实绩"; description = "炉卷轧制生产实绩"; columns = @("班组", "生产时间", "母版号", "钢板实际厚度", "钢板实际宽度", "钢板实际长度", "钢板理论重量", "钢种", "加热时间", "轧制时间", "轧制方式", "切边毛边", "入库时间", "净重", "原钢种", "厚度索引", "宽度索引", "关联钢种", "品种", "系列", "标记", "gaipanliang", "fur_no") } }
        "ljSubplateActuals" { return @{ table = "tmmhp01"; title = "炉卷子板实绩"; description = "炉卷子板生产实绩"; columns = @("mat_no", "cust_mat_nop", "sg_sign", "mat_act_thick", "mat_act_width", "mat_act_len", "mat_act_wt", "mat_theory_wt", "prod_time", "with_side_flag", "surface_device_code", "complex_device_code", "st_no", "stock_no", "cust_mat_no1", "flag") } }
        "rzRollConsumptions" { return @{ table = "zhagun"; title = "1780 轧辊消耗"; description = "1780 轧辊消耗实绩，当前为空表"; columns = @("轧辊编号", "消耗时间", "消耗量", "备注") } }
        "ljRollConsumptions" { return @{ table = "ljzhagun"; title = "炉卷轧辊消耗"; description = "炉卷轧辊消耗实绩，当前为空表"; columns = @("轧辊编号", "消耗时间", "消耗量", "备注") } }
        "steelmakingCostTotals" { return @{ table = "liangangchengbentotal"; title = "炼钢成本总表"; description = "炼钢实时成本汇总结果"; columns = @(); readonly = $false } }
        "steelmakingCostDetails" { return @{ table = "liangangchengbendetail"; title = "炼钢成本明细表"; description = "炼钢实时成本明细结果，当前暂无数据"; columns = @(); readonly = $false } }
        "coilCostTotals" { return @{ table = "ljchengbenzongbiao"; title = "炉卷成本计算"; description = "炉卷实时成本计算结果"; columns = @(); readonly = $false } }
        "steelmakingProductionReceipts" { return @{ table = "lgproduct"; title = "接收炼钢生产实绩"; description = "接收炼钢生产实绩数据"; columns = @(); readonly = $false } }
        default { return $null }
    }
}

function Resolve-SqlDatasetColumns {
    param([string]$ConnectionString, $Definition)
    if ($Definition.columns -and @($Definition.columns).Count -gt 0) { return @($Definition.columns) }
    $rows = Invoke-SqlRows $ConnectionString "SELECT COLUMN_NAME AS column_name FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = N'dbo' AND TABLE_NAME = @table AND COLUMN_NAME NOT IN (N'id', N'created_at', N'updated_at') ORDER BY ORDINAL_POSITION" @{ "@table" = $Definition.table }
    return @($rows | ForEach-Object { [string]$_.column_name })
}

function Get-SqlAdditionalBasicDataset {
    param([string]$ConnectionString, [string]$Name)
    $definition = Get-SqlAdditionalBasicDatasetDefinition $Name
    if (-not $definition) { throw "Unsupported basic dataset: $Name" }
    $columns = Resolve-SqlDatasetColumns $ConnectionString $definition
    $columnsSql = ($columns | ForEach-Object { "[$_]" }) -join ", "
    $rows = Invoke-SqlRows $ConnectionString "SELECT id, $columnsSql FROM dbo.$($definition.table) ORDER BY id"
    return [ordered]@{
        name = $Name
        rows = $rows
        meta = [ordered]@{ title = $definition.title; description = $definition.description; tableName = $definition.table; readonly = if ($definition.readonly) { $true } else { $false }; collectable = $false; count = $rows.Count; columns = @("id") + @($columns) }
    }
}

function ConvertTo-SqlPublicUser {
    param($Row)
    return [ordered]@{ id = [int]$Row.id; account = [string]$Row.account; name = [string]$Row.name; phone = [string]$Row.phone; displayName = if ($Row.name) { [string]$Row.name } else { [string]$Row.account }; password = [string]$Row.password_plain; group = [string]$Row.group }
}

function Get-SqlCostPeriodId {
    param([string]$ConnectionString, [datetime]$StartDate, [datetime]$EndDate)

    $periodRows = Invoke-SqlRows $ConnectionString "SELECT id, status FROM dbo.accounting_periods WHERE start_date=@startDate AND end_date=@endDate" @{ "@startDate" = $StartDate.Date; "@endDate" = $EndDate.Date }
    if ($periodRows.Count -gt 0) {
        if ($periodRows[0].status -eq "closed") { throw "当前核算期间已结账，不能重复计算" }
        return [int]$periodRows[0].id
    }
    $periodName = "$($StartDate.ToString('yyyy-MM-dd')) 至 $($EndDate.ToString('yyyy-MM-dd'))"
    return [int](Invoke-SqlScalar $ConnectionString "INSERT dbo.accounting_periods(period_name, start_date, end_date) VALUES(@name, @startDate, @endDate); SELECT CAST(SCOPE_IDENTITY() AS int)" @{ "@name" = $periodName; "@startDate" = $StartDate.Date; "@endDate" = $EndDate.Date })
}

function Get-SqlLJCostSourceRows {
    param([string]$ConnectionString, [datetime]$StartDate, [datetime]$EndDate)

    $start = $StartDate.ToString("yyyyMMdd000000")
    $end = $EndDate.AddDays(1).ToString("yyyyMMdd000000")
    return Invoke-SqlRows $ConnectionString @"
SELECT
    ISNULL(NULLIF([钢种], N''), N'未分类') AS grade,
    ISNULL(NULLIF([品种], N''), N'未分类') AS product,
    ISNULL(NULLIF([系列], N''), N'未分类') AS series,
    ISNULL(NULLIF([厚度索引], N''), N'未分类') AS thickness,
    ISNULL(NULLIF([宽度索引], N''), N'未分类') AS width,
    TRY_CONVERT(DECIMAL(18,4), [净重]) AS coil_weight,
    TRY_CONVERT(DECIMAL(18,4), [钢板理论重量]) AS input_weight
FROM dbo.tmmhp21
WHERE [生产时间] >= @start AND [生产时间] < @end
  AND TRY_CONVERT(DECIMAL(18,4), [净重]) IS NOT NULL
"@ @{ "@start" = $start; "@end" = $end }
}

function Get-SqlLJCostInputs {
    param([string]$ConnectionString, [datetime]$StartDate, [datetime]$EndDate)

    $start = $StartDate.ToString("yyyyMMdd000000")
    $end = $EndDate.AddDays(1).ToString("yyyyMMdd000000")
    $consumption = Invoke-SqlScalar $ConnectionString "SELECT ISNULL(SUM([金额]), 0) FROM dbo.ljxiaohao WHERE [开始时间] < @end AND [结束时间] >= @start" @{ "@start" = $start; "@end" = $end }
    $fallbackPrice = Invoke-SqlScalar $ConnectionString "SELECT ISNULL(AVG([计划价]), 0) FROM dbo.ljjihuajia" @{}
    return @{ processAmount = [decimal]$consumption; fallbackPrice = [decimal]$fallbackPrice }
}

function Get-SqlLJPlanPrice {
    param([string]$ConnectionString, [string]$Grade, [decimal]$FallbackPrice)
    $price = Invoke-SqlScalar $ConnectionString "SELECT TOP 1 ISNULL([炼钢实际价格], [计划价]) FROM dbo.ljjihuajia WHERE [钢种]=@grade ORDER BY id DESC" @{ "@grade" = $Grade }
    return if ($null -eq $price) { $FallbackPrice } else { [decimal]$price }
}

function Save-SqlCostCalculation {
    param([string]$ConnectionString, [string]$Line, [string]$Dimension, [datetime]$StartDate, [datetime]$EndDate, $Rows, [int]$SourceRowCount, [decimal]$ProcessAmount)

    $periodId = Get-SqlCostPeriodId $ConnectionString $StartDate $EndDate
    $batchNo = "COST-$($Line.ToUpperInvariant())-$($StartDate.ToString('yyyyMMdd'))-$([guid]::NewGuid().ToString('N').Substring(0, 8).ToUpperInvariant())"
    $totalWeight = [decimal](($Rows | Measure-Object -Property coilWt -Sum).Sum)
    $batchId = [int](Invoke-SqlScalar $ConnectionString "INSERT dbo.cost_calculation_batches(batch_no, period_id, line_code, dimension_code, source_row_count, output_row_count, total_output_weight) VALUES(@batchNo, @periodId, @line, @dimension, @sourceCount, @outputCount, @weight); SELECT CAST(SCOPE_IDENTITY() AS int)" @{ "@batchNo" = $batchNo; "@periodId" = $periodId; "@line" = $Line; "@dimension" = $Dimension; "@sourceCount" = $SourceRowCount; "@outputCount" = $Rows.Count; "@weight" = $totalWeight })
    $output = @()
    foreach ($row in $Rows) {
        $resultId = [int](Invoke-SqlScalar $ConnectionString "INSERT dbo.cost_calculation_results(batch_id, display_name, grade, product, series, thickness, width, coil_weight, input_weight, yield_rate, material_cost, process_cost, manufacturing_cost, sale_price, profit_per_ton) VALUES(@batchId, @name, @grade, @product, @series, @thickness, @width, @coilWeight, @inputWeight, @yieldRate, @materialCost, @processCost, @manufacturingCost, @salePrice, @profit); SELECT CAST(SCOPE_IDENTITY() AS int)" @{ "@batchId" = $batchId; "@name" = $row.name; "@grade" = $row.grade; "@product" = $row.pinzhong; "@series" = $row.xilie; "@thickness" = $row.thickness; "@width" = $row.width; "@coilWeight" = $row.coilWt; "@inputWeight" = $row.inputWt; "@yieldRate" = $row.yieldRate; "@materialCost" = $row.materialCost; "@processCost" = $row.processCost; "@manufacturingCost" = $row.manufacturingCost; "@salePrice" = $row.salePrice; "@profit" = $row.profitPerTon })
        Invoke-SqlNonQuery $ConnectionString "INSERT dbo.cost_calculation_details(result_id, item_name, amount, note) VALUES(@resultId, N'板坯原料成本', @material, N'板坯计划价按钢种匹配'), (@resultId, N'财务转账消耗分摊', @process, N'按本批次成品重量比例分摊'), (@resultId, N'制造成本', @total, N'原料成本与财务转账消耗之和')" @{ "@resultId" = $resultId; "@material" = $row.materialCost; "@process" = $row.processCost; "@total" = $row.manufacturingCost }
        $row.id = $resultId
        $row.detailKey = "sql-cost-$resultId"
        $output += ,$row
    }
    return [ordered]@{ batchId = $batchId; batchNo = $batchNo; periodId = $periodId; processAmount = $ProcessAmount; rows = $output }
}

function Run-SqlLJCost {
    param([string]$ConnectionString, $Request)

    $startDate = [datetime]::Parse([string]$Request.startDate)
    $endDate = [datetime]::Parse([string]$Request.endDate)
    if ($endDate.Date -lt $startDate.Date) { throw "截至日期不能早于开始日期" }
    $dimension = if ($Request.dimension) { [string]$Request.dimension } else { "bySpec" }
    $sourceRows = @(Get-SqlLJCostSourceRows $ConnectionString $startDate $endDate)
    if ($sourceRows.Count -eq 0) { return [ordered]@{ line = "lj"; dimension = $dimension; batchId = $null; rows = @(); message = "所选期间没有可核算的炉卷生产实绩" } }

    $inputs = Get-SqlLJCostInputs $ConnectionString $startDate $endDate
    $groups = @{}
    foreach ($source in $sourceRows) {
        $key = switch ($dimension) {
            "byGrade" { $source.grade }
            "bySeries" { $source.series }
            "byPinzhong" { $source.product }
            "bySpec" { "$($source.grade)|$($source.product)|$($source.series)|$($source.thickness)|$($source.width)" }
            default { throw "Unsupported cost dimension: $dimension" }
        }
        if (-not $groups.ContainsKey($key)) { $groups[$key] = @{ grade = $source.grade; pinzhong = $source.product; xilie = $source.series; thickness = $source.thickness; width = $source.width; coilWt = [decimal]0; inputWt = [decimal]0 } }
        $groups[$key].coilWt += [decimal]$source.coil_weight
        $groups[$key].inputWt += if ($null -eq $source.input_weight) { [decimal]$source.coil_weight } else { [decimal]$source.input_weight }
    }
    $totalWeight = [decimal](($groups.Values | Measure-Object -Property coilWt -Sum).Sum)
    $rows = @()
    foreach ($group in $groups.Values) {
        $price = Get-SqlLJPlanPrice $ConnectionString $group.grade $inputs.fallbackPrice
        $yieldRate = if ($group.inputWt -eq 0) { 0 } else { [math]::Round(($group.coilWt / $group.inputWt) * 100, 4) }
        $materialCost = [math]::Round([double]$price / [math]::Max([double]($yieldRate / 100), 0.0001), 4)
        $processCost = if ($totalWeight -eq 0) { 0 } else { [math]::Round([double]($inputs.processAmount / $totalWeight), 4) }
        $manufacturingCost = [math]::Round($materialCost + $processCost, 4)
        $name = if ($dimension -eq "bySpec") { "$($group.grade) / $($group.thickness) / $($group.width)" } elseif ($dimension -eq "byGrade") { $group.grade } elseif ($dimension -eq "bySeries") { $group.xilie } else { $group.pinzhong }
        $rows += ,[pscustomobject]@{ name = $name; grade = $group.grade; pinzhong = $group.pinzhong; xilie = $group.xilie; thickness = $group.thickness; width = $group.width; coilWt = [math]::Round([double]$group.coilWt, 4); inputWt = [math]::Round([double]$group.inputWt, 4); yieldRate = $yieldRate; materialCost = $materialCost; processCost = $processCost; manufacturingCost = $manufacturingCost; salePrice = 0; profitPerTon = -$manufacturingCost }
    }
    $saved = Save-SqlCostCalculation $ConnectionString "lj" $dimension $startDate $endDate $rows $sourceRows.Count $inputs.processAmount
    return [ordered]@{ line = "lj"; dimension = $dimension; batchId = $saved.batchId; batchNo = $saved.batchNo; rows = $saved.rows }
}

function Initialize-SqlSystemUsers {
    param([string]$ConnectionString)
    $count = [int](Invoke-SqlScalar $ConnectionString "SELECT COUNT(1) FROM dbo.sys_users")
    if ($count -gt 0) { return }
    $users = @(
        @{ account = "admin"; name = "系统管理员"; group = "系统管理员" }
        @{ account = "yaopeng"; name = "姚鹏"; group = "技术科" }
        @{ account = "guoxiaoming"; name = "郭晓明"; group = "安全科" }
        @{ account = "songmengxiao"; name = "宋梦晓"; group = "财务科" }
    )
    foreach ($user in $users) {
        $password = New-SqlPasswordRecord "123456"
        Invoke-SqlNonQuery $ConnectionString "INSERT dbo.sys_users(account, display_name, phone, password_plain, password_hash, password_salt, password_iterations, group_id) SELECT @account, @name, N'', @password, @hash, @salt, @iterations, id FROM dbo.sys_user_groups WHERE group_name = @group" @{ "@account" = $user.account; "@name" = $user.name; "@password" = "123456"; "@hash" = $password.hash; "@salt" = $password.salt; "@iterations" = $password.iterations; "@group" = $user.group }
    }
}

function New-SqlRepository {
    $config = Get-SqlRepositoryConfig
    $connectionString = [string]$config.ConnectionString
    Initialize-SqlSystemUsers $connectionString
    $repository = New-MockRepository
    $repository.ProviderName = "sqlserver"
    $repository | Add-Member -NotePropertyName SqlConnectionString -NotePropertyValue $connectionString
    $repository | Add-Member -NotePropertyName AuthTokens -NotePropertyValue @{}

    $repository | Add-Member -MemberType ScriptMethod -Name GetBootstrap -Force -Value {
        $datasets = [ordered]@{}
        foreach ($name in $this.State.datasets.Keys) {
            $datasets[$name] = if ($name -eq "heatTreatmentRequirements") { (Get-SqlHeatTreatmentDataset $this.SqlConnectionString).meta } elseif (Get-SqlGradeDatasetDefinition $name) { (Get-SqlGradeDataset $this.SqlConnectionString $name).meta } elseif (Get-SqlThicknessDatasetDefinition $name) { (Get-SqlThicknessDataset $this.SqlConnectionString $name).meta } elseif (Get-SqlAdditionalBasicDatasetDefinition $name) { (Get-SqlAdditionalBasicDataset $this.SqlConnectionString $name).meta } else { Mock-GetDatasetMeta -Repository $this -Name $name }
        }
        $this.State.system.currentProvider = "sqlserver"
        return [ordered]@{ system = $this.State.system; notices = $this.State.notices; modules = $this.State.modules; datasets = $datasets }
    }

    $repository | Add-Member -MemberType ScriptMethod -Name GetDataset -Force -Value {
        param([string]$Name)
        if ($Name -eq "heatTreatmentRequirements") { return Get-SqlHeatTreatmentDataset $this.SqlConnectionString }
        if (Get-SqlGradeDatasetDefinition $Name) { return Get-SqlGradeDataset $this.SqlConnectionString $Name }
        if (Get-SqlThicknessDatasetDefinition $Name) { return Get-SqlThicknessDataset $this.SqlConnectionString $Name }
        if (Get-SqlAdditionalBasicDatasetDefinition $Name) { return Get-SqlAdditionalBasicDataset $this.SqlConnectionString $Name }
        $rows = Mock-GetDatasetRows -Repository $this -Name $Name
        return [ordered]@{ name = $Name; rows = $rows; meta = Mock-GetDatasetMeta -Repository $this -Name $Name }
    }

    $repository | Add-Member -MemberType ScriptMethod -Name SaveDatasetRow -Force -Value {
        param([string]$Name, $Payload)
        if (Get-SqlGradeDatasetDefinition $Name) {
            $definition = Get-SqlGradeDatasetDefinition $Name
            $id = [int]$Payload.id; $grade = [string]$Payload.钢种; $product = [string]$Payload.品种; $series = [string]$Payload.系列
            if ([string]::IsNullOrWhiteSpace($grade) -or [string]::IsNullOrWhiteSpace($series)) { throw "钢种和系列不能为空" }
            try {
                if ($id -eq 0) {
                    [void](Invoke-SqlScalar $this.SqlConnectionString "INSERT dbo.$($definition.table)([钢种], [品种], [系列]) VALUES(@grade, @product, @series); SELECT CAST(SCOPE_IDENTITY() AS int)" @{ "@grade" = $grade; "@product" = $product; "@series" = $series })
                } else {
                    Invoke-SqlNonQuery $this.SqlConnectionString "UPDATE dbo.$($definition.table) SET [钢种]=@grade, [品种]=@product, [系列]=@series, updated_at=SYSDATETIME() WHERE id=@id" @{ "@id" = $id; "@grade" = $grade; "@product" = $product; "@series" = $series }
                }
            } catch { throw "钢种保存失败：钢种代码不能重复" }
            $result = Get-SqlGradeDataset $this.SqlConnectionString $Name
            $result.saved = @($result.rows | Where-Object { $_.钢种 -eq $grade } | Select-Object -First 1)
            return $result
        }
        if (Get-SqlThicknessDatasetDefinition $Name) {
            $definition = Get-SqlThicknessDatasetDefinition $Name
            $id = [int]$Payload.id; $index = [string]$Payload.厚度索引
            $start = if ([string]::IsNullOrWhiteSpace([string]$Payload.厚度起)) { $null } else { [decimal]$Payload.厚度起 }
            $end = if ([string]::IsNullOrWhiteSpace([string]$Payload.厚度尾)) { $null } else { [decimal]$Payload.厚度尾 }
            $range = if ([string]::IsNullOrWhiteSpace([string]$Payload.厚度范围)) { $null } else { [string]$Payload.厚度范围 }
            if ([string]::IsNullOrWhiteSpace($index)) { throw "厚度索引不能为空" }
            try {
                if ($id -eq 0) {
                    [void](Invoke-SqlScalar $this.SqlConnectionString "INSERT dbo.$($definition.table)([厚度索引], [厚度起], [厚度尾], [厚度范围]) VALUES(@index, @start, @end, @range); SELECT CAST(SCOPE_IDENTITY() AS int)" @{ "@index" = $index; "@start" = $start; "@end" = $end; "@range" = $range })
                } else {
                    Invoke-SqlNonQuery $this.SqlConnectionString "UPDATE dbo.$($definition.table) SET [厚度索引]=@index, [厚度起]=@start, [厚度尾]=@end, [厚度范围]=@range, updated_at=SYSDATETIME() WHERE id=@id" @{ "@id" = $id; "@index" = $index; "@start" = $start; "@end" = $end; "@range" = $range }
                }
            } catch { throw "厚度索引保存失败：索引不能重复" }
            $result = Get-SqlThicknessDataset $this.SqlConnectionString $Name
            $result.saved = @($result.rows | Where-Object { $_.厚度索引 -eq $index } | Select-Object -First 1)
            return $result
        }
        if (Get-SqlAdditionalBasicDatasetDefinition $Name) {
            $definition = Get-SqlAdditionalBasicDatasetDefinition $Name
            $id = [int]$Payload.id; $columns = @(Resolve-SqlDatasetColumns $this.SqlConnectionString $definition); $parameters = @{}
            for ($index = 0; $index -lt $columns.Count; $index += 1) {
                $property = $Payload.PSObject.Properties[$columns[$index]]
                $value = if ($property) { $property.Value } else { $null }
                if ($index -eq 0 -and [string]::IsNullOrWhiteSpace([string]$value)) { throw "$($columns[0])不能为空" }
                if ($index -gt 0 -and [string]::IsNullOrWhiteSpace([string]$value)) { $value = $null }
                $parameters["@p$index"] = $value
            }
            $columnsSql = ($columns | ForEach-Object { "[$_]" }) -join ", "
            if ($id -eq 0) {
                $parameterSql = (0..($columns.Count - 1) | ForEach-Object { "@p$_" }) -join ", "
                $newId = Invoke-SqlScalar $this.SqlConnectionString "INSERT dbo.$($definition.table)($columnsSql) VALUES($parameterSql); SELECT CAST(SCOPE_IDENTITY() AS int)" $parameters
                $savedId = [int]$newId
            } else {
                $sets = (0..($columns.Count - 1) | ForEach-Object { "[$($columns[$_])] = @p$_" }) -join ", "
                $parameters["@id"] = $id
                Invoke-SqlNonQuery $this.SqlConnectionString "UPDATE dbo.$($definition.table) SET $sets, updated_at=SYSDATETIME() WHERE id=@id" $parameters
                $savedId = $id
            }
            $result = Get-SqlAdditionalBasicDataset $this.SqlConnectionString $Name
            $result.saved = @($result.rows | Where-Object { [int]$_.id -eq $savedId } | Select-Object -First 1)
            return $result
        }
        if ($Name -ne "heatTreatmentRequirements") {
            $row = Mock-SaveRow -Repository $this -Name $Name -Payload $Payload
            Save-MockPersistentState -State $this.State
            $result = $this.GetDataset($Name)
            $result.saved = $row
            return $result
        }
        $id = [int]$Payload.id; $code = [string]$Payload.rclyq; $description = [string]$Payload.rclms
        if ([string]::IsNullOrWhiteSpace($code) -or [string]::IsNullOrWhiteSpace($description)) { throw "rclyq 和 rclms 均不能为空" }
        try {
            if ($id -eq 0) {
                [void](Invoke-SqlScalar $this.SqlConnectionString "INSERT dbo.yclyq(rclyq, rclms) VALUES(@rclyq, @rclms); SELECT CAST(SCOPE_IDENTITY() AS int)" @{ "@rclyq" = $code; "@rclms" = $description })
            } else {
                Invoke-SqlNonQuery $this.SqlConnectionString "UPDATE dbo.yclyq SET rclyq=@rclyq, rclms=@rclms, updated_at=SYSDATETIME() WHERE id=@id" @{ "@id" = $id; "@rclyq" = $code; "@rclms" = $description }
            }
        } catch { throw "热处理要求保存失败：代码不能重复" }
        $result = Get-SqlHeatTreatmentDataset $this.SqlConnectionString
        $result.saved = @($result.rows | Where-Object { $_.rclyq -eq $code } | Select-Object -First 1)
        return $result
    }

    $repository | Add-Member -MemberType ScriptMethod -Name DeleteDatasetRow -Force -Value {
        param([string]$Name, [int]$Id)
        if (Get-SqlGradeDatasetDefinition $Name) {
            $definition = Get-SqlGradeDatasetDefinition $Name
            Invoke-SqlNonQuery $this.SqlConnectionString "DELETE FROM dbo.$($definition.table) WHERE id=@id" @{ "@id" = $Id }
            return Get-SqlGradeDataset $this.SqlConnectionString $Name
        }
        if (Get-SqlThicknessDatasetDefinition $Name) {
            $definition = Get-SqlThicknessDatasetDefinition $Name
            Invoke-SqlNonQuery $this.SqlConnectionString "DELETE FROM dbo.$($definition.table) WHERE id=@id" @{ "@id" = $Id }
            return Get-SqlThicknessDataset $this.SqlConnectionString $Name
        }
        if (Get-SqlAdditionalBasicDatasetDefinition $Name) {
            $definition = Get-SqlAdditionalBasicDatasetDefinition $Name
            Invoke-SqlNonQuery $this.SqlConnectionString "DELETE FROM dbo.$($definition.table) WHERE id=@id" @{ "@id" = $Id }
            return Get-SqlAdditionalBasicDataset $this.SqlConnectionString $Name
        }
        if ($Name -ne "heatTreatmentRequirements") {
            Mock-DeleteRow -Repository $this -Name $Name -Id $Id
            Save-MockPersistentState -State $this.State
            return $this.GetDataset($Name)
        }
        Invoke-SqlNonQuery $this.SqlConnectionString "DELETE FROM dbo.yclyq WHERE id=@id" @{ "@id" = $Id }
        return Get-SqlHeatTreatmentDataset $this.SqlConnectionString
    }

    $repository | Add-Member -MemberType ScriptMethod -Name Login -Force -Value {
        param($Payload)
        $rows = Get-SqlUserRows $this.SqlConnectionString ([string]$Payload.account)
        $row = $rows | Select-Object -First 1
        if (-not $row -or -not (Test-SqlPassword ([string]$Payload.password) ([byte[]]$row.password_salt) ([int]$row.password_iterations) ([byte[]]$row.password_hash))) { throw "账户或密码错误" }
        $token = [guid]::NewGuid().ToString("N"); $this.AuthTokens[$token] = [string]$row.account
        return [ordered]@{ token = $token; user = ConvertTo-SqlPublicUser $row }
    }

    $repository | Add-Member -MemberType ScriptMethod -Name GetUsers -Force -Value {
        param([string]$Token)
        if (-not $this.AuthTokens.ContainsKey($Token)) { throw "请先登录系统" }
        $current = Get-SqlUserRows $this.SqlConnectionString $this.AuthTokens[$Token] | Select-Object -First 1
        if (-not $current) { throw "当前登录账户不存在" }
        $isAdmin = $current.group -eq "系统管理员"
        $rows = if ($isAdmin) { Get-SqlUserRows $this.SqlConnectionString } else { @($current) }
        return [ordered]@{ currentUser = ConvertTo-SqlPublicUser $current; isAdmin = $isAdmin; rows = @($rows | ForEach-Object { ConvertTo-SqlPublicUser $_ }) }
    }

    $repository | Add-Member -MemberType ScriptMethod -Name SaveUser -Force -Value {
        param([string]$Token, $Payload)
        $current = Get-SqlSessionUser $this $Token
        if ($current.group -ne "系统管理员") { throw "仅系统管理员可执行此操作" }
        $id = [int]$Payload.id
        $account = [string]$Payload.account; $name = [string]$Payload.name; $phone = [string]$Payload.phone; $group = [string]$Payload.group; $passwordText = [string]$Payload.password
        if (-not $account -or -not $group) { throw "账户和组归属不能为空" }
        $groupId = Invoke-SqlScalar $this.SqlConnectionString "SELECT id FROM dbo.sys_user_groups WHERE group_name = @group AND is_enabled = 1" @{ "@group" = $group }
        if ($null -eq $groupId) { throw "用户组不存在" }
        if ($id -eq 0) {
            if (-not $passwordText) { throw "新建用户必须填写密码" }
            $password = New-SqlPasswordRecord $passwordText
            try {
                Invoke-SqlNonQuery $this.SqlConnectionString "INSERT dbo.sys_users(account, display_name, phone, password_plain, password_hash, password_salt, password_iterations, group_id) VALUES(@account, @name, @phone, @password, @hash, @salt, @iterations, @groupId)" @{ "@account" = $account; "@name" = $name; "@phone" = $phone; "@password" = $passwordText; "@hash" = $password.hash; "@salt" = $password.salt; "@iterations" = $password.iterations; "@groupId" = [int]$groupId }
            } catch { throw "账户已存在或保存失败" }
        } else {
            $existing = Get-SqlUserById $this.SqlConnectionString $id
            if (-not $existing) { throw "用户不存在" }
            if ($passwordText) {
                $password = New-SqlPasswordRecord $passwordText
                Invoke-SqlNonQuery $this.SqlConnectionString "UPDATE dbo.sys_users SET account=@account, display_name=@name, phone=@phone, group_id=@groupId, password_plain=@password, password_hash=@hash, password_salt=@salt, password_iterations=@iterations, updated_at=SYSDATETIME() WHERE id=@id" @{ "@id" = $id; "@account" = $account; "@name" = $name; "@phone" = $phone; "@groupId" = [int]$groupId; "@password" = $passwordText; "@hash" = $password.hash; "@salt" = $password.salt; "@iterations" = $password.iterations }
            } else {
                Invoke-SqlNonQuery $this.SqlConnectionString "UPDATE dbo.sys_users SET account=@account, display_name=@name, phone=@phone, group_id=@groupId, updated_at=SYSDATETIME() WHERE id=@id" @{ "@id" = $id; "@account" = $account; "@name" = $name; "@phone" = $phone; "@groupId" = [int]$groupId }
            }
        }
        return $this.GetUsers($Token)
    }

    $repository | Add-Member -MemberType ScriptMethod -Name DeleteUser -Force -Value {
        param([string]$Token, [int]$Id)
        $current = Get-SqlSessionUser $this $Token
        if ($current.group -ne "系统管理员") { throw "仅系统管理员可执行此操作" }
        if ([int]$current.id -eq $Id) { throw "不能删除当前登录的管理员账户" }
        Invoke-SqlNonQuery $this.SqlConnectionString "UPDATE dbo.sys_users SET is_enabled=0, updated_at=SYSDATETIME() WHERE id=@id" @{ "@id" = $Id }
        return $this.GetUsers($Token)
    }

    $repository | Add-Member -MemberType ScriptMethod -Name ChangePassword -Force -Value {
        param([string]$Token, $Payload)
        $current = Get-SqlSessionUser $this $Token
        $targetId = if ($Payload.id) { [int]$Payload.id } else { [int]$current.id }
        $target = Get-SqlUserById $this.SqlConnectionString $targetId
        if (-not $target) { throw "用户不存在" }
        if ([int]$target.id -ne [int]$current.id -and $current.group -ne "系统管理员") { throw "只能修改自己的密码" }
        if ([int]$target.id -eq [int]$current.id -and $current.group -ne "系统管理员" -and -not (Test-SqlPassword ([string]$Payload.oldPassword) ([byte[]]$current.password_salt) ([int]$current.password_iterations) ([byte[]]$current.password_hash))) { throw "原密码不正确" }
        if (-not [string]$Payload.newPassword) { throw "新密码不能为空" }
        $password = New-SqlPasswordRecord ([string]$Payload.newPassword)
        Invoke-SqlNonQuery $this.SqlConnectionString "UPDATE dbo.sys_users SET password_plain=@password, password_hash=@hash, password_salt=@salt, password_iterations=@iterations, updated_at=SYSDATETIME() WHERE id=@id" @{ "@id" = $targetId; "@password" = [string]$Payload.newPassword; "@hash" = $password.hash; "@salt" = $password.salt; "@iterations" = $password.iterations }
        return [ordered]@{ changed = $true }
    }

    $repository | Add-Member -MemberType ScriptMethod -Name GetUserGroups -Force -Value {
        $rows = Invoke-SqlRows $this.SqlConnectionString "SELECT group_name AS [group] FROM dbo.sys_user_groups WHERE is_enabled = 1 ORDER BY id"
        return [ordered]@{ rows = $rows }
    }

    $repository | Add-Member -MemberType ScriptMethod -Name Authorize -Force -Value {
        param([string]$Token, [string]$Module, [string]$Action)
        return Assert-SqlPermission $this $Token $Module $Action
    }

    $repository | Add-Member -MemberType ScriptMethod -Name Audit -Force -Value {
        param([string]$Token, [string]$Action, [string]$EntityType, [string]$EntityId, [string]$Detail)
        $user = Get-SqlSessionUser $this $Token
        Write-SqlAudit $this.SqlConnectionString $user $Action $EntityType $EntityId $Detail
    }

    $repository | Add-Member -MemberType ScriptMethod -Name RunCost -Force -Value {
        param($Request)
        $line = if ($Request.line) { [string]$Request.line } else { "lj" }
        if ($line -ne "lj") { throw "当前 SQL 实际核算已接入炉卷（lj）；1780 与炼钢将在对应实绩口径确认后接入" }
        return Run-SqlLJCost $this.SqlConnectionString $Request
    }

    $repository | Add-Member -MemberType ScriptMethod -Name GetCostDetail -Force -Value {
        param([string]$DetailKey)
        if ($DetailKey -notmatch '^sql-cost-(\d+)$') { return [ordered]@{ rows = @() } }
        $resultId = [int]$Matches[1]
        $rows = Invoke-SqlRows $this.SqlConnectionString "SELECT item_name AS item, amount, ISNULL(note, N'') AS note FROM dbo.cost_calculation_details WHERE result_id=@id ORDER BY id" @{ "@id" = $resultId }
        return [ordered]@{ rows = $rows }
    }

    return $repository
}
