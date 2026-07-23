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
        foreach ($name in $this.State.datasets.Keys) { $datasets[$name] = Mock-GetDatasetMeta -Repository $this -Name $name }
        $this.State.system.currentProvider = "sqlserver"
        return [ordered]@{ system = $this.State.system; notices = $this.State.notices; modules = $this.State.modules; datasets = $datasets }
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
