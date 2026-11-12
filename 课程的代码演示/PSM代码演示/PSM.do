/*---------------------倾向得分匹配------------------------*/

ssc install psmatch2, replace/*----安装psmatch2命令包------*/
*use http://ssc/wisc.edu/sscc/pubs/files/psm,replace//网络调用psm数据
cd "D:\OneDrive - m.gduf.edu.cn\工作杂项\stata\课程的代码演示\PSM代码演示"
use psm.dta, clear
des                              /*----了解变量的含义----*/
sum
tabulate t  /*---了解处理组与控制组样本【占比】，例如，考虑是否进行有放回匹配等---*/

/*--1-----一对一匹配-----------------------------------------------------------
 psmatch2 depvar [indepvars] [if exp] [in range], [outcome(varlist) 
            pscore(varname) ai(integer k>1) mahalanobis(varlist) 
			caliper(real) noreplacement descending common trim(real) 
			odds index logit ties warnings quietly ate]

 ----选项----
 depvar ：处理变量。
 indepvars ：协变量。
 outcome(varlist) ：结果变量。没有这一项，则不估计ATT，只计算倾向得分
 pscore(varname) ：指定变量估计倾向得分，默认使用indepvars中的变量。
 ai(integer k>1) ：使用Abadie和Imbens（2006）提出的异方差稳健标准误估计，该选项
               仅适用于使用马氏距离的k近邻匹配，integer表示用于计算稳健标准误
				  的近邻个数。和altvariance一起使用，指定使用Abadie et al.(2004)估计。
 mahalanobis(varlist) ：马氏匹配，指定计算马氏距离的协变量。
 caliper(real) ：设置卡尺epsilon，为正实数。
 noreplacement ：无放回一对一匹配，默认为有放回抽样。（仅适用于最近邻倾向得分匹配）
 descending ：按降序无放回一对一匹配。（仅适用于最近邻倾向得分匹配）
 common ：仅对共同取值范围内个体进行匹配，默认是对所有个体匹配。
 trim(real) ：通过删除#%的实验组数据使得控制组得分密度最低，得到共同取值范围。
 odds ：使用机会比率（p/(1-p)）进行匹配，默认使用倾向得分匹配。
 index ：使用潜变量指标=xb，而非概率。
 logit ：用logit模型估计倾向得分，默认是probit。
 ties ：包括所有倾向得分相同的并列个体，对它们取平均值进行匹配。
 warnings ：用重复倾向得分值检验控制组（观测数据）。
 quietly ：不报告倾向得分估计过程。
 ate ：报告ATE、ATU、ATT，默认只报告ATT。
-----------------------------------------------------------------------------*/

/*--2-----k近邻匹配-----------------------------------------------------------
 psmatch2 depvar [indepvars] [if exp] [in range], [outcome(varlist) 
            pscore(varname) neighbor(integer k>1) caliper(real) 
			common trim(real) odds index logit ties warnings 
			quietly ate]

 ----选项---- 
 depvar ：处理变量。
 indepvars ：协变量。
 outcome(varlist) ：结果变量。
 pscore(varname) ：指定变量估计倾向得分，默认使用indepvars中的变量。
 neighbor(integer k>1) ：进行k近邻匹配，默认k=1，即一对一匹配。
 caliper(real) ：设置卡尺epsilon，为正实数。
 common ：仅对共同取值范围内个体进行匹配，默认是对所有个体匹配。
 trim(real) ：通过删除#%的实验组数据使得控制组得分密度最低，得到共同取值范围。
 odds ：使用机会比率（p/(1-p)）进行匹配，默认使用倾向得分匹配。
 index ：使用潜变量指标=xb，而非概率。
 logit ：用logit模型估计倾向得分，默认是probit。
 ties ：包括所有倾向得分相同的并列个体，对它们取平均值进行匹配。
 warnings ：用重复倾向得分值检验控制组（观测数据）。
 quietly ：不报告倾向得分估计过程。
 ate ：报告ATE、ATU、ATT，默认只报告ATT。
 
* 注意：$ 表示除了这个选项外，其他选项都已出现，即与前面命令中的含义一样。
-----------------------------------------------------------------------------*/
/*--3-----卡尺（半径）匹配----------------------------------------------------
 psmatch2 depvar [indepvars] [if exp] [in range], radius caliper(real) 
             [outcome(varlist) pscore(varname) common trim(real) 
			   odds index logit quietly ate]

 ----选项----
 depvar ：处理变量。
 indepvars ：协变量。
$ radius ：卡尺（半径）匹配。
 caliper(real) ：设置卡尺epsilon，为正实数。
 outcome(varlist) ：结果变量。
 pscore(varname) ：指定变量估计倾向得分，默认使用indepvars中的变量。
 common ：仅对共同取值范围内个体进行匹配，默认是对所有个体匹配。
 trim(real) ：通过删除#%的实验组数据使得控制组得分密度最低，得到共同取值范围。
 odds ：使用机会比率（p/(1-p)）进行匹配，默认使用倾向得分匹配。
 index ：使用潜变量指标=xb，而非概率。
 logit ：用logit模型估计倾向得分，默认是probit。
 quietly ：不报告倾向得分估计过程。
 ate ：报告ATE、ATU、ATT，默认只报告ATT。
 
* 注意：$ 表示除了这个选项外，其他选项都已出现，即与前面命令中的含义一样。
-----------------------------------------------------------------------------*/
/*--4-----核匹配-----------------------------------------------------------
 psmatch2 depvar [indepvars] [if exp] [in range], kernel [outcome(varlist) 
            kerneltype(kernel_type) pscore(varname) bwidth(real) 
			mahalanobis(varlist) common trim(real) odds index 
			logit quietly ate]

 ----选项----
 depvar ：处理变量。
 indepvars ：协变量。
$ kernel ：核匹配。
 outcome(varlist) ：结果变量。
$ kerneltype(kernel_type) ：设置核函数，默认为二次核（epan）。normal（gaussian核）、
                         biweight、epan（epanechnikov，默认）、uniform、tricube。
 pscore(varname) ：指定变量估计倾向得分，默认使用indepvars中的变量。
$ bwidth(real) ：指定窗宽，默认为0.06。
 mahalanobis(varlist) ：马氏匹配，指定计算马氏距离的协变量。
 common ：仅对共同取值范围内个体进行匹配，默认是对所有个体匹配。
 trim(real) ：通过删除#%的实验组数据使得控制组得分密度最低，得到共同取值范围。
 odds ：使用机会比率（p/(1-p)）进行匹配，默认使用倾向得分匹配。
 index ：使用潜变量指标=xb，而非概率。
 logit ：用logit模型估计倾向得分，默认是probit。
 quietly ：不报告倾向得分估计过程。
 ate ：报告ATE、ATU、ATT，默认只报告ATT。
 
* 注意：$ 表示除了这个选项外，其他选项都已出现，即与前面命令中的含义一样。
-----------------------------------------------------------------------------*/
/*--5-----马氏距离匹配---------------------------------------------------------
 psmatch2 depvar [if exp] [in range], mahalanobis(varlist) outcome(varlist) 
             ai(integer) [population altvariance kernel(kernel_type) 
			 llr bwidth(real) caliper(real) w(matrix) ate]

 ----选项----
 depvar ：处理变量。
 mahalanobis(varlist) ：马氏匹配，指定计算马氏距离的协变量。
 outcome(varlist) ：结果变量。
$ ai(integer) ：使用Abadie和Imbens（2006）提出的异方差稳健标准误估计，该选项
                  仅适用于使用马氏距离的k近邻匹配，integer表示用于计算稳健标准误
				  的近邻个数。和altvariance一起使用，指定使用Abadie et al.(2004)估计。
$ population ：当使用选项ai(integer)时，计算总体方差而非样本方差（默认是样本方差）。
$ altvariance ：当使用选项ai(integer)时，使用Abadie et al.(2004)中的公式计算条件方差。
$ kernel(kernel_type) ：设置核函数，默认为二次核（epan）。normal（gaussian核）、
                         biweight、epan（epanechnikov，默认）、uniform、tricube。
 llr ：局部线性回归。
 bwidth(real) ：指定窗宽，默认为0.06。
 caliper(real) ：设置卡尺epsilon，为正实数。
$ w(matrix) ：指定alternative 权重矩阵。
 ate ：报告ATE、ATU、ATT，默认只报告ATT。
 
* 注意：$ 表示除了这个选项外，其他选项都以出现，即与前面命令中的含义一样。
-----------------------------------------------------------------------------*/
psmatch2 t x1 x2,outcome(y) //默认用probit计算倾向匹配得分
probit t x1 x2       //psmatch2的第一个回归结果就是probit的结果
psmatch2 t x1 x2,outcome(y) logit //选择logit计算倾向匹配得分
logit t x1 x2 //psmatch2的第一个回归结果就是logit的结果
// _pscore 是倾向得分，进入处理组的概率
psmatch2 t,outcome(y) pscore(x1) //pscore(varname)使用某一个特定的变量作为倾向得分
quiet psmatch2 t x1 x2,outcome(y) //quiet 不汇报计算倾向得分回归结果
psmatch2 t x1 x2, outcome(y) n(1) common //common 就是删除处理组共同区间外的变量
//删除pscore 大于非处理组pscore最大值（最小值）的处理组个体
psmatch2 t x1 x2, outcome(y) n(1) ties //ties //多个个体pscore相同时，多个个体成为匹配对象，且取特征值Y的平均值
psmatch2 t x1 x2,outcome(y) n(1) odds //根据倾向得分的odds ratio 进行匹配 
psmatch2 t x1 x2,outcome(varname) //varname 是特征值变名，可以有多个特征值
psmatch2 t x1 x2,outcome(y) ate //汇报ate，否则默认att commonsupport只显示一组
pstest x1 x2,both graph //检验匹配前后协变量的平衡性 没有both选项只返回匹配后的结果
reg y t x1 x2 [fweight=_weight] //1对1匹配中使用，考虑了权重，建议使用这个
// fweight 观测值出现频次
reg y t x1 x2 if _weight!=. //1对多匹配中使用，没考虑权重

****近邻匹配*******
psmatch2 t x1 x2,outcome(y) n(1) //一对一有放回匹配
psmatch2 t x1 x2,outcome(y) n(1) noreplacement //无放回匹配，仅适合一对一匹配
psmatch2 t x1 x2,outcome(y) n(3) //3是任意值 一对多有放回匹配，不允许无放回匹配

****带卡尺的近邻匹配******
psmatch2 t x1 x2, outcome(y) n(1) caliper(0.03) // 0.03可以替换成自己需要的值
//卡尺匹配为了解决近邻匹配可能匹配到倾向得分差异较大的近邻，卡尺匹配要求使用跟近邻匹配得分差异在一定的容忍程度内的n个样本
****半径匹配*****
psmatch2 t x1 x2, outcome(y) radius caliper(0.03) //所有落入半径的值均包括

******核匹配*****
psmatch2 t x1 x2, outcome(y) kernel kerneltype() bwidth()common logit ate  //normal,biweight,epan,uniform,tricube 是核函数类型，默认的是epan,bwidth指定带宽，
///默认0.06 带宽变大，核函数会更平滑，降低估计密度函数方差。过度平滑会消除密度函数不平滑特点
///消除，让核函数的权重意义下降。核匹配多选择集中带宽进行稳健性检验，看看研究结果是不是带宽导致的偶然事件

******马氏匹配*******
psmatch2 t, mahal(x1 x2) outcome(y) ai(5)  ate //

********************************************
*Open Dehejia-Whaba(1999) experimental data
*********************************************
use nsw_dw, clear
gen agesq=age*age
tabulate t 
pstest age-re75,t(treat) raw //raw原始数据，即匹配前平衡性检验
psmatch2 t age-re75,outcome(re78) logit ate n(1) common ties
pstest age-re75,both graph //检验协变量在处理组和控制组之间是否平衡
/*---其中，both显示匹配前后数据平衡情况，默认仅显示匹配后平衡情况。
           graph表示用图形的方式显示各变量匹配前后的平衡情况---------*/ 
gen common = _support
drop if common == 0 //去掉不满足共同区间假定的观测值
psgraph //对匹配结果进行图示
/*------psgraph-----------------------------------------------------------
 psgraph [, bin(#) treated(varname) support(varname) pscore(varname) graph_options]
 
 ----选项----
 bin(#) ：指定直方图的分组数，默认是bin(20)。
 treated(varname) ：指定处理变量。
 support(varname) ：共同取值范围示性变量。
 pscore(varname) ：指定倾向得分。
* 注意：在psmatch2执行后，psgraph后可不带任何选项。
-----------------------------------------------------------------------------*/
use nsw_dw, clear
drop if treat==0 //删掉控制组
append using cps_controls //引入新的控制组

*--匹配前，对数据进行随机排序--------------------------------------
set seed 12345
gen neworder=runiform()
sort neworder

gen agesq=age*age
gen marriedre75=married*re75
gen agere74=age*re74
gen nodegreeage=nodegree*age //这4行命令是反复试出来的,平衡检验不通过，增加层数

pstest age-re75, t(treat) raw //匹配前协变量平衡性检验
psmatch2 t age-re75,outcome(re78) logit ate n(1) common ties
pstest age-re75,both graph //发现平衡性检验不通过，要增加分层

cap drop id_nsw ps_nsw //删除两个变量，没有的话也不报错
pscore treat age-re75, pscore(ps_nsw) blockid(id_nsw) logit 
//pscore命令可以直接报告 平衡检验不通过，需要增加分层,这个命令可以直观的告诉你是否平衡

cap drop id_nsw ps_nsw
pscore treat age education black hisp married re74 re75 ///
marriedre75 agere74, pscore(ps_nsw) blockid(id_nsw) ///
 comsup logit //这些变量不能直接录入psmatch2命令里面，提示变量太多
 
 cap drop l
g l=ln(ps_nsw/(1-ps_nsw))
pstest age-re75 ps_nsw l, t(treat) raw


********一个例子*************
use JTRAIN2,clear
set seed 12345
gen ranorder=runiform()
sort ranorder

*近邻匹配，k=4
global control "age educ black hisp married re74 re75 unem74 unem75"
psmatch2 train $control, outcome(re78) n(4) logit ties ate common 
pstest $control, both graph
psgraph
bootstrap r(att) r(atu) r(ate), reps(100):psmatch2 train $control, outcome(re78) n(4) logit ties ate common 

*卡尺匹配，k=4，卡尺范围 0-0.01*
sum _pscore
dis 0.25*r(sd) //倾向匹配得分标准差的四分之一
psmatch2 train $control, outcome(re78) n(4) caliper(0.01) logit ties ate common 
pstest $control, both graph
psgraph

*半径匹配
psmatch2 train $control, outcome(re78) radius caliper(0.01) logit ties ate common
pstest $control, both graph
psgraph

*核匹配*****
psmatch2 train $control, outcome(re78) kernel kerneltype() bwidth(0.05) logit ties ate common
//默认带宽0.06，根据需要自己调整
pstest $control, both graph
psgraph
bootstrap r(att) r(atu) r(ate), reps(100):psmatch2 train $control, outcome(re78) kernel bwidth(0.05) logit ties ate common
/*--6-----局部线性回归匹配-----------------------------------------------------------
 psmatch2 depvar [indepvars] [if exp] [in range], llr outcome(varlist) 
            [kerneltype(kernel_type) pscore(varname) bwidth(real) 
			  mahalanobis(varlist) common trim(real) odds index 
			  logit quietly ate]

 ----选项----
 depvar ：处理变量。
 indepvars ：协变量。
$ llr ：局部线性回归匹配。
 outcome(varlist) ：结果变量。
$ kerneltype(kernel_type) ：指定核函数，默认为三次核。normal（gaussian核）、
                         biweight、epan（epanechnikov，默认）、uniform、tricube。
 pscore(varname) ：指定变量估计倾向得分，默认使用indepvars中的变量。
$ bwidth(real) ：指定窗宽，默认为0.8。
 mahalanobis(varlist) ：马氏匹配，指定计算马氏距离的协变量。
 common ：仅对共同取值范围内个体进行匹配，默认是对所有个体匹配。
 trim(real) ：通过删除#%的实验组数据使得控制组得分密度最低，得到共同取值范围。
 odds ：使用机会比率（p/(1-p)）进行匹配，默认使用倾向得分匹配。
 index ：使用潜变量指标=xb，而非概率。
 logit ：用logit模型估计倾向得分，默认是probit。
 quietly ：不报告倾向得分估计过程。
 ate ：报告ATE、ATU、ATT，默认只报告ATT。
 
* 注意：$ 表示除了这个选项外，其他选项都以出现，即与前面命令中的含义一样。
-----------------------------------------------------------------------------*/
/*--7-----样条匹配------------------------------------------------------------
 psmatch2 depvar [indepvars] [if exp] [in range], spline outcome(varlist) 
            [nknots(integer) pscore(varname) neighbor(integer) 
			  caliper(real) common trim(real) odds index logit 
			  ties warnings quietly ate]

 ----选项----
 depvar ：处理变量。
 indepvars ：协变量。
$ spline ：样条匹配。
 outcome(varlist) ：结果变量。
$ nknots(integer) ：指定样条平滑内点个数。默认is the fourth root of 
                                     the number of comparison units
 pscore(varname) ：指定变量估计倾向得分，默认使用indepvars中的变量。
 neighbor(integer) 进行k近邻匹配，默认k=1，即一对一匹配。
 caliper(real) ：设置卡尺epsilon，为正实数。
 common ：仅对共同取值范围内个体进行匹配，默认是对所有个体匹配。
 trim(real) ：通过删除#%的实验组数据使得控制组得分密度最低，得到共同取值范围。
 odds ：使用机会比率（p/(1-p)）进行匹配，默认使用倾向得分匹配。
 index ：使用潜变量指标=xb，而非概率。
 logit ：用logit模型估计倾向得分，默认是probit。
 ties ：包括所有倾向得分相同的并列个体，默认是按照当前数据排序选择一个个体。
 warnings ：用重复倾向得分值检验控制组（观测数据）。
 quietly ：不报告倾向得分估计过程。
 ate ：报告ATE、ATU、ATT，默认只报告ATT。
 
* 注意：$ 表示除了这个选项外，其他选项都以出现，即与前面命令中的含义一样。
-----------------------------------------------------------------------------*/
/*三组命令比较-----------------------------------------------------------*/
/* pscore,atts,attnd/attnw/attnr/attk******/
use nsw_dw, clear
drop if treat==0 //删掉控制组
append using cps_controls 
cap drop id ps
pscore treat age edu black his married nodegree re74 re75,logit comsup ///
blockid(id) pscore(ps) 

/*新变量加入高阶变量和交叉项*/
gen agesq=age*age
gen marriedre75=married*re75
gen agere74=age*re74
gen nodegreeage=nodegree*age 
gen age3=age^3
gen marriedre74=married*74
gen re742=re74^2
gen re752=re75^2

cap drop id ps
pscore treat age education black his married nodegree re74 re75 agesq ///
marriedre75 agere74 nodegreeage age3 marriedre74 re742 re752, logit comsup ///
blockid(id) pscore(ps) 

attnd re78 treat, pscore(ps)
attnd re78 treat, pscore(ps) comsup

attnd re78 treat, pscore(ps) boot reps(100) comsup // bootstrap 即汇报解析方差也汇报汇报bs方差
psmatch2 treat,pscore(ps) outcome(re78) n(1) ties
psmatch2 treat,pscore(ps) outcome(re78) n(1) ties common
psmatch2 treat if comsup==1,pscore(ps) outcome(re78) n(1) ties
bootstrap r(att),reps(100):psmatch2 treat age education black his married ///
nodegree re74 re75 agesq marriedre75 agere74 nodegreeage age3 marriedre74 ///
re742 re752, outcome(re78) logit n(1) ties common

teffects psmatch (re78) (treat age education black his ///
married nodegree re74 re75 agesq marriedre75 agere74 ///
nodegreeage age3 marriedre74 re742 re752,logit) ,atet nn(1)

gen common=_support
drop if common==0
twoway(kdensity _ps if _treat==1,lp(solid) lw(*2.5)) ///
      (kdensity _ps if _treat==0, lp(dash) lw(*2.5)), ///
	  ytitle("Density",size(*1.1)) ///
	  ylabel(,angle(0)labsize(*1.1)) ///
	  xtitle("Propensity Score",size(*1.1) ) ///
	  xscale(titlegap(2)) ///
	  xlabel(0(0.2)0.8, format(%2.1f) labsize(*1.1)) ///
	  legend(label(1 "Treat") label(2 "control") row(2) ///
      position(3) ring(0) size(*1.1)) ///
	  scheme(slmono)
twoway(kdensity _ps if _treat==1,lp(solid) lw(*2.5)) ///
      (kdensity _ps if _weight!=1& _weight!=., lp(dash) ///
	  lw(*2.5)), ///
	  ytitle("Density",size(*1.1)) ///
	  ylabel(,angle(0)labsize(*1.1)) ///
	  xtitle("Propensity Score",size(*1.1) ) ///
	  xscale(titlegap(2)) ///
	  xlabel(0(0.2)0.8, format(%2.1f) labsize(*1.1)) ///
	  legend(label(1 "Treat") label(2 "control") row(2) ///
      position(3) ring(0) size(*1.1)) ///
	  scheme(slmono)


