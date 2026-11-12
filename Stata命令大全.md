# 📘 Stata 命令大全（运算符 · 横截面 · 时间序列 · 面板 · 因果分析）

> **通用格式说明**
>
> ```
> ❖ 命令名称  [语法快捷写法]
> ├─ 功能：一句话讲清这个命令做什么、解决什么问题
> ├─ 语法：命令的完整写法
> ├─ 参数说明：（表格，逐项解释）
> ├─ 输出结果：输出哪些统计量 / 存在 e()、r() 里的名字
> ├─ 常用选项：(options，逐行注释)
> ├─ 配套检验命令：这条命令跑完后通常要接着做的检验/诊断（本书重点补充）
> ├─ 结果怎么读 · 常见坑：假设前提、易错点、与相邻命令的区别
> └─ 示例：一到两个真实写法
> ```
>
> **每一章的安排**：章标题下先给一张 `📋 本章检验命令速览` 表（检验什么 / 原假设 / 前置命令 / 结论怎么读），
> 再逐条讲命令；每条命令后面都带 **配套检验命令**，方便"跑完回归马上知道该查什么"。

---

## 目录

- [运算符号与语法符号速查](#运算符号与语法符号速查)
- [第零部分 · 安装包使用说明（必读）](#第零部分--安装包使用说明必读)
- [第一部分 · 横截面数据（Cross-Sectional）](#第一部分--横截面数据cross-sectional)
- [第二部分 · 时间序列（Time Series）](#第二部分--时间序列time-series)
- [第三部分 · 面板数据（Panel Data）](#第三部分--面板数据panel-data)
- [第四部分 · 因果分析（Causal Inference）](#第四部分--因果分析causal-inference)
- [附录 A · 数据处理命令（Data Management）](#附录-a--数据处理命令data-management)
- [附录 B · 画图命令（Graphing）](#附录-b--画图命令graphing)
- [附录 C · 常用细节 / 回归后诊断命令](#附录-c--常用细节--回归后诊断命令post-estimation--details)
- [📌 速查：一个完整实证分析的标准流程](#-速查一个完整实证分析的标准流程)

---

# 运算符号与语法符号速查

> **为什么放在最前面**：Stata 的报错有相当一部分不是命令写错，而是**符号**写错——`=` 当 `==` 用、
> `and` 当 `&` 用、`**` 当幂、字符串在 `display` 里用 `+` 拼、宏引用少一个反引号。
> 下面每一条结论都在 **Stata 18** 里实测过（✅ 能用 / ❌ 会报错，括号内是真实错误码）。
> 后面各章的语法都以这张表为准。

## 1. 一张表看懂（最常用 22 个符号）

| 符号 | 含义 | ✅ 正确写法 | ❌ 常见错误 |
|------|------|-------------|-------------|
| `=` | 赋值（`gen`/`replace`/`scalar`/`local`） | `gen y = ln(x)` | `gen y == ln(x)` ❌ |
| `==` | 判断相等 | `keep if sex == 1` | `keep if sex = 1` ❌ |
| `!=` 或 `~=` | 不等于 | `drop if x != .` | 写成 `<>` ❌ |
| `>` `<` `>=` `<=` | 大于 / 小于 / 不小于 / 不大于 | `keep if age >= 18` | — |
| `&` | 逻辑"且" | `if a > 0 & b < 1` | `and` ❌（r(111)） |
| `\|` | 逻辑"或" | `if a == 1 \| a == 2` | `or` ❌（r(111)） |
| `!` 或 `~` | 逻辑"非" | `if !missing(x)` | `not` ❌（r(111)） |
| `+` `-` `*` `/` | 加 减 乘 除 | `gen r = (a + b) / c` | — |
| `^` | 乘方 | `gen x2 = x^2` | `x**2` ❌（r(198)） |
| `.` | 数值缺失值 | `keep if x == .` | 用 `0` 代替缺失 ❌ |
| `""` | 字符串缺失（空串） | `if name == ""` | 用 `.` 比较字符串 ❌ |
| `*` | 变量名通配符 / 乘号（看上下文） | `drop var*` | 表达式里当通配符 ❌ |
| `-` | 变量区间 | `summarize inc1-inc9` | 表达式里当区间 ❌ |
| `` ` `` + `'` | 引用 local 宏 | `local a 1` → `` `a' `` | 只写 `` `a `` ❌ |
| `$` | 引用 global 宏 | `global V "y x1"` → `reg $V` | — |
| `i.` | 因子/指示变量（自动展开虚拟变量） | `reg y i.year` | 手动 `tab year, gen()` 后全放 ❌ |
| `#` `##` | 交互项 | `reg y c.x##c.z` | 以为 `x*z` 是交互 ❌ |
| `L.` `F.` `D.` | 滞后 / 领先 / 差分（需先 `tsset`/`xtset`） | `gen g = D.y` | 未声明时间就用 ❌ |
| `%td` `%tq` `%tm` | 日期 / 季度 / 月度显示格式 | `format d %td` | — |
| `_n` `_N` | 当前观测号 / 总观测数 | `gen id = _n` | 与 `n`、`N` 混用 ❌ |
| `_b[]` `_se[]` | 取回归系数 / 标准误 | `display _b[educ]` | 写成 `_b(educ)` ❌ |
| `//` `///` `*` `/* */` | 注释 / 续行 | `///` 同一行内续行 | 用 `\` 续行 ❌ |

---

## 2. 算术运算符

| 运算符 | 含义 | 示例 | 实测结果 |
|--------|------|------|----------|
| `+` | 加（也用于字符串拼接，但**只能在 `gen`/`replace` 里**） | `gen y = a + b` | ✅ |
| `-` | 减（也用作负数前缀） | `gen y = a - b` | ✅ |
| `*` | 乘 | `gen y = a * b` | ✅ |
| `/` | 除 | `gen y = a / b` | ✅ `10/3` = 3.3333333 |
| `^` | 乘方 | `gen x2 = x^2` | ✅ `2^3` = 8 |
| `**` | ❌ **Stata 不支持** | `display 2**3` | r(198) |
| `%` | ❌ **不是取余运算符** | `display 5%2` | r(198) |

- 取余要用函数：`mod(5,2)` → `1`。
- 整除/取整：`int(-2.7)` → `-2`（**向零截断**，不是四舍五入）；四舍五入用 `round()`：
  ```stata
  display int(-2.7)          // -2
  display round(2.5)         // 3     （.5 向上进位）
  display round(2.567, 0.01)  // 2.57  （第二个参数指定精度）
  ```
- 常用数学函数（都是标量/变量通用，元素级作用）：

| 函数 | 作用 | 示例 → 结果 |
|------|------|-------------|
| `abs(x)` | 绝对值 | `abs(-3)` → 3 |
| `sign(x)` | 符号（-1/0/1） | `sign(-3)` → -1 |
| `exp(x)` `ln(x)` `log10(x)` | 指数 / 自然对数 / 常用对数 | `ln(exp(1))` → 1，`log10(100)` → 2 |
| `sqrt(x)` | 平方根 | `sqrt(2)` → 1.4142136 |
| `min(a,b,...)` `max(a,b,...)` | 多参数取最小/最大 | `min(1,2)` → 1 |
| `mod(a,b)` | 取余 | `mod(5,2)` → 1 |
| `sum()` | ⚠️ **是生成函数**（按观测累计求和），**不能当多参数求和** | `sum(1,2,3)` → r(198) |

> 🔎 想对多个标量求和，直接写 `1+2+3`，或把它们放进 `matrix`／`local` 用 `: word count` 之类的扩展函数处理。

---

## 3. 关系（比较）运算符

| 运算符 | 含义 | 备注 |
|--------|------|------|
| `==` | 等于 | 与赋值 `=` 严格区分 |
| `!=` 或 `~=` | 不等于 | 两种写法都合法，实测 `1~=2` → 1 |
| `>` `<` `>=` `<=` | 大小比较 | 结果是 1（真）/ 0（假） |

```stata
display (1==1)        // 1
display (1~=2)        // 1
display (. == .)      // 1   ← 缺失值等于缺失值
display (.a > .)      // 1   ← 扩展缺失 .a 比基础缺失 . 更大
```

⚠️ **缺失值参与比较是本手册最重要的坑之一**：Stata 把 `.` 当作"比任何普通数字都大的值"，所以

```stata
display . > 0            // 1  ← 看起来是"缺失大于0"，为真！
display . < 0            // 0

count if price > 5000    // 会把 price 缺失的观测也统计进来！
count if price > 5000 & !missing(price)   // 正确写法
```

也就是说 `keep if x > 0` 会**保留** x 缺失的样本。做样本筛选时几乎总要补 `& !missing(x)`。

---

## 4. 逻辑运算符

| 运算符 | 含义 | 优先级 |
|--------|------|--------|
| `!` 或 `~` | 非 | 高 |
| `&` | 且 | 中 |
| `\|` | 或 | 低 |

```stata
display 1 & 0                       // 0
display 1 | 0                       // 1
display !0                          // 1
display (1 == 1) & (2 > 1)          // 1
display 1 + 1 == 2                  // 1  ← 算术先算，再比较
```

- ❌ `and` / `or` / `not` **在 Stata 里不合法**（实测 r(111)：`not not found`）。
  从 Python / SQL 过来的人最容易在这里翻车，只能用 `&`、`|`、`!`。
- 括号优先，条件多时**一律加括号**，别靠优先级。

---

## 5. 缺失值的表示与判断

| 类型 | 缺失写法 | 判断 | 说明 |
|------|----------|------|------|
| 数值型 | `.`（基础缺失）、`.a`–`.z`（扩展缺失） | `missing(x)` / `x == .` | 扩展缺失 `.a` 表示"不适用"等含义 |
| 字符型 | `""`（空串） | `x == ""` 或 `missing(x)` | `missing()` 对字符变量同样可用 |

- `.` 与 `.a`–`.z` 的关系：`.` < `.a` < `.b` < … < `.z`，但**都大于任何普通数字**。
- 缺失值会"传染"：`display 1/.` → `.`；`gen y = x*2` 中 x 缺失则 y 缺失。
- 只把缺失当缺失值看，`if x == .` 抓不到 `.a`；要抓所有缺失用 `if missing(x)`。

---

## 6. 变量列表的通配符与区间

| 写法 | 含义 | 示例 |
|------|------|------|
| `var*` | 以 var 开头的所有变量 | `drop gdp*` |
| `*var*` | 变量名含 var | `keep *income*` |
| `var?` | var 后跟 1 个任意字符 | `drop x?` |
| `x1-x9` | 数据集中按**变量排列顺序**从 x1 到 x9（不是按数值大小） | `summarize inc1-inc9` |
| `_all` | 全部变量 | `describe _all` |
| `*` 单独用 | 全部变量 | `summarize *` |
| `var[1]` | 变量 `var` 第 1 个观测的取值 | `display price[5]` |

```stata
* 通配符只在"变量列表"位置有效，不能用在表达式里
drop price*                      // ✅
* drop price * 2                // ❌ 这里是乘号
```

---

## 7. 宏（local / global）与引用符号

| 写法 | 含义 |
|------|------|
| `` local name value `` | 定义局部宏（只在当前 do-file / 程序内有效） |
| `` `name' `` | 引用局部宏：**前反引号 + 后单引号**，缺一不可 |
| `global NAME value` | 定义全局宏（跨 do-file、跨程序有效） |
| `$NAME` 或 `${NAME}` | 引用全局宏 |
| `` `=表达式' `` | 先求值再展开（如 `` `=2+3' `` → `5`） |
| `` local n : word count `v' `` | 扩展宏函数（`:` 后面是函数名） |

```stata
local vlist "subsidy rd lev"
regress y `vlist'                    // ✅ 展开成三个变量
* regress y vlist                   // ❌ 会去找名叫 vlist 的变量

global V "y x1 x2"
regress $V                            // ✅
regress ${V}                          // ✅ 边界更清楚，推荐
```

- 引用符号是**反引号开始、单引号结束**：`` `v' ``。写成 `'v'`、`` `v` `` 都会报错。
- 宏展开发生在**命令解析之前**，所以宏里的内容可以是变量名、命令、甚至整段语句。
- 局部宏的作用域是"当前 do-file 文件"；在 `program define ... end` 里定义的要按程序作用域理解。

---

## 8. 因子变量与交互项符号（Stata 15+ 的因子变量系统）

| 符号 | 含义 | 示例 |
|------|------|------|
| `i.var` | 把 var 当**类别**（自动生成虚拟变量；连续变量也可强制） | `regress y i.year` |
| `c.var` | 把 var 当**连续变量**（连续变量默认就是 c.） | `regress y c.income` |
| `ib#.var` / `ib(first).var` | 指定第 # 类为基准组 | `regress y ib2.region` |
| `o.var` | 省略该变量（用于手动控制共线） | `regress y i.year o.region` |
| `#` | 两个变量交互（不含主效应） | `regress y i.year#i.region` |
| `##` | 交互**含主效应**（等价于 `a b a#b`） | `regress y c.x##c.z` |
| `c.x#c.z` | 两个连续变量相乘（= x*z） | `regress y c.x#c.z` |
| `i.a#c.b` | 分组异质性斜率（每组的 b 斜率不同） | `regress y i.region#c.income` |
| `##c.` | 混合写法，注意 `##` 的展开规则 | `regress y i.region##c.income` |

```stata
* 实测：这两个都能直接跑
regress price i.foreign
regress price c.mpg##c.weight     // 输出 mpg、weight、c.mpg#c.weight 三项
```

⚠️ `x*z` **不是交互项**，只是普通乘法变量（而且会丢主效应）；要交互用 `c.x#c.z` 或 `c.x##c.z`。

---

## 9. 时间序列算子（必须先 `tsset` / `xtset`）

| 算子 | 含义 | 示例 |
|------|------|------|
| `L.` / `L1.` | 滞后 1 期 | `gen g = L.gdp` |
| `L2.` | 滞后 2 期 | `L2.gdp` |
| `F.` | 领先 1 期（未来值） | `F.gdp` |
| `D.` | 一阶差分 | `D.gdp` = `gdp - L.gdp` |
| `S.` | 季节差分 | `S12.m` |
| `L(1/4).x` | 一次性生成 1–4 阶滞后（配合回归） | `regress y L(1/4).x` |
| `x#L.x` | 与算子组合 | 少见，需要时用 `gen` 先造变量 |

```stata
tsset id year          // 面板：xtset id year
gen d_gdp = D.gdp
gen g_gdp = D.ln(gdp)  // 增长率
```

- 面板数据用 `xtset`；纯时间序列用 `tsset`；没声明就用 `L.` 会报 `may not use time-series operators`。
- 面板里有时间缺口时，`L.` 取的是"上一个时间点"，缺口处会返回缺失（不是"上一行"）。

---

## 10. 日期 / 时间格式符号与函数

| 格式 | 含义 | 存储单位 | 例 |
|------|------|----------|-----|
| `%td` | 日度（天） | 1960-01-01 = 0 | `display %td 22000` → `26mar2020` |
| `%tw` | 周度 | 1960 第 1 周 = 0 | `%tw` |
| `%tm` | 月度 | 1960m1 = 0 | `%tm` |
| `%tq` | 季度 | 1960q1 = 0 | `display %tq 243` → `2020q4` |
| `%th` | 半年 | 1960h1 = 0 | `%th` |
| `%tc` | 日期时间（毫秒） | 1960-01-01 00:00 = 0 | `%tc` |
| `%d` `%tD` 等 | 自定义/扩展 | — | 见 `help datetime` |

```stata
gen d  = date(sdate, "YMD")                // 字符串 → 日度日期
gen q  = quarterly(squarter, "YQ")         // 字符串 "2020Q4" → 季度
gen q2 = yq(real(substr(squarter,1,4)), real(substr(squarter,6,1)))  // 手动拼
format d %td                               // 显示成 26mar2020
```

⚠️ 常见坑：`date()` 的掩码（mask）用的是 `Y`/`M`/`D`，不是 `YMD` 之外的写法；`%td` 与 `%d` 不是一回事。

---

## 11. 数值与字符串的显示格式符号

| 格式 | 含义 | 例（实测输出） |
|------|------|----------------|
| `%9.2f` | 浮点，总宽 9，2 位小数 | `display %9.2f 1.2345` → `     1.23` |
| `%6.4f` | 浮点，4 位小数 | `display %6.4f 0.05` → `0.0500` |
| `%12.3e` | 科学计数法 | `display %12.3e 0.000123` → `   1.230e-04` |
| `%5.0g` | 自动格式 | `display %5.0g 12` → `   12` |
| `%-10s` | 字符串左对齐，宽 10 | `display %-10s "ab"` → `ab        ` |
| `%td` `%tq` | 日期/季度 | 见上一节 |

```stata
display "系数 = " %9.4f _b[educ] "   t = " %6.2f _b[educ]/_se[educ]
```

---

## 12. 矩阵符号

| 符号 | 含义 | 示例 |
|------|------|------|
| `matrix A = (1,2 \ 3,4)` | 定义矩阵（`\` 换行，`,` 分列） | 2×2 矩阵 |
| `A[1,2]` | 取元素（行,列） | `matrix list` 里查 |
| `A'` | 转置 | `matrix B = A'` |
| `*` | 矩阵乘法 | `matrix C = A*B` |
| `#` | 克罗内克积 | `matrix` 相关的 `#` |
| `[1\2]` | 列向量 | `matrix v = (1\2\3)` |
| `(1,2,3)` | 行向量 | `matrix r = (1,2,3)` |
| `diag(v)` / `det(A)` / `inv(A)` | 对角阵 / 行列式 / 求逆 | `matrix D = diag(v)` |

```stata
matrix A = (1,2 \ 3,4)
matrix B = A'
matrix list B
display det(A)          // 用矩阵函数要求：display det(A)
```

---

## 13. 系统变量、估计结果与返回值符号

| 符号 | 含义 | 何时可用 |
|------|------|----------|
| `_n` | 当前观测的序号（组内序号在 `by` 前缀下是**组内**的） | 总是 |
| `_N` | 总观测数（`by` 前缀下是组内观测数） | 总是 |
| `_rc` | 上一条命令的返回码（0 = 成功） | `capture` 之后 |
| `_b[varname]` | 上一条估计命令的系数 | 回归之后 |
| `_se[varname]` | 标准误 | 回归之后 |
| `_b[_cons]` / `_se[_cons]` | 常数项 | 回归之后 |
| `e(name)` | 上一条**估计命令**存下的标量/矩阵/宏 | 估计之后（`e(N)`、`e(r2)`、`e(df_r)`） |
| `r(name)` | 上一条命令存下的普通返回值 | 多数命令之后（`r(mean)`、`r(N)`、`r(F)`） |
| `c(name)` | 系统参数（`c(N)`、`c(pwd)`、`c(current_date)`） | 总是 |
| `s(name)` | 程序/SVAR 返回值 | 少数命令 |

```stata
quietly summarize price
display r(mean)          // 均值
display r(N)             // 观测数
regress y x
display _b[x] " " _se[x] // 系数与标准误
```

⚠️ `r()` 会被**下一条命令**覆盖，要用就马上取；想长期保存请 `scalar` / `local` 存起来。

---

## 14. 命令前缀、冒号与外部文件符号

| 写法 | 作用 | 示例 |
|------|------|------|
| `quietly:` / `quietly ` | 不打印输出 | `quietly summarize x` |
| `noisily:` | 强制打印（在 `quietly` 里临时输出） | `noisily summarize x` |
| `capture:` | 出错也不中断，错误码存 `_rc` | `capture drop x` |
| `by varlist:` | 分组执行（先排序） | `by id: gen t = _n` |
| `bysort varlist:` | 先排序再分组（更安全） | `bysort id: egen m = mean(x)` |
| `frame name:` | 在指定 frame 里执行 | `frame raw: summarize` |
| `using 文件名` | 读写外部文件（后面不跟等号） | `save x.dta, replace`、`esttab m1 using t.rtf` |
| `>` 重定向 | Stata 里**不用于**重定向（那是 shell） | 输出到文件用 `log using` |
| `,` | 选项的起点（命令与选项之间的分隔） | `regress y x, robust` |

```stata
capture drop oldvar           // 不存在也不报错
if _rc != 0 display "出错了"
quietly: summarize price, detail
```

---

## 15. 注释、续行与分隔

| 写法 | 作用 | 说明 |
|------|------|------|
| `* 注释` | 整行注释 | `*` 必须在该行**第一列** |
| `// 注释` | 行内注释 | 可放在语句后面 |
| `///` | 续行 | 放在行尾，把下一行接上 |
| `/* ... */` | 块注释 | 可跨多行 |
| `#delimit ;` … `;` | 改变语句结束符 | 特殊场景用，一般不用 |

```stata
regress y x1 x2, ///
        robust cluster(id)      // ✅ 续行
* regress y x1 x2 \             // ❌ 不能用反斜杠续行
```

---

## 16. 运算符优先级（从高到低）

| 优先级 | 运算符 | 说明 |
|--------|--------|------|
| 1 | `()` | 括号（最保险，多用） |
| 2 | 函数 `ln()` `abs()` … | 函数调用 |
| 3 | `^` | 乘方 |
| 4 | `-` `+`（一元正负）、`!` `~` | 取负、逻辑非 |
| 5 | `*` `/` | 乘除 |
| 6 | `+` `-` | 加减 |
| 7 | `>` `<` `>=` `<=` | 大小比较 |
| 8 | `==` `!=` `~=` | 相等比较 |
| 9 | `&` | 且 |
| 10 | `\|` | 或 |

> 记不住就**加括号**：`if (a == 1 | a == 2) & b > 0` 比靠优先级靠谱得多。

---

## 17. 新手最容易踩的 10 个符号坑

1. **`=` 和 `==` 混用**：`keep if sex = 1` → `= invalid name`；判断必须 `==`。
2. **`and` / `or` / `not` 不存在**：只能用 `&`、`|`、`!`（实测 r(111)）。
3. **`**` 不是幂**：Stata 只有 `^`；`2**3` 直接 r(198)。
4. **`%` 不是取余**：用 `mod()`。
5. **`sum()` 不能求多个数之和**：它是生成函数（累计求和）；标量相加直接写 `a+b+c`。
6. **字符串拼接的 `+` 只认 `gen`/`replace`**：`display "a" + "b"` → r(198)；
   想打印拼接结果用 `display "a" "b"`（多个参数会连续输出）或先 `local p "a"` 再 `display "`p'" "b"`。
7. **缺失值"最大"**：`if x > 0` 会把缺失值留下；筛选样本时补 `& !missing(x)`。
8. **`*` 有两副面孔**：在变量列表里是通配符（`drop gdp*`），在表达式里是乘号。
9. **宏引用必须成对**：`` `v' ``，少一个反引号或单引号都会炸。
10. **`-` 变量区间按变量顺序**：`x1-x9` 取的是数据集里 x1 到 x9 **之间**的所有变量，不一定是 9 个。

---

## 18. 常用函数符号速查

| 类别 | 函数 | 说明 |
|------|------|------|
| 数学 | `abs` `exp` `ln` `log10` `sqrt` `mod` `int` `round` `sign` `min` `max` | 见第 2 节 |
| 统计（generate 用） | `mean` `sd` `sum` `rmean` `rsum` `rowtotal` `rowmiss` `rowmax` `rowmin` | 注意：行函数以 `row` 开头，按"行"（观测）算 |
| 字符串 | `substr` `strpos` `strlen` `ustrlen` `word` `upper` `lower` `trim` `itrim` `subinstr` `strtoname` | `ustrlen("中文abc")` → 5，`strlen` → 9（字节数） |
| 正则 | `regexm` `regexr` `regexs` `ustrregexm` | `regexm("abc123","[0-9]+")` → 1 |
| 类型转换 | `real` `string` `strofreal` `destring` `tostring` `encode` `decode` | 字符串↔数值 |
| 日期 | `date` `daily` `monthly` `quarterly` `halfyearly` `yearly` `yq` `ym` | 见第 10 节 |
| 缺失 | `missing` `!missing` | 数值/字符串通用 |
| 随机 | `runiform` `rnormal` `rpoisson` `rbinomial` | 结合 `set seed` 可复现 |

```stata
display substr("abcdef", 2, 3)      // bcd
display strpos("abcdef", "cd")      // 3
display ustrlen("中文abc")           // 5
display word("a b c", 2)            // b
display regexm("abc123", "[0-9]+")  // 1
display subinstr("a-b", "-", "+", .) // a+b
display strtoname("1st")            // _1st
```

---

# 第零部分 · 安装包使用说明（必读）

> Stata 的命令分为**官方内置**与**第三方安装（SSC/Binary/Net）**两类。搞清楚哪个命令要装、怎么装，能省掉一大半莫名其妙的报错。下面先讲清楚，再进入各命令部分。

---

## 0.1 什么是"官方命令"与"第三方命令"？

| 类型 | 说明 | 是否需要安装 |
|------|------|--------------|
| **官方内置命令** | Stata 自带的命令，装好 Stata 就能用 | ❌ 不需要 |
| **官方 ado 更新** | Stata 官方发布的升级包，随版本自带 | 通常已包含 |
| **第三方 SSC 命令** | 学者上传到 SSC 服务器（ssc install）| ✅ 需要安装 |
| **第三方 GitHub/Binary** | 通过 `net install` / GitHub 安装 | ✅ 需要安装 |

- **判断一个命令是否官方**：直接输入 `which 命令名`。如果返回类似 `built-in command` 或在 Stata 安装目录 `ado\base\` 下，就是官方的；如果提示 `command not found`，说明需要安装。
  ```stata
  which regress        // 官方内置 → 不用装
  which reghdfe        // 未安装 → 报错，提示需要 ssc install
  ```

---

## 0.2 三种安装方式（按场景选择）

| 场景 | 安装命令 | 说明 |
|------|----------|------|
| 从 **SSC** 安装（最常见）| `ssc install 包名` | 推荐首选，服务器稳定 |
| 从 **Net（可用离屏网/pkgs 目录）** 安装 | `net install 包名, from(网址)` | 用于 GitHub 等 |
| 从 **GitHub** 安装 | `net install 包名, from("https://raw.githubusercontent.com/.../master")` | 新版命令常用 |

### ① `ssc install`（最常用）
```stata
ssc install reghdfe
ssc install reghdfe, replace        // 更新到最新版本
```

### ② `net install`（从网站/仓库装）
```stata
net install coefplot, from("https://github.com/ssccmd/coefplot/raw/master")
```

### ③ 查看已安装哪些包
```stata
adopath              // 查看 ado 搜索路径
which 命令名          // 查看某命令是否已装及其路径
ado describe 包名     // 查看某包的描述
adoupdate, update    // 更新所有官方 ado 文件到最新
```

---

## 0.3 本文档涉及的"需要安装的包"清单

> 下表整理了本文档全部非官方命令，**首次使用请先执行对应 `ssc install`**。

| 包名 | 用途 | 安装命令 |
|------|------|----------|
| `reghdfe` | 高维固定效应回归 | `ssc install reghdfe` |
| `coefplot` | 系数图（可视化）| `ssc install coefplot` |
| `ivreg2` | 增强 IV（含 GMM）| `ssc install ivreg2` |
| `ranktest` | IV 秩检验（`ivreg2` 依赖）| `ssc install ranktest` |
| `overid` | 过度识别检验辅助 | `ssc install overid` |
| `rdrobust` | 断点回归 RDD | `ssc install rdrobust` |
| `rdbwselect` | RDD 带宽选择 | 随 `rdrobust` 安装 |
| `rddensity` | McCrary 密度检验 | `ssc install rddensity` |
| `synth` | 合成控制法 SCM | `ssc install synth` |
| `synth_runner` | 合成控制 + 安慰剂 | `ssc install synth_runner` |
| `gsynth` | 广义合成控制 | `ssc install gsynth` |
| `pstest` | 倾向得分平衡性 | `ssc install pstest` |
| `psmatch2` | 经典 PSM（第三方）| `ssc install psmatch2` |
| `bacondecomp` | DID 的 Bacon 分解 | `ssc install bacondecomp` |
| `csdid` | DID：Callaway–Sant’Anna | `ssc install csdid` |
| `did_imputation` | DID：插补估计量 | `ssc install did_imputation` |
| `eventstudyinteract` | 事件研究（Sun–Abraham）| `ssc install eventstudyinteract` |
| `binscatter` | 分箱散点图 | `ssc install binscatter` |
| `outreg2` | 结果导出 Word/Excel | `ssc install outreg2` |
| `asdoc` | 一键导出 Word | `ssc install asdoc` |
| `estout/esttab/eststo` | 结果整理（厂商官方命令，需安装）| `ssc install estout` |
| `vif` | 方差膨胀因子 | 官方内置，无需安装 |
| `partial` | 拉索双选（PDS-Lasso）| `ssc install partial` |
| `rlasso` | 惩罚回归 | `ssc install rlasso` |
| `winsor2` | 缩尾处理 | `ssc install winsor2` |
| `xtserial` | 面板自相关检验（Wooldridge）| `ssc install xtserial` |
| `xttest3` | 面板异方差检验（组间异方差）| `ssc install xttest3` |
| `xtcsd` | 面板截面相关检验（Pesaran）| `ssc install xtcsd` |
| `xtabond2` | 动态面板 GMM | `ssc install xtabond2` |
| `factortest` | KMO / Bartlett（因子适用性）| `ssc install factortest` |
| `mdesc` | 缺失值比例一览 | `ssc install mdesc` |
| `carryforward` | 缺失值前向填充 | `ssc install carryforward` |
| `winsor` | 老版缩尾命令（`winsor2` 的前身）| `ssc install winsor` |
| `devil` | 结果表格/图输出（可生成 HTML/LaTeX）| 官方内置（`help devil`） |

---

## 0.4 常见安装报错与解决

| 报错信息 | 原因 | 解决方法 |
|----------|------|----------|
| `command xxx is unrecognized` | 未安装或输入拼写错误 | `ssc install xxx` 安装 |
| `connection timed out` | 网络问题（SSC 服务器在国外）| 重试，或用代理；必要时用 `net install` 从国内镜像/ GitHub |
| `already installed` | 已装过 | 加 `, replace` 强制覆盖更新 |
| `file already exists` | 同名冲突 | 检查是否有同名 do/adofile |
| `file ... cannot be modified or erased`（r(608)）| 文件被占用（如正在写的 log、或批处理模式下 Stata 自己占着同名 log）| 关掉占用进程 / 换日志文件名 |

---

## 0.5 官方 vs 非官方：快速判断一句话

- **能用的就是装了/内置的**：遇到 `unrecognized` 就先 `ssc install`。
- **官方命令出现的概率高**：数据管理、`regress`、`summarize`、`gen`、`merge`、`reshape`、`xtreg`、`tsset`、`arima`、`tabulate`、`graph` 系列的 `twoway/scatter/histogram/kdensity` 等均为**官方内置**，无需任何安装。
- **检验类命令大部分是官方的**（`estat` 系列、`test`、`lincom`、`hausman`、`dfuller`、`arima` 后诊断等），但**面板的异方差/自相关/截面相关检验（`xttest3`/`xtserial`/`xtcsd`）和 RDD 的密度检验（`rddensity`）是第三方的**，写论文前记得装。

> 💡 提示：进入正式实证前，建议一次性把上面清单里需要的包全部 `ssc install`，避免中途报错。

---

# 第一部分 · 横截面数据（Cross-Sectional）

> 横截面数据：同一时间点、多个不同个体的观测（如一次调查的样本）。核心是**普通回归、广义线性模型、非线性模型与诊断检验**。

---

## 📋 本章检验命令速览

> 下表集中列出本章涉及的检验/诊断命令。**除 `fitstat` 为外部命令（需 `ssc install fitstat`）外，其余均为 Stata 官方命令**；凡标注"前置命令"的，必须在该估计命令之后、估计结果仍在内存中时使用（`estat` 系列尤其如此）。

| 检验/诊断命令 | 检验什么 | 原假设 H0 | 前置命令 | 结论怎么读 |
|------|------|------|------|------|
| `estat vif`（或 `vif`） | 多重共线性 | 无共线性（各 VIF=1） | `regress` | VIF>10 或 1/VIF<0.1 → 严重共线，删变量/合并/主成分 |
| `estat hettest` | 异方差（Breusch–Pagan） | 同方差 | `regress` | P<0.05 → 加 `, robust` 或 `, vce(cluster id)` |
| `estat imtest, white` | 异方差（White 检验） | 同方差 | `regress` | P<0.05 → 存在异方差，同上处理 |
| `estat ovtest` | 函数形式设定（Ramsey RESET） | 无遗漏的非线性项 | `regress` | P<0.05 → 试加平方项/交互项/取对数 |
| `estat dwstat` | 一阶自相关（Durbin–Watson） | 无一阶自相关 | `regress`（按时间排序） | d≈2 无自相关；<1.5 正自相关；>2.5 负自相关 |
| `linktest` | 链接函数与整体设定 | 设定正确（`_hatsq` 系数=0） | `regress`/`logit`/`poisson` 等 | `_hatsq` 显著 → 设定有误 |
| `sktest` | 偏度-峰度正态性 | 服从正态 | 无需前置 | P<0.05 → 拒绝正态，考虑取对数 |
| `swilk` | Shapiro–Wilk 正态性 | 服从正态 | 无需前置 | P<0.05 → 偏离正态；n>5000 慎用 |
| `test` | 单个/联合线性约束 | 约束成立（如 β₁=β₂=0） | 任意估计命令 | P<0.05 → 拒绝约束，系数显著或不相等 |
| `testparm` | 一组变量联合显著性 | 该组系数全为 0 | 任意估计命令 | P<0.05 → 该组变量联合显著 |
| `lincom` | 系数的线性组合 | 组合值=0 | 任意估计命令 | 读 estimate 与 P 值，可加 `, level(90)` |
| `margins, dydx(*)` | 平均边际效应（AME） | 边际效应=0 | `logit`/`probit`/`ologit`/`tobit` 等 | 符号同系数，量级按"概率/期望变化"读 |
| `margins, at(...)` | 特定取值处的预测值/概率 | 无（描述性） | 上述非线性模型 | 检查预测概率是否落在 0–1 |
| `estat classification` | 预测分类正确率（混淆矩阵） | 无（描述性） | `logit`/`logistic`/`probit` | 正确率须明显高于"全猜多数类"的基准 |
| `lroc` | ROC 曲线与 AUC | AUC=0.5（无判别力） | `logit`/`logistic`/`probit` | AUC>0.7 尚可、>0.8 好、≈0.5 等于瞎猜 |
| `estat gof` | 拟合优度（Pearson χ²；`, group(#)` 做 HL） | 模型拟合良好 | `logit`/`logistic`/`probit` | P<0.05 → 拟合不足 |
| `estat ic` | 信息准则 AIC/BIC | 无（比较用） | 任意估计命令 | 越小越好；只能同一样本、同一因变量间比较 |
| `fitstat`（外部命令） | 综合拟合指标 | 无（报告用） | `logit`/`logistic` 等 | 伪 R² 只是参考，别当 OLS 的 R² 读 |
| `tabulate ..., chi2` | 两变量独立性（列联表 χ²） | 相互独立 | 无需前置 | P<0.05 → 有关联；再看 Cramér's V 判强度 |
| `ttest` | 均值相等（单/两样本/配对） | 均值相等 | 无需前置 | P<0.05 → 均值差异显著 |
| `sdtest` | 两组方差是否相等 | 方差相等 | 无需前置 | P<0.05 → 方差不齐，`ttest` 加 `, unequal` |
| `anova` | 多组均值是否全相等 | 各组均值相等 | 无需前置 | 看 `Prob > F`；显著仅说明"至少一组不同" |
| `pwcompare` | 组间两两比较（含校正） | 两组均值相等 | `anova` 或 `margins` | 看校正后 P 值与置信区间是否跨 0 |
| `nbreg` 的 LR 检验 | 过度离散参数 α 是否为 0 | α=0（泊松已足够） | `poisson`/`nbreg` | P<0.05 → 存在过度离散，改用 `nbreg` |

---

## ❖ `regress` （多元线性回归 OLS）

- **功能**：对因变量与一个或多个自变量做普通最小二乘(OLS)回归，是计量中最核心的命令。它解决"控制其他因素后 x 对 y 的平均影响有多大"，同时是 `estat vif`、`estat hettest`、`estat ovtest`、`linktest` 等检验的**前置命令**。
- **语法**：
  ```stata
  regress depvar indepvars [if] [in] [weight] [, options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` | 因变量（被解释变量）y，连续变量 |
| `indepvars` | 自变量 x₁ x₂ …；分类变量写成 `i.var` |
| `[if] [in]` | 条件筛选 `if edu>3`；行范围 `in 1/100` |
| `[weight]` | 权重，如 `[aw=w]` 分析权重、`[fw=w]` 频数权重 |

- **输出结果**：回归系数、标准误、t值、P值、95%置信区间、R²、调整 R²、F统计量、残差平方和等。结果名：`e(N)`、`e(df_m)`/`e(df_r)`、`e(F)`、`e(r2)`、`e(r2_a)`、`e(rmse)`、`e(mss)`/`e(rss)`、`e(b)`/`e(V)`、`e(sample)`。
- **常用选项**：
  ```stata
  , robust            // 稳健标准误（异方差稳健），estat hettest 显著后必备
  , vce(cluster id)   // 聚类稳健标准误，个体内相关时用
  , beta              // 标准化回归系数，便于比较变量相对重要性
  , nocons            // 不加常数项（仅当理论上 y 必过原点）
  ```
- **配套检验命令**：
  ```stata
  estat vif            // 多重共线性：看解释变量是否"打架"
  estat hettest        // 异方差 B-P 检验：决定要不要加 , robust
  estat ovtest         // RESET 设定检验：查有无遗漏非线性项
  linktest             // _hatsq 是否显著，快速判断整体设定
  ```
- **结果怎么读 · 常见坑**：
  1. P 值是"控制其他变量后"的偏效应；单变量显著、多元后不显著很常见（共线性或中介），不必惊慌。
  2. 横截面微观数据 R² 只有 0.1–0.3 很正常，重点看系数符号与显著性是否符合理论。
  3. `, robust` 只改标准误、不改点估计；**先 `estat hettest` 再决定是否 robust** 才有依据。
  4. 分类变量必须写 `i.region`，直接放数值编码会被当连续变量，系数含义完全不同。
- **示例**：
  ```stata
  regress wage edu exp, robust
  regress wage edu i.region, vce(cluster firmid)
  ```

---

## ❖ `esttab` / `eststo` （回归结果输出与表格整理）

- **功能**：将多个回归结果整理成一张美观的表格输出到 Stata 窗口或导出为 Word/LaTeX。它解决"十几个回归怎么并成一张论文表"，本身不做估计，只做结果搬运，常与 `estimates store`、`estout` 配合。
- **语法**：
  ```stata
  eststo name1: regress y x1 x2
  esttab name1 name2 [, options]
  esttab name1 name2 using "文件名.rtf" [, options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `eststo name:` | 把紧随其后的回归结果存为 `name`（即 `estimates store`） |
| `esttab list` | 按列表导出多模型并列，列的先后即 list 顺序 |
| `using "文件"` | 导出到 `.rtf`/`.doc`/`.csv`/`.tex`；加 `replace` 覆盖 |
| `eststo clear` | 清空已存模型，换新表前先执行 |

- **输出结果**：不返回 `e()`/`r()`，输出排版后的表格。想看被搬运的原始统计量用 `estimates stats`。
- **常用选项**：
  ```stata
  , star(* 0.1 ** 0.05 *** 0.01)   // 显著性星号
  , b(3) se(3)                     // 3位小数显示系数、标准误
  , r2 ar2                        // 显示 R²、调整 R²
  , stats(N r2_a, labels("样本量" "调整R²"))   // 表底附加统计量
  ```
- **配套检验命令**：
  ```stata
  estimates stats m1 m2       // 并排比较 N、R²、AIC，查各列样本量是否一致
  estimates table m1 m2, star // 不装 estout 时的替代方案
  esttab m1 m2, stats(N r2_a) // 表底附统计量，审稿人最爱看 N
  ```
- **结果怎么读 · 常见坑**：
  1. 各列**样本量必须一致或注明差异**：加变量导致 N 变化时，系数不可跨列直接比较。
  2. `esttab` 默认显示系数与 t 值，论文里请显式写 `se`；`using "结果.doc"` 实际生成 RTF 内容，以 `.rtf` 命名更稳。
  3. `eststo`/`esttab` 需先 `ssc install estout`；忘记 `eststo clear` 会把旧模型混进新表。
- **示例**：
  ```stata
  eststo m1: regress wage edu
  eststo m2: regress wage edu exp, robust
  esttab m1 m2, b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) r2 title("工资决定因素")
  ```

---

## ❖ `summarize` （描述性统计）

- **功能**：计算变量的描述性统计量（观测数、均值、标准差、min、max 等）。它是回归前的**第一步体检**：看样本量、量纲、极端值，也常与 `sktest`/`swilk` 配合判断是否需要取对数。
- **语法**：
  ```stata
  summarize [varlist] [if] [in] [weight] [, options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `varlist` | 要统计的变量列表，省略则统计全部变量 |
| `[if] [in]` | 条件与范围，如 `if gender==1` |
| `[weight]` | 权重，如 `[aw=w]` |

- **输出结果**：Obs（n）、Mean、Std. Dev.、Min、Max。结果存入 `r()`：`r(N)`、`r(mean)`、`r(sd)`、`r(min)`、`r(max)`、`r(sum)`、`r(Var)`；加 `, detail` 后还有 `r(p50)`、`r(skewness)`、`r(kurtosis)`。
- **常用选项**：
  ```stata
  , detail    // 详细统计量（分位数、偏度、峰度、方差、变异系数）
  , meanonly  // 只算均值，速度快，常配合 r(mean) 做标准化
  ```
- **配套检验命令**：
  ```stata
  sktest wage                  // 偏度-峰度正态性检验
  swilk wage                   // Shapiro–Wilk 正态性检验（小样本首选）
  tabstat wage, stat(p50 iqr)  // 偏态时改看中位数与四分位距
  ```
- **结果怎么读 · 常见坑**：
  1. `Obs` 比样本总量少说明有缺失；回归的 N 会进一步缩小，需提前核对。
  2. 均值远大于中位数（`detail` 的 50% 分位）→ 右偏严重，考虑 `ln()`。
  3. 标准差远大于均值（变异系数大）→ 离散度高，回归时留意异方差。
  4. 与 `tabstat` 的分工：前者一屏速览，后者适合成表输出并支持 `by()` 分组。
- **示例**：
  ```stata
  summarize wage edu age
  summarize wage, detail
  ```

---

## ❖ `tabstat` （多变量统计表）

- **功能**：一张表里成组展示多个变量的多个统计量，比 summarize 更灵活。它解决"论文表 1 描述性统计"的排版问题，常与 `by()` 分组配合使用。
- **语法**：
  ```stata
  tabstat varlist [if] [in] [, statistics(statlist) by(groupvar) options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `varlist` | 要统计的变量列表 |
| `statistics(statlist)` | 需要的统计量，如 `mean sd min max n` |
| `by(groupvar)` | 按分组变量分别统计（分组变量本身不再统计） |
| `columns(statistics)` | 统计量排成列而非行；`save` 把结果存进 `r()` |

- **输出结果**：按变量分行、按统计量分列的表。常用关键字：`mean`、`sd`、`min`、`max`、`n`、`p50`、`sum`、`cv`、`iqr`、`var`、`skewness`、`kurtosis`。
- **常用选项**：
  ```stata
  , statistics(mean sd n)   // 需要的统计量
  , by(gender)              // 按分组变量分别统计
  , columns(statistics)     // 统计量作为列
  , missing format(%9.3f)   // 缺失值单列一组；统一小数位
  ```
- **配套检验命令**：
  ```stata
  ttest wage, by(gender)    // 分组均值差异是否有统计意义
  tabulate gender           // 看各组样本量是否均衡
  sktest wage               // 组间比较前先看分布是否正态
  ```
- **结果怎么读 · 常见坑**：
  1. `by()` 要求分组变量为整数型；字符串分组变量请先 `encode`。
  2. 分组样本量悬殊（20 对 2000）时均值比较意义有限，先看 `n`。
  3. `tabstat` 只描述不检验，要检验必须接 `ttest`/`pwmean`/`anova`。
- **示例**：
  ```stata
  tabstat wage edu age, statistics(mean sd n) by(gender)
  tabstat wage edu, stat(mean sd p50 min max n) columns(statistics) format(%9.2f)
  ```

---

## ❖ `tabulate` （频率表 / 交叉表）

- **功能**：单变量频率分布表，或两变量交叉列联表（可用于 χ² 检验）。它解决"分类变量的分布与关联"，是 `ttest`、`anova`、`logit` 之前了解数据结构的常用一步。
- **语法**：
  ```stata
  tabulate varname1 [varname2] [if] [in] [weight] [, options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `varname1` | 单变量时出频率表；两变量时为**行**变量 |
| `varname2` | 交叉表的**列**变量 |
| `, chi2` | 加做 Pearson χ² 独立性检验 |
| `, row` / `, col` | 行/列百分比；`, cell` 显示单元格百分比 |
| `, exact` | Fisher 精确检验（期望频数<5 时必用） |

- **输出结果**：频数、百分比、累计百分比；交叉表加 `chi2` 后显示 Pearson χ²、似然比 χ²、Fisher P 值。存于 `r()`：`r(N)`、`r(r)`、`r(c)`、`r(chi2)`、`r(p)`、`r(CramersV)`。
- **常用选项**：
  ```stata
  , chi2        // 卡方独立性检验
  , row         // 显示行百分比
  , col         // 显示列百分比
  , missing     // 把缺失值也计入
  , exact       // Fisher 精确检验
  ```
- **配套检验命令**：
  ```stata
  tabulate gender employment, chi2 row exact   // 独立性 + 精确检验
  tabodds employment gender                    // 各组的比数比(OR)及检验
  tabulate gender, missing                     // 先查缺失结构
  ```
- **结果怎么读 · 常见坑**：
  1. χ² 要求**期望频数≥5**；有单元格期望频数<5 时改看 `exact` 的 Fisher P 值。
  2. `chi2` 显著只说明"有关联"，强度看 `r(CramersV)`（0–1，越大越强）。
  3. `row` 是行内占比、`col` 是列内占比，写论文前先想清楚谁是分母。
  4. 三分类以上只能得到整体 χ²；两两比较连续变量用 `pwmean`，二值用 `tabodds`。
- **示例**：
  ```stata
  tabulate gender
  tabulate gender employment, chi2 row
  ```

---

## ❖ `ttest` （t 检验）

- **功能**：均值 t 检验——单样本、独立两样本、配对样本。它解决"两组均值差异是否显著"，是最简单的组间比较工具；`regress y treat` 与其等价，也是 `anova` 的两组特例。
- **语法**：
  ```stata
  ttest varname == value                 // 单样本
  ttest varname, by(groupvar)            // 两独立样本
  ttest var1 == var2                     // 配对样本
  ttesti n1 mean1 sd1 n2 mean2 sd2       // 汇总数据
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `varname == value` | 单样本检验，H0：均值等于 `value` |
| `by(groupvar)` | 两独立样本，分组变量须为二分 |
| `var1 == var2` | 配对样本，H0：两变量均值相等 |
| `ttesti` | 用手头汇总统计量做检验，无需原始数据 |

- **输出结果**：各组 Obs、Mean、Std. Err.、Std. Dev.、95% 置信区间；差值、t 值、自由度、双侧 P 值。存于 `r()`：`r(mu_1)`、`r(mu_2)`、`r(sd_1)`、`r(sd_2)`、`r(N_1)`、`r(N_2)`、`r(mu_diff)`、`r(t)`、`r(df)`、`r(p)`。
- **常用选项**：
  ```stata
  , unequal      // 方差不等时的 Welch 校正（Satterthwaite 自由度）
  , welch        // 等价写法
  , level(90)    // 改置信水平
  ```
- **回归形式**：
  ```stata
  regress wage treat            // 等价于两样本 t 检验，便于加控制变量
  regress wage treat, robust    // 异方差下的稳健版本，比 ttest 更通用
  ```
- **配套检验命令**：
  ```stata
  sdtest wage, by(gender)   // 方差齐性：P<0.05 则 ttest 要加 , unequal
  robvar wage, by(gender)   // 稳健的方差齐性检验（Levene/Brown–Forsythe）
  pwmean wage, over(edu)    // 三组以上两两比较
  ```
- **结果怎么读 · 常见坑**：
  1. 默认假定**两组方差相等**；先跑 `sdtest`，方差不齐就用 `, unequal`。
  2. 配对样本必须写 `ttest var1 == var2`（同批人测两次），误用 `by()` 会丢掉配对信息。
  3. `by()` 的分组变量只能有两个取值，三组以上会报错，改用 `anova`/`pwmean`。
  4. t 检验只比较均值；中位数比较用 `ranksum`，小样本严重偏斜时考虑非参数方法。
- **示例**：
  ```stata
  ttest wage, by(gender) unequal
  ttesti 100 5200 1800 120 4800 1600, unequal
  ```

---

## ❖ `anova` （方差分析）

- **功能**：单因素/多因素方差分析（ANOVA），检验组间均值差异。它解决"三组以上均值是否全相等、因素间是否有交互"，是 `ttest` 的多组推广，与 `regress` 加 `i.` 虚拟变量等价。
- **语法**：
  ```stata
  anova depvar factors [continuous] [if] [in] [, options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` | 因变量（连续） |
| `factors` | 分类因素，**不加 `i.`**，直接写变量名 |
| `a#b` | 交互项，如 `edu#gender` |
| `continuous` | 需控制的连续协变量（写在因素之后），即 ANCOVA |

- **输出结果**：方差来源、偏平方和（Partial SS）、自由度、均方、F 值、`Prob > F`，表底给 `R-squared`、`Adj R-squared`、`Root MSE`。存于 `e()`：`e(N)`、`e(F)`、`e(df_m)`、`e(df_r)`、`e(r2)`、`e(r2_a)`、`e(mss)`、`e(rss)`、`e(rmse)`。
- **常用选项**：
  ```stata
  , regress          // 以回归系数表输出，便于解释各组相对基准的差异
  , detail           // 显示更详细的平方和分解
  , repeated(pid)    // 重复测量方差分析（同一对象多次观测）
  ```
- **配套检验命令**：
  ```stata
  contrast edu                          // 主效应/交互效应假设检验（anova 专属）
  pwcompare edu, effects mcompare(bonferroni)   // 组间两两比较
  estat esize                           // 效应量（η²、ω²），判断差异的实际大小
  ```
- **结果怎么读 · 常见坑**：
  1. `anova` 里分类因素**不能写 `i.`**，`regress` 里则必须写 `i.`，两者相反。
  2. `Prob > F` 显著只说明"至少一组不同"，具体哪两组要接 `pwcompare`/`contrast`。
  3. 交互项显著时不能只读主效应，必须做简单效应分析（`margins` + `pwcompare`）。
  4. 方差不齐时经典 F 检验偏 liberal，可用 `regress y i.group, robust` 替代。
- **示例**：
  ```stata
  anova wage edu gender edu#gender
  pwcompare edu#gender, effects mcompare(bonferroni)
  ```

---

## ❖ `logistic` / `logit` （二值 Logit 回归）

- **功能**：因变量为 0/1 时做 Logit 回归。`logistic` 直接报告**几率比(or)**，`logit` 报告**log-odds 系数**。它解决"哪些因素影响事件发生概率"，跑完通常紧接 `margins, dydx(*)` 求边际效应，并用 `estat classification`/`lroc` 评价判别力。
- **语法**：
  ```stata
  logistic depvar indepvars [if] [weight] [, options]
  logit    depvar indepvars [if] [weight] [, options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` | 二值因变量，非 0 即 1（1 表示"事件发生"） |
| `indepvars` | 解释变量，分类变量写 `i.var` |
| `[if] [in]` | 条件与范围 |
| `[weight]` | 频数权重 `[fw=]` 或概率权重 `[pw=]` |

- **输出结果**：系数（logit）或几率比（logistic）、标准误、z值、P值、95% 置信区间、伪 R²（McFadden）、对数似然。存于 `e()`：`e(N)`、`e(ll)`、`e(ll_0)`、`e(chi2)`、`e(df_m)`、`e(r2_p)`、`e(b)`/`e(V)`。
- **常用选项**：
  ```stata
  , or          // 报几率比（logistic 默认；logit 加 , or 也转几率比）
  , robust      // 稳健标准误
  , vce(cluster id)   // 聚类稳健标准误
  , nolog       // 不显示迭代过程
  ```
- **配套检验命令**：
  ```stata
  estat classification   // 混淆矩阵与正确分类率
  lroc                   // ROC 曲线与 AUC，看判别力
  estat gof              // 拟合优度（可加 , group(10) 做 HL 型检验）
  margins, dydx(*)       // 平均边际效应，最常报告的"实际影响"
  ```
- **结果怎么读 · 常见坑**：
  1. `logit` 系数是 log-odds 变化，**不是概率变化**；报"影响多少个百分点"必须用 `margins, dydx(*)`。
  2. `logistic` 的 OR>1 表示提高发生几率，**不是概率翻倍**；基准概率高时两者差别很大。
  3. 伪 R²（McFadden 0.2–0.4 已很好）与 OLS 的 R² 不可类比。
  4. 完全分离会让系数发散、样本被大量剔除；看 OR 是否异常巨大可识别。
- **示例**：
  ```stata
  logistic employment edu age, or
  margins, dydx(*)
  estat classification
  ```

---

## ❖ `probit` （二值 Probit 回归）

- **功能**：因变量为 0/1，用标准正态累计分布(CDF)建模（与 Logit 互补）。它解决同一类"二值选择"问题，系数约为 logit 的 0.6 倍；实际结论通常一致，跑完同样接 `margins, dydx(*)` 与 `lroc` 比较。
- **语法**：
  ```stata
  probit depvar indepvars [if] [in] [weight] [, options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` | 二值因变量（0/1） |
| `indepvars` | 解释变量，分类变量写 `i.var` |
| `[if] [in]` | 条件与范围 |

- **输出结果**：系数（潜变量尺度）、标准误、z值、P值、伪 R²、对数似然。存于 `e()`：`e(N)`、`e(ll)`、`e(ll_0)`、`e(chi2)`、`e(df_m)`、`e(r2_p)`、`e(b)`、`e(V)`。
- **常用选项**：
  ```stata
  , robust            // 稳健标准误
  , vce(cluster id)   // 聚类稳健标准误
  , nolog             // 不显示迭代过程
  ```
- **配套检验命令**：
  ```stata
  margins, dydx(*)        // 平均边际效应，probit 系数本身不可直接解释
  estat classification    // 分类正确率（默认阈值 0.5）
  lroc                    // AUC，用来与 logit 比较判别力
  estat gof, group(10)    // Hosmer–Lemeshow 型拟合优度
  ```
- **结果怎么读 · 常见坑**：
  1. probit 系数是"潜变量标准差单位"，量纲无直观含义，务必报告边际效应。
  2. probit 与 logit 的系数不能直接比大小，但**边际效应、AUC、预测概率几乎一致**。
  3. 同样会遇到完全分离；`estat classification` 的阈值可用 `cutoff()` 调整。
  4. `estat gof` 分组过多会因期望频数过小而失效。
- **示例**：
  ```stata
  probit employment edu age
  margins, dydx(*)
  estat classification, cutoff(0.4)
  ```

---

## ❖ `margins` （边际效应）

- **功能**：计算非线性模型（probit/logit）中解释变量对因变量概率的平均边际效应。它解决"系数不能直接读"的问题，是 logit/probit/ologit/mlogit/tobit 跑完后**必做**的一步，也常与 `marginsplot` 配合画图。
- **语法**：
  ```stata
  margins [marginlist] [, options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `marginlist` | 要计算的变量，`*` 表示全部 |
| `dydx(varlist)` | 求偏效应（连续变量为导数，虚拟变量为离散变化） |
| `at(var=值)` | 在指定取值处计算预测值或该点上的边际效应 |
| `predict(选项)` | 指定预测类型，如 `predict(outcome(4))`、`predict(pr)` |
| `, post` | 把结果存为 `e(b)`/`e(V)`，可再做 `test`、`lincom` |

- **输出结果**：边际效应（dy/dx）、Delta-method 标准误、z/t 值、P 值、置信区间。加 `, post` 后进入 `e(b)`、`e(V)`；不加时存于 `r(b)`、`r(V)`、`r(table)`（含系数、P 值、置信区间矩阵）。
- **常用选项**：
  ```stata
  , dydx(*)     // 对所有变量的偏效应
  , at(age=30)  // 在某特定值处求边际效应
  , atmeans     // 在"平均人"处求边际效应（MEM），与默认 AME 不同
  , post        // 保存估计结果
  , vce(unconditional)   // 计入控制变量的抽样变异，标准误更保守
  ```
- **配套检验命令**：
  ```stata
  margins, dydx(*) post     // 存为估计结果
  test edu = age            // 两个边际效应是否相等
  lincom 2*edu              // 边际效应的线性组合
  marginsplot               // 把 at() 的结果画成图
  ```
- **结果怎么读 · 常见坑**：
  1. `margins` 必须紧跟估计命令；中间插了别的估计就要重跑模型。
  2. 默认是 **AME（每个人的边际效应取平均）**；`, atmeans` 是 MEM（平均人处），文中须说明。
  3. 虚拟变量的 `dydx` 是**从 0 跳到 1** 的离散变化，读作"概率变化多少个百分点"。
  4. 想跨模型比较，务必用 `, post` 或 `estimates store` 存下结果。
- **示例**：
  ```stata
  probit employment edu age
  margins, dydx(*)                       // 平均边际效应
  margins, dydx(edu) at(age=30 40 50)    // 分年龄的边际效应
  ```

---

## ❖ `mlogit` （多元/无序 Logit）

- **功能**：因变量有 3 个以上无序分类时使用（基准类别法）。它解决"在多个互斥选择中选哪一个"（如职业类别、出行方式），跑完用 `margins, dydx(*) predict(outcome(#))` 得到对某个类别的边际效应。
- **语法**：
  ```stata
  mlogit depvar indepvars [if] [in] [, base(值) options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` | 无序多分类因变量（数值编码 1,2,3…） |
| `indepvars` | 解释变量 |
| `base(值)` | 指定基准类别；省略时默认用最频繁的类别 |
| `, rrr` | 报告相对风险比（RRR）而非系数 |

- **输出结果**：每个非基准类别一组系数、标准误、z值、P值，以及整体 LR χ²。存于 `e()`：`e(N)`、`e(ll)`、`e(ll_0)`、`e(chi2)`、`e(df_m)`、`e(r2_p)`、`e(k_eq)`、`e(baseout)`。
- **常用选项**：
  ```stata
  , base(2)     // 指定基准类别
  , rrr         // 报告相对风险比
  , robust      // 稳健标准误
  , nolog       // 不显示迭代过程
  ```
- **配套检验命令**：
  ```stata
  margins, dydx(*) predict(outcome(1))   // 对第 1 类的平均边际效应
  test [2]edu = [3]edu                   // 两类方程中系数是否相等
  estat ic                               // AIC/BIC，与 ologit 比较
  ```
- **结果怎么读 · 常见坑**：
  1. 每组系数都是**相对基准类别**而言；换 `base()` 整体改号但结论等价。
  2. 系数不能读成概率变化，必须用 `margins ... predict(outcome(#))`。
  3. `test [2]edu = [3]edu` 中方括号是**方程编号**，漏写会报错。
  4. 因变量若其实有序（如满意度 1–5），用 `mlogit` 会浪费信息，应优先 `ologit`。
- **示例**：
  ```stata
  mlogit occupation edu age, base(1) rrr
  margins, dydx(edu) predict(outcome(3))
  ```

---

## ❖ `ologit` / `oprobit` （有序 Logit / Probit）

- **功能**：因变量为有序分类（如满意度 1-5）时使用。它解决"等级结果受什么影响"，依赖**平行线（比例优势）假设**；跑完用 `margins, dydx(*) predict(outcome(#))` 看对某一等级的边际效应。
- **语法**：
  ```stata
  ologit  depvar indepvars [if] [weight] [, options]
  oprobit depvar indepvars [if] [weight] [, options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` | 有序分类因变量（1,2,3…，数值越大等级越高） |
| `indepvars` | 解释变量 |
| `, or` | `ologit` 报告累积几率比 |
| `, nolog` | 不显示迭代过程 |

- **输出结果**：系数、标准误、z值、P值，以及切点 `/cut1`、`/cut2`…。存于 `e()`：`e(N)`、`e(ll)`、`e(ll_0)`、`e(chi2)`、`e(df_m)`、`e(r2_p)`、`e(cut1)` 等切点。
- **常用选项**：
  ```stata
  , or               // ologit 报累积几率比
  , robust           // 稳健标准误
  , vce(cluster id)  // 聚类稳健标准误
  , nolog            // 不显示迭代过程
  ```
- **配套检验命令**：
  ```stata
  margins, dydx(*) predict(outcome(4))   // 对第 4 类的边际效应
  test edu = age                         // 系数是否相等
  estat ic                               // AIC/BIC，与 mlogit 比较
  brant                                  // 平行线检验（外部命令：ssc install brant）
  ```
- **结果怎么读 · 常见坑**：
  1. **平行线假设**不成立（`brant` 检验 P<0.05）时，应考虑 `mlogit` 或广义有序模型。
  2. 系数符号表示"往更高等级移动"的方向，但**中间类别的边际效应符号可能与系数相反**。
  3. 各类别边际效应之和为 0，报告时常只报首尾两类。
  4. 因变量编码方向要确认：编码反了结论全反。
- **示例**：
  ```stata
  ologit satisfaction edu age
  margins, dydx(*) predict(outcome(4))
  ```

---

## ❖ `poisson` / `nbreg` （计数模型：泊松 / 负二项）

- **功能**：因变量为非负计数（如事故次数、专利数）时使用。`poisson` 假设方差=均值，`nbreg` 允许过度离散。它解决"次数多少受什么影响"；`nbreg` 表底的 LR 检验直接告诉你是否该用负二项。
- **语法**：
  ```stata
  poisson depvar indepvars [if] [weight] [, options]
  nbreg   depvar indepvars [if] [weight] [, options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` | 非负整数计数因变量 |
| `indepvars` | 解释变量 |
| `, exposure(变量)` | 暴露量（人口、员工数），等价于 `, offset(ln(变量))` |
| `, irr` | 报告发生比率比（IRR） |

- **输出结果**：系数（对数尺度）或 IRR、标准误、z值、P值、伪 R²、对数似然；`nbreg` 另报 `/lnalpha` 与 **LR test of alpha=0**。存于 `e()`：`e(N)`、`e(ll)`、`e(chi2)`、`e(r2_p)`、`e(deviance)`；`nbreg` 还有 `e(alpha)`、`e(lnalpha)`。
- **常用选项**：
  ```stata
  , exposure(pop)   // 暴露量（偏移项），率模型必备
  , irr             // 报告 incidence rate ratio
  , robust          // 稳健标准误（准泊松折中方案）
  , vce(cluster id) // 聚类稳健标准误
  ```
- **配套检验命令**：
  ```stata
  nbreg patents rnd, nolog   // 看表底 LR test of alpha=0：P<0.05 用负二项
  estat ic                   // AIC/BIC，比较 poisson 与 nbreg
  linktest                   // _hatsq 显著说明函数形式有问题
  margins, dydx(*)           // 对计数期望值的平均边际效应
  ```
- **结果怎么读 · 常见坑**：
  1. **先看方差是否远大于均值**：过度离散时 `poisson` 低估标准误、虚增显著性，`nbreg` 的 LR 检验是正规判据。
  2. 系数是对数期望计数的变化，`exp(b)` 才是 IRR；连续变量的 IRR 读作"每增一单位，发生率乘以 IRR"。
  3. 忘记 `exposure()` 会把"人口多的地区计数天然多"误读成效应。
  4. 零值极多且零膨胀明显时，考虑 `zip`/`zinb`，而非硬套泊松。
- **示例**：
  ```stata
  poisson patents rnd, exposure(employees) irr
  nbreg patents rnd, robust nolog
  ```

---

## ❖ `tobit` （受限因变量：Tobit 模型）

- **功能**：因变量存在**截断/角点解**（如很多 0 的消费数据）时使用，是归并 Tobit。它解决"大量观测堆在边界值、OLS 有偏"的问题；跑完必须用 `margins` 区分"对潜变量的效应"与"对实际观测值的效应"。
- **语法**：
  ```stata
  tobit depvar indepvars [if] [weight] [, ll(#) ul(#) options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` | 受限因变量（有堆叠在边界上的值） |
| `indepvars` | 解释变量 |
| `ll(#)` | 左归并点，如 `ll(0)` |
| `ul(#)` | 右归并点，如 `ul(100)`；可双边同时指定 |

- **输出结果**：系数（对潜变量 y* 的效应）、标准误、z值、P值、`sigma`、对数似然、LR χ²、伪 R²，以及左/右归并观测数。存于 `e()`：`e(N)`、`e(ll)`、`e(ll_0)`、`e(chi2)`、`e(df_m)`、`e(sigma)`、`e(r2_p)`。
- **常用选项**：
  ```stata
  , ll(0)          // 左归并在 0
  , ul(100)        // 右归并在 100
  , robust         // 稳健标准误，似然设定可疑时必用
  , nolog          // 不显示迭代过程
  ```
- **配套检验命令**：
  ```stata
  margins, dydx(*) predict(ystar(0))   // 对观测值 y 的边际效应（最常报告）
  margins, dydx(*) predict(e(0,.))     // 对潜变量 y* 的边际效应
  regress expenditure income           // 对照：与 tobit 差别大说明归并严重
  ```
- **结果怎么读 · 常见坑**：
  1. **Tobit 系数不等于边际效应**：`predict(ystar(#))` 才是对实际观测值的效应，通常小于系数。
  2. 前提是"同一潜变量机制 + 同方差正态"；若"是否为 0"与"多少"由两个过程决定，应改用 Heckman 或两部分模型。
  3. 归并点写错（把"未观测到"当成真实 0）会系统性偏误；先 `summarize` + `count if y==0` 确认。
  4. 只用 y>0 子样本做 OLS（截断回归）与 Tobit 含义不同，不能混用。
- **示例**：
  ```stata
  tobit expenditure income, ll(0)
  margins, dydx(income) predict(ystar(0))
  ```

---

## ❖ `pwmean` / `pwcompare` （成对均值比较）

> **说明**：原稿此处记作 `ttable`，但 Stata 官方**没有** `ttable` 命令（易与 `table`、`ttest` 混淆）。多组两两均值比较的官方命令是 `pwmean`（两两均值差及其检验）与 `pwcompare`（在 `anova`/`margins` 之后做两两对比）。下面按官方语法重写，原意不变。

- **功能**：多个组两两比较的均值检验。它解决"`anova` 只说至少有一组不同，到底哪两组不同"的问题，是方差分析后的标准后续步骤，并自带多重比较校正。
- **语法**：
  ```stata
  pwmean varname [if] [in], over(groupvar) [options]
  pwcompare groupvar, effects [options]     // 须在 anova 之后
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `varname` | 要比较均值的连续变量（`pwmean`） |
| `over(groupvar)` | 分组变量 |
| `mcompare(方法)` | 多重比较校正：`bonferroni`、`tukey`、`sidak`、`scheffe` 等 |
| `effects` | `pwcompare` 中比较各组边际均值 |

- **输出结果**：每两组之间的均值差、标准误、t 值、未校正 P 值，以及各校正方法下的 P 值与置信区间。
- **常用选项**：
  ```stata
  , mcompare(bonferroni)   // Bonferroni 校正，最保守常用
  , mcompare(tukey)        // Tukey HSD，组数多时更有效率
  , mcompare(sidak)        // Sidak 校正
  , level(99)              // 置信水平
  ```
- **配套检验命令**：
  ```stata
  anova wage edu                                // 先做整体 F 检验
  pwcompare edu, effects mcompare(bonferroni)   // 再做两两比较
  margins edu, pwcompare(effects)               // 回归框架下的等价做法
  ```
- **结果怎么读 · 常见坑**：
  1. **不要跳过整体检验**：`anova` 不显著还硬做两两比较，会大幅提高假阳性。
  2. 不做校正时组数越多假阳性越多；3–5 组用 `bonferroni` 或 `tukey` 均可。
  3. `pwmean` 默认假定方差齐性；方差不齐时先 `robvar` 检查，再用 `regress ..., robust`。
  4. 论文该报的是校正后 P 值，未校正 P 只作参考。
- **示例**：
  ```stata
  pwmean wage, over(edu) mcompare(tukey)
  anova wage edu gender edu#gender
  pwcompare edu#gender, effects mcompare(bonferroni)
  ```

---

## ❖ 横截面回归配套检验诊断（Post-estimation Diagnostics）

> 回归做完后，必须检验经典假定是否成立。以下命令均在 `regress`（或相应模型）之后使用。**注意：`estat` 系列只能紧跟估计命令**，中间若跑了别的估计命令，需重新估计。本节是上面各命令"配套检验"段的汇总与展开。

- **功能**：系统检查 OLS 的五项经典假定（无多重共线性、同方差、误差正态、设定正确、无自相关）与影响点，避免"系数好看但推断不可靠"。它解决的是"结果能不能信"的问题，与前面每个模型命令一一配合。
- **语法**：
  ```stata
  regress y x1 x2 x3
  estat vif
  estat hettest
  estat ovtest
  linktest
  ```
- **参数说明**：

| 命令 | 关键选项 | 说明 |
|------|------|------|
| `estat hettest` | `, iid` `, rhs` | `iid` 假定误差独立同分布；`rhs` 用全部解释变量做辅助回归 |
| `estat imtest` | `, white` | White 异方差检验，不预设异方差形式 |
| `estat ovtest` | `, rhs` | 用解释变量幂次构造 RESET；`estat gof` 的 `group(#)` 用于 HL 型分组检验 |

- **输出结果**：各检验给出统计量（χ²/F/t）、自由度与 P 值。`estat hettest` 存于 `r(chi2)`、`r(df)`、`r(p)`；`test`/`testparm` 存于 `r(F)`/`r(chi2)`、`r(df)`、`r(p)`；`lincom` 存于 `r(estimate)`、`r(se)`、`r(p)`、`r(lb)`、`r(ub)`。
- **常用选项**：
  ```stata
  estat hettest, iid rhs   // B-P 检验，用全部解释变量
  estat imtest, white      // White 检验
  estat ovtest, rhs        // RESET，用解释变量幂次
  estat vif, uncentered    // 无常数项模型的 VIF
  ```
- **配套检验命令**：
  ```stata
  test x1 = x2        // 两个系数是否相等
  testparm i.region   // 一组虚拟变量是否联合显著
  lincom x1 + x2      // 系数线性组合的点估计与检验
  margins, dydx(*)    // 非线性模型的边际效应
  ```
- **结果怎么读 · 常见坑**：
  1. **顺序很重要**：先 `estat vif`（变量间关系）→ `estat hettest`（方差）→ `estat ovtest`（函数形式）→ 影响点；先解决共线性，异方差检验才有意义。
  2. 所有检验的 P 值都建立在"模型已正确设定"之上；`ovtest` 显著时，异方差与正态检验的结论也要打折扣。
  3. 大样本下几乎所有检验都显著——**统计显著不等于实质严重**，要结合系数变化幅度判断；`estat` 只能用于支持它的估计命令，`logit` 之后要用 `estat classification`/`estat gof`。
- **示例**：
  ```stata
  regress wage edu exp tenure
  estat vif
  estat hettest, rhs
  linktest
  ```

### ✨ ① 多重共线性：`vif` / `estat vif`
- **功能**：检验自变量之间是否高度相关。VIF 均值>10 或单个>10 → 严重共线性。
- **语法**：`regress y x1 x2 x3` 之后执行 `vif` 或 `estat vif`（等价，后者另给 `Mean VIF`）。
- **输出与解读**：输出各变量的 `VIF` 与 `1/VIF`（容忍度）；`VIF = 1/(1-R²_j)`，R²_j 是把第 j 个 x 对其余 x 回归得到的 R²，>10 时可考虑删变量、合并指标或主成分，`1/VIF<0.1` 是同一件事的另一种写法。
- **坑**：VIF 只诊断线性相关；交互项与多项式项会天然拉高 VIF（可先对变量中心化）；共线性不影响无偏性，只放大标准误。

### ✨ ② 异方差检验：`estat hettest` / `estat imtest`
- **功能**：检验残差方差是否恒定。P<0.05 拒绝同方差假设，须改用稳健标准误。
- **语法**：`regress y x1 x2` 之后执行 `estat hettest`（B-P）、`estat hettest, iid rhs`（带全部解释变量）、`estat imtest, white`（White 检验）。
- **输出与解读**：χ² 统计量、自由度与 P 值（`estat hettest` 存于 `r(chi2)`、`r(df)`、`r(p)`）。存在异方差时加 `, robust` 重跑，聚类/面板数据用 `, vce(cluster id)`。
- **坑**：White 检验大样本下过于敏感、耗自由度；`estat hettest` 默认假定误差正态，`iid` 放宽该假定。异方差只影响标准误，不改系数点估计。

### ✨ ③ 正态性检验：`sktest` / `swilk`
- **功能**：检验残差/变量是否服从正态分布，常用于对数的选择。
- **语法**：`sktest wage`（Jarque–Bera 偏度峰度检验）、`swilk wage`（Shapiro–Wilk）；检验残差先 `predict e, res` 再 `sktest e`。
- **输出与解读**：偏度、峰度及各自检验的 P 值与联合检验 P 值；P<0.05 → 偏离正态，可视情况考虑对数变换 `ln()`。
- **坑**：OLS 的 t/F 检验**并不要求 y 或 x 正态**，大样本下只依赖渐近性质，小样本才需关心残差正态；`swilk` 样本量上限约 5000。

### ✨ ④ 模型设定与变量选择：`estat ovtest`（RESET）、`stepwise`
- **功能**：`estat ovtest`（Ramsey 回归设定误差检验）；`stepwise` 自动变量筛选。
- **语法**：`regress y x1 x2` 之后 `estat ovtest`（或 `estat ovtest, rhs`）；`stepwise, pr(0.1): regress y x1 x2 x3 x4` 向后筛选、`stepwise, pe(0.05): regress ...` 向前筛选。
- **输出与解读**：RESET 给 F 统计量与 P 值，P<0.05 → 存在函数形式设定错误，可加 `x^2` 或交互项；`stepwise` 逐步显示进出变量与每步的 F/P。
- **坑**：`stepwise` 属于数据挖掘，**不能当理论依据**，须在文中交代筛选规则；RESET 显著只提示"有遗漏"，不告诉你是哪个变量。

### ✨ ⑤ 影响点与残差诊断：`predict` + `lvr2plot`
- **功能**：查看极端值、杠杆值与学生化残差，判断是否有异常观测。
- **语法**：`regress` 之后用 `predict e, res`、`predict lev, hat`、`predict stu, rstudent`、`predict cook, cooksd`；再看 `lvr2plot`（杠杆-残差平方图）、`avplot x1`、`rvfplot`（残差-拟合值图）。
- **输出与解读**：新生成的变量与图形。经验判据：杠杆值>2k/n、|rstudent|>2、Cook's D>4/n 值得逐个核查。
- **坑**：不要一见异常值就删，先确认是否录入错误；删除观测必须在文中交代并做稳健性对照。

### ✨ ⑥ 离散选择模型拟合与检验：`estat classification` / 混淆矩阵
- **功能**：logit/probit 之后查看预测准确率与正确分类率。
- **语法**：`logit y x1 x2` 之后 `estat classification`（可加 `, cutoff(0.3)` 改阈值）、`lroc`、`estat gof, group(10)`、`fitstat`（外部命令）。
- **输出与解读**：混淆矩阵、灵敏度（Sensitivity）、特异度（Specificity）、正确分类率；`lroc` 给出 AUC 并存于 `r(area)`，>0.7 尚可、>0.8 好。
- **坑**：样本不平衡时"全预测为多数类"也能有高正确率，须与基准比例比较；AUC 与正确率衡量的是不同侧面（判别力 vs 阈值表现）。

### ✨ ⑦ 线性约束与联合显著性：`test` / `testparm` / `lincom`
- **功能**：检验系数的线性约束（系数相等、组合为零等），是解释"哪个变量真的有用"最直接的工具。
- **语法**：估计之后 `test x1 = 0`、`test x1 = x2`、`testparm i.region`、`lincom x1 - x2`。
- **输出与解读**：`test`/`testparm` 给 F 或 χ²、自由度、P 值（`r(F)`/`r(chi2)`、`r(df)`、`r(p)`）；`lincom` 给差的点估计与区间（`r(estimate)`、`r(se)`、`r(p)`、`r(lb)`、`r(ub)`）。
- **坑**：`testparm` 用于**一组变量**（尤其 `i.` 展开的多个虚拟变量），逐个 `test` 会高估整体显著性；约束须在估计命令之后立即做。

### ✨ ⑧ 模型比较与信息准则：`estat ic`
- **功能**：非嵌套模型之间比较拟合与复杂度，AIC/BIC 越小越好。
- **语法**：每次估计后执行 `estat ic`，可配合 `estimates store m1` 分别保存各模型。
- **输出与解读**：给出 AIC 与 BIC；差值 2–6 之间算有一定证据、>10 差别明显。
- **坑**：只能在**同一样本、同一因变量**之间比较；AIC 偏向预测、BIC 偏向简约，样本大时 BIC 惩罚更重。

### ✨ ⑨ 计数与受限模型的专门诊断
- **功能**：`poisson`/`nbreg`/`tobit` 的假定与 OLS 不同，需专门检查。
- **语法**：`nbreg y x1 x2, nolog`（看表底 LR test of alpha=0）、`linktest`、`margins, dydx(*)`；`tobit y x1 x2, ll(0)` 之后 `margins, dydx(*) predict(ystar(0))`。
- **输出与解读**：`alpha=0` 的 LR 检验 P<0.05 → 存在过度离散，应改用 `nbreg`；`linktest` 的 `_hatsq` 显著 → 函数形式有问题（试取对数或加平方项）。
- **坑**：Tobit 的系数不是边际效应，必须用 `predict(ystar(#))` 换算；比较 nest 模型时务必保持归并点一致。

---

# 第二部分 · 时间序列（Time Series）

> 时间序列：同一对象随时间变化的观测。核心是**趋势/季节、平稳性检验、ARIMA、协整、VAR、单位根与结构性检验**。**必须先 `tsset` 声明时间变量。**

本章工作流：**`tsline` 看形态 → `tsset` 声明结构 → 单位根检验（`dfuller`/`pperron`，`kpss` 反向验证）→ 平稳直接建模 / 不平稳则差分或做协整 → `arima` / `var` / `vec` → 残差白噪声与稳定性诊断 → 脉冲响应、Granger 因果、预测。** 每一步没过就退回上一步，不要硬建模。

## 📋 本章检验命令速览

| 检验/诊断命令 | 检验什么 | 原假设 H0 | 前置命令 | 结论怎么读 |
|---|---|---|---|---|
| `corrgram` | 各阶自相关 AC、偏自相关 PAC 与 Ljung–Box Q | 各阶自相关系数全为 0（白噪声） | `tsset` | `Prob>Q`<0.05 拒绝白噪声；再看 AC 拖尾/截尾定 AR/MA 阶 |
| `ac` / `pac` | 自相关图、偏自相关图 | 各阶自相关系数为 0 | `tsset` | 柱子在阴影带内即不显著；AC 拖尾+PAC 截尾→AR，反之→MA |
| `wntestq` | Ljung–Box Q 白噪声检验 | 序列（或残差）无自相关 | `tsset`；查残差先 `predict ..., residuals` | `Prob > chi2`<0.05 → 仍有自相关，阶数不够 |
| `wntestb` | 累积周期图（Bartlett）白噪声检验 | 序列为白噪声 | `tsset` | 累积周期图越出置信带、偏离 45° 线 → 非白噪声 |
| `dfuller` | ADF 单位根检验 | **存在单位根（非平稳）** | `tsset` | 统计量比临界值更负（或 MacKinnon P<0.05）→ 平稳 |
| `pperron` | PP 单位根检验（Newey–West 修正） | **存在单位根（非平稳）** | `tsset` | 判读同 ADF；两者结论一致才可信 |
| `dfgls` | DF-GLS 单位根检验（去均值 ADF，功效更高） | **存在单位根（非平稳）** | `tsset` | 统计量小于临界值 → 平稳；小样本比 ADF 可靠 |
| `kpss` | KPSS 平稳性检验（SSC 模块） | **平稳**（加 `notrend` 则检验水平平稳） | `tsset`；先 `ssc install kpss` | **方向相反**：统计量大于临界值才拒绝平稳 → 不平稳 |
| `estat bgodfrey` | 回归残差的 Breusch–Godfrey 自相关检验 | 残差无自相关 | `regress`（且已 `tsset`） | P<0.05 → 残差有自相关，加滞后项或用 `vce(hac nw #)` |
| `estat archlm` | 残差的 ARCH 效应（条件异方差） | 无 ARCH 效应（同方差） | `regress`（且已 `tsset`） | P<0.05 → 有 ARCH，改 `arch`/GARCH 建模 |
| `estat sbcusum` | 参数稳定性 CUSUM 检验 | 系数在样本期内稳定 | `regress`（且已 `tsset`） | 累积和图越出置信带 → 结构突变，加断点/交互项 |
| `arima` 后 `estat ic` | AIC/BIC 等信息准则 | 无 H0（模型比较） | `arima` | 越小越好；只在同一因变量、同一样本上可比 |
| `arima` 后 `estat aroots` | AR 根、MA 根是否在单位圆内 | 无 H0（看根模） | `arima` | AR 根模全 <1 → 平稳；MA 根模全 <1 → 可逆 |
| `arima` 后 `estat acplot` | 模型隐含的自相关/自协方差 | 无 H0（图形核对） | `arima` | 模型隐含 AC 应与实测 AC 吻合，明显偏离说明阶数不当 |
| `arima` 后 `predict`+`wntestq` | 残差是否白噪声 | 残差无自相关 | `arima` → `predict er, residuals` | P<0.05 → 残差还有信息，阶数不够 |
| `varsoc` | VAR 最优滞后阶（AIC/SBIC/HQIC/FPE） | 无 H0（选阶） | 已 `tsset`，变量平稳 | 带 `*` 的阶即各准则最优；冲突时优先 SBIC（简约） |
| `var` 后 `vargranger` | 成对 Granger 因果检验 | 被排除变量滞后项系数全为 0 | `var` | `Prob > chi2`<0.05 → 存在 Granger 因果 |
| `var` 后 `varstable` | VAR 稳定性（伴随矩阵特征根） | 无 H0（看特征根） | `var` | 全部根在单位圆内 → 稳定，IRF 与预测才有意义 |
| `var` 后 `varlmar` | 残差自相关 LM 检验 | 残差无自相关 | `var` | P<0.05 → 阶数偏低，需加滞后 |
| `var` 后 `irf create` / `irf graph` | 脉冲响应、方差分解 | 无 H0（看动态路径） | `var`（先 `irf create`） | 看方向、峰值期与置信带是否含 0；含 0 即不显著 |
| `vecrank` | Johansen 协整秩（trace / max-eigen） | 协整秩 ≤ r（至多 r 个协整关系） | 已 `tsset`，变量同为 I(1) | 第一个"统计量 < 临界值"的 r 即协整秩；`e(k_ce95)` 给出结论 |
| `johansen` | Johansen 协整检验（传统写法） | 协整秩 ≤ r | 已 `tsset` | 与 `vecrank` 等价，逐行比较统计量与临界值 |
| `vec` 后 `veclmar` / `vecnorm` / `vecstable` | 残差自相关、正态性、稳定性 | 无自相关 / 残差正态 / 稳定 | `vec` | 三项都过，VECM 结果才可解释 |

> 方向别记反：`dfuller`/`pperron`/`dfgls` 的 H0 是"有单位根"（拒绝才平稳）；`kpss` 的 H0 是"平稳"（拒绝才不平稳）。

---

## ❖ `tsset` （声明时间序列结构）

- **功能**：告诉 Stata 哪个是时间变量、频率单位是什么，几乎所有时间序列命令的前置步骤（不 `tsset`，`L.`/`D.` 算子、`dfuller`、`corrgram`、`var` 全部报错）。
- **语法**：
  ```stata
  tsset timevar [, options]
  tsset panelvar timevar [, options]    // 面板形式：个体 + 时间
  tsset                                 // 不带参数：显示当前设定
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `timevar` | 数值型日期变量（`%td`/`%tm`/`%tq` 格式）或整数年份 |
| `delta(#)` | 时间间隔：季度 `delta(4)`、月度 `delta(12)`、年度 `delta(1)` |
| `, daily` / `, monthly` / `, quarterly` / `, yearly` | 时间变量无日期格式时直接声明频率单位 |
| `, format(%fmt)` | 同时给时间变量套日期显示格式 |
| `, clear` | 清除已有 `tsset` 设定 |

- **输出结果**：只回显设定信息，不存 `e()`/`r()`：`Time variable: date, 1960m1 to 2000m12` / `Delta: 1 month`。报 `repeated time values` 或 `not equally spaced` 说明数据本身有重复时点或缺口。
- **常用选项**：
  ```stata
  tsset date                      // 日期已格式化
  tsset qdate, delta(4)           // 季度数据
  tsset panelid date              // 面板/长格式
  tsset, clear                    // 换数据集前清除
  ```
- **配套检验命令**：
  ```stata
  tsreport gdp, report     // 检查时间变量缺口与跳跃（声明后立刻做）
  dfuller gdp              // 单位根检验
  corrgram gdp, lags(12)   // 自相关结构
  ```
  用途：`tsset` 只是"开锁"，它不产出结论；声明完先体检数据缺口，再进检验环节。
- **结果怎么读 · 常见坑**：
  - **`tsset year month, monthly` 不是合法语法**：双变量形式只用于面板（个体+时间）；月度须 `gen mdate = ym(year, month)` → `format mdate %tm` → `tsset mdate`。
  - 时间变量不能重复、不能是字符串；有缺口用 `tsfill` 补全（配合 `tsappend` 可追加未来时点），否则 `D.`/`L.` 会跨过缺口算错。
  - 换数据集或改排序后要重新 `tsset`；`tsset, clear` 之后旧设定失效。
- **示例**：
  ```stata
  tsset year
  gen mdate = ym(year, month)
  format mdate %tm
  tsset mdate
  ```

---

## ❖ `tsline` / `tsgraph` （时间序列绘图）

- **功能**：按时间顺序绘制折线图。`tsline` 是 **Stata 官方命令**，时序画图首选；`tsgraph` 是 **SSC 外部模块**（`ssc install tsgraph`），早期教材常见，功能与 `tsline` 重叠，装与不装都不影响正常流程。
- **语法**：
  ```stata
  tsline varlist [if] [in] [, options]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `varlist` | 要画的变量，可多个、同图叠加 |
| `title()` / `ytitle()` / `xtitle()` | 图标题、纵轴标题（横轴自动为时间） |
| `lwidth(medium)` / `lpattern(dash)` / `lcolor(navy)` | 线宽、线型、线色（多变量叠加时区分） |
| `tlabel(1960m1(60)2000m1)` | 横轴时间刻度的起点、间隔、终点 |
| `name(图形名, replace)` | 命名，便于 `graph combine` |

- **输出结果**：只出图形，不存统计结果；横轴刻度由时间变量的格式决定（`%tm` 显示 `1960m1`）。
- **常用选项**：
  ```stata
  , title("GDP 走势") ytitle("亿元")     // 标题与轴标题
  , lpattern(solid dash) legend(rows(2)) // 多序列区分
  , name(gdp_plot, replace)              // 命名便于拼图
  ```
- **配套检验命令**：
  ```stata
  tsline D.lngdp, name(d1, replace)   // 差分后对比，直观看平稳性
  dfuller gdp, trend                  // 图上有趋势 → 检验加 trend
  corrgram gdp, lags(12)              // 接着看自相关结构
  ```
  用途：单位根检验前的图形判断——**有明显趋势加 `trend`、有漂移加 `drift`**，比事后反复试选项可靠。
- **结果怎么读 · 常见坑**：
  - 图上看三件事：**趋势**（长期升降）、**季节**（每年重复峰谷）、**方差是否随时间变大**（波动聚集），它们决定后面建模路径。
  - 折线持续上扬不回落 → 大概率不拒绝单位根；先取对数再差分常能一步到位。
  - 时间轴显示成一串整数说明日期没设格式，`format varname %tm` 修好；`tsline` 必须在 `tsset` 之后用。
- **示例**：
  ```stata
  tsline gdp, title("GDP 走势")
  tsline gdp unemp, legend(rows(2))
  tsline D.lngdp, name(d1, replace)
  ```

---

## ❖ `twoway` 基础：`scatter` / `line` （散点图 / 线图）

- **功能**：基础绘图命令，几乎所有的 twoway 图都由它派生（`tsline` 本质上是带时间轴的 `twoway line`）。
- **语法**：
  ```stata
  twoway scatter yvar xvar [if] [, options]
  twoway line yvar timevar [if] [, options]
  twoway (scatter yvar xvar) (line yvar xvar) [, options]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `yvar` / `xvar` | 纵轴、横轴变量；`line` 的横轴一般是时间变量 |
| `msymbol()` / `mcolor()` | 点的形状与颜色（`mcolor(%40)` 为半透明，重叠点多时好用） |
| `lfit` / `lfitci` | 叠加线性拟合线 / 拟合线+置信带 |
| `xtitle()` / `ytitle()` / `note()` / `scheme()` | 轴标题、脚注、配色主题 |

- **输出结果**：图形输出；`lfitci` 的拟合线与置信带来自对 `yvar` 的 OLS 回归，置信水平由 `level()` 控制（默认 95%）。
- **常用选项**：
  ```stata
  , msymbol(circle) mcolor(red)     // 点的样式和颜色
  , xtitle("x 轴") ytitle("y 轴")    // 轴标题
  , note("备注") scheme(s1color)     // 备注与配色
  ```
- **配套检验命令**：
  ```stata
  corr wage edu            // 画散点前先看相关系数
  twoway lfitci gdp t      // 线性趋势拟合（配合 gen t = _n）
  regress wage edu         // 拟合线的正式版本（出系数与检验）
  ```
  用途：先用 `twoway` 判断关系是否线性、有无离群点，再决定回归形式；"看图说话"的第一道工序。
- **结果怎么读 · 常见坑**：
  - 散点成扇形（方差随 x 增大）→ 取对数或改用稳健标准误。
  - `lfitci` 置信带在两端变宽是正常的（外推不可靠），不要据此断言端点关系。
  - 一个命令只有一个 `title()`；叠加子图改样式要写进各子图的括号内。
- **示例**：
  ```stata
  twoway (scatter gdp year) (line gdp year)
  twoway lfitci wage edu
  ```

---

## ❖ `regress` （时间序列中的回归）——见第一部分

- **功能**：时序上的 OLS 回归（静态回归、分布滞后、趋势回归），也是 Engle–Granger 协整两步法的第一步。
- **语法**：
  ```stata
  regress depvar indepvars [if] [in] [, options]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `L.` / `L2.` / `D.` / `F.` | 滞后、二阶滞后、差分、前移算子（须先 `tsset`）；`L(1/4).x` 一次写多阶 |
| `, vce(robust)` | 稳健标准误（处理异方差） |
| `, vce(hac nw 4)` | Newey–West HAC 标准误（时序回归更常用：同时处理自相关与异方差） |
| `, noconstant` | 无截距（如收益率回归） |

- **输出结果**：`e(b)`/`e(V)` 系数与方差协方差、`e(N)`、`e(r2)`/`e(r2_a)`、`e(rmse)`、`e(df_r)`、`e(F)`；残差用 `predict newvar, residuals` 取出。
- **常用选项**：
  ```stata
  , vce(hac nw 4)      // Newey-West，滞后 4 期
  , vce(robust)        // 只处理异方差
  , noconstant         // 无截距
  ```
- **配套检验命令**：
  ```stata
  estat bgodfrey, lags(1 4)    // 残差自相关
  estat archlm, lags(1)        // 残差 ARCH 效应
  estat sbcusum                // 系数稳定性（CUSUM）
  ```
  用途：时序回归三件套体检——自相关、异方差、结构突变；三项都过，t 值与 F 值才可信。
- **结果怎么读 · 常见坑**：
  - 时序残差几乎总有自相关：`estat bgodfrey` 显著时改用 `vce(hac nw #)`，或把滞后项写进模型。
  - 两个有趋势的变量直接回归，`R²` 很高也可能是**伪回归**；务必先做单位根/协整检验。
  - `L.` 算子会吃掉首期观测，`e(N)` 变小是正常的；样本量不同时不要比较 AIC/BIC。
- **示例**：
  ```stata
  regress gdp gdp L.gdp unemp D.unemp
  regress gdp money, vce(hac nw 4)
  predict ehat, residuals
  ```

---

## ❖ `corrgram` （自相关图 / 偏自相关图）

- **功能**：列出并绘制序列的自相关(AC)与偏自相关(PAC)，同时给出 Ljung–Box Q 统计量，辅助定 ARMA/ARIMA 阶数、判断是否需要差分。
- **语法**：
  ```stata
  corrgram varname [if] [in] [, lags(#)]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `varname` | 待检验序列，可写算子（如 `D.gdp`） |
| `lags(#)` | 计算到第 # 阶，默认 `min(floor(n/2), 40)`；月度建议 12/24 |
| `AC` / `PAC` 列 | 第 k 阶自相关、偏自相关系数 |
| `Q` / `Prob>Q` 列 | 到第 k 阶的**累积** Ljung–Box 统计量与 p 值 |

- **输出结果**：表格 + 柱形字符图，不存 `e()`；要数值可自行 `corr` 或看 `ac`/`pac` 图。
- **常用选项**：
  ```stata
  , lags(12)     // 月度数据
  , lags(24)     // 看季节峰值与更长期结构
  ```
- **配套检验命令**：
  ```stata
  wntestq gdp, lags(12)     // 正式的白噪声检验
  ac gdp, lags(12)          // 图形版
  dfuller gdp               // AC 衰减极慢 → 大概率有单位根
  ```
  用途：`corrgram` 是"看图定阶"的入口，`wntestq` 是它的正式检验版；先摸形状，再下结论。
- **结果怎么读 · 常见坑**：
  - **AC 缓慢线性衰减、第 1 阶接近 1** → 单位根信号，先差分再重看。
  - **AC 拖尾+PAC 第 p 阶后截尾** → AR(p)；**AC 截尾+PAC 拖尾** → MA(q)；都拖尾 → ARMA。
  - `Prob>Q` 从某阶起全部 <0.05 说明该阶后仍有显著自相关，模型阶数不够；季节数据在第 4/12 阶孤立高峰 → 需季节项。
- **示例**：
  ```stata
  corrgram gdp, lags(12)
  corrgram D.lngdp, lags(12)
  ```

---

## ❖ `ac` / `pac` （自相关图单独绘制）

- **功能**：分别绘制自相关图和偏自相关图（图形版，比 `corrgram` 的字符图直观，适合放进报告）。
- **语法**：
  ```stata
  ac varname [if] [in] [, lags(#) graph_options]
  pac varname [if] [in] [, lags(#) graph_options]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `lags(#)` | 画到第 # 阶 |
| `graph_options` | 任意 twoway 图形选项（`title()`、`name()`、`ytitle()` 等） |
| 图中阴影带 | 白噪声下的 95% 置信区间（约 ±1.96/√n） |

- **输出结果**：柱状图，横轴阶数、纵轴相关系数，阴影带为 Bartlett 95% 区间；不存 `e()`。
- **常用选项**：
  ```stata
  ac gdp, lags(12)                     // 自相关图
  pac gdp, lags(12)                    // 偏自相关图
  ac D.lngdp, lags(12)                 // 差分后重看
  ```
- **配套检验命令**：
  ```stata
  corrgram gdp, lags(12)    // 想看数值表格
  wntestq gdp, lags(12)     // 整段是否白噪声的正式判决
  ```
  用途：`ac`/`pac` 决定"看哪一阶"，`wntestq` 给出"是否白噪声"的结论。
- **结果怎么读 · 常见坑**：
  - 柱子基本都在阴影带内 → 白噪声，不需要 ARMA。
  - `ac` 第 1 阶接近 1 且慢降 = 非平稳；对差分序列重画 `ac`，若迅速衰减则 d=1。
  - `pac` 在某阶后突然全部落带内 → 该阶（注意是"截尾之后"）即 AR 阶数；阴影带是单阶近似、未校正多重比较，别把压线的柱子当铁证。
- **示例**：
  ```stata
  ac gdp, lags(12) name(ac1, replace)
  pac gdp, lags(12) name(pac1, replace)
  graph combine ac1 pac1
  ```

---

## ❖ `dfuller` （ADF 单位根检验）

- **功能**：增广 Dickey–Fuller 检验，判断序列是否平稳（是否存在单位根）。**本章最重要的检验**：不平稳序列直接回归会伪回归。
- **语法**：
  ```stata
  dfuller varname [if] [in] [, options]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `varname` | 待检验序列，可含算子（`D.gdp`） |
| `lags(#)` | 辅助回归中 # 阶滞后差分，默认按样本量自动选 |
| `trend` / `drift` / `noconstant` | 含线性趋势 / 含漂移 / 无常数；三者互斥，只能选一个 |
| `regress` | 显示辅助回归表 |

- **输出结果**：`Test Statistic`（τ）+ 1%/5%/10% 临界值 + MacKinnon 近似 P 值（`noconstant` 时无 P 值）。存于 `r()`：`r(Zt)` 统计量、`r(p)` 近似 P 值、`r(cv_1)`/`r(cv_5)`/`r(cv_10)`、`r(N)`、`r(lags)`、`r(level)`、`r(table)` 辅助回归矩阵。
- **常用选项**：
  ```stata
  , lags(2)     // 指定滞后差分阶数
  , trend       // 含线性趋势（有趋势的序列必加）
  , drift       // 原假设为带漂移随机游走
  , regress     // 显示辅助回归，检查滞后项是否显著
  ```
- **配套检验命令**：
  ```stata
  pperron gdp, trend          // PP 交叉验证
  dfgls gdp                   // DF-GLS，小样本功效更高
  kpss gdp                    // 反向验证（H0 是平稳）
  dfuller D.gdp               // 差分再检，确认 d=1
  ```
  用途：**ADF+PP 同向、KPSS 反向**三者一致才敢下平稳性结论；冲突时按"差分后平稳"的稳妥路线处理。
- **结果怎么读 · 常见坑**：
  - H0：**存在单位根（非平稳）**。统计量**比临界值更负**（或 `r(p)`<0.05）→ 拒绝 H0 → 平稳；看的是方向不是绝对值。
  - `trend`/`drift`/`noconstant` 选错规格（有趋势却只放常数）会让检验严重偏向"不拒绝"。
  - 滞后阶要够（`regress` 后看末阶滞后是否显著、残差是否仍有自相关）；滞后不足会使检验尺寸扭曲。
  - 结构性突变、季节、样本太短都会让 ADF 偏向不拒绝（Perron 现象），图上见断点先做断点处理；报告须写清规格与滞后阶。
- **示例**：
  ```stata
  dfuller gdp
  dfuller gdp, lags(2) trend
  dfuller D.gdp, noconstant
  ```

---

## ❖ `pperron` （PP 单位根检验）

- **功能**：Phillips–Perron 单位根检验，对 ADF 的补充：用 Newey–West 标准误修正序列相关、不靠加滞后差分项，因此**对滞后阶不敏感**，适合残差相关性较强或样本偏短的情形。
- **语法**：
  ```stata
  pperron varname [if] [in] [, options]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `varname` | 待检验序列，可含算子 |
| `lags(#)` | Newey–West 截断滞后，默认 `int(4(T/100)^(2/9))` |
| `trend` / `noconstant` | 含线性趋势 / 无常数（二者不能同用） |
| `regress` | 显示辅助回归表 |

- **输出结果**：`Test Statistic`（τ）+ 临界值 + MacKinnon 近似 P 值。存于 `r()`：`r(Zt)` τ、`r(Zrho)` ρ、`r(pval)` 近似 P 值（`noconstant` 时无）、`r(N)`、`r(lags)`、`r(level)`、`r(table)`、`r(cvalues)`。
- **常用选项**：
  ```stata
  , lags(4)      // 4 期 Newey-West 滞后
  , trend        // 含线性趋势
  , noconstant   // 无常数
  , regress      // 显示辅助回归
  ```
- **配套检验命令**：
  ```stata
  dfuller gdp, trend     // ADF 交叉验证
  dfgls gdp              // DF-GLS 高效版本
  kpss gdp               // 反向验证平稳
  pperron D.gdp          // 差分序列再检
  ```
  用途：ADF 与 PP 结论一致时可信度高；若一个拒绝、一个不拒绝，说明结论对"如何处理序列相关"敏感，两种结果都报告并采用保守处理。
- **结果怎么读 · 常见坑**：
  - H0：**存在单位根**，判读方向与 `dfuller` 相同（更负 → 平稳）；两统计量**不能直接比大小**，各对各的临界值。
  - `lags()` 太小 → 过度拒绝平稳；太大 → 功效下降。试 `lags(0)`、`lags(4)` 结论不变才写进报告。
  - `pperron` 不做结构突变稳健化，有断点的样本仍需 `estat sbcusum` 配合。
- **示例**：
  ```stata
  pperron gdp, trend
  pperron gdp, lags(4) trend regress
  pperron D.gdp
  ```

---

## ❖ `kpss` （KPSS 平稳性检验）

- **功能**：与 ADF **方向相反**：KPSS 的**原假设是序列平稳**（默认"趋势平稳"，加 `notrend` 为"水平平稳"），备择是存在单位根；与 ADF 互补使用结论更稳健。
- **语法**：
  ```stata
  ssc install kpss        // 首次：kpss 是 SSC 模块，不是官方命令
  kpss varname [, maxlag(#) notrend]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `varname` | 待检验序列 |
| `maxlag(#)` | 长期方差的最大滞后截断（Bartlett 核） |
| `notrend` | 检验水平平稳（H0：围绕常数平稳）；不加则检验趋势平稳 |
| 输出 | KPSS 统计量 + 1%/5%/10% 临界值（**无 P 值**） |

- **输出结果**：统计量 `eta` 与各显著性水平临界值，只打印、不提供标准 `e()`/`r()` 返回；要留档请 `log using kpss.log, replace`。
- **常用选项**：
  ```stata
  kpss gdp                 // H0：趋势平稳（默认）
  kpss gdp, notrend        // H0：水平平稳
  kpss gdp, maxlag(4)      // 手动指定滞后截断
  ```
- **配套检验命令**：
  ```stata
  dfuller gdp, trend       // 对照：ADF 拒绝 + KPSS 不拒绝 = 平稳
  pperron gdp              // 第三方旁证
  kpss D.gdp, notrend      // 差分后应"不拒绝平稳"
  ```
  用途：**"ADF 拒绝 + KPSS 不拒绝"是最干净的平稳证据**；"ADF 不拒绝 + KPSS 拒绝"是最干净的不平稳证据；互相矛盾时多半是趋势设定或样本太短。
- **结果怎么读 · 常见坑**：
  - **方向最容易写错**：KPSS 统计量 **大于**临界值 → 拒绝平稳 → 序列**不平稳**，与 ADF 正好相反。
  - **没有 p 值**，只能和 1%/5%/10% 临界值比，写论文要说清用的是哪一档。
  - 默认 H0 是趋势平稳；序列若只是围绕常数波动，应加 `notrend`，否则检验规格与数据不符。
  - 结论在临界值附近时报告 `maxlag()` 敏感性；该命令是 SSC 模块，换电脑要先 `ssc install kpss`（官方只有 `dfuller`/`pperron`/`dfgls` 一类）。
- **示例**：
  ```stata
  ssc install kpss
  kpss gdp
  kpss D.gdp, notrend
  ```

---

## ❖ `arima` （自回归移动平均 / ARIMA 模型）

- **功能**：估计 Box–Jenkins 的 ARIMA(p,d,q)（可加季节项与外生变量），用于预测与政策分析。d 由单位根检验定，p、q 由 AC/PAC 与信息准则定。
- **语法**：
  ```stata
  arima depvar [indepvars] [if] [in] [, arima(#,#,#) sarima(#,#,#,#) ar(numlist) ma(numlist) options]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `arima(p,d,q)` | 自回归阶 p、差分次数 d、移动平均阶 q；可重复写多个 |
| `sarima(P,D,Q,s)` | 季节 AR、季节差分、季节 MA、周期 s（月度 12、季度 4） |
| `ar(#)` / `ma(#)` | 只写 AR 或 MA 的简写 |
| `indepvars` | 外生解释变量（ARIMAX），支持 `L.`/`D.` 算子 |

- **输出结果**：系数表（AR/MA、常数、外生变量）、`sigma`、Log likelihood；存于 `e()`：`e(ll)` 对数似然、`e(aic)`/`e(bic)`、`e(N)`、`e(rank)`、`e(arima)`/`e(sarima)` 阶数。残差 `predict newvar, residuals`；拟合值 `predict newvar, y`（原序列）或 `xb`（差分序列）。
- **常用选项**：
  ```stata
  , arima(1,1,1)                     // ARIMA(1,1,1)
  , arima(1,0,0) ma(1)               // 等价写法：AR(1)+MA(1)
  , arima(1,1,1) sarima(0,1,1,12)    // 月度：加季节 MA
  , vce(robust)                      // 稳健标准误
  , technique(bfgs)                  // 难收敛时换算法
  ```
- **配套检验命令**：
  ```stata
  estat aroots                  // AR/MA 根是否都在单位圆内（平稳+可逆）
  predict er, residuals
  wntestq er, lags(12)          // 残差白噪声
  estat ic                      // AIC/BIC 比较候选阶数（存 r(S) 矩阵）
  estat acplot                  // 模型隐含 AC 与实测对照
  ```
  用途：`estat aroots` 查平稳可逆 → `predict`+`wntestq` 查残差白噪声 → `estat ic` 比 AIC/BIC；三步都过模型才算可用。
- **结果怎么读 · 常见坑**：
  - **`estat ic`/`aroots`/`acplot` 必须在 `arima` 之后立即用**，中间插别的估计命令会报 "last estimates not found"。
  - `predict` 的 `y` 是**原序列**预测、`xb` 是**差分序列**预测；与原序列对比画图必须用 `y`。
  - d **不要靠试**：I(1) → d=1。过度差分会让 MA 根接近 −1（不可逆）；AR/MA 根有一个接近 0.99+ 通常是过度参数化或近单位根。
  - 常数项含义随 d 变化：d=0 是均值、d=1 是漂移（趋势）、d=2 是趋势变化，解释要跟着改。
- **示例**：
  ```stata
  arima gdp, arima(1,1,1)
  predict f, dynamic(tq(2000q1))     // 动态预测
  predict yhat, y                    // 样本内拟合值（原序列尺度）
  arima D.lngdp, arima(1,0,1) sarima(0,1,1,12)
  ```

---

## ❖ `varsoc` （VAR 滞后阶数选择）

- **功能**：为 VAR 选择最优滞后阶，同时报告 AIC、SBIC（BIC）、HQIC 与 FPE、LR 检验。
- **语法**：
  ```stata
  varsoc varlist [if] [in] [, maxlag(#) minlag(#) exog(varlist)]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `varlist` | 进入 VAR 的变量（须平稳或已差分） |
| `maxlag(#)` | 最大考察阶数；月度试 12、季度试 8 |
| `minlag(#)` | 最小考察阶数（默认 0） |
| `exog(varlist)` | 外生变量（季节虚拟变量、断点虚拟变量） |

- **输出结果**：按阶数排列的表，列为 `LL`、`LR` 及 p 值、`FPE`、`AIC`、`HQIC`、`SBIC`，各准则最优阶用 `*` 标出（只打印，需留档用 `log using`）。
- **常用选项**：
  ```stata
  , maxlag(8)             // 季度数据
  , maxlag(12)            // 月度数据
  , exog(d90 d_season)    // 带外生虚拟变量
  ```
- **配套检验命令**：
  ```stata
  var gdp unemp money, lags(1/2)   // 按 varsoc 结论设定 lags
  varlmar                          // 残差自相关（验证阶数够不够）
  varstable                        // 稳定性（特征根在单位圆内）
  ```
  用途：`varsoc` 定阶 → 估 VAR → `varlmar` 确认残差没自相关 → `varstable` 确认稳定；`varlmar` 显著说明阶数仍偏低。
- **结果怎么读 · 常见坑**：
  - **四准则打架是常态**：AIC 偏大（易过拟合）、SBIC 偏小（偏简约）；样本大优先 SBIC/HQIC，关注动态传导时可用 AIC。
  - 必须先保证变量**平稳**再选阶；对不平稳序列选阶毫无意义（先差分或做协整/VECM）。
  - `maxlag()` 不能太大：自由度过低会让末几阶准则值失真。
- **示例**：
  ```stata
  varsoc gdp unemp money, maxlag(6)
  var gdp unemp money, lags(1/2)
  ```

---

## ❖ `var` （向量自回归 VAR）

- **功能**：估计多变量向量自回归，刻画变量间动态相互影响；是 IRF、方差分解、Granger 因果的基础。
- **语法**：
  ```stata
  var depvarlist [if] [in] [, lags(numlist) exog(varlist) noconstant dfk small]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `depvarlist` | 内生变量（每个变量既是因变量，也是所有变量的滞后解释变量） |
| `lags(1/2)` | 使用 1–2 阶滞后；`lags(2)` 表示只到 2 阶 |
| `exog(varlist)` | 外生变量（常数项自动含） |
| `dfk` / `small` | 小样本自由度调整 / 报告 t、F 统计量 |

- **输出结果**：每个方程一张系数表（含 `_cons`），表头给 `Sample`、`Log likelihood`、`AIC`、`SBIC`、`HQIC`；存于 `e()`：`e(b)`/`e(V)`、`e(N)`、`e(ll)`、`e(aic)`、`e(sbic)`、`e(hqic)`、`e(k_eq)`、`e(tmin)`/`e(tmax)`、`e(sample)`。
- **常用选项**：
  ```stata
  , lags(1/2)          // 滞后 1-2 阶
  , exog(d2020q1)      // 外生虚拟变量（如疫情）
  , dfk                // 小样本自由度调整
  ```
- **配套检验命令**：
  ```stata
  varstable                    // 特征根是否都在单位圆内（必做）
  varlmar                      // 残差自相关 LM 检验
  varnorm                      // 残差正态性
  vargranger                   // Granger 因果
  irf create irf1, set(myirf)  // 建 IRF 结果文件
  ```
  用途：`var` 之后标准流程是 `varstable` → `varlmar`（必要时 `varnorm`）→ 再谈因果与脉冲响应；模型不稳定时 IRF 置信带发散，结论作废。
- **结果怎么读 · 常见坑**：
  - **`estat stability` 不是 VAR 的稳定性命令**，正确的是 `varstable`（VECM 对应 `vecstable`）。
  - 单个系数显著与否几乎没意义（滞后项高度共线），要看**联合检验**：`test`、`varwle`、`vargranger`。
  - 变量须平稳（或差分后平稳），否则改用 `vec`；滞后阶由 `varsoc` 定，换阶数会让 IRF 形状甚至符号改变。
  - 加断点虚拟变量（危机、疫情）常比强行提高滞后阶更有效。
- **示例**：
  ```stata
  var gdp unemp money, lags(1/2)
  varstable
  varlmar
  ```

---

## ❖ `irf` （脉冲响应函数）

- **功能**：在 VAR/VECM 基础上计算脉冲响应函数(IRF)与预测误差方差分解(FEVD)，观察一个变量冲击对另一变量的动态影响路径。
- **语法**（先估计 VAR，再 create，再 graph/table）：
  ```stata
  irf set filename [, replace]
  irf create name [, set(filename) step(#) order(varlist) replace]
  irf graph stat [, impulse(varlist) response(varlist) options]
  irf table stat [, impulse(varlist) response(varlist)]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `stat` | `irf`（脉冲响应）、`oirf`（正交化）、`fevd`（方差分解）、`dm`/`cdm`（动态乘数） |
| `irf create` 的 `name` | 本次结果在 IRF 文件中的模型名（可并存多个模型比较） |
| `set(filename)` / `step(#)` | 结果文件名（默认 `irf.irf`）/ 预测期数（默认 8） |
| `order(varlist)` | 正交化的 Cholesky 排序，**先写的变量当期不受后者影响** |

- **输出结果**：`irf create` 只写文件并打印 `(file ... created)`；`irf graph` 出图（含 95% 置信带）、`irf table` 出数值表；`irf describe` 查看文件内容。
- **常用选项**：
  ```stata
  irf create irf1, set(myirf) step(20) replace   // 20 期，覆盖同名结果
  irf create irf1, order(gdp money unemp)        // 指定正交化顺序
  irf graph oirf, impulse(gdp) response(unemp)   // 正交化 IRF
  irf graph oirf, impulse(gdp money) response(unemp)  // 两个冲击画在同一张图
  ```
- **配套检验命令**：
  ```stata
  varstable              // 先确认 VAR 稳定，IRF 才收敛
  vargranger             // 先看有无 Granger 因果，再解释 IRF
  irf describe           // 查看 IRF 文件里有哪些模型与统计量
  ```
  用途：**IRF 之前必须查稳定性**；IRF 与 `vargranger` 互为表里——Granger 显著而 IRF 置信带含 0，说明效应很弱。
- **结果怎么读 · 常见坑**：
  - **必须先 `var`（或 `vec`）再 `irf create`**；中间换估计命令会让 IRF 对应到别的模型。
  - **`irf`（未正交化）与 `oirf`（正交化）不能混着解释**：报告常用 `oirf`，但它依赖 `order()`，顺序换了结果就换——这是识别假设，必须说明理由。
  - 置信带**含 0 的期数**视为不显著；`step()` 太小看不清长期效应，太大尾部爆炸，一般取 12–36 期并截到响应归零。
  - IRF 是"冲击—响应"，不是因果证明。
- **示例**：
  ```stata
  var gdp unemp money, lags(1/2)
  irf create myirf, set(irfresults)
  irf graph oirf, impulse(gdp) response(unemp)
  irf table fevd, impulse(gdp)
  ```

---

## ❖ `vargranger` （Granger 因果检验）

- **功能**：在 VAR 框架下做**成对** Granger 因果 Wald 检验：检验某变量的滞后项是否含有预测另一变量的额外信息。
- **语法**：
  ```stata
  var varlist, lags(numlist)
  vargranger [, estimates(statname) separator(#)]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| 前置 `var` | 只能在 `var` 之后运行，沿用其滞后结构与样本 |
| `estimates(statname)` | 对已存模型（`estimates store`）做检验 |
| `separator(#)` | 每隔 # 行加分隔线，结果多时便于阅读 |

- **输出结果**：一张 "Granger causality Wald tests" 表，每行 `Equation / Excluded` + `chi2` + `df` + `Prob > chi2`，两两双向各一行；结果存入 `r(gstats)` 矩阵（`e(small)` 非空时为 F 统计量）。
- **常用选项**：
  ```stata
  vargranger                       // 输出全部成对检验
  estimates store m1
  vargranger, estimates(m1)        // 对已存模型检验
  ```
- **配套检验命令**：
  ```stata
  varstable                    // 稳定性前提
  varlmar                      // 残差自相关（有自相关时检验不可靠）
  irf create irf1, set(myirf)  // 看动态方向与强度
  ```
  用途：`vargranger` 给"有没有预测信息"的结论，`irf` 给"冲击怎么传导"的图形，两者一起写进报告才完整。
- **结果怎么读 · 常见坑**：
  - H0：被排除变量滞后项系数全为 0（**不** Granger 引起）；P<0.05 → 拒绝 → 存在 Granger 因果。
  - **Granger 因果 ≠ 真正因果**：它只说"预测信息"，不排除遗漏变量与同期内生性。
  - 结论对**滞后阶**与**样本期**敏感，换 `lags()`、去掉断点年份可能翻转，要报告稳健性。
  - 变量不平稳时 χ² 分布不成立（伪因果），先差分或用 VECM；它只做两两检验，不控制第三个变量。
- **示例**：
  ```stata
  var gdp unemp, lags(1/4)
  vargranger
  ```

---

## ❖ `vecrank` （协整秩检验：Johansen）

- **功能**：判断多个非平稳（同为 I(1)）序列之间是否存在长期协整关系、协整向量有几个（协整秩 r）；是 `vec` 定 `rank()` 的官方推荐入口。
- **语法**：
  ```stata
  vecrank depvars [if] [in] [, lags(#) trend(trendspec) notrace max ic level99 levela]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `depvars` | 参与检验的变量（水平值，不是差分值） |
| `lags(#)` | 底层 VAR 滞后阶；VECM 自动少一阶（先 `varsoc` 定阶） |
| `trend(constant)` / `trend(rconstant)` | 无约束常数（默认）/ **受约束常数**（协整关系内有常数、数据无趋势，实证最常用） |
| `trend(trend)` / `trend(rtrend)` / `trend(none)` | 协整关系含线性趋势 / 受约束趋势 / 无常数无趋势 |
| `max` / `ic` / `notrace` / `level99` / `levela` | 报最大特征值统计量 / 报信息准则 / 不显示 trace / 用 1% 临界值 / 同报 1% 与 5% |

- **输出结果**：按"H0：协整秩 ≤ r"逐行列 trace（及 max）统计量与临界值，拒绝的行标 `*`。存于 `e()`：`e(N)`、`e(n_lags)`、`e(k_dv)`、`e(trend)`、`e(trace)`、`e(max)`、`e(lambda)`、`e(ll)`、`e(aic)`/`e(sbic)`/`e(hqic)` 向量；结论直接取 **`e(k_ce95)`**（5% 水平选的秩）、`e(k_ce99)`、`e(k_cesbic)`、`e(k_cehqic)`。
- **常用选项**：
  ```stata
  , lags(2)                // 底层 VAR 滞后 2 阶
  , trend(rconstant)       // 协整关系含受约束常数
  , max                    // 同时给最大特征值统计量
  , levela                 // 同时报 1% 与 5% 临界值
  ```
- **配套检验命令**：
  ```stata
  varsoc gdp money price, maxlag(6)   // 先定 VAR 滞后阶
  dfuller gdp                         // 确认各变量同为 I(1)
  vec gdp money price, rank(1)        // 按结论估计 VECM
  ```
  用途：顺序不能颠倒——确认每个变量 I(1) → `varsoc` 定阶 → `vecrank` 定秩 → `vec` 估计 → `veclmar`/`vecstable` 诊断。
- **结果怎么读 · 常见坑**：
  - 判读：从 r=0 起逐行看，**第一次"统计量 < 临界值"（不拒绝）的 r 就是协整秩**；秩=0 表示没有长期关系，不能建 VECM。
  - trace 与 max-eigen 结论在临界值附近可能不一致，此时以 trace 为主并说明，也可参考 `e(k_cesbic)`。
  - **`trend()` 设错会换掉整张临界值表**：无趋势数据却用 `trend(trend)`，结论严重偏误。
  - 变量必须是水平值；放差分序列做协整检验是常见错误。样本短/断点/离群年份会让 Johansen 检验失真，必要时加 `exog()` 虚拟变量。
- **示例**：
  ```stata
  vecrank gdp money price, trend(constant) lags(2)
  vecrank gdp money price, lags(2) trend(rconstant) max levela
  ```

---

## ❖ `johansen` / `vec` （协整与向量误差修正 VECM）

- **功能**：`johansen` 是 Johansen 协整检验的传统命令（与 `vecrank` 等价、输出更简）；`vec` 估计向量误差修正模型(VECM)，同时给出长期均衡（协整方程）与短期调整（误差修正系数）。
- **语法**：
  ```stata
  johansen varlist [, lags(#) trend(trendspec)]
  vec depvarlist [, rank(#) lags(#) trend(trendspec) exog(varlist) noconstant]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `johansen` 的 `lags(#)` / `trend()` | 底层 VAR 滞后阶 / 趋势规格（含义同 `vecrank`） |
| `vec` 的 `rank(#)` | 协整秩，取自 `vecrank` 的 `e(k_ce95)` |
| `vec` 的 `lags(#)` | VAR 表示的滞后阶（VECM 实际含 `lags-1` 阶差分滞后） |
| `vec` 的 `trend()` / `exog()` | 趋势规格（须与 `vecrank` 一致）/ 外生虚拟变量 |

- **输出结果**：`johansen` 打印特征值、trace/max 统计量与临界值。`vec` 打印协整方程（`_ce1`、`_ce2`…）、各方程中 `_ce1` 的调整系数、差分滞后项系数；存于 `e()`：`e(b)`/`e(V)`、`e(N)`、`e(ll)`、`e(rank)`、`e(n_lags)`、`e(trend)`、`e(aic)`/`e(sbic)`/`e(hqic)`。
- **常用选项**：
  ```stata
  johansen gdp money price, lags(2) trend(constant)
  vec gdp money price, rank(1) lags(2) trend(rconstant)
  vec gdp money price, rank(1) trend(rconstant) exog(d2020q1)
  ```
- **配套检验命令**：
  ```stata
  vecrank gdp money price, lags(2) trend(rconstant)  // 定秩（先做）
  vecstable                                          // 伴随矩阵特征根
  veclmar                                            // 残差自相关 LM
  vecnorm                                            // 残差正态性
  predict ce1, ce equation(_ce1)                     // 取协整关系取值
  ```
  用途：`vecrank` 定秩 → `vec` 估计 → `vecstable`/`veclmar`/`vecnorm` 三诊断 → `predict, ce` 或 `irf create` 做解读。
- **结果怎么读 · 常见坑**：
  - **`rank()` 必须来自 `vecrank`，且 `trend()` 两边一致**；不一致则估计与检验不对应，结论无效。秩=0 时不要用 `vec`。
  - **`_ce1` 是移项后的形式**（Stata 写成 `_ce1 = b1*y1 + b2*y2 + ...`，均衡为 `_ce1 = 0`），解读弹性时需自行反解符号。
  - **调整系数为负且显著**才说明存在向长期均衡的修正；为正或全不显著则长期关系可疑。
  - VECM 的脉冲响应仍需 `irf create`，`irf`/`oirf` 区别同 VAR。
- **示例**：
  ```stata
  johansen gdp money price, lags(2)
  vec gdp money price, rank(2) lags(2)
  vecstable
  ```

---

## ❖ `egranger` / `estat cointegration` （EG 协整检验）

- **功能**：Engle–Granger 两步法协整检验：先对水平值做 OLS，再对**残差**做单位根检验；残差平稳 → 存在协整（长期均衡）。注意 **Stata 官方没有 `egranger` 与 `estat cointegration` 这两个命令**：标准做法就是下面三行手动两步法；想一条命令搞定可装 SSC 模块 `egranger`（`ssc install egranger`，同时给 EG 检验与两步 ECM 估计）。
- **语法**：
  ```stata
  regress y x1 x2            // 第一步：水平值 OLS（协整回归）
  predict ehat, residuals    // 取残差
  dfuller ehat, noconstant   // 第二步：残差单位根检验
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `regress y x1 x2` | 协整回归：变量用**水平值**（不差分），可含常数 |
| `predict ehat, residuals` | 残差即均衡偏离项（误差修正项的滞后形态） |
| `dfuller ehat, noconstant` | 残差均值为 0，检验不放常数项 |
| `ssc install egranger` | 可选：SSC 模块，一次给出 EG 检验 + 两步 ECM |

- **输出结果**：`dfuller` 的 τ 统计量与临界值（`r(Zt)`、`r(cv_5)`、`r(p)`）；协整回归的 `e(b)`/`e(r2)` 只作长期弹性的点估计，**其 t 值不能按常规 t 分布解读**。
- **常用选项**：
  ```stata
  dfuller ehat, noconstant          // 残差无常数
  dfuller ehat, noconstant lags(4)  // 指定滞后阶
  dfuller ehat, noconstant regress  // 显示辅助回归，查残差自相关
  ```
- **配套检验命令**：
  ```stata
  dfuller ehat, noconstant      // 核心：残差单位根
  pperron ehat, noconstant      // 交叉验证
  wntestq ehat, lags(12)        // 残差白噪声（辅助判断回归规格）
  vecrank y x1 x2, trend(rconstant)   // 三变量以上改用 Johansen
  ```
  用途：两变量、单方程用 EG 两步法；三变量以上或需要多个协整向量，直接用 `vecrank`+`vec` 更稳妥。
- **结果怎么读 · 常见坑**：
  - **临界值要对**：检验协整残差时正确的 EG 临界值比标准 DF **更负**，直接用 `dfuller` 的临界值会**偏于判为存在协整**（假阳性）；临界值附近或样本小时用 `vecrank`/`egranger` 复核。
  - **回归方向影响结论**：`regress y x` 与 `regress x y` 残差不同，结论可能不同；两变量时两个方向都试，或改用 Johansen。
  - 残差必须紧接协整回归用 `predict ..., residuals` 取出，中间别插别的估计命令；残差仍有强自相关说明滞后结构没进模型。
  - 结论只说明"存在长期关系"，**不等于**有因果。
- **示例**：
  ```stata
  regress gdp money
  predict ehat, res
  dfuller ehat, nocons
  ```

---

## ❖ `tssmooth` / 差分运算 （数据平滑与差分）

- **功能**：生成对数、差分、滞后等转换变量，或做移动平均/指数平滑，为建模和画图准备"平稳版"数据。
- **语法**：
  ```stata
  gen newvar = ln(var)
  gen dvar = D.var                 // 一阶差分
  gen lvar = L.var                 // 一阶滞后
  tssmooth ma newvar = exp [, window(# [# #])]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `L.` / `L2.` / `F.` | 滞后 1 阶 / 滞后 2 阶 / 前移 1 阶 |
| `D.` / `D2.` / `S.` / `S12.` | 一阶、二阶差分 / 季节滞后（月度 12、季度 4） |
| `window(#l #c #r)` | 移动平均的左期数、是否含当期(0/1)、右期数 |
| `tssmooth` 的 `exp` | 被平滑的表达式，可含算子（如 `D.lngdp`） |

- **输出结果**：`gen` 生成新变量（不存 `e()`）；`tssmooth` 生成平滑序列并回显平滑方法、窗口与缺失的首尾期数。算子依赖 `tsset`，`L.`/`D.` 会自然产生缺失值。
- **常用选项**：
  ```stata
  gen lngdp = ln(gdp)                        // 取对数压方差
  gen dloggdp = D.ln(gdp)                    // 对数差分≈增长率
  gen l2gdp = L2.gdp                         // 二阶滞后
  tssmooth ma gdpma = gdp, window(3 1 3)     // 含当期，左右各 3 期
  tssmooth ma gdpma6 = gdp, window(6 1 0)    // 只看过去（不含未来）
  ```
- **配套检验命令**：
  ```stata
  dfuller D.lngdp              // 差分后立刻复查平稳性
  corrgram D.lngdp, lags(12)   // 差分后 AC 应迅速衰减
  tsline lngdp D.lngdp         // 画图对比水平值与差分值
  ```
  用途：**"取对数 → 差分 → 再检验"** 是处理非平稳序列的标准三步；每生成一个新变量都要重新做单位根检验，别假设它一定平稳。
- **结果怎么读 · 常见坑**：
  - `D.ln(gdp)`（对数差分=增长率）与 `ln(D.gdp)` **不是一回事**，常规用前者。
  - `L.`/`D.` 生成后首期为缺失值，回归会自动丢观测，用 `e(N)` 核对。
  - 移动平均 `window()` 含右期数会**用到未来信息**，做预测评估时属"偷看答案"，预测场景右侧设 0。
  - 平滑会**引入自相关**，平滑序列不适合直接做单位根/回归推断，只用于画图展示趋势。
- **示例**：
  ```stata
  gen lngdp = ln(gdp)
  gen dgdp = D.gdp
  gen dlngdp = D.ln(gdp)
  tssmooth ma gdpma = gdp, window(3 1 3)
  ```

---

## ❖ `cumul` / `gen trend` （趋势与累计）

- **功能**：生成线性/二次趋势项，配合回归控制时间趋势；`cumul` 生成**经验分布函数**（不是累计求和），累计求和要用 `sum()` 函数。
- **语法**：
  ```stata
  gen t = _n                        // 观测序号作为线性趋势
  gen t2 = t^2                      // 二次趋势
  gen csum = sum(x)                 // 累积和
  cumul varname [if] [in] [, generate(newvar)]   // 经验分布函数 F(x)
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `_n` | 当前观测序号（`tsset` 后一般等于时间顺序号） |
| `sum(x)` | `gen` 中的累积求和函数（逐行累加，不是求和统计量） |
| `cumul` 的 `generate(newvar)` | 把经验分布函数值（0–1）存成新变量 |
| `t^2` / `t^3` | 二次 / 三次趋势项 |

- **输出结果**：`gen` 生成变量；`cumul newvar` 打印经验分布表（分位点与取值），`cumul ..., generate(Fx)` 生成累积分布变量，均不存 `e()`。
- **常用选项**：
  ```stata
  gen t = _n                      // 线性趋势
  gen t2 = t^2                    // 二次趋势
  cumul wage, generate(Fwage)     // 经验分布函数
  regress gdp t t2                // 二次趋势回归
  ```
- **配套检验命令**：
  ```stata
  dfuller gdp, trend     // 有趋势时单位根检验必须加 trend
  estat sbcusum          // 趋势回归后查结构突变
  regress gdp t          // 线性趋势（取残差即去趋势）
  ```
  用途：趋势项用于"去趋势"或控制共同趋势；但**去趋势不能替代单位根检验**，随机趋势与确定性趋势的处理完全不同。
- **结果怎么读 · 常见坑**：
  - **`cumul` ≠ 累积求和**：它是经验 CDF；累加用 `gen csum = sum(x)`，面板内用 `bysort id: gen csum = sum(x)`。
  - `_n` 是"行号"，只有 `tsset` 且按时间排序时才等于趋势；安全写法是 `gen t = year - 1960`。
  - 含单位根的序列加趋势项回归会得到"显著"的伪结果（伪去趋势），先 `dfuller ..., trend` 分辨是确定性还是随机趋势。
  - `t` 与 `t2` 高度共线，同时显著不代表都有用，看联合检验与图形。
- **示例**：
  ```stata
  gen t = _n
  regress gdp t t2
  ```

---

## ❖ 时间序列配套检验诊断

> 本节把建模流程中"必须做但不属于某一条命令"的诊断集中起来。顺序：白噪声 → 残差单位根（协整）→ ARCH → 平稳性补充 → 结构突变 → VAR/VECM 诊断。

### ✨ ① 白噪声 / 残差无自相关检验：`wntestq` / `wntestb` / `estat bgodfrey`

- **功能**：检验序列是否为白噪声、或残差是否存在自相关。白噪声是 ARIMA 成败的判据：残差不是白噪声，说明模型没榨干信息。
- **语法**：
  ```stata
  tsset date
  wntestq varname [, lags(#)]              // Ljung-Box Q（序列或残差）
  wntestb varname                          // 累积周期图（Bartlett）
  regress gdp money
  estat bgodfrey [, lags(numlist) nolog]   // Breusch-Godfrey（回归残差）
  arima gdp, arima(1,1,1)
  predict er, residuals
  wntestq er, lags(12)                     // ARIMA 残差检验（最常用）
  ```
- **参数说明**：

| 命令 | 前置 | H0 | 关键选项 |
|---|---|---|---|
| `wntestq` | `tsset` | 无自相关（白噪声） | `lags(#)` 检验到第 # 阶 |
| `wntestb` | `tsset` | 白噪声 | 看图形是否越出置信带 |
| `estat bgodfrey` | `regress` + `tsset` | 残差无自相关 | `lags(numlist)`、`nolog` |

- **输出结果**：`wntestq` 打印 `Portmanteau (Q) statistic` 与 `Prob > chi2`；`wntestb` 画累积周期图（含 95% 带）；`estat bgodfrey` 打印各阶 `chi2`、`df`、`Prob > chi2`。
- **常用选项**：
  ```stata
  wntestq gdp, lags(12)            // 序列层面
  wntestq er, lags(24)             // 月度残差，检验更长阶
  estat bgodfrey, lags(1 4)        // 同时看 1 阶与 4 阶
  ```
- **配套检验命令**：
  ```stata
  corrgram gdp, lags(12)    // 图形化看是哪几阶不显著
  ac er, lags(12)           // 残差自相关图
  ```
  用途：`wntestq` 给联合判决，`corrgram`/`ac` 定位"哪一阶"出问题，两者配合才知道该加 AR 还是 MA。
- **结果怎么读 · 常见坑**：
  - P<0.05 → 存在自相关，需加 AR/MA 项或提高滞后阶；P>0.05 → 不能拒绝白噪声，残差合格。
  - `lags()` 要与频率匹配（月度 12–24、季度 4–8），阶数太少会漏掉季节自相关。
  - `estat bgodfrey` 必须在 `regress` 之后立刻用；`arima` 之后要用 `predict, residuals` + `wntestq`，不能直接 `estat bgodfrey`。
- **示例**：
  ```stata
  tsset mdate
  regress gdp money
  estat bgodfrey, lags(1 4)
  ```

### ✨ ② 残差单位根（协整的 EG 两步）：`dfuller` on residuals

- **功能**：Engle–Granger 协整检验，对协整回归残差做单位根检验；残差平稳即两序列存在长期均衡。
- **语法**：
  ```stata
  regress gdp money
  predict ehat, res
  dfuller ehat, nocons
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `predict ehat, res` | `res` 是 `residuals` 的合法缩写 |
| `dfuller ehat, nocons` | `nocons` 即 `noconstant`：残差无常数 |
| `lags(#)` | 残差自相关较强时指定滞后阶 |

- **输出结果**：τ 统计量与临界值（`r(Zt)`、`r(cv_5)`、`r(p)`）。
- **常用选项**：
  ```stata
  dfuller ehat, noconstant lags(2)   // 指定滞后阶
  dfuller ehat, noconstant regress   // 看辅助回归
  ```
- **配套检验命令**：
  ```stata
  pperron ehat, noconstant    // 交叉验证
  wntestq ehat, lags(12)      // 残差白噪声
  vecrank gdp money, trend(rconstant)   // 多变量改用 Johansen
  ```
  用途：单方程两变量协整用 EG；三变量以上直接 `vecrank` + `vec`。
- **结果怎么读 · 常见坑**：
  - 用标准 DF 临界值检验协整残差会**偏于判为存在协整**，临界值附近必须用 `vecrank` 或 SSC `egranger` 复核。
  - 回归方向会改变结论；两变量时两个方向都试。
  - 残差强自相关说明模型漏了滞后项（可加 `L.` 项或改用 ARDL 的 bounds 检验）。
- **示例**：
  ```stata
  regress lngdp lnmoney
  predict ehat, residuals
  dfuller ehat, noconstant
  ```

### ✨ ③ ARCH 效应检验：`estat archlm` / `arch`

- **功能**：检验金融/波动序列是否存在 ARCH（条件异方差）；显著则用 `arch` 估计 ARCH/GARCH，刻画波动聚集。
- **语法**：
  ```stata
  tsset date
  regress r D.r
  estat archlm, lags(1)             // 对残差检验 ARCH(1)
  arch r ar(1), arch(1)             // ARCH(1)
  arch r, ar(1) arch(1) garch(1)    // GARCH(1,1)
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `estat archlm, lags(numlist)` | 检验到第几阶 ARCH（`lags(1)`、`lags(1 5)`） |
| `arch()` / `garch()` | ARCH 项、GARCH 项阶数 |
| `ar()` / `ma()` | 均值方程中的 AR/MA 项 |

- **输出结果**：`estat archlm` 打印 `chi2`、`df`、`Prob > chi2`；`arch` 打印均值方程与方差方程系数表、`e(ll)`、`e(aic)`/`e(bic)`。条件方差用 `predict vhat, variance` 取出。
- **常用选项**：
  ```stata
  estat archlm, lags(1 5)     // 同时看 1 阶与 5 阶
  arch r, ar(1) arch(1) garch(1) noconstant
  predict vhat, variance      // 取条件方差
  ```
- **配套检验命令**：
  ```stata
  estat ic                // 比较 ARCH 阶数/模型
  predict vhat, variance  // 画出条件方差看波动聚集
  tsline vhat
  ```
  用途：`estat archlm` 决定"要不要建 GARCH"，`estat ic` 与条件方差图决定"几阶合适"。
- **结果怎么读 · 常见坑**：
  - `estat archlm` 只能在 `regress` 一类线性估计之后、且已 `tsset` 时使用。
  - P<0.05 → 存在 ARCH 效应，OLS 标准误不可信；`arch` 中 ARCH/GARCH 项显著为正 → 波动聚集被刻画住。
  - 方差方程要求系数非负、`arch+garch` 之和 <1（否则方差非平稳/爆炸）；不收敛先简化阶数。
  - 收益率序列先去掉均值（`arch r, ar(1)`），直接对价格建 GARCH 无意义。
- **示例**：
  ```stata
  regress r D.r
  estat archlm, lags(1)
  arch r, ar(1) arch(1)
  ```

### ✨ ④ 平稳性（单位根）补充：`dfgls` / `dfuller`（面板用 `xtunitroot`）

- **功能**：确认多个序列是否同阶单整（I(1)），这是 VAR/协整的前提；`xtunitroot` 只用于**面板**数据，纯时间序列不要用。
- **语法**：
  ```stata
  dfuller gdp, lags(2)
  dfuller dgdp                     // 差分后再检
  dfgls gdp                        // DF-GLS，小样本功效更高
  xtset id year
  xtunitroot ips lngdp             // 面板专用（另有 llc / hadri / fisher）
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `dfuller varname` | 时间序列单位根检验 |
| `dfgls varname` | DF-GLS，去均值后检验，功效更高 |
| `xtunitroot ips/llc/hadri` | 面板单位根检验（须先 `xtset`） |

- **输出结果**：`dfgls` 打印各滞后阶的 DF-GLS 统计量与临界值；`xtunitroot` 打印面板统计量与 p 值。
- **常用选项**：
  ```stata
  dfgls gdp                // 自动选滞后阶并报临界值
  dfuller dgdp, noconstant // 差分序列检验
  xtunitroot ips lngdp     // 面板 IPS 检验
  ```
- **配套检验命令**：
  ```stata
  kpss gdp                 // 反向验证
  pperron gdp              // PP 旁证
  vecrank gdp money price  // 同为 I(1) 才能做协整
  ```
  用途：逐个变量报告"水平不平稳、一阶差分平稳"即 I(1)；**同为 I(1)** 才能进协整分析，阶数不同不能直接建 VECM。
- **结果怎么读 · 常见坑**：
  - 纯时间序列误用 `xtunitroot` 会报错（未 `xtset`）；面板误用 `dfuller` 会忽略个体维度，结论无效。
  - 别只检一个"代表变量"，要逐个变量报告检验结果。
  - 差分后仍有趋势要在检验中加 `trend`；差分后 MA 根接近 −1 说明差分过头。
- **示例**：
  ```stata
  dfuller gdp, lags(2)
  dfuller dgdp
  ```

### ✨ ⑤ 结构性突变检验：`estat sbcusum` / Chow（`test`）

- **功能**：判断回归系数是否在样本期内发生结构突变（政策变化、危机、制度转轨）。
- **语法**：
  ```stata
  tsset year
  regress gdp money
  estat sbcusum                    // 递归残差累积和检验（默认）
  estat sbcusum, ols               // 改用 OLS 残差
  estat sbcusum, generate(cusum)   // 保存累积和序列
  * 手动 Chow：按断点拆分年份
  regress gdp money if year<=1990
  regress gdp money if year>1990
  test _b[money]
  * 或用交互项做正式 Chow 检验
  gen post = (year>1990)
  gen money_post = money*post
  regress gdp money post money_post
  test post money_post             // 联合检验 = Chow 检验
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `estat sbcusum` | 默认用递归残差，需 `regress` 且已 `tsset` |
| `, ols` | 改用 OLS 残差的累积和 |
| `, generate(newvar)` | 保存各期累积和 |
| `, level(#)` | 置信带水平，默认 95 |

- **输出结果**：画 CUSUM 图（累积和线与置信带），并存 `r(cusum)` 统计量、`r(cvalues)` 临界值向量、`r(level)`、`r(df)`、`r(statistic)`（`recursive`/`ols`）。
- **常用选项**：
  ```stata
  estat sbcusum                 // 看累积和是否越出置信带
  estat sbcusum, ols            // 换 OLS 残差
  estat sbcusum, level(99)      // 99% 置信带
  ```
- **配套检验命令**：
  ```stata
  dfuller gdp, trend     // 断点会让 ADF 偏向不拒绝，先确认平稳性
  test post money_post   // 交互项法的 Chow 检验
  regress gdp money post money_post
  ```
  用途：CUSUM 提示"有没有突变"，Chow/交互项定位"断点在哪、影响多大"。
- **结果怎么读 · 常见坑**：
  - 累积和线**越出置信带** → 拒绝参数稳定 → 存在结构突变，应加断点虚拟变量、分段回归或交互项。
  - `estat sbcusum` 必须紧跟 `regress`、且已 `tsset`；跑完 `arima`/`var` 之后不能用它。
  - CUSUM **只提示有突变、不告诉你断点位置**；断点位置要用 Quandt-Andrews 类方法或逐个候选年份试。
  - 按"看图猜年份"做 Chow 会高估显著性（数据窥探）；断点前后样本太短时 Chow 无法计算。
- **示例**：
  ```stata
  regress gdp money
  estat sbcusum
  ```

### ✨ ⑥ VAR / VECM 后诊断：`varstable` / `varlmar` / `vecstable`

- **功能**：VAR/VECM 估计后检验模型稳定性与残差是否白噪声；不稳定的 VAR，脉冲响应与预测都不可信。
- **语法**：
  ```stata
  var gdp unemp, lags(1/2)
  varstable                        // 伴随矩阵特征根是否在单位圆内
  varlmar                          // 残差自相关 LM 检验
  varnorm                          // 残差正态性
  varwle                           // 各阶滞后联合显著性（Wald 滞后排除）
  predict r1, residuals equation(gdp)
  wntestq r1, lags(12)             // 逐方程残差白噪声
  vec gdp unemp, rank(1)
  vecstable
  veclmar
  vecnorm
  ```
- **参数说明**：

| 命令 | 作用 |
|---|---|
| `varstable` | 打印特征根表与单位圆图；根模全 <1 → 稳定 |
| `varlmar` | 残差自相关 LM 检验，H0：无自相关 |
| `varnorm` | 残差正态性（Jarque–Bera），H0：正态 |
| `varwle` | 各阶滞后的 Wald 排除检验，判断阶数能否减少 |
| `vecstable` / `veclmar` / `vecnorm` | VECM 的对应版本 |

- **输出结果**：`varstable` 给特征值表（含实部、虚部、模）与单位圆图，并存 `r(Re)`/`r(Im)`/`r(Modulus)`；`varlmar`/`varnorm` 给 χ² 与 p 值；`varwle` 给各阶 χ² 与 p 值；估计结果仍属 VAR 本身。
- **常用选项**：
  ```stata
  varstable, graph            // 画出伴随矩阵特征值的单位圆图
  varstable, estimates(var1)  // 对已存模型检查稳定性
  varlmar                     // 建议默认输出全部阶
  wntestq r1, lags(24)        // 月度数据看更长阶
  ```
- **配套检验命令**：
  ```stata
  vargranger              // 诊断通过后再谈因果
  irf create irf1, set(myirf)   // 再谈动态响应
  varsoc                  // 阶数可疑时回到选阶
  tsline r1               // 画残差图看异常与波动
  ```
  用途：诊断顺序建议 `varstable`（能不能用）→ `varlmar`（阶数够不够）→ `varnorm`（推断是否稳健）→ 再解读 `vargranger`/`irf`。
- **结果怎么读 · 常见坑**：
  - **`estat stability` 不是 VAR 的稳定性命令**，正确的是 `varstable`（VECM 用 `vecstable`）；原教材里的 `estat stability` 与直接 `wntestq r1`（未先生成 `r1`）都会报错。
  - 有根落在圆外 → 模型不稳定，多半是变量不平稳、阶数过高或样本太短；先解决平稳性，别靠调阶数"凑稳定"。
  - `varlmar` P<0.05 → 残差仍有自相关，优先加滞后阶；到上限仍显著，考虑 `exog()` 虚拟变量或改用 VECM。
  - 残差非正态不影响系数一致性，但会让 IRF 置信带偏窄，必要时用 bootstrap 置信区间。
- **示例**：
  ```stata
  var gdp unemp, lags(1/2)
  varstable
  varlmar
  predict r1, residuals equation(gdp)
  wntestq r1, lags(12)
  ```

---

# 第三部分 · 面板数据（Panel Data）

> 面板数据：同一批个体跨多个时间点的观测（个体×时间）。核心是**个体/时间效应、固定效应、随机效应、Hausman 检验**。**必须先 `xtset` 声明。**

> 记忆主线：**`xtset` 声明结构 → `xtdes`/`xtsum` 看清数据 → `xtreg,fe` 与 `xtreg,re` 估计 → `testparm`/`hausman`/`xttest0` 选模型 → `xtserial`/`xttest3`/`xtcsd` 修标准误 → `xtabond2` 处理动态面板**。面板报错九成来自两件事：没 `xtset`；面板变量非数值型或 `id×time` 不唯一。

---

## 📋 本章检验命令速览

> 只列**本章范围内真实可用**的检验/诊断命令。第三列是原假设 H0（"拒绝 H0"一般指 P<0.05）；第四列是**前置命令**，顺序错了会报 `last estimates not found` 或 `not valid after …`。标"需安装"的先 `ssc install 包名`。

| 检验/诊断命令 | 检验什么 | 原假设 H0 | 前置命令 | 结论怎么读 |
|---|---|---|---|---|
| `testparm i.id` | 个体效应是否整体存在（LSDV 形式） | 所有个体虚拟变量系数 = 0 | `regress y x i.id` | P<0.05 → 有个体效应，pooled OLS 不合适，改 `xtreg,fe` |
| `test x1 x2` / `testparm x1 x2 x3` | 若干系数是否**联合**为 0 | 这些系数联合为 0 | `xtreg y x1 x2 x3, fe`（或 `, re`） | P<0.05 → 联合显著 |
| `estat hettest` | 异方差（BP / White） | 同方差 | `regress y x i.id`（**`xtreg` 后不可用**） | P<0.05 → 有异方差，加 `, robust` 或 `, vce(cluster id)` |
| `vif` / `estat vif` | 多重共线性 | 无共线性（VIF = 1） | `regress y x1 x2`（**`xtreg` 后不可用**，见 ⑤） | VIF>10（宽松 5）→ 共线性严重 |
| `xttest0` | 是否存在随机效应（BP LM） | Var(u_i) = 0 | `xtreg y x, re` | P<0.05 → 有随机效应，不该用 pooled OLS |
| `hausman fe re` | FE 与 RE 谁更合适 | RE 一致且有效（个体效应与 x 不相关） | `xtreg,fe` → `estimates store fe` → `xtreg,re` → `estimates store re` | P<0.05 → 用 `fe`；P>0.05 → 用更有效的 `re` |
| `xtserial y x1 x2`（需安装 `xtserial`） | 残差一阶自相关（Wooldridge） | 无一阶自相关 | 只需 `xtset`，**不必先回归** | P<0.05 → 有序列相关，加 `, vce(cluster id)` 或上动态面板 |
| `xttest3`（需安装 `xttest3`） | 组间异方差（Modified Wald） | 各组误差方差相同 | `xtreg y x, fe` | P<0.05 → 用 `, vce(cluster id)` / `, robust` |
| `xttest2`（需安装 `xttest2`） | 截面（同期）相关，**T>N 长面板** | 无截面相关 | `xtreg y x, fe`，须**平衡面板** | P<0.05 → 改用 `xtscc`（Driscoll–Kraay） |
| `xtcsd, pesaran`（需安装 `xtcsd`） | 截面相关，**N 大 T 小** | 无截面相关 | `xtreg y x, fe`（须平衡面板） | P<0.05 → 改用 `xtscc` 或 `xtpcse` |
| `xtunitroot llc y` / `xtunitroot fisher y` | 面板单位根（平稳性） | 所有面板含单位根（非平稳） | 只需 `xtset`（**长面板**才有意义） | P<0.05 → 平稳；不拒绝 → 先差分防伪回归 |
| `xtoverid`（需安装 `xtoverid`） | 过度识别 / 稳健版 Hausman | 工具变量外生、约束成立 | `xtivreg …, fe` 或 `xtreg y x, re robust` | P>0.05 → 工具变量可用（RE 也合适） |
| `estat abond`（`xtabond2` 后，需安装） | Arellano–Bond AR(1)/AR(2) | 无 AR(1)/无 AR(2) | `xtabond2 …` | **AR(2) 的 P>0.10 才合格**；AR(1) 显著属正常 |
| `estat sargan`（`xtabond2` 后） | Sargan 过度识别（工具变量有效性） | 工具变量全部外生 | `xtabond2 …` | P>0.10 才不拒绝；P≈1 说明工具过多，改 `estat hansen` |

> 一句话顺序：**`xttest0`（要不要面板模型）→ `hausman`（fe 还是 re）→ `xtserial`/`xttest3`/`xtcsd`（标准误怎么算）→ 动态模型才用 AB/Sargan**。

---

## ❖ `xtset` （声明面板结构）

- **功能**：告诉 Stata 哪个是个体 ID、哪个是时间变量，是面板命令的前置。不做这一步，所有 `xt*` 命令都报 `no panel data in memory`。
- **语法**：
  ```stata
  xtset panelvar [timevar] [, options]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `panelvar` | 个体标识，**必须是数值型**；字符串 ID 先 `encode` 转数值 |
| `timevar` | 时间变量，**必须是整数型数值**（如 `year`） |
| `delta(#)` | 声明时间间隔，如每 4 年一期用 `delta(4)` |
| `clear` | `xtset, clear` 解除面板设定 |

- **输出结果**：显示 `panel variable: id (strongly balanced)`、`time variable: year, 2000 to 2020`、`delta: 1 unit`；非平衡时标 `(unbalanced)` 并提示 gaps。**不是估计命令，不返回 `e()`**；复查设定直接敲空的 `xtset`。
- **常用选项**：
  ```stata
  xtset id year                 // 最常用：个体 id + 时间 year
  xtset firmid year, delta(4)   // 时间不连续（每 4 年一期）
  xtset, clear                  // 解除面板设定（换 ID 或退回普通数据分析）
  ```
- **配套检验命令**：
  - `duplicates report id year`：`xtset` **之前**必查，`id×year` 必须唯一，否则后面全错。
  - `xtdes`（= `xtdescribe`）：声明后立刻确认 N、T 与是否平衡。
  - `xtsum`：看组内/组间变异，判断数据能否支撑 `fe`。
- **结果怎么读 · 常见坑**：
  - ID 是字符串会报 `string variables not allowed`，先 `encode company, gen(id)`；ID 有缺失会报错，先 `drop if missing(id) | missing(year)`。
  - `id×time` 重复报 `repeated time values within panel`：先 `duplicates report id year`，再 `duplicates drop id year, force`。
  - `(strongly balanced)` 只是描述、不是要求；但 `xtserial`、`xttest2`、`L.x` 对缺口敏感；`reshape`/`collapse`/`merge` 后设定会失效，需重新 `xtset`。
- **示例**：
  ```stata
  encode firmname, gen(firmid)
  xtset firmid year
  xtdes
  ```

---

## ❖ `xtdes` （面板数据结构的描述）

- **功能**：查看面板结构——多少个体、多少期、是否平衡、有无缺失。`xtdes` 是官方 `xtdescribe` 的合法缩写。
- **语法**：
  ```stata
  xtdescribe [varlist] [if] [in]
  ```
- **参数说明**：

| 参数 | 说明 |
|---|---|
| （无参数） | 整体结构：个体数 N、`Distribution of T_i`、观测 pattern |
| `varlist` | 只看这些变量**非缺失**时的观测模式 |
| `[if]`/`[in]` | 限定子样本后再描述 |

- **输出结果**：N、`Distribution of T_i`（各期数频数与累计百分比）、`Pattern` 列表（如 `1111`、`1101`）；只有一种全 1 的 pattern 即强平衡。**纯描述，不返回 `e()`/`r()`**。
- **常用选项**：
  ```stata
  xtdes                    // 整体结构
  xtdescribe wage          // 只在 wage 非缺失时看模式（查缺失空洞）
  ```
- **配套检验命令**：
  - `xtsum`：结构看完再看变异分解，两组信息合起来才判断得出该用哪个模型。
  - `xttab id`：逐个个体列出期数，比 pattern 图更快找出"只有一期"的个体。
  - `xtunitroot`：确认 T 够长（一般 T>10）后才值得做面板单位根检验。
- **结果怎么读 · 常见坑**：
  - 出现多种 pattern 即**非平衡面板**，别用要求平衡的命令（`xttest2`、部分 `xtcsd`）；`T_i` 的 min = 1 的个体对 `xtreg,fe` 毫无贡献（自动剔除），样本损失要在正文交代。
  - 有大段缺口时 `L.x` 不跨缺口取值，滞后回归的 N 会明显变小。
  - 补全缺口用 `tsfill`（需先 `xtset`）再配合插补；`xtdes` 本身不改数据。
- **示例**：
  ```stata
  xtset id year
  xtdes
  ```

---

## ❖ `xtsum` （组内/组间/总体描述统计）

- **功能**：把变量的变异分解为**组间(between)**与**组内(within)**变异。`fe` 只吃组内变异、`be` 只吃组间变异，先看 `xtsum` 就知道哪个模型"有料"。
- **语法**：
  ```stata
  xtsum [varlist] [if] [in]
  ```
- **参数说明**：

| 参数 | 说明 |
|---|---|
| `varlist` | 一个或多个变量；省略时对全部变量分解 |
| `[if]`/`[in]` | 限定样本（如只描述政策前） |

- **输出结果**：每个变量三行——`Overall`（总体）、`Between`（个体均值之间）、`Within`（个体内部偏离），并给出各自 `N` 与 `T-bar`。**不返回 `e()`**；要取数进程序改用 `summarize` 或 `collapse`。
- **常用选项**：
  ```stata
  xtsum wage                      // 单变量：within 与 between 谁大
  xtsum wage edu exp tenure       // 多变量一次分解
  ```
- **配套检验命令**：
  - `summarize varname, detail`：要偏度、峰度、分位数时配合（`xtsum` 不给分位数）。
  - `xtreg y x, fe`：`within` SD 极小的变量在 `fe` 里估不准甚至被 omit，先看再建模。
  - `xtreg y x, be`：想对照纯组间关系时用组间估计。
- **结果怎么读 · 常见坑**：
  - **组内变异太小是致命问题**：几乎不随时间变的变量（性别、地区、出生年）在 `fe` 里会被 omit；反之若 within 只有 between 的 1/10，`fe` 系数会很不精确。
  - `Between` 行的 N 是**个体数**，不是观测数，别混报。
  - 非平衡面板的 `within` 按各自均值去中心化，跨个体不可比。
- **示例**：
  ```stata
  xtset firmid year
  xtsum invest value capital
  ```

---

## ❖ `xttab` / `xttrans` （面板频率表 / 状态转移）

- **功能**：`xttab` 分个体统计频率（把总体百分比拆成 between 与 within）；`xttrans` 看状态从本期到下一期的转移概率，研究"流动性/持续性"的入门工具。
- **语法**：
  ```stata
  xttab varname [if] [in]
  xttrans varname [if] [in]
  ```
- **参数说明**：

| 参数 | 说明 |
|---|---|
| `varname` | 分类变量（先 `label values` 加标签，输出可直接读） |
| `xttab` 三块 | `Overall`（全部观测的频率）/ `Between` / `Within` |
| `xttrans` 方阵 | 行 = 本期状态，列 = 下期状态，对角线 = 状态持续率 |

- **输出结果**：`xttab` 给 `Freq.`、`Percent`、`Cum.` 三列并分 Overall/Between/Within；`xttrans` 给转移概率方阵。**两者都是描述命令，不返回 `e()`/`r()`**。
- **常用选项**：
  ```stata
  xttab employment            // overall / between / within 三视角
  xttrans employment          // 本期→下期转移概率
  ```
- **配套检验命令**：
  - `xtdes`：`xttrans` 依赖相邻两期，先确认没有大缺口。
  - `tabulate varname`：与 `xttab` 的 Overall 列对照，确认没算错。
  - `xtlogit y x, fe`：转移概率显示状态高度持续时，因变量可能要做动态设定（加 `L.y`）。
- **结果怎么读 · 常见坑**：
  - `Between` 与 `Overall` 差异大 → 个体间差异主导（适合 `be` 或加个体效应）；三者接近 → 个体内部变异为主。
  - `xttrans` 只统计**相邻两期都有观测**的样本，非平衡面板的转移概率分母与 `xttab` 不同。
  - 变量必须离散分类，连续变量先 `xtile`/`recode`；有缺失会造成"假持续"。
- **示例**：
  ```stata
  xtset id year
  xttab employment
  xttrans employment
  ```

---

## ❖ `xtreg` （面板数据固定/随机效应回归）

- **功能**：核心面板回归命令。`fe` 允许个体效应与解释变量相关，`re` 要求二者不相关，`be` 只用组间变异，`pa` 是总体平均（GEE）。
- **语法**：
  ```stata
  xtreg depvar [indepvars] [if] [in] [weight] [, options]
  ```
- **参数说明**：

| 选项 | 模型类型 / 含义 |
|---|---|
| `fe` | 固定效应（个体 FE，等价 LSDV），只用组内变异 |
| `re` | 随机效应（GLS），个体效应进入扰动项 |
| `be` | 组间估计，只用个体均值回归（样本量 = 个体数） |
| `pa` | 总体平均（GEE），系数为总体平均效应 |
| `re sa` | `re` 的 Swamy–Arora 方差成分算法（**与"吸收固定效应"无关**） |
| `re mle` / `, ml` | 极大似然版随机效应（可 `lrtest` 比较） |

- **输出结果**：`R-sq: within / between / overall`、`Wald chi2`（re）或 `F`（fe）、`rho`（个体效应方差占比）、`sigma_u`/`sigma_e`、`N` 与 `N_g`（个体数）；`fe` 另有 **`F test that all u_i=0`**，即个体效应整体检验。`e()` 名字：`e(b)`、`e(V)`、`e(r2_w)`、`e(rho)`、`e(sigma_u)`、`e(sigma_e)`、`e(N)`、`e(N_g)`、`e(g_min)`、`e(g_max)`；`fe` 另有 `e(F)`、`e(df_m)`、`e(df_r)`，`re` 另有 `e(chi2)`、`e(theta)`、`e(df)`；`ereturn list` 里可能还有 `e(r2_b)`、`e(r2_o)`，以实际显示为准。
- **常用选项**：
  ```stata
  , fe                        // 固定效应（最常用）
  , fe vce(cluster firmid)    // FE + 个体聚类标准误
  , fe i.year                 // 个体 FE + 年份虚拟变量 = 双向固定效应
  , be                        // 组间估计（看长期/截面关系）
  ```
- **配套检验命令**：
  - `testparm i.year`：检验时间效应是否联合显著；`estat ic` 用来比较不同设定的 AIC/BIC。
  - `predict uhat, e` / `predict ufe, u`：取残差 / 个体效应预测值。
  - `xttest0`、`hausman fe re`：见下文两节，用来定"要不要面板模型"和"fe 还是 re"。
- **结果怎么读 · 常见坑**：
  - `fe` **不报告真正的常数项**，输出里的 `_cons` 是"个体效应均值"，别当截距解释；不随时间变化的变量在 `fe` 里被 omit 不是 bug，是模型识别不了。
  - `fe` 与 `re` 的样本必须可比（`fe` 剔除单期个体、也剔除被 omit 的观测），否则 `hausman` 无效。
  - **聚类数太少**（<30~50）时 `vce(cluster id)` 的标准误不可靠，改用 wild cluster bootstrap（`boottest`，需 `ssc install boottest`）；`, robust` 与 `, vce(cluster id)` 不要同时写。
- **示例**：
  ```stata
  xtset firmid year
  xtreg invest value capital, fe
  xtreg invest value capital i.year, fe vce(cluster firmid)
  ```
  ```stata
  xtreg invest value capital, fe
  estimates store fe1
  xtreg invest value capital, re
  estimates store re1
  esttab fe1 re1, b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) r2
  ```

---

## ❖ `xtreg` 后的 `testparm` / F 检验 （判断是否需要固定效应）

- **功能**：固定效应回归后，检验所有个体虚拟变量是否联合显著（即是否存在个体效应）；也用来检验任一指定变量组（如年份虚拟变量）是否联合显著。`xtreg,fe` 输出末行的 `F test that all u_i = 0` 就是个体效应整体检验。
- **语法**：
  ```stata
  xtreg y x, fe                 // 看末行 F test that all u_i=0
  regress y x i.id
  testparm i.id                 // LSDV 形式下的联合检验
  ```
- **参数说明**：

| 参数 | 说明 |
|---|---|
| `testparm varlist` | 这些变量的系数是否**同时**为 0（联合检验） |
| `i.id` / `i.year` | 因子变量写法，一次检验该因子的所有水平 |
| `test x` | 单个系数 t 检验，等价于看该系数的 P 值 |
| `test x1 = x2` | 线性约束（系数相等）检验 |

- **输出结果**：`F(df1, df2)` 与 `Prob > F`，并回显被检验的约束；`r()` 里有 `r(F)`、`r(df)`、`r(df_r)`、`r(p)`。
- **常用选项**：
  ```stata
  testparm i.year              // 年份虚拟变量是否联合显著
  testparm x1 x2 x3            // 指定变量联合为 0
  test (x1 = 0) (x2 = 0)       // 多个约束同时检验
  ```
- **配套检验命令**：
  - `xttest0`：随机效应形式的 LM 检验，与 F 检验互为佐证。
  - `hausman fe re`：确认有个体效应后，再决定 fe 还是 re。
  - `lincom`：要"系数之和"的点估计与置信区间时用（`test` 只给检验不给区间）。
- **结果怎么读 · 常见坑**：
  - 联合检验与单个 t 检验结论可能相反（共线性下常见）；`Prob > F` 极小只说明个体效应存在，**不等于**"必须用 FE"，还要看 `hausman`。
  - `testparm i.id` 只能在 `regress … i.id` 之后；`fe` 已把个体虚拟变量吸收掉，没有系数可测，`test _cons` 也会报错（无常数项）。
  - N 上千时 LSDV（`i.id`）极慢甚至爆内存，直接用 `xtreg,fe` 的 F 检验。
- **示例**：
  ```stata
  xtreg invest value capital i.year, fe
  testparm i.year
  ```

---

## ❖ `hausman` （Hausman 检验：FE vs RE）

- **功能**：检验应选固定效应还是随机效应。**H0：RE 一致且有效**（个体效应与解释变量不相关）；P<0.05 拒绝 → 用 FE；不拒绝 → 用更有效的 RE。
- **语法**：
  ```stata
  xtreg y x, fe
  estimates store fe
  xtreg y x, re
  estimates store re
  hausman fe re [, options]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `hausman fe re` | 前者一致但低效，后者有效但依赖 H0 |
| `, sigmamore` | 用 pooled 误差方差做分母，提高数值稳定性 |
| `, constant` | 把常数项纳入比较（`fe` 无常数项时慎用） |

- **输出结果**：`chi2(df)` 与 `Prob>chi2`；`r()` 里有 `r(chi2)`、`r(df)`、`r(p)`（可 `display r(p)` 取 P 值）。
- **常用选项**：
  ```stata
  hausman fe re              // 标准用法
  hausman fe re, sigmamore   // chi2 为负/数值不稳时试
  ```
- **配套检验命令**：
  - `xttest0`（re 后）：先确认"到底要不要面板模型"，再谈 fe/re 取舍。
  - `xtoverid`（需安装）：`xtreg y x, re robust` 之后的**稳健版 Hausman**，聚类稳健下应当用它。
  - `estimates dir`：确认两个模型都存上了（名字重复、顺序写反都会让检验失败）。
- **结果怎么读 · 常见坑**：
  - **负 chi2** 或提示 `fails to meet the asymptotic assumptions`：RE 低效所致，改用 `, sigmamore`、去掉 `, robust`，或直接用 `xtoverid`。
  - 两个回归必须同样本同变量；`fe` 剔除单期个体会让样本不同，可先限定 `if e(sample)` 再估 `re`。
  - **不能用聚类/稳健版本做经典 Hausman**（那是 `xtoverid` 的领域）；结论随设定与样本期变化，报告时最好两套估计并列。
- **示例**：
  ```stata
  xtreg invest value capital, fe
  estimates store fixed
  xtreg invest value capital, re
  estimates store random
  hausman fixed random
  ```

---

## ❖ `xtlnull` / `testparm` （随机效应检验的 Larange 乘子检验）

> ⚠️ **先纠一个笔误**：Stata **没有** `xtlnull` 这个命令（输入会报 `unrecognized command`）。真正做 Breusch–Pagan 拉格朗日乘子（LM）检验的是官方命令 **`xttest0`**，且必须在 `xtreg …, re` 之后运行。原条目名保留以便对照，语法一律以 `xttest0` 为准。

- **功能**：`xttest0`（RE 回归后）做 Breusch–Pagan 的 LM 检验，判断是否存在随机效应，即"要不要面板模型，还是 pooled OLS 就够"。
- **语法**：
  ```stata
  xtreg y x, re
  xttest0
  ```
- **参数说明**：

| 参数 | 说明 |
|---|---|
| （无参数） | 只能紧跟 `xtreg, re` 估计之后，不能加变量 |
| 前置条件 | 先 `xtset`，再跑 `xtreg …, re` |

- **输出结果**：`Breusch and Pagan Lagrangian multiplier test for random effects`，给出 `chibar2(01)` 与 `Prob > chibar2`；`r()` 里有 `r(chi2)`、`r(df)`、`r(p)`。
- **常用选项**：
  ```stata
  xtreg y x, re
  xttest0                // 唯一正确用法：紧跟 re 之后
  ```
- **配套检验命令**：
  - `regress y x`：LM 不显著时 pooled OLS 就够，用它报告结果即可。
  - `hausman fe re`：确认有面板效应之后，再决定 fe 还是 re。
  - `xttest3`（需安装）：`fe` 之后的组间异方差检验，与"有没有效应"是两回事。
- **结果怎么读 · 常见坑**：
  - P<0.05 → 存在随机效应，不该用 pooled OLS；P>0.05 → 用 `regress` 即可，面板模型没有额外信息。
  - 统计量服从**混合卡方**（`chibar2`），别查普通卡方临界值；`fe` 之后会报 `xttest0 is not valid after xtreg, fe`。
  - LM 显著只说明"个体效应方差不为 0"，**不能**替代 `hausman`；带 `, robust`/聚类时结论会受影响。
- **示例**：
  ```stata
  xtreg invest value capital, re
  xttest0
  ```

---

## ❖ `xtivreg` （面板工具变量回归）

- **功能**：面板存在内生解释变量时，用固定/随机效应 + 工具变量（2SLS 的面板版）。`fe` 先组内变换再 2SLS，`fd` 做一阶差分，`re` 是 GLS 型 IV。
- **语法**：
  ```stata
  xtivreg depvar [varlist1] (varlist2 = varlist_iv) [if] [in] [weight] [, options]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `varlist1` | 外生解释变量（自身充当工具变量） |
| `(varlist2 = varlist_iv)` | 左 = 内生变量，右 = 排除性工具变量 |
| `fe`/`re`/`fd`/`be` | 固定效应 / 随机效应 / 一阶差分 / 组间 IV |
| `, first` | 报告第一阶段回归（看工具变量强弱） |
| `, vce(cluster id)` | 聚类稳健标准误（面板几乎必加） |

- **输出结果**：系数、z（或 t）、`Wald chi2`（或 F）、`R-sq`、`N`、`N_g`；`e()` 里有 `e(b)`、`e(V)`、`e(N)`、`e(N_g)`、`e(r2)`、`e(chi2)`（以 `ereturn list` 为准）。
- **常用选项**：
  ```stata
  , fe first                 // FE-IV + 第一阶段
  , fd                       // 一阶差分 IV
  , fe vce(cluster firmid)   // 聚类稳健（推荐）
  ```
- **配套检验命令**：
  - `xtoverid`（需安装）：过度识别检验，检验工具变量是否外生（恰好识别时无法做）。
  - `hausman fe_iv re_iv`：IV 框架下的 fe/re 取舍（同样可能出负 chi2）。
  - `ivreg2` / `ivreghdfe`（需安装）：弱工具变量、Hansen J 等完整诊断，多维固定效应 + IV 的首选。
- **结果怎么读 · 常见坑**：
  - `fe` 会**吸收掉不随时间变化的工具变量**（被 omit），工具变量必须在个体内随时间变化；工具变量数 < 内生变量数直接报识别不足。
  - `xtivreg` 默认不聚类，面板推断要加 `, vce(cluster id)`；`fd` 会再损失一期观测。
  - `estat firststage` 是 `ivregress` 的，`xtivreg` 用 `, first` 看第一阶段，弱工具变量参考第一阶段 F 是否远大于 10。
- **示例**：
  ```stata
  xtivreg y x1 (x2 = z1 z2), fe first vce(cluster firmid)
  xtoverid
  ```

---

## ❖ `xtprobit` / `xtlogit` （面板离散选择）

- **功能**：面板因变量为 0/1 时使用。`xtlogit, fe` 是**条件（固定效应）Logit**，无需假设个体效应与 x 不相关；`re` 把个体效应当正态随机变量。`xtprobit` 只有 `re` 与 `pa`，**没有 `fe`**。
- **语法**：
  ```stata
  xtlogit depvar [indepvars] [if] [in] [weight] , fe|re|pa [options]
  xtprobit depvar [indepvars] [if] [in] [weight] , re|pa [options]
  ```
- **参数说明**：

| 选项 | 说明 |
|---|---|
| `xtlogit, fe` | 条件固定效应 Logit（只保留因变量在个体内有变化的样本） |
| `xtlogit, re` | 随机效应 Logit（个体效应服从正态分布） |
| `, pa` | 总体平均（GEE），配 `, vce(cluster id)` |
| `, or` | 报告几率比（odds ratio）而非系数 |
| `, nolog` | 不打印迭代过程 |

- **输出结果**：系数（或 OR）、z 值、`Wald chi2`、`Log likelihood`、`N`、`N_g`；`re` 版本另给 `rho` 与 `Prob >= chibar2`（rho 是否为 0 的 LR 检验）。`e()` 里有 `e(b)`、`e(V)`、`e(ll)`、`e(N)`、`e(N_g)`、`e(chi2)`。
- **常用选项**：
  ```stata
  , fe                    // 条件固定效应 Logit（xtlogit 专用）
  , re or                 // 随机效应 + 几率比
  , pa vce(cluster id)    // 总体平均 + 聚类
  ```
- **配套检验命令**：
  - `margins, dydx(*)`：平均边际效应（Logit 系数不能直接当边际效应读）。
  - `testparm x1 x2`：变量联合显著性；`estat ic` 比较不同设定的 AIC/BIC。
  - `hausman fe re`：条件 Logit 与 RE Logit 取舍（常出负 chi2，且两者样本不同，慎用）。
- **结果怎么读 · 常见坑**：
  - `xtlogit, fe` **丢掉"因变量在个体内无变化"的个体**（全 0 / 全 1），N 骤减，必须在正文交代样本损失。
  - `xtprobit` 不支持 `, fe`；要固定效应用 `xtlogit, fe` 或 `clogit y x, group(id)`。
  - 系数是**对数几率**不是概率：要么 `, or`，要么 `margins, dydx(*)`；二元面板 FE 还有附带参数问题，T 小时别只报 FE。
- **示例**：
  ```stata
  xtlogit employment educ age, fe
  xtlogit employment educ age, re or
  margins, dydx(*)
  ```

---

## ❖ `xtpoisson` （面板计数模型）

- **功能**：面板计数因变量（专利数、就诊次数、事故数）。`fe` 是条件固定效应泊松，`re` 假设个体效应服从 Gamma 分布。
- **语法**：
  ```stata
  xtpoisson depvar [indepvars] [if] [in] [exposure(varname)] [offset(varname)] , fe|re|pa [options]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `depvar` | 计数变量（非负整数） |
| `exposure(varname)` | 暴露量（员工数、人口数），等价于加 `ln(exposure)` 并约束系数为 1 |
| `offset(varname)` | 直接给偏移项（一般已取对数） |
| `fe`/`re`/`pa` | 条件固定效应 / 随机效应 / 总体平均 |
| `, irr` | 报告发生率比（incidence-rate ratio） |

- **输出结果**：系数（或 IRR）、z 值、`Wald chi2`、`Log likelihood`、`N`、`N_g`；`re` 版本另报 `alpha`（个体效应离散参数）。`e()` 里有 `e(b)`、`e(V)`、`e(ll)`、`e(N)`、`e(N_g)`、`e(chi2)`。
- **常用选项**：
  ```stata
  , fe                        // 条件固定效应泊松
  , re                        // 随机效应（看 alpha 是否显著）
  , fe irr                    // 报告发生率比，解读直观
  ```
- **配套检验命令**：
  - `xtnbreg y x, fe`：过度分散严重时改负二项（官方命令，与 `xtpoisson` 同框架）。
  - `estat ic`：`xtpoisson` 与 `xtnbreg` 的 AIC/BIC 对比。
  - `margins, dydx(*)` / `margins, at(...)`：平均边际效应、特定取值下的预测次数。
- **结果怎么读 · 常见坑**：
  - 计数变量含负值或非整数会报错/警告，先 `summarize` 核对；有 0 不能放进 `exposure()`（要取对数）。
  - `fe` 剔除"计数全为 0"的个体，结论只对"有变化"的个体成立。
  - 泊松要求均值 = 方差，`alpha` 显著说明过度分散，考虑 `xtnbreg, re`；`irr` 读作"发生率变为原来的 irr 倍"。
- **示例**：
  ```stata
  xtpoisson patents rnd, fe exposure(employees) irr
  ```

---

## ❖ `long` / `reshape` （面板数据长宽转换）

- **功能**：`reshape long`/`wide` 在长格式与宽格式之间转换；**`xtset` 需要 long 格式**（每行 = 一个个体一期）。从 Excel 拷来的宽表（一行一个体、多列年份）必须先转长。
- **语法**：
  ```stata
  reshape long stubnames, i(idvars) j(newvar) [options]
  reshape wide stubnames, i(idvars) j(var) [options]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `stubnames` | 变量前缀，如 `y x`（对应 `y2001 y2002 …`） |
| `i(idvars)` | 个体标识 |
| `j(newvar)` | 由变量名后缀生成的时间变量（long 时新建） |
| `, string` | 后缀是字符串（如 `y_A`）时使用 |
| `, at(...)` | 指定后缀取值范围 |

- **输出结果**：报告转换提示 `(note: j = 2001, ...)`、`(j = 3 levels)` 与转换后观测数；成功后即可 `xtset id year`。**不返回估计结果**（`return list` 只有少量返回值）。
- **常用选项**：
  ```stata
  reshape long y, i(id) j(year)          // 宽 → 长（year 由后缀生成）
  reshape wide y, i(id) j(year)          // 长 → 宽（一行一个体）
  reshape error                          // 诊断：为什么转不了
  ```
- **配套检验命令**：
  - `duplicates report id year`：转长后立刻查唯一性（最常见的副作用就是重复）。
  - `xtset id year` + `xtdes`：确认结构与平衡性；`isid id year` 断言唯一。
  - `describe`：转换前看清变量名规律，`stubnames` 写错会报 `variable y2001 not found`。
- **结果怎么读 · 常见坑**：
  - 同前缀变量后缀必须**完全对应**，缺年份会造缺失或报错；宽转长时 `j()` 变量由 Stata 生成，已有同名变量会报 `j variable already defined`。
  - 转完必须**重新 `xtset`**，原面板设定失效。
  - 宽表不能直接 `xtset`；长表才能用 `xtline y` 画每个个体的时间序列。
- **示例**：
  ```stata
  reshape long invest, i(firmid) j(year)
  xtset firmid year
  xtdes
  ```

---

## ❖ `xtreg, sa` / `xtreg, fe` 需要注意的 `absorb` （多维固定效应）

- **功能**：`xtreg` 只支持**一个**个体固定效应（面板变量），时间效应要靠 `i.year` 手加。需要"个体 + 年份 + 行业 + 地区"等高维固定效应时，用官方 `areg`（一个 `absorb()`）或第三方 `reghdfe`（多个 `absorb()`、自动剔单例）。注意 `xtreg, re sa` 的 `sa` 是 Swamy–Arora 方差成分算法，**与吸收固定效应无关**。
- **语法**：
  ```stata
  areg depvar indepvars, absorb(panelvar) [options]
  reghdfe depvar indepvars, absorb(absvars) [options]     // ssc install reghdfe
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `absorb(firmid)` | `areg` 的吸收变量，**只能一个**，等价 `xtreg, fe` |
| `absorb(firmid year)` | `reghdfe` 多维度吸收 |
| `absorb(firmid year industry#year)` | 高阶交互固定效应 |
| `, keepsingletons` | `reghdfe` 默认剔除单例，加此项保留 |
| `, resid(newvar)` | 保存残差，供后续自相关/截面相关检验 |

- **输出结果**：`areg` 报 `F`、`R-squared`、`Adj R-squared`、`Root MSE`，`e()` 里有 `e(b)`、`e(V)`、`e(r2)`、`e(r2_a)`、`e(df_a)`（被吸收自由度）；`reghdfe` 报 `R2`、`R2_within`、`R2_a`、`N_hdfe`，`e()` 里有 `e(r2)`、`e(r2_within)`、`e(r2_a)`、`e(df_a)`、`e(N_hdfe)`、`e(N_clust)`。
- **常用选项**：
  ```stata
  areg y x, absorb(firmid) vce(cluster firmid)            // 一个 FE + 聚类
  reghdfe y x, absorb(firmid year) vce(cluster firmid)    // 双向固定效应
  reghdfe y x, absorb(firmid year) keepsingletons         // 保留单例
  reghdfe y x, absorb(firmid year) resid(ehat)            // 存残差
  ```
- **配套检验命令**：
  - `testparm x1 x2`：`reghdfe` 后照常做联合显著性检验。
  - `xtscc y x, lag(2)`（需安装）：Driscoll–Kraay 标准误，处理截面相关 + 自相关。
  - `estimates store` + `esttab`：与 `xtreg,fe` 并排比较，确认 FE 部分一致。
- **结果怎么读 · 常见坑**：
  - `areg` 的 `absorb()` 只能放一个；要两个请把 `i.year` 放进解释变量，或改用 `reghdfe`。
  - `reghdfe` 默认**剔除单例**，N 比 `xtreg,fe` 小，结果对不上时先加 `keepsingletons`；它的 `R2` 与 `xtreg` 的 `R-sq: within` 口径不同，报告时注明。
  - `reghdfe` 是第三方命令，装完首次运行还会要求装 `ftools` 等依赖；把 `xtreg, sa` 当"多维固定效应"是**错的**。
- **示例**：
  ```stata
  ssc install reghdfe
  reghdfe y x1 x2, absorb(firmid year) vce(cluster firmid)
  ```

---

## ❖ `xtgls` （面板广义最小二乘）

- **功能**：考虑面板异方差与同期相关的 GLS，常用于 T 较长、个体数不多的面板。可让每个面板有各自误差方差（`panels(hetero)`），并允许面板内自相关（`corr(ar1)`）与面板间同期相关（`panels(correlated)`）。
- **语法**：
  ```stata
  xtgls depvar [indepvars] [if] [in] [weight] , panels(hetero|correlated|iid) [corr(ar1|psar1|independent)] [options]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `panels(hetero)` | 每个面板有各自误差方差（组间异方差） |
| `panels(correlated)` | 允许面板间同期相关（需 T ≥ N） |
| `corr(ar1)` / `corr(psar1)` | 面板内一阶自相关（系数相同 / 面板特定） |
| `, igls` | 迭代 GLS（默认两步可行 GLS） |
| `, nmk` | 不做小样本自由度校正 |

- **输出结果**：系数、z 值、`Wald chi2`、`Log likelihood`；`e()` 里有 `e(b)`、`e(V)`、`e(chi2)`、`e(ll)`、`e(N)`、`e(N_g)`、`e(Ti)`（各面板期数），`ereturn list` 还可见 `e(Sigma)`。
- **常用选项**：
  ```stata
  , panels(hetero) corr(ar1)           // 组间异方差 + 面板内 AR(1)（最常用）
  , panels(heteroskedastic) corr(ar1)  // 同上，全称写法
  , panels(correlated) corr(ar1)       // 再加同期相关（T 不能太小）
  ```
- **配套检验命令**：
  - `xttest3`（需安装）：`xtreg,fe` 后检验组间异方差，决定要不要 `panels(hetero)`。
  - `xttest2`（需安装）：平衡面板且 T>N 时检验截面相关，决定要不要 `panels(correlated)`。
  - `xtpcse y x, corr(ar1)`（官方）、`xtscc y x, lag(2)`（需安装）：更稳健的替代，N 大 T 小时优先。
- **结果怎么读 · 常见坑**：
  - GLS 对"方差结构设定正确"很敏感，设错反而不如 `xtreg,fe vce(cluster id)` 稳健；`panels(correlated)` 要求 **T ≥ N**，否则直接报错。
  - `xtgls` **没有固定效应选项**，要个体效应请用 `i.id` 或改 `xtreg`；非平衡面板下 `corr(ar1)`、`panels(correlated)` 可能失败，先 `xtdes` 看结构。
  - `xtgls` 与 `xtreg,re` 不嵌套，**不能**做 `hausman`。
- **示例**：
  ```stata
  xtgls invest value capital, panels(hetero) corr(ar1)
  ```

---

## ❖ `xtabond2` （动态面板 GMM：Arellano–Bond / Blundell–Bond）

- **功能**：因变量含滞后项（`L.y`）时，`xtreg,fe` 有"动态面板偏误"、不一致。`xtabond2` 用差分 GMM / 系统 GMM 估计，并给出 Arellano–Bond 自相关与 Sargan/Hansen 过度识别检验。**需安装**：`ssc install xtabond2`。
- **语法**：
  ```stata
  xtabond2 depvar L.depvar [indepvars] [if] [in] , gmm(gmmvars, gmmopts) iv(ivvars) [options]
  ```
- **参数说明**：

| 参数/选项 | 说明 |
|---|---|
| `gmm(...)` | 被工具化的内生/预设变量（常用 `L.y`），括号内 `lag(2 3)` 指定可用滞后阶范围 |
| `iv(...)` | 严格外生变量（自己给自己当工具） |
| `, noleveleq` | 只用差分方程（差分 GMM）；默认是系统 GMM |
| `, twostep` / `, robust` | 两步 GMM（更有效）/ 稳健标准误（twostep 时自动给 Windmeijer 校正） |
| `collapse`（在 `gmm()` 内） | 压缩工具变量数，缓解"工具过多" |

- **输出结果**：系数表、`Number of instruments`、`Arellano-Bond test for AR(1)/AR(2)`（z 与 P）、`Sargan test`、`Hansen test`。`e()` 里有 `e(ar1p)`、`e(ar2p)`、`e(sarganp)`、`e(hansenp)`、`e(n_instr)`、`e(N)`、`e(N_g)`、`e(g_min)`、`e(g_max)`（以 `ereturn list` 为准）。
- **常用选项**：
  ```stata
  , gmm(L.y, lag(2 3)) iv(x1 x2)            // 差分 GMM：用 2 阶及更远滞后做工具
  , gmm(L.y, lag(2 .)) iv(x1 x2) robust     // 系统 GMM（含水平方程）
  , gmm(L.y, lag(1 2) collapse) iv(x1 x2)   // 压缩工具变量，缓解工具过多
  ```
- **配套检验命令**：
  - `estat abond`：重看 AR(1)/AR(2)，便于取数报出。
  - `estat sargan` / `estat hansen`：过度识别检验（后者异方差稳健，更可信）。
  - 与 `xtreg y L.y x, fe` 对照：T 较大时后者动态偏误已很小，未必要上 GMM。
- **结果怎么读 · 常见坑**：
  - **AR(1) 显著是正常的**（差分后必有负一阶自相关），关键是 **AR(2) 的 P>0.10**。
  - Sargan/Hansen 的 P 要 >0.10 但**不能接近 1**，否则说明工具过多、检验失效（用 `collapse` 或缩短 `lag()`）；`n_instr` 必须 ≤ 个体数 N_g。
  - 系统 GMM 需要"差分变量与个体效应无关"的额外假设；缺失值会截断滞后链，样本对不上时先 `xtdes` 复查。
- **示例**：
  ```stata
  xtabond2 y L.y x1 x2, gmm(L.y, lag(2 3)) iv(x1 x2) robust noleveleq
  estat abond
  estat sargan
  ```

---

## ❖ 面板配套检验诊断

> 标准动作顺序：**① 要不要面板模型（`xttest0` / `testparm`）→ ② fe 还是 re（`hausman`）→ ③ 标准误怎么修（`xtserial` / `xttest3` / `xtcsd`）→ ④ 动态模型再加 AB 与 Sargan**。检验只是提示牌，最终要结合 N、T、平衡性与经济学含义判断。

### ✨ ① 固定 vs 随机效应：`hausman`（见上文核心）
- **语法**：
  ```stata
  xtreg y x, fe
  estimates store fe
  xtreg y x, re
  estimates store re
  hausman fe re
  ```
- **解读**：P<0.05 → 用 `fe`；P>0.05 → 用更有效的 `re`。
- **坑**：出现负 `chi2` 或 `fails to meet the asymptotic assumptions` 时，改用 `, sigmamore`，或 `xtreg y x, re robust` + `xtoverid`（需 `ssc install xtoverid`）。

### ✨ ② 是否有随机效应（LM 检验）：`xttest0`
- **语法**：
  ```stata
  xtreg y x, re
  xttest0
  ```
- **解读**：P<0.05 → 存在随机效应，不该用混合 OLS（pooled）；P>0.05 → `regress` 足够。
- **坑**：统计量是 `chibar2(01)`（混合卡方），不能查普通卡方表；`fe` 之后报 `not valid`。

### ✨ ③ 个体效应联合检验：`testparm` on dummies / `xtreg fe`
- **功能**：固定效应是否整体显著，以及某组变量（如年份虚拟变量）是否联合显著。
- **语法**：
  ```stata
  xtreg y x, fe                      // 看末行 F test that all u_i=0
  regress y x i.id
  testparm i.id                      // LSDV 形式下的联合检验
  xtreg y x i.year, fe
  testparm i.year                    // 时间效应是否联合显著
  ```
- **坑**：`testparm` 是联合检验，与逐个 t 检验可能不同；`fe` 之后没有个体虚拟变量可测。

### ✨ ④ 面板自相关检验：`xtserial`（Wooldridge）
- **功能**：检验面板残差一阶自相关（H0：无一阶自相关）。**需安装**：`ssc install xtserial`。
- **语法**：
  ```stata
  ssc install xtserial
  xtserial y x1 x2
  ```
- **解读**：P<0.05 → 有序列相关，加 `, vce(cluster id)` 或引入 `L.y` 上动态面板。
- **坑**：只需 `xtset`、不必先回归；非平衡面板会损失观测，T 很小时功效低。

### ✨ ⑤ 面板异方差检验：`xttest3` / 修正`xtgls`
- **功能**：固定效应回归后检验组间异方差（Modified Wald，H0：各组误差方差相同）。**需安装**：`ssc install xttest3`。
- **语法**：
  ```stata
  ssc install xttest3
  xtreg y x, fe
  xttest3                     // 组间异方差检验（需第三方，可装）
  ```
- **解读**：P<0.05 → 用 `xtreg y x, fe vce(cluster id)` 或 `, robust`。
- **坑**：`xttest3` 只在 `xtreg,fe` 之后有效；**`xtreg` 之后不能用 `estat hettest`**（它只服务于 `regress`），要么 `regress y x i.id` + `estat hettest`，要么直接用 `xttest3`。同理 **`estat vif`/`vif` 在 `xtreg,fe` 之后不可用**（无常数项、个体效应已吸收），要看 VIF 请用 `regress y x i.id` 或 `regress y x` 之后 `estat vif`。

### ✨ ⑥ 面板单位根检验：`xtunitroot`
- **功能**：长面板时检验变量是否平稳，防伪回归。**官方命令**，无需安装。
- **语法**：
  ```stata
  xtunitroot llc y                        // Levin–Lin–Chu（H0：所有面板含单位根）
  xtunitroot ips y                        // Im–Pesaran–Shin（允许异质系数）
  xtunitroot fisher y, dfuller lags(1)    // Fisher 型（ADF 基础）
  xtunitroot ht y                         // Harris–Tzavalis（T 固定、N 大）
  ```
- **解读**：P<0.05 → 平稳；不拒绝 → 差分后重做（`gen dy = D.y`）。
- **坑**：要求 T 足够长（通常 T>10）；LLC 假设各面板自回归系数相同，异质性强的数据用 IPS/Fisher；检验形式要与数据特征匹配。

### ✨ ⑦ 组间同期相关检验：`xtcsd`
- **功能**：检验各截面残差是否同期相关（H0：无截面相关）。**需安装**：`ssc install xtcsd`。
- **语法**：
  ```stata
  xtreg y x, fe
  xtcsd, pesaran            // Pesaran CD（N 大 T 小首选）
  xtcsd, frees              // Frees 检验
  xtcsd, friedman           // Friedman（T 大 N 小）
  ```
- **解读**：P<0.05 → 有截面相关，改用 `xtscc`（Driscoll–Kraay，需 `ssc install xtscc`）或 `xtpcse`。
- **坑**：经典 `xtcsd` 要求**平衡面板**；`xttest2`（需安装）用于 T>N 且同样要求平衡；截面相关 ≠ 空间相关。

### ✨ ⑧ 动态面板诊断：`xtabond2` 的 Arellano–Bond 与 Sargan/Hansen
- **语法**：
  ```stata
  xtabond2 y L.y x1 x2, gmm(L.y, lag(2 3)) iv(x1 x2) robust noleveleq
  estat abond        // AR(1)/AR(2)
  estat sargan       // Sargan 过度识别检验
  estat hansen       // Hansen J（稳健版）
  ```
- **解读**：AR(2) 的 P>0.10 才算合格；Sargan/Hansen 的 P>0.10 且不接近 1，说明工具变量可用且不过多。
- **坑**：`n_instr` 应小于个体数 N_g，否则检验失效；AR(1) 显著属正常。

### ✨ ⑨ 工具变量面板的过度识别：`xtoverid`
- **功能**：`xtivreg`（或 `xtreg, re robust`）之后检验过度识别约束，也是稳健版 Hausman。**需安装**：`ssc install xtoverid`。
- **语法**：
  ```stata
  xtivreg y x1 (x2 = z1 z2), fe
  xtoverid
  ```
- **解读**：P>0.05 → 不能拒绝"工具变量外生"，工具变量可用；P<0.05 → 至少一个工具变量不外生。
- **坑**：恰好识别（工具变量数 = 内生变量数）时无法检验。

---

# 第四部分 · 因果分析（Causal Inference）

> 因果推断：目的是从观测数据估计**处理效应**，而不是相关关系。核心方法论包括**DID、匹配(PSM)、IV（工具变量）、断点回归(RDD)、面板 DID 变体、合成控制**等。
>
> 本章顺序：DID（含交错处理的稳健估计量）→ 匹配与加权 → 工具变量 → 高维固定效应 → 断点回归 → 合成控制 → 随机化推断与重抽样 → 高维协变量选择 → 章末「因果分析配套检验」。每个命令条目后的「配套检验命令」和「结果怎么读 · 常见坑」是实战中最容易被忽略、也最容易被审稿人抓住的部分。

---

## 📋 本章检验命令速览

| 检验/诊断命令 | 检验什么 | 原假设 H0 | 前置命令 | 结论怎么读 |
|------|------|------|------|------|
| `estat ptrends` | 处理前两组线性趋势是否相同（平行趋势） | 两组处理前趋势相同 | `didregress` / `xtdidregress` | P>0.05 不拒绝 → 平行趋势可接受；P<0.05 → 事前趋势已分叉 |
| `estat granger` | 处理前结果是否已能"格兰杰预测"处理状态 | 处理前无格兰杰因果（无提前反应） | `didregress` / `xtdidregress` | P>0.05 → 处理前结果未提前反应，支持设计有效 |
| `estat event` | 逐期处理效应（含处理前各期） | 处理前各期效应 = 0 | `didregress` / `xtdidregress` | 事前系数接近 0 且不显著 → 平行趋势；事后系数即动态效应 |
| `estat trendplots` | 两组处理前后趋势图（可视诊断） | 无（作图） | `didregress` / `xtdidregress` | 处理前两线是否平行、处理后是否分离 |
| `estat firststage` | 第一阶段工具系数是否联合为零；最小特征值/弱工具诊断 | 工具系数联合为 0（工具弱/无效） | `ivregress 2sls` | 第一阶段 F 或最小特征值远大于 10 才算强工具 |
| `estat endog` | 内生变量是否真的内生（DWH 检验） | 变量外生（OLS 与 IV 一致） | `ivregress 2sls` | P<0.05 拒绝外生 → 确需 IV；P>0.05 只能说明"没有证据" |
| `estat overid` | 过度识别约束是否成立（工具是否外生） | 全部工具外生、模型正确设定 | `ivregress 2sls`（工具数 > 内生变量数） | P>0.05 不拒绝 → 工具外生性可接受 |
| `test pre*`（手动事件研究） | 处理前各期交互项是否联合为零 | 所有事前系数 = 0 | `regress` / `reghdfe` / `xtreg` | P>0.05 → 平行趋势成立 |
| `bacondecomp`（需 `ssc install bacondecomp`） | 交错处理下 TWFE 系数的"好比较/坏比较"权重 | 无（分解，不做检验） | 无（独立命令） | 坏比较权重越大，TWFE 偏误越大，应换 `csdid` / `did_imputation` |
| `csdid` + `estat pretrend`（需 `ssc install csdid`） | Callaway–Sant'Anna 估计下处理前 ATT 是否联合为零 | 处理前各期 ATT(g,t) 全为 0 | `csdid` | 联合检验 P>0.05 → 平行趋势可接受 |
| `ivreg2` 报出的 KP rk Wald F（`e(widstat)`） | 稳健的弱工具变量检验 | 工具弱（识别不足） | `ivreg2 ..., robust` | 经验门槛 >10；Stock–Yogo 10% 最大偏误临界约 16.38 |
| `ivreg2` 报出的 Hansen J（`e(hansenj)`） | 过度识别 / 工具外生性（GMM，稳健） | 工具变量外生 | `ivreg2 ..., gmm2s robust` | P>0.05 不拒绝 → 工具外生性可接受 |
| `ivreg2` 报出的 Sargan（`e(sargan)`） | 过度识别（同方差下的经典检验） | 工具变量外生 | `ivreg2 ...`（未加 robust） | P>0.05 不拒绝；与 Hansen J 冲突时以 Hansen J 为准 |
| `pstest` | 匹配前后协变量组间均值差异是否消失 | 两组协变量均值无差异 | `psmatch2` | 匹配后 \|bias\|<10%、t 检验 P>0.1、%reduct 高 → 合格 |
| `tebalance summarize` | `teffects` 匹配/加权后协变量平衡（标准化差异、方差比） | 加权后两组协变量分布相同 | `teffects psmatch/ipw/ipwra/aipw` | 标准化差异趋近 0、方差比趋近 1 为合格 |
| `teffects overlap` | 倾向得分的共同支撑（重叠度） | 无（作图/统计） | `teffects` | 两组得分重叠越好；明显不重叠说明可比性差 |
| `rddensity`（需 `ssc install rddensity`） | 断点处驱使变量密度是否连续（McCrary 检验） | 密度在断点处连续（无操纵） | 无（独立命令） | P>0.05 不拒绝 → 无断点操纵嫌疑 |
| `rdbwselect` | 最优带宽（MSE / 覆盖率准则） | 无（选择带宽） | 无（独立命令） | 同时报 MSE 与 CER 带宽，并做多带宽敏感性 |
| `synth_runner` 的安慰剂推断 | 处理单元效应是否异于安慰剂分布 | 处理效应为 0 | `synth_runner` | 看 p 值与处理单元 RMSPE 比值的排名 |
| `permute` | 随机置换处理标记构造零分布，得经验 P 值 | 处理分配与结果无关（无效应） | 任意估计命令 | 经验 P<0.05 → 效应不太可能由随机分配产生 |
| `bootstrap` + `estat bootstrap` | 重抽样 SE 与 CI（normal/percentile/BC/BCa） | 无（推断工具） | 任意估计命令 | BC/BCa 区间是否含 0；与解析 SE 差异大说明分布偏斜 |
| `lassocoef` / `coefpath` / `lassoselect` | 高维协变量中选入哪些变量、系数路径与 λ | 无（变量选择结果） | `lasso linear` / `lasso logit` | 关注选入集合是否稳定，选完再用 `regress`/`ivregress` 重估 |

> 提示：`estat ptrends` / `granger` / `event` / `trendplots` 只在 `didregress`、`xtdidregress` **之后**可用；`estat firststage` / `endog` / `overid` 只在 `ivregress` 之后可用。前置命令用错，Stata 会报 "last estimates not found"。

---

## ❖ DID 准备：`diff` / 手动交互项 （双重差分，Difference-in-Differences）

- **功能**：比较处理组与对照组在政策前后变化之差。经典做法是 OLS 中加入 `treat×post` 交互项，两期两组时该交互项系数就是 DID 估计量（ATT）。
- **语法**：
  ```stata
  gen treat = (group==1)              // 处理组=1
  gen post  = (year>=2010)            // 政策后=1
  gen did   = treat * post            // 交互项
  regress y treat post did, vce(cluster id)

  ssc install diff                    // 一条命令版（World Bank）
  diff y, treated(treat) period(post)
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `treat` | 处理组虚拟变量（1=处理组，0=对照组） |
| `post` | 政策后虚拟变量（1=政策后） |
| `did` | 交互项 `treat*post`，系数即 ATT |
| `treated()` / `period()` | `diff` 中指定处理组变量与政策前后变量 |
| `covariates()` / `id()` | `diff` 中指定协变量 / 面板个体（用于聚类） |

- **输出结果**：`regress` 输出中 `did` 行 Coef. 即 ATT。`e()` 中：`e(b)`、`e(V)`、`e(N)`、`e(r2)`、`e(df_r)`、`e(N_clust)`（聚类时）。`diff` 直接打印 2×2 表、ATT、SE、t、P 与 95% CI（存名用 `ereturn list` 查）。
- **常用选项**：
  ```stata
  , vce(cluster id)     // 个体层面聚类（推荐）
  , vce(robust)         // 稳健标准误
  , absorb(id year)     // 不支持；多维固定效应请改用 reghdfe
  ```
- **配套检验命令**：
  - `estat ptrends`（`didregress` 之后）：官方平行趋势检验。
  - `bacondecomp`（需安装）：分解 TWFE 权重，判断交错处理下能否用本写法。
  - `permute`：随机重排 `treat` 做安慰剂，看真实 `_b[did]` 在零分布中的位置。
- **结果怎么读 · 常见坑**：
  - **平行趋势是前提不是结论**：没有事件研究图或 `estat ptrends`，`did` 系数不能解释为因果。
  - **处理时点交错时 TWFE 有偏**：估计量是各 2×2 的加权平均，权重可为负（"坏比较"），应改用 `csdid` / `did_imputation` / `eventstudyinteract`。
  - **聚类层级选对**：政策在个体层变动 cluster 到个体；在市/行业层变动则收敛到政策层。
  - **两个主效应别丢**：`treat`、`post` 必须进回归，否则 `did` 会吸收组别与时间的水平差异。
- **示例**：
  ```stata
  gen did = treat*post
  regress y treat post did, vce(cluster id)

  reghdfe y did x1 x2, absorb(id year) vce(cluster id)   // 双向固定效应等价写法
  ```

---

## ❖ 平行趋势检验：`estat ptrends` / 事件研究法 （DID 前提）

> **校订说明**：原文标题写作 `estat parallel`。`didregress` / `xtdidregress` 事后检验中并无 `estat parallel`，官方对应命令是 `estat ptrends`（线性趋势平行性）、`estat granger`、`estat event` 与 `estat trendplots`。下面按官方命令写，并保留原手动事件研究法。

- **功能**：DID 有效性要求**处理前两组均值平行**。可用官方命令做形式化检验，也可用事件研究图检验。
- **语法**：
  ```stata
  * 官方途径
  didregress (y) (treat), group(id) time(year) vce(cluster id)
  estat ptrends
  estat granger
  estat event
  estat trendplots

  * 手动事件研究法（任意版本可用）
  forvalues t = 2005/2009 {
      gen pre`t' = treat * (year==`t')
  }
  gen post_did = treat * (year>=2010)
  regress y pre2005-pre2009 post_did, vce(cluster id)
  test pre2005 pre2006 pre2007 pre2008 pre2009
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `pre\`t'` | 政策前各期 × 处理组虚拟变量，系数应接近 0 |
| `post_did` | 政策后 × 处理组交互项，系数即动态效应起点 |
| `group(id)` / `time(year)` | 处理组别/个体标识 与 时间变量 |
| `test pre*` | 对事前系数做联合检验 |

- **输出结果**：`estat ptrends` 打印处理前线性趋势是否相等的联合检验（F/χ²）与 P 值；`estat granger` 打印格兰杰检验 P 值；`estat event` 输出逐期系数表。手动回归的联合检验结果见 `r(F)`、`r(p)`、`r(df)`、`r(df_r)`。
- **常用选项**：
  ```stata
  test pre2005 pre2006 pre2007 pre2008 pre2009    // 显式列变量（推荐）
  coefplot, keep(pre*) vertical yline(0) drop(_cons)   // 事件研究图（需安装 coefplot）
  reghdfe y pre* post_did, absorb(id year) vce(cluster id)  // 双向固定效应版
  ```
- **配套检验命令**：
  - `estat granger`：从"预测"角度补一条证据，别只报一个联合 F。
  - `estat trendplots`：趋势图，答辩/审稿必备。
  - `bacondecomp`：处理时点交错时先看分解权重。
- **结果怎么读 · 常见坑**：
  - **联合检验不显著 ≠ 平行趋势成立**，只是"没有证据反对"；样本小时检验功效低，要同时给图和逐期系数。
  - **基准期要省略一期**（通常政策前一期），否则与 `treat` 主效应共线。
  - **事前系数显著不等于"政策无效"**，多半说明两组本来趋势不同，应换对照组或改用合成控制。
  - 交错处理时逐期 TWFE 系数同样有偏，应改用 `csdid` 的 `estat event` 或 `eventstudyinteract`。
- **示例**：
  ```stata
  regress y pre2005-pre2009 post_did, vce(cluster id)
  test pre2005 pre2006 pre2007 pre2008 pre2009

  xtset id year
  xtdidregress (y) (treat), group(id) time(year) vce(cluster id)
  estat ptrends
  ```

---

## ❖ 事件研究法 / 动态 DID （Event Study）

- **功能**：估计政策对每一期（含政策前）的动态影响，检验平行趋势并观察动态效应（立刻出现、滞后、还是逐年衰减）。
- **语法**：
  ```stata
  reghdfe y ib2010.treat#i.year, absorb(id year) vce(cluster id)
  ```
  （以 2010 年为基准）或更稳健的新方法：
  ```stata
  ssc install did_imputation
  did_imputation y first_treat year, unit(id) time(year) horizons(0/4)
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `ib2010.treat#i.year` | 处理组 × 年份交互，`ib2010` 指定 2010 为省略基准期 |
| `absorb(id year)` | 吸收个体与年份固定效应 |
| `first_treat` | 首次受处理的年份（从未处理记 0 或缺失） |
| `horizons(0/4)` | 报告相对期 0–4 的 ATT |

- **输出结果**：`reghdfe` 输出中各期交互项系数即相对效应。`e()` 中：`e(b)`、`e(V)`、`e(N)`、`e(r2)`、`e(r2_within)`、`e(df_a)`、`e(N_clust)`。`did_imputation` 输出逐期 ATT 表并存 `e(b)`、`e(V)`。
- **常用选项**：
  ```stata
  , absorb(id year) vce(cluster id)    // 个体+年份 FE，个体聚类
  reghdfe y ib(-1).rel_time, absorb(id year) vce(cluster id)   // 用相对期号，基准 -1
  coefplot, keep(*rel_time) vertical yline(0)                  // 事件研究图
  ```
- **配套检验命令**：
  - `test`：联合检验事前各期系数。
  - `did_imputation ... , pretrends(#)`：Borusyak 等的处理前趋势检验。
  - `csdid` + `estat event`：交错处理下的稳健事件研究。
- **结果怎么读 · 常见坑**：
  - **基准期选择改变所有系数的解释**，必须在表注写明基准期。
  - **不要"挑"基准期**让事前系数变漂亮（p-hacking）。
  - `ib2010.treat#i.year` 与 `i.treat##i.year` 不同：前者只保留处理组×年份，更省参数。
  - 交错处理用普通 TWFE 事件研究，事后系数可能为负、权重可为负，务必用 `csdid`/`did_imputation`/`eventstudyinteract` 交叉验证。
- **示例**：
  ```stata
  reghdfe y ib2010.treat#i.year, absorb(id year) vce(cluster id)

  did_imputation y first_treat year, unit(id) time(year) horizons(0/4) pretrends(4)
  ```

---

## ❖ `xtdidregress` / `didregress` （官方 DID 命令）

- **功能**：Stata 15+ 的内置 DID 命令，语法规范，可加协变量与聚类标准误，并自带平行趋势、格兰杰、事件研究、趋势图等事后检验。`didregress` 用于横截面/重复截面，`xtdidregress` 用于面板（需先 `xtset`）。
- **语法**：
  ```stata
  didregress (depvar) (treatvar), group(groupvar) time(timevar) [options]
  xtdidregress (depvar) (treatvar), group(groupvar) time(timevar) [options]
  ```
  > **校订说明**：结果变量与处理变量必须各自放在**括号**里，协变量写进第一个括号。原文的 `didregress y x1 x2, group(...) time(...)` 会直接报语法错误。
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `(depvar [covariates])` | 结果变量及协变量 |
| `(treatvar)` | 处理状态变量（0/1） |
| `group(groupvar)` | 个体标识或处理组标识（`xtdidregress` 中等于面板 id） |
| `time(timevar)` | 时间变量，须为数值型 |
| `vce(cluster clustvar)` | 聚类稳健标准误 |

- **输出结果**：输出 ATT 及标准误、z/t、P、置信区间。`e()` 中：`e(b)`、`e(V)`、`e(N)`、`e(N_clust)`、`e(treated)`、`e(time)`、`e(cmd)`。事后检验分别由 `estat ptrends`、`estat granger`、`estat event`、`estat trendplots` 输出。
- **常用选项**：
  ```stata
  , vce(cluster id)     // 个体层面聚类（面板几乎必加）
  , vce(robust)         // 稳健标准误
  , atet                // 汇报 ATT（默认即 ATT 口径）
  ```
- **配套检验命令**：
  - `estat ptrends`：处理前线性趋势平行性（最重要）。
  - `estat granger`：处理前结果是否已对处理状态有反应。
  - `estat event`：逐期效应表，可直接画事件研究图。
  - `estat trendplots`：处理前后均值趋势图。
- **结果怎么读 · 常见坑**：
  - **先 `xtset` 再 `xtdidregress`**，且 `group()` 要与面板 id 一致，否则结果错位。
  - 交错且效应异质时，它仍属加权 TWFE 家族，建议用 `csdid` 复核。
  - `time()` 必须是数值；字符串日期先 `encode`/`destring`。
  - 每个个体只有一期数据（纯重复截面）时必须用 `didregress`。
- **示例**：
  ```stata
  xtset id year
  xtdidregress (y) (treat), group(id) time(year) vce(cluster id)
  estat ptrends
  estat event

  didregress (y x1 x2) (treat), group(id) time(year) vce(cluster id)   // 带协变量
  ```

---

## ❖ `bacondecomp` （DID 分解 / Bacon–Goodman 检验）

- **功能**：多期 DID 中处理时间不一致时，检验系数中"坏比较"的权重。Goodman-Bacon (2021) 证明 TWFE 的 DID 系数是若干 2×2 DID 的加权平均，其中"已处理组作对照"会带来偏误，本命令把权重拆开给你看。
- **语法**：
  ```stata
  ssc install bacondecomp
  bacondecomp depvar treatvar [covariates], [ddetail]
  ```
  > **校订说明**：原文的 `ddtreat()`、`ddpost()` 不是该命令选项。处理变量直接作为第二个位置参数，用 `ddetail` 打印分解明细。
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` | 结果变量 |
| `treatvar` | 处理状态变量（0/1，吸收型：处理不退出） |
| `covariates` | 可选协变量 |
| `ddetail` | 输出完整 2×2 分解明细（各比较类型的权重与系数） |

- **输出结果**：打印按比较类型汇总的表（Earlier T vs Later C、Later T vs Earlier C、T vs Never Treated）及权重；图形版给出权重-系数散点。`e()` 中：`e(b)`、`e(V)`、`e(N)`；明细矩阵用 `ereturn list` 查存名。
- **常用选项**：
  ```stata
  , ddetail            // 打印分解明细
  , ddetail nograph    // 不出图，只要数字
  ```
- **配套检验命令**：
  - `csdid`：坏比较权重大时改用 Callaway–Sant'Anna 估计量重估。
  - `did_imputation`：插补法路线，交叉验证。
  - `estat ptrends`（配合 `didregress`）：分解只解决权重问题，趋势仍须单独检验。
- **结果怎么读 · 常见坑**：
  - **坏比较权重小 ≠ 设计没问题**，平行趋势、预期效应仍要单独处理。
  - 要求**平衡面板**且处理为吸收型；不平衡时要先补齐。
  - 必须有"从未处理"对照组，否则分解不完整、估计更不可靠。
  - 它只是诊断，**不产生可引用的因果估计**；论文正报的是 `csdid` 等。
- **示例**：
  ```stata
  bacondecomp y treat, ddetail
  ```

---

## ❖ DID 安慰剂检验：`diff` / `permute`

> **校订说明**：原文标题写作 `estat summ`，Stata 并无该事后检验命令，DID 安慰剂实际靠 `diff`（需安装）与 `permute` 实现。

- **功能**：用虚构处理时间或虚构处理组重复 DID，看是否出现虚假显著：①时间安慰剂（把政策提前，效应应消失）；②随机化安慰剂（随机抽"假处理组"重复估计，看真实系数的位置）。
- **语法**：
  ```stata
  * ① 虚构处理时间
  diff y, treated(treat) period(fake_post)

  * ② 随机化推断（推荐）
  permute did_beta=_b[did], reps(500) rseed(12345): regress y treat post did
  ```
  （`permute` 详见本章"随机化推断"一节）
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `fake_post` | 虚构的政策时点（真实政策年提前若干期） |
| `did_beta=_b[did]` | 每次置换收集的统计量（DID 系数） |
| `reps(#)` | 置换次数，正文一般 500–1000 |
| `rseed(#)` | 随机种子，保证可复现 |

- **输出结果**：`permute` 打印观测统计量、置换分布均值/标准差与经验 P 值（左/右/双尾）；`diff` 打印 ATT 与 SE。用 `saving()` 可存下每次系数画核密度图。
- **常用选项**：
  ```stata
  , reps(500) nodots rseed(12345)              // 常规设置
  , reps(500) saving(placebo, replace)         // 保存分布以便作图
  ```
- **配套检验命令**：
  - `kdensity` / `histogram`：画 500 次安慰剂系数分布并标出真实值（最直观的安慰剂图）。
  - `summarize`：汇总零分布均值与标准差。
  - `count if`：统计安慰剂系数超过真实值的次数，手算经验 P。
- **结果怎么读 · 常见坑**：
  - **安慰剂不是平行趋势的替代品**，两者回答不同问题，都要报。
  - 提前太多会撞上真实政策期，提前太少没功效；一般提前 2–4 期。
  - 面板数据直接整体重排观测会破坏组内相关，应用 `strata()` 或只重排处理组标签。
  - 经验 P 值下限约 1/(reps+1)，别报 "P=0.000"。
- **示例**：
  ```stata
  permute betadid=_b[did], reps(500) rseed(12345): regress y treat post did
  ```

---

## ❖ `teffects psmatch` （倾向得分匹配 PSM）

- **功能**：用倾向得分匹配处理组与对照组，估计平均处理效应(ATE/ATT)。先用 logit/probit 估得分，再做近邻匹配，标准误用 Abadie–Imbens 修正。
- **语法**：
  ```stata
  teffects psmatch (ovar) (tvar tvars) [if] [in] [, options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `(ovar)` | 结果变量 |
| `(tvar tvars)` | 处理变量 + 倾向得分方程的解释变量 |
| `atet` | 汇报 ATT（默认报 ATE） |
| `nn(#)` / `caliper(#)` | 近邻个数 / 卡尺 |
| `common` | 只保留共同支撑区域 |

- **输出结果**：输出 ATE 或 ATET、AI 修正稳健标准误、z、P、置信区间。`e()` 中：`e(b)`、`e(V)`、`e(N)`、`e(N_clust)`、`e(cmd)`、`e(stat)`。平衡性用 `tebalance` 单独检查。
- **常用选项**：
  ```stata
  , atet            // 报告 ATT（论文常用）
  , nn(3)           // 1:3 匹配
  , caliper(0.05)   // 卡尺，避免"远距离匹配"
  , common          // 只保留共同支撑区域
  , nolog           // 不显示得分估计迭代
  ```
- **配套检验命令**：
  - `tebalance summarize`：匹配后标准化差异与方差比。
  - `teffects overlap`：倾向得分重叠图，判断共同支撑是否足够。
  - `tebalance density`：匹配后得分密度对比。
- **结果怎么读 · 常见坑**：
  - **共同支撑不足时 ATE 无意义**：先看 `teffects overlap`，必要时改报 ATET 或限定样本。
  - **平衡性比显著性更重要**：匹配后仍有 \|标准化差异\|>10%，说明得分方程设错。
  - **得分方程要"薄"**：只放同时影响处理与结果的混杂因素，塞无关变量会放大不平衡。
  - 匹配后不要用普通 `regress` 重估来当标准误，`teffects` 已内置修正。
- **示例**：
  ```stata
  teffects psmatch (wage) (treat edu exp age), atet nn(3)
  tebalance summarize
  ```

---

## ❖ `psmatch2` （经典 PSM 命令，可看平衡性）

- **功能**：经典匹配流程——先估倾向得分，再匹配、检验平衡性。会生成 `_pscore`、`_treated`、`_weight`、`_support` 等变量，方便手工检查。
- **语法**（安装 `ssc install psmatch2`）：
  ```stata
  ssc install psmatch2
  psmatch2 treatvar [varlist], outcome(y) neighbor(1) common
  ```
  > **校订说明**：匹配个数选项是 `neighbor()`，原文示例中的 `nearest(1)` 不存在。
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `treatvar` | 处理变量（0/1），写在最前面 |
| `varlist` | 进入倾向得分方程的协变量 |
| `outcome(y)` | 结果变量，用于直接报告 ATT |
| `neighbor(#)` | 近邻匹配个数（默认 1） |
| `caliper(#)` | 卡尺；`common` 只在共同支撑内匹配 |

- **输出结果**：打印处理组/对照组观测数、共同支撑内观测数、ATT/ATU/ATE 及标准误与 t 值。`r()` 中可用 `r(att)`、`r(seatt)`、`r(ate)`、`r(seate)`、`r(atc)`、`r(n_treated)`、`r(n_controls)`（不同版本略有差异，用 `return list` 确认）。
- **常用选项**：
  ```stata
  , neighbor(1)      // 1:1 最近邻匹配
  , neighbor(5)      // 1:5 匹配
  , caliper(0.05)    // 卡尺控制
  , common           // 只保留共同支撑区域
  , kernel           // 核匹配（与近邻二选一）
  , logit            // 用 logit 估得分（默认 probit）
  , noreplacement    // 无放回匹配
  ```
- **配套检验命令**：
  - `pstest`：匹配前后协变量平衡性（最常用）。
  - `psgraph`：两组倾向得分分布密度图，直观看共同支撑。
  - `tab _support`：检查共同支撑丢掉了多少观测。
- **结果怎么读 · 常见坑**：
  - **`common` 会删样本**，且不是随机缺失，样本量变化要交代。
  - 无放回匹配依赖观测排序，先 `set seed`/`sort` 固定顺序。
  - `psmatch2` 的 SE 未考虑得分估计的不确定性，**比 `teffects` 偏小**；稳健做法是 `bootstrap` 或直接用 `teffects`。
  - 卡尺太宽等于没卡尺，太窄大量丢样本；常用 0.01–0.05 并报多组稳健性。
- **示例**：
  ```stata
  psmatch2 treat edu age, outcome(wage) neighbor(1) caliper(0.05) common
  pstest edu age, both
  ```

---

## ❖ `pstest` （倾向得分平衡性检验）

- **功能**：检验匹配后处理组与对照组协变量是否平衡（差异不显著即合格）。输出标准化偏差（bias）、偏差缩减比例（%reduct）、t 检验与联合检验。
- **语法**：
  ```stata
  psmatch2 treat edu age, outcome(wage)
  pstest edu age, both
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `varlist` | 要检查的协变量（应与得分方程一致） |
| `both` | 同时报告匹配前与匹配后 |
| `treated()` | 处理变量（一般自动识别） |

- **输出结果**：逐变量给出 Mean Treated/Control、%bias、%reduct、t 与 P 值，末行为联合检验（Ps R2、LR chi2、P）。`r()` 中可看 `r(bias)` 等（`return list` 确认）。
- **常用选项**：
  ```stata
  pstest edu age, both            // 匹配前后都报告
  pstest edu age, both summarize  // 简短汇总
  ```
- **配套检验命令**：
  - `psgraph`：得分分布图，与平衡性表互补。
  - `tebalance summarize`：改用 `teffects` 后的对应检查。
  - `sum _pscore if _support==1`：确认共同支撑内得分范围。
- **结果怎么读 · 常见坑**：
  - **只看 Matched 那一列**，匹配前不平衡是常态。
  - 判据：\|bias\|<10%（严格 <5%）、t 检验 P>0.1、联合检验 P>0.05。
  - **平衡只说明"可观测协变量均值接近"**，不解决遗漏变量。
  - 某变量怎么调都不平衡，考虑加它的高次项/交互项进得分方程。
- **示例**：
  ```stata
  pstest edu exp age, both
  ```

---

## ❖ `teffects ipw` / `teffects ipwra` （逆概率加权 IPW）

- **功能**：以倾向得分倒数为权重加权估计处理效应，矫正选择偏差。`ipwra` 是"加权+回归"的双重稳健版：倾向得分模型或结果方程有一个设对，估计就一致。
- **语法**：
  ```stata
  teffects ipw (ovar) (tvar tvars) [, atet]
  teffects ipwra (ovar ovars) (tvar tvars) [, atet]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `(ovar)` / `(ovar ovars)` | 结果变量；`ipwra` 中再加结果方程协变量 |
| `(tvar tvars)` | 处理变量 + 得分方程变量 |
| `atet` | 报告 ATT（默认 ATE） |
| `osample()` | 标记样本外观测 |

- **输出结果**：加权后 ATE/ATET 及稳健标准误、z、P、CI。`e()` 中：`e(b)`、`e(V)`、`e(N)`、`e(cmd)`、`e(stat)`。
- **常用选项**：
  ```stata
  , atet              // 报 ATT
  , nolog             // 不显示迭代过程
  , vce(robust)       // 稳健标准误
  , osample(newvar)   // 生成样本外标记（得分接近 0/1）
  ```
- **配套检验命令**：
  - `tebalance summarize`：加权后协变量平衡（IPW 核心诊断）。
  - `teffects overlap`：重叠不足是极端权重的根源。
  - `teffects aipw`：再跑 AIPW 交叉验证。
- **结果怎么读 · 常见坑**：
  - **得分接近 0 或 1 时权重爆炸**，几个观测就能左右结果；查 `osample()` 与方差比。
  - IPW 只平衡"进了方程的变量"，未进方程的混杂照样偏。
  - `ipw` 与 `ipwra` 结论差异大，说明至少一个模型设错。
  - 权重是 1/p 或 1/(1−p)，要说明是否做了截断（trimming）。
- **示例**：
  ```stata
  teffects ipwra (wage edu age) (treat edu age), atet
  tebalance summarize
  ```

---

## ❖ `teffects` 综合：`teffects aipw` / `nnmatch`（双重稳健）

- **功能**：AIPW（增强型 IPW）结合回归与加权，双重稳健；`nnmatch` 则基于协变量距离直接匹配（Abadie–Imbens），不经过倾向得分。
- **语法**：
  ```stata
  teffects aipw (ovar ovars) (tvar tvars) [, atet]
  teffects nnmatch (ovar ovars) (tvar) [, atet nn(#) metric(maha)]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `(ovar ovars)` | 结果变量 + 结果方程协变量 |
| `(tvar tvars)` | 处理变量 + 得分方程变量 |
| `nn(#)` | 近邻个数 |
| `metric(maha)` | 马氏距离（`euclidean` 为欧氏） |

- **输出结果**：ATE/ATET 及稳健标准误。`e()` 中：`e(b)`、`e(V)`、`e(N)`、`e(stat)`。
- **常用选项**：
  ```stata
  , atet              // 报 ATT
  , nn(4)             // nnmatch 近邻数
  , metric(maha)      // 马氏距离（推荐）
  , biasadj           // 偏差调整（nnmatch）
  ```
- **配套检验命令**：
  - `tebalance summarize`：AIPW / nnmatch 后平衡性。
  - `teffects overlap`：涉及得分的估计量才需要。
  - 与 `teffects psmatch`、`ipwra` 并列汇报做敏感性对比。
- **结果怎么读 · 常见坑**：
  - **双重稳健是渐近性质**，小样本、重叠差时照样偏。
  - `nnmatch` 高维协变量有"维度诅咒"，协变量超过 5–6 个要谨慎。
  - 四个 `teffects` 估计量给出四个数很正常，**别只报最显著的那个**。
- **示例**：
  ```stata
  teffects aipw (wage edu exp age) (treat edu exp), atet
  teffects nnmatch (wage edu exp age) (treat), atet nn(4) metric(maha)
  ```

---

## ❖ `ivregress` （工具变量两阶段最小二乘 2SLS）

- **功能**：解释变量内生时用工具变量做 2SLS 估计。外生工具要满足**相关性**（与内生变量相关）与**排他性**（只通过内生变量影响结果）。
- **语法**：
  ```stata
  ivregress 2sls depvar [varlist1] (varlist2 = varlist_iv) [if] [in] [weight] [, options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` | 结果变量 |
| `varlist1` | 外生解释变量 |
| `(varlist2 = varlist_iv)` | 内生变量 = 它的工具变量 |
| `varlist_iv` | 排除性工具变量，个数不少于内生变量 |

- **输出结果**：系数、稳健标准误、z、P、CI，以及 `Number of obs`、`Wald chi2`、`R-squared`。`e()` 中：`e(b)`、`e(V)`、`e(N)`、`e(r2)`、`e(chi2)`、`e(df_m)`、`e(rank)`、`e(rmse)`。
- **常用选项**：
  ```stata
  , vce(robust)         // 异方差稳健
  , vce(cluster id)     // 聚类稳健
  , first               // 报告第一阶段（论文建议加）
  ```
- **配套检验命令**：
  - `estat firststage`：第一阶段 F 与偏 R²，弱工具诊断。
  - `estat endog`：DWH 内生性检验，确认是否真需要 IV。
  - `estat overid`：过度识别检验（工具数 > 内生变量数时）。
- **结果怎么读 · 常见坑**：
  - **弱工具是头号杀手**：第一阶段 F<10 时 2SLS 有严重偏误、t 检验失效，须做弱工具稳健推断。
  - **过度识别检验通过 ≠ 工具外生**，排除性约束本质上不可检验。
  - 恰好识别时 `estat overid` 无法计算，属正常。
  - 报告要写清哪个是内生变量、哪些是工具、排他性理由。
- **示例**：
  ```stata
  ivregress 2sls wage educ (exper = nearcollege), vce(robust) first
  estat firststage
  estat endog
  ```

---

## ❖ 2SLS 后的诊断：`estat firststage` / `estat endog` / `estat overid`

- **功能**：检验工具变量质量与模型设定。三条命令分别回答：工具够不够强？变量真的内生吗？工具有没有外生？
- **语法**：
  ```stata
  ivregress 2sls y x (endog = z1 z2), vce(robust)
  estat firststage        // 第一阶段 F 是否 > 10（弱工具变量诊断）
  estat endog             // Durbin–Wu–Hausman 内生性检验
  estat overid            // 过度识别检验（Sargan/Hansen）
  ```
  > **校订说明**：过度识别检验是 `estat overid`，原文示例中的 `estat overidentify`、`estat enogd` 均为笔误（Stata 不认）。
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `estat firststage` | 各内生变量的第一阶段：偏 R²、F、最小特征值 |
| `estat endog` | DWH 检验：H0 为内生变量其实外生 |
| `estat overid` | H0 为工具外生；需工具数 > 内生变量数 |

- **输出结果**：`estat firststage` 给 `Shea's partial R2`、`F(.,.)`、`Prob > F` 与最小特征值统计量；`estat endog` 给 Durbin / Wu–Hausman 统计量；`estat overid` 给 Sargan 与 Basmann 统计量。统计量存于 `r()`/`e()`，存名随版本不同，引用前先 `return list` 确认。
- **常用选项**：
  ```stata
  estat firststage, all    // 同时显示最小特征值与 Stock-Yogo 临界值
  estat endog, robust      // 稳健版（与 vce(robust) 配套）
  estat overid             // 过度识别（Sargan/Basmann）
  ```
- **配套检验命令**：
  - `ivreg2 ..., robust` 的 KP rk Wald F（`e(widstat)`）：异方差稳健的弱工具检验，比 `estat firststage` 的 F 可靠。
  - `ivreg2` 的 Hansen J（`e(hansenj)`）：稳健过度识别检验。
  - `test` 检验第一阶段工具系数，确认相关性方向与量级。
- **结果怎么读 · 常见坑**：
  - **F>10 只是经验法则**，多内生变量/多弱工具要用 Stock–Yogo 临界值（`estat firststage, all`）。
  - `estat endog` 不显著**不能证明外生**，只能说没有证据；理论上内生就该用 IV。
  - 同方差下 Sargan 更有效，异方差下必须看 Hansen J；冲突时以 Hansen J 为准。
  - 恰好识别时无 `estat overid` 输出属正常。
- **示例**：
  ```stata
  ivregress 2sls wage educ (exper = nearcollege momeduc), vce(robust) first
  estat firststage, all
  estat endog
  estat overid
  ```

---

## ❖ `ivreg2` / `ivreg2h` （增强版 IV，含多种检验）

- **功能**：`ivreg2` 提供更多诊断（KP F、Hansen 过度识别、弱工具稳健推断），是实证论文 IV 部分的事实标准；`ivreg2h` 用于异方差下的工具变量估计（Hausman–Newey）。
- **语法**：
  ```stata
  ssc install ivreg2
  ivreg2 depvar [varlist1] (varlist2 = varlist_iv) [if] [in] [weight] [, options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `gmm2s` | 两阶段 GMM（异方差下比 2SLS 有效） |
| `robust` / `cluster(id)` | 稳健 / 聚类稳健，同时给出 KP rk Wald F |
| `partial(varlist)` | 报告指定外生变量的偏 R² |
| `first` / `ffirst` | 报告第一阶段（`ffirst` 更详细） |
| `small` | 报告小样本 F 统计量 |

- **输出结果**：底部给出 `Underidentification test`（LM 统计量）、`Weak identification test`（Cragg–Donald / KP rk Wald F，附 Stock–Yogo 临界值）、`Sargan statistic`、`Hansen J statistic`。`e()` 中可取：`e(widstat)`（KP rk Wald F）、`e(hansenj)`、`e(hansenjdf)`、`e(sargan)`、`e(sargandf)`、`e(arf)`、`e(arfchi2)`、`e(idstat)`、`e(b)`、`e(V)`、`e(N)`。
- **常用选项**：
  ```stata
  , robust              // 稳健 SE + KP rk Wald F
  , cluster(id)         // 聚类稳健
  , gmm2s               // 两阶段 GMM
  , first               // 打印第一阶段
  , partial(educ)       // educ 的偏 R2
  , savefirst savefprefix(fs_)   // 保存第一阶段结果以便复现
  ```
- **配套检验命令**：
  - `estat firststage`（`ivreg2` 后不一定可用，优先看输出的 KP F）。
  - `weakiv`（需安装）：弱工具稳健置信区间（Anderson–Rubin）。
  - `ivreghdfe`：带高维固定效应的 IV，语法与 `ivreg2` 兼容。
- **结果怎么读 · 常见坑**：
  - **看 KP rk Wald F，不看 Cragg–Donald F**（后者假定同方差）。
  - Stock–Yogo 10% 最大偏误临界值对单内生变量约 16.38；F 在 10–16 属"灰色地带"。
  - Hansen J 的 P<0.05 是**拒绝外生性**，不是"工具有效"。
  - `partial()` 里只能放外生变量。
- **示例**：
  ```stata
  ivreg2 wage educ (exper = nearcollege momeduc), robust first
  display e(widstat)      // KP rk Wald F
  display e(hansenj)      // Hansen J
  ```

---

## ❖ `ivreg` （回归形式的基础 IV）

- **功能**：用 `ivreg` 也可以做 2SLS，与 `ivregress` 输入格式不同但结果相近。它是早期命令，语法更"回归化"，适合快速试算；正式论文建议 `ivregress` 或 `ivreg2`。
- **语法**：
  ```stata
  ivreg depvar [varlist1] (varlist2 = varlist_iv) [if] [in] [weight] [, options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` | 结果变量 |
| `varlist1` | 外生解释变量（可省略） |
| `(varlist2 = varlist_iv)` | 内生变量 = 工具变量 |
| `robust` | 稳健标准误 |

- **输出结果**：与 `ivregress` 类似的系数表；`e()` 中 `e(b)`、`e(V)`、`e(N)`、`e(r2)`。注意 `ivreg` 不支持 `estat firststage` 等事后检验，诊断请改用 `ivregress` / `ivreg2`。
- **常用选项**：
  ```stata
  , robust        // 稳健标准误
  , noconstant    // 无常数项
  ```
- **配套检验命令**：
  - 用 `ivregress 2sls` 重跑同一模型后 `estat firststage`。
  - `ivreg2`：一并给出弱工具与过度识别诊断。
- **结果怎么读 · 常见坑**：
  - `ivreg` 与 `ivregress 2sls` 点估计相同，**默认标准误算法可能不同**，比较时加同一个 `robust`。
  - 连字符简写（如 `educ-exper`）容易写错范围，建议显式列变量。
  - 新代码不要再用 `ivreg`。
- **示例**：
  ```stata
  ivreg wage educ exp (exper = nearcollege), robust
  ```

---

## ❖ `reghdfe` （高维固定效应回归）

- **功能**：吸收多个固定效应（如行业×年份），速度极快，是实证论文标配，也是 DID/事件研究的主力（配合 `absorb(id year)`）。
- **语法**：
  ```stata
  ssc install reghdfe
  reghdfe depvar [indepvars] [if] [in] [weight], absorb(absvars) [options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` / `indepvars` | 结果变量 / 解释变量（含 DID 交互项） |
| `absorb(varlist)` | 要吸收的固定效应，可多个 |
| `vce(cluster clustvar)` | 聚类标准误（新版推荐写法） |

- **输出结果**：系数表 + `Absorbed degrees of freedom` 段。`e()` 中：`e(b)`、`e(V)`、`e(N)`、`e(N_clust)`、`e(r2)`、`e(r2_a)`、`e(r2_within)`、`e(df_a)`、`e(df_m)`、`e(F)`、`e(rmse)`。
- **常用选项**：
  ```stata
  , absorb(firm year)       // 多个固定效应
  , vce(cluster firm)       // 聚类标准误
  , absorb(firm#year)       // 交互固定效应（企业×年份）
  , keepsingletons          // 保留只有一期的观测
  , residuals(resid)        // 生成残差变量
  , savefe                  // 保存固定效应估计值
  ```
- **配套检验命令**：
  - `estfe`：被吸收固定效应的联合显著性，判断是否保留某组 FE。
  - `ivreghdfe`（需安装）：带高维 FE 的 IV。
  - `test` / `testparm`：对事件研究事前系数做联合检验。
- **结果怎么读 · 常见坑**：
  - **`absorb()` 里不能放连续变量**，会生成海量虚拟变量。
  - 聚类层级应高于或等于固定效应层级，否则标准误偏小。
  - 报告 `e(r2_within)` 而非总 R²，审稿人更关心组内解释力。
  - 单维 FE 下与 `xtreg, fe` 结果近似，但自由度调整略异，数字不会分毫不差。
- **示例**：
  ```stata
  reghdfe y treat x, absorb(industry year) vce(cluster firm)
  reghdfe y did x1 x2, absorb(id year) vce(cluster id)
  ```

---

## ❖ `xtivreg` （面板 IV）——见面板部分

- **功能**：面板数据的工具变量估计，可同时控制个体固定效应（`fe`）或随机效应（`re`），是"内生性 + 面板"的标准解法。
- **语法**：
  ```stata
  xtivreg depvar [varlist1] (varlist2 = varlist_iv) [, fe|re|fd options]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `fe` / `re` / `fd` | 固定效应 / 随机效应 / 一阶差分 IV 估计 |
| `varlist1` | 外生解释变量 |
| `(varlist2 = varlist_iv)` | 内生变量 = 工具变量 |

- **输出结果**：系数表；`fe` 版报告组内 R²。`e()` 中：`e(b)`、`e(V)`、`e(N)`、`e(N_g)`、`e(r2_w)`、`e(sigma_u)`、`e(sigma_e)`。
- **常用选项**：
  ```stata
  , fe              // 固定效应 IV（最常用）
  , vce(robust)     // 稳健标准误
  , vce(cluster id) // 聚类稳健（实践几乎必加）
  ```
- **配套检验命令**：
  - `xtoverid`（需安装）：面板 IV 的过度识别检验，也可做稳健 Hausman 检验。
  - `xtivreg2`（需安装）：带弱工具诊断的面板 IV。
  - `hausman`：`fe` 与 `re` 版本之间的选择。
- **结果怎么读 · 常见坑**：
  - **`fe` 会消掉所有不随时间变化的变量**，包括不随时间变化的工具。
  - 面板 IV 的弱工具比横截面更严重（组内变异小），务必查第一阶段强度。
  - `xtivreg` 默认标准误未聚类，几乎总要加 `vce(cluster id)`。
- **示例**：
  ```stata
  xtset id year
  xtivreg y x1 (x2 = z), fe vce(cluster id)
  ```

---

## ❖ `rdrobust` / `rd` （断点回归 RDD）

- **功能**：在某个确定阈值（断点）两侧比较结果，估计局部处理效应(LATE)。`rdrobust` 实现 Calonico–Cattaneo–Titiunik 的稳健偏差修正与最优带宽，是目前的标准命令。
- **语法**：
  ```stata
  ssc install rdrobust
  rdrobust depvar runvar [if] [in] [, c(#) p(#) q(#) kernel() bwselect() vce() cluster() covs() level(#)]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` / `runvar` | 结果变量 / 驱使变量(running var) |
| `c(#)` | 断点位置（默认 0） |
| `p(#)` / `q(#)` | 局部多项式阶数（默认 1）/ 偏差修正阶数（默认 p+1） |
| `bwselect()` | 带宽选择：`mserd`、`msetwo`、`cerrd`、`certwo` |
| `vce()` | 标准误类型：`hc0`–`hc3`、`nn` |

- **输出结果**：Conventional / Bias-corrected / Robust 三套估计，各带系数、SE、z、P、CI；下方给带宽 `BW est. (h)` 与两侧有效观测数。`e()` 中：`e(tau_cl)`、`e(tau_bc)`、`e(se_tau_cl)`、`e(se_tau_bc)`、`e(ci_l_rb)`、`e(ci_r_rb)`、`e(h_l)`、`e(h_r)`、`e(b_l)`、`e(b_r)`、`e(N_h_l)`、`e(N_h_r)`。
- **常用选项**：
  ```stata
  , c(50)               // 断点在 50
  , p(1)                // 局部线性
  , kernel(triangular)  // 核函数（默认 triangular）
  , bwselect(mserd)     // 两侧统一 MSE 最优带宽
  , bwselect(msetwo)    // 两侧各自最优带宽
  , cluster(id)         // 聚类（政策在县/市层面时）
  , covs(x1 x2)         // 加连续协变量（断点前确定）
  ```
- **配套检验命令**：
  - `rdbwselect`：单独看最优带宽并做多带宽敏感性。
  - `rddensity`（需安装）：McCrary 型密度检验，排除断点操纵。
  - `rdplot`：断点两侧拟合图。
  - 把协变量当结果跑 `rdrobust`：断点两侧协变量应连续（系数不显著）。
- **结果怎么读 · 常见坑**：
  - **报 Robust 那一列**，不要报 Conventional（后者 SE 偏小）。
  - **结果对带宽敏感**：附录给 2–3 个带宽，结论方向不能翻。
  - **驱使变量不能有操纵**：看 `rddensity`，并检查断点附近有无堆积。
  - 两侧有效观测各 <20 时任何估计都不可靠。
- **示例**：
  ```stata
  rdrobust y runningvar, c(50) p(1) bwselect(mserd)
  rdbwselect y runningvar, c(50)
  ```

---

## ❖ `rdplot` / `rdbwselect` （RDD 作图与带宽选择）

- **功能**：`rdplot` 绘制断点两侧拟合（论文里那张"断点图"）；`rdbwselect` 选择最优带宽，决定估计窗口。
- **语法**：
  ```stata
  rdplot depvar runvar [if] [in] [, c(#) p(#) nbins(#) binselect() kernel()]
  rdbwselect depvar runvar [, c(#) p(#) bwselect() kernel() vce() cluster()]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `c(#)` / `p(#)` | 断点位置 / 拟合多项式阶数 |
| `nbins(#)` | 两侧分箱数（可写 `# #` 分别指定） |
| `binselect()` | 分箱方式：`esmv`、`espr`、`qs`、`qsmv` |
| `bwselect()` | 带宽准则：`mserd`、`msetwo`、`cerrd`、`certwo` |

- **输出结果**：`rdplot` 出图并打印分箱与阶数；`rdbwselect` 打印各准则下的 `h`（及偏差带宽 `b`）。`e()` 中：`e(h_mserd)`、`e(h_msetwo)`、`e(h_cerrd)`、`e(h_certwo)`、`e(b_mserd)` 等。
- **常用选项**：
  ```stata
  rdplot y x, c(0) p(1) nbins(20 20)                // 两侧各 20 个箱
  rdplot y x, c(0) binselect(esmv) kernel(uniform)  // 分箱方式与核
  rdbwselect y x, c(0) bwselect(mserd)              // MSE 最优带宽
  rdbwselect y x, c(0) bwselect(cerrd)              // 覆盖率最优（更宽）
  ```
- **配套检验命令**：
  - `rdrobust y x, h(#)`：手动代入带宽做敏感性对比。
  - `rddensity`：密度检验，与断点图一起看。
  - `binscatter`：另一种分箱展示，可互相印证。
- **结果怎么读 · 常见坑**：
  - **图好看不代表识别有效**，断点图不能替代密度检验与协变量平衡检验。
  - 分箱太少掩盖非线性，太多噪声大；`nbins` 建议按默认 `esmv` 规则。
  - `cerrd` 通常比 `mserd` 宽：覆盖率好但偏误大，两个都报最稳。
  - 断点不在 0 时务必显式写 `c()`，否则图画错位置。
- **示例**：
  ```stata
  rdplot score outcome, c(50)
  rdbwselect score outcome, c(50) bwselect(mserd)
  ```

---

## ❖ `synth` （合成控制法 SCM）

- **功能**：为处理单元构建一个虚拟"合成对照"，比较政策效果（适用于单个处理单元）。给对照单元找一组非负权重，使加权后的对照在政策前尽量贴合处理单元，再把这条反事实路径延伸到政策后。
- **语法**（安装 `ssc install synth`）：
  ```stata
  ssc install synth
  synth depvar predictorvars, trunit(#) trperiod(#) [fig nested keep() ]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` / `predictorvars` | 结果变量 / 预测变量（可含结果滞后项） |
| `trunit(#)` | 处理单元的编号（`unit` 变量的取值） |
| `trperiod(#)` | 政策发生的期数 |
| `fig` | 画真实路径与合成路径对比图 |
| `nested` / `keep()` | 嵌套优化（更稳更慢）/ 保存中间结果 |

- **输出结果**：打印政策后差距、政策前 RMSPE（拟合优度）与对照单元权重表。`e()` 中：`e(Y0)`（合成路径）、`e(Y1)`（真实路径）、`e(RMSPE)`、`e(b)`、`e(V)`（存名以 `ereturn list` 为准）。
- **常用选项**：
  ```stata
  , trunit(3) trperiod(1990)   // 第 3 个单元在 1990 年受处理
  , fig                        // 出对比图
  , nested                     // 嵌套优化
  , keep(synthres, replace)    // 保存结果
  , xperiod(1980(1)1989)       // 只用这些期拟合权重
  , mspeperiod(1980(1)1989)    // 用这些期算 RMSPE
  ```
- **配套检验命令**：
  - `synth_runner`：自动安慰剂检验并给 p 值。
  - `fig` 的对比图：政策前贴合、政策后分离是最基本的读法。
  - 手写安慰剂循环（逐个把对照单元当"处理单元"跑 `synth`），比较 RMSPE 比值。
- **结果怎么读 · 常见坑**：
  - **政策前 RMSPE 必须小**，拟合都不像就谈不上反事实。
  - **不要外推太远**，政策后期数越多合成路径越不可信。
  - 权重全为 0/1 说明退化成"挑一个对照"，结论脆弱；权重表要报。
  - 处理单元样本期内若有其它政策冲击，SCM 无法区分，需说明。
- **示例**：
  ```stata
  synth y X1 X2 X3, trunit(3) trperiod(1990) fig
  ```

---

## ❖ `synth_runner`（合成控制法 + 安慰剂推断）

- **功能**：自动做合成控制并跑安慰剂检验，得到 p 值。它把每个对照单元依次当作"假处理单元"跑一遍 `synth`，用 RMSPE 比值构造零分布。
- **语法**：
  ```stata
  ssc install synth_runner
  synth_runner depvar predictorvars, trunit(#) trperiod(#) [gen_vars postest inference() ]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` / `predictorvars` | 与 `synth` 相同 |
| `trunit(#)` / `trperiod(#)` | 处理单元编号 / 处理期 |
| `gen_vars` | 生成 `_Y0`、`_Y1`、`_effect`、`_post` 等变量便于画图 |
| `postest` | 输出处理后逐期效应表 |
| `inference(method)` | 推断方式：`parametric`、`nonparametric`、`rank` |

- **输出结果**：打印处理效应 p 值（RMSPE 比值排名）、处理后逐期效应与安慰剂分布摘要；`gen_vars` 生成的 `_effect` 可直接作图。
- **常用选项**：
  ```stata
  , trunit(3) trperiod(1990) gen_vars   // 生成变量便于画图
  , postest                             // 打印处理后逐期效应
  , inference(rank)                     // 按排名做推断
  , seed(12345)                         // 随机种子
  ```
- **配套检验命令**：
  - `twoway line _effect period`：画处理效应路径（配合 `gen_vars`）。
  - `kdensity`：画安慰剂 RMSPE 比值分布，标出处理单元位置。
  - 手工 `synth` 复核：确认内部估计与手工结果一致。
- **结果怎么读 · 常见坑**：
  - **p 值来自排名**：对照只有 10–20 个时最小 p 受限于 1/(N_controls+1)，别指望 0.001。
  - 安慰剂单元若同期也受类似冲击，会稀释效应、抬高 p 值。
  - `gen_vars` 变量名固定，重复跑会覆盖，先 `drop` 或另存数据。
  - 政策前拟合极差的对照单元当安慰剂会扭曲分布，可按 RMSPE 阈值筛掉。
- **示例**：
  ```stata
  synth_runner y X1 X2, trunit(3) trperiod(1990) gen_vars
  twoway line _effect _period, yline(0)
  ```

---

## ❖ `scm` / `gsynth`（广义合成控制）

- **功能**：多处理期、多处理单元时的合成控制扩展。`gsynth` 用交互固定效应模型（Xu 2017）做广义合成控制，能处理多个受处理单元与交错处理期，并给出基于置换的推断。
- **语法**：
  ```stata
  ssc install gsynth
  gsynth depvar indepvars, id(idvar) time(timevar) treat(treatvar) [r(#) k(#) ]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` / `indepvars` | 结果变量与协变量 |
| `id()` / `time()` | 面板个体与时间变量 |
| `treat()` | 处理状态变量（0/1） |
| `r(#)` | 因子个数（交互固定效应的秩），0 表示不加因子 |
| `k(#)` | 交叉验证折数（用于选因子个数） |

- **输出结果**：打印 ATT 及基于置换/参数 bootstrap 的推断，并给出因子个数选择结果；具体存名用 `ereturn list` 查看（选项名以 `help gsynth` 为准，版本间略有差异）。
- **常用选项**：
  ```stata
  , r(0) k(5)         // 不加因子，5 折交叉验证
  , nboots(200)       // 置换/bootstrap 次数
  , seed(12345)       // 随机种子
  ```
- **配套检验命令**：
  - `gsynth` 自带交叉验证的因子个数选择，优先于人为指定 `r()`。
  - `synth` / `synth_runner`：单处理单元情形下的交叉验证。
  - `bacondecomp`：若是 DID 设计，先排除 TWFE 权重偏误。
- **结果怎么读 · 常见坑**：
  - **`r()` 选错会严重改变结论**，交给交叉验证并汇报不同 `r()` 下的稳健性。
  - 处理单元太少（<5）时置换推断几乎没有功效。
  - 假定"处理前无预期反应"，事前若干期要单独检查。
- **示例**：
  ```stata
  gsynth y x1 x2, id(id) time(year) treat(treat) r(0) k(5)
  ```

---

## ❖ `regression discontinuity` 辅助：`binscatter`（分箱散点图）

- **功能**：把散点按 x 分箱取均值画图，常用于 RDD 与回归趋势展示。在 RDD 里它是不写模型也能看出断点跳变的"第一张图"。
- **语法**：
  ```stata
  ssc install binscatter
  binscatter depvar indepvar [if] [in] [, noscatter line(qfit) bins(#) by(varlist)]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` / `indepvar` | 结果变量 / 横轴变量 |
| `noscatter` | 不画原始散点，只画分箱点 |
| `line(qfit)` | 叠加二次拟合线（`lfit` 为线性） |
| `bins(#)` / `by(varlist)` | 分箱数 / 分组各画一张 |

- **输出结果**：图；可用 `genxq()` 生成分箱变量自制图，分箱统计量存于 `r()`（`return list` 查看）。
- **常用选项**：
  ```stata
  binscatter y x, noscatter line(qfit)          // 干净的分箱图
  binscatter y x, by(treat) line(qfit) bins(20)  // 分组 + 20 箱
  binscatter y x, genxq(xq)                     // 生成分箱编号
  ```
- **配套检验命令**：
  - `rdplot`：RDD 专用作图，功能强于 `binscatter`。
  - `rdrobust`：把图里的直观跳变用正式估计量化。
  - `rddensity`：确认断点附近无堆积。
- **结果怎么读 · 常见坑**：
  - **分箱数改变图形形状**，图只作定性佐证，正式结论看 `rdrobust`。
  - x 分布极不均匀时边缘箱观测极少，噪声大。
  - 画的是条件均值，**不能说明因果**，只是"更干净的散点"。
- **示例**：
  ```stata
  binscatter y x, by(treat) line(qfit) bins(20)
  ```

---

## ❖ `permute` （随机化推断）

- **功能**：通过随机置换处理标记来构造零分布，计算经验 p 值，适合小样本因果检验；不依赖大样本正态近似。
- **语法**：
  ```stata
  permute permvar = exp_list, reps(#) [options] : command
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `permvar` | 收集统计量的自取名字（如 `did_beta`） |
| `exp_list` | 统计量表达式，如 `_b[treat]` 或 `_b[treat]/_se[treat]` |
| `reps(#)` | 置换次数 |
| `: command` | 每次置换后执行的估计命令 |

- **输出结果**：打印观测统计量 `T(obs)`、置换分布信息与经验 P 值；用 `saving()` 可把每次置换的统计量存成数据集再作图。
- **常用选项**：
  ```stata
  , reps(1000)             // 置换次数
  , nodots                 // 不显示进度点
  , rseed(12345)           // 随机种子，保证可复现
  , strata(varlist)        // 分层置换（面板/分组数据强烈建议）
  , saving(file, replace)  // 保存置换分布
  ```
- **配套检验命令**：
  - `kdensity` / `histogram`：画置换分布并标出真实统计量。
  - `summarize`：汇总零分布均值与标准差。
  - `count if`：手算经验 P，与输出交叉核对。
- **结果怎么读 · 常见坑**：
  - **面板数据不能整体置换观测**，会破坏组内相关；用 `strata()` 或只置换处理组标签。
  - 经验 P 分辨率是 1/(reps+1)，reps=1000 时最小约 0.001。
  - 零假设是"处理分配与潜在结果无关"（强于"无效应"），写作要讲清。
- **示例**：
  ```stata
  permute betadid=_b[did], reps(500) rseed(12345): regress y treat post did
  permute tstat=(_b[treat]/_se[treat]), reps(1000) nodots: regress y treat x
  ```

---

## ❖ `bootstrap` （自助法）

- **功能**：对有偏/复杂统计量（如有些因果估计）用重抽样构造标准误。解析标准误不可得时（两步估计、匹配后估计），`bootstrap` 是最通用的补救。
- **语法**：
  ```stata
  bootstrap exp_list [, options] : command
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `exp_list` | 要收集的统计量，如 `_b`、`r(mean)`、`_b[x]/_b[y]` |
| `reps(#)` | 重抽样次数 |
| `cluster(id)` | 聚类自助（重抽聚类而非观测） |
| `seed(#)` | 随机种子 |

- **输出结果**：打印原样本统计量、自助标准误、正态近似 CI 与偏差(bias)。结果存于 `e(b)`、`e(V)`、`e(N)`；`estat bootstrap, all` 给 normal / percentile / BC / BCa 四种区间。
- **常用选项**：
  ```stata
  , reps(1000)          // 重抽样次数
  , cluster(id)         // 聚类自助（面板必加）
  , strata(group)       // 分层自助
  , seed(12345)         // 随机种子
  , saving(bs, replace) // 保存每次统计量
  ```
- **配套检验命令**：
  - `estat bootstrap, all`：四种置信区间，BCa 在偏斜分布下最可靠。
  - `bootstrap, saving()` + `kdensity`：看自助分布形状，判断正态近似是否可用。
  - 与 `teffects`/`ivreg2` 的解析稳健 SE 对比，判断推断稳定性。
- **结果怎么读 · 常见坑**：
  - **自助救不了错误的模型设定**，只修正抽样不确定性。
  - 面板/聚类数据必须 `cluster()`，否则标准误严重偏小。
  - 分布严重偏斜时看 BCa，不要只看正态区间。
  - 给 `teffects` 之类慢命令做 bootstrap，`reps` 先小规模试跑。
- **示例**：
  ```stata
  bootstrap _b, reps(500) seed(12345): regress y x
  bootstrap, reps(500): ivregress 2sls y x (z1=z2)
  estat bootstrap, all
  ```

---

## ❖ `lasso` / `rlasso`（因果推断中的正则化变量选择）

- **功能**：在高维协变量下做拉索变量选择，配合因果模型（如 post-double-selection）使用。因果推断里 lasso 的用途不是"预测"，而是**挑控制变量**：把与处理、与结果都相关的协变量选进来。
- **语法**：
  ```stata
  lasso linear depvar indepvars [, selection(cv) folds(#) rseed(#) nolog]
  lasso logit depvar indepvars, selection(cv)      // 二值处理变量

  ssc install lassopack                             // 第三方：lasso2 / rlasso / cvlasso
  rlasso depvar indepvars
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `linear` / `logit` | 线性 / 二值模型 |
| `selection(cv)` | 交叉验证选 λ（也可 `adaptive`、`plugin`、`none`） |
| `folds(#)` / `rseed(#)` | 交叉验证折数 / 随机种子 |
| `rlasso` | 惩罚项具备稳健性质，配异方差稳健推断 |

- **输出结果**：输出选入变量个数、λ 值、样本内外拟合。`lasso` 结果存于 `e()`（`e(b)`、`e(lambda)`、`e(selection)`、`e(N)`、`e(df)` 等）；`rlasso` 输出系数表与选入变量数。
- **常用选项**：
  ```stata
  lasso linear y x1-x100, selection(cv) folds(10) rseed(12345) nolog   // 交叉验证选 λ
  lasso linear y x1-x100, selection(adaptive)                          // 自适应 lasso
  lassocoef                                                             // 看选入变量及系数
  coefpath                                                              // 系数路径图
  lassoselect                                                           // 交互式选 λ
  ```
- **配套检验命令**：
  - `lassocoef`：列出最终选中的变量与系数（附录常放）。
  - `coefpath`：系数路径图，看变量进入顺序是否稳定。
  - `lassoselect`：手动指定 λ 后重估，做稳健性。
  - `poregress`（Stata 16+）：post-double-selection 的官方实现，直接给处理效应的有效推断；`dsregress` 为单处理变量版本（详见 `help poregress`）。
- **结果怎么读 · 常见坑**：
  - **lasso 系数不能作因果解释**（惩罚带来收缩偏误），只能用来选变量，选完用 `regress`/`ivregress` 重估。
  - **别把处理变量放进 lasso 一起选**，否则会把处理效应本身收缩掉；要"处理方程/结果方程"分别做 lasso。
  - `selection(cv)` 依赖随机折分，**换种子结果会变**，要报 `rseed` 并做多种子稳健性。
  - 高维变量里若含处理后的变量（bad controls），lasso 会选进来反而制造偏误。
- **示例**：
  ```stata
  lasso linear y x1-x100, selection(cv) folds(10) rseed(12345) nolog
  lassocoef
  coefpath

  ssc install lassopack
  rlasso y x1-x100
  ```

---

## ❖ `did_imputation` / `csdid`（DID 最新异质性稳健估计：Callaway–Sant'Anna）

- **功能**：处理时间交错、效应异质时对 DID 的稳健估计。这类估计量先估每一队列 g 在每一期 t 的 ATT(g,t)，再加权汇总，从根本上避开 TWFE 的"坏比较"。
- **语法**：
  ```stata
  ssc install csdid
  csdid depvar [indepvars], ivar(id) time(year) gvar(first_treat) [notyet]
  estat event
  estat pretrend

  ssc install did_imputation
  did_imputation depvar first_treat timevar, unit(id) time(year) horizons(0/4)
  ```
  > `did_imputation`（插补法）与 `csdid`（分组-分期法）是两条独立路线，结论应互相印证。
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `ivar(id)` / `time(year)` | 面板个体 / 时间变量 |
| `gvar(first_treat)` | 个体**首次受处理**的期数；从未处理通常记 0 或缺失 |
| `notyet` | 只用"尚未处理"单元作对照（推荐） |
| `horizons(#)` | 要报告的相对期 |

- **输出结果**：`csdid` 输出各 ATT(g,t) 及聚合结果；`estat event` 给事件研究表，`estat pretrend` 给处理前趋势联合检验，`estat aggte` 给各种聚合。`e()` 中可用 `e(b)`、`e(V)`、`e(N)`（存名以 `ereturn list` 为准）；`did_imputation` 输出逐期 ATT 并存 `e(b)`、`e(V)`。
- **常用选项**：
  ```stata
  csdid y x1 x2, ivar(id) time(year) gvar(first_treat) notyet   // 推荐设定
  csdid y, ivar(id) time(year) gvar(first_treat) method(dripw)  // 双重稳健
  estat event                     // 事件研究表
  estat pretrend                  // 处理前趋势联合检验
  estat aggte, type(simple)       // 简单聚合 ATT
  estat aggte, type(dynamic)      // 动态效应
  ```
- **配套检验命令**：
  - `estat pretrend`：处理前 ATT 是否联合为零（平行趋势）。
  - `estat event`：动态效应表，直接画事件研究图。
  - `bacondecomp`：先看 TWFE 坏比较权重大不大，作为换用本估计量的依据。
- **结果怎么读 · 常见坑**：
  - **`gvar` 编码最容易错**：必须是"首次处理期"，从未处理记 0；把 0/1 处理状态塞进去会得到完全错误的结果。
  - **不要只报 simple ATT**：效应随时间变化时应同时报 dynamic 与 group 聚合。
  - `notyet` 与"已处理组作对照"改变估计目标，需在文中说明。
  - 协变量只是放松为"条件平行趋势"，不是万能的。
- **示例**：
  ```stata
  csdid y, ivar(id) time(year) gvar(first_treat) notyet
  estat event
  estat pretrend

  did_imputation y first_treat year, unit(id) time(year) horizons(0/4) pretrends(4)
  ```

---

## ❖ `eventstudyinteract`（两阶段 DID，Sun–Abraham）

- **功能**：交错处理下的动态事件研究，处理异质性。Sun–Abraham (2021) 用交互加权估计量按队列规模加权，避免 TWFE 事件研究中的负权重污染。
- **语法**：
  ```stata
  ssc install eventstudyinteract
  eventstudyinteract depvar rel_time_varlist [covariates], absorb(idvar) cohort(first_treat) control_cohort(never_treat) [vce(cluster idvar)]
  ```
  > **校订说明**：该命令的输入是**一组相对期虚拟变量**（须省略基准期 −1），而不是 `i.event##i.period` 交互项；选项为 `absorb()`、`cohort()`、`control_cohort()`、`vce()`。
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `depvar` | 结果变量 |
| `rel_time_varlist` | 相对期虚拟变量（如 `rel_m2 rel_0 rel_1`，省略 −1） |
| `absorb(idvar)` | 个体固定效应 |
| `cohort(first_treat)` | 首次处理期（队列标识） |
| `control_cohort(never_treat)` | 从未处理组标识 |
| `vce(cluster idvar)` | 聚类标准误 |

- **输出结果**：输出交互加权后的各相对期系数 `e(b_iw)` 与方差 `e(V_iw)`，以及加权用的队列规模；可用 `matrix list e(b_iw)` 查看，或配合第三方 `event_plot`（`ssc install event_plot`）作图。
- **常用选项**：
  ```stata
  , absorb(id) cohort(first_treat) control_cohort(never_treat) vce(cluster id)
  matrix list e(b_iw)     // 交互加权系数
  matrix list e(V_iw)     // 交互加权方差
  ```
- **配套检验命令**：
  - `csdid` + `estat event`：另一条交错稳健路线，结果应接近。
  - `did_imputation`：插补法路线，交叉验证。
  - `bacondecomp`：说明为什么必须换掉 TWFE。
- **结果怎么读 · 常见坑**：
  - **相对期虚拟变量要自己生成且省略 −1 期**；直接丢 `i.event##i.period` 会报错。
  - 必须有"从未处理"对照组；若全样本最终都被处理，需用"尚未处理"组并说明假设。
  - 标准误要报 `e(V_iw)` 对应的，别混用普通 OLS 标准误。
- **示例**：
  ```stata
  gen rel_m2 = (rel_time == -2)
  gen rel_0  = (rel_time == 0)
  gen rel_1  = (rel_time == 1)

  eventstudyinteract y rel_m2 rel_0 rel_1, ///
      absorb(id) cohort(first_treat) control_cohort(never_treat) vce(cluster id)
  matrix list e(b_iw)
  ```

---

## ❖ 因果分析配套检验（Validating Causal Designs）

> 因果推断的关键是**验证前提假设**。下面是最常用的一致性检验命令，均用于检验某一步骤是否有效。每条给出"用途 + 怎么读"，与章首速览表互为索引。

### ✨ ① DID 平行趋势检验：事件研究 / 手动交互项
- **功能**：检验政策前两组趋势是否平行（DID 的前提）。
- **语法**：
  ```stata
  * 事件研究法：政策前各期虚拟变量×treat
  reghdfe y ib2010.treat##i.year, absorb(id year) vce(cluster id)
  * 或手动
  forvalues t=2005/2009 {
      gen pre`t' = treat*(year==`t')
  }
  regress y pre2005-pre2009 post, vce(cluster id)
  test pre2005 pre2006 pre2007 pre2008 pre2009   // 联合不显著→平行
  ```
- **解读**：政策前各期交互项系数不显著（联合检验 P>0.05），则平行趋势成立。官方命令版：`didregress` 后 `estat ptrends` / `estat granger` / `estat event` / `estat trendplots`。
- **用途**：这是 DID 的"准入证"，不报平行趋势的 DID 结果基本无法发表。

### ✨ ② DID 安慰剂检验：`permute` 随机化推断
- **功能**：随机打乱处理/时间，看所得系数是否符合零分布（无效应）。
- **语法**：
  ```stata
  permute _b[did], reps(1000) rseed(12345): regress y treat post did
  ```
- **怎么读**：真实系数应落在置换分布的极端尾部（经验 P<0.05）；落在分布中央说明效应可能只是随机噪声。
- **用途**：平行趋势之外的第二道防线，尤其适合小样本、样本期短的场景。

### ✨ ③ DID 分解（多期交错的偏误检验）：`bacondecomp`
- **功能**：处理时间交错时"坏比较"权重，检验 DID 稳健性。
- **语法**：
  ```stata
  ssc install bacondecomp
  bacondecomp y treat, ddetail
  ```
- **怎么读**："Later vs Earlier"这类坏比较权重越大，TWFE 系数越不可信，应改用 `csdid` / `did_imputation` / `eventstudyinteract`。
- **用途**：交错 DID 论文的必报项，与稳健估计量配套出现。

### ✨ ④ IV 弱工具变量与过度识别：`estat firststage` / `estat overid` / `estat endog`
- **功能**：检验工具变量是否弱（第一阶段 F>10）及工具是否外生。
- **语法**：
  ```stata
  ivregress 2sls y x1 (x2 = z1 z2), vce(robust)
  estat firststage           // 看第一阶段 F
  estat overid               // 过度识别检验（Sargan）
  estat endog                // 内生性检验（DWH）
  ```
- **怎么读**：第一阶段 F 远大于 10（最好 >16.38）才算强工具；`estat endog` 的 P<0.05 说明确需 IV；`estat overid` 的 P>0.05 说明不能拒绝工具外生。异方差下再用 `ivreg2` 的 KP rk Wald F 与 Hansen J 复核。
- **用途**：IV 论文的三件套，缺一不可。

### ✨ ⑤ PSM 平衡性检验：`pstest` / `tebalance`
- **功能**：匹配后处理组与对照组协变量是否平衡。
- **语法**：
  ```stata
  psmatch2 treat edu age, outcome(wage)
  pstest edu age, both       // both=匹配前后都报告

  * 用 teffects 时
  teffects psmatch (wage) (treat edu age), atet
  tebalance summarize
  teffects overlap
  ```
- **怎么读**：匹配后 \|bias\|<10%、t 检验 P>0.1、联合检验 P>0.05 → 合格。原文此处提到的 `estat loadings` 并非 PSM 的平衡性检验命令，别用错。
- **用途**：PSM 能否成立全看这一张表，同时用 `teffects overlap` 检查共同支撑。

### ✨ ⑥ RDD 密度/连续性检验：`rddensity`（McCrary 检验）
- **功能**：检验断点处无操纵（驱使变量密度连续）。
- **语法**：
  ```stata
  ssc install rddensity
  rddensity runningvar, c(0)
  ```
- **解读**：P>0.05 → 断点处密度无跳跃，无操纵嫌疑。同时应把协变量当结果变量跑 `rdrobust`，断点两侧协变量应连续（系数不显著）。
- **用途**：RDD 的识别前提之一，再配合多带宽敏感性（`rdbwselect`）汇报。

### ✨ ⑦ 合成控制安慰剂：`synth_runner` 推断
- **功能**：对处理单元做安慰剂，得到处理器效应 p 值。
- **语法**：
  ```stata
  synth_runner y X, trunit(3) trperiod(1990) gen_vars
  ```
- **怎么读**：看处理后效应 p 值，以及处理单元 RMSPE 比值在安慰剂分布中的排名；政策前 RMSPE 必须足够小，否则反事实不可信。
- **用途**：SCM 的显著性几乎只能靠安慰剂推断，这是标准做法。

---

# 附录 · 数据处理 / 画图 / 常用细节命令
# 附录 A · 数据处理命令（Data Management）

> 本附录把实证分析中最高频的**数据处理命令、绘图命令**以及**回归后的细节诊断命令**集中整理，统一格式供随时查阅。

> 数据处理是实证分析里最耗时间、也最容易悄悄出错的一环：一次忘了 `isid` 的 `merge`，就足以让样本量翻倍而毫无报错。因此本章每个条目还额外给了**配套核查命令**（做完这步用什么命令验证数据是对的）与**常见坑**，建议养成"改一步、查一步"的节奏。

## 📋 本章检验命令速查（数据质量核查）

> 本章是数据管理命令，这里说的"检验"是**数据质量核查**：唯一性、重复值、缺失、类型与取值范围。建议在 `merge` / `collapse` / `reshape` 等**破坏性操作**前后各跑一遍。

| 核查命令 | 核查什么 | 判定标准 / 输出怎么读 | 常与谁配合 |
|---|---|---|---|
| `isid id year` | 关键变量组合是否**唯一**标识观测 | 不报错 = 唯一；报 `does not uniquely identify` 即有重复 | `merge`、`xtset`、`reshape` 前必跑 |
| `duplicates report id` | 重复的规模 | 看 `surplus`（多余观测数），0 = 无重复 | `duplicates examples` 定位具体行 |
| `assert 条件` | 数据必须满足的硬规则 | **无输出 = 通过**；报 `assertion is false` + `r(9)` 即有违规行 | `count if !(条件)` 数违规条数 |
| `count if missing(x)` | 单变量缺失条数 | 返回观测数，除以 `_N` 即缺失率 | `misstable summarize` |
| `misstable summarize` | 全表缺失分布 | 看 `Obs=.`（缺失）与 `Obs>.`（`.a`–`.z` 扩展缺失）两列 | `misstable patterns` 看缺失模式 |
| `codebook v` | 取值范围、唯一值、缺失 | 看 `range`、`unique values`、`missing`；出现 999/-1 等特殊码须处理 | `summarize, detail`、`tab v, missing` |
| `describe` | 变量**存储类型** | `str18` = 字符串，`byte/int/long/float/double` = 数值；该是数字却是 `str` 说明导入有问题 | `destring`、`compress` |
| `tab v, missing` | 分类变量异常取值 | 不在 `label list` 里的码值即异常；末行 `.` 是缺失数 | `label define`、`recode` |
| `summarize v, detail` | 极值与分布 | `min/max` 与 `p1/p99` 差得离谱，多半是录入错误或单位不一致 | `list if v>上限`、`winsor2`（需安装） |
| `compare`（需安装） | 两份数据是否逐格一致 | 逐变量报不一致观测数，**全 0** 才说明相同 | `datasignature`、`preserve/restore` |

---

## ❖ `use` / `save` / `compress` （载入 / 保存 / 压缩数据）
- **功能**：`use` 读入 .dta 文件；`save` 保存当前数据；`compress` 压缩存储空间。
- **语法**：
  ```stata
  use [varlist] using "filename.dta" [, clear]
  save "filename.dta" [, replace]
  compress
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `using "filename.dta"` | 数据文件路径，含空格或中文必须加双引号 |
| `, clear` | 不提示、直接清空内存中已有数据 |
| `, replace` | `save` 时覆盖同名文件，否则报 file already exists |

- **常用选项/函数**：
  ```stata
  use ..., clear        // 不提示直接覆盖内存中的数据
  save ..., replace     // 覆盖同名文件
  ```

- **配套核查命令**：读入后立刻 `describe`（核对变量数与类型）、`count`（确认 `_N`），并用 `datasignature set` 打"指纹"、日后 `datasignature report` 验证数据没被改动。

- **常见坑**：
  - 忘写 `, clear`：内存中已有数据时报 `no; data in memory would be lost`。
  - `save` 不加 `, replace` 会直接报错停下，在 do 文件里会打断整个流程。
  - Windows 路径的反斜杠建议写成 `/`（如 `"C:/data/wage.dta"`），否则可能被当转义符。
  - `compress` 只缩存储类型，不改数值、也不修 `float` 存大整数的精度问题。

- **示例**：
  ```stata
  use "C:\data\wage.dta", clear
  gen lwage = ln(wage)
  compress
  save "C:\data\wage_new.dta", replace
  ```

---

## ❖ `import` / `export` （导入导出 Excel / CSV）
- **功能**：跨格式读写数据，把 Excel / CSV 变成 .dta，或把结果导出成表。
- **语法**：
  ```stata
  import excel "file.xlsx", sheet("数据") firstrow clear
  import delimited "file.csv", clear
  export excel using "out.xlsx", firstrow(variables) replace
  export delimited "out.csv", replace
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `sheet("表名")` | `import excel` 指定工作表，不写则读第一张 |
| `firstrow` | 导入时首行作变量名（导出要写 `firstrow(variables)`） |
| `varnames(1)` | `import delimited` 把第 1 行当变量名 |
| `encoding("utf-8")` | 文本编码，中文乱码时改用 `"gb18030"` |

- **常用选项/函数**：
  ```stata
  import excel "f.xlsx", cellrange(B2:D100) firstrow clear  // 表头不规整时指定区域
  import delimited "f.csv", stringcols(1 3) clear           // 强制读成字符串，保留前导零
  export excel using "out.xlsx", sheet("结果") firstrow(variables) replace
  ```

- **配套核查命令**：导入后先 `describe` 看本该是数值的列有没有变成 `str`，再 `browse in 1/10` 目视核对有无串列，最后 `codebook, compact` 扫一遍取值范围与异常码。

- **常见坑**：
  - Excel 有合并单元格或双行表头时，`firstrow` 把表头读成 `v2 v3`；先清理表格或用 `cellrange()`。
  - 金额含千分位逗号、百分号、空格会被读成字符串，需 `destring, ignore("," "%" " ")`。
  - 身份证号、邮编会被读成数值而丢掉前导零，用 `stringcols()` 保留为字符串。
  - 导出 Excel 时目标文件正被打开会报无法写入，先关掉文件。

- **示例**：
  ```stata
  import excel "dataset.xlsx", sheet("Sheet1") firstrow clear
  destring salary, replace ignore(",")
  export excel using "result.xlsx", firstrow(variables) replace
  ```

---

## ❖ `describe` / `codebook` / `list` （查看数据结构与内容）
- **功能**：`describe` 列出变量信息；`codebook` 查看变量细节（含缺失值）；`list` 直接显示观测。
- **语法**：
  ```stata
  describe [, short]
  codebook varlist
  list varlist [if], sep(0)
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `describe` | 变量名、存储类型、显示格式、变量标签 |
| `codebook, compact` | 一行一个变量，看类型、唯一值、缺失、取值范围 |
| `list ..., sep(0)` | 不按观测分组、紧凑输出，查异常码值时加 `nolabel` |

- **常用选项/函数**：
  ```stata
  list ..., sep(0)      // 不按观测分组
  list ..., nolabel     // 显示标签对应的数值
  codebook x, compact   // 简洁版
  ```

- **配套核查命令**：用 `summarize v, detail` 对照 `codebook` 的 range 确认极值不是录入错误，用 `tab v, missing` 逐码点数分类变量，关键变量再用 `assert !missing(key)` 断言无缺失。

- **常见坑**：
  - `list` 不加 `in`/`if`，几万行会刷很久，核对数据一律用 `in 1/20`。
  - `codebook` 会列出字符串变量的所有唯一值，长文本（地址）会让输出爆炸。
  - `describe` 显示的是**存储类型**（`str18`、`float`），不是显示格式。
  - 排查异常码值要加 `nolabel`，否则只看到标签名、看不到码值。

- **示例**：
  ```stata
  describe
  codebook wage edu, compact
  list id wage client if missing(wage)
  ```

---

## ❖ `browse` / `edit` （图形化浏览 / 编辑数据）
- **功能**：`browse` 弹出数据查看窗口；`edit` 可在窗口中手动修改。
- **语法**：
  ```stata
  browse [varlist] [if] [in]
  edit [varlist] [if] [in]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `browse` | **只读**浏览，关窗口不影响数据 |
| `edit` | **可写**，单元格改动直接写入内存数据 |
| `, nolabel` | 显示数值而非值标签 |

- **常用选项/函数**：
  ```stata
  browse id wage              // 打开数据编辑器（只读）
  browse if wage>10000        // 只看工资异常高的观测
  edit wage                   // 手动修改工资（危险操作，先 preserve）
  ```

- **配套核查命令**：动 `edit` 之前先 `preserve`（改坏了能 `restore`）；改完用 `describe` 核对类型与变量数、`count if 条件` 统计改动条数，最后 `assert` 把"改对了"写成断言。

- **常见坑**：
  - `edit` **不能撤销**，改错只能靠事先的 `preserve` / `save`；正式数据尽量不用。
  - 在 do 文件里 `browse` 会暂停执行直到关窗口，跑长流程别放进去。
  - 数据被 `sort` 后行号会变，照旧行号改第 N 行很容易改错观测，用 `if` 精确定位。
  - 手输的值不会自动校验，容易混入非法码值，改完务必 `tab v, missing` 复查。

- **示例**：
  ```stata
  browse id wage
  edit wage          // 手动修改工资
  ```

---

## ❖ `gen` / `replace` （生成与替换变量）
- **功能**：`gen` 新建变量，`replace` 修改已有变量。变量生成的赋值表达式支持算术、逻辑、函数。
- **语法**：
  ```stata
  gen newvar = expression [if] [in]
  replace var = expression [if] [in]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `newvar` | 新变量名，不能与已有变量重名 |
| `expression` | 算术 `+ - * / ^`、逻辑 `& \| !`、函数 `ln() exp() sqrt()` |
| `[if]` | 条件，不满足者为**缺失**（不是 0） |
| `gen byte/str20` | 显式指定存储类型，省内存、防溢出 |

- **常用表达式**：
  ```stata
  gen wage2  = wage^2
  gen lwage  = ln(wage)
  gen exp2   = exp^2 / 100
  gen treat  = (group==1)          // 逻辑：真=1 假=0
  gen female = 1 if gender==2      // 条件生成：其余观测为缺失
  replace female = 0 if gender==1
  gen agecat = 1 if age<30
  replace agecat = 2 if age>=30 & age<50
  ```

- **配套核查命令**：用 `count if missing(newvar)` 数一数条件生成留下的缺失，用 `summarize newvar, detail` 看均值与极值是否合经济含义，离散变量再 `tab newvar, missing`。

- **常见坑**：
  - 对已存在变量用 `gen` 报 `already defined`，要改用 `replace`，或先 `drop`。
  - `gen x = 1 if cond` 只给满足者赋值，其余是**缺失不是 0**，否则项要显式 `replace`。
  - `replace` 漏写 `if` 会作用于全部观测，一次错误覆盖整列且无提示。
  - **缺失比任何数都大**：`gen hi = (income>100)` 中 `income` 缺失会被判为 1，要写 `& !missing(income)`。

- **示例**：
  ```stata
  gen size = ln(sales) - ln(assets)   // 相对指标
  gen year2 = year - 2000             // 中心化
  ```

---

## ❖ `egen` （扩展生成，分组统计函数）
- **功能**：比 `gen` 更强的扩展生成函数，常与 `by()` 组合做**组内**统计。
- **语法**：
  ```stata
  egen newvar = fcn(exprlist) [, by(groupvar)]
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `newvar` | 新变量名，必须尚不存在 |
| `fcn` | `egen` 专用函数，与 `gen` 的普通函数不是同一套 |
| `exprlist` | 参与计算的变量，如 `rowmean(x y z)` 中的 `x y z` |
| `by(groupvar)` | 分组变量，省略时作用于全样本 |

- **常用函数**：
  ```stata
  egen m = mean(wage), by(year)        // 组内均值
  egen s = sd(wage), by(year)          // 组内标准差
  egen mx = max(age)                   // 全局最大值
  egen mn = min(age), by(id)           // 组内最小值
  egen tot  = total(sales), by(id)     // 组内总和
  egen cnt  = count(income), by(id)    // 组内非缺失个数
  egen n    = nvals(id)                // 唯一值个数
  egen rank = rank(wage)               // 排名
  egen rowmean = rowmean(x y z)        // 行级均值
  egen tagg = tag(id)                  // 每个组第一个=1
  egen cutv = cut(age), at(20 30 40 50)   // 分组编码（at() 是选项）
  ```

- **配套核查命令**：`summarize newvar, detail` 看组级统计量的分布是否合理；若生成的是组级常数，用 `bysort gid: assert _N==1` 验证组内唯一；再用 `count if missing(newvar)` 查空组。

- **常见坑**：
  - `egen x = mean(y)` 漏写 `by()` 得到的是**全样本**均值，这是最高频错误。
  - 生成的是逐观测重复的**组级常数**，要算离差还得再 `gen dev = wage - m`。
  - `egen` 不能覆盖已存在变量，脚本里重跑会报 `already defined`，先 `capture drop`。
  - `rowmean()`/`rowtotal()` 会忽略缺失，要"全部非缺失才算"需配合 `rowmiss()`。

- **示例**：
  ```stata
  egen meanwage = mean(wage), by(gender)   // 分性别均值
  gen dev = wage - meanwage                // 组内离差
  ```

---

## ❖ `bysort` （分组排序 + 组内操作）
- **功能**：先在组内排序，再执行生成命令（`gen`、`replace` 常与组序号配合）。
- **语法**：
  ```stata
  bysort groupvar [(sortvar)]: 命令
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `groupvar` | 分组变量，可多个：`bysort id year:` |
| `(sortvar)` | 括号内是**组内**排序键，如 `bysort id (year):` |
| `_n` | 组内当前观测序号（1,2,3…） |
| `_N` | 组内总数；不加 `by` 时表示全样本总数 |

- **常用选项/函数**：
  ```stata
  bysort id year: gen seq = _n            // 组内序号
  bysort id (year): gen lag_y = y[_n-1]   // 组内上一期值
  bysort id: gen first = y[1]             // 组内第一个值
  bysort id: gen last = y[_N]             // 组内最后一个值
  ```

- **配套核查命令**：先用 `isid id year` 确认分组键唯一（否则 `_n` 无意义）、`duplicates report id` 看每组重复几次，面板数据再 `bysort id (year): assert year>year[_n-1]` 验证时间严格递增。

- **常见坑**：
  - `by` 之前**必须先 `sort`**，否则报 `not sorted`；`bysort` 就是把两步合并。
  - `bysort id: gen y = x[_n-1]` 若组内未按时间排，取到的是"上一行"而非"上一期"。
  - 括号里才是组内排序键，`bysort id year:` 的 `year` 是**第二个分组变量**，含义完全不同。
  - `bysort` 会**永久改变行顺序**，旧的 `_n` 全部失效；需要时先 `gen long obsid = _n`。

- **示例**：
  ```stata
  bysort id (year): gen d_y = y - y[_n-1]
  bysort id: egen maxy = max(y)
  ```

---

## ❖ `keep` / `drop` （变量与观测的保留 / 删除）
- **功能**：`keep` 只保留指定内容，`drop` 删除指定内容。
- **语法**：
  ```stata
  keep varlist            // 只保留这些变量
  keep if 条件             // 只保留满足条件的观测
  drop varlist            // 删除这些变量
  drop if 条件             // 删除满足条件的观测
  drop _all              // 清空所有（等于 clear all）
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `varlist` | 变量清单，支持通配与区间：`keep id-wage`、`drop x*` |
| `if 条件` | 按观测筛除，会改变 `_N` |
| `in 范围` | 按行号筛除，如 `drop in 1/5` |

- **常用选项/函数**：
  ```stata
  keep id year wage treat                // 只留分析要用的变量
  drop if missing(wage) | missing(edu)   // 删除关键变量缺失
  drop in 1/5                            // 删前 5 行（导入的表头垃圾行）
  ```

- **配套核查命令**：删除前先 `count if 条件` 数一遍要删多少行、心里有数，删后用 `assert _N==预期样本量` 核对样本量，再用 `describe` 核对残留变量清单。

- **常见坑**：
  - `keep if` / `drop if` **不可撤销**，先 `preserve` 或 `save` 备份。
  - 两种用法不能混写，`drop x if y>0` 会报错，按条件删变量只能分两步。
  - 删观测后 `_N` 改变，此前基于 `_n`/`_N` 生成的滞后项、序号全部错位。
  - `keep if x==1` 遇缺失既不保留也不报错，要保留需写 `| missing(x)`。

- **示例**：
  ```stata
  keep id year wage treat
  keep if treat==1
  drop if missing(wage)
  ```

---

## ❖ `generate` 缺失值处理：`missing` / `mi` / 填补
- **功能**：处理缺失值——识别、查看、删除与简单填补。
- **语法**：
  ```stata
  gen miss = missing(income)         // 是否缺失
  count if missing(income)
  drop if missing(income)            // 删除缺失行（列表删除）
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `missing(x)` | 判断任意缺失（`.` 与 `.a`–`.z`），返回 1/0，最可靠 |
| `x==.` | 只能识别系统缺失 `.`，识别不了 `.a`–`.z` |
| `mi(x)` | 与 `missing()` 行为一致，写法可互换；`.a`–`.z` 是可区分原因 |

- **常用做法**：
  ```stata
  keep if !missing(y)                // 只保留因变量不缺失
  foreach v of varlist x1-x10 {
      replace `v' = 0 if missing(`v')   // 补 0（会把"真缺失"变"真零"）
  }
  misstable summarize                // 全表缺失分布一览
  ```

- **配套核查命令**：填补/删除前后各跑一次 `misstable summarize`，对比缺失数是否归零；单变量用 `count if missing(x)`，关键变量用 `assert !missing(key)` 卡死。

- **常见坑**：
  - 用 `x==.` 判缺失会漏掉 `.a`–`.z`，统一用 `missing(x)`。
  - 缺失参与算术运算结果仍是缺失：`gen y = x + 1` 中 `x` 缺失则 `y` 缺失。
  - `summarize` 默认忽略缺失，均值只基于非缺失样本，样本量看 `Obs` 列。
  - "补 0"最危险：把"没观测到"与"确实为 0"混为一谈，会系统性低估均值。

- **示例**：
  ```stata
  drop if missing(wage) | missing(edu)
  gen byte lw_miss = missing(wage)
  tab lw_miss
  ```

---

## ❖ `sort` / `gsort` / `order` / `recode` （排序与重编码）
- **功能**：`sort` 升序排序；`gsort` 混合排序（降序）；`order` 调整变量顺序；`recode` 重编码。
- **语法**：
  ```stata
  sort varlist                  // 升序
  gsort -year id                // year 降序、id 升序
  order id year y               // 调换变量位置
  recode edu (1=0)(2/3=1)(else=.), gen(edu2)
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `sort ..., stable` | 相同键值的观测保持原有相对顺序 |
| `gsort -var` | `-` 前缀表示降序，`+` 表示升序 |
| `recode` 规则 | `(旧=新)`、`(范围=新)`、`(else=新)`；未匹配值默认**保持不变** |

- **常用选项/函数**：
  ```stata
  sort ..., stable      // 保持原相对顺序
  gsort -wage           // 工资降序
  order year id wage    // 变量重排，方便阅读
  recode age (0/17=1)(18/59=2)(else=3), gen(agecat)   // else 必须放最后
  ```

- **配套核查命令**：`tab oldvar newvar, missing` 交叉表核对每个旧值落到哪个新值（最关键），再 `assert !missing(newvar)` 确认 `else` 兜底覆盖了所有情况，`codebook newvar` 看新编码范围。

- **常见坑**：
  - `sort` 默认**不稳定**，键值相同的观测相对顺序会变，需保留时加 `stable`。
  - `recode` 没写 `(else=.)` 时，未列出的旧值原样保留，容易把 99 之类特殊码留在新变量里。
  - `(else=...)` 必须放在**最后**，否则报语法错误。
  - `order` 只改列位置不删变量；排序后 `_n` 全部改变，基于行号的引用都要重算。

- **示例**：
  ```stata
  gsort -wage
  recode age (0/17=1 "未成年")(18/59=2 "劳动")(else=3), gen(agecat)
  tab age agecat, missing
  ```

---

## ❖ 字符串与数值转换：`destring` / `tostring` / `encode` / `decode`
- **功能**：变量类型互转——数值↔字符串，以及字符串分类→编码。
- **语法**：
  ```stata
  destring x, replace [force]      // 字符串→数值
  tostring id, replace             // 数值→字符串
  encode region, gen(regionid)     // 字符串分类→数值+标签
  decode regionid, gen(region2)    // 数值标签→字符串
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `, ignore("$,")` | 转换前忽略这些字符（千分位逗号、货币符号） |
| `, force` | 强制转换，转不了的值变**缺失**（会静默丢数据） |
| `, gen(new)` | 不覆盖原变量，生成新变量 |
| `encode ..., label(名)` | 指定生成的值标签名 |

- **常用选项/函数**：
  ```stata
  destring ..., gen(new) ignore("$")  // 忽略特定字符
  destring ..., force                 // 强制转换（丢掉无法转的）
  destring x, replace ignore("," "%") // 处理千分位与百分号
  tostring id, replace format(%09.0f) // 保留前导零（邮编、学号）
  ```

- **配套核查命令**：`describe x` 确认类型真的从 `str` 变成了数值，`count if missing(x)` 揪出 `force` 造成的缺失暴增，`tab region regionid, missing` 核对 `encode` 后标签与数值一一对应。

- **常见坑**：
  - 不加 `force` 时只要有一个非数字字符就整列不转，且不一定报错，靠 `describe` 才发现还是 `str`。
  - 加了 `force` 则脏值被静默变成缺失，样本悄悄缩水，必须 `count if missing()` 复查。
  - 前导/尾随空格会让转换失败，先 `replace x = trim(x)`。
  - **`encode` ≠ `destring`**：`encode` 是给分类标签编号（"北京"→1），数值无大小含义、不能算均值；`destring` 才是把数字文本变回可计算数值。
  - `tostring` 默认按显示格式转换，可能丢精度或丢前导零，用 `format()` 明确指定。

- **示例**：
  ```stata
  destring salary, gen(sal) ignore(",")
  encode gender_str, gen(gender)
  ```

---

## ❖ 标签管理：`label`
- **功能**：给变量、数值加上可读中文/英文标签，让输出表格直接可读。
- **语法**：
  ```stata
  label variable wage "小时工资"
  label define g 0 "男" 1 "女"
  label values gender g
  label data "示例数据集说明"
  label list
  label drop g
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `label variable var "文字"` | 变量标签（最长 80 字符） |
| `label define 名 值 "文字"` | 定义**值标签**（可复用的标签集） |
| `label values var 标签名` | 把值标签贴到数值变量上 |
| `label dir` / `labelbook` | 列出内存中标签名 / 全部标签映射 |

- **常用选项/函数**：
  ```stata
  label define edu_cat 1 "小学" 2 "中学" 3 "大学"   // 一次性定义
  label define edu_cat 4 "研究生", add               // 追加必须 add
  label variable wage "月工资（元）"                  // 变量标签
  ```

- **配套核查命令**：`label list edu_cat` 确认标签内容建对了，`tab v, missing` 检查有没有"裸码值"（未定义标签的取值），`describe` 看哪些变量挂了值标签。

- **常见坑**：
  - 同名标签重复 `label define` 而不加 `, add` 会**覆盖**原定义，已贴好的标签全变。
  - `label values` 只能贴到**数值**变量上，字符型报错。
  - 没定义的码值（9、99）在 `tab` 里直接显示数字，看到突兀数字就是漏定义。
  - 合并两份数据时同名标签内容不同会报 `label ... already defined`，改用 `, add` 或重命名。

- **示例**：
  ```stata
  label variable education "受教育年限"
  label define edu_cat 1 "小学" 2 "中学" 3 "大学"
  label values edu edu_cat
  ```

---

## ❖ 拼接 / 追加：`merge` / `append` / `joinby` / `cross`
- **功能**：横向合并、纵向追加、笛卡尔积、联结。
- **语法**：
  ```stata
  merge 1:1 id using "file.dta"        // 一对一
  merge m:1 id using "file.dta"        // 多对一
  merge 1:m year using "file.dta"      // 一对多
  append using "file.dta"              // 纵向追加
  joinby id using "file.dta"           // 生成全部匹配组合
  cross using "file.dta"               // 笛卡尔积
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `1:1` / `m:1` / `1:m` | 两边 key 的对应关系，`1:1` 要求两边都唯一，最安全 |
| `_merge` | 自动生成：1=仅主表，2=仅 using，3=两边都有 |
| `keepusing(varlist)` | 只从 using 表取指定变量 |
| `keep(match master using)` | 保留哪些匹配类型 |

- **常用选项/函数**：
  ```stata
  merge 1:1 id using "...", keepusing(var)   // 只保留指定变量
  merge ..., nogen                          // 不生成 _merge 变量
  merge ..., assert(match)                  // 断言只应出现匹配，不满足就报错
  ```

- **配套核查命令**：合并**前**必须 `isid id`（两边 key 都唯一），合并后第一件事 `tab _merge` 看匹配情况分布，再用 `assert _merge==3` 断言"应全部匹配"、不满足立即停下。

- **常见坑**：
  - **`merge` 前必须先 `isid`**：`m:1`/`1:m` 遇重复会**静默复制观测**，样本翻倍还查不出来。
  - `_merge==1` 占比很高，多半是 key 写法不一致（一边 `"01"`、一边 `1`）。
  - 同名的**非键变量**会保留主表值、丢弃 using 的且不提示，需要时先 `rename`。
  - `append` 按变量名对齐，名字不一致（`wage` vs `salary`）会各留一列缺失。

- **示例**：
  ```stata
  isid id year
  merge 1:1 id year using "firm.dta", keepusing(profit)
  tab _merge
  drop if _merge==1             // 删除仅主表有（没匹配上的）
  drop _merge
  ```

---

## ❖ `collapse` （数据折叠 / 聚合压缩）
- **功能**：把原始数据按组汇总成统计量，常用于构造宏观/面板聚合变量。
- **语法**：
  ```stata
  collapse (mean) x (sd) x_sd (count) n=id (sum) s=value, by(year)
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `(统计量) 新变量=原变量` | 每组算一个统计量，不写 `新变量=` 则沿用原变量名 |
| `by(varlist)` | 分组变量；省略则把全部数据压成一行 |
| `, cw` | 删掉 `by()` 变量缺失的观测，避免"缺失组" |
| `_freq` | 自动生成，记录每组参与计算的观测数 |

- **常用统计函数**：
  ```stata
  (mean)     (sd)     (median)     (min)     (max)
  (sum)      (count)  (iqr)        (p25)  p50
  (first)    (last)
  ```
- **配套核查命令**：`collapse` **之前先 `preserve`**；折叠后 `isid 分组变量` 确认每组只剩一行，用 `tab _freq if _freq==1` 找出只含 1 个观测、均值代表性差的组。

- **常见坑**：
  - `collapse` 会**直接替换内存中的原数据**且不可撤销——先 `preserve`，最致命的坑。
  - 折叠后只保留 `by()` 变量与统计量，其余变量**全部消失**。
  - `(count)` 数的是**非缺失**个数，`(sum)` 也忽略缺失，`_freq` 可能小于真实行数。
  - `by()` 变量有缺失时会自成一"组"，通常不是想要的，加 `, cw` 排除。

- **示例**：
  ```stata
  collapse (mean) wage (median) wage_m=wage, by(gender)
  collapse (sum) sales, by(firm year)       // 面板→年度合计
  ```

---

## ❖ `reshape` （长宽格式转换）
- **功能**：`reshape wide/long` 在面板"长格式"与"宽格式"间转换。面板回归要求长格式。
- **语法**：
  ```stata
  reshape long varlist, i(id) j(time)
  reshape wide varlist, i(id) j(time)
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `varlist`（stub） | 变量**词干**，如 `y x` 对应 `y2010 y2011`、`x2010 x2011` |
| `i(id)` | 个体标识，宽格式下每个 `i` 一行 |
| `j(time)` | 时点变量名；`long` 时新建，`wide` 时已存在 |

- **常用选项/函数**：
  ```stata
  reshape long y x, i(id) j(year)      // 宽→长：y2010 y2011 变 y + year
  reshape wide y x, i(id) j(year)      // 长→宽：反向操作
  reshape error                        // 失败时定位哪些 (i,j) 组合重复
  ```

- **配套核查命令**：转 `long` 后立刻 `isid id year` 验证 `(i, j)` 唯一，`assert _N==人数*年数` 核对行数，再 `xtset id year` 把面板结构定下来。

- **常见坑**：
  - `(i, j)` 重复时报 `repeated time values within panel`，用 `duplicates report id year` 找重复行。
  - 变量名必须是"词干+后缀"（`y2010`），写成 `y_2010` 认不出来，需先 `rename`。
  - 后缀缺年份（有 2010、2012 没 2011）会得到全缺失的观测，事后要 `drop if missing(y)`。
  - `reshape` 后行序被打乱，旧的 `_n` 排序失效，需要时重新 `sort`。

- **示例**：
  ```stata
  reshape long y x, i(id) j(year)     // 宽→长
  xtset id year
  reshape wide y x, i(id) j(year)     // 长→宽
  ```

---

## ❖ 重复值处理：`duplicates` / `isid`
- **功能**：发现并删除重复观测；`isid` 检验变量是否能唯一标识个体。
- **语法**：
  ```stata
  duplicates report var
  duplicates list
  duplicates examples var
  duplicates drop id, force
  isid id               // 若报错说明 id 不唯一
  isid id year          // 面板组合唯一
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `duplicates report varlist` | 报告重复观测数与"多余"观测数 `surplus` |
| `duplicates examples` | 每组重复只举一例，输出清爽 |
| `duplicates drop ..., force` | 删除重复、只留第一条，`force` 是确认 |
| `isid varlist [, missok]` | 只检验不改数据；`missok` 允许缺失参与判断 |

- **常用选项/函数**：
  ```stata
  duplicates report id year          // 最常用：先看规模
  duplicates examples id year        // 看不一致的具体行
  duplicates tag id, gen(ndup)       // 标记重复次数（0=不重复）
  duplicates drop id year, force     // 去重（先 preserve）
  ```

- **配套核查命令**：去重后 `isid id year` 必须通过、`duplicates report id year` 的 `surplus` 应归零，再用 `count` 对比去重前后的行数差。

- **常见坑**：
  - `duplicates drop` 直接**永久删观测**，务必先 `preserve` 或 `save`。
  - 判重只看你给的变量：只写 `id` 会把同一 `id` 的多期数据全删掉，面板必须写 `id year`。
  - 保留的是"第一次出现"那条，两条记录其它变量不同时留下的未必是你要的。
  - `isid` 只检验、不改数据，`merge` 前可放心反复运行。

- **示例**：
  ```stata
  isid id year          // 面板必须唯一
  duplicates drop id year, force
  ```

---

## ❖ `preserve` / `restore`
- **功能**：临时保存当前数据，做实验性修改后再 `restore` 还原。
- **语法**：
  ```stata
  preserve
  ... 对数据做临时操作 ...
  restore     // 还原到 preserve 时的状态
  ```
- **参数说明**：

| 参数 | 说明 |
|------|------|
| `preserve` | 把当前内存数据整份快照到临时文件 |
| `restore` | 丢弃当前数据，恢复最近一次快照 |
| `restore, not` | 只丢弃快照、不恢复（当前数据保留） |
| `snapshot`（17+） | 可命名的多版本快照机制 |

- **常用选项/函数**：
  ```stata
  preserve
  keep if treat==1
  summarize wage
  restore                     // 回到全样本
  ```

- **配套核查命令**：`preserve` 前用 `datasignature set` 打指纹、`restore` 后 `datasignature report` 验证完全一致；也可用 `compare`（需安装）逐变量比对，`count` 确认 `_N` 复原。

- **常见坑**：
  - `preserve` 会把数据**整份复制**，大数据可能直接内存不足；改用另存文件再 `use`。
  - 只能恢复到**最近一次**快照：连写两次 `preserve`，第二份覆盖第一份。
  - 忘记 `restore` 会让后续代码在"被裁剪过的数据"上继续跑，结果全错却毫无报错。
  - `restore` 之后，`preserve` 期间生成的**新变量全部消失**，要保留的结果先 `save`。

- **示例**：
  ```stata
  preserve
  keep if treat==1
  summarize wage
  restore
  ```

---

# 附录 B · 画图命令（Graphing）

> Stata 图形体系以 `graph` 为容器、`twoway` 为二维图基础。学会 `scatter`、`line`、`histogram` 等即可覆盖 80% 需求。

## 📋 本章速查：出图后必做的检查

| 检查项 | 怎么查 | 说明 |
|---|---|---|
| 图形是否导出 | `graph export "fig.png", replace` | 屏幕上显示不等于存进文件；批量出图用循环逐张导，别指望事后翻屏幕 |
| 分辨率够不够 | `graph export ..., width(3000)` | 位图要给足 `width()`，否则插进 Word 就糊；正式排版优先导 `.pdf`/`.eps` 矢量图 |
| 图是否被 `clear` 清掉 | `graph dir` / `graph drop _all` | `clear` 会连内存中的图一起清空；重要图先 `graph save` 或起名 `name(g1)` |
| `by()` 分面是否错位 | 数面板个数，加 `xcommon ycommon` | 某组全为缺失时该面板不出现，面板编号就变了；各面板坐标轴默认各自计算，无法横向比 |
| `ylabel` 刻度是否被重算 | 显式写 `ylabel(0(20)100)` | 自动刻度常出 0、2700、5400 这类步长，投稿前统一成整数区间 |
| 中文字体是否乱码 | `graph set window fontface "Microsoft YaHei"` | Windows 默认字体不含中文，标题图例变方框；导出 PDF 更要显式设字体 |
| 图例顺序对不对 | `legend(order(2 1))`、`legend(label(1 "处理组"))` | 图例编号按**绘图顺序**排，不按数值大小；改顺序要连带核对 `label()` 编号 |
| 调色板是否可读 | `scheme(colorblindr)`、`colorpalette` | 灰度打印和色盲读者都要能区分，别长期只用红/绿这一对 |
| 坐标轴是否被极端值带偏 | `xscale(range(0 120))`、`if` 截样本 | 一个离群值会把整张图压扁；截样本要用 `if`，`range()` 只改显示范围 |
| 图是否可复现 | 选项全部写进 do 文件 | 图形编辑器里的鼠标改动无法复现，能写成代码的一律写代码 |
## ❖ `twoway` （二维图基础容器）
**功能**：几乎所有的散点、折线、拟合图都写在 `twoway` 里，可叠加多个图形。它是绘图家族的总入口，标题、坐标轴、图例这类"整张图"的选项都挂在逗号后面。
**语法**：
```stata
twoway (plot1) (plot2) ... [, options]
```
**参数说明**：

| 写法 | 含义 |
|---|---|
| `twoway (plot1) (plot2)` | 括号分组叠加多层，顺序即绘制顺序 |
| `twoway plot1 || plot2` | 简写形式，`\|\|` 等价于一对方括号分组 |
| `[if] [in]` | 样本条件；写在括号内只影响该层，写在括号外只影响第一层 |
| `, options` | 整张图共用：`title()`、`xtitle()`、`legend()`、`scheme()` |
**常用选项**：
```stata
, title("标题") xtitle("x轴") ytitle("y轴")   // 图标题与轴标题
, legend(rows(2)) scheme(s1color)               // 图例两行、换配色主题
, note("脚注") xlabel(0(10)100)                 // 脚注与手工刻度
, ylabel(, angle(0) grid)                       // 刻度旋转 + 网格线
```
**出图后怎么检查 / 常见坑**：
1. 一个 `twoway` 里只能有一个 `by()`；分面选项写在逗号后的公共部分，写进某个 `( )` 里不生效。
2. 括号位置决定作用域：`twoway (scatter y x if g==1) (scatter y x if g==0)` 是两套独立条件；`twoway (scatter y x) (scatter y x) if g==1` 只有第一层受 `if` 限制。
3. 用 `yaxis(2)` 画双轴时，两条轴都要写 `ytitle()`，否则读者分不清哪条线对应哪条轴。
4. 叠加层数一多，图例按层的顺序排，出图先核对图例文字与线的颜色是否对得上。
**配套命令**：`graph combine` / `graph export` / `graph save` / `set scheme`
**示例**：
```stata
twoway (scatter wage edu) (lfit wage edu)
twoway (scatter wage edu if female==0, mcolor(navy)) ///
       (scatter wage edu if female==1, mcolor(maroon)), ///
       legend(order(1 "男性" 2 "女性")) ytitle("月工资")
```
## ❖ `scatter` （散点图）
**功能**：两变量散点图，观察关系。判断线性趋势、异常值、异方差最直接的一张图。
**语法**：
```stata
twoway scatter y x [, options]
scatter y x [, options]        // 单层简写
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `y` / `x` | 纵轴 / 横轴变量，均须数值型 |
| `jitter(#)` | 在 x 方向加 `1/#` 的随机抖动，缓解散点重叠 |
| `msymbol()` / `mcolor()` / `msize()` | 点的形状 / 颜色 / 大小 |
| `mlabel(varname)` | 给点加标签，一般只用于少量观测 |
**常用选项**：
```stata
, msymbol(circle) mcolor(navy) msize(small)   // 点形状、颜色、大小
, jitter(5)        // 抖动避免重叠
, by(gender)       // 分性别作图
, mlabel(id) mlabel(position(6) size(vsmall)) // 点旁加个案标签
```
**出图后怎么检查 / 常见坑**：
1. `jitter()` 只是"视觉上"错开，横轴数值没变，别在正文里按图目测均值。
2. 点数上千后散点会糊成一团，改用透明度 `mcolor(navy%30)`、缩小 `msize()` 或换 `hexbin`。
3. `by()` 分面后各面板轴范围默认独立，要横向比较必须加 `xcommon ycommon`。
4. 散点图既不显示因果也不显示拟合优度，正式呈现时叠一条 `lfit` 或 `lowess`。
**配套命令**：`lfit` / `lowess` / `graph combine` / `graph export`
**示例**：
```stata
scatter wage edu, jitter(3)
scatter wage edu, by(gender) title("分性别散点")
twoway (scatter wage edu, mcolor(navy%40)) ///
       (lfit wage edu, lcolor(red)), legend(off)
```
## ❖ `line` / `connected` （折线图 / 连线散点）
**功能**：按顺序连线，适合趋势展示。`line` 只画线，`connected` 线加标记点，落在哪一年、哪个取值上一眼能看出。
**语法**：
```stata
twoway line y x [, options]
twoway connected y x [, options]
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `y` / `x` | 纵轴 / 横轴变量；`x` 一般是时间或有序变量 |
| `lcolor()` / `lwidth()` / `lpattern()` | 线的颜色 / 粗细 / 虚实 |
| `msymbol()` / `mcolor()` | `connected` 专用的点形状与点颜色 |
| `sort` | 按 x 排序后再连线（数据未按 x 排序时必加） |
**常用选项**：
```stata
, lcolor(red) lwidth(medium) lpattern(solid)   // 线色、线宽、线型
, sort           // 自动排序 x
, lpattern(dash) lwidth(thick)                 // 强调某一条序列
, msymbol(none)                                // connected 去掉点
```
**出图后怎么检查 / 常见坑**：
1. 少一个 `sort` 就可能画出"来回横跳"的折线——先 `sort x` 或加 `, sort` 再画。
2. `by()` 分面里画折线要在组内排序：`sort groupvar xvar`，否则连线仍按原始观察顺序。
3. 多条线量纲差很远（GDP 与失业率）别硬塞一根 y 轴，改用双轴并明确标注。
4. 横轴只有几个观测点却画得"很平滑"时，标题或脚注要注明数据频率，避免误读。
**配套命令**：`tsline` / `tsconnected` / `graph export` / `scheme`
**示例**：
```stata
tsline gdp          // 时间序列
twoway connected price quantity, sort
sort year
twoway (line gdp year, lcolor(navy)) ///
       (line cons year, lcolor(maroon) lpattern(dash)), ///
       legend(order(1 "GDP" 2 "消费"))
```
## ❖ `lfit` / `qfit` / `lowess` （拟合线）
**功能**：加线性拟合、二次拟合、局部加权回归平滑线。用来在散点图上看"大致形状"，判断线性设定够不够。
**语法**：
```stata
twoway (scatter y x) (lfit y x)
twoway (scatter y x) (qfit y x)
twoway (scatter y x) (lowess y x, bw(0.4))
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `lfit y x` | 一次（直线）拟合线，斜率即 OLS 系数 |
| `qfit y x` | 二次拟合，画抛物线，用来挑非线性 |
| `lowess y x` | 局部加权平滑，不假定函数形式 |
| `bwidth(#)` | `lowess` 带宽，取值 (0,1]，越小越贴数据、越抖 |
**常用选项**：
```stata
, lcolor(red) lpattern(dash) lwidth(medium)   // 与散点区分开
, bwidth(0.4)                                  // lowess 带宽，常用折中
, level(95)                                    // lfitci 的置信水平
, n(100)                                       // lowess 计算点数
```
**出图后怎么检查 / 常见坑**：
1. 拟合线只反映相关形状，图上好看不等于回归显著，两张证据要一起看。
2. `lowess` 的带宽会明显改变结论形态，脚注里最好写明 `bwidth()` 取值。
3. `qfit` 是否成立最终靠回归中 `c.x#c.x` 的显著性，图只是提示。
4. 分组时两条 `lfit` 斜率不同，务必用 `legend` 标清组别，别只靠颜色区分。
**配套命令**：`regress`（取斜率）/ `graph combine` / `graph export`
**示例**：
```stata
twoway (scatter wage edu) (lfit wage edu) (lowess wage edu)
twoway (scatter wage edu, mcolor(gs10)) ///
       (lfitci wage edu, color(navy%20)) ///
       (lfit wage edu, lcolor(navy)), legend(order(2 "95% 置信带" 3 "线性拟合"))
```
## ❖ `histogram` （直方图）
**功能**：变量分布直方图。看偏度、双峰、异常值最快的图。
**语法**：
```stata
histogram varname [, options]
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `bin(#)` / `width(#)` | 分组个数 / 组宽，二者只能选一个 |
| `frequency` / `percent` / `density` | 纵轴口径：频数 / 百分比 / 密度 |
| `normal` / `kdensity` | 叠加正态曲线 / 核密度曲线 |
| `by(varlist)` | 按分类变量分面 |
**常用选项**：
```stata
, bin(20) width(10)   // 分组数与组宽（只能二选一）
, frequency || percent || density(1)   // 纵轴口径
, normal              // 叠加正态曲线
, kdensity            // 叠加核密度
```
**出图后怎么检查 / 常见坑**：
1. `bin()` 与 `width()` 同时写会报错，只能留一个。
2. 叠 `normal` 时纵轴必须切到 `density`，否则曲线与柱子量纲不一致，看着像"曲线贴地"。
3. 组数改变会改变"几个峰"的观感，正文描述分布形状时说明分组方式。
4. 有极端值时先 `summarize, detail` 看范围，必要时 `if` 截尾，别让一根柱子撑满全图。
**配套命令**：`kdensity` / `graph combine` / `graph export` / `summarize, detail`
**示例**：
```stata
histogram wage, bin(30) normal title("工资分布")
histogram wage, by(gender) percent
histogram wage, width(500) density xtitle("月工资") note("组宽 500 元")
```
## ❖ `kdensity` （核密度图）
**功能**：平滑地展示概率密度，比较分布。相比直方图不受分组起点影响，做组间分布对比更稳。
**语法**：
```stata
kdensity varname [if] [in] [, options]
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `bwidth(#)` | 带宽，越小越尖、细节越多也越吵 |
| `kernel()` | 核函数，默认 `epanechnikov` |
| `n(#)` | 计算点数，默认 50，平滑曲线可设 200 以上 |
| `normal` / `by()` | 叠加正态曲线 / 按组求密度 |
**常用选项**：
```stata
, normal          // 叠加正态曲线
, by(gender)      // 分组合并
, bwidth(0.5)     // 带宽
, n(200)          // 提高曲线平滑度
```
**出图后怎么检查 / 常见坑**：
1. 带宽决定"看得见几个峰"，报告前用两三个带宽各画一次，确认结论不随带宽翻转。
2. 两组样本量差很多时，曲线高度不可直接比"谁多"，只比形状。
3. `by()` 分面时各组纵轴默认独立，加 `ycommon` 才能横向比较。
4. 同一张图比较两组要用 `twoway (kdensity ... if ...) (kdensity ...)`，连写两次 `kdensity` 后一张会覆盖前一张。
**配套命令**：`histogram` / `graph combine` / `graph export`
**示例**：
```stata
kdensity wage
kdensity wage, by(gender) legend(label(1 "男") label(2 "女"))
twoway (kdensity wage if treat==1, lcolor(navy)) ///
       (kdensity wage if treat==0, lcolor(maroon) lpattern(dash)), ///
       legend(order(1 "处理组" 2 "对照组"))
```
## ❖ `graph box` / `graph hbar` （箱线图 / 条形图）
**功能**：箱线图看分布与异常值；条形图看均值对比。前者信息量大、适合探索，后者直观、适合汇报。
**语法**：
```stata
graph box y, over(groupvar)
graph bar (mean) y, over(groupvar)
graph hbar (mean) y, over(groupvar)   // 水平条形图
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `(stat)` | 条形图统计量：`(mean)`、`(median)`、`(sum)`、`(count)` |
| `over(groupvar)` | 按分组变量拆类别，可叠两层 `over(a) over(b)` |
| `asyvars` | 多个 y 变量各自成组（自动配色区分） |
| `box()` / `marker()` | 箱线图的箱子样式 / 异常值标记样式 |
**常用选项**：
```stata
, over(gender) ytitle("") legend(off)      // 单分组、去掉多余图例
, asyvars                                   // 多个 y 变量作并列条形
, bar(1, color(navy) fintensity(80))        // 指定某一根柱子的颜色
, blabel(bar, format(%9.2f) size(small))    // 柱顶标数值
```
**出图后怎么检查 / 常见坑**：
1. 条形图默认画的是**均值**，中位数请显式写 `(median)`；偏态分布下均值会误导。
2. `graph box` 标出的异常值按 1.5 倍 IQR 规则判定，出现一长串点先怀疑数据录入。
3. `asyvars` 只在有多个 y 变量时才有意义，单变量加了不报错但无效果。
4. 两类条形图别把 y 轴截断成非零起点，视觉上会夸大差异。
**配套命令**：`graph combine` / `graph export` / `table`（取数核对）
**示例**：
```stata
graph box wage, over(gender) title("分性别工资箱线图")
graph bar (mean) wage, over(edu)
graph hbar (mean) wage, over(edu, sort(1) descending) blabel(bar, format(%9.0f))
```
## ❖ `ecdf` / `cumul` （累积分布函数图）
**功能**：展示累积分布（CDF），用于比较分布是否占优。教育回报、收入分配、政策评估里判断一阶随机占优时常用。
**语法**：
```stata
cdfplot varname if..., by(gender)
twoway (cumul y) (cumul x, lpattern(dash))
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `twoway cumul varname` | 官方内置的累积分布图，纵轴是经验分布比例 |
| `cdfplot` | 外部/扩展命令，各版本可用性不一致，先 `which cdfplot` 确认 |
| `(cumul y)` / `(cumul x)` | 两条 CDF 叠在一张图上比较 |
| `lpattern(dash)` | 让两条曲线在黑白打印下也能区分 |
**常用选项**：
```stata
, lpattern(solid) lwidth(medium)     // 主曲线实线
, lpattern(dash)                     // 对照曲线虚线
, legend(order(1 "处理组" 2 "对照组"))
, xlabel(0(20)100)                   // 累积比例刻度
```
**出图后怎么检查 / 常见坑**：
1. `cdfplot` 不是所有版本都自带，正式使用前先 `which cdfplot`，没有就改用 `twoway cumul`。
2. 判断"占优"看两条曲线是否整段不交叉，局部交叉时不能下"整体更好"的结论。
3. 曲线尾部抖动受小样本影响，极端区间的差异要谨慎解读。
4. 曲线应在 1 处收敛，若图上没到 1，说明样本被 `if` 截过，脚注要交代。
**配套命令**：`graph export` / `graph combine` / `ksmirnov`（分布差异检验）
**示例**：
```stata
twoway (cumul wage if treat==1, lcolor(navy)) ///
       (cumul wage if treat==0, lcolor(maroon) lpattern(dash)), ///
       legend(order(1 "处理组" 2 "对照组")) ytitle("累积比例")
```
## ❖ `histogram` 组合 / `graph combine` （多图合并）
**功能**：把多个图拼接到一个大图。投稿时常把"直方图 + 核密度"或"四个分组的图"拼成一张 Figure。
**语法**：
```stata
graph combine g1 g2 g3, cols(2)
twoway histogram x || kdensity x
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `graph combine namelist` | 合并内存或磁盘上已存在的图，接受图名或文件名 |
| `cols(#)` / `rows(#)` | 指定列数 / 行数 |
| `xcommon` / `ycommon` | 各子图共用坐标轴范围（比较必备） |
| `name(g1)` | 给当前图起名，供 `combine` 调用 |
**常用选项**：
```stata
, cols(2) rows(2)                 // 2×2 排版
, xcommon ycommon                 // 统一坐标轴，便于比较
, title("四组分布对比")            // 合并后的大标题
, imargin(small)                  // 缩小子图间距
```
**出图后怎么检查 / 常见坑**：
1. `graph combine` 只能合并**已存在**的图：先 `name()` 起名或 `graph save` 到磁盘；屏幕上"当前这张"没名字时合并会报错。
2. 大标题用合并的 `title()`，子图标题在各自绘图时写，两边别重复。
3. 不加 `xcommon ycommon` 的子图各用各的刻度，拼在一起极易被误读成"量级不同"。
4. 直方图叠核密度两边纵轴口径要一致（都用 `density`），否则曲线被压成贴地线。
**配套命令**：`graph save` / `graph use` / `graph export`
**示例**：
```stata
twoway (histogram wage, density) || (kdensity wage)
histogram wage if female==0, name(h1, replace) title("男性")
histogram wage if female==1, name(h2, replace) title("女性")
graph combine h1 h2, cols(2) xcommon ycommon title("工资分布对比")
```
## ❖ `graph export` / `graph save` （图形导出）
**功能**：把图形保存为图片文件（png/pdf/eps/tif）。交给 Word、LaTeX 或期刊的最终产物就是这一步的输出。
**语法**：
```stata
graph export "fig1.png", replace width(3000)
graph save "fig.gph", replace
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `filename` | 输出文件名，扩展名决定格式（`.png`/`.pdf`/`.eps`/`.tif`） |
| `replace` | 覆盖同名文件；不写则文件已存在时报错 |
| `width(#)` / `height(#)` | 位图像素尺寸，只给一个时按比例推算另一个 |
| `name(graphname)` | 导出指定图名的图，而非屏幕上当前那张 |
**常用选项**：
```stata
, width(4000) height(2500)   // 像素（高清）
, replace                     // 覆盖旧文件
, name(g1)                    // 导出名为 g1 的图
```
**出图后怎么检查 / 常见坑**：
1. 不带 `replace` 时第二次运行 do 文件会因"文件已存在"中断；正式脚本一律加 `replace`。
2. 位图 `width()` 太小是投稿被退回的高频原因，3000 像素起步；矢量图（pdf/eps）不需要 `width()`。
3. `graph export` 导出的是当前图或 `name()` 指定的图，`graph combine` 之后要导出合并后的那张。
4. 中文图若字体没设好，屏幕上正常、导出 PDF 里却是方框，导出后一定打开文件肉眼确认。
**配套命令**：`graph combine` / `graph save` / `graph dir` / `set scheme`
**示例**：
```stata
histogram wage, normal
graph export "wage_hist.png", width(3000) replace
graph export "fig_main.pdf", replace          // 投稿用矢量图
```
## ❖ 图例与主题：`scheme` / `graph set`
**功能**：切换配色主题，`s1color`、`s2color`、`economist` 等。一次 `set scheme` 之后的每张图都按该主题出图，是统一整套图风格最省力的做法。
**语法**：
```stata
set scheme s1color
graph set window fontface "SimHei"    // 中文字体
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `set scheme name` | 设定后续所有图的默认主题，只影响之后的图 |
| `scheme(name)` | 只在当前这张图上临时换主题，优先级更高 |
| `graph set window fontface` | 设置图形窗口默认字体（影响中文显示） |
| `graph query` / `graph set` | 查看当前图形设置 |
**常用选项**：
```stata
set scheme s1color                  // 白底细线，论文最常用
set scheme s2color                  // 传统 Stata 蓝底
graph set window fontface "Microsoft YaHei"   // 中文字体
graph set window fontface "SimHei"            // 黑体备选
```
**出图后怎么检查 / 常见坑**：
1. `set scheme` 只对**之后**画的图生效，已画好的图不受影响，脚本里要写在最前面。
2. `economist` 等主题在部分版本需先安装，报错就改用 `s1color`。
3. 中文建议写 `"Microsoft YaHei"` 或 `"SimHei"`，导 PDF 后打开确认没有方框。
4. 换主题会连带改坐标轴、网格、图例位置，换完要重看 `legend` 有没有被挤出画面。
**配套命令**：`graph export` / `graph combine` / `s1color`、`s2color`、`colorblind` 等主题
**示例**：
```stata
set scheme s1color
graph set window fontface "Microsoft YaHei"
scatter wage edu, scheme(economist)
```
## ❖ 坐标轴控制：`xlabel` / `ylabel` / `xticks` / `yticks`
**功能**：精确控制坐标轴刻度、范围、间隔与格式。图"好不好看"的八成在于轴刻度有没有被收拾过。
**语法**：
```stata
, xlabel(0(5)100)        // 0 到 100，步长 5
, xlabel(10 20 30 "自定义" 40)   // 自定义刻度与标签
, ylabel(, angle(45))    // 刻字旋转，避免重叠
, ylabel(, grid)         // 加水平网格线
, xscale(range(0 120))   // 强制 x 轴范围
, xtick(5(5)95)          // 只加小刻度不标数字
```
**参数说明**：

| 写法 | 含义 |
|---|---|
| `xlabel(a(b)c)` | 从 a 到 c、步长 b 的刻度与标签 |
| `xlabel(10 20 30 "自定义" 40)` | 手工列刻度，引号内替换该刻度的显示文字 |
| `xlabel(, angle(45))` | 只给子选项：旋转标签；`labsize()`、`labcolor()` 同类 |
| `xscale(range(a b))` | 仅扩展显示范围，**不删除数据**（范围外的点被裁掉） |
| `xtick()` / `xmtick()` | 小刻度（不标数字）/ 更细的次刻度 |
**常用选项**：
```stata
, xlabel(0(5)20) ylabel(0(200)1200, angle(0))   // 主刻度
, ylabel(, grid gstyle(dot))                     // 点状网格线
, ylabel(, nogrid)                               // 去掉网格
, ylabel(#6)                                     // 让 Stata 自挑约 6 个刻度
```
**出图后怎么检查 / 常见坑**：
1. 想刻度"好看"就自己写步长；交给自动算法常出现 2700、5400 这类读数。
2. `xscale(range())` 只改显示范围，图外的点直接消失；要截样本请用 `if`。
3. 标签太长先 `angle(45)` 或 `labsize(small)`，再考虑换缩写变量名。
4. `grid`/`nogrid` 写在括号逗号后；写成 `ylabel(grid)` 会被当成刻度值而报错。
5. 双轴图 `yaxis(2)` 的刻度要单独用 `ylabel(..., axis(2))` 指定。
**配套命令**：`xtitle` / `ytitle` / `scheme` / `graph export`
**示例**：
```stata
scatter wage edu, xlabel(0(5)20) ylabel(0(100)1000, angle(0))
twoway line gdp year, xlabel(1990(5)2020, angle(45)) ///
    ylabel(0(5000)20000, format(%9.0gc)) ytitle("GDP（亿元）")
```
## ❖ 坐标轴标题与刻度标签：`xlabel(..., labels(...))` / 旋转
**功能**：处理长变量名或日期标签的换行与角度，以及在关键年份、关键取值处加参考线。
**语法**：
```stata
, xlabel(, labcolor(navy) labsize(small))
, xlabel(, angle(45) labsize(small))     // 日期/长标签常用
, ylabel(, nogrid)                       // 去掉网格
, xline(2010, lcolor(red) lpattern(dash)) // 在某处画竖线（断点）
, yline(0, lpattern(dash))                // 在 y=0 画横线
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `labcolor()` / `labsize()` | 刻度标签的颜色 / 字号 |
| `angle(#)` | 标签旋转角度，长标签防重叠 |
| `format(%…)` | 标签数字格式，如 `%9.0gc` 带千分位 |
| `xline(#)` / `yline(#)` | 竖参考线 / 横参考线，可一次给多个值 |
**常用选项**：
```stata
, xline(2010, lcolor(red) lpattern(dash))    // 政策年竖线
, yline(0, lcolor(black) lpattern(dot))      // 零线
, ylabel(, angle(0) labsize(small))          // 小字号、不旋转
, xtitle("")                                  // 去掉轴标题
```
**出图后怎么检查 / 常见坑**：
1. `xline()`/`yline()` 是**参考线**不是数据线，图例里不会出现，正文要交代它代表什么。
2. 多条参考线写成 `xline(2008 2015, lpattern(dash))`，样式对所有线同时生效。
3. 参考线颜色别和数据线撞色，灰色 `gs8` 配虚线最稳。
4. 轴标题和参考线说明别都堆在 `note()` 里，脚注最多两行。
**配套命令**：`xlabel` / `ylabel` / `graph export` / `scheme`
**示例**：
```stata
twoway line gdp year, xline(2010) yline(0)   // 政策年画竖线
twoway line gdp year, xline(2008, lcolor(gs8) lpattern(dash)) ///
    xlabel(1995(5)2020, angle(45) labsize(small)) note("虚线为政策实施年")
```
## ❖ 图例控制：`legend`
**功能**：图文例（每个图形对应的图例文字）。图例错位、编号错乱是审稿意见里最常见的图形问题之一。
**语法**：
```stata
, legend(label(1 "处理组") label(2 "对照组"))   // 第1/2个图的图例
, legend(rows(1))                               // 1 行排开
, legend(order(2 1))                            // 调整显示顺序
, legend(off)                                   // 关闭图例
, legend(position(6) ring(0))                   // 位置 6=底中
, legend(cols(2))                               // 2 列
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `label(# "文字")` | 替换第 # 层的图例文字，编号按绘图顺序 |
| `order(# # …)` | 图例显示顺序，`order(2 1)` 表示第 2 层放前面 |
| `rows(#)` / `cols(#)` | 图例排列行数 / 列数 |
| `position(#)` / `ring(#)` | 位置码 1–12（顺时针，12 在正上）；`ring(0)` 才挪进绘图区 |
**常用选项**：
```stata
, legend(rows(1) position(6) ring(0))         // 图内底部一行
, legend(order(1 "2010" 2 "2015" 3 "2020"))   // 顺序 + 文字一起改
, legend(region(lcolor(none)))                // 去掉图例边框
, legend(size(small) symxsize(*0.6))          // 缩小图例符号
```
**出图后怎么检查 / 常见坑**：
1. `label()` 里的编号是**绘图顺序**，不是变量在数据里的顺序；叠三层就按 `( )` 出现的先后数 1、2、3。
2. `order()` 只改显示顺序、不改编号含义；与 `label()` 同用时先对一遍编号。
3. `position()` 是钟点位；不写 `ring(0)` 时图例只能放图外。
4. `by()` 分面后图例默认只出现一次，各面板含义不同就改用 `b1title()` 之类的子图标题。
**配套命令**：`by()` / `graph combine` / `scheme` / `graph export`
**示例**：
```stata
twoway (kdensity wage if treat==1) (kdensity wage if treat==0), ///
       legend(label(1 "处理组") label(2 "对照组") position(6))
twoway (line gdp year) (line cons year), ///
       legend(order(2 "消费" 1 "GDP") rows(1) region(lcolor(none)))
```
## ❖ 子图分面：`by()` / `by()` 组合
**功能**：按分类变量拆分成多个小图（一面），适合比较。做异质性展示、分组描述时比堆在一张图上更清楚。
**语法**：
```stata
histogram wage, by(gender)
scatter wage edu, by(year, cols(2) title(""))    // 按年份拆分，2列
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `by(varlist)` | 一个或多个分类变量，多个变量形成嵌套分面 |
| `cols(#)` / `rows(#)` | 面板的列数 / 行数 |
| `total` | 额外增加一个"全样本"面板 |
| `title("")` / `note("")` | 清掉每个面板重复的标题 / 脚注 |
**常用选项**：
```stata
by(region, cols(3) title("各省") note(""))
by(treat, legend(off))
by(gender, total cols(3) ycommon)      // 加全样本面板、统一纵轴
```
**出图后怎么检查 / 常见坑**：
1. 缺组会少一个面板：面板数和 `tab` 出来的类别数对不上时，先 `tab byvar, missing` 查缺失与空组。
2. 各面板默认各算各的坐标轴，横向比较前加 `xcommon ycommon`，否则"看着差不多"其实量级差十倍。
3. `by()` 里画折线要组内排序：先 `sort byvar xvar` 再画。
4. 面板超过 3×3 会挤成一堆小图，改用 `graph combine` 手工挑图。
**配套命令**：`graph combine` / `graph bar` 的 `over()`（同类分面思路）/ `graph export`
**示例**：
```stata
scatter wage edu, by(gender year, cols(2))
bysort gender (edu): scatter wage edu, by(gender, cols(2) ycommon)
tab region, missing          // 先确认有几组、有没有缺失
histogram wage, by(region, cols(3) ycommon title("分地区工资分布"))
```
## ❖ 图形叠加：`||`（双竖线简写）
**功能**：`||` 是 `( … )` 分组的简写，用来快速叠加多层图形。写起来短，层数一多也比嵌套括号好读。
**语法**：
```stata
twoway scatter y x || lfit y x
twoway line gdp year || line unemp year
```
**参数说明**：

| 写法 | 含义 |
|---|---|
| `plot1 || plot2` | 把两层图叠加，`\|\|` 前不加逗号 |
| `(plot1, opts) \|\| (plot2, opts)` | 每层单独给选项时必须保留括号 |
| `plot1 \|\| plot2, options` | 逗号后的选项作用于整张图 |
| `\|\|` 与 `( )` | 二者完全等价，可以混用 |
**常用选项**：
```stata
, legend(order(1 "散点" 2 "拟合线"))     // 叠加后一定要核对图例
, yaxis(2)                               // 量纲差太多时用第二纵轴
```
**出图后怎么检查 / 常见坑**：
1. `||` 前面不要再加逗号；写成 `twoway scatter y x, || lfit y x` 会报错。
2. 每层要单独设样式就必须带括号：`(lfit y x, lcolor(red)) || ...`。
3. 叠加顺序决定图例编号，也决定谁画在上面：后画的层覆盖先画的层。
4. 用 `yaxis(2)` 时两层各自指定 `yaxis(1)`/`yaxis(2)`，两条轴标题都写清楚。
**配套命令**：`twoway` / `legend` / `graph export`
**示例**：
```stata
twoway (scatter wage edu) || lowess wage edu
twoway (scatter wage edu, mcolor(gs10)) || ///
       (lfit wage edu, lcolor(navy)), ///
       legend(order(1 "样本" 2 "OLS 拟合"))
```
## ❖ 图形保存为 gph & 重新编辑：`graph save` / `graph use` / `graph display`
**功能**：保存为可再编辑的 .gph 文件，之后 `graph use` 再次打开、`graph display` 显示的窗口。`.gph` 保留全部绘图结构，改完再导图比图片格式灵活。
**语法**：
```stata
graph save "fig.gph", replace
graph use "fig.gph"
graph display NameOfGraph
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `graph save name, replace` | 把当前图存成 `.gph`（不带扩展名自动补） |
| `graph use "file.gph"` | 读回磁盘上的图，成为当前图 |
| `graph display gname` | 把内存中名为 `gname` 的图显示出来 |
| `graph dir` / `graph drop` | 列出内存中所有图名 / 删除指定图 |
**常用选项**：
```stata
, replace          // 覆盖同名 .gph
, as("fig2")       // 另存为另一个名字
, name(g1, replace) // 绘图时直接起名，不必先画再 save
```
**出图后怎么检查 / 常见坑**：
1. 内存中的图是临时的：`clear`、重跑绘图都会让它消失，重要图立刻 `graph save`。
2. `graph use` 把图读成**当前图**，之前未保存的当前图会被覆盖。
3. `graph display g1` 只能显示内存中的命名图；只在磁盘上的要先 `graph use`。
4. 用 `graph dir` 核对图名有没有拼错，图名区分大小写。
**配套命令**：`graph export` / `graph combine` / `graph drop` / `graph dir`
**示例**：
```stata
scatter wage edu
graph save "fig.gph", replace
graph use "fig.gph"
scatter wage edu, name(sc1, replace)
graph display sc1
```
## ❖ 颜色与线型/点型系统（通用选项）
**功能**：控制所有图的中 `color`、`lpattern`、`msymbol`。黑白打印、色盲读者、投影仪偏色三种场景都能靠这套选项兜住。
**语法**：
```stata
, lcolor(navy) lwidth(thick) lpattern(dash dashed dot longdash)
, mcolor(red) msymbol(circle square triangle diamond) msize(medium)
, connect(ascending)      // 连线方式
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `lcolor()` / `mcolor()` | 线色 / 点色，可加透明度如 `navy%40` |
| `lwidth()` | 线宽：`thin`、`medium`、`thick`、`vthick` |
| `lpattern()` | 线型：`solid`、`dash`、`dot`、`dash_dot`、`longdash` |
| `msymbol()` / `msize()` | 点形状（`O` 圆、`S` 方、`T` 三角、`D` 菱形）/ 点大小 |
| `connect()` | 连线方式：`direct`、`ascending`、`descending`、`L` |
**常用选项**：
```stata
, lcolor(navy) lwidth(medium) lpattern(solid)   // 主序列：实线深蓝
, lcolor(maroon) lpattern(dash)                 // 对照序列：虚线暗红
, msymbol(S) msize(small) mcolor(gs6)            // 灰点方块，黑白打印也清楚
, lwidth(none)                                   // 隐藏边框线
```
**出图后怎么检查 / 常见坑**：
1. 合法线型有 `solid`、`dash`、`dot`、`dash_dot`、`longdash`、`shortdash`，**没有** `dashed`；写了 `dashed` 会报错，请改 `dash`。
2. 颜色之外一定再配线条/形状差异，只靠颜色在黑白复印和色盲读者那里会失效。
3. 透明度写法是颜色后加百分号（`navy%40`），不是 `alpha()`。
4. `msymbol(O)` 与 `msymbol(o)` 大小写不同、效果不同，别随手写。
**配套命令**：`scheme` / `legend` / `graph export` / `colorpalette`（取色板）
**示例**：
```stata
twoway (scatter wage edu, msymbol(circle) mcolor(navy)) ///
       (lfit wage edu, lcolor(red) lpattern(dash) lwidth(thick))
twoway (line gdp year, lcolor(navy)) ///
       (line cons year, lcolor(gs6) lpattern(dash)), ///
       legend(order(1 "GDP" 2 "消费") rows(1))
```
## ❖ `coefplot` （回归系数图——第三方，需安装）
**功能**：把回归系数连同置信区间画成横向点图，是呈现核心结果最漂亮的方式。多个模型并排对比时比表格更直观。
**语法**（`ssc install coefplot`）：
```stata
regress wage edu exp i.region
coefplot, drop(_cons)            // 去掉常数项
coefplot, xline(0) xlabel(-1(0.2)1)
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `drop(...)` / `keep(...)` | 不显示 / 只显示哪些系数（变量名或 `_cons`） |
| `xline(0)` | 在 0 处画参考线，判断系数是否跨零 |
| `levels(#)` | 置信水平，默认 95 |
| `vertical` | 改为竖排（系数在 x 轴） |
**常用选项**：
```stata
, drop(_cons)         // 不显示常数
, xline(0)            // 在 0 处画参考线
, levels(90)          // 置信水平
, vertical            // 竖排
, coeflabels(edu "受教育年限" exp "工作经验")   // 中文标签
```
**出图后怎么检查 / 常见坑**：
1. `coefplot` 不是官方命令，换台电脑要先 `ssc install coefplot`，do 文件里写明安装步骤。
2. 用 `i.region` 这类因子变量时横轴标签是 `2.region` 一长串，用 `coeflabels()` 改成中文。
3. 忘写 `drop(_cons)`，常数项会把整张图拉宽，其他系数挤成一团。
4. 多模型并排（`coefplot m1 m2`）时 `drop()` 要一致，否则系数位置错行。
**配套命令**：`regress` / `estimates store` / `graph export` / `graph combine`
**示例**：
```stata
regress y treat post did
coefplot did, xline(0) title("DID 交互项系数")
regress wage edu exp i.region
coefplot, drop(_cons) xline(0) ///
    coeflabels(edu "受教育年限" exp "工作经验") title("工资方程系数")
```
## ❖ 时间序列画图：`tsline` / `tsconnected` / `tsrline`（需先 `tsset`）
**功能**：时间序列专用画图，自动处理时间轴。刻度会按季度、月份、年份自动识别，比 `twoway line` 少踩格式坑。
**语法**：
```stata
tsset date
tsline gdp unemp, legend(label(1 "GDP") label(2 "失业率"))
tsline gdp, tlabel(1990(5)2015, angle(45))   // 时间刻度
tsrline y, level(95)                          // 画收益与波动带
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `tsset timevar` | 声明时间变量，必须先做；面板数据用 `xtset` |
| `tsline varlist` | 画一条或多条时间序列 |
| `tsconnected varlist` | 时间序列 + 数据点 |
| `tlabel(...)` | 时间轴刻度，如 `tlabel(1990(5)2015, angle(45))` |
**常用选项**：
```stata
, tlabel(1990(5)2015, angle(45))     // 每 5 年一个刻度并旋转
, tlabel(#10, format(%ty))            // 让 Stata 自挑约 10 个刻度
, lcolor(navy) lpattern(solid)        // 逐条设样式
, legend(rows(1))                      // 多条序列时图例排一行
```
**出图后怎么检查 / 常见坑**：
1. 忘了 `tsset` 会直接报 "time variable not set"；`tsline` 只适用于纯时间序列，面板要用 `xtline`。
2. 季度/月度数据导图后时间标签易重叠，加 `angle(45)` 或 `tlabel(#8)`。
3. 量纲差很远的变量画在一根轴上会互相压扁，改用 `yaxis(2)` 或分开画再 `graph combine`。
4. `tsrline` 依赖前一步的时序设定，换数据后要重跑 `tsset`。
**配套命令**：`tsset` / `twoway line` / `graph combine` / `graph export`
**示例**：
```stata
tsset year
tsline gdp
tsline gdp unemp, title("宏观走势")
tsline gdp unemp, tlabel(1990(5)2020, angle(45)) ///
    legend(order(1 "GDP" 2 "失业率") rows(1))
```
## ❖ 容忍图 / 误差带：`rarea` / `rspike` / `marginsplot`
**功能**：用 `rarea/rspike` 叠加置信区间带，或直接 `marginsplot`。把"估计值 + 不确定区间"画出来，比只画一条点估计线诚实得多。
**语法**：
```stata
margins x, at(...)
marginsplot
twoway rarea lower upper x     // 手工叠加置信带
```
**参数说明**：

| 参数 | 含义 |
|---|---|
| `twoway rarea y1 y2 x` | 在 y1 与 y2 之间填色，用来画置信带 |
| `twoway rspike y1 y2 x` | 在 y1 与 y2 之间画竖线（区间线） |
| `margins, at(var=(a(b)c))` | 在指定取值点计算预测值 / 边际效应 |
| `recastci()` | 置信区间的呈现形式，如 `recastci(rarea)` |
**常用选项**：
```stata
, at(age=(20(10)60))                    // 在 20 到 60 岁、每 10 岁取点
, recastci(rarea)                        // 用色带画置信区间
, ciopts(fcolor(navy%20) lcolor(navy%40)) // 色带颜色与透明度
, xdimension(age)                         // 指定横轴变量
```
**出图后怎么检查 / 常见坑**：
1. `marginsplot` 与 `margins` 是一对，中间插了别的估计命令图就画不出来；对比两个模型先 `estimates store`。
2. `at()` 取值超出样本范围属于外推，图上要注明或改用样本内取值。
3. 手写 `twoway rarea` 时 `lower`/`upper` 要先算好，且 `y1 < y2`，顺序反了会画出空白。
4. `rarea` 默认填充很深，会盖住散点，务必用 `fcolor(...%20)` 加透明度并画在最底层。
**配套命令**：`margins` / `marginsplot` / `twoway` / `graph export`
**示例**：
```stata
probit y edu age
margins, at(age=(20(10)60))
marginsplot
regress wage edu
predict fitted, xb
predict se, stdf
gen lo = fitted - 1.96*se
gen hi = fitted + 1.96*se
twoway (rarea lo hi edu, fcolor(navy%20) lwidth(none)) ///
       (line fitted edu, lcolor(navy)), legend(off)
```

---

# 附录 C · 常用细节 / 回归后诊断命令（Post-estimation & Details）

---

## 📋 本章速查：回归后该做的检验清单

> 回归跑完不等于做完。下表是"一篇规范实证论文在基准回归之后至少要过一遍"的清单。**顺序建议**：先共线性与函数形式（设定问题）→ 再异方差、自相关（推断问题）→ 最后影响点与正态性（稳健性问题）。

| 检查什么 | 命令 | 适用模型 | 判定标准 |
|----------|------|----------|----------|
| 多重共线性 | `estat vif`（或 `vif`） | `regress` 之后；`xtreg, re` 可用；**`xtreg, fe` 后不可用**，改用 `regress y x i.id` | VIF>10 严重共线，VIF>5 需警惕；1/VIF<0.1 说明该变量几乎被其余变量线性解释 |
| 异方差（BP / Cook–Weisberg） | `estat hettest` | `regress` 等线性估计之后（需非稳健拟合） | H0：同方差；p<0.05 拒绝 → 报 `, robust` 标准误 |
| 异方差（White） | `estat imtest, white` | 同上 | H0：同方差；p<0.05 拒绝 → 用稳健或聚类标准误 |
| 自相关（DW） | `estat dwstat` | `tsset` 后的时间序列 `regress` | DW≈2 无自相关；明显小于 2 提示正自相关（约 1.5–2.5 可接受） |
| 自相关（Breusch–Godfrey） | `estat bgodfrey, lags(p)` | `tsset` 后的时间序列 `regress`（含滞后因变量也适用） | H0：无 p 阶自相关；p<0.05 拒绝 → `newey` 的 HAC 标准误 |
| 函数形式/遗漏非线性项 | `estat ovtest` | `regress` 之后（Ramsey RESET） | H0：无遗漏高阶项；p<0.05 提示设定有误 |
| 影响点/强影响观测 | `predict`, `lvr2plot`, `predict cooksd` | 线性 `regress` 之后 | Cook's D>4/N 需逐个核查；杠杆-残差平方图中远离参考线的点要复核 |
| 正态性 | `sktest`, `swilk` | 任意变量（残差先用 `predict e, resid`） | H0：正态；p<0.05 拒绝。大样本过于敏感，重点看偏度峰度 |
| 系数线性约束 | `test`, `testparm`, `lincom` | 几乎所有 `e()` 类估计命令之后 | H0：约束成立；p<0.05 拒绝。`lincom` 直给估计值、标准误与 CI |
| 面板：FE vs RE | `hausman` | `xtreg, fe` 与 `xtreg, re` 成对之后 | p<0.05 拒绝 RE 的一致性 → 用 FE |
| 面板：组间异方差/序列相关 | `xttest3` / `xtserial`（第三方） | `xtreg` 之后 | p<0.05 → `xtreg, fe vce(cluster id)` 或 `xtgls` |

> ⚠️ 三条铁律：①`estat` 只能紧跟估计命令，中间插入估计命令它就检验新模型；②`estat hettest`/`estat imtest` 要求非稳健拟合，先 `regress` 检验、再加 `, robust` 重跑；③检验的 `r()` 会被下一条 r 类命令覆盖，要留用立刻 `scalar`/`local` 存下。

---

## ❖ `vif` （多重共线性检验 VIF）

- **1. 功能**：回归后检查自变量间是否高度线性相关。VIF 越大系数方差被放大得越厉害（标准误膨胀、显著性下降乃至符号反转）；VIF>10 视为严重共线。

- **2. 语法**：
  ```stata
  regress depvar indepvars
  vif
  estat vif            // 等价写法
  ```

- **3. 参数说明**：

| 参数 | 说明 |
|------|------|
| （无参数） | `vif` 不接受变量列表，总是对"上一次回归的全部自变量"计算 |
| `vif` / `estat vif` | 官方两条写法，输出完全相同 |

- **4. 输出结果/返回值**：表格列出每个自变量的 `VIF` 与 `1/VIF`（容忍度），末行 `Mean VIF` 为均值；`VIF_j = 1/(1-R_j²)`，`R_j²` 是该变量对其余自变量回归的 R²。`vif` **不保存常用的 `r()` 标量**（无法 `display r(vif)`），也不改动 `e()`，之后仍可 `predict`、`test`。

- **5. 常用选项**：
  ```stata
  regress y x1 x2 x3
  vif                    // 看 VIF、1/VIF、Mean VIF
  estat vif              // 等价写法
  // vif 无"只挑几个变量"的选项，只看部分变量就重跑一个小回归
  regress y x1 x2
  vif
  ```

- **6. 配套检验/联动命令**：
  - `corr x1 x2 x3`：先看两两相关，定位"哪两个变量打架"。
  - `testparm x1 x2 x3`：共线常表现为"整体 F 显著、单个系数都不显著"，用它确认联合显著性。
  - `regress y x i.id`：`xtreg, fe` 之后不能 `estat vif`，用这种写法近似看组内共线。

- **7. 常见坑**：
  - `xtreg, fe` 之后 Stata 拒绝 `estat vif`（组内均值已减掉）；改 `xtreg, re` 或用 `regress y x i.id`。
  - `vif x1 x2` 是语法错——它不给变量列表。
  - 二次项、交互项与主效应天然高度相关（可先去均值），此时 VIF 高不一定是病；共线只放大方差、不产生偏误。
  - 常数项不参与 VIF 计算，别把 `_cons` 的异常当共线。

- **8. 示例**：
  ```stata
  sysuse auto, clear
  regress price mpg weight length
  vif
  regress price mpg weight        // 删掉最可疑的变量再看
  estat vif
  ```

---

## ❖ `estat hettest` / `estat imtest` （异方差检验）

- **1. 功能**：检验残差是否同方差。`estat hettest` 为 Breusch–Pagan / Cook–Weisberg 检验（默认用拟合值 ŷ 作辅助回归变量）；`estat imtest, white` 为 White 检验（用所有自变量的平方与交叉乘积）。流程是"先检验、再决定要不要 `, robust`"。

- **2. 语法**：
  ```stata
  regress depvar indepvars
  estat hettest [varlist] [, iid fstat rhs]
  estat imtest [, white]
  ```

- **3. 参数说明**：

| 参数 | 说明 |
|------|------|
| `estat hettest` | 默认用 ŷ 作辅助回归变量（Cook–Weisberg 版） |
| `, rhs` / `, iid` / `, fstat` | 改用全部自变量 / 假定 iid 误差 / 报 F 形式（小样本更稳） |
| `estat imtest, white` | White 检验：含平方项与交叉乘积项 |

- **4. 输出结果/返回值**：屏幕给检验名、卡方（或 F）、自由度与 p 值。`r(chi2)` 统计量、`r(df)` 自由度、`r(p)` p 值（最常用，程序中判断"p<0.05 就改 robust"全靠它；具体名称可用 `return list` 现场核实）。检验不改动 `e()`，但 `r()` 会被下一条 r 类命令覆盖。

- **5. 常用选项**：
  ```stata
  regress y x1 x2
  estat hettest            // 默认 BP（用 yhat）
  estat hettest, rhs       // 用全部自变量做辅助回归
  estat hettest, fstat     // 报 F 统计量
  estat imtest, white      // White 检验
  ```

- **6. 配套检验/联动命令**：
  - `rvfplot` / `rvpplot x1`：残差-拟合值 / 残差-自变量图，肉眼找"喇叭口"，并定位来源变量。
  - `regress y x1 x2, robust`：检验拒绝同方差后的标准做法（等价 `vce(robust)`）。
  - `estat ovtest`：函数形式检验，常与异方差一起出问题。

- **7. 常见坑**：
  - 两条检验都基于**非稳健**拟合；先跑了 `regress, robust` 再检验会报错或结果不可信，正确顺序是"`regress` → 检验 → 加 `, robust` 重跑"。
  - `estat` 只能紧跟估计命令：中间插 `summarize` 无妨，插 `regress`/`logit` 就换了检验对象。
  - White 检验在自变量多、样本小时自由度极大，几乎必然不显著，别当唯一标准；检验不显著也不等于可以不报稳健标准误。
  - 面板的组间异方差用 `xttest3`（第三方），不是 `estat hettest`。

- **8. 示例**：
  ```stata
  sysuse auto, clear
  regress price mpg weight
  estat hettest
  estat imtest, white
  regress price mpg weight, robust   // 若 p<0.05
  ```

---

## ❖ `estat dwstat` / `estat bgodfrey` （自相关检验）

- **1. 功能**：检验时间序列回归残差是否存在序列相关。`estat dwstat` 给 Durbin–Watson 统计量（仅一阶）；`estat bgodfrey` 为 Breusch–Godfrey 检验，可查任意 p 阶、且允许模型含滞后因变量（含 `L.y` 时 DW 失效）。两者都要求先 `tsset`。

- **2. 语法**：
  ```stata
  tsset timevar
  regress depvar indepvars
  estat dwstat
  estat bgodfrey [, lags(#)]
  ```

- **3. 参数说明**：

| 参数 | 说明 |
|------|------|
| `tsset timevar` | 必须先声明时间变量，否则两条 `estat` 无法计算 |
| `estat dwstat` | 输出 DW 统计量（约 0–4，2 表示无自相关） |
| `lags(#)` | BG 检验的滞后阶数；不写用默认阶数（屏幕会显示） |

- **4. 输出结果/返回值**：屏幕给 DW 统计量或 BG 的卡方/自由度/p 值；要编程取用请跑完立刻 `return list` 核对本版本的 `r()` 名称（版本间命名有差异，不要凭记忆硬写）。判断口径：DW 接近 2 无一阶自相关，明显小于 2 为正自相关（宏观时序常见），大于 2 为负自相关（少见）。检验不改动 `e()`。

- **5. 常用选项**：
  ```stata
  tsset date
  regress gdp money
  estat dwstat              // DW（一阶）
  estat bgodfrey, lags(1)   // 一阶 BG
  estat bgodfrey, lags(4)   // 季度数据常用 4 阶
  ```

- **6. 配套检验/联动命令**：
  - `newey y x, lag(#)`：存在自相关时的标准做法，直接给 HAC（Newey–West）标准误。
  - `prais y x`：一阶自相关下的可行 GLS（Prais–Winsten）。
  - `ac y` / `corrgram y`：看各阶自相关系数，判断阶数。
  - `xtserial y x`（第三方）：面板的 Wooldridge 序列相关检验。

- **7. 常见坑**：
  - 忘 `tsset` 直接 `estat dwstat` 会报错；声明后别再 `sort` 打乱顺序。
  - DW 只能查一阶且模型不能含滞后因变量；含 `L.y` 请用 `estat bgodfrey` 或 `estat durbinalt`。
  - 时间序列里 `, robust` 只解决异方差，**不能**解决自相关，必须 `newey` 或 `vce(hac ...)`。
  - 面板（`xtset` 后）不提供 `estat dwstat`，别硬试。

- **8. 示例**：
  ```stata
  sysuse gnp96, clear
  tsset date
  regress gnp L.gnp
  estat bgodfrey, lags(1)
  newey gnp L.gnp, lag(2)          // 拒绝无自相关后
  ```

---

## ❖ `predict` （生成预测值与残差）

- **1. 功能**：估计命令之后，把拟合值、残差、标准误、概率、杠杆值、Cook's D 等写成数据里的新变量，是"诊断 → 作图 → 进一步检验"的枢纽。

- **2. 语法**：
  ```stata
  predict newvar [, statistic]
  ```
  一次只能指定一个统计量；不写选项默认 `xb`（线性预测值）。

- **3. 参数说明**：

| 参数 | 说明 |
|------|------|
| `newvar` | 新变量名，不能与已有变量同名 |
| `, xb` / `, residuals` | 线性预测值 xβ / 残差（可缩写 `resid`、`res`） |
| `, stdp` / `, stdf` | 预测值标准误（置信带）/ 预测误差标准误（预测区间） |
| `, pr` | 事件发生概率（`logit`/`probit` 等二值模型） |
| `, hat` / `, cooksd` / `, rstudent` | 杠杆值 / Cook's D / 学生化残差 |

- **4. 输出结果/返回值**：`predict` **不返回 `r()`/`e()`**，输出就是数据集里的新变量；新变量只在 `e(sample)==1` 的观测上有值，其余为 `.`（所以残差图常"少一半"）。可用 `summarize`、`count if missing(newvar)` 检查；回归 `e()` 不被破坏，可连续多次 `predict`。

- **5. 常用选项**：
  ```stata
  regress y x1 x2
  predict yhat            // 默认 = xb，拟合值
  predict e, resid        // 残差
  predict se, stdp        // 拟合值标准误
  predict d, cooksd       // Cook's D
  logit y x1 x2
  predict p, pr           // 预测概率（0–1）
  ```

- **6. 配套检验/联动命令**：
  - `rvfplot` / `lvr2plot`：异方差图 / 杠杆-残差平方图（标出强影响点）。
  - `sktest e` / `swilk e`：残差正态性检验。
  - `twoway scatter yhat e`：自定义残差图，比内置命令灵活。

- **7. 常见坑**：
  - 一次只能写一个统计量：`predict e, resid stdp` 会报错，要写两条。
  - 选项依赖命令：`, pr` 只对二值/有序模型有效，`regress` 之后写会报错。
  - `predict e` 默认给的是**拟合值**，忘了 `, resid` 却拿去当残差用，是新手最常见的错。
  - 变量已存在报 `already defined`，先 `drop` 或改名；`,` 后多余的选项不会被静默忽略。
  - `regress, robust` 之后 `predict, resid` 仍是普通残差，稳健性体现在 `e(V)` 而非残差。

- **8. 示例**：
  ```stata
  sysuse auto, clear
  regress price mpg weight
  predict yhat
  predict e, resid
  gen e2 = e^2
  rvfplot
  list make price yhat e if abs(e) > 3000
  ```

---

## ❖ `marginsplot` （边际效应作图）

- **1. 功能**：把上一条 `margins` 算出的调整预测值或边际效应连同置信区间画成图，呈现交互与非线性效应最省事。

- **2. 语法**：
  ```stata
  margins ... [, options]
  marginsplot [, options]
  ```

- **3. 参数说明**：

| 参数 | 说明 |
|------|------|
| 前置 `margins` | 必须先算边际效应，`marginsplot` 只负责画 |
| `xdimension(varname)` | 指定横轴变量（多维时必用） |
| `yline(0)` / `noci` | 加 y=0 参考线（画边际效应几乎标配）/ 不画置信区间 |
| `recastci(rarea)` | 置信区间画成阴影带 |

- **4. 输出结果/返回值**：生成一个普通 `graph`，可用 `name()` 命名、`graph save`/`graph export` 保存，本身不返回 `r()`。数值都在 `margins`：`r(b)`、`r(V)`、`r(table)`（估计值、标准误、z/t、CI、df），可 `matrix list r(table)` 查看；`margins` 会覆盖之前 `r()`，故两步之间别插命令。

- **5. 常用选项**：
  ```stata
  margins, dydx(edu) at(age=(20(10)60))
  marginsplot, yline(0)                            // 边际效应图加零线
  marginsplot, recastci(rarea) ciopts(color(%30))  // CI 画成阴影
  marginsplot, noci                                // 只画点估计
  marginsplot, name(g_m, replace)                  // 命名以便合并
  ```

- **6. 配套检验/联动命令**：
  - `margins, dydx(*)`：所有变量的平均边际效应（AME），可直接抄进论文。
  - `margins, at(...) pwcompare`：多个取值点两两比较并给 p 值。
  - `graph combine`：把多张 `marginsplot` 拼成组图。

- **7. 常见坑**：
  - 必须**紧跟**对应 `margins`；中间插 `regress`/`summarize` 就报 "last estimates not found"。
  - `margins, dydx()` 的纵轴是"边际效应"，`margins, at()` 的是"预测值"，含义完全不同。
  - 交互模型要用 `margins, dydx(x) at(z=(...))`，只看 `_b` 的交互项系数容易解读错。
  - 分类变量 `at()` 用取值列表（`at(region=(1 2 3))`），不要写区间。

- **8. 示例**：
  ```stata
  sysuse auto, clear
  regress price mpg weight foreign
  margins, dydx(mpg) at(weight=(2000(500)4000))
  marginsplot, yline(0) name(g1, replace)
  ```

---

## ❖ `estimates store` / `estout` / `esttab` （估计结果存储与管理）

- **1. 功能**：`estimates store`（官方）把当前整套 `e()` 存进内存命名空间，随时 `restore` 或并列输出；`estout`/`esttab`（**第三方，`ssc install estout`**）把它们排版成可贴进论文的表格。

- **2. 语法**：
  ```stata
  estimates store name
  estimates dir
  estimates restore name
  estimates clear
  estimates table name1 name2 [, options]
  eststo name: regress y x1 x2            // 第三方
  esttab name1 name2 [using file] [, options]
  ```

- **3. 参数说明**：

| 参数 | 说明 |
|------|------|
| `estimates store name` | 把当前 `e()` 复制保存，`name` 自取 |
| `estimates dir` / `restore` / `drop` / `clear` | 列出 / 恢复为当前估计 / 删除一个 / 清空全部 |
| `eststo name: cmd` | 第三方快捷写法 = 跑命令 + 存结果 |
| `esttab a b, ...` | 两个及以上模型并列成表 |

- **4. 输出结果/返回值**：保存的是 `e()` 的完整副本（`e(b)`、`e(V)`、`e(N)`、`e(r2)`、`e(sample)` 全部保留）；`estimates dir` 列出模型名、因变量、命令与样本量；`restore` 之后 `ereturn list` 可核对。`esttab` 只排版输出，不产生可用的 `r()`。

- **5. 常用选项**：
  ```stata
  esttab m1 m2, b(3) se(3)                     // 系数/标准误 3 位小数
  esttab m1 m2, star(* 0.1 ** 0.05 *** 0.01)   // 显著性星号
  esttab m1 m2, r2 ar2                         // 显示 R²、调整 R²
  esttab m1 m2, mtitles("模型1" "模型2") title("工资回归")
  esttab m1 m2 using "表1.rtf", replace         // 导出（rtf 最稳）
  estimates table m1 m2, b(%9.3f) se stats(N r2)   // 官方版，样式朴素
  ```

- **6. 配套检验/联动命令**：
  - `estimates restore m1` + `test`/`lincom`：对已存模型补做系数检验。
  - `estimates stats m1 m2`（官方）：汇总样本量与信息准则。
  - `coefplot m1 m2`（第三方）：多模型系数点图。
  - `suest`（官方）：跨模型系数比较前必须先 `estimates store`。

- **7. 常见坑**：
  - `estat`/`test` 作用于"当前估计"，`estimates restore` 之后当前估计就变了。
  - 同名重复 `estimates store m1` 报 "already defined"，先 `estimates drop m1` 或换名。
  - `esttab` 是第三方命令，没装会 `unrecognized`；`estimates store` 不用装。
  - `using` 后缀要与格式一致；`.doc`/`.xls` 多为 RTF/XML 伪装，Word 打开提示"格式与扩展名不符"点"是"即可。
  - 存太多模型占内存、`esttab` 变慢，收尾 `estimates clear`。

- **8. 示例**：
  ```stata
  sysuse auto, clear
  eststo m1: regress price mpg
  eststo m2: regress price mpg weight
  esttab m1 m2, b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) r2 ///
      mtitles("模型1" "模型2") title("价格回归")
  estimates dir
  estimates clear
  ```

---

## ❖ `test` / `lincom` / `testparm` （系数检验与线性组合）

- **1. 功能**：`test` 检验系数是否满足线性约束（等于 0、两系数相等、和为 1 等）；`testparm` 检验一组变量（尤其因子变量组）的联合显著性；`lincom` 直接给出线性组合的点估计、标准误、置信区间与 p 值。

- **2. 语法**：
  ```stata
  test (term1) (term2) ...          // 联合检验，各约束同时为 0
  test exp = exp                    // 单个线性约束
  testparm varlist [, equal]
  lincom exp [, eform level(#)]
  ```

- **3. 参数说明**：

| 参数 | 说明 |
|------|------|
| `test x1` / `test x1 = x2` | 系数为 0（等价 `test x1 = 0`）/ 两系数相等 |
| `test x1 x2 x3` / `test (a) (b)` | 联合为 0 / 多个约束同时检验 |
| `testparm i.education` / `, equal` | 一组虚拟变量联合为 0 / 几个系数彼此相等 |
| `lincom x1 + x2`、`_b[x1] - _b[x2]` | 线性组合；`x1 + x2` 与 `_b[x1] + _b[x2]` 等价 |
| `, eform` / `, level(#)` | 结果取指数（报告 OR）/ 置信水平（默认 95） |

- **4. 输出结果/返回值**：`test` 后 `r(p)`（最常用）、`r(F)` 或 `r(chi2)`、`r(df)`、`r(df_r)`——OLS 报 F，MLE 或稳健方差报 Wald 卡方；`lincom` 后 `r(estimate)`、`r(se)`、`r(lb)`、`r(ub)`、`r(p)`、`r(df)`；`testparm` 与 `test` 存同类 `r()`。这些 `r()` 都会被下一条 r 类命令覆盖，循环里必须"算完立刻存"。

- **5. 常用选项**：
  ```stata
  regress y x1 x2 x3
  test x1 = x2                 // 系数相等
  test x1 x2 x3                // 联合显著
  test (x1 = 0) (x2 + x3 = 1)  // 多约束
  testparm i.region            // 虚拟变量组联合检验
  testparm x1 x2 x3, equal     // 三者是否相等
  lincom x1*0.5 + x2*0.5, level(90)
  logit y x1 x2
  lincom x1, eform             // 报告 OR
  ```

- **6. 配套检验/联动命令**：
  - `display r(p)`：把 p 值写进自定义结果表或循环汇总。
  - `lincom` + `margins, dydx()`：后者给平均边际效应，前者给精确线性组合，互补使用。
  - `suest`（官方）+ `test [m1]x1 = [m2]x1`：比较两个模型的系数——单模型内 `test` 做不到。
  - `xtreg` 后 `testparm`：检验个体虚拟变量联合为 0，即 FE 是否必要。

- **7. 常见坑**：
  - `test` 与 `testparm` 的区别：`test` 按**系数名/表达式**检验，适合少量约束；`testparm` 按**变量列表**检验，自动处理因子变量所有水平与基准项，检验"这组变量整体有没有用"用它，手写 `test 1.region 2.region 3.region` 极易漏项。
  - 因子变量系数名要写 `1.education`，`test education` 在 `i.education` 模型里含义不明。
  - `test` 的 `r(p)` 会被下一条命令覆盖，批量保存请 `scalar p1 = r(p)`。
  - 稳健/聚类标准误下 `test` 报 Wald 卡方而非 F，不能与 F 表比对。

- **8. 示例**：
  ```stata
  sysuse auto, clear
  regress price mpg weight length
  test mpg = weight                // 系数是否相等
  test mpg weight length           // 联合显著
  lincom _b[mpg] - _b[length], level(90)
  display "p 值 = " %6.4f r(p)
  ```

---

## ❖ `quietly` / `capture` / `noisily` （命令修饰符）

- **1. 功能**：三条前缀修饰符。`quietly` 静默执行（不打印，结果照常进 `r()`/`e()`）；`capture` 捕获错误让程序继续（错误码存 `_rc`）；`noisily` 在 `quietly`/`capture` 之下强制显示输出。

- **2. 语法**：
  ```stata
  quietly command
  capture command
  capture noisily command
  capture quietly command        // 两者可组合
  ```

- **3. 参数说明**：

| 参数 | 说明 |
|------|------|
| `quietly`（`qui`） | 抑制屏幕输出，`e()`/`r()` 一切照旧 |
| `capture` | 无论成败都不中断程序，返回码存入 `_rc`（0 = 成功） |
| `noisily`（`noi`） | 强制显示输出，调试时用来抵消 `quietly` |
| `_rc` | `capture` 留下的返回码，**只在下一条命令前有效** |

- **4. 输出结果/返回值**：`quietly`/`noisily` 不改变任何返回值；`capture` 的关键产物是 `_rc`：0 为成功，非 0 即 Stata 错误码（111 变量不存在、199 语法错、9 断言失败、430 无观测）。`capture` 成功时被捕获命令自己的 `r()`/`e()` 照常留下；失败时 `e()` 可能还是上一次的结果，别误用。

- **5. 常用选项**：
  ```stata
  quietly regress y x             // 结果仍可 test/predict
  quietly summarize x, detail     // 只取 r() 不刷屏
  capture confirm variable x      // 试探变量是否存在
  capture regress y x             // 出错也继续
  capture noisily regress y x     // 出错继续但打印信息（调试首选）
  ```

- **6. 配套检验/联动命令**：
  - `_rc` + `if`：标准错误处理 `capture cmd` 后接 `if _rc { display "失败：" _rc }`。
  - `confirm variable/file/dir`：配合 `capture` 做前置检查。
  - `error #`：主动抛出错误码（自定义校验失败时用）。

- **7. 常见坑**：
  - `capture` 会**吞掉错误信息**，程序看似跑通其实步步失败：务必查 `_rc`，调试期改用 `capture noisily`。
  - `_rc` 只反映紧邻的上一条 `capture` 命令，中间插命令就被改写，要"capture 完马上 if `_rc`"。
  - `quietly` 不影响取值：`quietly regress` 之后 `e(N)`、`e(r2)`、`_b[x]`、`predict`、`test` 全部照常可用。
  - `capture` 不能"半失败"：命令有错就整体不生效。

- **8. 示例**：
  ```stata
  sysuse auto, clear
  capture quietly regress price mpg
  if _rc == 0 {
      predict e, resid
      display "回归成功，N = " e(N)
  }
  else display "失败，_rc = " _rc
  ```

---

## ❖ `foreach` / `forvalues` / `while` （循环）

- **1. 功能**：对一组变量、一组取值或一个数值区间重复执行命令块；批量生成变量、批量回归、批量导出全靠它。

- **2. 语法**：
  ```stata
  foreach v of varlist x1-x10 { ... }
  foreach v of newlist a b c { ... }
  foreach v of local mylist { ... }
  forvalues i = 1/10 { ... }
  while cond { ... }
  ```

- **3. 参数说明**：

| 参数 | 说明 |
|------|------|
| `of varlist` | 遍历变量，支持 `x1-x10`、`x*` 通配 |
| `of newlist` / `of numlist` | 任意名字列表 / 数字列表（`1/10`、`1(2)9`） |
| `of local` / `of global` | 遍历已定义的宏内容 |
| `forvalues i = 1/10` | 整数或小数序列循环 |
| `while cond` | 条件为真就继续，**循环体里必须改变条件** |

- **4. 输出结果/返回值**：循环本身不产生 `r()`/`e()`（体内最后一条命令的结果会保留）。循环变量 `v`/`i` 是临时局部宏，引用写 `` `v' ``、`` `i' ``；体内定义的 `local` 循环结束后仍在（同一 do-file 层级）；累积结果用 `local ++n` 或 `scalar`，大批量推荐 `postfile`。

- **5. 常用选项**：
  ```stata
  foreach v of varlist x1 x2 x3 {
      quietly regress y `v'
      display "`v': coef = " %8.4f _b[`v'] "  p = " %6.4f r(p)
  }
  forvalues i = 1/5 {
      gen lag`i' = L`i'.gdp
  }
  ```

- **6. 配套检验/联动命令**：
  - `postfile`/`post`/`postclose`：把每个模型的系数、p 值、N 收集成数据集。
  - `estimates store m` + `` `i' ``：批量存模型，再 `esttab` 一次成表。
  - `levelsof group, local(glist)`：取出全部取值再 `foreach g of local glist`。
  - `continue` / `break`：跳过本轮 / 跳出循环。

- **7. 常见坑**：
  - 左大括号 `{` 必须写在**行尾**；do-file 里单独一行会报错（交互式窗口允许回车续行）。
  - 引用宏忘引号：`display `v'` 报错，须 `` display "`v'" ``。
  - `of varlist x*` 按**数据集变量顺序**展开，不是字母序，先 `describe x*` 确认。
  - `while` 忘记改变条件 → 死循环；`forvalues i = 1/0` 一次都不执行且不报错。
  - 循环里反复 `regress` 不加 `quietly`，几百张表刷屏，又慢又难查错。

- **8. 示例**：
  ```stata
  sysuse auto, clear
  foreach v of varlist price mpg weight {
      quietly summarize `v'
      display "`v'  均值=" %9.3f r(mean) "  N=" r(N)
  }
  ```

---

## ❖ `local` / `global` （宏 / 变量）

- **1. 功能**：定义可复用的字符串替换块。`local` 作用域限于当前 do-file 或程序；`global` 整个 Stata 会话可用，直到被清除或退出。写 do 文件时装变量列表、路径、循环参数，一处修改、处处生效。

- **2. 语法**：
  ```stata
  local name "内容"
  local name = 数值表达式
  local ++name
  global name "内容"
  ```

- **3. 参数说明**：

| 参数 | 说明 |
|------|------|
| `` `name' `` | 引用**局部**宏（反引号开头、单引号结尾） |
| `$name` / `${name}` | 引用**全局**宏；名字后紧跟字符时用 `${}` 界定边界 |
| `local n = 3` / `local ++n` | 数值型局部宏（`=` 先求值）/ 自增 |
| `macro drop name` | 删除全局宏 |

- **4. 输出结果/返回值**：宏不是 `r()`/`e()`，是"文本替换"：`` display "`name'" `` 打印内容，`display `n'` 打印数值；`local` 随 do-file/程序结束消失，`global` 常驻；`macro dir` 可列出全局宏，局部宏只能自己 `display`。

- **5. 常用选项**：
  ```stata
  local vars "wage edu exp"
  regress `vars'                     // 展开为 regress wage edu exp
  local n : word count `vars'        // 宏扩展函数：数单词个数
  global dir "D:/data"               // 路径用正斜杠或双反斜杠
  use "$dir/panel.dta", clear
  global controls "age age2 female"
  regress lnwage edu $controls
  ```

- **6. 配套检验/联动命令**：
  - `display`/`di`：查看宏内容与类型，调试首选。
  - `foreach ... of local`：把宏当循环列表。
  - `tokenize` + `` `1' ``、`` `2' ``：拆分文字为位置参数。
  - `tempname`：生成不冲突的临时名（写 ado 时用）。

- **7. 常见坑**：
  - 引用符号不能混：局部宏是 `` `name' ``，全局宏是 `$name`；混用取不到值。
  - **作用域**不同：do-file 跑完 `local` 即失效，子 do-file 里读不到父文件的 `local`，要传就用 `global` 或写在参数里。
  - do-file 编辑器里**只选中部分行**执行时，`local` 常"定义了却用不了"（定义与使用不在同一次执行里）。
  - 内容含空格要加双引号，含引号用复合引号 `` `"..."' ``；路径中的 `\` 要写 `\\` 或用 `/`。
  - `local x = 1/3` 存**数值** .333333（先求值），`local x 1/3` 存**字符串** "1/3"。

- **8. 示例**：
  ```stata
  sysuse auto, clear
  local y "price"
  local xs "mpg weight length"
  regress `y' `xs'
  global ctrl "mpg weight"
  regress price $ctrl
  macro drop ctrl
  ```

---

## ❖ `return list` / `ereturn list` （查看返回值）

- **1. 功能**：Stata 把结果存进三套返回值：`r()`（一般命令，如 `summarize`）、`e()`（估计命令，如 `regress`）、`s()`（少数命令，如 `sktest`）。记住存了什么，才能在程序里取用 `r(mean)`、`e(N)`、`e(r2)`、`_b[x]`、`_rc`。

- **2. 语法**：
  ```stata
  return list
  ereturn list
  sreturn list
  matrix list e(b)
  ```

- **3. 参数说明**：

| 参数 | 说明 |
|------|------|
| `return list` | 显示上一条一般命令的 `r()`（标量、宏、矩阵） |
| `ereturn list` | 显示上一条估计命令的 `e()`（含 `e(b)`、`e(V)`、`e(N)`） |
| `sreturn list` | 显示 `s()` 结果（`sktest` 等用） |
| `matrix list e(b)` | 单看系数向量；`e(V)` 为方差-协方差矩阵 |

- **4. 输出结果/返回值**：`r()` 常见 `r(N)`、`r(mean)`、`r(sd)`、`r(min)`、`r(max)`、`r(sum)`、`r(p)`；`e()` 常见 `e(N)`、`e(r2)`、`e(r2_a)`、`e(F)`、`e(df_m)`、`e(df_r)`、`e(ll)`、`e(sample)`（0/1 标记估计样本）、`e(cmd)`、`e(depvar)`；系数与标准误用只读的 `_b[x1]`、`_se[x1]`。三套返回值都会被下一条同类命令覆盖，`ereturn list` 只在最近一次估计后有义。

- **5. 常用选项**：
  ```stata
  summarize wage
  return list                        // 看 r() 里有什么
  display %9.4f r(mean)
  regress y x
  ereturn list                       // 看 e() 全套
  display e(N) " " e(r2)
  display _b[x] " " _se[x]
  ```

- **6. 配套检验/联动命令**：
  - `scalar`：把 `r()`/`e()` 的值固化，避免被覆盖。
  - `estimates store`/`restore`：换回某个模型的 `e()` 再取数。
  - `display` 的 `%9.4f`/`%6.3f`：控制输出精度。
  - `predict`：与手工用 `_b[]` 拼出的预测值对照，校验系数是否读对。

- **7. 常见坑**：
  - `return list` 只看 `r()`；估计结果在 `e()` 里，必须 `ereturn list`。
  - 返回值随命令覆盖：`summarize x` 之后跑 `count`，`r(mean)` 就没了。
  - 名字要精确：`e(r2)` 与 `e(r2_a)` 不是一个东西，加权时还有 `r(mean_w)`；拿不准先 `return list`。
  - 估计命令失败后 `ereturn list` 仍显示上一次成功的 `e()`，易误判，配合 `capture` + `_rc`。
  - `_b[x]` 只读不能赋值；取用是"函数式" `r(mean)`，不是 `` `r(mean)' ``。

- **8. 示例**：
  ```stata
  sysuse auto, clear
  summarize price
  display "均值 = " %9.2f r(mean)
  regress price mpg weight
  ereturn list
  scalar r2_saved = e(r2)      // 固化，避免被覆盖
  display "N=" e(N) " R2=" %6.4f r2_saved
  ```

---

## ❖ `outreg2` / `asdoc` （结果导出 Word/Excel）

- **1. 功能**：把回归结果直接写成 Word/Excel 文件，省去复制粘贴。两者都是**第三方**（`ssc install outreg2`、`ssc install asdoc`）；官方替代是 `esttab using file.rtf` 或 `estimates table`。

- **2. 语法**：
  ```stata
  ssc install outreg2
  regress y x1 x2
  outreg2 using "res.doc", replace word dec(3)
  ssc install asdoc
  asdoc regress y x1 x2, replace
  ```

- **3. 参数说明**：

| 参数 | 说明 |
|------|------|
| `using "file"` | 输出文件名，后缀决定格式（`.doc`/`.xls`/`.rtf`/`.txt`） |
| `replace` / `append` | 覆盖已有文件（第一次必用）/ 追加（多模型并列时用） |
| `word` / `excel` | 指定输出为 Word 表 / Excel 表 |
| `dec(3)` / `ctitle("...")` | 系数与标准误小数位 / 该列表头 |
| `label` / `keep()` / `drop()` / `nor2` | 用变量标签 / 只留 / 去掉某些变量 / 不报 R² |

- **4. 输出结果/返回值**："输出"就是磁盘文件，不在 `r()`/`e()` 里留东西。文件生成后到 Word/Excel 打开检查是唯一可靠验收；命令执行后 `e()` 仍是原回归结果，可继续 `test` 或下一轮 `append`；报 "file not found" 或写出空表时先查目录（`pwd`、`cd`）。

- **5. 常用选项**：
  ```stata
  outreg2 using "res.doc", replace word dec(3)                 // 新建
  outreg2 using "res.doc", append word dec(3) ctitle("模型2")  // 追加一列
  outreg2 using "res.xls", replace excel dec(3)                // 输出 Excel
  asdoc reg y x1 x2, replace save(表1.doc) dec(3)
  asdoc sum y x1 x2, replace save(描述统计.doc)                // 描述统计也能导
  ```

- **6. 配套检验/联动命令**：
  - `esttab`/`estout` + `eststo`：可复现性更好的表格方案，建议优先掌握。
  - `estimates table`（官方）：不装任何包时的应急输出。
  - `putdocx`（官方，Stata 15+）：用代码精细控制 Word 排版。
  - `pwd`/`cd`：确认文件到底写到了哪个目录。

- **7. 常见坑**：
  - 第一次写同一文件必须 `replace`，后续并列必须 `append`，反过来会丢结果或报错。
  - `word` 与 `excel` 只能二选一；后缀与格式不匹配时打开会提示"格式与扩展名不符"，点"是"即可。
  - 中文路径/表头在旧版本可能乱码，尽量用英文文件名或 `unicode translate`。
  - `asdoc` 每跑一次重写一次文件，要并列多模型请改用 `esttab`。

- **8. 示例**：
  ```stata
  sysuse auto, clear
  outreg2 using "price_reg.doc", replace word dec(3) ctitle("模型1")
  regress price mpg weight foreign
  outreg2 using "price_reg.doc", append word dec(3) ctitle("模型2")
  ```

---

## ❖ 统计量与标量：`scalar` / `display`

- **1. 功能**：`scalar` 定义数值常量（比宏更适合装数字），`display`（`di`）打印数值、字符串与 `_b[]`/`r()`/`e()` 的取值；写自定义输出表、拼结果字符串全靠它们。

- **2. 语法**：
  ```stata
  scalar name = exp
  scalar dir
  display [%fmt] exp [...]
  ```

- **3. 参数说明**：

| 参数 | 说明 |
|------|------|
| `scalar name = exp` | 定义/覆盖标量，`exp` 可为 `e(r2)`、`_b[x]`、算术表达式 |
| `scalar dir` / `scalar drop name` | 列出已定义标量 / 删除 |
| `%9.4f`、`%6.2f` | 格式符：总宽.小数位 |
| `_N` / `_b[x]` / `_se[x]` | 观测总数 / 上一次估计的系数与标准误 |

- **4. 输出结果/返回值**：`scalar` 是持久对象（直到 `scalar drop` 或退出 Stata），不会被下一条命令覆盖，这正是它优于 `r()` 之处；`display` 本身不产生 `r()`，只"读"：`display r(mean)`、`display e(N)`、`display _b[x1]`、`display _rc` 是最常用的四种取值。

- **5. 常用选项**：
  ```stata
  regress y x
  scalar b1 = _b[x]              // 固化系数
  display %9.4f b1               // 格式化输出
  display scalar(b1)             // 同名变量存在时用它消歧
  display _N " obs, " _b[x] _se[x]
  display "b=" %8.4f _b[x] " (se=" %8.4f _se[x] ")"
  ```

- **6. 配套检验/联动命令**：
  - `local`：装字符串/列表；`scalar` 只管数字，两者分工。
  - `test`/`lincom` + `scalar p = r(p)`：把 p 值固化进结果表。
  - `matrix`：需要多维结果时用矩阵（`matrix b = e(b)`）。
  - `display` 的 `_n`/`_skip()`：排版换行与缩进。

- **7. 常见坑**：
  - 变量名与标量名相同时 Stata 优先按**变量**解释，会打印出一列数，需写 `scalar(name)`。
  - `_b[x]` 只在上一次估计后有效，中间跑过别的估计命令就变成新模型的系数。
  - 格式符必须紧跟表达式：`display %9.4f r(mean)` 对，放在逗号后面是错的。
  - 字符串要加引号（`display "均值"`），否则被当变量名；`scalar` 不能存字符串。
  - `display` 不改变 `r()`，也不会帮你保留 `r()`。

- **8. 示例**：
  ```stata
  sysuse auto, clear
  regress price mpg weight
  scalar b_mpg = _b[mpg]
  display "b_mpg = " %8.3f scalar(b_mpg) "；N = " e(N)
  scalar drop b_mpg
  ```

---

## ❖ `count` / `assert` （计数与断言）

- **1. 功能**：`count` 数满足条件的观测数（结果存 `r(N)`，不生成变量）；`assert` 校验条件，不成立就报错中断——数据清洗与 do 文件的自检哨兵。

- **2. 语法**：
  ```stata
  count [if] [in]
  assert exp [if] [in]
  ```

- **3. 参数说明**：

| 参数 | 说明 |
|------|------|
| `count` / `count if treat==1` | 总观测数 / 满足条件的观测数 |
| `count if missing(wage)` | 缺失值个数 |
| `assert exp` | 全为真则静默通过，否则报错中断 |
| `assert inlist(region,1,2,3)` | 校验取值合法 |
| `assert !missing(id)` | 校验关键变量无缺失 |

- **4. 输出结果/返回值**：`count` 后 `r(N)` 为满足条件的观测数（可能还有 `r(N_...)`，以 `return list` 为准）；`assert` 通过时无输出，失败时报错并给错误码 `r(9)`（"assertion is false"），在 `capture` 下可用 `_rc == 9` 判断。`r(N)` 会被下一条 r 类命令覆盖，要累积请 `scalar n = r(N)`。

- **5. 常用选项**：
  ```stata
  count                          // 总观测数
  count if missing(wage)         // 缺失值个数
  count if inrange(age, 18, 60)  // 区间内观测数
  assert id != .                 // 关键 ID 不许缺失
  assert wage > 0 if !missing(wage)
  ```

- **6. 配套检验/联动命令**：
  - `isid id`：官方命令，检查 `id` 唯一，比手写 `assert` 省事。
  - `duplicates report` / `duplicates list`：查重复观测。
  - `codebook` / `misstable summarize`：系统排查异常取值与缺失。
  - `capture assert ...` + `_rc`：把断言当"软检查"，不中断程序。

- **7. 常见坑**：
  - `count` 的 `r(N)` 与 `_N` 不同：`_N` 是数据集总观测数，不随 `if` 变化。
  - `count` 只给个数；分类型计数用 `tabulate`（自带百分比与累计）。
  - `assert` 在交互窗口报错不崩会话，但在 do 文件里会**中止后续所有命令**。
  - 对含缺失的变量写 `assert wage > 0` 会因 `.` 参与比较而出问题，务必加 `if !missing(wage)`。
  - `assert` 只报第几个观测失败，定位要靠 `list ... if !(条件)`。

- **8. 示例**：
  ```stata
  sysuse auto, clear
  count if foreign == 1
  count if missing(rep78)
  assert price > 0
  capture assert mpg > 100
  display "越界检查 _rc = " _rc
  ```

---

## ❖ `in` / 通配符（变量范围与选择）

- **1. 功能**：用 `x1-x10`（按数据集变量顺序的连续区间）与 `x*`、`x?`（名字通配）快速写出变量列表；用 `in 1/100` 按观测序号取子样本。几十个变量的回归、批量改名、批量筛选都靠它。

- **2. 语法**：
  ```stata
  varlist：   x1-x10    x*    *rate    x?
  obs range： in 1/100   in -20/l
  ```

- **3. 参数说明**：

| 参数 | 说明 |
|------|------|
| `x1-x5` | 从 `x1` 到 `x5`，**按数据集变量顺序**（不是字母序）取连续一段 |
| `x*` / `*rate` / `x?` | 以 x 开头 / 以 rate 结尾 / x 后跟一个字符的变量 |
| `in 1/100` | 第 1 到第 100 个观测 |
| `in -20/l` | 最后 20 个观测（`l` 即 last） |
| `if` + `in` | 可合用：`if year>2000 in 1/100` |

- **4. 输出结果/返回值**：这是"语法糖"，本身不产生 `r()`/`e()`；实际生效范围可用 `describe varlist` 或 `ds varlist` 预先确认。`in` 不改变数据集、只在该条命令内生效，要真正取子集用 `keep in 1/100`。

- **5. 常用选项**：
  ```stata
  summarize x1-x5          // 连续区间
  describe x*              // 以 x 开头的变量
  ds *rate                 // 更干净的变量罗列
  keep in 1/100            // 真正保留前 100 行
  list in -10/l            // 看最后 10 行
  ```

- **6. 配套检验/联动命令**：
  - `describe` / `ds`：先确认 `-` 与 `*` 匹配了哪些变量，再执行破坏性命令。
  - `keep` / `drop`：把 `if`/`in` 的选择落到数据上。
  - `order` / `rename` + `foreach v of varlist`：批量整理变量。
  - `mark` / `marksample`（写程序时用）：安全生成样本标记。

- **7. 常见坑**：
  - `a-zz` 走的是**变量物理顺序**而非字母序；中间夹着 `id`、`year` 等会被一起选进去。
  - `x*` 也按数据集顺序展开，`x10` 可能排在 `x2` 前面，"数字顺序"的直觉不可靠。
  - `gen y = x*` 里的 `*` 是乘法不是通配，通配只在变量列表位置生效。
  - `in` 依赖当前排序，`sort` 之后 `in 1/100` 指向的观测就变了。
  - 做 `drop x1-x10` 之类破坏性操作前，先 `describe x1-x10` 核对。

- **8. 示例**：
  ```stata
  sysuse auto, clear
  describe price*                 // 先看匹配到哪些
  keep in 1/50                    // 保留前 50 行
  list make price in -5/l         // 最后 5 行
  ```

---

## 📋 官方内置命令速查表（官方 = 无需安装，装好 Stata 即可用）

> 下表把本文档出现的、**Stata 官方自带**的命令分门别类列出。只有不在下表里的第三方命令才需要 `ssc install`。

| 类别 | 官方内置命令 |
|------|--------------|
| **数据管理** | `use` `save` `compress` `import` `export` `describe` `codebook` `list` `browse` `edit` `gen` `replace` `egen` `bysort` `keep` `drop` `sort` `gsort` `order` `recode` `destring` `tostring` `encode` `decode` `label` `merge` `append` `joinby` `cross` `collapse` `reshape` `duplicates` `isid` `preserve` `restore` `missing` |
| **描述统计** | `summarize` `tabstat` `tabulate` `table` `ttest` `anova` `pwmean` `count` `distinct` |
| **线性回归** | `regress` `predict` `test` `lincom` `testparm` `vif`(回归后) `estat hettest` `estat imtest` `estat dwstat` `estat bgodfrey` `estimates` `margins` `marginsplot` |
| **回归后诊断（本章）** | `estat vif` `estat hettest` `estat imtest` `estat ovtest` `estat dwstat` `estat bgodfrey` `estat durbinalt` `estat ic` `predict` `rvfplot` `rvpplot` `lvr2plot` `sktest` `swilk` `newey` `prais` `estimates store/dir/restore/table` `test` `lincom` `testparm` |
| **返回值与宏** | `return list` `ereturn list` `sreturn list` `scalar` `matrix` `display` `local` `global` `macro` `foreach` `forvalues` `while` `quietly` `capture` `noisily` `count` `assert` `confirm` `error` |
| **广义/非线性** | `logit` `logistic` `probit` `mlogit` `ologit` `oprobit` `poisson` `nbreg` `tobit` `intro` `glm` |
| **时间序列** | `tsset` `tsline` `corrgram` `ac` `pac` `dfuller` `pperron` `kpss` `arima` `var` `varsoc` `irf` `vargranger` `vecrank` `vec` `johansen`(需官方 ssc 补充) |
| **面板数据** | `xtset` `xtdes` `xtsum` `xttab` `xttrans` `xtreg` `xtivreg` `xtprobit` `xtlogit` `xtpoisson` `xtgls` `hausman` `xttest0` |
| **画图** | `graph` `twoway` `scatter` `line` `connected` `lfit` `qfit` `lowess` `histogram` `kdensity` `graph box` `graph bar` `graph hbar` `cumul` `graph combine` `graph export` `graph save` `graph use` `set scheme` |
| **宏/循环** | `foreach` `forvalues` `while` `local` `global` `return list` `ereturn list` `scalar` `display` `quietly` `capture` `noisily` `if` |

> 💡 其余如 `reghdfe`、`ivreg2`、`rdrobust`、`synth`、`csdid`、`bacondecomp`、`psmatch2`、`outreg2`、`asdoc`、`coefplot`、`binscatter`、`estout`（含 `esttab`/`eststo`）、`xttest3`、`xtserial` 等均为**第三方命令**，需先 `ssc install`，详细清单见上方二部分 0.3。

> ⚠️ 认不出的命令先 `help cmd` 或 `which cmd`：`which` 会告诉你这是官方内置、已装的第三方，还是没装。

---

## 📖 使用说明（README）

1. **每个命令的结构**统一为：功能 → 语法 → 参数表 → 输出 → 常用选项 → 示例，方便检索。（本章附录 C 的条目细化为：功能 → 语法 → 参数说明 → 输出结果/返回值 → 常用选项 → 配套检验/联动命令 → 常见坑 → 示例。）
2. **前置条件**：
   - 时间序列命令前务必 `tsset`；
   - 面板命令前务必 `xtset`；
   - 遇到 `command xxx is unrecognized`，先查上方"官方内置速查表"；不在表内就先 `ssc install xxx`（始终记住官方内置用完即走，第三方要装）。
   - `estat` 系列、`test`、`lincom`、`predict`、`margins`、`marginsplot` 都要求**上方紧邻**一条成功的估计命令（`marginsplot` 紧邻 `margins`）。
3. **内容结构**：
   - **第零部分**：安装包使用说明（官方 vs 第三方、安装方式、包清单）。
   - **第一~四部分**：横截面 / 时间序列 / 面板 / 因果推断的核心模型命令。
   - **附录 A**：数据读入、生成、转换、合并、清洗等数据处理命令。
   - **附录 B**：散点、折线、直方图、核密度、箱线图、坐标轴/图例/分面等画图命令。
   - **附录 C**：VIF、异方差、自相关检验，以及 `predict`、`test`、`esttab`、循环等高频细节命令。
4. **版本**：本文基于 Stata 17（部分新命令如 `didregress`、`csdid` 需 Stata 15+ 或最新版）。
5. **提示**：遇到未知选项或语法细节，随时可用 `help 命令名` 查看官方完整文档。
6. **本章推荐工作流**：`regress` → `estat vif` + `estat ovtest`（设定）→ `estat hettest` + `estat imtest, white`（异方差）→ `predict e, resid` + `rvfplot` + `lvr2plot`（残差与影响点）→ `sktest e`（正态性，大样本可略）→ `regress ..., vce(cluster id)` + `test`（定稿）→ `estimates store` + `esttab`（成表）。

---

---

## 📌 速查：一个完整实证分析的标准流程

> 把全书串成一条流水线：每一步"做什么 → 用什么命令 → 这一步之后必须查什么检验"。
> 顺序不要颠倒：**先诊断、再定稿**；检验没做就写结果，是实证论文被打回的第一大原因。

| 步骤 | 做什么 | 核心命令 | 这一步之后必查的检验 |
|------|--------|----------|----------------------|
| 1 | 读数据、看清结构 | `import delimited` / `use` / `describe` / `codebook` | `isid`（唯一性）、`misstable summarize`（缺失）、`duplicates report`（重复） |
| 2 | 变量构造与清洗 | `gen` / `egen` / `replace` / `encode` / `destring` | `assert`（逻辑规则）、`summarize, detail`（极值）、`tab v, missing`（异常码） |
| 3 | 描述性统计 | `summarize` / `tabstat` / `pwcorr` / `tabulate` | 相关系数是否 >0.8（共线预警）、缺失率是否过高 |
| 4 | 声明数据结构 | 横截面：无；时间序列：`tsset`；面板：`xtset` | `xtdes` / `xtsum`（面板结构）、`tsreport`（时间缺口） |
| 5 | 设定检验（共线性 / 函数形式） | `regress` | `estat vif`（<10）、`estat ovtest`（RESET）、`linktest` |
| 6 | 异方差 / 自相关 | `regress` | `estat hettest`、`estat imtest, white`、`estat dwstat` / `estat bgodfrey` |
| 7 | 选模型（FE vs RE / 时间效应） | `xtreg, fe` / `xtreg, re` | `hausman`（FE vs RE）、`xttest0`（LM）、`testparm i.year`（时间效应） |
| 8 | 主回归（定标准误） | `regress ..., vce(cluster id)` / `xtreg ..., fe vce(cluster id)` | 聚类数够不够（>30 更稳）、系数符号是否符合理论预期 |
| 9 | 内生性（如需要） | `ivregress 2sls` / `xtivreg` / `reghdfe` | `estat firststage`（弱工具 F>10）、`estat endog`（内生性）、`estat overid`（过度识别） |
| 10 | 稳健性 | 换因变量 / 缩尾 / 换样本 / 换标准误 | 核心系数符号与显著性是否稳定（不要只报显著的那一版） |
| 11 | 异质性 / 机制 | 分组回归 / 交互项 | 组间差异是否显著（`lincom` / `test` 交叉项） |
| 12 | 成表与复现 | `estimates store` / `esttab` / `outreg2` | 表内 N、R²、FE/TE 标注齐全；do 文件能一键重跑 |

> **三条铁律**
> 1. **先诊断后解读**：`estat` 系列没跑就下结论，等于不知道标准误对不对。
> 2. **检验与设定必须匹配**：`estat vif` 只能在 `regress`（或 `xtreg, re`）之后；`xtreg, fe` 之后要 VIF，得改用 `regress y x i.id` 或安装 `xttest3` 之类命令。
> 3. **报告全部结果**：显著与不显著的一起报，否则稳健性检验就没有意义。

---

*整理：Stata 命令大全（横截面 / 时间序列 / 面板 / 因果分析 / 数据处理 / 画图 / 安装包说明）