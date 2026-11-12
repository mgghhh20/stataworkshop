*首先打开文件
use "D:\OneDrive - m.gduf.edu.cn\工作杂项\stata\s4poe4_statadata\food"

*接着是描述文档
describe

/*如果是提取某些数据行，list[varlist] [if] [in] [,options] */
list in 1/5
list food_exp in 1/5
list food_exp if income <=10

*创建散点图 twoway*
twoway (scatter food_exp income)
/*绘制图以stata图形扩展名-.gph保存在磁盘，twoway (scatter food_exp income)，saving(food1,replace)*/

*巩固图形绘制*
twoway (scatter food_exp income), ///*逗号不要离太近
       ylabel (0(100)600)  ///
       xlabel (0(5)35)   ///
       title(Food Expenditure Data)
	   
*回归分析*
reg food_exp income

/*拟合值及残差，生成
predict的基本语法如下：
predict [type] newvar [if] [in] [,single_options]*/
predict yhat，
predict ehat,residuals

/*弹性计算
条件边际效应atmean
平均边际效应 没有atmean*/
margins,eyex(income)atmeans

*估计误差项方差和观察估计方差和协方差*
estat vce

*运用Stata获得预测值
/*replace命令：
replace 变量名字 = 变量命令 [if] [in] [,nopromote]*/
/*Data Editor将显示的观测值为41的收入值为20*/
edit
set obs 41
replace income = 20 in 41
