. (Join-Path (Split-Path -Parent $PSScriptRoot) "seed-data.ps1")

function Mock-ToPlain {
    param([Parameter(Mandatory = $true)]$Value)

    if ($null -eq $Value) { return $null }
    if ($Value -is [string] -or $Value -is [int] -or $Value -is [double] -or $Value -is [decimal] -or $Value -is [bool]) {
        return $Value
    }
    if ($Value -is [System.Collections.IDictionary]) {
        $result = [ordered]@{}
        foreach ($key in $Value.Keys) {
            $result[$key] = Mock-ToPlain $Value[$key]
        }
        return $result
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        $items = @()
        foreach ($item in $Value) {
            $items += ,(Mock-ToPlain $item)
        }
        return $items
    }
    $result = [ordered]@{}
    foreach ($prop in $Value.PSObject.Properties) {
        $result[$prop.Name] = Mock-ToPlain $prop.Value
    }
    return $result
}

function Mock-GetDatasetRows {
    param(
        [Parameter(Mandatory = $true)]$Repository,
        [Parameter(Mandatory = $true)][string]$Name
    )
    if (-not $Repository.State.datasets.Contains($Name)) {
        throw "Dataset not found: $Name"
    }
    return @($Repository.State.datasets[$Name])
}

function Mock-SetDatasetRows {
    param(
        [Parameter(Mandatory = $true)]$Repository,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)]$Rows
    )
    $Repository.State.datasets[$Name] = @($Rows)
}

function Mock-NextId {
    param([Parameter(Mandatory = $true)]$Rows)

    if (-not $Rows -or $Rows.Count -eq 0) { return 1 }
    $maxId = 0
    foreach ($row in $Rows) {
        $current = [int]$row.id
        if ($current -gt $maxId) {
            $maxId = $current
        }
    }
    return ($maxId + 1)
}

function Mock-GetDatasetMeta {
    param(
        [Parameter(Mandatory = $true)]$Repository,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $config = $Repository.State.datasetConfig[$Name]
    $rows = Mock-GetDatasetRows -Repository $Repository -Name $Name
    $columns = @()
    if ($rows.Count -gt 0) {
        $columns = @($rows[0].Keys)
    }
    return [ordered]@{
        title = $config.title
        description = $config.description
        readonly = [bool]$config.readonly
        collectable = [bool]$config.collectable
        count = $rows.Count
        columns = $columns
    }
}

function Mock-SaveRow {
    param(
        [Parameter(Mandatory = $true)]$Repository,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)]$Payload
    )

    $config = $Repository.State.datasetConfig[$Name]
    if ($config.readonly) {
        throw "Dataset is readonly: $Name"
    }

    $rows = Mock-GetDatasetRows -Repository $Repository -Name $Name
    $row = Mock-ToPlain $Payload
    if (-not $row.id -or [int]$row.id -eq 0) {
        $row.id = Mock-NextId $rows
    }

    $updated = @()
    $found = $false
    foreach ($item in $rows) {
        if ([int]$item.id -eq [int]$row.id) {
            $updated += ,$row
            $found = $true
        } else {
            $updated += ,$item
        }
    }
    if (-not $found) {
        $updated += ,$row
    }

    Mock-SetDatasetRows -Repository $Repository -Name $Name -Rows $updated
    return $row
}

function Mock-DeleteRow {
    param(
        [Parameter(Mandatory = $true)]$Repository,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][int]$Id
    )

    $config = $Repository.State.datasetConfig[$Name]
    if ($config.readonly) {
        throw "Dataset is readonly: $Name"
    }

    $rows = Mock-GetDatasetRows -Repository $Repository -Name $Name
    Mock-SetDatasetRows -Repository $Repository -Name $Name -Rows ($rows | Where-Object { [int]$_.id -ne $Id })
}

function Mock-CollectRow {
    param(
        [Parameter(Mandatory = $true)]$Repository,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $config = $Repository.State.datasetConfig[$Name]
    if (-not $config.collectable) {
        throw "Collect is not supported for dataset: $Name"
    }

    $rows = Mock-GetDatasetRows -Repository $Repository -Name $Name
    $id = Mock-NextId $rows
    $now = Get-Date

    switch ($Name) {
        "ljActuals" {
            $sample = [ordered]@{
                id = $id
                prodTime = $now.ToString("yyyy-MM-dd HH:mm:ss")
                prodShiftNo = "A"
                prodShiftGroup = "A"
                grade = "Q235B"
                thickIndex = 1
                widthIndex = 2
                slabWtComd = 24.6
                matTheoryWt = 23.7
                matNetWt = 23.4
                inFurnaceTime = 137
                inRollTime = 43
                chengcailv = 0.9512
            }
        }
        "rzActuals" {
            $sample = [ordered]@{
                id = $id
                prodTime = $now.ToString("yyyy-MM-dd HH:mm:ss")
                prodShiftNo = "D"
                prodShiftGroup = "A"
                grade = "SPHC"
                thickIndex = 1
                widthIndex = 2
                slabWtComd = 26.4
                matActWt = 25.0
                matNetWt = 24.8
                inFurnaceTime = 123
                ftRollTime = 39
                rollPractDiv = 0
                chengcailv = 0.9495
            }
        }
        "steelmakingActuals" {
            $sample = [ordered]@{
                id = $id
                collectTime = $now.ToString("yyyy-MM-dd HH:mm:ss")
                heatNo = "SM" + $now.ToString("yyMMddHH")
                grade = "Q235B"
                routeIndex = "LF-1"
                steelWt = 146.8
                steelmakingMinutes = 43
                refiningMinutes = 29
                castingMinutes = 37
                status = "正常"
            }
        }
        default {
            throw "Collect not implemented: $Name"
        }
    }

    Mock-SetDatasetRows -Repository $Repository -Name $Name -Rows (@($sample) + $rows)
    return $sample
}

function Mock-WeightedAverage {
    param(
        [Parameter(Mandatory = $true)]$Rows,
        [Parameter(Mandatory = $true)][string]$Field,
        [Parameter(Mandatory = $true)][string]$WeightField
    )

    $totalWeight = 0.0
    $weighted = 0.0
    foreach ($row in $Rows) {
        $weight = [double]$row.$WeightField
        $value = [double]$row.$Field
        $totalWeight += $weight
        $weighted += ($value * $weight)
    }
    if ($totalWeight -eq 0) { return 0 }
    return [math]::Round(($weighted / $totalWeight), 2)
}

function Mock-BuildDetailRows {
    param([Parameter(Mandatory = $true)]$Rows)

    $avgSteelmaking = Mock-WeightedAverage -Rows $Rows -Field "steelmakingCost" -WeightField "coilWt"
    $avgProcess = Mock-WeightedAverage -Rows $Rows -Field "processCost" -WeightField "coilWt"
    $avgHeating = Mock-WeightedAverage -Rows $Rows -Field "heatingCost" -WeightField "coilWt"
    $avgRolling = Mock-WeightedAverage -Rows $Rows -Field "rollingCost" -WeightField "coilWt"
    $avgRoll = Mock-WeightedAverage -Rows $Rows -Field "rollCost" -WeightField "coilWt"
    $avgPackage = Mock-WeightedAverage -Rows $Rows -Field "packageCost" -WeightField "coilWt"
    $avgSample = Mock-WeightedAverage -Rows $Rows -Field "sampleCost" -WeightField "coilWt"
    $avgOther = Mock-WeightedAverage -Rows $Rows -Field "otherCost" -WeightField "coilWt"
    $avgRecycle = Mock-WeightedAverage -Rows $Rows -Field "recycleCredit" -WeightField "coilWt"

    return @(
        @{ item = "Steelmaking"; amount = $avgSteelmaking; note = "Billet plan price plus market and process premium" }
        @{ item = "Heating"; amount = $avgHeating; note = "Share from furnace step time" }
        @{ item = "Rolling"; amount = $avgRolling; note = "Share from mill step time" }
        @{ item = "Roll"; amount = $avgRoll; note = "Length and stress factor share" }
        @{ item = "Package"; amount = $avgPackage; note = "Packing process cost" }
        @{ item = "Sample"; amount = $avgSample; note = "Sample processing charge" }
        @{ item = "Other"; amount = $avgOther; note = "Other average allocated items" }
        @{ item = "Recycle Credit"; amount = $avgRecycle; note = "Credit from recycle and by-product recovery" }
        @{ item = "Process Total"; amount = $avgProcess; note = "Heating, rolling, roll, package and sample total" }
    )
}

function Mock-BuildCostSummaryRow {
    param(
        [Parameter(Mandatory = $true)]$Rows,
        [Parameter(Mandatory = $true)][string]$Line,
        [Parameter(Mandatory = $true)][string]$Dimension,
        [Parameter(Mandatory = $true)][string]$Label,
        $DetailKey,
        [bool]$IncludeSpec = $false
    )

    $slabWt = 0.0
    $coilWt = 0.0
    foreach ($row in $Rows) {
        $slabWt += [double]$row.slabWt
        $coilWt += [double]$row.coilWt
    }

    $name = switch ($Dimension) {
        "bySpec" { "$($Rows[0].grade) / $($Rows[0].thickness)mm / $($Rows[0].width)mm" }
        "byGrade" { $Rows[0].grade }
        "bySeries" { $Rows[0].xilie }
        "byPinzhong" { $Rows[0].pinzhong }
        default { $Label }
    }

    return [ordered]@{
        id = if ($null -eq $DetailKey) { [string]$Label } else { [string]$DetailKey }
        line = $Line
        name = $name
        grade = if ($Dimension -eq "bySeries" -or $Dimension -eq "byPinzhong") { "-" } else { $Rows[0].grade }
        pinzhong = $Rows[0].pinzhong
        xilie = $Rows[0].xilie
        thickness = if ($IncludeSpec) { $Rows[0].thickness } else { "-" }
        width = if ($IncludeSpec) { $Rows[0].width } else { "-" }
        slabWt = [math]::Round($slabWt, 2)
        coilWt = [math]::Round($coilWt, 2)
        yieldRate = if ($slabWt -eq 0) { 0 } else { [math]::Round(($coilWt / $slabWt), 4) }
        steelmakingCost = Mock-WeightedAverage -Rows $Rows -Field "steelmakingCost" -WeightField "coilWt"
        processCost = Mock-WeightedAverage -Rows $Rows -Field "processCost" -WeightField "coilWt"
        manufacturingCost = Mock-WeightedAverage -Rows $Rows -Field "manufacturingCost" -WeightField "coilWt"
        salePrice = Mock-WeightedAverage -Rows $Rows -Field "salePrice" -WeightField "coilWt"
        profitPerTon = [math]::Round(
            (Mock-WeightedAverage -Rows $Rows -Field "salePrice" -WeightField "coilWt") -
            (Mock-WeightedAverage -Rows $Rows -Field "manufacturingCost" -WeightField "coilWt"),
            2
        )
        detailKey = $DetailKey
    }
}

function Mock-RunCost {
    param(
        [Parameter(Mandatory = $true)]$Repository,
        [Parameter(Mandatory = $true)]$Request
    )

    $line = if ($Request.line) { [string]$Request.line } else { "lj" }
    $dimension = if ($Request.dimension) { [string]$Request.dimension } else { "bySpec" }
    $rows = @($Repository.State.costBaseRows | Where-Object { $_.line -eq $line })
    $Repository.State.runtime.generatedCostDetails = @{}

    $groups = @()
    switch ($dimension) {
        "bySpec" {
            foreach ($row in $rows) {
                $groups += ,@($row)
            }
        }
        "byGrade" {
            foreach ($group in ($rows | Group-Object grade)) {
                $groups += ,@($group.Group)
            }
        }
        "bySeries" {
            foreach ($group in ($rows | Group-Object xilie)) {
                $groups += ,@($group.Group)
            }
        }
        "byPinzhong" {
            foreach ($group in ($rows | Group-Object pinzhong)) {
                $groups += ,@($group.Group)
            }
        }
        default {
            throw "Unsupported cost dimension: $dimension"
        }
    }

    $resultRows = @()
    $index = 1
    foreach ($group in $groups) {
        $detailKey = "cost-$line-$dimension-$index"
        $resultRows += ,(Mock-BuildCostSummaryRow -Rows $group -Line $line -Dimension $dimension -Label $detailKey -DetailKey $detailKey -IncludeSpec ($dimension -eq "bySpec"))
        $Repository.State.runtime.generatedCostDetails[$detailKey] = Mock-BuildDetailRows -Rows $group
        $index += 1
    }

    $totalRow = Mock-BuildCostSummaryRow -Rows $rows -Line $line -Dimension "byGrade" -Label "total" -DetailKey $null -IncludeSpec $false
    $totalRow.name = "Total"
    $totalRow.grade = "-"
    $resultRows += ,$totalRow

    return [ordered]@{
        line = $line
        dimension = $dimension
        rows = $resultRows
    }
}

function Mock-RunStandardCost {
    param(
        [Parameter(Mandatory = $true)]$Repository,
        [Parameter(Mandatory = $true)]$Request
    )

    $line = if ($Request.line) { [string]$Request.line } else { "rz" }
    $conditions = @($Repository.State.datasets.standardConditions | Where-Object { $_.line -eq $line })
    $totalThreshold = [double](($conditions | Where-Object { $_.conditionType -eq "total_output" } | Select-Object -First 1).value)
    $singleThreshold = [double](($conditions | Where-Object { $_.conditionType -eq "min_grade_output" } | Select-Object -First 1).value)

    $historyRows = @($Repository.State.standardHistory | Where-Object { $_.line -eq $line })
    $periodTotals = @{}
    foreach ($row in $historyRows) {
        if (-not $periodTotals.ContainsKey($row.period)) {
            $periodTotals[$row.period] = 0.0
        }
        $periodTotals[$row.period] += [double]$row.coilWt
    }

    $filtered = @($historyRows | Where-Object {
        [double]$_.coilWt -ge $singleThreshold -and $periodTotals[$_.period] -ge $totalThreshold
    })

    $averageRows = @()
    $standardRows = @()
    foreach ($group in ($filtered | Group-Object grade)) {
        $rows = @($group.Group)
        $slabWt = 0.0
        $coilWt = 0.0
        foreach ($row in $rows) {
            $slabWt += [double]$row.slabWt
            $coilWt += [double]$row.coilWt
        }

        $averageRows += ,([ordered]@{
            grade = $rows[0].grade
            pinzhong = $rows[0].pinzhong
            xilie = $rows[0].xilie
            sampleCount = $rows.Count
            sourcePeriods = ($rows.period | Sort-Object -Unique) -join ", "
            coilWt = [math]::Round($coilWt, 2)
            yieldRate = if ($slabWt -eq 0) { 0 } else { [math]::Round(($coilWt / $slabWt), 4) }
            processCost = Mock-WeightedAverage -Rows $rows -Field "processCost" -WeightField "coilWt"
            manufacturingCost = Mock-WeightedAverage -Rows $rows -Field "manufacturingCost" -WeightField "coilWt"
            sampleCost = Mock-WeightedAverage -Rows $rows -Field "sampleCost" -WeightField "coilWt"
            packageCost = Mock-WeightedAverage -Rows $rows -Field "packageCost" -WeightField "coilWt"
        })

        $best = $rows | Sort-Object manufacturingCost | Select-Object -First 1
        $standardRows += ,([ordered]@{
            grade = $best.grade
            pinzhong = $best.pinzhong
            xilie = $best.xilie
            selectedPeriod = $best.period
            coilWt = $best.coilWt
            yieldRate = $best.yieldRate
            processCost = $best.processCost
            manufacturingCost = $best.manufacturingCost
            sampleCost = $best.sampleCost
            packageCost = $best.packageCost
            recycleCredit = $best.recycleCredit
        })
    }

    return [ordered]@{
        line = $line
        totalThreshold = $totalThreshold
        singleThreshold = $singleThreshold
        selectedPeriods = @($filtered.period | Sort-Object -Unique)
        averageRows = $averageRows
        standardRows = $standardRows
    }
}

function Mock-RunSchedule {
    param(
        [Parameter(Mandatory = $true)]$Repository,
        [Parameter(Mandatory = $true)]$Request
    )

    $line = if ($Request.line) { [string]$Request.line } else { "lj" }
    $startDate = if ($Request.startDate) { [datetime]$Request.startDate } else { [datetime]"2026-07-15 08:00:00" }
    $paramsDataset = if ($line -eq "lj") { "ljScheduleParams" } else { "rzScheduleParams" }
    $planKey = if ($line -eq "lj") { "lj" } else { "rz" }

    $params = @{}
    foreach ($row in $Repository.State.datasets[$paramsDataset]) {
        $params[$row.stepCode] = [double]$row.minutes
    }

    $plans = @($Repository.State.schedulePlans[$planKey])
    $cursor = $startDate
    $rows = @()
    foreach ($plan in $plans) {
        $funcStart = $cursor
        $funcEnd = $funcStart.AddMinutes($params.furnace)
        $millStart = $funcEnd.AddMinutes($params.gapFuncMill)
        $millEnd = $millStart.AddMinutes($params.rolling)
        $coldStart = $millEnd.AddMinutes($params.gapMillCold)
        $coldEnd = $coldStart.AddMinutes($params.cold)
        $finishStart = $coldEnd
        $finishEnd = $finishStart.AddMinutes($params.finish)

        $rows += ,([ordered]@{
            slabNo = $plan.slabNo
            grade = $plan.grade
            thickness = $plan.thickness
            width = $plan.width
            funcStart = $funcStart.ToString("yyyy-MM-dd HH:mm")
            funcEnd = $funcEnd.ToString("yyyy-MM-dd HH:mm")
            millStart = $millStart.ToString("yyyy-MM-dd HH:mm")
            millEnd = $millEnd.ToString("yyyy-MM-dd HH:mm")
            coldEnd = $coldEnd.ToString("yyyy-MM-dd HH:mm")
            finishEnd = $finishEnd.ToString("yyyy-MM-dd HH:mm")
        })

        $cursor = $cursor.AddMinutes($params.chargeGap)
    }

    $bottleneck = $Repository.State.datasets[$paramsDataset] | Sort-Object minutes -Descending | Select-Object -First 1
    return [ordered]@{
        line = $line
        startDate = $startDate.ToString("yyyy-MM-dd HH:mm")
        notes = @(
            "Current schedule output is mock data and mirrors the sequence simulation in the original desktop module.",
            "Current bottleneck step: $($bottleneck.stepName) ($($bottleneck.minutes) min)"
        )
        rows = $rows
    }
}

function New-MockRepository {
    $repository = [pscustomobject]@{
        ProviderName = "mock"
        State = Get-SeedData
    }

    $repository | Add-Member -MemberType ScriptMethod -Name GetBootstrap -Value {
        $datasets = [ordered]@{}
        foreach ($name in $this.State.datasets.Keys) {
            $datasets[$name] = Mock-GetDatasetMeta -Repository $this -Name $name
        }
        return [ordered]@{
            system = $this.State.system
            notices = $this.State.notices
            modules = $this.State.modules
            datasets = $datasets
        }
    }

    $repository | Add-Member -MemberType ScriptMethod -Name GetDataset -Value {
        param([string]$Name)
        return [ordered]@{
            name = $Name
            rows = Mock-GetDatasetRows -Repository $this -Name $Name
            meta = Mock-GetDatasetMeta -Repository $this -Name $Name
        }
    }

    $repository | Add-Member -MemberType ScriptMethod -Name SaveDatasetRow -Value {
        param([string]$Name, $Payload)
        $row = Mock-SaveRow -Repository $this -Name $Name -Payload $Payload
        return [ordered]@{
            saved = $row
            rows = Mock-GetDatasetRows -Repository $this -Name $Name
            meta = Mock-GetDatasetMeta -Repository $this -Name $Name
        }
    }

    $repository | Add-Member -MemberType ScriptMethod -Name DeleteDatasetRow -Value {
        param([string]$Name, [int]$Id)
        Mock-DeleteRow -Repository $this -Name $Name -Id $Id
        return [ordered]@{
            rows = Mock-GetDatasetRows -Repository $this -Name $Name
            meta = Mock-GetDatasetMeta -Repository $this -Name $Name
        }
    }

    $repository | Add-Member -MemberType ScriptMethod -Name CollectDataset -Value {
        param([string]$Name)
        $row = Mock-CollectRow -Repository $this -Name $Name
        return [ordered]@{
            collected = $row
            rows = Mock-GetDatasetRows -Repository $this -Name $Name
            meta = Mock-GetDatasetMeta -Repository $this -Name $Name
        }
    }

    $repository | Add-Member -MemberType ScriptMethod -Name RunCost -Value {
        param($Request)
        return Mock-RunCost -Repository $this -Request $Request
    }

    $repository | Add-Member -MemberType ScriptMethod -Name GetCostDetail -Value {
        param([string]$DetailKey)
        if ($this.State.runtime.generatedCostDetails.ContainsKey($DetailKey)) {
            return [ordered]@{ rows = @($this.State.runtime.generatedCostDetails[$DetailKey]) }
        }
        return [ordered]@{ rows = @() }
    }

    $repository | Add-Member -MemberType ScriptMethod -Name RunStandardCost -Value {
        param($Request)
        return Mock-RunStandardCost -Repository $this -Request $Request
    }

    $repository | Add-Member -MemberType ScriptMethod -Name RunSchedule -Value {
        param($Request)
        return Mock-RunSchedule -Repository $this -Request $Request
    }

    return $repository
}
