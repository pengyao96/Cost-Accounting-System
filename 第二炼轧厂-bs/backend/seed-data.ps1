function Get-SeedData {
    $datasetConfig = [ordered]@{
        heatTreatmentRequirements = @{ title = "热处理要求"; description = "热处理代码与要求说明"; tableName = "yclyq"; readonly = $false; collectable = $false }
        slabGrades = @{ title = "板坯钢种"; description = "板坯钢种、系列与品种"; tableName = "lggrade"; readonly = $false; collectable = $false }
        plateGrades = @{ title = "钢板钢种"; description = "钢板钢种、品种与系列"; tableName = "ljgrade"; readonly = $false; collectable = $false }
        coilGrades = @{ title = "钢卷钢种"; description = "钢卷钢种、品种与系列"; tableName = "rzgrade"; readonly = $false; collectable = $false }
        slabThicknessIndexes = @{ title = "板坯厚度索引"; description = "板坯厚度索引，当前按设计保持空表"; tableName = "lgthick"; readonly = $false; collectable = $false }
        plateThicknessIndexes = @{ title = "钢板厚度索引"; description = "钢板厚度索引"; tableName = "ljthick"; readonly = $false; collectable = $false }
        coilThicknessIndexes = @{ title = "钢卷厚度索引"; description = "钢卷厚度索引"; tableName = "thick"; readonly = $false; collectable = $false }
        slabWidthIndexes = @{ title = "板坯宽度索引"; description = "板坯宽度索引，当前按设计保持空表"; tableName = "lgwidth"; readonly = $false; collectable = $false }
        plateWidthIndexes = @{ title = "钢板宽度索引"; description = "钢板宽度索引"; tableName = "ljwidth"; readonly = $false; collectable = $false }
        coilWidthIndexes = @{ title = "钢卷宽度索引"; description = "钢卷宽度索引"; tableName = "width"; readonly = $false; collectable = $false }
        slabLengthIndexes = @{ title = "板坯长度索引"; description = "板坯长度索引"; tableName = "lgslablen"; readonly = $false; collectable = $false }
        plateLengthIndexes = @{ title = "钢板长度索引"; description = "钢板长度索引"; tableName = "ljpatlen"; readonly = $false; collectable = $false }
        steelmakingPaths = @{ title = "工艺路径"; description = "炼钢工艺路径"; tableName = "lgpath"; readonly = $false; collectable = $false }
        wageEquipmentCoefficients = @{ title = "工资设备系数"; description = "区域工资与设备系数"; tableName = "lggongzishebeixishu"; readonly = $false; collectable = $false }
        steelmakingConsumptionTypes = @{ title = "炼钢消耗类型"; description = "炼钢及连铸消耗类型"; tableName = "lgxhlx"; readonly = $false; collectable = $false }
        rollingConsumptionTypes = @{ title = "轧钢消耗类型"; description = "轧钢消耗类型"; tableName = "xhlx"; readonly = $false; collectable = $false }
        rollingConsumableProducts = @{ title = "1780 耗材产品"; description = "1780 生产线耗材产品及分摊配置"; tableName = "hccp"; readonly = $false; collectable = $false }
        steelmakingConsumableProducts = @{ title = "炼钢耗材产品"; description = "炼钢耗材产品分类"; tableName = "lghccp"; readonly = $false; collectable = $false }
        coilConsumableProducts = @{ title = "炉卷耗材产品"; description = "炉卷生产线耗材产品及分摊配置"; tableName = "ljhccp"; readonly = $false; collectable = $false }
        steelmakingGrades = @{ title = "炼钢钢种基础数据"; description = "炼钢钢种与系列；为1780和炉卷提供炼钢水平附加的关联基础"; readonly = $false; collectable = $false }
        steelmakingRoutes = @{ title = "炼钢路径表"; description = "钢种对应的精炼路径与连铸号"; readonly = $false; collectable = $false }
        steelmakingPrices = @{ title = "炼钢计划价与水平附加"; description = "铁水、合金料计划价及炼钢降本增效形成的板坯水平附加"; readonly = $false; collectable = $false }
        steelmakingActuals = @{ title = "炼钢工序实绩"; description = "转炉、精炼、连铸、天车物流、脱硫等三级实绩；每8小时采集"; readonly = $false; collectable = $true }
        steelmakingFixedConsumption = @{ title = "炼钢固定消耗实绩"; description = "未接能源计量系统时按周录入，接入后每日更新"; readonly = $false; collectable = $false }
        shareRules = @{ title = "Share Rules"; description = "Heating, rolling and roll-cost share rules"; readonly = $false; collectable = $false }
        planPriceLj = @{ title = "LJ Plan Price"; description = "Plan price dataset for LJ line"; readonly = $false; collectable = $false }
        planPriceRz = @{ title = "RZ Plan Price"; description = "Plan price dataset for RZ line"; readonly = $false; collectable = $false }
        samplePriceLj = @{ title = "LJ Sample Price"; description = "Sample charge dataset for LJ line"; readonly = $false; collectable = $false }
        samplePriceRz = @{ title = "RZ Sample Price"; description = "Sample charge dataset for RZ line"; readonly = $false; collectable = $false }
        energyRates = @{ title = "Energy Rates"; description = "Water, power, gas and steam rates"; readonly = $false; collectable = $false }
        otherConsumptions = @{ title = "Other Consumptions"; description = "PR supplementary consumption entries"; readonly = $false; collectable = $false }
        recycleEntries = @{ title = "Recycle Entries"; description = "Recycle and by-product credits"; readonly = $false; collectable = $false }
        ljActuals = @{ title = "LJ Actuals"; description = "Actual production rows for LJ line"; readonly = $false; collectable = $true }
        rzActuals = @{ title = "RZ Actuals"; description = "Actual production rows for RZ line"; readonly = $false; collectable = $true }
        standardConditions = @{ title = "Standard Cost Conditions"; description = "SC filtering conditions"; readonly = $false; collectable = $false }
        ljScheduleParams = @{ title = "LJ Schedule Params"; description = "Step duration settings for LJ schedule"; readonly = $false; collectable = $false }
        rzScheduleParams = @{ title = "RZ Schedule Params"; description = "Step duration settings for RZ schedule"; readonly = $false; collectable = $false }
    }

    return [ordered]@{
        system = [ordered]@{
            name = "第二炼轧厂精量化成本核算系统"
            sourceEntry = "ZXCBXT/ZXCBXT.sln"
            currentProvider = "mock"
            nextProvider = "sqlserver"
        }
        notices = @(
            "系统由1780、炉卷、炼钢三个成本核算子系统组成；炼钢水平附加向两条轧线提供板坯成本修正。",
            "三级生产实绩按8小时采集；固定消耗在未接入能源计量系统前支持人工维护。",
            "本版为Mock数据实现，SQL Server仓储可在不改页面的情况下替换。"
        )
        modules = @(
            @{ code = "1780"; title = "1780精量化成本"; source = "基础数据 / 实绩 / 成本计算"; summary = "按钢种、厚度、宽度组距汇总，核算原料、变动加工费和固定费用" }
            @{ code = "炉卷"; title = "炉卷精量化成本"; source = "基础数据 / 实绩 / 成本计算"; summary = "增加轧制方式、切割类型与精整时间，按钢种组距建立成本表" }
            @{ code = "炼钢"; title = "炼钢精量化成本"; source = "基础数据 / 实时成本"; summary = "按钢种路径核算钢水、合金、辅材、炼钢与连铸工序成本，并提供水平附加" }
            @{ code = "标准成本"; title = "标准成本"; source = "SC"; summary = "按产量门槛筛选并提炼平均标准成本与标准成本" }
        )
        userGroups = @("系统管理员", "财务科", "安全科", "技术科")
        systemUsers = @(
            @{ id = 1; account = "admin"; displayName = "系统管理员"; name = "系统管理员"; phone = ""; password = "123456"; group = "系统管理员" }
            @{ id = 2; account = "yaopeng"; displayName = "姚鹏"; name = "姚鹏"; phone = ""; password = "123456"; group = "技术科" }
            @{ id = 3; account = "guoxiaoming"; displayName = "郭晓明"; name = "郭晓明"; phone = ""; password = "123456"; group = "安全科" }
            @{ id = 4; account = "songmengxiao"; displayName = "宋梦晓"; name = "宋梦晓"; phone = ""; password = "123456"; group = "财务科" }
        )
        authTokens = @{}
        datasetConfig = $datasetConfig
        datasets = [ordered]@{
            heatTreatmentRequirements = @(
                @{ id = 1; rclyq = "N"; rclms = "要求热处理" }
                @{ id = 2; rclyq = "X"; rclms = "不要求热处理" }
            )
            slabGrades = @(
                @{ id = 1; 钢种 = "Q235B"; 品种 = ""; 系列 = "普碳" }
            )
            plateGrades = @(
                @{ id = 1; 钢种 = "Q390B"; 品种 = "Q390板"; 系列 = "低合金板" }
            )
            coilGrades = @(
                @{ id = 1; 钢种 = "SPHC"; 品种 = "SPHC、SPHT卷"; 系列 = "冷轧基料" }
            )
            slabThicknessIndexes = @()
            plateThicknessIndexes = @(
                @{ id = 1; 厚度索引 = "1"; 厚度起 = 4.74; 厚度尾 = 6.01; 厚度范围 = "(4.74,6.01]" }
            )
            coilThicknessIndexes = @(
                @{ id = 1; 厚度索引 = "1"; 厚度起 = 1.2; 厚度尾 = 1.6; 厚度范围 = "(1.2,1.6]" }
            )
            slabWidthIndexes = @()
            plateWidthIndexes = @(
                @{ id = 1; 宽度索引 = "1"; 起始 = 800; 结束 = 2000 }
            )
            coilWidthIndexes = @(
                @{ id = 1; 宽度索引 = "1"; 起始 = 800; 结束 = 1000 }
            )
            slabLengthIndexes = @(
                @{ id = 1; 序号 = 1; 长度起始 = 4800; 长度终止 = 5100 }
            )
            plateLengthIndexes = @(
                @{ id = 1; 序号 = 1; 长度起始 = 4700; 长度终止 = 9999 }
            )
            steelmakingPaths = @(
                @{ id = 1; path_idx = 1; zlpath = "A"; jlpath = "J"; lzpath = "1" }
            )
            wageEquipmentCoefficients = @(
                @{ id = 1; 区域 = "转炉与LF"; 工资系数 = 12.4; 设备系数 = 9.8 }
            )
            steelmakingConsumptionTypes = @(
                @{ id = 1; hno = 1; bno = 3; cp = "中高碳锰铁"; dj = "100"; 分摊类型 = "辊耗分摊"; 区域 = "炼钢"; 列名 = "" }
            )
            rollingConsumptionTypes = @(
                @{ id = 1; 序号 = 1; 消耗类型 = "钢坯" }
            )
            rollingConsumableProducts = @(
                @{ id = 1; hno = 1; bno = 3; cp = "轧辊"; 日核算类型 = "上月"; 分摊类型 = "辊耗分摊"; 列名 = "" }
            )
            steelmakingConsumableProducts = @(
                @{ id = 1; bno = 1; 消耗 = "钢铁料" }
            )
            coilConsumableProducts = @(
                @{ id = 1; hno = 1; bno = 3; cp = "轧辊"; 日核算类型 = "上月"; 分摊类型 = "辊耗分摊"; 列名 = "" }
            )
            steelmakingGrades = @(
                @{ id = 1; gradeName = "Q235B"; xilie = "低碳系列"; note = "炼钢小标" }
                @{ id = 2; gradeName = "Q345B"; xilie = "结构钢系列"; note = "炼钢小标" }
                @{ id = 3; gradeName = "SPHC"; xilie = "商品卷系列"; note = "炼钢小标" }
            )
            steelmakingRoutes = @(
                @{ id = 1; routeIndex = "LF-1"; grade = "Q235B"; refiningRoute = "转炉-LF"; casterNo = "1#连铸" }
                @{ id = 2; routeIndex = "RH-1"; grade = "Q345B"; refiningRoute = "转炉-LF-RH"; casterNo = "2#连铸" }
                @{ id = 3; routeIndex = "VD-1"; grade = "SPHC"; refiningRoute = "转炉-VD"; casterNo = "1#连铸" }
            )
            steelmakingPrices = @(
                @{ id = 1; grade = "Q235B"; pigIronPlanPrice = 2150; alloyPrice = 6500; levelPremium = 58; effectiveDate = "2026-07-01"; note = "炼钢水平附加，供炉卷成本使用" }
                @{ id = 2; grade = "Q345B"; pigIronPlanPrice = 2150; alloyPrice = 7900; levelPremium = 86; effectiveDate = "2026-07-01"; note = "炼钢水平附加，供炉卷成本使用" }
                @{ id = 3; grade = "SPHC"; pigIronPlanPrice = 2150; alloyPrice = 6500; levelPremium = 74; effectiveDate = "2026-07-01"; note = "炼钢水平附加，供1780成本使用" }
            )
            steelmakingActuals = @(
                @{ id = 1; collectTime = "2026-07-02 08:00:00"; heatNo = "26070201"; grade = "Q235B"; routeIndex = "LF-1"; steelWt = 148.6; steelmakingMinutes = 42; refiningMinutes = 28; castingMinutes = 36; status = "正常" }
                @{ id = 2; collectTime = "2026-07-02 16:00:00"; heatNo = "26070202"; grade = "Q345B"; routeIndex = "RH-1"; steelWt = 145.2; steelmakingMinutes = 45; refiningMinutes = 45; castingMinutes = 38; status = "正常" }
            )
            steelmakingFixedConsumption = @(
                @{ id = 1; period = "2026-07"; area = "炼钢"; product = "工资及薪酬"; amount = 0; money = 126000; inputCycle = "每周" }
                @{ id = 2; period = "2026-07"; area = "连铸"; product = "折旧"; amount = 0; money = 86000; inputCycle = "每周" }
            )
            shareRules = @(
                @{ id = 1; line = "lj"; ruleType = "yield_rate"; basis = "coil_wt / slab_wt"; targetTable = "rzbiaozhunchengbenzongbiao"; note = "from StackMillPercent" }
                @{ id = 2; line = "lj"; ruleType = "roll_share"; basis = "length * stress_factor"; targetTable = "rzbiaozhunchengbenzongbiao"; note = "from HotMillLenMultFsn" }
                @{ id = 3; line = "rz"; ruleType = "heating_share"; basis = "heating_time_ratio"; targetTable = "rzbiaozhunchengbenzongbiao"; note = "from HotMillFurnace" }
                @{ id = 4; line = "rz"; ruleType = "rolling_share"; basis = "rolling_time_ratio"; targetTable = "rzbiaozhunchengbenzongbiao"; note = "from HotMillMill" }
            )
            planPriceLj = @(
                @{ id = 1; grade = "Q235B"; price = 3640; marketPrice = 3705; levelPremium = 58; note = "plan price LJ" }
                @{ id = 2; grade = "Q345B"; price = 3870; marketPrice = 3955; levelPremium = 86; note = "plan price LJ" }
            )
            planPriceRz = @(
                @{ id = 1; grade = "SPHC"; price = 3815; marketPrice = 3898; levelPremium = 74; note = "plan price RZ" }
                @{ id = 2; grade = "ST12"; price = 4040; marketPrice = 4128; levelPremium = 93; note = "plan price RZ" }
            )
            samplePriceLj = @(
                @{ id = 1; grade = "Q235B"; price = 18; note = "sample price LJ" }
                @{ id = 2; grade = "Q345B"; price = 24; note = "sample price LJ" }
            )
            samplePriceRz = @(
                @{ id = 1; grade = "SPHC"; price = 26; note = "sample price RZ" }
                @{ id = 2; grade = "ST12"; price = 35; note = "sample price RZ" }
            )
            energyRates = @(
                @{ id = 1; material = "power"; unit = "kWh"; price = 0.71; shareType = "peak_flat_valley"; note = "base electric rate" }
                @{ id = 2; material = "oxygen"; unit = "Nm3"; price = 0.78; shareType = "usage_share"; note = "media rate" }
                @{ id = 3; material = "steam"; unit = "t"; price = 165; shareType = "heating_share"; note = "heating process" }
                @{ id = 4; material = "soft_water"; unit = "t"; price = 5.2; shareType = "heating_share"; note = "heating process" }
            )
            otherConsumptions = @(
                @{ id = 1; line = "lj"; start = "2026-07-01"; end = "2026-07-31"; quyu = "rolling"; product = "work_roll"; amount = 12.6; money = 48.3; note = "mock temp consume row" }
                @{ id = 2; line = "rz"; start = "2026-07-01"; end = "2026-07-31"; quyu = "heating"; product = "soft_water"; amount = 128.0; money = 6.4; note = "mock temp consume row" }
                @{ id = 3; line = "rz"; start = "2026-07-01"; end = "2026-07-31"; quyu = "packing"; product = "packing_strip"; amount = 9.6; money = 21.8; note = "mock temp consume row" }
            )
            recycleEntries = @(
                @{ id = 1; line = "lj"; date = "2026-07-02"; type = "recycle"; weight = 11.2; price = 1620; note = "mock recycle row" }
                @{ id = 2; line = "lj"; date = "2026-07-06"; type = "scale"; weight = 5.8; price = 380; note = "mock scale row" }
                @{ id = 3; line = "rz"; date = "2026-07-08"; type = "recycle"; weight = 13.6; price = 1660; note = "mock recycle row" }
            )
            ljActuals = @(
                @{ id = 1; prodTime = "2026-07-02 08:16:00"; prodShiftNo = "A"; prodShiftGroup = "A"; grade = "Q235B"; thickIndex = 1; widthIndex = 2; slabWtComd = 24.8; matTheoryWt = 23.9; matNetWt = 23.6; inFurnaceTime = 138; inRollTime = 42; chengcailv = 0.9516 }
                @{ id = 2; prodTime = "2026-07-05 10:36:00"; prodShiftNo = "B"; prodShiftGroup = "B"; grade = "Q345B"; thickIndex = 2; widthIndex = 2; slabWtComd = 25.4; matTheoryWt = 24.3; matNetWt = 24.0; inFurnaceTime = 142; inRollTime = 46; chengcailv = 0.9448 }
                @{ id = 3; prodTime = "2026-07-09 15:22:00"; prodShiftNo = "A"; prodShiftGroup = "A"; grade = "Q235B"; thickIndex = 1; widthIndex = 1; slabWtComd = 24.2; matTheoryWt = 23.4; matNetWt = 23.1; inFurnaceTime = 136; inRollTime = 41; chengcailv = 0.9545 }
            )
            rzActuals = @(
                @{ id = 1; prodTime = "2026-07-03 09:20:00"; prodShiftNo = "D"; prodShiftGroup = "A"; grade = "SPHC"; thickIndex = 1; widthIndex = 2; slabWtComd = 26.2; matActWt = 25.1; matNetWt = 24.9; inFurnaceTime = 122; ftRollTime = 38; rollPractDiv = 0; chengcailv = 0.9504 }
                @{ id = 2; prodTime = "2026-07-07 14:10:00"; prodShiftNo = "M"; prodShiftGroup = "B"; grade = "ST12"; thickIndex = 1; widthIndex = 1; slabWtComd = 25.6; matActWt = 24.1; matNetWt = 23.9; inFurnaceTime = 128; ftRollTime = 40; rollPractDiv = 0; chengcailv = 0.9336 }
                @{ id = 3; prodTime = "2026-07-10 18:45:00"; prodShiftNo = "N"; prodShiftGroup = "C"; grade = "SPHC"; thickIndex = 2; widthIndex = 2; slabWtComd = 26.8; matActWt = 25.7; matNetWt = 25.4; inFurnaceTime = 124; ftRollTime = 39; rollPractDiv = 0; chengcailv = 0.9478 }
            )
            standardConditions = @(
                @{ id = 1; line = "rz"; conditionType = "total_output"; value = 2400; note = "SC total output threshold" }
                @{ id = 2; line = "rz"; conditionType = "min_grade_output"; value = 2300; note = "SC min single grade threshold" }
                @{ id = 3; line = "lj"; conditionType = "total_output"; value = 2250; note = "SC total output threshold" }
                @{ id = 4; line = "lj"; conditionType = "min_grade_output"; value = 2250; note = "SC min single grade threshold" }
            )
            ljScheduleParams = @(
                @{ id = 1; stepCode = "furnace"; stepName = "Furnace"; minutes = 128; note = "func_time" }
                @{ id = 2; stepCode = "gapFuncMill"; stepName = "Gap To Mill"; minutes = 3; note = "gongxudian" }
                @{ id = 3; stepCode = "rolling"; stepName = "Rolling"; minutes = 8; note = "mill_time" }
                @{ id = 4; stepCode = "gapMillCold"; stepName = "Gap To Cold"; minutes = 2; note = "gongxudian" }
                @{ id = 5; stepCode = "cold"; stepName = "Cold Bed"; minutes = 26; note = "cold_time" }
                @{ id = 6; stepCode = "finish"; stepName = "Finishing"; minutes = 9; note = "across_or_park" }
                @{ id = 7; stepCode = "chargeGap"; stepName = "Charge Gap"; minutes = 4; note = "continuous rhythm" }
            )
            rzScheduleParams = @(
                @{ id = 1; stepCode = "furnace"; stepName = "Furnace"; minutes = 112; note = "funcetime" }
                @{ id = 2; stepCode = "gapFuncMill"; stepName = "Gap To Mill"; minutes = 2; note = "gongxudian" }
                @{ id = 3; stepCode = "rolling"; stepName = "Rolling"; minutes = 6; note = "ft_roll_time" }
                @{ id = 4; stepCode = "gapMillCold"; stepName = "Gap To Cold"; minutes = 1; note = "gongxudian" }
                @{ id = 5; stepCode = "cold"; stepName = "Cooling Coiling"; minutes = 18; note = "post rolling rhythm" }
                @{ id = 6; stepCode = "finish"; stepName = "Packing"; minutes = 7; note = "packing step" }
                @{ id = 7; stepCode = "chargeGap"; stepName = "Charge Gap"; minutes = 3; note = "continuous rhythm" }
            )
        }
        costBaseRows = @(
            @{ id = 1; line = "lj"; period = "2026-07"; grade = "Q235B"; pinzhong = "carbon_steel"; xilie = "low_carbon"; thickness = 1.6; width = 1250; thickIndex = 1; widthIndex = 2; slabWt = 2480; coilWt = 2365; steelmakingCost = 3724; processCost = 668; manufacturingCost = 4852; salePrice = 5070; heatingCost = 132; rollingCost = 186; rollCost = 22; packageCost = 0; sampleCost = 18; otherCost = 310; recycleCredit = -12 }
            @{ id = 2; line = "lj"; period = "2026-07"; grade = "Q345B"; pinzhong = "alloy_steel"; xilie = "structural_series"; thickness = 2.8; width = 1250; thickIndex = 2; widthIndex = 2; slabWt = 2540; coilWt = 2396; steelmakingCost = 3968; processCost = 724; manufacturingCost = 5108; salePrice = 5388; heatingCost = 140; rollingCost = 194; rollCost = 24; packageCost = 0; sampleCost = 24; otherCost = 342; recycleCredit = -10 }
            @{ id = 3; line = "lj"; period = "2026-08"; grade = "Q235B"; pinzhong = "carbon_steel"; xilie = "low_carbon"; thickness = 1.8; width = 1050; thickIndex = 1; widthIndex = 1; slabWt = 2410; coilWt = 2302; steelmakingCost = 3708; processCost = 652; manufacturingCost = 4805; salePrice = 5032; heatingCost = 128; rollingCost = 181; rollCost = 21; packageCost = 0; sampleCost = 18; otherCost = 304; recycleCredit = -14 }
            @{ id = 4; line = "rz"; period = "2026-07"; grade = "SPHC"; pinzhong = "hot_roll_commercial"; xilie = "commercial_series"; thickness = 2.5; width = 1500; thickIndex = 1; widthIndex = 2; slabWt = 2620; coilWt = 2490; steelmakingCost = 3872; processCost = 742; manufacturingCost = 5072; salePrice = 5290; heatingCost = 138; rollingCost = 198; rollCost = 24; packageCost = 18; sampleCost = 26; otherCost = 338; recycleCredit = -16 }
            @{ id = 5; line = "rz"; period = "2026-07"; grade = "ST12"; pinzhong = "cold_roll_feed"; xilie = "deep_draw_series"; thickness = 1.4; width = 1380; thickIndex = 1; widthIndex = 1; slabWt = 2560; coilWt = 2392; steelmakingCost = 4098; processCost = 786; manufacturingCost = 5296; salePrice = 5568; heatingCost = 146; rollingCost = 202; rollCost = 27; packageCost = 19; sampleCost = 35; otherCost = 357; recycleCredit = -12 }
            @{ id = 6; line = "rz"; period = "2026-08"; grade = "SPHC"; pinzhong = "hot_roll_commercial"; xilie = "commercial_series"; thickness = 4.2; width = 1500; thickIndex = 2; widthIndex = 2; slabWt = 2680; coilWt = 2528; steelmakingCost = 3894; processCost = 754; manufacturingCost = 5109; salePrice = 5315; heatingCost = 140; rollingCost = 200; rollCost = 25; packageCost = 18; sampleCost = 26; otherCost = 345; recycleCredit = -15 }
        )
        standardHistory = @(
            @{ id = 1; line = "rz"; period = "2026-04"; grade = "SPHC"; pinzhong = "hot_roll_commercial"; xilie = "commercial_series"; slabWt = 2550; coilWt = 2435; manufacturingCost = 5120; processCost = 748; yieldRate = 0.9549; sampleCost = 26; packageCost = 18; recycleCredit = -14 }
            @{ id = 2; line = "rz"; period = "2026-05"; grade = "SPHC"; pinzhong = "hot_roll_commercial"; xilie = "commercial_series"; slabWt = 2640; coilWt = 2518; manufacturingCost = 5078; processCost = 739; yieldRate = 0.9538; sampleCost = 26; packageCost = 18; recycleCredit = -16 }
            @{ id = 3; line = "rz"; period = "2026-06"; grade = "ST12"; pinzhong = "cold_roll_feed"; xilie = "deep_draw_series"; slabWt = 2580; coilWt = 2404; manufacturingCost = 5322; processCost = 792; yieldRate = 0.9318; sampleCost = 35; packageCost = 19; recycleCredit = -11 }
            @{ id = 4; line = "rz"; period = "2026-07"; grade = "ST12"; pinzhong = "cold_roll_feed"; xilie = "deep_draw_series"; slabWt = 2620; coilWt = 2456; manufacturingCost = 5291; processCost = 784; yieldRate = 0.9374; sampleCost = 35; packageCost = 19; recycleCredit = -13 }
            @{ id = 5; line = "lj"; period = "2026-04"; grade = "Q235B"; pinzhong = "carbon_steel"; xilie = "low_carbon"; slabWt = 2400; coilWt = 2292; manufacturingCost = 4826; processCost = 658; yieldRate = 0.9550; sampleCost = 18; packageCost = 0; recycleCredit = -14 }
            @{ id = 6; line = "lj"; period = "2026-05"; grade = "Q235B"; pinzhong = "carbon_steel"; xilie = "low_carbon"; slabWt = 2460; coilWt = 2351; manufacturingCost = 4802; processCost = 651; yieldRate = 0.9557; sampleCost = 18; packageCost = 0; recycleCredit = -15 }
            @{ id = 7; line = "lj"; period = "2026-06"; grade = "Q345B"; pinzhong = "alloy_steel"; xilie = "structural_series"; slabWt = 2510; coilWt = 2370; manufacturingCost = 5116; processCost = 728; yieldRate = 0.9442; sampleCost = 24; packageCost = 0; recycleCredit = -10 }
            @{ id = 8; line = "lj"; period = "2026-07"; grade = "Q345B"; pinzhong = "alloy_steel"; xilie = "structural_series"; slabWt = 2560; coilWt = 2415; manufacturingCost = 5098; processCost = 722; yieldRate = 0.9434; sampleCost = 24; packageCost = 0; recycleCredit = -11 }
        )
        schedulePlans = [ordered]@{
            lj = @(
                @{ id = 1; slabNo = "LJ260701001"; grade = "Q235B"; thickness = 1.6; width = 1250 }
                @{ id = 2; slabNo = "LJ260701002"; grade = "Q345B"; thickness = 2.8; width = 1250 }
                @{ id = 3; slabNo = "LJ260701003"; grade = "Q235B"; thickness = 1.8; width = 1050 }
                @{ id = 4; slabNo = "LJ260701004"; grade = "Q235B"; thickness = 1.6; width = 1250 }
            )
            rz = @(
                @{ id = 1; slabNo = "RZ260701001"; grade = "SPHC"; thickness = 2.5; width = 1500 }
                @{ id = 2; slabNo = "RZ260701002"; grade = "ST12"; thickness = 1.4; width = 1380 }
                @{ id = 3; slabNo = "RZ260701003"; grade = "SPHC"; thickness = 4.2; width = 1500 }
                @{ id = 4; slabNo = "RZ260701004"; grade = "SPHC"; thickness = 2.5; width = 1500 }
            )
        }
        runtime = [ordered]@{
            generatedCostDetails = @{}
        }
    }
}
