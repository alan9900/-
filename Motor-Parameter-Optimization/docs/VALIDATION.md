# 发布校验与数据来源

2026-10-18 发布前检查：

- 在干净的稀疏检出副本中固定官方 commit，成功应用 `execution_changes.patch`。只检出两种本次任务入口，没有复制作者历史优化归档。
- MATLAB R2025a 调用 `run_project('validate')` 成功：MAT/CSV、共同 30 点、121 个场解、总体标准差、变量界限、53 条回调、六张可编辑 FIG 均通过检查。
- MATLAB 调用 `run_project('figures')` 成功，使用已发布实算数据重新生成图表；该检查未重新启动优化。新图输出于被忽略的 `runtime/parameter_optimization/`。
- 独立 Python 审计读取全部 MAT、校验所有 PNG、核对指标/样本/界限/迭代、Markdown 链接及 SHA-256。链接和清单逐级检查实际文件名大小写，避免 Windows 宽松匹配掩盖 GitHub 路径错误。运行 `py src/reproduction/validate_publication.py` 可重复检查。
- 最大发布文件小于 1 MB，无文件接近 GitHub 的大文件限制。源码依赖下载目录、缓存、临时文件和个人用户路径不进入发布目录。
- 原根目录 README.md、REPRODUCTION_PLAN.md 未修改。原本机计算交付及运行目录没有因发布整理而改变。

`results/data/` 和 `results/figures/` 来源为本机 `local_run`。论文比较 CSV 的参考列为 `paper_reference`；作者已存在 MAT 结果未作为本次计算结果。53 条回调保留两个迭代 0，绘图取首条重复迭代记录。

发布副本中，三个 MAT 文件（param_evaluation、design_parameters、final_design/final_metadata）仅把本机绝对路径元数据改为相对索引；全部数值、结构参数和计算数组保留。JSON 的同类索引也转为相对路径。日志去除用户目录前缀和终端退格字符；文本统一 LF。Word/PDF 保留原审核版，Markdown 调整 GitHub 相对链接。

文件清单 `FILE_MANIFEST.csv` 列出发布项目内所有文件的大小、SHA-256 和来源，清单自身不计算在内。`runtime/` 不属于发布清单。该清单用于验证 GitHub 下载内容与本地发布副本完全相同；不将文本排版、元数据规范化或重新绘图误记为新的优化计算。
