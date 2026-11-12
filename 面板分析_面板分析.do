/*==============================================================================
 * 面板数据分析：补贴—研发—企业价值（新能源车企）
 * ——《实战代码一.ipynb》的 Stata 复现版
 *
 * 数据：python/AA论文大全/DATA/新面板数据.csv（23 家企业、529 条季度观测）
 *
 * 【使用说明】
 *   1) 用 Stata 打开本文件直接运行（工作目录设为本文件所在目录）。
 *      运行后生成：面板分析_面板分析.log（详细日志）、若干 .rtf 结果表、若干 .png 图。
 *   2) Stata 的 import delimited 会把变量名全部转为小写，故本文件统一使用小写变量名。
 *   3) 预处理只在一处实现（program prepare_panel），与 notebook 的 prepare_panel()
 *      一一对应：缩尾 -> 企业内线性插值 -> 剔除不完整观测 -> 中心化 -> 交互项。
 *   4) 固定效应面板回归的标准误统一按企业聚类，
 *      对应 linearmodels 的 fit(cov_type='clustered', cluster_entity=True)。
 *
 * 【按要求跳过 / 无法完全对应的部分】
 *   - cell 50「主成分的稳健性回归」（PC1–PC4 进入回归）——按要求不做；
 *   - cell 56「中介变量检验」——notebook 中该单元为空，无内容可译；
 *   - Stargazer 表格 -> 改用 esttab（未安装时自动退回内置 estimates table）；
 *   - 相关系数热力图 / 载荷热力图 / Bootstrap 分布图：Stata 无对应内置命令，
 *     改为输出数值表（相关系数矩阵、载荷矩阵）；
 *   - PCA 得分的正负号在 Stata 与 sklearn 之间可能相反（PCA 符号不确定），
 *     这是主成分分析的固有性质，不影响载荷大小与解释。
 *=============================================================================*/

clear all
set more off
set linesize 200

*--------------------------------------------------------------- 日志与依赖 --
* 注：如果改用批处理方式 `stata /e do 面板分析_面板分析.do` 运行，Stata 会先占用同名日志，
*     此处再打开就会报 r(608)，因此用 capture 容错（输出同样会写进该日志文件）。
capture log close
capture log using "面板分析_面板分析.log", replace text

capture which esttab
global have_esttab = (_rc == 0)
display "esttab 可用: $have_esttab （=0 时表格自动改用内置 estimates table 输出）"

local data_path "D:/OneDrive - m.gduf.edu.cn/工作杂项/python/AA论文大全/DATA"

* 变量清单（对应 notebook cell 8 的三组清单）
global cols_to_winsor   "tobinq subsidy rd lev cf salesq bm gm roe roa"
global center_vars      "subsidy rd lev cf salesq roa gm roe bm"
global interaction_vars "subsidy_rd subsidy_rd2 subsidy_lev rd_lev salesq_sub"

*==============================================================================
* 工具程序 1：prepare_panel —— 对应 notebook 的 prepare_panel()
*   用法：
*     prepare_panel, winsor                                   // 只缩尾（cell 9）
*     prepare_panel, impute(varlist) dropna(varlist)          // 完整流水线（cell 19/64）
*     prepare_panel                                           // 只中心化+交互项（cell 41）
*   要点：缩尾只对非缺失值做（notebook 特别强调：缺失值参与分位数会导致上侧不缩尾）。
*==============================================================================
capture program drop prepare_panel
program define prepare_panel
    syntax [, WInsor IMpute(varlist) DROPna(varlist) NoCenter]

    * (a) 1%/99% 缩尾
    if "`winsor'" != "" {
        foreach v of global cols_to_winsor {
            quietly summarize `v', detail
            local lo = r(p1)
            local hi = r(p99)
            quietly replace `v' = `lo' if !missing(`v') & `v' < `lo'
            quietly replace `v' = `hi' if !missing(`v') & `v' > `hi'
        }
        display "  [prepare_panel] 已完成 1%/99% 缩尾（只对非缺失值）"
    }

    * (b) 企业内线性插值（TobinQ 不插值；不用未来值回填过去）
    *     对应 pandas: groupby('Code')[cols].transform(
    *         lambda x: x.interpolate(method='linear', limit_direction='forward'))
    *     即：中间缺口线性插值，尾部缺口用最近的前值填补，首部缺口保持缺失。
    *     注意插值间距：pandas 是按行号（reset_index 后的 RangeIndex）计算间距的，
    *     不是按自然时间；因此这里同样按"企业内行号"插值，保证与 notebook 完全一致
    *     （只有存在整段缺失行的企业，如 LEAPMOTOR，两种口径才会有差别）。
    if "`impute'" != "" {
        capture drop __rowid
        quietly bysort panel_id (time): gen long __rowid = _n
        foreach v of varlist `impute' {
            capture drop __ip
            capture ipolate `v' __rowid, gen(__ip) by(panel_id)
            capture quietly replace `v' = __ip if missing(`v') & !missing(__ip)
            capture drop __ip
            forvalues k = 1/40 {
                capture quietly bysort panel_id (time): replace `v' = `v'[_n-1] if missing(`v')
            }
        }
        capture drop __rowid
        display "  [prepare_panel] 已完成企业内线性插值（TobinQ 与被解释变量除外）"
    }

    * (c) 剔除仍然不完整的观测（必须在中心化之前，保证 *_c 均值严格为 0）
    if "`dropna'" != "" {
        quietly egen __rowmiss = rowmiss(`dropna')
        quietly drop if __rowmiss > 0
        capture drop __rowmiss
        display "  [prepare_panel] 剔除不完整观测后 N = " _N
    }

    * (d) 中心化  (e) 交互项（一律用中心化变量相乘：Aiken & West, 1991）
    if "`nocenter'" == "" {
        foreach v of global center_vars {
            capture drop `v'_c
            quietly egen __m = mean(`v')
            quietly gen `v'_c = `v' - __m
            capture drop __m
        }
        foreach v of global interaction_vars {
            capture drop `v'
        }
        quietly gen subsidy_rd  = subsidy_c * rd_c
        quietly gen subsidy_rd2 = subsidy_c * rd_c^2
        quietly gen subsidy_lev = subsidy_c * lev_c
        quietly gen rd_lev      = rd_c * lev_c
        quietly gen salesq_sub  = salesq_c * subsidy_c
        * 交互项自身再中心化（供需要 *_c 版交互项的模型使用）
        foreach v of global interaction_vars {
            capture drop `v'_c
            quietly egen __m = mean(`v')
            quietly gen `v'_c = `v' - __m
            capture drop __m
        }
        display "  [prepare_panel] 已完成中心化与交互项构建"
    }
end

*==============================================================================
* 工具程序 2：show_models —— 输出已存储模型的对比表
*   有 esttab 时输出 rtf 表 + 屏幕表；没有时退回 estimates table
*==============================================================================
capture program drop show_models
program define show_models
    syntax anything [, TItle(string) FIle(string) MTitles(string) KEEP(string)]
    local mtopt ""
    if "`mtitles'" != "" local mtopt `"mtitles(`mtitles')"'
    local keepopt ""
    if "`keep'" != "" local keepopt "keep(`keep')"
    display _n(2) "=============== 表：`title' ==============="
    if "$have_esttab" == "1" {
        if "`file'" != "" {
            esttab `anything' using "`file'", replace b(4) se(4) ///
                star(* 0.1 ** 0.05 *** 0.01) nogap compress title("`title'") ///
                `mtopt' `keepopt'
        }
        else {
            esttab `anything', b(4) se(4) star(* 0.1 ** 0.05 *** 0.01) ///
                nogap compress title("`title'") `mtopt' `keepopt'
        }
    }
    else {
        estimates table `anything', b(%9.4f) star(0.10 0.05 0.01) ///
            stats(N r2_w r2_o F) `keepopt'
    }
end

*==============================================================================
* 工具程序 3：vif_table —— 计算方差膨胀因子
*   VIF_j = 1/(1-R²_j)，R²_j 来自"把第 j 个解释变量对其余解释变量回归"；
*   所有辅助回归都限制在"全部变量均不缺失"的同一样本上，
*   与 notebook 中 variance_inflation_factor 在同一个 .dropna() 矩阵上的算法等价。
*==============================================================================
capture program drop vif_table
program define vif_table
    local all `*'
    quietly egen __okrow = rowmiss(`all')
    quietly count if __okrow == 0
    display "  （VIF 计算样本：N = " r(N) "）"
    display "  变量              VIF        1/VIF      判断"
    foreach x of local all {
        local others : list all - x
        quietly regress `x' `others' if __okrow == 0
        scalar __vif = 1/(1 - e(r2))
        local flag "无共线性"
        if __vif >= 5  local flag "中度共线"
        if __vif >= 10 local flag "严重共线"
        display "  " %-14s "`x'" %9.3f scalar(__vif) %11.3f scalar(1/__vif) "      `flag'"
    }
    capture drop __okrow
end

*==============================================================================
* 第一部分：数据导入与描述（notebook cell 2–7）
*==============================================================================
display _n(2) "=================================================="
display "第一部分：数据导入与描述统计"
display "=================================================="

capture frame drop raw
frame create raw
frame change raw
import delimited using "`data_path'/新面板数据.csv", clear encoding("utf-8") varnames(1)
sort code year quarter

* 列集合（对应 notebook cell 5）：headers4 = 前 11 个变量
local headers4 "tobinq subsidy rd soe lev cf salesq roa roe gm bm"
display _n "描述性统计（对应 cell 6）："
summarize `headers4'

display _n "相关系数矩阵（对应 cell 7 的相关系数热力图）："
pwcorr `headers4', star(0.05)

*==============================================================================
* 第二部分：数据预处理与交互项（notebook cell 8–9）
*==============================================================================
display _n(2) "=================================================="
display "第二部分：数据预处理与交互项构建"
display "=================================================="

capture frame drop main
frame copy raw main
frame change main

* (1) 时间标识：Quarter 形如 '2020Q4'，取末位季度数字
gen qnum = real(substr(quarter, strlen(quarter), 1))
assert !missing(qnum)
label variable qnum "季度(1-4)"
* (2) 时间序号：2021Q1 = 1、2021Q2 = 2 ……（与 notebook 完全一致）
gen time = (year - 2021) * 4 + qnum
label variable time "时间序号(2021Q1=1)"
sort code time

* (3) 面板设定：Stata 的面板 id 必须数值型，字符串企业代码需先转数值
egen panel_id = group(code)
label variable panel_id "企业(数值面板id)"
xtset panel_id time
xtdes

* (4) 主样本第一步：只缩尾（样本尚未定下来，暂不中心化）
prepare_panel, winsor
quietly summarize tobinq
display "  自检 TobinQ: min = " %8.4f r(min) "  max = " %8.4f r(max)

* 产权性质分布（对应 cell 9 的企业分类说明）
tab soe

*==============================================================================
* 第三部分：共线性 / 内生性 / 异方差诊断（notebook cell 11–14）
*==============================================================================
display _n(2) "=================================================="
display "第三部分：共线性、内生性、异方差诊断"
display "=================================================="

* --- 3.1 VIF（cell 12）-------------------------------------------------------
* 说明：VIF 只取决于解释变量与样本。notebook 先把解释变量矩阵 .dropna() 再算 VIF，
*       这里对同一个"解释变量全不缺失"的样本逐变量计算 1/(1-R²)，口径完全一致。
display _n "【表1】VIF —— 集合：subsidy rd soe lev cf salesq roa roe gm bm"
vif_table subsidy rd soe lev cf salesq roa roe gm bm

display _n "【表2】VIF —— 集合：subsidy rd cf salesq bm gm roa roe"
vif_table subsidy rd cf salesq bm gm roa roe
display "判断标准：VIF < 5 无严重共线性；5–10 中度；> 10 严重"

* --- 3.2 DWH 内生性检验（cell 13）------------------------------------------
* 工具变量：subsidy 的滞后一期（按企业取上一行，等价 pandas shift(1)）
display _n "【DWH 检验】工具变量：subsidy_lag1（滞后一期补贴）"
bysort panel_id (time): gen subsidy_lag1 = subsidy[_n-1]
label variable subsidy_lag1 "滞后一期补贴"

* OLS（企业固定效应），样本与 IV 完全一致才可比
xtreg tobinq subsidy rd lev cf if !missing(subsidy_lag1), fe
scalar ols_coef = _b[subsidy]
scalar ols_p    = 2 * ttail(e(df_r), abs(_b[subsidy]/_se[subsidy]))
estimates store dwh_ols

* IV(2SLS)（企业固定效应；对应 notebook 的 LSDV 实体固定效应 IV）
xtivreg tobinq rd lev cf (subsidy = subsidy_lag1) if !missing(subsidy_lag1), fe
scalar iv_coef = _b[subsidy]
scalar iv_t    = _b[subsidy]/_se[subsidy]
scalar iv_p    = .
capture scalar iv_p = 2 * ttail(e(df_r), abs(iv_t))
if missing(iv_p) scalar iv_p = 2 * normal(-abs(iv_t))
estimates store dwh_iv

display "  OLS  subsidy 系数 = " %9.4f scalar(ols_coef) "  (p = " %6.4f scalar(ols_p) ")"
display "  IV   subsidy 系数 = " %9.4f scalar(iv_coef)  "  (p = " %6.4f scalar(iv_p)  ")"
display "  OLS 与 IV 系数差异 = " %9.4f scalar(abs(iv_coef - ols_coef))
if abs(iv_coef - ols_coef) > abs(ols_coef) * 0.3 {
    display "  !! 系数差异较大，提示可能存在内生性问题，建议使用 IV 估计"
}
else {
    display "  OK 系数差异较小，内生性问题不严重"
}
show_models dwh_ols dwh_iv, title("DWH：OLS vs IV") ///
    mtitles("OLS(FE)" "IV(FE)") file("表_dwh_ols_iv.rtf")

* --- 3.3 异方差检验（cell 14）----------------------------------------------
display _n "【异方差检验】混合 OLS 残差"
regress tobinq subsidy rd lev cf
display "Breusch-Pagan 检验（Stata 的 estat hettest 报的是 Cook–Weisberg 变体）："
estat hettest, rhs
display "White 检验："
estat imtest, white
display "经典 Breusch-Pagan LM（= N·R²，与 notebook 的 het_breuschpagan 完全同口径）："
quietly regress tobinq subsidy rd lev cf
quietly predict __e, resid
quietly gen __e2 = __e^2
quietly regress __e2 subsidy rd lev cf
scalar lm_bp = e(N) * e(r2)
display "  LM = " %9.4f scalar(lm_bp) "   p = " %9.6f scalar(chi2tail(4, lm_bp))
quietly drop __e __e2
display "注：对应 notebook 的 het_breuschpagan / het_white；"
display "    因检验显示存在异方差，后续回归统一使用企业层面聚类稳健标准误。"

*==============================================================================
* 第四部分：主成分分析（notebook cell 15–25；按要求跳过 cell 50）
*==============================================================================
display _n(2) "=================================================="
display "第四部分：主成分分析（PCA）"
display "=================================================="

capture frame drop withtsla
frame copy main withtsla
frame change withtsla

* --- 4.1 缺失情况（cell 18）------------------------------------------------
display _n "【4.1】缺失值情况"
misstable summarize

* --- 4.2 预处理（cell 19）：插值 -> 剔除不完整 -> 中心化 -> 交互项 ----------
* notebook 在此构造 df_pca（含 TSLA 的全样本），它随后成为全篇的分析样本 panel_df
local num_cols "year qnum time tobinq subsidy rd soe lev cf salesq roa roe gm bm"
local imp_cols "subsidy rd soe lev cf salesq roa roe gm bm"
prepare_panel, impute(`imp_cols') dropna(`num_cols')
sort panel_id time
display "  数据形状：N = " _N
quietly summarize subsidy_c
display "  自检 Subsidy_c 均值 = " %12.3e r(mean) " （中心化后应接近 0）"

* --- 4.3 KMO 与 Bartlett 球形检验（cell 22）--------------------------------
local pca_features "subsidy rd lev cf roa gm salesq roe"
display _n "【4.3】PCA 前置检验"
display "KMO 抽样充分性检验（> 0.6 适合做 PCA）："
factor `pca_features', pcf
estat kmo

display _n "Bartlett 球形检验（H0：相关矩阵为单位阵）："
pca `pca_features'
matrix C = e(C)
scalar b_n = e(N)
local  b_p : word count `pca_features'
scalar b_chi2 = -(b_n - 1 - (2*`b_p' + 5)/6) * ln(det(C))
scalar b_df   = `b_p' * (`b_p' - 1)/2
display "  χ² = " %9.2f scalar(b_chi2) "   df = " scalar(b_df) ///
        "   p = " %9.6f scalar(chi2tail(b_df, b_chi2))
display "  （与 factor 的 LR test: independent vs. saturated 近似一致，仅常数项取法略有差异）"

* --- 4.4 主成分个数与得分（cell 23/24）-------------------------------------
* 保留累计解释方差 >= 80% 的主成分，且限制在 [2, 5] 之间
matrix Ev = e(Ev)
scalar cum = 0
scalar ncomp = 0
forvalues j = 1/`b_p' {
    scalar cum = cum + Ev[1, `j']/`b_p'
    if (cum >= 0.80 & ncomp == 0) scalar ncomp = `j'
}
if ncomp < 2 scalar ncomp = 2
if ncomp > 5 scalar ncomp = 5
display _n "保留前 " scalar(ncomp) " 个主成分（累计解释方差 >= 80%）"

local pcnames ""
forvalues j = 1/`=ncomp' {
    capture drop pc`j'
    local pcnames "`pcnames' pc`j'"
}
pca `pca_features', components(`=ncomp')
predict `pcnames', score
display "主成分得分描述统计："
summarize `pcnames'

* --- 4.5 载荷矩阵（cell 24）-----------------------------------------------
* Stata 的 e(L) 是单位特征向量；notebook 展示的"载荷"是
*   载荷 = 单位特征向量 × √特征值（标准化数据下即变量与主成分的相关系数，取值 [-1,1]）
* 这里两者都给出。
display _n "【4.5】主成分载荷矩阵"
display "单位特征向量（estat loadings）："
estat loadings
matrix Ev2 = e(Ev)
matrix L   = e(L)
* 载荷 = 单位特征向量 × √特征值（逐列缩放；这里只保留已提取的前 ncomp 个主成分）
local nkeep = colsof(L)
matrix D = J(`nkeep', `nkeep', 0)
forvalues j = 1/`nkeep' {
    matrix D[`j', `j'] = sqrt(Ev2[1, `j'])
}
matrix LOAD = L * D
display _n "载荷矩阵（变量与主成分的相关系数）："
matrix list LOAD, format(%9.3f)
display "注：|载荷| > 0.6 为该主成分的主要构成变量。"
display "注：主成分中 subsidy 与 rd 载荷符号相反是正交化约束的结果，"
display "    不代表经济上的替代关系。"
quietly correlate subsidy rd
display "    两者实际相关系数 = " %6.3f r(rho)

* --- 4.6 PCA 企业聚类散点图（cell 25，用 Stata 图形代替 matplotlib）--------
display _n "【4.6】PCA 企业财务特征聚类散点图"
capture graph drop pca_scatter
twoway scatter pc2 pc1, mlabel(code) mlabsize(vsmall) ///
    msymbol(oh) mcolor(navy%60) ///
    xtitle("主成分1：盈利—规模 ↔ 研发密集") ///
    ytitle("主成分2：杠杆—补贴因子") ///
    title("新能源车企财务特征 PCA 聚类图") ///
    legend(off) graphregion(color(white))
capture graph export "图_pca企业聚类.png", replace width(1600)

*==============================================================================
* 第五部分：Lasso 变量筛选（notebook cell 31–33）
*==============================================================================
display _n(2) "=================================================="
display "第五部分：Lasso 变量筛选"
display "=================================================="

* 组内去均值（消除企业固定效应）
* 对应 pandas: groupby("Code")[col].transform(lambda x: x - x.mean())
foreach v in tobinq subsidy rd lev cf salesq roa gm roe bm ///
             subsidy_rd subsidy_rd2 subsidy_lev rd_lev salesq_sub {
    capture drop `v'_dm
    quietly bysort panel_id: egen __m = mean(`v')
    quietly gen `v'_dm = `v' - __m
    capture drop __m
}

display _n "Lasso（5 折交叉验证，随机种子 42；对应 LassoCV(cv=5, random_state=42)）"
lasso linear tobinq_dm subsidy_dm rd_dm lev_dm cf_dm salesq_dm roa_dm gm_dm ///
    roe_dm bm_dm subsidy_rd_dm subsidy_rd2_dm subsidy_lev_dm rd_lev_dm ///
    salesq_sub_dm, selection(cv, folds(5)) rseed(42) nolog

display _n "Lasso 系数路径图："
capture graph drop lasso_path
coefpath
capture graph export "图_lasso路径图.png", replace width(1600)
display _n "各变量系数（0 表示被 Lasso 剔除；对应 notebook 的 lasso_result 表）："
lassocoef

*==============================================================================
* 第六部分：工具变量法 2SLS（notebook cell 35–39）
*==============================================================================
display _n(2) "=================================================="
display "第六部分：工具变量法 2SLS"
display "=================================================="

* 滞后工具变量：notebook 的 IV 部分（cell 36/37/38）是从"已插值的 df_pca/panel_df"
* 重新计算滞后项的，因此这里必须在当前（已插值）样本上重建 lag；
* 不能沿用第三部分基于"未插值"数据算出来的 lag（那样会导致样本与系数不一致）。
capture drop subsidy_lag1
capture drop rd_lag1
bysort panel_id (time): gen subsidy_lag1 = subsidy[_n-1]
bysort panel_id (time): gen rd_lag1 = rd[_n-1]
label variable subsidy_lag1 "滞后一期补贴"
label variable rd_lag1      "滞后一期研发"

* --- 6.1 第一阶段（cell 36/37）：弱工具变量检验 ----------------------------
display _n "【第一阶段】只含 subsidy_lag1："
regress subsidy subsidy_lag1 rd lev cf salesq roa gm roe bm
test subsidy_lag1 = 0
display "  第一阶段工具变量 F = " %8.2f r(F) ///
        cond(r(F) > 10, "   （F>10，非弱工具变量）", "   （F<10，可能为弱工具变量）")

display _n "【第一阶段】含 subsidy_lag1 与 rd_lag1："
regress subsidy subsidy_lag1 rd_lag1 rd lev cf salesq roa gm roe bm
test (subsidy_lag1 = 0) (rd_lag1 = 0)
display "  两工具变量联合 F = " %8.2f r(F) ///
        cond(r(F) > 10, "   （F>10，非弱工具变量）", "   （F<10，可能为弱工具变量）")

* --- 6.2 第二阶段（cell 38）：2SLS 与 OLS/IV（固定效应）对比 ---------------
display _n "【第二阶段】2SLS 估计（混合 2SLS，稳健标准误）："
ivregress 2sls tobinq rd lev cf salesq roa gm roe bm (subsidy = subsidy_lag1), vce(robust)
estimates store iv_2sls

display _n "对比①：OLS（企业固定效应，聚类稳健标准误；样本与 IV 完全一致）"
xtreg tobinq subsidy rd lev cf salesq roa gm roe bm ///
    if !missing(subsidy_lag1) & !missing(rd_lag1), fe vce(cluster panel_id)
estimates store iv_ols_fe

display _n "对比②：IV（企业固定效应，滞后补贴作工具变量）"
xtivreg tobinq rd lev cf salesq roa gm roe bm (subsidy = subsidy_lag1), fe
estimates store iv_xtivreg

show_models iv_ols_fe iv_2sls iv_xtivreg, ///
    title("OLS vs 2SLS vs IV(固定效应)") ///
    mtitles("OLS(FE)" "2SLS(混合)" "IV(FE)") keep(subsidy rd lev cf) ///
    file("表_iv_ols_iv.rtf")
display "注：混合 2SLS 的第一阶段 F 只反映原始数据的相关性；固定效应 IV 还要看组内变异，"
display "    在企业数少、工具变量偏弱时系数可能极不稳定，请结合第一阶段结果与理论谨慎解读。"

*==============================================================================
* 第七部分：模型选择与基准回归（notebook cell 40–49、52–54）
*==============================================================================
display _n(2) "=================================================="
display "第七部分：模型选择与基准回归"
display "=================================================="

* --- 7.1 Hausman 检验：FE vs RE（cell 41）---------------------------------
display _n "【Hausman 检验】固定效应 vs 随机效应（全样本，含 TSLA）"
local X_hausman "subsidy_c rd_c subsidy_rd_c subsidy_rd2_c subsidy_lev_c rd_lev_c"
xtreg tobinq `X_hausman', fe
estimates store fe_hausman
xtreg tobinq `X_hausman', re
estimates store re_hausman
hausman fe_hausman re_hausman, sigmamore
show_models fe_hausman re_hausman, title("Hausman：FE vs RE") ///
    mtitles("FE" "RE") file("表_hausman_fe_re.rtf")

* --- 7.2 是否需要时间效应（cell 43）----------------------------------------
display _n "【时间效应检验】FE（不含时间效应）vs FE（含时间效应）"
xtreg tobinq `X_hausman', fe
estimates store fe_notime_h
xtreg tobinq `X_hausman' i.time, fe
estimates store fe_time_h
show_models fe_notime_h fe_time_h, title("FE：不含/含时间效应") ///
    mtitles("FE(无时间效应)" "FE(含时间效应)") keep(`X_hausman') ///
    file("表_fe_time_effects.rtf")

*-------------------------------------------------------- 主样本（剔除 TSLA）--
* notebook cell 46：剔除特斯拉；cell 47–77 全部基于该样本
capture frame drop panel
frame copy withtsla panel
frame change panel
xtset panel_id time
quietly count if code == "TSLA"
local n_tsla = r(N)
drop if code == "TSLA"
display _n "剔除 TSLA " `n_tsla' " 条观测；现样本 N = " _N
quietly levelsof code, local(firm_list)
local nfirm : word count `firm_list'
display "  企业数 = `nfirm'"

* --- 7.3 基准回归（cell 48）-----------------------------------------------
display _n "【模型1】双变量模型（无交互项、无控制变量）"
xtreg tobinq subsidy_c rd_c, fe vce(cluster panel_id)
estimates store m1_twovar

display _n "【模型2】基础模型（无交互项）"
xtreg tobinq subsidy_c rd_c cf_c salesq_c gm_c roe_c, fe vce(cluster panel_id)
estimates store m2_base

display _n "【模型3】基础模型（剔除盈利控制 GM）"
xtreg tobinq subsidy_c rd_c cf_c salesq_c roe_c, fe vce(cluster panel_id)
estimates store m3_nogm

display _n "【模型4】基础模型（Lasso 筛选变量：subsidy_c rd_c bm_c salesq_c）"
xtreg tobinq subsidy_c rd_c bm_c salesq_c, fe vce(cluster panel_id)
estimates store m4_lasso

show_models m1_twovar m2_base m3_nogm m4_lasso, ///
    title("模型对比：基准回归") ///
    mtitles("双变量" "基础模型" "基础模型(无GM)" "基础模型(Lasso筛选)") ///
    keep(subsidy_c rd_c cf_c salesq_c gm_c roe_c bm_c) ///
    file("表_基准回归.rtf")

* --- 7.4 产权性质调节效应（cell 49）---------------------------------------
display _n "【模型A/B】加入 subsidy×SOE 交互项"
* SOE 不随时间变化，会被企业固定效应吸收，故只放交互项
gen subsidy_c_soe = subsidy_c * soe
gen subsidy_c_lev = subsidy_c * lev_c

xtreg tobinq subsidy_c rd_c subsidy_c_soe cf_c salesq_c gm_c, fe vce(cluster panel_id)
estimates store m_soeA
display _n "模型A：边际效应"
display "  非国企组 subsidy 效应 = " %9.4f _b[subsidy_c] ///
        "  (p = " %6.4f 2*ttail(e(df_r), abs(_b[subsidy_c]/_se[subsidy_c])) ")"
display "  国企组 subsidy 效应 = subsidy_c + subsidy_c_soe："
lincom subsidy_c + subsidy_c_soe
display "  组间差异（subsidy×SOE）= " %9.4f _b[subsidy_c_soe] ///
        "  (p = " %6.4f 2*ttail(e(df_r), abs(_b[subsidy_c_soe]/_se[subsidy_c_soe])) ")"

xtreg tobinq subsidy_c rd_c subsidy_c_soe subsidy_c_lev cf_c salesq_c gm_c, ///
    fe vce(cluster panel_id)
estimates store m_soeB
display _n "模型B：国企组 subsidy 效应 = subsidy_c + subsidy_c_soe"
lincom subsidy_c + subsidy_c_soe

show_models m2_base m_soeA m_soeB, title("基准模型 vs 加入产权性质调节") ///
    mtitles("基准模型" "模型A:+Subsidy×SOE" "模型B:+Subsidy×SOE+Subsidy×Lev") ///
    keep(subsidy_c subsidy_c_soe subsidy_c_lev rd_c cf_c gm_c salesq_c) ///
    file("表_产权性质调节.rtf")

* --- 7.5 国企 / 非国企分组回归（cell 52）-----------------------------------
display _n "【分组回归】国企组（SOE=1）"
xtreg tobinq subsidy_c rd_c cf_c gm_c salesq_c roe_c if soe == 1, fe vce(cluster panel_id)
estimates store m_soe1
display _n "【分组回归】非国企组（SOE=0）"
xtreg tobinq subsidy_c rd_c cf_c gm_c salesq_c roe_c if soe == 0, fe vce(cluster panel_id)
estimates store m_soe0
show_models m2_base m_soe1 m_soe0, title("所有制分组回归") ///
    mtitles("全样本" "国企(SOE=1)" "非国企(SOE=0)") ///
    keep(subsidy_c rd_c cf_c gm_c salesq_c roe_c) ///
    file("表_所有制分组.rtf")

* --- 7.6 交互项回归（cell 54）---------------------------------------------
display _n "【模型】全样本（含全部交互项）"
xtreg tobinq subsidy_c rd_c cf_c gm_c salesq_c ///
    subsidy_rd subsidy_rd2 subsidy_lev rd_lev salesq_sub, fe vce(cluster panel_id)
estimates store m_int_all

foreach v in subsidy_rd subsidy_rd2 subsidy_lev rd_lev salesq_sub {
    display _n "【模型】逐一放入交互项：`v'"
    xtreg tobinq subsidy_c rd_c cf_c gm_c salesq_c `v', fe vce(cluster panel_id)
    estimates store m_int_`v'
}
show_models m_int_all m_int_subsidy_rd m_int_subsidy_rd2 m_int_subsidy_lev ///
    m_int_rd_lev m_int_salesq_sub, title("交互项模型对比") ///
    mtitles("全样本" "Subsidy×RD" "Subsidy×RD²" "Subsidy×Lev" "RD×Lev" "SalesQ×Subsidy") ///
    keep(subsidy_c rd_c cf_c gm_c salesq_c subsidy_rd subsidy_rd2 subsidy_lev rd_lev salesq_sub) ///
    file("表_交互项.rtf")

* 注：notebook cell 56「中介变量检验」是空单元，无内容可译。

*==============================================================================
* 第八部分：稳健性检验（notebook cell 57–66）
*==============================================================================
display _n(2) "=================================================="
display "第八部分：稳健性检验"
display "=================================================="

* --- 8.1 替换因变量为 ROA（cell 58）---------------------------------------
display _n "【5.1】替换因变量：ROA"
xtreg roa subsidy rd lev cf salesq gm bm, fe vce(cluster panel_id)
estimates store r_roa

* --- 8.2 加入时间固定效应（cell 60）---------------------------------------
display _n "【5.2】加入时间固定效应（双向固定效应）"
xtreg tobinq subsidy rd cf gm salesq roe i.time, fe vce(cluster panel_id)
estimates store r_twfe

* --- 8.3 加入特斯拉（cell 62）---------------------------------------------
display _n "【5.3】含特斯拉样本（回到含 TSLA 的 withtsla 帧）"
frame change withtsla
xtset panel_id time
xtreg tobinq subsidy rd cf gm salesq roe, fe vce(cluster panel_id)
estimates store r_tsla

* --- 8.4 不做缩尾（cell 64/65）-------------------------------------------
display _n "【5.4】全样本不做缩尾（原始数据 -> 插值 -> 剔除不完整 -> 中心化）"
capture frame drop nowinsor
frame copy raw nowinsor
frame change nowinsor
gen qnum = real(substr(quarter, strlen(quarter), 1))
assert !missing(qnum)
gen time = (year - 2021) * 4 + qnum
sort code time
egen panel_id = group(code)
xtset panel_id time
drop if code == "TSLA"
local num_cols2 "year qnum time tobinq subsidy rd soe lev cf salesq roa roe gm bm"
local imp_cols2 "subsidy rd soe lev cf salesq roa gm roe bm"
prepare_panel, impute(`imp_cols2') dropna(`num_cols2')
xtreg tobinq subsidy rd cf salesq gm roe, fe vce(cluster panel_id)
estimates store r_nowinsor

frame change panel
xtset panel_id time
show_models r_roa r_twfe r_tsla r_nowinsor, title("稳健性检验") ///
    mtitles("替换因变量ROA" "加入时间效应" "含特斯拉" "全样本不缩尾") ///
    keep(subsidy rd cf gm salesq roe lev bm) file("表_稳健性检验.rtf")

*==============================================================================
* 第九部分：异质性检验（notebook cell 67–77）
*==============================================================================
display _n(2) "=================================================="
display "第九部分：异质性检验"
display "=================================================="

* --- 9.1 大企业 / 小企业（cell 70）----------------------------------------
* notebook 原写法按"季度规模"分组会把同一家企业拆到两组；这里改为按"企业"分组：
* 用各企业平均营业收入(SalesQ)的中位数划分大小企业。
* ⚠️ 口径必须与 notebook 完全一致：notebook 用 df.groupby('Code')['SalesQ'].mean()，
*    其中 df 是"只缩尾、未插值、含全部 23 家企业（含 TSLA）"的样本；
*    若改用分析样本（已插值、剔 TSLA、只剩 21 家）计算，中位数会不同，
*    会把 LEAPMOTOR 这类企业分到另一组。因此这里专门回到 main 帧计算，
*    再按企业代码把分组结果并入分析样本。
display _n "【规模异质性】以各企业平均 SalesQ 的中位数分组（口径同 notebook）"
capture frame drop fsize
frame copy main fsize
frame change fsize
bysort panel_id: egen firm_msalesq = mean(salesq)
egen tag_firm = tag(panel_id)
quietly summarize firm_msalesq if tag_firm, detail
scalar med_salesq = r(p50)
quietly keep if tag_firm
keep code firm_msalesq
tempfile fsize
quietly save `fsize'
frame change panel
xtset panel_id time
merge m:1 code using `fsize', keep(master match) nogen
capture frame drop fsize
gen byte large_firm = firm_msalesq >= med_salesq
label variable large_firm "大规模企业(=1)"
display "  各企业平均 SalesQ 的中位数 = " %12.4f scalar(med_salesq) ///
        "（基于 23 家企业、未插值的缩尾样本）"
display "  大规模企业："
levelsof code if large_firm == 1, clean local(big)
display "    `big'"
display "  小规模企业："
levelsof code if large_firm == 0, clean local(small)
display "    `small'"

display _n "【大规模企业】"
xtreg tobinq subsidy_c rd_c cf_c gm_c salesq_c roe_c if large_firm == 1, fe vce(cluster panel_id)
estimates store h_large
display _n "【小规模企业】"
xtreg tobinq subsidy_c rd_c cf_c gm_c salesq_c roe_c if large_firm == 0, fe vce(cluster panel_id)
estimates store h_small

show_models m2_base m_soe1 m_soe0 h_large h_small, ///
    title("规模/所有制分组回归") ///
    mtitles("全样本" "国企" "非国企" "大型企业" "小型企业") ///
    keep(subsidy_c rd_c cf_c gm_c salesq_c roe_c) ///
    file("表_异质性分组.rtf")

* --- 9.2 每家企业各自回归（cell 76/77）------------------------------------
* notebook 用 PooledOLS + cov_type='robust'（单企业无法识别企业固定效应），
* 对应 Stata 的 regress + vce(robust)。
display _n(2) "【9.2】各企业单独回归（企业数 = `nfirm'）"

display _n "----- 版本A：TobinQ ~ Subsidy + RD + CF + GM + SalesQ + Subsidy_RD -----"
display "企业 | N | subsidy | rd | subsidy_rd (p值)"
foreach c of local firm_list {
    capture quietly regress tobinq subsidy rd cf gm salesq subsidy_rd ///
        if code == "`c'", vce(robust)
    if _rc != 0 {
        display "`c' | 回归失败（解释变量缺失或共线）"
    }
    else if _se[subsidy_rd] == 0 | _se[subsidy] == 0 {
        display "`c' | " e(N) " | 系数被省略（该企业样本内变量无变异或与其它变量共线）"
    }
    else {
        local b_i = _b[subsidy_rd]
        local p_i = 2 * ttail(e(df_r), abs(_b[subsidy_rd]/_se[subsidy_rd]))
        display "`c' | " e(N) " | " %9.4f _b[subsidy] " | " %9.4f _b[rd] ///
                " | " %9.4f `b_i' "  (p = " %6.4f `p_i' ")"
    }
}

display _n "----- 版本B：TobinQ ~ Subsidy + RD + Subsidy_RD -----"
display "企业 | N | subsidy | rd | subsidy_rd (p值)"
foreach c of local firm_list {
    capture quietly regress tobinq subsidy rd subsidy_rd if code == "`c'", vce(robust)
    if _rc != 0 {
        display "`c' | 回归失败（解释变量缺失或共线）"
    }
    else if _se[subsidy_rd] == 0 | _se[subsidy] == 0 {
        display "`c' | " e(N) " | 系数被省略（该企业样本内变量无变异或与其它变量共线）"
    }
    else {
        local b_i = _b[subsidy_rd]
        local p_i = 2 * ttail(e(df_r), abs(_b[subsidy_rd]/_se[subsidy_rd]))
        display "`c' | " e(N) " | " %9.4f _b[subsidy] " | " %9.4f _b[rd] ///
                " | " %9.4f `b_i' "  (p = " %6.4f `p_i' ")"
    }
}

*==============================================================================
* 第十部分：结果汇总
*==============================================================================
display _n(2) "=================================================="
display "第十部分：主要结果汇总"
display "=================================================="
show_models m1_twovar m2_base m3_nogm m4_lasso m_soeA m_soeB, ///
    title("主要模型汇总") ///
    mtitles("双变量" "基础模型" "无GM" "Lasso筛选" "模型A" "模型B") ///
    keep(subsidy_c rd_c subsidy_c_soe cf_c salesq_c gm_c) ///
    file("表_主要模型汇总.rtf")

display _n "已生成文件："
display "  - 面板分析_面板分析.log     运行日志（含全部回归输出）"
display "  - 表_*.rtf                  各结果表（esttab 可用时生成）"
display "  - 图_pca企业聚类.png、图_lasso路径图.png"

capture log close
display _n "====================== 全部完成 ======================"
