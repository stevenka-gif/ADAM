*******************************************************************;
*Program Name       : adtte.sas
*Protocol/Study     : D933IC00003 
*Type               : ADAM dataset 
*Description        : To create ADTTE dataset
*Author             : Stephen Kangu
*
*Date created       : 21JUL2023
*Input datasets     : sdtm.tr,sdtm.supptr,sdtm.tu,sdtm.supptu,adam.adsl,adam.adtr,adam.adresp,sdtm.ds,sdtm.suppds,sdtm.rs,sdtm.cm,sdtm.vs, sdtm.lb,sdtm.ho,sdtm.ae    
*
*Macro used         : %combinesdtm, %checklog   
*Function used      : 
*
*******************************************************************;
*
*Change History     :
*Reason for change  :
*Date changed       :
*
*******************************************************************;
*Clear work library;
proc datasets lib=work nolist memtype=data kill;
run;
quit;

*Clear log;
dm 'log; clear; ';
run;
quit;


*To read in required sdtm datasets;
%combinesdtm(tu); 
%combinesdtm(tr);
%combinesdtm(ds);
%combinesdtm(dm);

*To derive subject investigator level flags;
**ONTPFL: Any Non Target Lesions Present; 
proc sort data =tu out =ontpfl (keep= studyid usubjid tueval rename=(tueval=parqual))nodupkeys; 
  by usubjid tueval;
  where tuloc ne "" and index(tulnkid,"NT")>0 and tueval ="INVESTIGATOR" ;   
run;   

data ontpfl_1;
  length ontpfl $2;   
  set ontpfl;
  ontpfl="Y";
run;   


**ONTVBPFL: Valid Baseline for NTL at Entry;
proc sort data = tu out =ontvbpfl(keep =studyid usubjid tueval rename =(tueval =parqual)) nodupkeys;  
  by usubjid tueval;   
  where tuloc ne "" and index(tulnkid,"NT")>0 and tueval ="INVESTIGATOR" and tublfl ="Y";
run;   

data ontvbpfl_1;
  length ontvbpfl $2;   
  set ontvbpfl;
  ontvbpfl="Y";
run; 

**OTLPFL: Target Lesions Present;
proc sort data =adam.adtr out =otlpfl (keep =studyid usubjid parqual) nodupkeys; 
  by usubjid parqual;  
  where aval > 0 and paramcd in ("TRLONDD")and parqual="INVESTIGATOR";
run; 

data otlpfl_1;
  length otlpfl $2;   
  set otlpfl;
  otlpfl="Y";
run; 

**OTLVBPFL:	Valid Baseline for TL at Entry;
proc sort data =tu out= otlvbpfl(keep =studyid usubjid tueval rename =(tueval =parqual)) nodupkeys;
  by usubjid tueval;   
  where tuloc ne "" and index(tulnkid,"T") >0 and tublfl ="Y" and tueval ="INVESTIGATOR";
run; 

data otlvbpfl_1;
  length otlvbpfl $2;   
  set otlvbpfl;
  otlvbpfl="Y";
run; 
 
*To combine subject investigator level flags;
data flags;  
  merge ontpfl_1 
        ontvbpfl_1
		otlpfl_1
		otlvbpfl_1;
  by studyid usubjid parqual;
run;


*To check if there independent assessor data from tr dataset;
proc sql noprint;  
  create table assessor_1 as
  select distinct usubjid, treval, visitnum, trdtc
  from tr
  where trgrpid in ("TARGET") and treval in ("INDEPENDENT ASSESSOR"); 

  create table assessor_2 as 
  select *, count(usubjid) as cnt 
  from assessor_1
  group by usubjid
  having cnt > 0;  

  select count(usubjid)
  into :obs trimmed
  from assessor_2; 
quit;   
%put obs =&obs.; 

*Subjects used in the efficacy analysis;
proc sort data =adam.adsl out =_itt(keep =usubjid studyid); 
  by usubjid studyid;
  where fasfl ="Y"; 
run; 

*data set containing date of data cut (dco); 
data _itt1(drop=dco);  
  length dco $19;   
  set _itt;
  dco ="&dcodate.";
  cutoffdt =input(dco,e8601da.); 
  format cutoffdt date9.; 
run;


*To derive startdt: Time to event origin date ;
*We consider startdt eq to date of randomization since the study is randomised;  
data _startdt(drop= dsdecod);   
  set ds(keep =studyid usubjid dsstdtc dsdecod);
  where index(upcase(dsdecod),"RANDOMIZATION CODE ALLOCATED")>0;
  startdt =input(dsstdtc,e8601da.);
  format startdt date9.;  
run;   


*To create record for each eval possibility;
data _startdt1;
  length parqual $200;   
  set _startdt;  
  %if &obs. gt 0 %then %do; 
     parqual="INDEPENDENT ASSESSOR";
     output;  
  %end;  
  parqual ="INVESTIGATOR";
  output;  
run;

proc sort data = _startdt1 out =_startdt2;
  by usubjid parqual;   
run;  

proc sort data=tr(rename=(treval=parqual)) out=_dummy1(keep=usubjid parqual) nodupkeys;
  by usubjid parqual;
run;

data _startdt3_;
  merge _startdt2(in=a) _dummy1(in=b);
  by usubjid parqual;
  if a and parqual="INDEPENDENT ASSESSOR" and not b then delete; 
run;  


proc sort data =_startdt3_ out= _startdt3; 
  by studyid usubjid parqual;
run;    

*To get visit response dataset from adresp and drop records after PD; 
*To prepare for derivation of OEVDT: -Last Evaluable assessment prior to progression; 
proc sort data =adam.adresp out =_postpd; 
  by usubjid parqual astdt;
  where paramcd ="TRVROV";
run;  


data _postpd1;   
  set _postpd;  
  by usubjid parqual astdt; 
  retain pd pdflag ; 
  if first.parqual then do; 
    pd =0; 
    pdflag =0;  
  end;
  if opdvrfl ="Y" then pd =1; 
  if not pd then pdflag =0 ; *No PD; 
  else pdflag +1;  **1st PD =1 , 2nd PD =2,...; 
  if pdflag ge 2 then  delete;  **These are records after 1st progression;  
run;

*To get the earliest opdvdt at any visit (where PARAMCD=TRVROV);
proc sql noprint;   
  create table _minopdv as 
  select distinct studyid, usubjid,parqual,paramcd, min(opdvdt) as minopdv format =date9. 
  from adam.adresp
  where opdvrfl ="Y" and paramcd ="TRVROV"
  group by studyid, usubjid,parqual
  order by studyid, usubjid,parqual; 
quit;
 
****Start of derivation of oevdt: Date of last evaluable visit*;
*Add minopdv to all records;
*Keep astdtc that are before to minopdv;   
data _aestdt1(keep =studyid usubjid parqual astdt aendt minopdv osctrfl);
  merge _postpd1(rename=(avalc =avalcr paramcd=trvparam) where =(avalcr in ("CR","PR","SD"))
  keep = studyid usubjid parqual  astdt aendt paramcd avalc osctrfl)
  _minopdv (in =a); 
  by studyid usubjid parqual;

  if (astdt le minopdv and astdt ne .) or (minopdv eq .);
run;


*To get latest aendtc before minopdv;
proc sort data = _aestdt1 out =_aestdt2;
  by studyid usubjid parqual aendt;
run;  

data _astdt3;
  set _aestdt2;
  by studyid usubjid parqual aendt;
  if last.parqual;
 run; 


*Add startdt to last astdtc;
*To derive oevdt: Date of last evaluable visit;
data _astdt3_;
  merge _astdt3 _minopdv (keep=studyid usubjid parqual minopdv rename=(minopdv=minopdv2));
  by studyid usubjid parqual;
run;  

data _astdt3;
  merge _astdt3_(in=a) adam.adsl(keep=usubjid  studyid randdt);
  by usubjid;
  if a;
run;

data _progn1;   
   merge _startdt3 _astdt3;
   by studyid usubjid parqual;
   if n(astdt,startdt)=2 then oevdt =max(aendt,startdt);
   else if aendt ne .  then oevdt =aendt;  
   else if startdt ne . then oevdt =startdt;
   else oevdt =.;
 
  *To calculate days from randomisation to previous visit;
  if n(oevdt,randdt)=2 then oevdy=oevdt - randdt; 

  *To calculate opdevval;
  if .<oevdy<274 then opdevval =126;
  else if 274<=oevdy<=329 then opdevval=154; 
  else if oevdy>329 then opdevval =182; 
  else if opdevval =. then opdevval =126;
  format oevdt date9. ; 
run; 

********End of derivation of OEVDT: Date of last Evaluable Visit******


*Get time of death and termination reason;
*Get date of death;
proc sort data =adam.adsl out=_death(keep =studyid usubjid dthdtc);
  by studyid usubjid; 
  where fasfl ="Y" and not missing(dthdtc);
run;  

*Get termination reason;
proc sort data =ds out =_ds_(keep =studyid usubjid dsdecod dsstdtc dsterm); 
  by studyid usubjid; 
  where dsterm like "WITHDRAWN FROM STUDY DUE TO%" or dsterm like "LOST TO FOLLOW-UP%" or dsterm like "WITHDRAWAL BY SUBJECT%"
        or dsterm like "DEATH" or dsterm like "SCREEN FAILURE" or dsterm like "STUDY TERMINATED BY SPONSOR" or dsterm like "OTHER";   
run; 

*In case a subject has two observations;
data _ds;  
  set _ds_;
  by studyid usubjid;
  if first.usubjid;
run;  


*To get progressive disease information from adam.adresp dataset;
proc sql noprint;   
  create table _pd as 
  select studyid, usubjid, parqual, opdvrfl,opdevady,osctrfl,min(opdvdt) as min_pddate format =date9.
  from adam.adresp
  where paramcd eq "TRVROV" and opdvrfl ="Y"
  group by studyid,usubjid
  order by studyid, usubjid, parqual;
quit;  

*If more than one PD response,keep the first one; 
data _pd2;
  set _pd;   
  by studyid usubjid parqual;
  if first.parqual;  
run; 

 
*To get date of subsequent cancer therapy and date of discontinuation from adsl to be used in deriving EVNTDESC;
data _sbts;   
  set adam.adsl(keep =studyid usubjid sbtstdtc dcsdt fasfl);
  where fasfl ="Y";
run;  

data _progn2; 
  merge _progn1(in=a) 
        _pd2
        _death
        _sbts
        _itt1(in=b)
        _ds;
  by studyid usubjid;  
  if a and b;  
run; 

 
**To derive adt,cnsdtdsc,cnsr,evntdesc,param,paramcd and aphase in progression free survival (Unadjusted);
data trprogn(keep =studyid usubjid parqual param paramcd aval startdt cnsdtdsc oevdt adt cnsr evntdesc ocendy aphase);
  length cnsdtdsc evntdesc aphase  param $200  paramcd $8 ;
  set _progn2;
  minor_pd=coalesce(minopdv,min_pddate);
  if not missing(dsstdtc) then ds_date =input(dsstdtc,e8601da.);
  if not missing(sbtstdtc) then sbts =input(sbtstdtc,e8601da.);  

  *To derive adt;
  if minor_pd ne . then adt =minor_pd;
  else if not missing(dthdtc) then adt=input(dthdtc,yymmdd10.);
  else if not missing(oevdt)  then adt =oevdt; 
  else adt =startdt;  
  format adt date9.;

  *To derive cnsr;
   if opdvrfl ="Y" or not missing(dthdtc)then cnsr =0; 
   else cnsr =1; 

   *To derive evntdesc;
   if opdvrfl ="Y" then evntdesc="RECIST progression";
   else if cnsr =0 then evntdesc ="Death";
   else if  index(dsterm,"LOST TO FOLLOW-UP")>0 then evntdesc="Lost to follow-up";
   else if upcase(dsterm) in ("WITHDRAWN FROM STUDY DUE TO WITHDRAWAL BY SUBJECT",
                               "STUDY DISCONTINUED DUE TO SUBJECT DECISION",
                               "WITHDRAWAL BY SUBJECT",
                               "WITHDRAWN FROM STUDY DUE TO CONSENT WITHDRAWAL BY SUBJECT")then evntdesc ="Withdrawn consent";
   else if (upcase(dsterm) in ("DEATH" ,"SCREEN FAILURE" , "OTHER")) or (upcase(dsterm) in ("STUDY TERMINATED BY SPONSOR") 
         and ds_date ne cutoffdt) then evntdesc ="Discontinued study (any other specified reason for discontinuing study)";
   else evntdesc ="Alive & progression free";

   *To derive cnsdtdsc;
   if cnsr =1 then cnsdtdsc ="Last evaluable RECIST assessment, or randomisation date if no evaluable post baseline assessments";

   *To derive aphase;
   if missing(sbts) and cnsr =1 then aphase ="No subsequent therapy without progression"; 
   else if missing(sbts) and cnsr =0 then aphase ="No subsequent therapy with progression";
   else if not missing(sbts) and cnsr =1 then aphase ="No progression"; 
   else if n(adt,sbts) =2 and adt lt sbts then aphase ="After progression";
   else if n(adt,sbts) =2 and adt gt sbts then aphase ="Before progression";
   else if n(adt,sbts) =2 and adt eq sbts then aphase ="After progression";
   else if n(adt,sbts) =2 and adt eq sbts then aphase ="Before progression";

   *To derive ocedy;
   if cnsr =1 then ocendy =cutoffdt -adt; 

   *To derive aval;
   if n(adt,startdt)=2 then do; 
     if adt ge startdt then  aval = (adt -startdt)+1; 
     else aval =adt -startdt;   
   end; 
   
   *To set param & paramcd;
   paramcd ="TRPROGN";
   param ="Progression-free survival (unadjusted)";    
run; 
 
   
***To derive Progression-free survival (time adjust.)param and associated variables;
***To get evntdesc for TRPROGT from TRPROGT;    
data _evnt;  
  set trprogn(keep =usubjid evntdesc cnsr rename =(evntdesc =evnt cnsr =cnsrn));
run; 

data _progt1;   
  merge _progn2 _evnt;   
  by usubjid;  
run;  


data _progt2;
  length cnsdtdsc aphase $200;
  set _progt1; 
  minor_pd=coalesce(minopdv,min_pddate);
  if not missing(dsstdtc) then ds_date =input(dsstdtc,e8601da.);
  if not missing(sbtstdtc) then sbts =input(sbtstdtc,e8601da.); 
  if not missing(dthdtc) then d_date =input(dthdtc,e8601da.);
  if n(d_date,oevdt)=2 then diff= d_date -oevdt;  

  *To derive adt;
  if opdvrfl ="Y" and opdevady le opdevval then adt =minor_pd;
  else if not missing(dthdtc) and n(diff,opdevval) and diff le opdevval then adt =d_date;
  else if not missing(oevdt) then adt =oevdt;
  else adt =startdt;
  format adt date9.; 

  *To derive cnsr;
  if opdvrfl ="Y"  and n(opdevady,opdevval)=2 and opdevady le opdevval or (not missing(dthdtc) and diff le opdevval) then cnsr =0;
  else cnsr =1; 

  *To derive cnsdtdsc;
  if cnsr =1 then cnsdtdsc ="Last evaluable RECIST assessment, or randomisation date if no evaluable post baseline assessments";

  *To derive ocendy;
  if n(cutoffdt,adt)=2 and cnsr =1 then ocendy =cutoffdt -adt; 

  *To derive aval;
  if n(adt,startdt)=2 then do; 
    if adt ge startdt then  aval = (adt -startdt)+1; 
    else aval =adt -startdt;   
  end;   

   *To derive aphase;
   if missing(sbts) and cnsr =1 then aphase ="No subsequent therapy without progression"; 
   else if missing(sbts) and cnsr =0 then aphase ="No subsequent therapy with progression";
   else if not missing(sbts) and cnsr =1 then aphase ="No progression"; 
   else if n(adt,sbts) =2 and adt lt sbts then aphase ="After progression";
   else if n(adt,sbts) =2 and adt gt sbts then aphase ="Before progression";
   else if n(adt,sbts) =2 and adt eq sbts then aphase ="After progression";
   else if n(adt,sbts) =2 and adt eq sbts then aphase ="Before progression";
run;  

*To get target lesion visit response from response dataset;
data _pdvr;  
 set adam.adresp; 
 where paramcd in ("TRVRTL","TRVRNTL","TRVRNEW"); 
 keep studyid usubjid avalc paramcd parqual adt visitnum; 
run; 

proc sql noprint;   
  create table _pdvr as 
  select studyid, usubjid, avalc , parqual,paramcd as parmcd, adt as dt, visitnum
  from adam.adresp
  where paramcd in ("TRVRTL","TRVRNTL","TRVRNEW")
  order by studyid,usubjid;   
quit;   

*To get earliest PD date from response data;
proc sql noprint; 
  create table _pddate as 
  select studyid, usubjid, parqual, min(opdvdt)as prog_d format =date9.,opdvrfl,visitnum as vsnum
  from adam.adresp
  where opdvrfl in ("Y") and not missing(opdvdt)
  group by studyid,usubjid
  order by studyid,usubjid;
quit; 

data _pddate1; 
  merge _pdvr _pddate(in=a);
  by studyid usubjid; 
  if a and vsnum eq visitnum and dt ne .;  
 run; 
   
*To have one new lesion record per usubjid and prog_d;
proc sort data =_pddate1 out =_pddate2;  
  by studyid usubjid parqual parmcd prog_d; 
run;  

data _pddate3;   
  set _pddate2;
  by studyid usubjid parqual parmcd prog_d;
  if first.parmcd ne 1 and parmcd in ("TRVRNEW")then delete;
run;   

proc transpose data =_pddate3 out =_pddate4(drop =_:); 
  by studyid usubjid parqual  prog_d;
  id parmcd;
  var avalc;  
run;  
 
*To merge _pddate with _progt2 by studyid, usubjid and parqual;
data _progt3;  
  merge _progt2(in=a) _pddate4; 
  by studyid usubjid parqual;   
  if a;  
run;   


*To derive evntdesc;  
data trprogt(keep =studyid usubjid parqual param paramcd aval startdt cnsdtdsc oevdt adt cnsr evntdesc ocendy aphase);
  length evntdesc param $200  paramcd $8;
  set _progt3;

  *To derive evntdesc;
  if cnsr =0 and opdvrfl ="Y" then do;
    if trvrtl ="PD"  and trvrntl ="PD" and trvrnew ="Y" then evntdesc ="RECIST progression with target, non target and new lesions";
	else if trvrtl ="PD"  and trvrntl ="PD" and trvrnew ^="Y" then evntdesc ="RECIST progression with target and non target lesions only";
    else if trvrtl ="PD"  and trvrntl ^="PD" and trvrnew ^="Y" then evntdesc ="RECIST progression with target lesions only";
    else if trvrtl ="PD"  and trvrntl ^="PD" and trvrnew ="Y" then evntdesc ="RECIST progression with target and new lesions only";
    else if trvrtl ^="PD"  and trvrntl ="PD" and trvrnew ^="Y" then evntdesc ="RECIST progression with non target lesions only";
    else if trvrtl ^="PD"  and trvrntl ="PD" and trvrnew ="Y"  then evntdesc="RECIST progression with non target and new lesions only";
    else if trvrtl ^="PD"  and trvrntl ^="PD" and trvrnew ="Y"  then evntdesc="RECIST progression with new lesions only";
    else if trvrtl ^="PD"  and trvrntl ^="PD" and trvrnew ^="Y"  then evntdesc="RECIST progression without target, non target nor new lesions";
  end; 
 else if cnsr =0 then  evntdesc="Death";
 else if cnsrn =0 and evnt ="RECIST progression" then evntdesc ="Censored RECIST progression";
 else if cnsrn =0 and evnt ="Death" then evntdesc ="Censored death";
 else if index(upcase(dsterm),"LOST TO FOLLOW-UP") >0 then evntdesc ="Lost to follow-up";
 else if upcase(dsterm) in ("WITHDRAWN FROM STUDY DUE TO WITHDRAWAL BY SUBJECT",
                             "STUDY DISCONTINUED DUE TO SUBJECT DECISION",
                              "WITHDRAWAL BY SUBJECT",
                              "WITHDRAWN FROM STUDY DUE TO CONSENT WITHDRAWAL BY SUBJECT") then evntdesc ="Withdrawn consent";

 else if upcase(dsterm) in ("DEATH", "SCREEN FAILURE" , "OTHER") or (upcase(dsterm) in ("STUDY TERMINATED BY SPONSOR") 
    and ds_date ne cutoffdt) then evntdesc ="Discontinued study  (any other specified reason for discontinuing study)";
 else evntdesc ="Alive & progression free";

 *To derive param and paramcd;
  paramcd ="TRPROGT";
  param ="Progression-free survival (time adjust.)"; 
run;   


**To derive Progression-free survival (evaluation-time bias) param and associated variables;
data _progm;  
  merge _evnt _progn2(in=a);
  by usubjid;  
  if a;  
run;   

 
data trprogm(keep =studyid usubjid parqual param paramcd aval startdt cnsdtdsc oevdt adt cnsr evntdesc ocendy);
  length evntdesc cnsdtdsc param $200 paramcd $8;   
  set _progm;
  minor_pd=coalesce(minopdv,min_pddate);
  if not missing(dsstdtc) then ds_date =input(dsstdtc,e8601da.);
  if not missing(sbtstdtc) then sbts =input(sbtstdtc,e8601da.); 
  if not missing(dthdtc) then d_date =input(dthdtc,e8601da.);
  if n(d_date,oevdt)=2 then diff= d_date -oevdt;

  *To derive adt;
  if opdvrfl ="Y" and osctrfl^="Y" and n(opdevady,opdevval)=2 and opdevady le opdevval then adt =floor((oevdt+minor_pd)/2);
  else if not missing(dthdtc) and n(diff,opdevval)=2 and diff le opdevval then adt =d_date;
  else if not missing(oevdt) then adt = oevdt;   
  else adt =startdt;
  format adt date9.;

  *To derive cnsr;
  if opdvrfl ="Y" and n(opdevady,opdevval)=2 and opdevady le opdevval or not missing(dthdtc) and n(diff,opdevval)and 
     diff le opdevval then cnsr =0;   
  else cnsr =1; 

  *To derive evntdesc; 
  if cnsr =0 and opdvrfl ="Y" then evntdesc ="RECIST progression";
  else if cnsr =0 then evntdesc ="Death";
  else if cnsr =1 and evnt ="RECIST progression"  then evntdesc ="Censored RECIST progression";
  else if cnsr =1 and evnt ="Death" then evntdesc ="Censored death";
  else if index(upcase(dsterm),"LOST TO FOLLOW-UP")>0 then evntdesc ="Lost to follow-up";
  else if upcase(dsterm) in ("WITHDRAWN FROM STUDY DUE TO WITHDRAWAL BY SUBJECT",
                             "STUDY DISCONTINUED DUE TO SUBJECT DECISION",
                              "WITHDRAWAL BY SUBJECT",
                              "WITHDRAWN FROM STUDY DUE TO CONSENT WITHDRAWAL BY SUBJECT") then evntdesc ="Withdrawn consent";
  else if upcase(dsterm) in ("DEATH", "SCREEN FAILURE" , "OTHER") or (upcase(dsterm) in ("STUDY TERMINATED BY SPONSOR") 
    and ds_date ne cutoffdt) then evntdesc ="Discontinued study  (any other specified reason for discontinuing study)";
 else evntdesc ="Alive & progression free"; 

  *To derive cnsdtdsc;
  if cnsr =1 then cnsdtdsc = "Last evaluable RECIST assessment, or randomisation date if no evaluable post baseline assessments"; 

  *T derive ocendy;
  if cnsr =1 and n(cutoffdt,adt)=2 then ocendy = cutoffdt-adt;

  *To derive aval;
  if n(adt,startdt)=2 then do; 
    if adt ge startdt then  aval = (adt -startdt)+1; 
    else aval =adt -startdt;   
  end; 

  *To derive param and paramcd;
  paramcd ="TRPROGM"; 
  param ="Progression-free survival (evaluation-time bias)";
    
run;  
 

***To derive Progression-free survival (attrition bias) param and associated variables;
****Incoporating subjects started subsequent cancer therapy by early scan at visit***;
*To eliminate records who started subsequent cancer therapy by  early scan at visit where osctrfl ne "Y";   
*Add startdt to last astdtc;
*To derive oevdt: Date of last evaluable visit where osctrfl ne "Y";
*To get latest aendtc before minopdv;
proc sort data = _aestdt1 out =_osctrfl2;
  by studyid usubjid parqual aendt;
  where osctrfl ne "Y";
run;  

data _osctrfl3;
  set _osctrfl2;
  by studyid usubjid parqual aendt;
  if last.parqual;
 run; 


*Add startdt to last astdtc;
*To derive oevdt: Date of last evaluable visit;
data _osctrfl3_;
  merge _osctrfl3 _minopdv (keep=studyid usubjid parqual minopdv rename=(minopdv=minopdv2));
  by studyid usubjid parqual;
run;  

data _osctrfl3;
  merge _osctrfl3_(in=a) adam.adsl(keep=usubjid  studyid randdt);
  by usubjid;
  if a;
run;

data _proga1;   
   merge _startdt3 _osctrfl3;
   by studyid usubjid parqual;
   if n(astdt,startdt)=2 then oevdt =max(aendt,startdt);
   else if aendt ne .  then oevdt =aendt;  
   else if startdt ne . then oevdt =startdt;
   else oevdt =.;
 
  *To calculate days from randomisation to previous visit;
  if n(oevdt,randdt)=2 then oevdy=oevdt - randdt; 

  *To calculate opdevval;
  if .<oevdy<274 then opdevval =126;
  else if 274<=oevdy<=329 then opdevval=154; 
  else if oevdy>329 then opdevval =182; 
  else if opdevval =. then opdevval =126;
  format oevdt date9. ; 
run; 

********End of derivation of OEVDT: Date of last Evaluable Visit******;
data _proga2; 
  merge _proga1(in=a) 
        _pd2 
        _death
        _sbts
        _itt1(in=b)
        _ds;
  by studyid usubjid;  
  if a and b;  
run; 

*To get event description from trprogn;
data _proga3;   
  merge _proga2 _evnt;   
  by usubjid;  
run;
 

data trproga(keep =studyid usubjid parqual param paramcd aval startdt cnsdtdsc oevdt adt cnsr evntdesc ocendy aphase);
  length evntdesc cnsdtdsc aphase param $200 paramcd $8;   
  set _proga3; 
  minor_pd=coalesce(minopdv,min_pddate);
  if not missing(dsstdtc) then ds_date =input(dsstdtc,e8601da.);
  if not missing(sbtstdtc) then sbts =input(sbtstdtc,e8601da.); 
  if not missing(dthdtc) then d_date =input(dthdtc,e8601da.);
  if n(d_date,oevdt)=2 then diff= d_date -oevdt;

  *To derive adt;  
  if opdvrfl ="Y" and osctrfl ne "Y" and (n(minor_pd,sbts)=2 and minor_pd lt sbts or sbts eq .)then adt =minor_pd;
  else if not missing(dthdtc) and osctrfl ne "Y" and missing(sbts) and (sbts ne . and d_date lt sbts or sbts eq .) then adt =d_date; 
  else if not missing(oevdt) and (sbts ne . and oevdt lt sbts or sbts eq .) then adt =oevdt; 
  else adt =startdt;
  format adt date9.;


  *To derive cnsr;
  if opdvrfl = "Y" and osctrfl ne "Y" or not missing(dthdtc) and sbts eq . then cnsr =0;
  else cnsr =1;

  *To derive evntdesc; 
  if cnsr =0 and opdvrfl ="Y" then evntdesc ="RECIST progression"; 
  else if cnsr =0 then evntdesc ="Death"; 
  else if cnsrn =0 then evntdesc ="Censored RECIST progression or death"; 
  else if index(upcase(dsterm),"LOST TO FOLLOW-UP")> 0 then evntdesc ="Lost to follow-up"; 
  else if upcase(dsterm) in ("WITHDRAWN FROM STUDY DUE TO WITHDRAWAL BY SUBJECT",
                             "STUDY DISCONTINUED DUE TO SUBJECT DECISION",
                              "WITHDRAWAL BY SUBJECT",
                              "WITHDRAWN FROM STUDY DUE TO CONSENT WITHDRAWAL BY SUBJECT") then evntdesc ="Withdrawn consent";
  else if upcase(dsterm) in ("DEATH", "SCREEN FAILURE" , "OTHER") or (upcase(dsterm) in ("STUDY TERMINATED BY SPONSOR") 
    and ds_date ne cutoffdt) then evntdesc ="Discontinued study  (any other specified reason for discontinuing study)";
 else evntdesc ="Alive & progression free"; 

 *To derive cnsdtdsc; 
 if cnsr =1 then cnsdtdsc ="Last evaluable RECIST assessment prior to receiving subsequent cancer therapy, or randomisation date if no evaluable post baseline assessments"; 

 *To derive ocendy;
  if cnsr =1 then ocendy = cutoffdt - adt ;   

 *To derive aphase; 
 if missing(sbts) and cnsr =1 then aphase ="No subsequent therapy without progression";
 else if missing(sbts) and cnsr =0 then aphase ="No subsequent therapy with progression"; 
 else if not missing(sbts) and cnsr =1 then aphase ="No progression"; 
 else if n(sbts,adt)=2  then do;   
    if  adt lt sbts then aphase ="After progression";
	else if adt gt sbts then aphase ="Before progression";
	else if adt eq sbts and evntdesc="RECIST progression" then aphase ="After progression"; 
    else if adt eq sbts and evntdesc="Death" then aphase ="Before progression";
 end; 

 *To derive aval;  
  if n(adt,startdt)=2 then do; 
    if adt ge startdt then  aval = (adt -startdt)+1; 
    else aval =adt -startdt;   
  end; 

 *To derive param and paramcd;
  param ="Progression-free survival (evaluation-time bias)";  
  paramcd ="TRPROGA";
run; 


***********To derive Overall Survival param  and associated variables*****************; 
**To get date a subject is last known alive from CRF modules;
proc sql noprint;
  *Get latest date known to be alive from ds dataset;
  create table _ovsurv1 as 
  select distinct studyid,usubjid,max(input(dsstdtc,e8601da.)) as alive format =date9.
  from ds 
  where dsdecod ="LAST KNOWN ALIVE"
  group by studyid, usubjid;
  
  * AE start and stop dates;
  create table _ovsurva as 
  select distinct a.studyid,a.usubjid,
         max(input(b.aestdtc,e8601da.)) as max_aes format =date9.,
		 max(input(c.aeendtc,e8601da.)) as max_aee format =date9.
  from _itt as a left join sdtm.ae as b on a.usubjid =b.usubjid and length(b.aestdtc)>=10
                 left join sdtm.ae as c on a.usubjid =c.usubjid and length(c.aeendtc)>=10
  group by a.usubjid;   

  * Admission and discharge dates of hospitalisation;
  create table _ovsurvb as 
  select distinct a.studyid,a.usubjid,
         max(input(b.hostdtc,e8601da.)) as max_hos format =date9.,
		 max(input(b.hoendtc,e8601da.)) as max_hoe format =date9.
  from _itt as a left join sdtm.ho as b on a.usubjid=b.usubjid and length(b.hostdtc)>=10
                 left join sdtm.ho as c on a.usubjid=c.usubjid and length(b.hoendtc)>=10
  group by a.usubjid;

  * Randomisation date, treatment start and end dates;
  create table _ovsurvc as
  select distinct a.studyid, a.usubjid,b.trtsdt,b.trtedt,b.randdt
  from _itt as a left join adam.adsl as b on a.usubjid =b.usubjid
  order by usubjid;   

  * Lab test dates;
  create table _ovsurvd as 
  select distinct a.studyid,a.usubjid,
         max(input(b.lbdtc,e8601da.)) as max_lb format =date9.
  from _itt as a left join sdtm.lb as b on a.usubjid=b.usubjid and length(b.lbdtc)>=10
  group by a.usubjid; 

  *Date of vital signs;
   create table _ovsurve as 
   select distinct a.studyid, a.usubjid, max(input(b.vsdtc,e8601da.)) as max_vs format=date9.
   from _itt a left join sdtm.vs b on a.usubjid=b.usubjid and length(b.vsdtc)>=10
   group by a.usubjid;

  *RECIST assessment dates;
  create table _ovsurvf as 
  select distinct a.studyid,a.usubjid,  
                  max(input(b.rsdtc,e8601da.)) as max_rs format =date9.,
				  max(input(c.trdtc,e8601da.)) as max_tr format =date9., 
				  max(input(d.tudtc,e8601da.)) as max_tu format =date9.
  from _itt as a left join sdtm.rs as b on a.usubjid =b.usubjid and length(b.rsdtc)>=10
                 left join tr as c on a.usubjid =c.usubjid and length(c.trdtc)>=10
				 left join tu as d on a.usubjid= d.usubjid and length(d.tudtc)>=10
  group by a.usubjid;  
    
  *Anticancer therapy start and stop dates; 
  create table _ovsurvg as 
  select distinct a.studyid, a.usubjid,
                  max(input(b.cmstdtc,e8601da.)) as max_cms format =date9.,
				  max(input(c.cmendtc,e8601da.)) as max_cme format =date9.,
				  max(input(d.dsstdtc,e8601da.)) as max_ds  format =date9.
  from _itt as a left join sdtm.cm as b on a.usubjid=b.usubjid and length(b.cmstdtc)>=10 and b.cmcat="CANCER THERAPY"
                 left join sdtm.cm as c on a.usubjid=c.usubjid and length(c.cmendtc)>=10 and c.cmcat="CANCER THERAPY"
				 left join sdtm.ds as d on a.usubjid=d.usubjid and length(d.dsstdtc)>=10 and d.dsdecod="WITHDRAWAL BY SUBJECT"
  group by a.usubjid; 

  *Combine and get max date;
   create table _last_known as
   select distinct a.studyid,a.usubjid,h.alive,max(a.max_aes,a.max_aee,b.max_hos,b.max_hoe,c.trtsdt, c.trtedt, c.randdt,
                                           d.max_lb,e.max_vs,f.max_rs, f.max_tr, f.max_tu,g.max_cms, g.max_cme,g.max_ds)
										   as max_date format =date9.
    from _ovsurva as a 
    full join _ovsurvb as b on a.usubjid=b.usubjid  
    full join _ovsurvc as c on a.usubjid=c.usubjid
    full join _ovsurvd as d on a.usubjid=d.usubjid
    full join _ovsurve as e on a.usubjid=e.usubjid 
	full join _ovsurvf as f on a.usubjid=f.usubjid 
	full join _ovsurvg as g on a.usubjid=g.usubjid
	full join _ovsurv1 as h on a.usubjid=h.usubjid
	and cmiss(a.max_aes,a.max_aee,b.max_hos,b.max_hoe,c.trtsdt, c.trtedt, c.randdt,
              d.max_lb,e.max_vs,f.max_rs, f.max_tr, f.max_tu,g.max_cms, g.max_cme,g.max_ds)<15
    order by a.usubjid;  

quit; 


data _ovsur; 
  merge _progn1(in=a) 
        _pd2 
        _death
        _sbts
        _itt1(in=b)
        _ds
        _last_known;
  by studyid usubjid;  
  if a and b;  
run;

**Format for dsterm;
proc format library =work;  
  value $_fmt "LOST TO FOLLOW-UP" = "Lost to follow-up" 
              "WITHDRAWAL BY SUBJECT" = "Withdrawal by subject"
              "DEATH"   = "Death"
              "SCREEN FAILURE" ="Screen failure"
              "STUDY TERMINATED BY SPONSOR" ="Study terminated by sponsor"
              "OTHER"  ="Other" 
	  ; 
run;   


data ovsurv(keep =studyid usubjid parqual param paramcd aval startdt cnsdtdsc oevdt adt cnsr evntdesc ocendy);
  length evntdesc cnsdtdsc param $200 paramcd $8;    
  set _ovsur;
  if not missing(sbtstdtc) then sbts =input(sbtstdtc,e8601da.); 
  if not missing(dthdtc) then d_date =input(dthdtc,e8601da.);

  *To derive adt; 
  if not missing(d_date) then adt =d_date; 
  else if missing(d_date) and n(alive,cutoffdt)then adt =min(alive,cutoffdt); 
  else if not missing(max_date)and missing(alive) then adt =max_date; **Date from CRF modules**;  
  format adt date9.;  

  *To derive aval;
  if n(adt,startdt)=2 then do; 
    if adt ge startdt then  aval = (adt -startdt)+1; 
    else aval =adt -startdt;   
  end; 
   
  *To derive cnsr; 
  if not missing(dthdtc) then cnsr =0; 
  else cnsr =1;

  *To derive evntdesc;
  if not missing(dthdtc) then evntdesc ="Death"; 
  else if missing(dthdtc) and dsterm in ("LOST TO FOLLOW-UP" ,"WITHDRAWAL BY SUBJECT", "DEATH" ,"SCREEN FAILURE",
        "STUDY TERMINATED BY SPONSOR", "OTHER")then evntdesc =put(dsterm,$_fmt.);
  else evntdesc ="Still in survival follow-up";  
  
  *To derive cnsdtdsc;
  if cnsr =1 then cnsdtdsc ="Last date from the CRF that indicates the subject is still alive";

  *To derive ocendy;
  if cnsr =1 and n(adt,cutoffdt)=2 then ocendy =cutoffdt -adt;  

  *To derive param and paramcd;
   param ="OVSURV";
   paramcd ="Overall Survival";  
run; 
 

*To derive duration of response param and associated variables; 
***To get first documented CR/PR from response data;
proc sql noprint;  
  create table _resp as
  select distinct studyid, usubjid, min(aendt) as resp_dt format=date9.,avalc, parqual
  from adam.adresp
  where paramcd in("TRVROV") and (ocrvrfl ="Y" or oprvrfl ="Y")
  group by studyid,usubjid,parqual
  order by studyid,usubjid,parqual; 
quit; 

proc sort data =_resp out =_resp1 nodupkeys;  
  by studyid usubjid parqual;
run;  

*To merge _resp1 with _itt;
data _resp2; 
  length param $200 paramcd $8; 
  merge _resp1(in=a) _itt(in=b); 
  by studyid usubjid;   
  if a and b; 

  *To derive startdt;
  if not missing(resp_dt) then startdt =resp_dt;
  format startdt;  
 
  *To derive param and paramcd;
  param ="Duration of Response";
  paramcd ="DURRESP"; 
run; 


*To get adt and cnsr from trprogt dataset;
proc sort data =trprogt out =_pfs(keep =studyid usubjid parqual adt cnsr); 
  by studyid usubjid parqual;  
run;    

data durresp(keep =studyid usubjid param paramcd aval startdt adt cnsr parqual);  
  merge _resp2(in=a) _pfs(in=b);
  by studyid usubjid parqual;
  if a and b; 

  *To derive aval;
  if n(adt,startdt)=2 then do; 
    if adt ge startdt then  aval = (adt -startdt)+1; 
    else aval =adt -startdt;   
  end;
run;  


*To combine all params;
data adtte_1;  
  set durresp trprogn trprogt trprogm trproga ovsurv;
run; 

*To merge adtte_1 with subject investigator flags;
proc sort data =adtte_1 out=adtte_2;   
  by studyid usubjid parqual;
run;  

data adtte_3; 
  merge adtte_2(in=a) flags;  
  by studyid usubjid parqual;
  if a;   
run;  

*To bring in cross variables from adsl;
data adtte_4;
  length trta trtp $40;    
  merge adtte_3(in=a) adam.adsl(keep= &adsl_keep.);
  by usubjid;
  if a; 

  *To derive treatment variables;
  trta   =trt01a; 
  trtan  =trt01an ; 
  trtp   =trt01p; 
  trtpn  =trt01pn;  
run; 

*To derive analysis sequence number; 
proc sort data =adtte_4 out =adtte_5;  
  by studyid usubjid adt paramcd; 
run; 

data adtte_6;   
  set adtte_5;   
  by studyid usubjid adt paramcd; 
  if first.usubjid then aseq =0;   
  aseq +1;

  *To derive ady;  
  if n(adt,randdt)=2 then do;
    if adt ge randdt then ady =(adt -randdt)+1;
    else ady =adt -randdt;    
  end; 
run;  


*To set variable attributes;
data adtte(keep=studyid - -ethnic label ="Efficacy TTE, Analysis Data");   
  attrib STUDYID  Label = 'Study Identifier'                          Length = $21
         USUBJID  Label = 'Unique Subject Identifier'                 Length = $30
         SUBJID   Label = 'Subject Identifier for the Study'          Length = $8
         ASEQ     Label = 'Analysis Sequence Number'                  Length = 8
         ARM      Label = 'Description of Planned Arm'                Length = $200
         ARMCD    Label = 'Planned Arm Code'                          Length = $20
         ACTARM   Label = 'Description of Actual Arm'                 Length = $200
         ACTARMCD Label = 'Actual Arm Code'                           Length = $20
         TRTA     Label = 'Actual Treatment'                          Length = $40
         TRTAN    Label = 'Actual Treatment (N)'                      Length = 8
         TRTP     Label = 'Planned Treatment'                         Length = $40
         TRTPN    Label = 'Planned Treatment (N)'                     Length = 8
         ONTPFL   Label = 'Any Non Target Lesions Present'            Length = $2
         ONTVBPFL Label = 'Valid Baseline for NTL at Entry'           Length = $2
         OTLPFL   Label = 'Target Lesions Present'                    Length = $2
         OTLVBPFL Label = 'Valid Baseline for TL at Entry'            Length = $2
         ADT      Label = 'Analysis Date'                             Length = 8
         ADY      Label = 'Analysis Relative Day'                     Length = 8
         APHASE   Label = 'Phase'                                     Length = $200
         OCENDY   Label = 'Rel Day of DCO from Date Event Censored'   Length = 8
         OEVDT    Label = 'Date of Last Evaluable Visit'              Length = 8
         AVAL     Label = 'Analysis Value'                            Length = 8
         PARAM    Label = 'Parameter'                                 Length = $200
         PARAMCD  Label = 'Parameter Code'                            Length = $8
         PARQUAL  Label = 'Parameter Qualifier'                       Length = $200
         CNSR     Label = 'Censor'                                    Length = 8
         CNSDTDSC Label = 'Censor Date Description'                   Length = $200
         EVNTDESC Label = 'Event or Censoring Description'            Length = $200
         STARTDT  Label = 'Time to Event Origin Date for Subject'     Length = 8
         TRT01P   Label = 'Planned Treatment for Period 01'           Length = $40
         TRT01PN  Label = 'Planned Treatment for Period 01 (N)'       Length = 8
         TRT01A   Label = 'Actual Treatment for Period 01'            Length = $40
         TRT01AN  Label = 'Actual Treatment for Period 01 (N)'        Length = 8
         SITEID   Label = 'Study Site Identifier'                     Length = $5
         RANDDT   Label = 'Date of Randomization'                     Length = 8
         RANDFL   Label = 'Randomized Population Flag'                Length = $2
         TRTEDT   Label = 'Date of Last Exposure to Treatment'        Length = 8
         TRTSDT   Label = 'Date of First Exposure to Treatment'       Length = 8
         TRTEDTM  Label = 'Datetime of Last Exposure to Treatment'    Length = 8
         TRTSDTM  Label = 'Datetime of First Exposure to Treatment'   Length = 8
         DTHDT    Label = 'Date of Death'                             Length = 8
         DTHDTF   Label = 'Date of Death Imputation Flag'             Length = $2
         DTHDTC   Label = 'Date/Time of Death'                        Length = $19
         DTHFL    Label = 'Subject Death Flag'                        Length = $1
         STRATA   Label = 'Randomized Strata'                         Length = $200
         STRATAN  Label = 'Randomized Strata (N)'                     Length = 8
         STRATF1A Label = 'Stratification Factor-HRR status'          Length = $200
         STRATF2A Label = 'Stratification Factor-Bajorin Risk index'  Length = $8
         DCTDT    Label = 'Date of Discontinuation of Treatment'      Length = 8
         AGE      Label = 'Age'                                       Length = 8
         AGEU     Label = 'Age Units'                                 Length = $10
         ENRLFL   Label = 'Enrolled Population Flag'                  Length = $2
         FASFL    Label = 'Full Analysis Set Population Flag'         Length = $2
         SBTSTDTC Label = 'Start Date of Subsequent Therapy'          Length = $19
         POP1FL   Label = 'Population 1 Flag'                         Length = $2
         POP1FLD  Label = 'Population 1 Flag Description'             Length = $200
         RACE     Label = 'Race'                                      Length = $60
         RECIPFL  Label = 'Subject Received Investigational Product'  Length = $2
         SAFFL    Label = 'Safety Population Flag'                    Length = $2
         COVAR1   Label = 'Covariate 1'                               Length = 8
         COVAR1D  Label = 'Covariate definition 1'                    Length = $80
         SEX      Label = 'Sex'                                       Length = $1
         ETHNIC   Label = 'Ethnicity'                                 Length = $60
	 ; 
  set adtte_6;
run; 
 

**To check the log;
%checklog;  






