******标准DID*********
use t1,clear
xtset id year
xtdes
gen policy = treat*period
reg y policy x1 x2 x3 i.id i.year, robust  
 // 缺点：回归结果中显示的个体、时点虚拟变量过多
 est sto Reg
areg y policy x1 x2 x3 i.year, absorb(id) r 
 est sto Areg 
 
reghdfe  y policy x1 x2 x3, absorb(id year) vce(r)  
 // 推荐使用该命令（高维固定效应方法）
 // 回归结果中不显示个体、时点虚拟变量结果，可以控制多维固定效应
 est sto Reghdfe

 xtreg y policy x1 x2 x3 i.year,fe vce(cluster id)
 est sto XTreg
 
  diff y, treated(treat) p(period) cov(x1 x2 x3) robust
 estimates store DID_Cov
 
 * （1）结果显示在t1.xls文件中，也可以生成word版本，改为：t1.doc
 
  esttab Reg Areg Reghdfe XTreg  using t1.xls,  ///
                title("5种估计处理效应方法结果对比")  /// 可以修改成自己想要的标题
                keep(x1 x2 x3 policy)  /// 保留要显示的变量名称，此处没有要截距项
	            b(%8.4f) ar2(%8.4f) se(%8.4f) nogap  ///
	            aic bic  mtitles replace	
*【温馨提示】上述5种方法中，前4种方法处理效应估计结果一样（diff结果略有差异），
*            任选一种即可，我们推荐reghdfe命令，
*            当然，大家可以根据自己的喜好进行选择。

**********平行趋势检验**********短面板

gen event = year - 2015   					//政策发生年份 


	forvalues i=4(-1)1{
	  gen pre`i'=(event==-`i'& treat==1)
	}
	
	gen current=(event==0 & treat==1)
	
	forvalues i=1(1)5{
	  gen post`i'=(event==`i'& treat==1)
	}
	drop pre4
	
	xtreg y pre* current post* x1 x2 x3 i.year,fe clu(id)
    reghdfe  y pre* current post* x1 x2 x3, absorb(id year) clu(id)
	
	*画图
	
	coefplot, 						   						///
	keep( pre* current post* ) 		   						///
	vertical                           						///
	yline(0, lwidth(thin) lcolor(gray 13)) 					///
	xline(4, lpattern(shortdash) lcolor(maroon))			///
	xtitle("平行趋势检验" ,height(5))   						///
    ytitle("政策系数") msize(small) 			///
	ylabel(-1(1)10 ,labsize(*0.85) angle(0)) 			///
	xlabel(,labsize(*0.85)) 								///
	addplot(line @b @at,lwidth(0.5) lcolor(erose)) 			///增加点之间的连线
	ciopts(recast(rcap) lwidth(0.5) lpattern(dash) lcolor(khaki)) msymbol(Dh) msize(1.3) mcolor(navy) 	///置信区间样式
	scheme(s1mono)	//xline 里面的4是调节政策发生试点 ylabel里面-1(1)10 是调节量纲
****************
use t2,clear
xtset id year
xtdes
gen policy = treat*period
reghdfe  y policy x1 x2 x3, absorb(id year) vce(r)

gen event = year - 2015   					//政策发生年份 

	forvalues i=4(-1)1{
	  gen pre`i'=(event==-`i'& treat==1)
	}
	
	gen current=(event==0 & treat==1)
	
	forvalues i=1(1)5{
	  gen post`i'=(event==`i'& treat==1)
	}
	drop pre4
	
	xtreg y pre* current post* x1 x2 x3 i.year,fe clu(id)
    reghdfe y pre* current post* x1 x2 x3, absorb(id year) vce(r)  
	
	*画图
	
	coefplot, 						   		  ///
	keep( pre* current post* ) 		   						///
	vertical                           						///
	coeflabels(pre3="3" ///
	pre2="2"            ///
	pre1="1"            ///
	current = "0"      ///
	post1="1"          ///
	post2="2"          ///
	post3="3"          ///
	post4="4"          ///
	post5="5"          ///
	) ///
	yline(0, lwidth(thin) lcolor(gray 13)) 					///
	xline(4, lpattern(shortdash) lcolor(maroon))			///
	xtitle("Time Period" ,height(5))   						///
    ytitle("Estimated Coefficients") msize(small) 			///
	ylabel(-1(1)5 ,labsize(*0.85) angle(0)) 			///
	xlabel(,labsize(*0.85)) 								///
	addplot(line @b @at,lwidth(0.5) lcolor(erose)) 			///增加点之间的连线
	ciopts(recast(rcap) lwidth(0.5) lpattern(dash) lcolor(khaki)) msymbol(Dh) msize(1.3) mcolor(navy) 	///置信区间样式
	scheme(s1mono)	
*********平行趋势检验 长面板
	use t3,clear
xtset id year
xtdes
gen policy = treat*period
reghdfe  y policy x1 x2 x3, absorb(id year) vce(r)  

gen event = year - 2003   					//政策发生年份 
    replace event = -7 if event <= -7

	forvalues i=7(-1)1{
	  gen pre`i'=(event==-`i'& treat==1)
	}
	
	gen current=(event==0 & treat==1)
	
	replace event = 13 if event >= 13
	forvalues i=1(1)13{
	  gen post`i'=(event==`i'& treat==1)
	}
	drop pre7 //将这一期作为基准组，很重要！！！，防止出现共线性
	
reghdfe y pre* current post* x1 x2 x3, absorb(id year) vce(r)  
	
	*画图
	coefplot, baselevels						   		  ///
	keep( pre* current post* ) 		   						///
	vertical /// 
	yline(0, lwidth(thin) lcolor(gray 13)) 	    /// 加入y=0这条虚线
	xline(7, lpattern(shortdash) lcolor(maroon)) ///画垂直于横轴的基期虚线
	xtitle("Time Period" ,height(5))   						///
    ytitle("Estimated Coefficients") msize(small) 			///
	ylabel(-2(1)6 ,labsize(*0.85) angle(0)) 			///
	xlabel(,labsize(*0.85)) 								///
	addplot(line @b @at,lwidth(0.5) lcolor(erose)) 			///增加点之间的连线
	ciopts(recast(rcap) lwidth(0.5) lpattern(dash) lcolor(khaki)) msymbol(Dh) msize(1.3) mcolor(navy) 	///置信区间样式
	scheme(s1mono)	
*********安慰剂检验***********
gen did=treat*period
reghdfe y did x1 x2 x3,absorb(id year) vce(r)
cap erase "simulations.dta"	
permute did beta = _b[did] se=_se[did] df=e(df_r),reps(1000) rseed(9999) ///
saving("simulations.dta"):reghdfe y did x1 x2 x3,absorb(id year) vce(r) 

use "simulations.dta",clear
gen t_value=beta/se
gen p_value=2*ttail(df,abs(beta/se))
dpplot beta,xline(0.2,lp(dash)) xtitle("Estimatior") yline(0.1,lp(dash)) ytitle("Density")
dpplot t_value,xtitle("T-value")ytitle("Density")
dpplot p_value,xtitle("P-value")ytitle("Density")
twoway(scatter p_value beta)(kdensity beta, yaxis(2)) //系数和p值的量纲不一样,尽量使用这个命令
twoway(scatter p_value beta)(kdensity beta)

//请使用lso2数据，做两控区政策效应评估，做平行趋势检验 安慰剂检验//

*********多时点DID****************
use bacon_example.dta,clear
rename post policy

xtreg asmrs policy pcinc asmrh cases i.year, fe robust //这
reghdfe asmrs policy pcinc asmrh cases, absorb(stfips year) clu(stfips) //twfe

gen event= year-_nfd
replace event=-4 if event<-4
bys stfips: egen t=max(policy) //生成实验组虚拟变量
gen dum_t=(t==1)

replace event=5 if event>5 //选取政策前后观察的截止年份
forvalues i= 4(-1)1{      
	gen pre`i'=(event==-`i'&dum_t==1)
}
gen current = (event==0 &dum_t==1) //政策发生时点
forvalues i=1(1)5{
	gen post`i'=(event==`i'&dum_t==1) //政策发生后
}
drop pre4 //以删掉的为基期
xtreg asmrs pre* current post* pcinc asmrh cases i.year,fe clu(stfips) //里面不要有表政策变量
xtreg asmrs policy pcinc asmrh cases i.year,fe clu(stfips)
reghdfe asmrs  pre* current post* pcinc asmrh cases, absorb(stfips year) clu(stfips) 

*****平行趋势检验作图******8
coefplot, 						   						///
	keep( pre* current post* ) 		   						///
	vertical                           						///
	yline(0, lwidth(thin) lcolor(gray 13)) 					///
	xline(4, lpattern(shortdash) lcolor(maroon))			///
	xtitle("Time Period" ,height(5))   						///
    ytitle("Estimated Coefficients") msize(small) 			///
	ylabel(-40(5)10 ,labsize(*0.85) angle(0)) 			///
	xlabel(,labsize(*0.85)) 								///
	addplot(line @b @at,lwidth(0.5) lcolor(erose)) 			///增加点之间的连线
	ciopts(recast(rcap) lwidth(0.5) lpattern(dash) lcolor(khaki)) msymbol(Dh) msize(1.3) mcolor(navy) 	///置信区间样式
	scheme(s1mono)		

****Goodmanbacon分解*************
bacondecomp asmrs policy //需要安装 ssc install bacondecomp, replace
ddtiming asmrs policy, i(stfips) t(year) //需要安装 不能的话就下载放进ado文件夹 我的电脑装了没反应，你们自己试试。


*******一个完整的练习********
clear
set more off
use divorce
** panel setting
xtset state year
gen year2=year^2
** benchmark
reghdfe div_rate unilateral divx* if year>1967 & year<1989 [w=stpop], absorb(i.state i.year) cl(state)
** state-specific trend
reghdfe div_rate unilateral divx* if year>1967 & year<1989 [w=stpop], absorb(i.state i.year i.state#c.year) cl(state)
reghdfe div_rate unilateral divx* if year>1967 & year<1989 [w=stpop], absorb(i.state i.year i.state#c.year i.state#c.year2) cl(state)
**平行趋势检验***
gen event=lfdivlaw-year  //产生相对时间变量
replace event=-20 if event<-20 //删除端
replace event=12 if event>12
*生成提前变量 当期变量 和后期变量
forvalues i=1/20{
	gen pre`i'=(event== -`i')
}
gen current=(event==0)
forvalues i=1/12{
	gen post`i'=(event==`i')
}
drop pre11-pre20
reghdfe div_rate pre* current post* divx* if year>1967 & year<1989 [w=stpop], absorb(i.state i.year) cl(state)

coefplot, 						   						///
	keep( pre* current post* ) 		   						///
	vertical                           						///
	coeflabels(pre10=-10 pre9=-9 pre8=-8 pre7=-7 pre6=-6 pre5=-5 pre4=-4 ///
	pre3=-3 pre2=-2 pre1=-1 current=0 post1=1 post2=2 post3=3 post4=4 ///
	post5=5 post6=6 post7=7 post8=8 post9=9 post10=10 post11=11 post12=12) ///
	yline(0, lwidth(thin) lcolor(gray 13)) 					///
	xline(11, lpattern(shortdash) lcolor(maroon))			///
	xtitle("Time Period" ,height(5))   						///
    ytitle("Estimated Coefficients") msize(small) 			///
	ylabel(-2(0.5)2 ,labsize(*0.85) angle(0)) 			///
	xlabel(,labsize(*0.85)) 								///
	addplot(line @b @at,lwidth(0.5) lcolor(erose)) 			///增加点之间的连线
	ciopts(recast(rcap) lwidth(0.5) lpattern(dash) lcolor(khaki)) msymbol(Dh) msize(1.3) mcolor(navy) 	///置信区间样式
	scheme(s1mono)	
**控制随时间变化的线性趋势**这个回归里面作用不好
tab(event),missing
reghdfe div_rate pre* current post* divx*  event if year>1967 & year<1989 [w=stpop], absorb(i.state i.year i.state#c.event) cl(state)
	
** dynamic effects
reghdfe div_rate pre* current post* divx* if year>1967 & year<1989 [w=stpop], absorb(i.state i.year) cl(state)

use divorce,clear
mat b = J(500,1,0)
mat se = J(500,1,0)
mat p = J(500,1,0)
*抽样方案一：在变量year中随机抽取50个数据依次作为这政策时间
forvalues i=1/500{
	use divorce,clear
	xtset state year
	sample 50, count
	keep year
	mkmat year, matrix(sampleyear) //向量转化为矩阵，方便调用
	use divorce, clear
	xtset state year
	gen treat = 0
	*生成单位时间处理变量
	foreach j of numlist 1/100{
		replace treat = 1 if (state==`j'&year>=sampleyear[`j',1])		
	}
	gen year2=year^2
	qui reghdfe div_rate treat divx* if year>1967 & year<1989 [w=stpop], absorb(i.state i.year i.state#c.year i.state#c.year2) cl(state)
	* 存储并计算所需回归结果
	mat b[`i',1]=_b[treat]
	mat se[`i',1]=_se[treat]
	mat p[`i',1]= 2*ttail(e(df_r),abs(_b[treat]/_se[treat]))
}
**绘图
svmat b, names(coef)
svmat se, names(se)
svmat p, names(pvalue)

drop if pvalue1==.
label var pvalue p值
label var coef1 估计系数

#delimit;
twoway(scatter pvalue1 coef1,xline(0,lwidth(0.2) lp(shortdash))
      xlabel(,grid) xtitle(估计系数) ytitle(p值)
	  xline(0.43,lp(shortdash))
	  yline(0.1, lpattern(shortdash) lcolor(black)) msymbol(smcircle_hollow) mcolor(orange) legend(off))
	  (kdensity coef1, title(安慰剂检验) yaxis(2));
# delimit cr
*抽样方案2 伪实验伪政策组抽样
use divorce,clear
mat b = J(500,1,0)
mat se = J(500,1,0)
mat p = J(500,1,0)
forvalue i=1/500{
	use divorce,clear
	xtset state year
	keep if year==1983 //只留一年的数据，这样可以把所有界面保留下来
	sample 9 // 随机选择9个截面，有多少个试点就改写成数字多少，和真实的实验组的数量保持一致
	keep state
	save statecode.dta,replace
	merge 1:m state using divorce
	gen treat =(_merge==3)
	save matchstate`i'.dta,replace
	**上面是生成伪实验组，下面是生政伪政策变量
	use divorce, clear
	bsample 1,strata(state) //strata(varlist):用于指定类层的变量,即在每个类层内选取样本
	keep year
	save matchyear.dta,replace
	mkmat year, matrix(sampleyear)
	use matchstate`i'.dta, replace
	xtset state year
	gen treat1=0
	foreach j of numlist 1/9{
	replace treat1=1 if (state==`j'& year>=sampleyear[`j',1])
	} //总样本有多少个个体，就写多少个。
	gen year2=year^2
	qui reghdfe div_rate treat1 divx* if year>1967 & year<1989 [w=stpop], absorb(i.state i.year i.state#c.year i.state#c.year2) cl(state)
	* 存储并计算所需回归结果
	mat b[`i',1]=_b[treat1]
	mat se[`i',1]=_se[treat1]
	mat p[`i',1]= 2*ttail(e(df_r),abs(_b[treat1]/_se[treat1]))	
}
svmat b, names(coef)
svmat se, names(se)
svmat p, names(pvalue)

drop if pvalue1==.
label var pvalue p值
label var coef1 估计系数

#delimit;
twoway(scatter pvalue1 coef1,xline(0,lwidth(0.2) lp(shortdash))
      xlabel(,grid) xtitle(估计系数) ytitle(p值)
	  xline(0.43,lp(shortdash))
	  yline(0.1, lpattern(shortdash) lcolor(black)) msymbol(smcircle_hollow) mcolor(blue) legend(off))
	  (kdensity coef1, title(安慰剂检验) yaxis(2));
	  
# delimit cr
***删除保存的500个matchstate数据
forvalue i=1/500{
	erase matchstate`i'.dta
}
