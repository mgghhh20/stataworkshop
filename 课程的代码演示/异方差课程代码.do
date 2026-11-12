clear all
set more off

* ============================================================
* 开启日志文件：保存本次运行的全部命令与输出
* 存放在当前工作目录，文件名为 异方差_log.smcl
* （如需改位置/格式，改下面一行即可）
* ============================================================
capture log close _all
log using "异方差_log.log", replace    // SMCL 格式，Stata 内打开更美观
* 如需纯文本，改用: log using "异方差_log.txt", text replace

* ============================================================
* 异方差(Heteroskedasticity)检验与诊断作图
* 数据集 : nerlove.dta  (Nerlove 电力成本函数数据)
* 回归   : lntc 对 lnq lnpl lnpk lnpf
* ============================================================

* --- 载入数据（请确保 nerlove.dta 在当前工作目录下） ---
use "D:\OneDrive - m.gduf.edu.cn\工作杂项\stata\课程的代码演示\2026异方差研究生金融计量经济学再补充材料\nerlove.dta", clear

* --- 查看数据概况 ---
describe
summarize

* ============================================================
* 1. 基本回归模型
* ============================================================
regress lntc lnq lnpl lnpk lnpf
estimates store model1

* 生成残差、拟合值
predict yhat, xb                 // 拟合值
predict residuals, residuals     // 残差
gen residuals2   = residuals^2   // 残差平方
gen absresid     = abs(residuals) // 残差绝对值

* ============================================================
* 2. 诊断图
* ============================================================
* 2.1 残差 vs 拟合值（喇叭状 → 异方差）
graph twoway (scatter residuals yhat, msymbol(oh) msize(small)) ///
       (lfit residuals yhat, lcolor(cranberry) lwidth(medium)), ///
       title("Residuals vs Fitted") ///
       xtitle("Fitted values") ytitle("Residuals") ///
       name(g1, replace)

* 2.2 残差平方 vs 拟合值
graph twoway (scatter residuals2 yhat, msymbol(oh) msize(small)) ///
       (lfit residuals2 yhat, lcolor(edkblue) lwidth(medium)), ///
       title("Residual^2 vs Fitted") ///
       xtitle("Fitted values") ytitle("Residual^2") ///
       name(g2, replace)

* 2.3 残差平方 vs 对数产出 lnq（常体现方差随规模变化）
graph twoway (scatter residuals2 lnq, msymbol(oh) msize(small)) ///
       (lfit residuals2 lnq, lcolor(green) lwidth(medium)), ///
       title("Residual^2 vs lnq") ///
       xtitle("lnq") ytitle("Residual^2") ///
       name(g3, replace)

* 合成一张诊断图
graph combine g1 g2 g3, title("异方差诊断图") ///
       name(het_diag, replace) ysize(4) xsize(6)

* ============================================================
* 3. 异方差检验（五种方法）
* ============================================================
di _n "================= 异方差检验 ================="

* ============================================================
* 检验一：Breusch-Pagan 检验
* 原假设 H0: 同方差；p<0.05 → 拒绝 H0，存在异方差
* ============================================================
di _n "--- 检验一: Breusch-Pagan 检验 ---"
estat hettest, iid

* ============================================================
* 检验二：White 检验（最稳健，含交叉项与平方项）
* ============================================================
di _n "--- 检验二: White 检验 ---"
estat imtest, white

* ============================================================
* 检验三：Goldfeld-Quandt 检验
* 按某变量(此处用 lnq)排序，舍去中间样本，比较前后两段残差方差
* ============================================================
di _n "--- 检验三: Goldfeld-Quandt 检验 ---"
gsort lnq
gen order = _n
local c = int(_N/4)                                    // 中间舍弃的样本数
qui regress lntc lnq lnpl lnpk lnpf if order <= (_N - _N/2)/2     // 前半段
scalar rss1 = e(rss)
scalar n1   = e(df_r)
qui regress lntc lnq lnpl lnpk lnpf if order >  (_N + _N/2)/2     // 后半段
scalar rss2 = e(rss)
scalar n2   = e(df_r)
scalar F_gq = (rss2/n2) / (rss1/n1)
scalar p_gq = Ftail(n2, n1, F_gq)
di "前半段残差方差 = " %10.4f rss1/n1
di "后半段残差方差 = " %10.4f rss2/n2
di "F 统计量      = " %6.3f F_gq
di "p值           = " %6.4f p_gq
di "结论: " cond(p_gq < 0.05, "拒绝 H0，存在异方差", "不能拒绝 H0，视为同方差")

* ============================================================
* 检验四：Glejser 检验
* 用 |残差| 对解释变量回归，考察其显著性
* ============================================================
di _n "--- 检验四: Glejser 检验 ---"
qui regress absresid lnq lnpl lnpk lnpf
test lnq lnpl lnpk lnpf
di "结论: " cond(r(p) < 0.05, "拒绝 H0，存在异方差", "不能拒绝 H0，视为同方差")

* ============================================================
* 检验五：Spearman 秩相关检验
* 对 |残差| 与各解释变量做 Spearman 秩相关，显著则存在异方差
* ============================================================
di _n "--- 检验五: Spearman 秩相关检验 ---"
spearman absresid lnq lnpl lnpk lnpf, star(0.05)
di "结论: 任一带 * 号的变量表明其与|残差|秩相关显著 → 提示存在异方差"

* ============================================================
* 4. 结果汇总
* ============================================================
di _n "================= 检验结果汇总 ================="
di "1) Breusch-Pagan      : 见 estat hettest 输出"
di "2) White              : 见 estat imtest, white 输出"
di "3) Goldfeld-Quandt    : F = " %6.3f F_gq " , p = " %6.4f p_gq
di "4) Spearman           : 见上方秩相关表(带*显著)"
summarize residuals residuals2

* 生成图（如需保存到磁盘，取消下一行注释）
* graph export "异方差诊断图.png", replace width(1600)

display "异方差检验与作图完成！"

* ============================================================
* 关闭日志并保存
* ============================================================
log close _all
