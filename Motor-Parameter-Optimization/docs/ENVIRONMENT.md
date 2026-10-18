# 运行环境

本次实算：Windows、MATLAB `25.1.0.2943329 (R2025a)`；AMD Ryzen 7 5800H（8 核/16 线程），约 16 GB 内存。

已安装并通过 `license('test',...)` 的工具箱：Optimization Toolbox、Curve Fitting Toolbox、Global Optimization Toolbox。官方仓库附带 GeoPDEs 与 NURBS 快照，保持固定 commit，不另行替换版本。官方最初测试版本为 R2024a，本次实际使用 R2025a。

依赖下载需要 Git 和 PowerShell；MATLAB 批处理可将 `matlab` 加入 PATH，或使用本机 MATLAB 可执行文件完整路径。读取结果、重画图不需要 Python。可选数据审计使用 Python 3、NumPy、SciPy、Pillow。

官方 commit：`e61673e10d4a7f164b713fb744e19bb69973f7e9`。原任务书来源 commit：`4745ca9783b4679ebffea3812763440323a9ef66`。后续用户要求将范围缩减至参数优化。

求解配置保留原入口：fmincon/interior-point，MaxIterations=300，StepTolerance=1e-8，OptimalityTolerance=1e-6，ConstraintTolerance=1e-6，ScaleProblem=false，HonorBounds=false，原梯度设置、目标及约束不变。原非线性场求解器、材料、几何及电流工况不变。补丁只增加场残差/迭代记录、保存 fmincon 退出信息，并移除入口全局路径重置。

日志见 `../results/logs/environment.log`。`runtime/` 是被 Git 忽略的计算目录；所有发布结果在 `results/`，新运行不会覆盖发布的结果。
