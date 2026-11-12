use tax,clear
gen treat = id<=2 /*产生虚拟变量*/
gen after = year>=2014 /*事件发生前后虚拟变量*/
gen treatafter =after*treat /*产生交叉变量*/
list id year q tax treat after treatafter, sep(8) ab(12) noobs
reg q after treat treatafter
tab id, gen(id) /*个体虚拟变量*/
tab year,gen(year)
reg q treatafter id1-id4 year2-year8, noconstant /*LSDV回归，无常数项*/
xtreg q treatafter i.year,fe /*固定效应*/
