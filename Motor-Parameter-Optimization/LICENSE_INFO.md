# 代码、第三方依赖与数据来源

- 论文及官方实现版权属于 Michael Wiesheu、Theodor Komann、Melina Merkel、Sebastian Schöps、Stefan Ulbrich、Idoia Cortes Garcia 等原作者。官方固定 commit 为 `e61673e10d4a7f164b713fb744e19bb69973f7e9`。
- 官方代码声明 GPL-3.0-or-later。完整许可证与原始说明见 `src/original/LICENSE.GPL-3.0.txt`、`src/original/UPSTREAM_README.md`。本目录新增 MATLAB 包装代码、从官方代码改编的评价程序及补丁同样按 GPL-3.0-or-later 提供，保留作者署名和修改说明。
- 官方 GeoPDEs、NURBS 快照只从固定官方仓库按需获取，保留其各自许可证，未将整套第三方包重新上传。
- 官方 README 指出几何源自 [JMAG-RT Motor Model Library](https://www.jmag-international.com/modellibrary/)，适用 JSOL 条款；材料数据源自 FEMM，适用其 [Aladdin Free Public License](https://www.femm.info/wiki/license)。软件 GPL 声明不取代这些独立条款。本仓库不附带原始 JSOL 模型包或 FEMM 材料库文件。外部依赖的使用和再分发仍应遵守其原始条款。
- `results/` 是本机 MATLAB 实际运行产生的参数、转矩、统计、NURBS 导出几何、迭代记录和图表，注明 `local_run`。几何结果保留上述来源和条款说明，不以软件许可证重新授权第三方几何设计权利。
- `paper_parameter_comparison.csv` 中参考数字来自论文 Table 3 的 Parameter 一列，明确标记 `paper_reference`；不包含作者历史 MAT 优化结果。报告正常引用论文 DOI，不重新分发论文全文。
- Word/PDF 报告为原交付报告，Markdown 为适配 GitHub 路径的同内容版本。日志仅清理本地用户路径和终端退格控制字符，数值未改动。原始本地交付未修改。
