(function () {
  var app = document.getElementById("app");
  if (!app) {
    return;
  }

  var API_BASE = (window.location.protocol === "http:" || window.location.protocol === "https:")
    ? window.location.origin + "/api"
    : "http://127.0.0.1:8091/api";
  var DEBUG_AUTO_LOGIN = true;

  var navGroups = [
    {
      label: "总览",
      items: [{ id: "dashboard", title: "系统总览", kind: "dashboard" }]
    },
    {
      label: "1780 精量化成本",
      items: [
        { id: "steelGrades", title: "基础数据：钢种与系列", kind: "dataset", dataset: "steelGrades" },
        { id: "thicknessRules", title: "基础数据：厚度索引", kind: "dataset", dataset: "thicknessRules" },
        { id: "widthRules", title: "基础数据：宽度索引", kind: "dataset", dataset: "widthRules" },
        { id: "planPriceRz", title: "基础数据：板坯计划价", kind: "dataset", dataset: "planPriceRz" },
        { id: "samplePriceRz", title: "基础数据：试样/包装费", kind: "dataset", dataset: "samplePriceRz" },
        { id: "rzActuals", title: "实绩：准发与轧制实绩", kind: "dataset", dataset: "rzActuals" },
        { id: "recycleEntries", title: "实绩：回收与改判", kind: "dataset", dataset: "recycleEntries" },
        { id: "costSummary", title: "成本计算总表", kind: "costSummary" }
      ]
    },
    {
      label: "炉卷 精量化成本",
      items: [
        { id: "consumeProducts", title: "基础数据：消耗产品与分摊", kind: "dataset", dataset: "consumeProducts" },
        { id: "shareRules", title: "基础数据：分摊规则", kind: "dataset", dataset: "shareRules" },
        { id: "planPriceLj", title: "基础数据：板坯计划价", kind: "dataset", dataset: "planPriceLj" },
        { id: "samplePriceLj", title: "基础数据：试样加工费", kind: "dataset", dataset: "samplePriceLj" },
        { id: "ljActuals", title: "实绩：综合信息与轧制", kind: "dataset", dataset: "ljActuals" },
        { id: "otherConsumptions", title: "实绩：固定消耗", kind: "dataset", dataset: "otherConsumptions" },
        { id: "ljScheduleParams", title: "时刻表：节拍参数", kind: "dataset", dataset: "ljScheduleParams" },
        { id: "ljSchedule", title: "时刻表：排程模拟", kind: "schedule", line: "lj", paramsDataset: "ljScheduleParams" }
      ]
    },
    {
      label: "炼钢 精量化成本",
      items: [
        { id: "steelmakingGrades", title: "基础数据：钢种与系列", kind: "dataset", dataset: "steelmakingGrades" },
        { id: "steelmakingRoutes", title: "基础数据：路径表", kind: "dataset", dataset: "steelmakingRoutes" },
        { id: "steelmakingProducts", title: "基础数据：消耗产品", kind: "dataset", dataset: "steelmakingProducts" },
        { id: "steelmakingPrices", title: "基础数据：计划价与水平附加", kind: "dataset", dataset: "steelmakingPrices" },
        { id: "steelmakingActuals", title: "实绩：转炉、精炼与连铸", kind: "dataset", dataset: "steelmakingActuals" },
        { id: "steelmakingFixedConsumption", title: "实绩：固定消耗", kind: "dataset", dataset: "steelmakingFixedConsumption" }
      ]
    },
    {
      label: "标准成本与辅助功能",
      items: [
        { id: "standardConditions", title: "标准成本条件", kind: "dataset", dataset: "standardConditions" },
        { id: "standardCost", title: "标准成本结果", kind: "standardCost" },
        { id: "rzScheduleParams", title: "热连轧节拍参数", kind: "dataset", dataset: "rzScheduleParams" },
        { id: "rzSchedule", title: "1780 时刻表模拟", kind: "schedule", line: "rz", paramsDataset: "rzScheduleParams" }
      ]
    }
  ];

  var navTree = [
    {
      id: "basic-data",
      label: "基础数据",
      children: [
        { id: "heat-treatment", label: "热处理要求" },
        {
          id: "steel-grades", label: "钢种", children: [
            { id: "slab-grades", label: "板坯钢种", pageId: "steelmakingGrades" },
            { id: "plate-grades", label: "钢板钢种", pageId: "steelGrades" },
            { id: "coil-grades", label: "钢卷钢种", pageId: "steelGrades" }
          ]
        },
        {
          id: "thickness-index", label: "厚度索引", children: [
            { id: "slab-thickness", label: "板坯厚度索引", pageId: "thicknessRules" },
            { id: "plate-thickness", label: "钢板厚度索引", pageId: "thicknessRules" },
            { id: "coil-thickness", label: "钢卷厚度索引", pageId: "thicknessRules" }
          ]
        },
        {
          id: "width-index", label: "宽度索引", children: [
            { id: "slab-width", label: "板坯宽度索引", pageId: "widthRules" },
            { id: "plate-width", label: "钢板宽度索引", pageId: "widthRules" },
            { id: "coil-width", label: "钢卷宽度索引", pageId: "widthRules" }
          ]
        },
        { id: "length-index", label: "长度索引", children: [{ id: "slab-length", label: "板坯长度索引" }, { id: "plate-length", label: "钢板长度索引" }] },
        { id: "process-route", label: "工艺路径", pageId: "steelmakingRoutes" },
        { id: "wage-equipment", label: "工资设备系数" },
        { id: "consumption-type", label: "消耗类型", children: [{ id: "steelmaking-consumption-type", label: "炼钢消耗类型", pageId: "steelmakingProducts" }, { id: "rolling-consumption-type", label: "轧钢消耗类型", pageId: "consumeProducts" }] },
        { id: "consumable-product", label: "耗材产品", children: [{ id: "rz-consumable", label: "1780 耗材产品", pageId: "consumeProducts" }, { id: "steelmaking-consumable", label: "炼钢耗材产品", pageId: "steelmakingProducts" }, { id: "lj-consumable", label: "炉卷耗材产品", pageId: "consumeProducts" }] }
      ]
    },
    {
      id: "basic-fee",
      label: "基础费用",
      children: [
        { id: "electric-config", label: "电能配置表" },
        { id: "energy-config", label: "能源配置表" },
        { id: "sample-fee", label: "试样加工费", children: [{ id: "rz-sample-fee", label: "1780 试样加工费", pageId: "samplePriceRz" }, { id: "lj-sample-fee", label: "炉卷试样加工费", pageId: "samplePriceLj" }] },
        { id: "plan-price", label: "计划价", children: [{ id: "alloy-plan-price", label: "合金计划价", pageId: "steelmakingPrices" }, { id: "slab-plan-price", label: "板坯计划价", children: [{ id: "rz-slab-plan-price", label: "1780 板坯计划价", pageId: "planPriceRz" }, { id: "lj-slab-plan-price", label: "炉卷板坯计划价", pageId: "planPriceLj" }] }, { id: "hot-metal-plan-price", label: "铁水计划价", pageId: "steelmakingPrices" }] },
        { id: "actual-price", label: "实际价", children: [{ id: "alloy-actual-price", label: "合金实际价", pageId: "steelmakingPrices" }, { id: "slab-actual-price", label: "板坯实际价", children: [{ id: "rz-slab-actual-price", label: "1780 板坯实际价", pageId: "planPriceRz" }, { id: "lj-slab-actual-price", label: "炉卷板坯实际价", pageId: "planPriceLj" }] }, { id: "hot-metal-actual-price", label: "铁水实际价", pageId: "steelmakingPrices" }] },
        { id: "history-plan-price", label: "历史计划价", children: [{ id: "rz-history-plan-price", label: "1780 板坯历史计划价", pageId: "planPriceRz" }, { id: "lj-history-plan-price", label: "炉卷板坯历史计划价", pageId: "planPriceLj" }] },
        { id: "history-sale-price", label: "历史销售价", children: [{ id: "plate-history-sale-price", label: "钢板历史销售价" }, { id: "coil-history-sale-price", label: "钢卷历史销售价" }] },
        { id: "internal-price", label: "内部结算价" },
        { id: "packing-fee", label: "包装费", pageId: "samplePriceRz" }
      ]
    },
    {
      id: "actuals",
      label: "实绩表",
      children: [
        { id: "financial-transfer", label: "财务转账消耗表", children: [{ id: "steelmaking-casting-consumption", label: "炼钢连铸消耗", pageId: "steelmakingFixedConsumption" }, { id: "lj-consumption", label: "炉卷消耗", pageId: "otherConsumptions" }, { id: "rz-consumption", label: "1780 消耗", pageId: "otherConsumptions" }] },
        { id: "electric-actuals", label: "电能消耗" },
        { id: "recycle-actuals", label: "回收实绩", children: [{ id: "rz-recycle", label: "1780 回收", pageId: "recycleEntries" }, { id: "meter-recycle", label: "广义计量回收", pageId: "recycleEntries" }, { id: "lj-recycle", label: "炉卷回收", pageId: "recycleEntries" }] },
        { id: "medium-actuals", label: "介质消耗" },
        { id: "production-actuals", label: "生产实绩", children: [
          { id: "rz-production", label: "1780 生产实绩", children: [{ id: "rz-rejudge", label: "1780 改判", pageId: "recycleEntries" }, { id: "coil-actuals", label: "钢卷实绩", pageId: "rzActuals" }, { id: "release-confirm", label: "准发确认", pageId: "rzActuals" }] },
          { id: "steelmaking-production", label: "炼钢生产实绩", children: [{ id: "lf-actuals", label: "LF 炉实绩", pageId: "steelmakingActuals" }, { id: "rh-actuals", label: "RH 炉实绩", pageId: "steelmakingActuals" }, { id: "vd-actuals", label: "VD 炉实绩", pageId: "steelmakingActuals" }, { id: "casting-actuals", label: "浇注实绩", pageId: "steelmakingActuals" }, { id: "steelmaking-actuals", label: "炼钢实绩", pageId: "steelmakingActuals" }, { id: "steelmaking-statistics", label: "炼钢统计", pageId: "steelmakingActuals" }, { id: "steelmaking-consumption-actuals", label: "炼钢消耗实绩", pageId: "steelmakingFixedConsumption" }, { id: "heat-grade-process", label: "炉次钢种子工序实绩", pageId: "steelmakingActuals" }, { id: "steelmaking-plan", label: "炼钢计划表", pageId: "steelmakingActuals" }, { id: "cutting-actuals", label: "切断实绩", pageId: "steelmakingActuals" }, { id: "desulfurization-actuals", label: "脱硫实绩", pageId: "steelmakingActuals" }, { id: "raw-material-actuals", label: "原料消耗", pageId: "steelmakingActuals" }, { id: "converter-actuals", label: "转炉实绩", pageId: "steelmakingActuals" }] },
          { id: "lj-production", label: "炉卷生产实绩", pageId: "ljActuals" }
        ] },
        { id: "roll-actuals", label: "轧辊消耗实绩", children: [{ id: "rz-roll-actuals", label: "1780 轧辊消耗", pageId: "otherConsumptions" }, { id: "lj-roll-actuals", label: "炉卷轧辊消耗", pageId: "otherConsumptions" }] }
      ]
    },
    {
      id: "realtime-cost",
      label: "实时成本",
      children: [
        { id: "cost-calculation", label: "成本计算", children: [{ id: "steelmaking-cost-calc", label: "炼钢成本计算", pageId: "steelmakingPrices" }, { id: "rz-cost-calc", label: "1780 成本计算" }, { id: "lj-cost-calc", label: "炉卷成本计算" }, { id: "receive-steelmaking-actuals", label: "接收炼钢生产实绩", pageId: "steelmakingActuals" }, { id: "receive-steelmaking-consumption", label: "接收炼钢消耗与产量", pageId: "steelmakingFixedConsumption" }, { id: "rz-stop-cost", label: "1780 停产消耗计算" }] },
        { id: "history-cost", label: "历史成本", children: [{ id: "rz-history-cost", label: "1780 历史成本" }, { id: "steelmaking-history-cost", label: "炼钢历史成本", pageId: "steelmakingPrices" }, { id: "lj-history-cost", label: "炉卷历史成本" }] }
      ]
    },
    {
      id: "system-maintenance",
      label: "系统维护",
      children: [
        { id: "button-management", label: "按钮管理" },
        { id: "menu-management", label: "菜单管理" },
        { id: "screen-management", label: "画面管理" },
        { id: "permission-management", label: "权限管理" },
        { id: "user-relation-management", label: "用户关系管理" },
        { id: "user-management", label: "用户管理", pageId: "user-management" },
        { id: "user-group-management", label: "用户组管理", pageId: "user-group-management" }
      ]
    }
  ];

  var pageMap = {};
  each(navGroups, function (group) {
    each(group.items, function (item) {
      pageMap[item.id] = item;
    });
  });

  var pageMenuPaths = {};
  indexMenuPages(navTree, []);
  pageMap["user-management"] = { id: "user-management", title: "用户管理", kind: "userManagement" };
  pageMap["user-group-management"] = { id: "user-group-management", title: "用户组管理", kind: "userGroups" };

  var state = {
    loading: true,
    error: "",
    currentPage: "dashboard",
    session: null,
    expandedMenus: {},
    bootstrap: null,
    datasets: {},
    datasetQueries: {},
    selectedRows: {},
    drafts: {},
    costRun: {
      line: "lj",
      dimension: "bySpec",
      startDate: "2026-07-01",
      endDate: "2026-07-31",
      rows: [],
      loading: false
    },
    currentCostDetails: null,
    standardCost: {
      line: "rz",
      startDate: "2026-04-01",
      endDate: "2026-07-31",
      loading: false,
      result: null
    },
    schedules: {
      lj: { startDate: "2026-07-15T08:00", loading: false, result: null },
      rz: { startDate: "2026-07-15T08:00", loading: false, result: null }
    },
    userManagement: { payload: null, draft: null, groups: [] }
  };

  if (DEBUG_AUTO_LOGIN) {
    loginWithCredentials("admin", "123456");
  } else {
    render();
  }

  function initialize() {
    refreshBootstrap(function (error) {
      if (error) {
        state.loading = false;
        state.error = error.message || "初始化失败";
        render();
        return;
      }

      state.loading = false;
      render();
      runCost();
      runStandardCost();
      runSchedule("lj", false);
      runSchedule("rz", false);
    });
  }

  function refreshBootstrap(callback) {
    apiGet("/bootstrap", function (error, payload) {
      if (!error) {
        state.bootstrap = payload;
      }
      done(callback, error, payload);
    });
  }

  function ensureDataset(name, force, callback) {
    if (typeof force === "function") {
      callback = force;
      force = false;
    }

    if (!force && state.datasets[name]) {
      done(callback, null, state.datasets[name]);
      return;
    }

    apiGet("/datasets/" + name, function (error, payload) {
      if (error) {
        done(callback, error);
        return;
      }

      state.datasets[name] = payload;
      var rows = payload.rows || [];
      var selectedId = state.selectedRows[name];

      if (!selectedId && rows.length > 0) {
        state.selectedRows[name] = rows[0].id;
        state.drafts[name] = cloneRow(rows[0]);
      } else if (selectedId) {
        var selected = findRowById(rows, selectedId);
        if (selected) {
          state.drafts[name] = cloneRow(selected);
        }
      }

      done(callback, null, payload);
    });
  }

  function ensureLocalDataset(page) {
    var name = page.dataset;
    if (state.datasets[name]) {
      return;
    }
    state.datasets[name] = {
      rows: [
        { id: 1, 名称: page.title, 状态: "示例", 说明: "本地占位数据，可直接编辑" },
        { id: 2, 名称: page.title + "示例 2", 状态: "启用", 说明: "可新增、删除、导入和导出" }
      ],
      meta: {
        title: page.title,
        description: "该子页面已建立通用表格，可替换为真实数据表。",
        readonly: false,
        collectable: false,
        columns: ["id", "名称", "状态", "说明"]
      }
    };
    state.selectedRows[name] = 1;
    state.drafts[name] = cloneRow(state.datasets[name].rows[0]);
    render();
  }

  function navigateTo(pageId) {
    var page = pageMap[pageId];
    if (!page) {
      return;
    }
    state.currentPage = pageId;
    each(pageMenuPaths[pageId] || [], function (menuId) {
      state.expandedMenus[menuId] = true;
    });
    render();

    if (page.kind === "userManagement" || page.kind === "userGroups") {
      loadUserManagement(function () { render(); });
      return;
    }

    if (page.kind === "localDataset") {
      ensureLocalDataset(page);
      return;
    }

    if (page.kind === "dataset") {
      ensureDataset(page.dataset, function () {
        render();
      });
    }
  }

  function render() {
    if (!state.session) {
      app.innerHTML = renderLogin();
      bindEvents();
      return;
    }
    app.innerHTML = [
      '<div class="layout">',
      renderSidebar(),
      '<main class="main-shell">',
      renderTopbar(),
      '<section class="workspace">',
      renderCurrentPage(),
      "</section>",
      "</main>",
      "</div>"
    ].join("");

    bindEvents();
  }

  function renderSidebar() {
    var html = [];
    html.push('<aside class="sidebar">');
    html.push('<div class="brand"><div class="brand-mark"><img src="./assets/company-logo.jpeg" alt="河南钢铁"></div><div><h1>第二炼轧厂</h1><p>精量化成本核算系统</p></div></div>');

    html.push('<nav class="tree-nav" aria-label="系统菜单">');
    each(navTree, function (node) {
      html.push(renderMenuNode(node, 1));
    });
    html.push("</nav>");
    html.push('<div class="sidebar-footer"><span class="live-dot"></span><span>系统运行中 · B/S 平台</span></div>');

    html.push("</aside>");
    return html.join("");
  }

  function renderMenuNode(node, level) {
    var hasChildren = node.children && node.children.length > 0;
    var isExpanded = !!state.expandedMenus[node.id];
    var isActive = (node.pageId && state.currentPage === node.pageId) || (!node.pageId && !hasChildren && state.currentPage === node.id);
    var html = [];

    html.push('<div class="tree-node level-' + level + '">');
    if (hasChildren) {
      html.push(
        '<button class="tree-toggle" data-menu-toggle="' + safe(node.id) + '" aria-expanded="' + isExpanded + '">' +
        '<span class="tree-caret" aria-hidden="true">' + (isExpanded ? "▾" : "▸") + "</span>" +
        '<span>' + safe(node.label) + "</span>" +
        "</button>"
      );
      html.push('<div class="tree-children ' + (isExpanded ? "expanded" : "") + '">');
      each(node.children, function (child) {
        html.push(renderMenuNode(child, level + 1));
      });
      html.push("</div>");
    } else if (node.pageId) {
      html.push(
        '<button class="tree-leaf ' + (isActive ? "active" : "") + '" data-nav="' + safe(node.pageId) + '">' +
        '<span class="tree-leaf-dot" aria-hidden="true"></span><span>' + safe(node.label) + "</span></button>"
      );
    } else {
      html.push('<button class="tree-leaf local-placeholder" data-nav="' + safe(node.id) + '"><span class="tree-leaf-dot" aria-hidden="true"></span><span>' + safe(node.label) + "</span></button>");
    }
    html.push("</div>");
    return html.join("");
  }

  function indexMenuPages(nodes, ancestorIds) {
    each(nodes, function (node) {
      var path = ancestorIds.concat(node.id);
      if (node.pageId) {
        pageMenuPaths[node.pageId] = path;
      } else if (!node.children || !node.children.length) {
        pageMap[node.id] = { id: node.id, title: node.label, kind: "localDataset", dataset: "local:" + node.id };
        pageMenuPaths[node.id] = path;
      }
      if (node.children) {
        indexMenuPages(node.children, path);
      }
    });
  }

  function renderTopbar() {
    var page = pageMap[state.currentPage];
    var system = state.bootstrap && state.bootstrap.system ? state.bootstrap.system : {};
    return [
      '<header class="topbar">',
      '<div class="page-heading"><div class="breadcrumb">第二炼轧厂 <span>/</span> ' + safe(page.title) + '</div>',
      "<h2>" + safe(page.title) + "</h2>",
      "<p>" + safe(describePage(page)) + "</p>",
      "</div>",
      '<div class="status-panel">',
      '<span class="current-user">' + safe(state.session.user.account) + ' · ' + safe(state.session.user.group) + '</span>',
      '<button class="logout-btn" data-action="logout">退出登录</button>',
      '<span class="pill">' + safe(system.currentProvider || "mock") + "</span>",
      '<span class="pill subtle">' + safe(system.sourceEntry || "") + "</span>",
      "</div>",
      "</header>"
    ].join("");
  }

  function renderCurrentPage() {
    var page;
    if (state.loading) {
      return renderLoading();
    }
    if (state.error) {
      return renderError();
    }

    page = pageMap[state.currentPage];
    if (page.kind === "dashboard") {
      return renderDashboard();
    }
    if (page.kind === "costSummary") {
      return renderCostSummary();
    }
    if (page.kind === "standardCost") {
      return renderStandardCost();
    }
    if (page.kind === "schedule") {
      return renderSchedulePage(page);
    }
    if (page.kind === "userManagement") {
      return renderUserManagement();
    }
    if (page.kind === "userGroups") {
      return renderUserGroups();
    }
    return renderDatasetPage(page);
  }

  function renderLogin() {
    return '<main class="login-shell"><section class="login-panel"><div class="login-logo"><img src="./assets/company-logo.jpeg" alt="公司图标"></div><div class="login-copy"><p>第二炼轧厂</p><h1>精量化成本核算系统</h1><span>请使用系统账户登录后继续操作</span></div><form class="login-form"><label>账户<input name="account" autocomplete="username" value="admin" placeholder="请输入账户"></label><label>密码<input name="password" type="password" autocomplete="current-password" value="123456" placeholder="请输入密码"></label><button class="primary-btn" type="button" data-action="login">登录系统</button><p class="login-tip">调试模式：默认管理员账户已自动登录；如需切换账户，请先退出登录。</p>' + (state.error ? '<p class="login-error">' + safe(state.error) + '</p>' : '') + '</form></section></main>';
  }

  function loginWithCredentials(account, password) {
    state.loading = true;
    render();
    apiPost('/auth/login', { account: account, password: password }, function (error, result) {
      if (error) {
        state.loading = false;
        state.error = error.message || '登录失败';
        render();
        return;
      }
      state.session = result;
      initialize();
    });
  }

  function renderLoading() {
    return '<section class="panel"><div class="empty-detail"><strong>系统加载中</strong><p>正在从本地 Mock API 拉取模块定义与伪数据。</p></div></section>';
  }

  function renderError() {
    return '<section class="panel"><div class="empty-detail"><strong>无法连接第二炼轧厂 B/S 服务</strong><p>' +
      safe(state.error) +
      '</p><div class="hero-actions"><button class="primary-btn" data-action="retry-bootstrap">重新连接</button></div></div></section>';
  }

  function renderDashboard() {
    var datasets = state.bootstrap && state.bootstrap.datasets ? state.bootstrap.datasets : {};
    var modules = state.bootstrap && state.bootstrap.modules ? state.bootstrap.modules : [];
    var notices = state.bootstrap && state.bootstrap.notices ? state.bootstrap.notices : [];
    var system = state.bootstrap && state.bootstrap.system ? state.bootstrap.system : {};
    var cards = [
      { label: "1780 数据", value: countValues(["steelGrades", "thicknessRules", "widthRules", "planPriceRz", "rzActuals"], datasets), note: "基础、实绩、成本计算" },
      { label: "炉卷数据", value: countValues(["consumeProducts", "shareRules", "planPriceLj", "ljActuals", "otherConsumptions"], datasets), note: "基础、实绩、时刻表" },
      { label: "炼钢数据", value: countValues(["steelmakingGrades", "steelmakingRoutes", "steelmakingProducts", "steelmakingActuals", "steelmakingFixedConsumption"], datasets), note: "基础、实绩、水平附加" },
      { label: "后端提供者", value: system.currentProvider || "-", note: "未来可切到 sqlserver" }
    ];
    var html = [];

    html.push('<div class="hero"><div class="hero-copy">');
    html.push('<div class="eyebrow">第二炼轧厂 · 精量化成本核算</div>');
    html.push('<h3>以“1780、炉卷、炼钢”三个子系统组织基础数据、实绩采集和成本计算</h3>');
    html.push('<p>炼钢按钢种路径核算钢水、合金、辅材、炼钢与连铸工序成本，形成炼钢水平附加；1780与炉卷再按钢种组距、生产实绩和分摊规则计算轧钢制造成本。三级实绩按8小时采集，固定消耗支持人工维护。</p>');
    html.push('<div class="hero-actions"><button class="primary-btn" data-nav="costSummary">查看轧钢成本总表</button><button class="secondary-btn" data-nav="steelmakingPrices">维护炼钢水平附加</button></div>');
    html.push('</div><div class="hero-panel"><div class="flow-card"><div class="flow-caption">成本数据闭环</div><div class="flow-step"><b>01</b><span>基础参数</span></div><div class="flow-line"></div><div class="flow-step"><b>02</b><span>实绩采集</span></div><div class="flow-line"></div><div class="flow-step"><b>03</b><span>成本核算</span></div><div class="flow-line"></div><div class="flow-step"><b>04</b><span>经营分析</span></div></div></div></div>');

    html.push('<div class="card-grid">');
    each(cards, function (card) {
      html.push('<article class="metric-card"><span>' + safe(card.label) + '</span><strong>' + safe(String(card.value)) + '</strong><small>' + safe(card.note) + '</small></article>');
    });
    html.push("</div>");

    html.push('<div class="two-column">');
    html.push('<section class="panel"><div class="panel-header"><h3>说明书业务结构</h3><p>以下结构对应精量化成本核算系统说明书的三个子系统。</p></div><div class="mapping-list">');
    each(modules, function (item) {
      html.push("<div><strong>" + safe(item.code) + " · " + safe(item.title) + "</strong><span>" + safe(item.source) + " · " + safe(item.summary) + "</span></div>");
    });
    html.push("</div></section>");

    html.push('<section class="panel"><div class="panel-header"><h3>当前说明</h3><p>这些说明来自 bootstrap 接口，未来也可以换成后端配置。</p></div><ul class="notice-list">');
    each(notices, function (item) {
      html.push("<li>" + safe(item) + "</li>");
    });
    html.push("</ul></section></div>");

    return html.join("");
  }

  function renderDatasetPage(page) {
    var payload = state.datasets[page.dataset];
    var rows;
    var meta;
    var columns;
    var visibleRows;
    var query;
    var selectedId;
    var selectedRow;
    var draft;
    var html = [];

    if (!payload) {
      return '<section class="panel"><div class="empty-detail"><strong>尚未加载数据</strong><p>点击下方按钮从 API 拉取该数据集。</p><div class="hero-actions"><button class="primary-btn" data-action="load-dataset" data-dataset="' +
        safe(page.dataset) +
        '">加载 ' +
        safe(page.title) +
        "</button></div></div></section>";
    }

    rows = payload.rows || [];
    meta = payload.meta || {};
    columns = meta.columns || inferColumns(rows);
    query = state.datasetQueries[page.dataset] || "";
    visibleRows = filterRows(rows, query);
    selectedId = state.selectedRows[page.dataset];
    selectedRow = findRowById(rows, selectedId) || (rows.length ? rows[0] : null);
    draft = state.drafts[page.dataset] || cloneRow(selectedRow || makeEmptyRow(columns));

    html.push('<div class="two-column">');
    html.push('<section class="panel table-panel"><div class="panel-header"><h3>' + safe(meta.title || page.title) + "</h3><p>" + safe(meta.description || "") + '</p></div>');
    html.push('<div class="toolbar"><button class="primary-btn" data-action="reload-dataset" data-dataset="' + safe(page.dataset) + '">刷新</button>');
    if (!meta.readonly) {
      html.push('<button class="secondary-btn" data-action="new-row" data-dataset="' + safe(page.dataset) + '">新建</button>');
    }
    if (meta.collectable) {
      html.push('<button class="secondary-btn" data-action="collect-row" data-dataset="' + safe(page.dataset) + '">模拟采集</button>');
    }
    html.push('<label class="table-search"><span>查询</span><input type="search" placeholder="输入关键字" value="' + safeInputValue(query) + '" data-query-dataset="' + safe(page.dataset) + '"></label>');
    html.push('<button class="secondary-btn" data-action="import-excel" data-dataset="' + safe(page.dataset) + '">导入 Excel</button><input class="file-input" type="file" accept=".csv,.tsv,.txt,.xls" data-file-dataset="' + safe(page.dataset) + '">');
    html.push('<button class="secondary-btn" data-action="export-excel" data-dataset="' + safe(page.dataset) + '">导出 Excel</button>');
    html.push('<span class="mock-chip">显示 ' + safe(String(visibleRows.length)) + ' / ' + safe(String(rows.length)) + ' 条</span></div>');
    html.push('<div class="table-wrap"><table><thead><tr>');
    each(columns, function (column) {
      html.push("<th>" + safe(column) + "</th>");
    });
    html.push("</tr></thead><tbody>");
    each(visibleRows, function (row) {
      html.push('<tr class="' + (String(row.id) === String(selectedId) ? "selected" : "") + '" data-select-row="' + safe(page.dataset + ":" + row.id) + '">');
      each(columns, function (column) {
        html.push("<td>" + safe(formatCell(row[column])) + "</td>");
      });
      html.push("</tr>");
    });
    html.push("</tbody></table></div></section>");

    html.push('<section class="panel"><div class="panel-header"><h3>' + (meta.readonly ? "记录详情" : "记录编辑") + "</h3><p>" + safe(meta.readonly ? "当前数据集只读，未来应由真实采集服务或数据库同步更新。" : "当前会通过 API 保存到 mock 仓储，未来可替换为 SQL 仓储。") + "</p></div>");
    if (selectedRow || !meta.readonly) {
      html.push(renderEditor(page.dataset, columns, draft, meta.readonly));
    } else {
      html.push('<div class="empty-detail"><strong>暂无可编辑记录</strong><p>请先新建一条记录。</p></div>');
    }
    html.push("</section></div>");

    return html.join("");
  }

  function renderEditor(datasetName, columns, draft, readonly) {
    var html = [];
    html.push('<div class="editor-form">');
    each(columns, function (column) {
      html.push('<label><span>' + safe(column) + '</span><input type="text" value="' + safeInputValue(draft[column]) + '" data-input-dataset="' + safe(datasetName) + '" data-input-field="' + safe(column) + '"' + ((readonly || column === "id") ? " disabled" : "") + "></label>");
    });
    html.push('<div class="form-actions">');
    if (!readonly) {
      html.push('<button class="primary-btn" data-action="save-row" data-dataset="' + safe(datasetName) + '">保存</button>');
      html.push('<button class="danger-btn" data-action="delete-row" data-dataset="' + safe(datasetName) + '"' + (draft.id ? "" : " disabled") + '>删除</button>');
    }
    html.push("</div></div>");
    return html.join("");
  }

  function renderCostSummary() {
    var rows = state.costRun.rows || [];
    var selected = state.currentCostDetails;
    var selectedMeta = selected && selected.meta ? selected.meta : null;
    var detailRows = selected && selected.rows ? selected.rows : [];
    var html = [];

    html.push('<section class="panel"><div class="panel-header"><h3>轧钢成本计算总表</h3><p>按钢种、厚度索引、宽度索引汇总投料与产量，计算成材率、原料成本、变动加工费、固定费用和制造成本。</p></div>');
    html.push('<div class="cost-runner">');
    html.push(renderSelectControl("line", "子系统", state.costRun.line, [{ value: "lj", label: "炉卷" }, { value: "rz", label: "1780" }], "cost"));
    html.push(renderSelectControl("dimension", "核算维度", state.costRun.dimension, [{ value: "bySpec", label: "钢种规格" }, { value: "byGrade", label: "钢种" }, { value: "bySeries", label: "系列" }, { value: "byPinzhong", label: "品种" }], "cost"));
    html.push(renderInputControl("startDate", "开始日期", state.costRun.startDate, "date", "cost"));
    html.push(renderInputControl("endDate", "结束日期", state.costRun.endDate, "date", "cost"));
    html.push('<button class="primary-btn" data-action="run-cost">' + (state.costRun.loading ? "计算中..." : "执行核算") + "</button></div>");
    html.push('<div class="callout"><strong>当前说明</strong><span>成本结果来自 Mock Cost Engine，但接口边界已经按未来服务化方式拆开：`POST /api/cost/run` 与 `GET /api/cost/detail`。</span></div>');
    html.push('<div class="table-wrap"><table><thead><tr><th>显示名称</th><th>钢种</th><th>品种</th><th>系列</th><th>厚度</th><th>宽度</th><th>卷重</th><th>成材率</th><th>制造成本</th><th>售价</th><th>吨钢利润</th></tr></thead><tbody>');
    each(rows, function (row) {
      html.push('<tr class="' + (selectedMeta && selectedMeta.id === row.id ? "selected" : "") + '" data-cost-row="' + safe(row.id) + '">');
      html.push("<td>" + safe(row.name) + "</td><td>" + safe(row.grade) + "</td><td>" + safe(row.pinzhong) + "</td><td>" + safe(row.xilie) + "</td><td>" + safe(formatCell(row.thickness)) + "</td><td>" + safe(formatCell(row.width)) + "</td><td>" + safe(formatCell(row.coilWt)) + "</td><td>" + safe(formatCell(row.yieldRate)) + "</td><td>" + safe(formatCell(row.manufacturingCost)) + "</td><td>" + safe(formatCell(row.salePrice)) + "</td><td>" + safe(formatCell(row.profitPerTon)) + "</td>");
      html.push("</tr>");
    });
    html.push("</tbody></table></div>");

    html.push('<div class="detail-panel"><div class="detail-header"><div><strong>' + safe(selectedMeta ? selectedMeta.name : "成本明细") + "</strong><span>" + (selectedMeta ? "当前选中行对应的分项成本明细" : "选择一行查看明细") + '</span></div></div><div class="detail-list">');
    if (detailRows.length) {
      each(detailRows, function (row) {
        html.push('<div class="detail-item"><div><strong>' + safe(row.item) + "</strong><p>" + safe(row.note) + "</p></div><span>" + safe(formatCell(row.amount)) + "</span></div>");
      });
    } else {
      html.push('<div class="empty-detail"><strong>暂无明细</strong><p>请从成本总表中选择一条非“合计”记录。</p></div>');
    }
    html.push("</div></div></section>");
    return html.join("");
  }

  function renderStandardCost() {
    var result = state.standardCost.result;
    var html = [];

    html.push('<section class="panel"><div class="panel-header"><h3>标准成本与平均标准成本</h3><p>按产量门槛筛选，提炼炉卷或1780的平均标准成本与标准成本。</p></div>');
    html.push('<div class="cost-runner">');
    html.push(renderSelectControl("line", "子系统", state.standardCost.line, [{ value: "rz", label: "1780" }, { value: "lj", label: "炉卷" }], "standard"));
    html.push(renderInputControl("startDate", "开始日期", state.standardCost.startDate, "date", "standard"));
    html.push(renderInputControl("endDate", "结束日期", state.standardCost.endDate, "date", "standard"));
    html.push('<button class="primary-btn" data-action="run-standard-cost">' + (state.standardCost.loading ? "生成中..." : "生成标准成本") + "</button></div>");

    if (!result) {
      html.push('<div class="empty-detail"><strong>尚未生成结果</strong><p>点击“生成标准成本”后，系统会调用 `/api/standard-cost/run` 返回两张结果表。</p></div></section>');
      return html.join("");
    }

    html.push('<div class="callout"><strong>筛选条件</strong><span>总产量阈值 ' + safe(String(result.totalThreshold)) + '，单钢种最小产量 ' + safe(String(result.singleThreshold)) + '，入选期间 ' + safe((result.selectedPeriods || []).join(", ") || "无") + "。</span></div>");
    html.push('<div class="two-column"><section class="panel"><div class="panel-header"><h3>平均标准成本</h3><p>按入选样本加权平均。</p></div><div class="table-wrap"><table><thead><tr><th>钢种</th><th>品种</th><th>系列</th><th>样本数</th><th>来源期间</th><th>成材率</th><th>工序成本</th><th>制造成本</th></tr></thead><tbody>');
    each(result.averageRows || [], function (row) {
      html.push("<tr><td>" + safe(row.grade) + "</td><td>" + safe(row.pinzhong) + "</td><td>" + safe(row.xilie) + "</td><td>" + safe(formatCell(row.sampleCount)) + "</td><td>" + safe(row.sourcePeriods) + "</td><td>" + safe(formatCell(row.yieldRate)) + "</td><td>" + safe(formatCell(row.processCost)) + "</td><td>" + safe(formatCell(row.manufacturingCost)) + "</td></tr>");
    });
    html.push('</tbody></table></div></section>');

    html.push('<section class="panel"><div class="panel-header"><h3>标准成本</h3><p>按候选样本中制造成本最低值提炼。</p></div><div class="table-wrap"><table><thead><tr><th>钢种</th><th>入选期间</th><th>成材率</th><th>工序成本</th><th>制造成本</th><th>试样费</th></tr></thead><tbody>');
    each(result.standardRows || [], function (row) {
      html.push("<tr><td>" + safe(row.grade) + "</td><td>" + safe(row.selectedPeriod) + "</td><td>" + safe(formatCell(row.yieldRate)) + "</td><td>" + safe(formatCell(row.processCost)) + "</td><td>" + safe(formatCell(row.manufacturingCost)) + "</td><td>" + safe(formatCell(row.sampleCost)) + "</td></tr>");
    });
    html.push("</tbody></table></div></section></div></section>");
    return html.join("");
  }

  function renderSchedulePage(page) {
    var scheduleState = state.schedules[page.line];
    var result = scheduleState.result;
    var paramsPayload = state.datasets[page.paramsDataset];
    var paramsRows = paramsPayload && paramsPayload.rows ? paramsPayload.rows : [];
    var html = [];

    html.push('<div class="two-column"><section class="panel"><div class="panel-header"><h3>' + safe(page.title) + "</h3><p>映射 " + safe(page.line === "lj" ? "JSLJSKB" : "RZSKB") + " 的节拍参数和顺序推演逻辑，当前用伪数据模拟时刻表生成结果。</p></div>");
    html.push('<div class="cost-runner">' + renderInputControl("startDate", "开始时刻", scheduleState.startDate, "datetime-local", "schedule-" + page.line) + '<button class="primary-btn" data-action="run-schedule" data-line="' + safe(page.line) + '">' + (scheduleState.loading ? "生成中..." : "生成排程") + "</button></div>");

    if (result) {
      html.push('<div class="callout"><strong>结果说明</strong><span>' + safe((result.notes || []).join(" ")) + '</span></div>');
      html.push('<div class="table-wrap"><table><thead><tr><th>板坯号</th><th>钢种</th><th>厚度</th><th>宽度</th><th>装炉开始</th><th>出炉结束</th><th>开轧</th><th>终轧</th><th>冷却完成</th><th>精整完成</th></tr></thead><tbody>');
      each(result.rows || [], function (row) {
        html.push("<tr><td>" + safe(row.slabNo) + "</td><td>" + safe(row.grade) + "</td><td>" + safe(formatCell(row.thickness)) + "</td><td>" + safe(formatCell(row.width)) + "</td><td>" + safe(row.funcStart) + "</td><td>" + safe(row.funcEnd) + "</td><td>" + safe(row.millStart) + "</td><td>" + safe(row.millEnd) + "</td><td>" + safe(row.coldEnd) + "</td><td>" + safe(row.finishEnd) + "</td></tr>");
      });
      html.push("</tbody></table></div>");
    } else {
      html.push('<div class="empty-detail"><strong>尚未生成排程</strong><p>点击“生成排程”后会调用 `/api/schedules/run` 返回推演后的时刻表。</p></div>');
    }
    html.push("</section>");

    html.push('<section class="panel"><div class="panel-header"><h3>当前节拍参数</h3><p>这些参数来自 `' + safe(page.paramsDataset) + '` 数据集，后续可直接替换成真实数据库配置表。</p></div><div class="detail-list">');
    each(paramsRows, function (row) {
      html.push('<div class="detail-item"><div><strong>' + safe(row.stepName) + "</strong><p>" + safe(row.note) + "</p></div><span>" + safe(formatCell(row.minutes)) + " 分钟</span></div>");
    });
    html.push("</div></section></div>");
    return html.join("");
  }

  function renderUserManagement() {
    var payload = state.userManagement.payload;
    var isAdmin = payload && payload.isAdmin;
    var rows = payload ? payload.rows || [] : [];
    var draft = state.userManagement.draft || (rows[0] ? cloneRow(rows[0]) : { account: "", password: "", group: "" });
    var groups = state.userManagement.groups || [];
    var html = [];
    html.push('<div class="two-column user-management"><section class="panel table-panel"><div class="panel-header"><h3>账户信息</h3><p>' + (isAdmin ? '系统管理员可维护全部账户、密码与组归属。' : '当前账户仅可查看本人信息并修改自己的密码。') + '</p></div>');
    if (isAdmin) { html.push('<div class="toolbar"><button class="primary-btn" data-action="new-user">新增用户</button></div>'); }
    html.push('<div class="table-wrap"><table><thead><tr><th>账户</th><th>当前密码</th><th>组归属</th></tr></thead><tbody>');
    each(rows, function (row) { html.push('<tr class="' + (String(draft.id) === String(row.id) ? 'selected' : '') + '" data-user-row="' + safe(row.id) + '"><td>' + safe(row.account) + '</td><td class="password-cell">' + safe(row.password) + '</td><td>' + safe(row.group) + '</td></tr>'); });
    html.push('</tbody></table></div></section><section class="panel"><div class="panel-header"><h3>' + (isAdmin ? '账户维护' : '我的账户') + '</h3><p>当前账号：' + safe(state.session.user.account) + ' · 组归属：' + safe(state.session.user.group) + '</p></div>');
    html.push('<div class="editor-form"><label><span>账户</span><input name="user-account-' + safe(draft.id || 'new') + '" autocomplete="off" data-user-field="account" value="' + safeInputValue(draft.account) + '"' + (isAdmin ? '' : ' disabled') + '></label>');
    if (isAdmin) { html.push('<label><span>密码</span><input name="user-password-' + safe(draft.id || 'new') + '" type="password" autocomplete="new-password" data-user-field="password" value="" placeholder="新建时必填；留空则保留原密码"></label><label><span>组归属</span><select data-user-field="group"><option value=""' + (draft.group ? '' : ' selected') + '>请选择用户组</option>' + groups.map(function (group) { return '<option value="' + safe(group) + '"' + (group === draft.group ? ' selected' : '') + '>' + safe(group) + '</option>'; }).join('') + '</select></label>'); }
    html.push('<div class="form-actions">');
    if (isAdmin) { html.push('<button class="primary-btn" data-action="save-user">保存账户</button><button class="danger-btn" data-action="delete-user"' + (draft.id ? '' : ' disabled') + '>删除账户</button>'); }
    html.push('<button class="secondary-btn" data-action="show-password-form">修改密码</button></div></div>');
    html.push('<div class="password-form ' + (state.userManagement.showPassword ? 'open' : '') + '"><label><span>原密码</span><input type="password" data-password-field="oldPassword"></label><label><span>新密码</span><input type="password" data-password-field="newPassword"></label><button class="primary-btn" data-action="change-password">确认修改</button></div>');
    if (state.userManagement.message) { html.push('<div class="user-message ' + (state.userManagement.messageType === 'error' ? 'error' : '') + '">' + safe(state.userManagement.message) + '</div>'); }
    html.push('</section></div>');
    return html.join('');
  }

  function renderUserGroups() {
    var groups = state.userManagement.groups || [];
    var html = ['<section class="panel"><div class="panel-header"><h3>用户组管理</h3><p>当前已配置的用户组。用户组增删将在接入真实权限仓储后开放。</p></div><div class="group-grid">'];
    each(groups, function (group) { html.push('<div class="group-item"><strong>' + safe(group) + '</strong><span>系统用户组</span></div>'); });
    html.push('</div></section>');
    return html.join('');
  }

  function bindEvents() {
    bindClick("[data-action='login']", function () {
      var account = app.querySelector('[name="account"]');
      var password = app.querySelector('[name="password"]');
      loginWithCredentials(account ? account.value : '', password ? password.value : '');
    });

    bindClick("[data-action='logout']", function () {
      state.session = null;
      state.userManagement = { payload: null, draft: null, groups: [] };
      render();
    });

    bindClick("[data-menu-toggle]", function (button) {
      var menuId = button.getAttribute("data-menu-toggle");
      state.expandedMenus[menuId] = !state.expandedMenus[menuId];
      render();
    });

    bindClick("[data-nav]", function (button) {
      navigateTo(button.getAttribute("data-nav"));
    });

    bindClick("[data-action='retry-bootstrap']", function () {
      state.error = "";
      state.loading = true;
      render();
      refreshBootstrap(function (error) {
        state.loading = false;
        state.error = error ? (error.message || "重连失败") : "";
        render();
      });
    });

    bindClick("[data-action='load-dataset']", function (button) {
      ensureDataset(button.getAttribute("data-dataset"), true, function () {
        render();
      });
    });

    bindClick("[data-action='reload-dataset']", function (button) {
      var dataset = button.getAttribute("data-dataset");
      ensureDataset(dataset, true, function () {
        refreshBootstrap(function () {
          render();
        });
      });
    });

    bindClick("[data-select-row]", function (rowButton) {
      var parts = rowButton.getAttribute("data-select-row").split(":");
      var datasetName = parts[0];
      var rowId = parts[1];
      var payload = state.datasets[datasetName];
      var row = findRowById(payload && payload.rows ? payload.rows : [], rowId);
      state.selectedRows[datasetName] = rowId;
      state.drafts[datasetName] = cloneRow(row);
      render();
    });

    bindInputs("[data-input-dataset]", function (input) {
      var dataset = input.getAttribute("data-input-dataset");
      var field = input.getAttribute("data-input-field");
      if (!state.drafts[dataset]) {
        state.drafts[dataset] = {};
      }
      state.drafts[dataset][field] = input.value;
    });

    bindInputs("[data-query-dataset]", function (input) {
      state.datasetQueries[input.getAttribute("data-query-dataset")] = input.value;
      render();
    });

    bindClick("[data-action='import-excel']", function (button) {
      var dataset = button.getAttribute("data-dataset");
      var input = findDatasetFileInput(dataset);
      if (input) {
        input.click();
      }
    });

    each(app.querySelectorAll("[data-file-dataset]"), function (input) {
      input.onchange = function () {
        importExcelFile(input.getAttribute("data-file-dataset"), input.files && input.files[0]);
      };
    });

    bindClick("[data-action='export-excel']", function (button) {
      exportExcelFile(button.getAttribute("data-dataset"));
    });

    bindClick("[data-action='new-row']", function (button) {
      var dataset = button.getAttribute("data-dataset");
      var datasetState = state.datasets[dataset] || {};
      var datasetMeta = datasetState.meta || {};
      var columns = datasetMeta.columns || [];
      state.selectedRows[dataset] = null;
      state.drafts[dataset] = makeEmptyRow(columns);
      render();
    });

    bindClick("[data-action='save-row']", function (button) {
      var dataset = button.getAttribute("data-dataset");
      if (isLocalDataset(dataset)) {
        saveLocalRow(dataset);
        return;
      }
      apiPost("/datasets/" + dataset, state.drafts[dataset] || {}, function (error, saved) {
        if (error) {
          showError(error);
          return;
        }
        state.datasets[dataset] = saved;
        if (saved.saved && saved.saved.id) {
          state.selectedRows[dataset] = saved.saved.id;
          state.drafts[dataset] = cloneRow(saved.saved);
        }
        refreshBootstrap(function () {
          render();
        });
      });
    });

    bindClick("[data-action='delete-row']", function (button) {
      var dataset = button.getAttribute("data-dataset");
      var row = state.drafts[dataset];
      if (!row || !row.id) {
        return;
      }
      if (isLocalDataset(dataset)) {
        deleteLocalRow(dataset, row.id);
        return;
      }
      apiDelete("/datasets/" + dataset + "/" + row.id, function (error, payload) {
        var first;
        var payloadMeta;
        if (error) {
          showError(error);
          return;
        }
        state.datasets[dataset] = payload;
        first = payload.rows && payload.rows.length ? payload.rows[0] : null;
        payloadMeta = payload.meta || {};
        state.selectedRows[dataset] = first ? first.id : null;
        state.drafts[dataset] = first ? cloneRow(first) : makeEmptyRow(payloadMeta.columns || []);
        refreshBootstrap(function () {
          render();
        });
      });
    });

    bindClick("[data-action='collect-row']", function (button) {
      var dataset = button.getAttribute("data-dataset");
      apiPost("/datasets/" + dataset + "/collect", {}, function (error, payload) {
        if (error) {
          showError(error);
          return;
        }
        state.datasets[dataset] = payload;
        refreshBootstrap(function () {
          render();
        });
      });
    });

    bindClick("[data-cost-row]", function (rowButton) {
      var row = findRowById(state.costRun.rows || [], rowButton.getAttribute("data-cost-row"));
      if (!row || !row.detailKey) {
        return;
      }
      apiGet("/cost/detail?detailKey=" + encodeURIComponent(row.detailKey), function (error, payload) {
        if (error) {
          showError(error);
          return;
        }
        state.currentCostDetails = { meta: row, rows: payload.rows || [] };
        render();
      });
    });

    bindInputs("[data-scope='cost']", function (input) {
      state.costRun[input.getAttribute("data-field")] = input.value;
    });

    bindClick("[data-action='run-cost']", function () {
      runCost();
    });

    bindInputs("[data-scope='standard']", function (input) {
      state.standardCost[input.getAttribute("data-field")] = input.value;
    });

    bindClick("[data-action='run-standard-cost']", function () {
      runStandardCost();
    });

    bindInputs("[data-scope^='schedule-']", function (input) {
      var scope = input.getAttribute("data-scope");
      var line = scope.replace("schedule-", "");
      state.schedules[line][input.getAttribute("data-field")] = input.value;
    });

    bindClick("[data-action='run-schedule']", function (button) {
      runSchedule(button.getAttribute("data-line"), true);
    });

    bindClick("[data-user-row]", function (rowButton) {
      var row = findRowById((state.userManagement.payload || {}).rows || [], rowButton.getAttribute('data-user-row'));
      state.userManagement.draft = cloneRow(row);
      state.userManagement.isCreating = false;
      state.userManagement.showPassword = false;
      render();
    });

    bindInputs('[data-user-field]', function (input) {
      if (!state.userManagement.draft) { state.userManagement.draft = {}; }
      state.userManagement.draft[input.getAttribute('data-user-field')] = input.value;
    });

    bindInputs('[data-password-field]', function (input) {
      state.userManagement[input.getAttribute('data-password-field')] = input.value;
    });

    bindClick("[data-action='new-user']", function () {
      state.userManagement.draft = { id: 0, account: '', password: '', group: '' };
      state.userManagement.isCreating = true;
      state.userManagement.showPassword = false;
      state.userManagement.message = '';
      render();
    });

    bindClick("[data-action='save-user']", function () {
      apiPost('/auth/users/save', { token: state.session.token, user: state.userManagement.draft }, function (error) {
        if (error) { showUserMessage(error.message || '账户保存失败', 'error'); return; }
        state.userManagement.message = '账户已保存。';
        state.userManagement.messageType = 'success';
        if (state.userManagement.isCreating) {
          state.userManagement.draft = { id: 0, account: '', password: '', group: '' };
        }
        loadUserManagement(function () { render(); });
      });
    });

    bindClick("[data-action='delete-user']", function () {
      var draft = state.userManagement.draft || {};
      if (!draft.id) { return; }
      apiPost('/auth/users/delete', { token: state.session.token, id: draft.id }, function (error) {
        if (error) { showUserMessage(error.message || '账户删除失败', 'error'); return; }
        state.userManagement.draft = null;
        state.userManagement.isCreating = false;
        state.userManagement.message = '账户已删除。';
        state.userManagement.messageType = 'success';
        loadUserManagement(function () { render(); });
      });
    });

    bindClick("[data-action='show-password-form']", function () {
      state.userManagement.showPassword = !state.userManagement.showPassword;
      render();
    });

    bindClick("[data-action='change-password']", function () {
      var draft = state.userManagement.draft || {};
      apiPost('/auth/password', { token: state.session.token, id: draft.id, oldPassword: state.userManagement.oldPassword || '', newPassword: state.userManagement.newPassword || '' }, function (error) {
        if (error) { showUserMessage(error.message || '密码修改失败', 'error'); return; }
        state.userManagement.oldPassword = '';
        state.userManagement.newPassword = '';
        state.userManagement.showPassword = false;
        window.alert('密码已修改');
        render();
      });
    });
  }

  function loadUserManagement(callback) {
    apiPost('/auth/users', { token: state.session.token }, function (error, payload) {
      if (error) { done(callback, error); showError(error); return; }
      state.userManagement.payload = payload;
      if (!state.userManagement.isCreating && (!state.userManagement.draft || !findRowById(payload.rows || [], state.userManagement.draft.id))) {
        state.userManagement.draft = cloneRow((payload.rows || [])[0] || {});
      }
      apiGet('/auth/groups', function (groupError, groupPayload) {
        state.userManagement.groups = groupError ? [] : (groupPayload.rows || []).map(function (item) { return item.group; });
        done(callback, groupError, payload);
      });
    });
  }

  function showUserMessage(message, type) {
    state.userManagement.message = message;
    state.userManagement.messageType = type || 'error';
    render();
  }

  function runCost() {
    state.costRun.loading = true;
    render();
    apiPost("/cost/run", state.costRun, function (error, result) {
      state.costRun.loading = false;
      if (error) {
        showError(error);
        return;
      }
      state.costRun.rows = result.rows || [];
      state.currentCostDetails = null;
      render();
    });
  }

  function runStandardCost() {
    state.standardCost.loading = true;
    render();
    apiPost("/standard-cost/run", state.standardCost, function (error, result) {
      state.standardCost.loading = false;
      if (error) {
        showError(error);
        return;
      }
      state.standardCost.result = result;
      render();
    });
  }

  function runSchedule(line, renderAfter) {
    var paramsName = line === "lj" ? "ljScheduleParams" : "rzScheduleParams";
    if (renderAfter !== false) {
      renderAfter = true;
    }

    state.schedules[line].loading = true;
    if (renderAfter) {
      render();
    }

    ensureDataset(paramsName, function (datasetError) {
      if (datasetError) {
        state.schedules[line].loading = false;
        showError(datasetError);
        return;
      }

      apiPost("/schedules/run", { line: line, startDate: state.schedules[line].startDate }, function (error, result) {
        state.schedules[line].loading = false;
        if (error) {
          showError(error);
          return;
        }
        state.schedules[line].result = result;
        if (renderAfter) {
          render();
        }
      });
    });
  }

  function renderSelectControl(field, label, value, options, scope) {
    var html = [];
    html.push("<label><span>" + safe(label) + '</span><select data-scope="' + safe(scope) + '" data-field="' + safe(field) + '">');
    each(options, function (option) {
      html.push('<option value="' + safe(option.value) + '"' + (String(option.value) === String(value) ? " selected" : "") + ">" + safe(option.label) + "</option>");
    });
    html.push("</select></label>");
    return html.join("");
  }

  function renderInputControl(field, label, value, type, scope) {
    return '<label><span>' + safe(label) + '</span><input data-scope="' + safe(scope) + '" data-field="' + safe(field) + '" type="' + safe(type) + '" value="' + safeInputValue(value) + '"></label>';
  }

  function describePage(page) {
    if (page.kind === "dashboard") {
      return "以 第二炼轧厂\\ZXCBXT 为分析入口重组后的 B/S 模块总览";
    }
    if (page.kind === "costSummary") {
      return "面向未来服务化的成本核算总表与明细联动";
    }
    if (page.kind === "standardCost") {
      return "标准成本与平均标准成本的筛选与提炼";
    }
    if (page.kind === "schedule") {
      return "工艺时刻表与节拍推演";
    }
    return "数据先经 API，再进入仓储层，未来可切换到真实数据库";
  }

  function countValues(keys, datasetsMeta) {
    var total = 0;
    each(keys, function (key) {
      var meta = datasetsMeta[key] || {};
      total += Number(meta.count || 0);
    });
    return total;
  }

  function inferColumns(rows) {
    if (!rows || !rows.length) {
      return [];
    }
    return Object.keys(rows[0]);
  }

  function filterRows(rows, query) {
    var keyword = String(query || "").trim().toLowerCase();
    if (!keyword) {
      return rows || [];
    }
    return (rows || []).filter(function (row) {
      return Object.keys(row).some(function (key) {
        return String(row[key] === null || row[key] === undefined ? "" : row[key]).toLowerCase().indexOf(keyword) >= 0;
      });
    });
  }

  function isLocalDataset(dataset) {
    return String(dataset || "").indexOf("local:") === 0;
  }

  function findDatasetFileInput(dataset) {
    var inputs = app.querySelectorAll("[data-file-dataset]");
    var found = null;
    each(inputs, function (input) {
      if (!found && input.getAttribute("data-file-dataset") === dataset) {
        found = input;
      }
    });
    return found;
  }

  function saveLocalRow(dataset) {
    var payload = state.datasets[dataset];
    var draft = cloneRow(state.drafts[dataset] || {});
    var rows = payload.rows || [];
    var id = Number(draft.id || 0);
    var found = false;
    if (!id) {
      id = rows.reduce(function (max, row) { return Math.max(max, Number(row.id) || 0); }, 0) + 1;
      draft.id = id;
    }
    payload.rows = rows.map(function (row) {
      if (Number(row.id) === id) {
        found = true;
        return draft;
      }
      return row;
    });
    if (!found) {
      payload.rows.push(draft);
    }
    state.selectedRows[dataset] = id;
    state.drafts[dataset] = cloneRow(draft);
    render();
  }

  function deleteLocalRow(dataset, id) {
    var payload = state.datasets[dataset];
    payload.rows = (payload.rows || []).filter(function (row) { return Number(row.id) !== Number(id); });
    var first = payload.rows[0] || makeEmptyRow(payload.meta.columns || []);
    state.selectedRows[dataset] = first.id || null;
    state.drafts[dataset] = cloneRow(first);
    render();
  }

  function exportExcelFile(dataset) {
    var payload = state.datasets[dataset];
    var rows = filterRows(payload ? payload.rows : [], state.datasetQueries[dataset] || "");
    var columns = payload && payload.meta ? payload.meta.columns : inferColumns(rows);
    var lines = [columns.map(excelCell).join("\t")];
    rows.forEach(function (row) {
      lines.push(columns.map(function (column) { return excelCell(row[column]); }).join("\t"));
    });
    var blob = new Blob(["\ufeff" + lines.join("\r\n")], { type: "application/vnd.ms-excel;charset=utf-8" });
    var url = URL.createObjectURL(blob);
    var link = document.createElement("a");
    link.href = url;
    link.download = (payload && payload.meta && payload.meta.title ? payload.meta.title : dataset) + ".xls";
    link.click();
    URL.revokeObjectURL(url);
  }

  function excelCell(value) {
    return String(value === null || value === undefined ? "" : value).replace(/[\t\r\n]/g, " ");
  }

  function importExcelFile(dataset, file) {
    if (!file) {
      return;
    }
    var reader = new FileReader();
    reader.onload = function () {
      var rows = parseDelimitedText(String(reader.result || ""));
      if (!rows.length) {
        showError(new Error("文件中没有可导入的记录"));
        return;
      }
      if (isLocalDataset(dataset)) {
        var payload = state.datasets[dataset];
        var columns = payload.meta.columns || rows[0];
        rows.slice(1).forEach(function (values) {
          var row = { id: nextLocalId(payload.rows) };
          columns.forEach(function (column, index) { row[column] = values[index] || ""; });
          payload.rows.push(row);
        });
        render();
        return;
      }
      importApiRows(dataset, rows, 1, rows[0]);
    };
    reader.readAsText(file, "utf-8");
  }

  function parseDelimitedText(text) {
    return text.replace(/^\ufeff/, "").split(/\r?\n/).filter(function (line) { return line.trim(); }).map(function (line) {
      return line.indexOf("\t") >= 0 ? line.split("\t") : parseCsvLine(line);
    });
  }

  function parseCsvLine(line) {
    var values = [];
    var value = "";
    var quoted = false;
    for (var i = 0; i < line.length; i += 1) {
      var ch = line[i];
      if (ch.charCodeAt(0) === 34) {
        if (quoted && line[i + 1] && line[i + 1].charCodeAt(0) === 34) { value += String.fromCharCode(34); i += 1; } else { quoted = !quoted; }
      } else if (ch === "," && !quoted) {
        values.push(value);
        value = "";
      } else {
        value += ch;
      }
    }
    values.push(value);
    return values;
  }

  function importApiRows(dataset, rows, index, columns) {
    if (index >= rows.length) {
      ensureDataset(dataset, true, function () { render(); });
      return;
    }
    var values = rows[index];
    var payload = {};
    columns.forEach(function (column, columnIndex) { payload[column] = values[columnIndex] || ""; });
    delete payload.id;
    apiPost("/datasets/" + dataset, payload, function (error) {
      if (error) {
        showError(error);
        return;
      }
      importApiRows(dataset, rows, index + 1, columns);
    });
  }

  function nextLocalId(rows) {
    return (rows || []).reduce(function (max, row) { return Math.max(max, Number(row.id) || 0); }, 0) + 1;
  }

  function cloneRow(row) {
    return row ? JSON.parse(JSON.stringify(row)) : {};
  }

  function makeEmptyRow(columns) {
    var row = {};
    each(columns, function (column) {
      row[column] = column === "id" ? 0 : "";
    });
    return row;
  }

  function formatCell(value) {
    var mapped;
    if (value === null || value === undefined || value === "") {
      return "-";
    }
    mapped = {
      lj: "炉卷",
      rz: "1780",
      total_output: "总产量",
      min_grade_output: "单钢种最小产量",
      carbon_steel: "普碳钢",
      alloy_steel: "低合金钢",
      hot_roll_commercial: "热轧商品卷",
      cold_roll_feed: "冷轧基料",
      low_carbon: "低碳系列",
      structural_series: "结构钢系列",
      commercial_series: "商品卷系列",
      deep_draw_series: "深冲系列",
      heating: "加热",
      rolling: "轧制",
      packing: "包装",
      mixed_gas: "混合煤气",
      work_roll: "工作辊",
      soft_water: "软水",
      packing_strip: "包装钢带",
      heating_share: "加热分摊",
      rolling_share: "轧制分摊",
      roll_share: "辊耗分摊",
      avg_share: "平均分摊",
      yield_rate: "成材率",
      recycle: "回收",
      scale: "氧化铁皮",
      peak_flat_valley: "峰平谷",
      usage_share: "用量分摊"
    };
    return mapped[value] || value;
  }

  function safe(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function safeInputValue(value) {
    return safe(String(value == null ? "" : value)).replace(/\n/g, "&#10;");
  }

  function apiGet(path, callback) {
    apiRequest("GET", path, null, callback);
  }

  function apiPost(path, payload, callback) {
    apiRequest("POST", path, payload, callback);
  }

  function apiDelete(path, callback) {
    apiRequest("DELETE", path, null, callback);
  }

  function apiRequest(method, path, payload, callback) {
    var xhr = new XMLHttpRequest();
    xhr.open(method, API_BASE + path, true);
    xhr.setRequestHeader("Content-Type", "application/json");
    xhr.onreadystatechange = function () {
      var data;
      if (xhr.readyState !== 4) {
        return;
      }

      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          data = xhr.responseText ? JSON.parse(xhr.responseText) : {};
          done(callback, null, data);
        } catch (parseError) {
          done(callback, parseError);
        }
        return;
      }

      done(callback, new Error(xhr.responseText || ("HTTP " + xhr.status)));
    };

    xhr.onerror = function () {
      done(callback, new Error("无法连接到本地服务，请确认 8091 端口服务已启动。"));
    };

    try {
      xhr.send(payload ? JSON.stringify(payload) : null);
    } catch (sendError) {
      done(callback, sendError);
    }
  }

  function bindClick(selector, handler) {
    var nodes = app.querySelectorAll(selector);
    each(nodes, function (node) {
      node.onclick = function () {
        handler(node);
      };
    });
  }

  function bindInputs(selector, handler) {
    var nodes = app.querySelectorAll(selector);
    each(nodes, function (node) {
      node.onchange = function () {
        handler(node);
      };
      node.onkeyup = function () {
        handler(node);
      };
    });
  }

  function showError(error) {
    state.error = error && error.message ? error.message : String(error || "操作失败");
    state.loading = false;
    render();
  }

  function findRowById(rows, id) {
    var found = null;
    each(rows || [], function (row) {
      if (found === null && String(row.id) === String(id)) {
        found = row;
      }
    });
    return found;
  }

  function each(items, iterator) {
    var i;
    if (!items) {
      return;
    }
    for (i = 0; i < items.length; i += 1) {
      iterator(items[i], i);
    }
  }

  function done(callback, error, value) {
    if (typeof callback === "function") {
      callback(error, value);
    }
  }
})();
