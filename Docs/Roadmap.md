# CombinedChartFramework Roadmap

本文从架构演进角度定义当前项目的中短期路线图。  
它不是功能 wishlist，而是围绕“能否成为可持续演进的图表框架”来排序优先级。

## 1. 当前阶段判断

截至 2026-03-10，项目已经完成了一个具备框架雏形的 `CombinedChart` 组件，具备：

- 公共 API
- 数据与状态分层
- 双渲染路径
- 双滚动路径
- 单元测试与快照测试

但它仍处于“单组件工程向平台化框架过渡”的阶段。  
因此路线图的首要目标不是继续叠加图表种类，而是先把基础架构做稳。

## 1.1 终态能力版图（对齐 Arch.md）

根据 `Arch.md`，路线图的终点不是“把 `CombinedChartView` 做得更复杂”，而是形成 `ChartKit` 多图表平台。  
最终至少要支持：

- `CombinedChart`
- `LineChart`
- `BarChart`
- `PieChart`
- `AreaChart`
- `CandlestickChart`

并且终态仓库结构应满足：

- Sample App 只负责 demo、验证、调试
- 核心逻辑进入 `ChartKit` Swift Package
- Package 内按四层组织：
  - `Foundation`
  - `Components`
  - `SharedUI`
  - `Compatibility`

这意味着后续所有阶段都必须围绕“如何支撑多图表平台”来设计，而不是只围绕当前 `CombinedChart` 的局部便利性。

## 2. 路线图原则

后续演进建议遵循以下原则：

1. 先做平台化基础，再扩功能面。
2. 先收敛事实来源，再扩展交互能力。
3. 先建立模块边界，再扩展多图表组件。
4. 先稳定 API，再追求抽象美观。

## 3. 阶段一：基础稳定化

### 目标

把当前仓库从“可用工程”提升为“可持续维护工程”。

### 重点工作

- 修复 `Package.swift` 平台声明与 UIKit 依赖不一致问题
- 明确 iOS 16 / iOS 17 的默认渲染与滚动策略
- 清理文档占位项并形成统一文档集
- 把当前 `swift test`、UI 快照测试纳入稳定验证流程
- 规范 `CHANGELOG.md` 内容，恢复为可发布格式

### 退出标准

- Package 在声明支持的平台上可以稳定构建
- `Docs/` 形成可交付文档集
- 至少一条标准测试路径可在本地和 CI 稳定运行
- 已知高优先级稳定性问题被显式记录并可复现

## 4. 阶段二：模块化拆分

### 目标

把当前“目录分层”升级为“真实模块分层”。

### 推荐模块边界

- `Foundation`
- `Components/CombinedChart`
- `Components/LineChart`
- `Components/BarChart`
- `Components/PieChart`
- `SharedUI`
- `Compatibility`

### 重点工作

- 将 `PagerState`、`SelectionResolver`、`DragState`、domain/tick 计算等迁移到基础层
- 将 `YAxisLabels`、pager UI 等复用视图迁移到共享 UI 层
- 将 UIKit 桥接和平台条件编译放入兼容层
- 让 `CombinedChartView` 只保留 `Components/CombinedChart` 内的组合和公共入口职责
- 为未来 `LineChart`、`BarChart`、`PieChart` 预留独立组件边界，而不是继续扩展单一组件目录

### 退出标准

- 基础算法不再依赖 `CombinedChartView` 命名空间
- UIKit 依赖不再直接泄漏进所有平台源码路径
- 至少一个内部模块可以被未来其它图表直接复用

## 5. 阶段三：渲染抽象统一

### 目标

降低 `Charts` 与 `Canvas` 双实现的长期维护成本。

### 重点工作

- 抽象统一的 marks/overlay 几何语义
- 将柱段、线段、选择态、axis 布局描述中间化
- 建立 render parity 验证用例
- 明确“主引擎”与“兼容引擎”的产品策略

### 关键决策

此阶段必须回答一个问题：

- `Charts` 是主路径，`Canvas` 是兜底
- 还是 `Canvas` 作为可控主路径，`Charts` 用于平台集成

如果这个决策长期不做，渲染复杂度会持续上升。

### 退出标准

- 两条渲染路径共享同一套上层几何语义
- 核心选择态与坐标逻辑不再重复实现
- 视觉回归测试可以区分出引擎间差异

## 6. 阶段四：交互架构收敛

### 目标

让分页、拖拽、可见起点和选择态围绕单一事实来源运行。

### 重点工作

- 统一 viewport 的主状态模型
- 收敛 `startIndex` 与 `contentOffsetX` 的职责边界
- 明确 SwiftUI 与 UIKit 两种滚动实现的适用场景
- 把 `DebugState` 接入更稳定的诊断流程

### 推荐方向

后续应尽量避免多条并行推导链同时定义“当前可见位置”。  
最佳状态是：

- 偏移有单一来源
- pager 由偏移推导
- 可见起点由偏移推导
- 选择态和调试状态都消费同一事实源

### 退出标准

- 不同滚动实现下 pager 结果一致
- 调试态与屏幕内容一致
- 快速拖拽、翻页、切 tab 场景下无明显状态漂移

## 7. 阶段五：公共 API 稳定化

### 目标

为外部消费者提供一个足够稳定的 1.0 级 API 表面。

### 重点工作

- 完成 `viewSlots:` 的迁移和后续移除计划
- 明确公共类型与内部类型边界
- 形成 API 兼容承诺和废弃策略
- 统一 README、API Notes 与示例代码

### 退出标准

- 公共入口集合稳定
- 废弃项有明确移除窗口
- 新增功能不再随意暴露内部类型

## 8. 阶段六：扩展到多图表平台

### 目标

从 `CombinedChartFramework` 演进到更通用的 `ChartKit` 能力层。

### 优先扩展顺序

建议按以下顺序扩展，而不是同时展开：

1. `LineChart`
2. `BarChart`
3. `PieChart`
4. `AreaChart`
5. `CandlestickChart`

原因：

- `LineChart` 和 `BarChart` 与当前基础能力复用度最高
- `PieChart` 是 `Arch.md` 中明确要求支持的核心图表之一，应在第一轮多图表化中进入平台版图
- `AreaChart` 可在趋势线与填充能力成熟后自然演进
- `CandlestickChart` 对金融场景数据模型要求更高，应放在基础层成熟之后

### 退出标准

- 第二个图表类型无需复制 `CombinedChart` 大量内部实现
- 新图表复用基础模块而不是绕过基础模块
- 新增图表目录时不需要修改已有 chart component 的内部实现

## 9. 阶段七：工程化与产品化增强

### 目标

让组件具备更强的生产环境能力。

### 重点工作

- 大数据量性能治理
- downsampling 策略
- accessibility 和 VoiceOver 支持
- 主题系统与 design token 接入
- 预览数据和文档站点建设
- 版本发布、语义化变更记录、CI 发布流程

### 退出标准

- 可以面向多个业务团队稳定复用
- 性能和可访问性不再只是演示级水平

## 10. 不建议当前阶段优先做的事情

以下事项短期内不建议放到高优先级：

- 继续增加更多 tab 组合模式
- 在没有统一抽象前继续叠加视觉特效
- 在未模块化前直接扩展 4-5 种新图表
- 在平台边界未稳定前承诺更广的平台支持

这些工作会放大当前架构债务，而不会真正提升框架成熟度。

## 11. 建议的优先级排序

如果只能选最关键的五件事，推荐顺序如下：

1. 平台构建与兼容边界修正
2. 模块化拆分
3. 渲染抽象统一
4. 交互状态单一事实来源治理
5. API 稳定化

## 12. 结论

当前项目已经值得按“框架”而不是“Demo”来管理，但前提是路线图必须克制。  
短期真正重要的不是做更多图，而是先完成三项基础建设：

1. 稳定性
2. 模块化
3. 语义统一

这三项完成之后，再按 `Arch.md` 定义的终态逐步扩展到：

- `CombinedChart`
- `LineChart`
- `BarChart`
- `PieChart`
- `AreaChart`
- `CandlestickChart`

这样扩展多图表能力时，整体投入产出比才会显著改善。
