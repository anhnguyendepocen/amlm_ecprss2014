# Reproducing Rabe-Hesketh & Skrondal (RHS) in R

# Chapter 2

#2.3
require(foreign)
pefr<-read.dta("http://www.stata-press.com/data/mlmus3/pefr.dta")

pefr$mean_wm <- (pefr$wm1+pefr$wm2)/2

summary(pefr$mean_wm)
sd(pefr$mean_wm)

require(ggplot2)
ggplot(pefr) +
  geom_point(aes(x=id,y=wm1,colour=1)) +
  geom_point(aes(x=id,y=wm2,colour=2)) +
  geom_hline(yintercept=mean(pefr$mean_wm)) +
  theme_bw() +
  theme(legend.position="none")

#2.5.1
pefr.long<-data.frame(id=rep(pefr$id,2),wp=c(pefr$wp1,pefr$wp2),wm=c(pefr$wm1,pefr$wm2),occasion=c(rep(1,nrow(pefr)),rep(2,nrow(pefr))))

#2.5.2
require(lme4)
vim1<-lmer(wm~1+(1|id),data=pefr.long,REML=F)

summary(vim1)

(vim1.psi<-attr(summary(vim1)$varcor$id,"stddev")^2)

(vim1.theta<-attr(summary(vim1)$varcor,"sc")^2)

(vim1.icc<-vim1.psi/(vim1.psi+vim1.theta)) # ICC


#2.6.2

require(lmerTest)

rand(vim1) #likelihood ratio test

summary(fem1<-lm(wm~factor(id),data=pefr.long))

anova(fem1,lm(wm~1,data=pefr.long)) #F-test


#2.9

pefr.long$occ2<-ifelse(pefr.long$occasion==2,1,0)

summary(cem1<-lmer(wm~occ2+(1|id),data=pefr.long,REML=F)) #crossed effects model

#2.10.3

se.bf<-sqrt(vim1.theta/length(pefr.long$id)) #fixed effects model se

se.ols<-summary(lm(wm~1,data=pefr.long))$coefficients[1,2] #ols se

require(arm)
se.b<-se.fixef(vim1) #RE model se

barplot(c(se.bf,se.ols,se.b),names=c("SE(B.F)","SE(B.OLS)","SE(B)"))

#2.11.1

ranef(vim1) #ML intercept estimates 

#2.11.2

(vim1.ebr<-vim1.psi/(vim1.psi+vim1.theta/2)) # empirical bayes shrinkage factor R

ebests<-ranef(vim1)$id*vim1.ebr

ebests

### Chapter 3
rm(list=(ls(all=T)))

sm<-read.dta("http://www.stata-press.com/data/mlmus3/smoking.dta")

#3.4.1
summary(vim2<-lmer(birwt~smoke+male+mage+hsgrad+somecoll+collgrad+married+black+kessner2+kessner3+novisit+pretri2+pretri3+(1|momid),data=sm,REML=F))

#3.5
summary(vim2null<-lmer(birwt~1+(1|momid),data=sm,REML=F))

vim2totvar<-attr(summary(vim2)$varcor$momid,"stddev")^2+attr(summary(vim2)$varcor,"sc")^2

vim2nulltotvar<-attr(summary(vim2null)$varcor$momid,"stddev")^2+attr(summary(vim2null)$varcor,"sc")^2

(vim2rsq<-(vim2totvar-vim2nulltotvar)/vim2nulltotvar)

#3.7.5

as.numeric(sm$smoke)
sm$mn_smok<-NA
sm$dev_smok<-NA
momids<-unique(sm$momid)

mean(as.numeric(sm$smoke[sm$momid==sm$momid[1]])-1,na.rm=T)

for (i in 1:nrow(sm)){
  sm$mn_smok[i]<-mean(as.numeric(sm$smoke[sm$momid==sm$momid[i]])-1,na.rm=T)
  sm$dev_smok[i]<-as.numeric(sm$smoke[i])-1-sm$mn_smok[i]
}

summary(vim3<-lmer(birwt~dev_smok+mn_smok+male+mage+hsgrad+somecoll+collgrad+married+black+kessner2+kessner3+novisit+pretri2+pretri3+(1|momid),data=sm,REML=F))

### Chapter 4
rm(list=(ls(all=T)))
gc<-read.dta("http://www.stata-press.com/data/mlmus3/gcse.dta")

summary(lm(gcse~lrt,data=gc[gc$school==1,]))

ggplot(subset(gc,school==1),aes(x=lrt,y=gcse)) +
  geom_point() +
  geom_smooth(method="lm",alpha=0,linetype=2) +
  theme_bw()

ggplot(gc,aes(x=lrt,y=gcse)) +
  geom_point(alpha=.5) +
  geom_smooth(method="lm",alpha=0,linetype=2) +
  theme_bw() +
  facet_wrap(~school)

summary(vim3<-lmer(gcse~lrt+(1|school),data=gc,REML=F))

vim3preds<-predict(vim3)

summary(vivsm3<-lmer(gcse~lrt+(1+lrt|school),data=gc,REML=F)) #random coefficients + random intercept model

rand(vivsm3) # naïve likelihood ratio test

#plot random intercept vs random coefficient model
ris<-as.data.frame(ranef(vim3)$school)
rcs<-as.data.frame(ranef(vivsm3)$school)
m3preds.ri<-as.data.frame(cbind(gc=seq(from=-30,to=30,by=20),matrix(nrow=4,ncol=65)))
m3preds.rc<-as.data.frame(cbind(gc=seq(from=-30,to=30,by=20),matrix(nrow=4,ncol=65)))
for (j in 2:ncol(m3preds.ri)){
  for (i in 1:nrow(m3preds.ri)){
    m3preds.ri[i,j]<-(.0238+ris[j-1,1])+.5633*m3preds.ri$gc[i]
  }
}
m3preds.ri<-melt(m3preds.ri,id.vars="gc")
m3preds.ri$mtype<-"ri"
for (j in 2:ncol(m3preds.rc)){
  for (i in 1:nrow(m3preds.rc)){
    m3preds.rc[i,j]<-(.0238+rcs[j-1,1])+(.5633+rcs[j-1,2])*m3preds.rc$gc[i]
  }
}
m3preds.rc<-melt(m3preds.rc,id.vars="gc")
m3preds.rc$mtype<-"rc"

m3preds.bytype<-as.data.frame(rbind(m3preds.ri,m3preds.rc))

ggplot(m3preds.bytype,aes(x=gc,y=value,group=variable)) +
  geom_line(alpha=.5) +
  facet_grid(.~mtype) +
  theme_bw()

### Chapter 10
rm(list=(ls(all=T)))
wlf<-read.dta("http://www.stata-press.com/data/mlmus3/womenlf.dta")

table(as.numeric(wlf$workstat))

wlf$workstat01<-ifelse(as.numeric(wlf$workstat)>1,1,0)

summary(logit1<-glm(workstat01~husbinc+chilpres,data=wlf,family=binomial())) #logit model

exp(coef(logit1)) #odds ratios

#10.3
rm(list=(ls(all=T)))
tn<-read.dta("http://www.stata-press.com/data/mlmus3/toenail.dta")

summary(logit2<-glm(outcome~treatment+month+treatment:month,data=tn,family=binomial())) #naïve ols

#10.5

require(rms)
robcov(logit3<-lrm(outcome~treatment+month+treatment:month,data=tn,x=T,y=T),cluster=tn$patient) #clustered standard errors

#10.7

summary(logit4<-glmer(outcome~treatment+month+treatment:month+(1|patient),data=tn,family=binomial()))


### Chapter 8

require(foreign)
pefr<-read.dta("http://www.stata-press.com/data/mlmus3/pefr.dta")

pefr.long<-data.frame(id=rep(pefr$id,2),wp=c(pefr$wp1,pefr$wp2),wm=c(pefr$wm1,pefr$wm2),occasion=c(rep(1,nrow(pefr)),rep(2,nrow(pefr))))
require(reshape2)
pefr.long2<-melt(pefr.long,id.vars=c("id","occasion"),variable.name="meth",value.name="w")
require(lme4)
summary(nvim1<-lmer(w~1+(1|id/meth),data=pefr.long2,REML=F)) #nested model - highest level first


