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
                for ($i = 0; $i -lt $reader.FieldCount; $i += 1) { $row[$reader.GetName($i)] = if ($reader.IsDBNull($i)) { "" } else { $reader.GetValue($i) } }
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
        default { return $null }
    }
}

function Get-SqlAdditionalBasicDataset {
    param([string]$ConnectionString, [string]$Name)
    $definition = Get-SqlAdditionalBasicDatasetDefinition $Name
    if (-not $definition) { throw "Unsupported basic dataset: $Name" }
    $columnsSql = ($definition.columns | ForEach-Object { "[$_]" }) -join ", "
    $rows = Invoke-SqlRows $ConnectionString "SELECT id, $columnsSql FROM dbo.$($definition.table) ORDER BY id"
    return [ordered]@{
        name = $Name
        rows = $rows
        meta = [ordered]@{ title = $definition.title; description = $definition.description; tableName = $definition.table; readonly = $false; collectable = $false; count = $rows.Count; columns = @("id") + @($definition.columns) }
    }
}

function ConvertTo-SqlPublicUser {
    param($Row)
    return [ordered]@{ id = [int]$Row.id; account = [string]$Row.account; name = [string]$Row.name; phone = [string]$Row.phone; displayName = if ($Row.name) { [string]$Row.name } else { [string]$Row.account }; password = [string]$Row.password_plain; group = [string]$Row.group }
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
            $id = [int]$Payload.id; $columns = @($definition.columns); $parameters = @{}
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

    return $repository
}
