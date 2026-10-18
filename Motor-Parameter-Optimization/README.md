# 电机结构参数优化复现（MATLAB R2025a）

复现 Wiesheu 等 *Combined parameter and shape optimization of electric machines with isogeometric analysis*，Optimization and Engineering 26:1011–1038（2025；2024 在线发表）。[论文 DOI](https://doi.org/10.1007/s11081-024-09925-0) · [官方代码](https://github.com/MichaelWiesheu/MotorOptimization) · [完整中文报告](reports/Parameter_Optimization_Report.md)。

**本项目只复现 Parameter Optimization、初始模型评价和终态独立评价；没有复现形状、顺序或联合优化，也没有运行 Maxwell。** 仓库根目录原有任务书是较早的完整研究计划，本项目范围以本说明和后续用户指令为准。

## 已完成的真实计算

| 指标 | 初始电机 | 参数优化终态 | 变化 |
|---|---:|---:|---:|
| 永磁体面积（四分之一模型，mm²） | 176.000000 | 159.065269 | 降低 9.62201% |
| 平均转矩（整机，N·m） | 2.245589663 | 2.300000107 | 增加 2.42299% |
| 转矩总体标准差（整机，N·m） | 0.333825086 | 0.099621509 | 降低 70.15757% |

完整参数优化 51 次迭代、72 次函数评价，求解器耗时 3143.2174604 s（52.387 min），最终目标值 4.08119016493。exitflag=2：步长达到阈值且约束可行；一阶最优性为 1.39505e-5，尚未达到 1e-6。平均转矩满足 ≥2.3 N·m，九个几何约束及所有变量界限可行。终态已重新求解 121 个角度，性能对比取共同 0°、1°、…、29°，标准差使用 `std(T,1)`。

论文 Table 3 单独 Parameter 参考值为面积 159.1 mm²、整机平均转矩 2.3 N·m、整机标准差 0.0996 N·m。本次相对误差分别为 −0.02183%、+0.00000464%、+0.02160%；论文为 65 次评价、2100 s，本机为 72 次、3143.22 s，不能将硬件/软件导致的运行时间差当作模型性能差。论文表格为舍入值。初始几何默认 RA1=144.2°，优化入口初值 RA1=144°，均按官方保留，详见报告。

## 目录

```text
src/original/       官方链接、固定 commit、原始 README 与许可证
src/reproduction/   本次 MATLAB 包装、评价、绘图、依赖引导及校验程序
results/figures/    6 类主图及 2 类补充图；PNG(300 dpi)、FIG、PDF
results/data/       MAT、CSV、最终参数、53 条原始回调和 0–51 迭代几何
results/logs/       本机初始评价、优化、终态重算和环境日志
reports/           完整中文 Markdown、Word、PDF 报告
docs/              环境、文件清单和结果来源说明
runtime/           下载依赖及新运行输出（自动生成，不上传）
```

## 环境及依赖准备

需要 MATLAB R2025a、Optimization Toolbox、Curve Fitting Toolbox、Global Optimization Toolbox、Git、PowerShell。GeoPDEs/NURBS 使用官方同一 commit 附带版本。详见 [环境说明](docs/ENVIRONMENT.md) 和 [许可说明](LICENSE_INFO.md)。官方源代码按固定 commit 下载，避免重复分发带有独立条款的几何/材料及第三方源码。

在本目录打开 PowerShell：

```powershell
powershell -ExecutionPolicy Bypass -File src/reproduction/Bootstrap-Upstream.ps1
matlab -batch "addpath('src/reproduction'); run_project('environment')"
```

若 `matlab` 不在 PATH，用本机 MATLAB 可执行文件绝对路径调用。初始化只检出参数计算依赖和两个官方入口，不检出作者结果归档。`execution_changes.patch` 为审计补丁，不改变核心物理模型或优化配置。

## 使用已有结果（优先推荐）

GitHub 可直接查看报告、CSV 和 PNG；MAT/FIG 下载后在 MATLAB 中读取。重新生成全部图表：

```matlab
addpath('src/reproduction');
run_project('validate');   % 从 MAT/CSV 校验真实结果，无需启动优化
run_project('figures');    % 只读保存数据，重画图，需先下载官方依赖
```

新生成图表和表格写入 `runtime/parameter_optimization/`，不覆盖 `results/`。`validate` 只读取数据，不依赖 Python。可选独立审计：`py src/reproduction/validate_publication.py`（需要 NumPy、SciPy、Pillow）。

## 重新运行初始评价、参数优化和终态评价

以下操作会重新计算；不要对正在运行的优化重复启动。只有 `optimize` 会启动完整参数优化，其他入口不启动优化。

```matlab
addpath('src/reproduction');
run_project('baseline');  % 若 runtime 已有基线则直接读取；首次调用执行官方 eval_init
run_project('optimize');  % 原始 300 次上限配置，完成后独立评价终态；本机约 53 min
run_project('evaluate');  % 用最终参数/几何重新求解电磁场；本机约 2 min
run_project('figures');   % 从本轮保存结果生成图表
```

`baseline`/`optimize` 使用被忽略的 `runtime/` 保存新日志和 MAT，不修改本次已发布数据。为防止误重启，若 `runtime/data/param_opt.mat` 已存在，`optimize` 会拒绝再次计算。`figures`/`evaluate` 在没有新运行数据时导入已发布实算结果；若之后要做全新优化，请另用干净克隆，或先备份并重命名 `runtime/` 后重新初始化。不要移动仍在运行的目录。

## 数据与完成情况

已完成初始场解、完整参数迭代、独立终态场解、约束核验、全部要求图表和中文报告。没有缺失的参数优化最终结果。53 条回调含迭代 0 两条，绘图按迭代号取第一条，不插值。16 个几何变量与电流初相角 Phase0 的界限、初值和终值见 [参数表](results/data/Parameter_Comparison.csv)，性能见 [性能表](results/data/Performance_Comparison.csv)，详细论文对照见 [对照 CSV](results/data/paper_parameter_comparison.csv)。RS 仅有求解精度量级微小变化，其余 15 个几何参数及 Phase0 有可辨变化。

`results/` 除明确标记 `paper_reference` 的论文参考列外，均来自本机 `local_run`，不是作者已有归档。作者原归档 SHA-256 核对保持不变。无形状/顺序/联合优化结果、无效率/损耗或实验验证结论。源数据文件与 SHA-256 见 [文件清单](docs/FILE_MANIFEST.csv)。

![转矩对比](results/figures/Fig3_Torque_Comparison.png)
![收敛曲线](results/figures/Fig2_Objective_Convergence.png)
