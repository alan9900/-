# 电机结构参数与形状联合优化｜MATLAB 复现执行任务书

**供 Codex 直接执行 · V1.0 · 2026-10-18**  
**本阶段目标：仅使用 MATLAB R2025a 完成原论文的参数/形状优化、数值结果评价与报告；Maxwell 独立仿真放在后续阶段。**

## 0. 边界与完成定义

研究对象：Wiesheu 等《Combined parameter and shape optimization of electric machines with isogeometric analysis》。本阶段用作者官方代码重新运行初始电机评价、结构参数优化、形状优化、先参数后形状的顺序优化、参数与形状联合优化；提取设计变量、永磁体面积、平均电磁转矩、转矩标准差、可行性、收敛过程和耗时。

**必须：** 固定官方源代码版本，检查环境/许可，识别真实脚本路径，先基线后优化，重新评价最终设计，将运行数据与论文 Table 3 / Fig. 9–11 对照，保存日志、图表、数据与结论。

**禁止：** 本阶段不使用 Maxwell、JMAG、COMSOL、FEMM，不做样机实验；不擅自修改物理模型、材料、目标函数、约束、采样角度而仍宣称严格复现；不得把作者历史结果冒充自己运行结果；不能从转矩波动下降推断整机效率提升。

**完成标准：** 至少真实运行初始电机评价和参数优化，条件允许时完成其余优化；每阶段记录状态、来源、数值、日志，失败环节如实标注。

## 1. 参考文献与代码来源

- 论文：Michael Wiesheu 等，*Combined parameter and shape optimization of electric machines with isogeometric analysis*, Optimization and Engineering, 26:1011–1038 (2025 卷期，2024 年在线发表)。
- DOI：https://doi.org/10.1007/s11081-024-09925-0
- Springer：https://link.springer.com/article/10.1007/s11081-024-09925-0
- 作者官方代码：https://github.com/MichaelWiesheu/MotorOptimization
- MATLAB：作者以 R2024a 测试；本项目在用户现有 R2025a 上尝试。
- 工具箱：Optimization Toolbox、Curve Fitting Toolbox、Global Optimization Toolbox。仓库附带 GeoPDEs 与 NURBS Toolbox 的代码快照。以 README 与源码为最终依据。
- 遵守仓库 GPL-3.0 等许可证和相关外部数据条款；引用作者成果。

原研究用二维非线性静磁模型、NURBS/IGA 求解和基于梯度的优化。研究核心为**永磁体面积、转矩标准差与平均转矩约束**，不是整机效率优化。

### 论文数字仅作参照（不得填写为本机结果）

- 初始平均转矩约 2.24 N·m。
- 联合优化目标平均转矩约束下限 2.3 N·m；单独形状与顺序优化的下限可能是 2.0 N·m，须以论文/代码核实。
- 联合优化：永磁体面积下降约 18.9%，转矩标准差下降约 99.0%；原论文其他方案的精确值与单位以 Table 3 为准。
- 转矩按同一组转子角度采样：0°、1°、…、29°（30 个点）；论文中部分面积指标采用四分之一对称模型的几何口径，须特别注意。

## 2. Codex 执行原则

1. **先阅读，后执行。** 阅读 README、LICENSE、论文方法与表格、所有入口脚本的调用/输入/保存逻辑。不要马上启动多小时优化。
2. **固定版本。** 保存上游 URL、commit SHA、克隆时间、MATLAB `version` 和 `ver` 结果。
3. **保持上游源码干净。** 自建 `reproduction/` 和 `reproduction_output/`，新脚本与结果写入其中。若 R2025a 兼容性修复不可避免，保留独立补丁/diff 和原因。
4. **先备份作者数据。** 检查 `OptimizationHistory.mat` 等原始归档是否会被覆写；任何可能改变文件的实验先在工作副本进行。
5. **严格区分来源。** 每张表图附 `provenance=local_run`、`author_archive` 或 `paper_reference`；从已有 MAT 文件画图不是重新运行优化。
6. **阶段性检查。** 环境审计 → 初始评价 → 参数优化 → 其余优化 → 统一重新评价 → 对照报告。
7. **不要造数。** MATLAB 不可调用、缺许可、运行超时或求解失败时，保存日志并说明障碍；只能报告真实已完成的工作。
8. **冒烟测试与正式复现分开。** 缩短迭代、降低精度、减少角度只允许作为 smoke test，结果不得列作严格复现。

## 3. Windows + MATLAB R2025a 环境

需要检查：
- MATLAB R2025a 能被 Codex 所在环境实际调用。若 Codex 仅在云端且不能访问本地 MATLAB，则只做源码静态审计、准备包装脚本和用户执行说明，不能声称已完成仿真。
- Optimization Toolbox、Curve Fitting Toolbox、Global Optimization Toolbox 可用且已授权。
- 现有仓库内 GeoPDEs 与 NURBS 代码快照正确配置。不要贸然覆盖成其他版本。
- 内存、磁盘空间及长时间优化运行权限可用。

在 MATLAB 命令窗口或 batch 内运行：

```matlab
version
ver
which fmincon -all
which fit -all
which ga -all
license('test','Optimization_Toolbox')
```

在指定工作目录执行：

```powershell
git clone https://github.com/MichaelWiesheu/MotorOptimization.git
cd MotorOptimization
git rev-parse HEAD
git status --short
```

**关键提醒：** 官方仓库 `results/` 下可能还有 `init_evaluations/`、`opt_evaluations/`、`opt_param/`、`opt_shape/`、`opt_param_then_shape/`、`opt_param_shape/` 等子目录。**禁止假设所有 .m 文件都在 results 根目录。** 必须先递归扫描真实路径、函数依赖和各脚本期望的工作目录。

MATLAB 扫描示例：

```matlab
repo = 'D:\MATLAB\MotorOptimization'; % 改成实际路径
files = dir(fullfile(repo, '**', '*.m'));
names = string({files.name});
wanted = ["eval_init.m","opt_param.m","opt_shape.m", ...
  "opt_param_then_shape.m","opt_param_shape.m", ...
  "eval_param_shape.m","eval_opt_torques.m"];
for s = wanted
    ix = find(names == s);
    if isempty(ix)
        fprintf('NOT FOUND: %s\n', s);
    else
        for k = ix
            fprintf('%s -> %s\n', s, fullfile(files(k).folder, files(k).name));
        end
    end
end
```

将扫描结果写入 `reproduction_output/SCRIPT_MAP.md`，逐项列出真实路径、输入 MAT 文件、输出文件、工作目录、依赖函数、是否读取/覆写作者归档、已核实的入口。

## 4. 分阶段运行与阶段验收

| 阶段 | 操作 | 最低交付物 | 通过条件 |
|---|---|---|---|
| A 环境审计 | 检查版本、工具箱、许可、代码目录、脚本调用 | ENVIRONMENT.md、SCRIPT_MAP.md、commit.txt | 入口与依赖明确 |
| B 初始评价 | 定位并运行 eval_init.m | baseline.mat、baseline_metrics.csv、baseline.log、几何图 | 电磁求解成功、数值有限 |
| C 参数优化 | 运行 opt_param.m | param_opt.mat、param_metrics.csv、param_opt.log | 获得终态变量、状态与指标 |
| D 形状优化 | 运行 opt_shape.m | shape_opt.mat、shape_metrics.csv、shape_opt.log | 终态几何可以重新评价 |
| E 顺序优化 | 运行 opt_param_then_shape.m | sequential_opt.mat、sequential_metrics.csv | 两个优化阶段数据保留 |
| F 联合优化 | 运行 opt_param_shape.m | combined_opt.mat、combined_metrics.csv、combined_opt.log | 有终态参数、控制点及求解记录 |
| G 统一重算 | 使用 eval_*、eval_opt_torques.m 等已确认入口 | metrics_all.csv、torque_profiles.csv、标准化图表 | 同一指标、单位和角度口径 |
| H 报告 | 与论文 Table 3、Fig. 9–11 比较 | REPRODUCTION_REPORT.md、paper_comparison.csv | 计算偏差并解释问题 |

推荐顺序：A → B → C → G（先生成前两组对比）→ D → E → F → G → H。联合优化可能持续数小时，应提前告知用户并保存分阶段中间结果。

执行时要检查脚本是否为脚本文件而非函数、是否依赖调用者工作区、相对 `load()` 路径、`cd`、`save` 和 `addpath`；按源码决定调用方式，不要盲目全项目递归加入路径造成同名函数遮蔽。

## 5. 统一评价：指标和约束

每个实验至少记录：`scenario`、`status`、`provenance`、`commit`、`matlab_version`、`timestamp`、`elapsed_s`、`iterations`、`func_count`、`exitflag`、`mean_torque_Nm`、`torque_std_Nm`、`magnet_area_m2`、`torque_target_Nm`、`constraint_max_violation`、`source_file`。

1. 平均转矩：`mean(T)`。
2. **总体转矩标准差**：`std(T,1)` 或 `sqrt(mean((T-mean(T)).^2))`，不是默认样本标准差 `std(T)`，也不是峰峰值波动率。
3. 永磁体面积下降：`100*(A_initial-A_new)/A_initial`，必须相同单位、相同对称几何口径。
4. 转矩标准差下降：`100*(S_initial-S_new)/S_initial`；分母为 0 时不能计算。
5. 平均转矩要求：分别按源代码实际约束核实 2.0 或 2.3 N·m，并报告违反量、约束余量。不同约束强度不可不加说明直接比较。
6. 几何可行性：读取真实非线性约束函数。论文外铁桥厚度下限约 1.5 mm，具体条件及不等式数量以源码为准。
7. 转矩角度位置按论文 0°–29° 每隔 1° 采样；计算各结构时采用相同载荷、励磁及相位约定。

参考计算片段（变量需与真实源码映射后才可调用）：

```matlab
T = T(:);
assert(all(isfinite(T)), 'Nonfinite torque values');
Tmean = mean(T);
Tstd = std(T, 1);
reductionAreaPct = 100*(A0-A1)/A0;
reductionStdPct = 100*(S0-S1)/S0;
```

**物理指标必须从真实几何和求解器重新评价获得，不能只通过 fmincon 返回的单一目标函数值推算所有物理量。** 对设计向量 x* 进行几何更新，调用原始电磁场求解器，保存每角度转矩和面积，检查数值有限与约束满足。

## 6. 数据与图表交付清单

| 编号 | 文件 | 内容 |
|---|---|---|
| F01 | geometry_initial.png | 原始二维电机结构与材料区域，注明坐标单位 |
| F02 | geometry_comparison.png | 参数/形状/顺序/联合优化几何的有效对比 |
| F03 | torque_profiles.png | 统一角度坐标的初始与优化后转矩曲线 |
| F04 | convergence_combined.png | 联合优化目标值与关键指标的迭代历程 |
| F05 | metrics_comparison.png | 永磁体面积、平均转矩、标准差对比 |
| T01 | design_variables.csv | 变量名称、单位、原值、优化值、边界、变化量 |
| T02 | metrics_all.csv | 全方案指标、约束、来源、状态和执行信息 |
| T03 | paper_comparison.csv | 实测复现结果 vs 论文 Table 3、偏差 |
| LOG | logs/*.log | 原始运行输出、报错堆栈、运行时间 |

输出报告必须写清真实数据来源；如果只读取论文作者已有的 `OptimizationHistory.mat` 则标 `author_archive`，不得写成“本机成功运行”。

## 7. 兼容性、异常和验收规则

- 若 Windows 本地能调用 MATLAB，可使用 `matlab -batch "run('...')"`；否则准备可在 GUI 中手动运行的 `.m` 包装入口。
- 遇到缺工具箱、R2025a API 不兼容、路径/相对目录问题、同名函数、NaN/Inf、几何无效、优化耗时/超时，保留错误编号、堆栈、触发脚本、时间与修复动作。
- 最小修改原则：优先修环境与路径，其次处理不影响物理模型的版本兼容性。涉及目标/约束/几何/角度的改变必须另标“改进实验”，不能当原论文复现。
- 结果判定分为：`reproduced`（本机实算并对照）、`partial`（仅部分环节成功）、`archive_only`（只可查看作者历史结果）、`failed`（未能运行）。
- 不因历史数据图表正确、示例脚本能跑或没有约束检查就宣布整个研究完成。

## 8. 目标目录（按实际仓库组织调整）

```text
MotorOptimization/
├── <官方源码，尽量保持不变>
├── reproduction/
│   ├── inspect_repository.m
│   ├── run_baseline.m
│   ├── run_experiments.m
│   ├── collect_metrics.m
│   └── make_plots.m
└── reproduction_output/
    ├── ENVIRONMENT.md
    ├── SCRIPT_MAP.md
    ├── REPRODUCTION_REPORT.md
    ├── commit.txt
    ├── logs/
    ├── data/
    └── figures/
```

上述是目标结构而非官方仓库已有文件。脚本应按源码真实变量和函数实现，不要生成空壳文件充数。

## 9. 可直接交给 Codex 的执行指令

> 请完整阅读本仓库的 REPRODUCTION_PLAN.md。目标是在 Windows 本地 MATLAB R2025a 中，依据官方 MichaelWiesheu/MotorOptimization 代码，重新运行初始电机评价、结构参数优化、形状优化、顺序优化和联合优化，并完成物理指标重算。先克隆官方仓库、固定 commit、阅读 README/许可/真实 .m 脚本，递归扫描 results 各子目录并生成 SCRIPT_MAP.md；不要假设脚本在 results 根目录。检查三个 MATLAB 工具箱，优先运行 eval_init，再运行 opt_param，逐阶段运行其余实验。每阶段保存日志、终态设计变量、目标值、约束和运行时间。对最终设计重新调用电磁求解器，输出永磁体面积、平均转矩、总体标准差、几何约束、CSV 和对比图；对照论文 Table 3、Fig. 9–11。禁止在修改模型/约束/角度采样后仍称为严格复现，禁止用作者归档数据冒充本机结果；本阶段不运行 Maxwell。若不能访问本地 MATLAB，只能提交静态审计、包装脚本及待执行命令，并如实说明限制。

## 10. 最终检查清单

- [ ] 上游仓库地址、commit SHA、clone 日期已保存。
- [ ] MATLAB R2025a 与三个工具箱的可用性和许可已记录。
- [ ] 入口文件的路径经扫描核实，而不是猜测。
- [ ] 基线 `eval_init` 已本机重算并保存日志、MAT、CSV 和几何图。
- [ ] 参数优化已实算，变量、面积、转矩和约束可提取。
- [ ] 形状、顺序、联合优化已运行或有明确障碍报告。
- [ ] 各结构使用一致的角度采样，转矩标准差按 `std(T,1)`。
- [ ] 2.0 N·m / 2.3 N·m 的不同实验约束明确标注。
- [ ] 论文参考数据、作者历史 MAT 与本机仿真数据绝不混淆。
- [ ] 图表、参数表、运行日志、`REPRODUCTION_REPORT.md` 齐全。

---

*备注：该任务书为复现执行规范，不代表已在 MATLAB R2025a 中实际运行官方项目。运行入口、变量名、约束和输出位置须由 Codex 根据当时仓库源码核实。*
