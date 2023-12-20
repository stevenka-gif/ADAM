**********************************************************
*
* Program Name   : study_adsl.sas
* Protocol/ Study: p:\training area\phapharma\praxis2\user_Naomi Tabitha
* Type           : ADaM
* Description    : To produce the ADSL ADaM dataset
*
* Author         : Stephen Kangu
*
* Date Created   : 08 - JUL - 2023
* Input datasets : sdtm.dm, sdtm.ds, sdtm.mh 
* Macros used    : %combinesdtm, %checklog
* Files used     : 
*
**********************************************************
* Change History
* Changed By:
* Reason for Change:
* Date Changed:
* <Repeat if necessary>
**********************************************************;

*** Merge main and supplemental SDTM datasets together***;
%combinesdtm(dm);

*Obtains analysis variables from the sdtm.dm dataset******;
data adsl1;
  length agegr1 agegr2 $20;
  set dm; 
  if  actarm = "Durvalumab MEDI4736 1500mg Q4W + Olaparib AZD2281 BID" then trt01a = "Durva + Olaparib";
  else if actarm = "Durvalumab MEDI4736 1500mg Q4W + Placebo BID" then trt01a = "Durva + Placebo";
  else trt01a = "";
  if trt01a = 'Durva + Olaparib' then trt01an = 1;
  else if trt01a = 'Durva + Placebo' then trt01an = 2;
  else trt01an = .;
  if  arm = "Durvalumab MEDI4736 1500mg Q4W + Olaparib AZD2281 BID" then trt01p = "Durva + Olaparib";
  else if actarm = "Durvalumab MEDI4736 1500mg Q4W + Placebo BID" then trt01p = "Durva + Placebo";
  else trt01p = "";
  if trt01p = 'Durva + Olaparib' then trt01pn = 1;
  else if trt01p = 'Durva + Placebo' then trt01pn = 2;
  else trt01pn = .;
  if ~missing(rficdtc) then enrlfl = "Y";
  else enrlfl = "N";
  if ~missing(rfstdtc) then recipfl = "Y";
  else recipfl = "N";
  if recipfl = "Y" then saffl = "Y";
  else saffl = "N";
  if .<age<50 then agegr1 = "< 50";
  else if 50<=age<65 then agegr1 = ">= 50 to < 65";
  else if 65<=age<75 then agegr1 = ">= 65 to < 75";
  else if 75<=age<80 then agegr1 = ">= 75 to < 80";
  else if 80<=age<85 then agegr1 = ">= 80 to < 85";
  else if age>=85 then agegr1 = ">= 85";
  if .<age<50 then agegr1n = 1;
  else if 50<=age<65 then agegr1n = 2;
  else if 65<=age<75 then agegr1n = 3;
  else if 75<=age<80 then agegr1n = 4;
  else if 80<=age<85 then agegr1n = 5;
  else if age>=85 then agegr1n = 6;
  if .<age<65 then agegr2 = "< 65";
  else if age>=65 then agegr2 = ">= 65";
  if .<age<65 then agegr2n = 1;
  else if age>=65 then agegr2n = 2;
  if length(rfxendtc)=16 then trtedt = input(rfxendtc, yymmdd19.);
  else if length(rfxendtc)=10 then trtedt = input(rfxendtc, yymmdd10.); 
  if length(rfstdtc)=16 then trtsdt = input(rfstdtc, yymmdd19.);
  else if length(rfstdtc)=10 then trtsdt = input(rfstdtc, yymmdd10.); 
  if length(rfxendtc)=16 then trtedtm = input(rfxendtc, b8601dt.);
  else if length(rfxendtc)=10 then trtedtm = input(rfxendtc, b8601dt.); 
  if length(rfstdtc)=16 then trtsdtm = input(rfstdtc, b8601dt.);
  else if length(rfstdtc)=10 then trtsdtm = input(rfstdtc, b8601dt.);  
  format trtedt trtsdt date9. trtedtm trtsdtm datetime18.;
run;

*Obtains analysis variables from the sdtm.dm dataset******;
data adsl2;
  length strata $200 stratan 8;
  set adsl1;
  strata = catx(" and Bajorin risk index ", stratf1a, stratf2a);
  ecogi = input(ecogps, best.);
  crc_=coalescec(rscacrcl, rscrcl, scacrcl, scrcl);
  crc = input(crc_, best.);
  if strata='HRRm and Bajorin risk index 0' then stratan =1;
  else if strata='HRRm and Bajorin risk index 1' then stratan =2;
  else if strata='HRRm and Bajorin risk index 2' then stratan =3;
  else if strata='HRRwt and Bajorin risk index 0' then stratan =4;
  else if strata='HRRwt and Bajorin risk index 1' then stratan =5;
  else if strata='HRRwt and Bajorin risk index 2' then stratan =6;
  if vismeta='YES' then viscmeti ="Y";
  else if vismeta='NO' then viscmeti ="N";
  if stratf1a='HRRm' then pop1fl ="Y";
  else pop1fl ="N";
  if cmiss(rscacrcl, rscrcl, scacrcl, scrcl) < 4 then do;
    if crc < 60 then crcllwsc = "Y";
    if crc >= 60 then crcllwsc = "N";
  end;
  if missing(rsaudlos) then do;
    if saudlos = "Yes" then ctcaeahl = "Y";
    else if saudlos = "No" then ctcaeahl = "N";
  end;
  else do;
    if rsaudlos = "Yes" then ctcaeahl = "Y";
    else if rsaudlos = "No" then ctcaeahl = "N";
  end;
  if missing(rspneuro) then do;
    if spneuro = "Yes" then ctcaepn = "Y";
    else if spneuro = "No" then ctcaepn = "N";
  end;
  else do;
    if rspneuro = "Yes" then ctcaepn = "Y";
    else if rspneuro = "No" then ctcaepn = "N";
  end;
  if missing(rshtfail) then do;
    if shtfail = "Yes" then nyhachf = "Y";
    else if shtfail = "No" then nyhachf = "N";
  end;
  else do;
    if rshtfail = "Yes" then nyhachf = "Y";
    else if rshtfail = "No" then nyhachf = "N";
  end;
  if ~missing(ecogps) then do;
    if ecogps >= "2" then ecogge2 = "Y";
    else if ecogps < "2" then ecogge2 = "N";
  end;
  if missing(rsadvage) then do;
    if sadvage = "Yes" then advage = "Y";
    else if sadvage = "No" then advage = "N";
  end;
  else do;
    if rsadvage = "Yes" then advage = "Y";
    else if rsadvage = "No" then advage = "N";
  end;
  if missing(rsredps) then do;
    if sredps = "Yes" then redps = "Y";
    else if sredps = "No" then redps = "N";
  end;
  else do;
    if rsredps = "Yes" then redps = "Y";
    else if rsredps = "No" then redps = "N";
  end;
  if missing(rscmdcom) then do;
    if scmdcom = "Yes" then cmdcom = "Y";
    else if scmdcom = "No" then cmdcom = "N";
  end;
  else do;
    if rscmdcom = "Yes" then cmdcom = "Y";
    else if rscmdcom = "No" then cmdcom = "N";
  end;
  if missing(rscospfy) then cospfy = scospfy;
  else cospfy = rscospfy;
  if saffl = "N" then safxl = "Did not receive IP";
  else safxl = "";
run;

*Obtains CrCI and CTCAE analysis variables ******;
data adsl3;
  set adsl2;
  if crcllwsc='Y' or ctcaeahl='Y' or ctcaepn='Y' or nyhachf ='Y' or ecogi=2 then cispiefl = "Y";
  if cmiss(crcllwsc, ctcaeahl, ctcaepn, nyhachf, ecogge2)=0 then do;
    if crcllwsc = "Y" & ctcaeahl = "Y" & ctcaepn = "Y" & nyhachf = "Y" & ecogge2 = "Y" 
    then c5capne= "Y";
    else c5capne= "N";
  end;
  if cmiss(crcllwsc, ctcaeahl, ctcaepn, nyhachf, ecogge2, c5capne)=0 then do;
    if ctcaeahl = "Y" & ctcaepn = "Y" & nyhachf = "Y" & ecogge2 = "Y" & c5capne = "N" 
    then c4apne= "Y";
    else c4apne= "N";
    if crcllwsc = "Y" & ctcaepn = "Y" & nyhachf = "Y" & ecogge2 = "Y" & c5capne = "N" 
    then c4cpne= "Y";
    else c4cpne= "N";
    if crcllwsc = "Y" & ctcaeahl = "Y" & nyhachf = "Y" & ecogge2 = "Y" & c5capne = "N" 
    then c4cane= "Y";
    else c4cane= "N";
    if crcllwsc = "Y" & ctcaeahl = "Y" & ctcaepn = "Y" & ecogge2 = "Y" & c5capne = "N" 
    then c4cape= "Y";
    else c4cape= "N";
    if crcllwsc = "Y" & ctcaeahl = "Y" & ctcaepn = "Y" & nyhachf = "Y" & c5capne = "N" 
    then c4capn= "Y";
    else c4capn= "N";
  end;
  if cmiss(ctcaepn, nyhachf, ecogge2, c5capne, c4apne, c4cpne, c4cane, c4cape, c4capn)=0 then do;
    if ctcaepn = "Y" & nyhachf = "Y" & ecogge2 = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" then c3pne= "Y";
    else c3pne= "N";
    if ctcaeahl = "Y" & nyhachf = "Y" & ecogge2 = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" then c3ane= "Y";
    else c3ane= "N";
    if ctcaeahl = "Y" & ctcaepn = "Y" & ecogge2 = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" then c3ape= "Y";
    else c3ape= "N";
    if ctcaeahl = "Y" & ctcaepn = "Y" & nyhachf = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" then c3apn= "Y";
    else c3apn= "N";
    if crcllwsc = "Y" & nyhachf = "Y" & ecogge2 = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" then c3cne= "Y";
    else c3cne= "N";
    if crcllwsc = "Y" & ctcaepn = "Y" & ecogge2 = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" then c3cpe= "Y";
    else c3cpe= "N";
    if crcllwsc = "Y" & ctcaepn = "Y" & nyhachf = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" then c3cpn= "Y";
    else c3cpn= "N";
    if crcllwsc = "Y" & ctcaeahl = "Y" & ecogge2 = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" then c3cae= "Y";
    else c3cae= "N";
    if crcllwsc = "Y" & ctcaeahl = "Y" & nyhachf = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" then c3can= "Y";
    else c3can= "N";
    if crcllwsc = "Y" & ctcaeahl = "Y" & ctcaepn = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" then c3cap= "Y";
    else c3cap= "N";
  end;
  if cmiss(nyhachf, ecogge2, c5capne, c4apne, c4cpne, c4cane, c4cape, c4capn, c3pne, c3ane,             
  c3ape, c3apn, c3cne, c3cpe, c3cpn, c3cae, c3can, c3cap)=0 then do;
    if nyhachf = "Y" & ecogge2 = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" & c3pne = "N" & c3ane = "N" 
    & c3ape = "N" & c3apn = "N" & c3cne= "N" & c3cpe= "N" &  c3cpn= "N" & c3cae= "N" 
    & c3can= "N" & c3cap= "N" then c2ne= "Y";
    else c2ne= "N";
    if ctcaepn = "Y" & ecogge2 = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" & c3pne = "N" & c3ane = "N" 
    & c3ape = "N" & c3apn = "N" & c3cne= "N" & c3cpe= "N" &  c3cpn= "N" & c3cae= "N" 
    & c3can= "N" & c3cap= "N" then c2pe= "Y";
    else c2pe= "N";
    if ctcaepn = "Y" & nyhachf = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" & c3pne = "N" & c3ane = "N" 
    & c3ape = "N" & c3apn = "N" & c3cne= "N" & c3cpe= "N" &  c3cpn= "N" & c3cae= "N" 
    & c3can= "N" & c3cap= "N" then c2pn= "Y";
    else c2pn= "N";
    if ctcaeahl = "Y" & ecogge2 = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" & c3pne = "N" & c3ane = "N" 
    & c3ape = "N" & c3apn = "N" & c3cne= "N" & c3cpe= "N" &  c3cpn= "N" & c3cae= "N" 
    & c3can= "N" & c3cap= "N" then c2ae= "Y";
    else c2ae= "N";
    if ctcaeahl = "Y" & nyhachf = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" & c3pne = "N" & c3ane = "N" 
    & c3ape = "N" & c3apn = "N" & c3cne= "N" & c3cpe= "N" &  c3cpn= "N" & c3cae= "N" 
    & c3can= "N" & c3cap= "N" then c2an= "Y";
    else c2an= "N";
    if ctcaeahl = "Y" & ctcaepn = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" & c3pne = "N" & c3ane = "N" 
    & c3ape = "N" & c3apn = "N" & c3cne= "N" & c3cpe= "N" &  c3cpn= "N" & c3cae= "N" 
    & c3can= "N" & c3cap= "N" then c2ap= "Y";
    else c2ap= "N";
    if crcllwsc = "Y" & ecogge2 = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" & c3pne = "N" & c3ane = "N" 
    & c3ape = "N" & c3apn = "N" & c3cne= "N" & c3cpe= "N" &  c3cpn= "N" & c3cae= "N" 
    & c3can= "N" & c3cap= "N" then c2ce= "Y";
    else c2ce= "N";
    if crcllwsc = "Y" & nyhachf = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" & c3pne = "N" & c3ane = "N" 
    & c3ape = "N" & c3apn = "N" & c3cne= "N" & c3cpe= "N" &  c3cpn= "N" & c3cae= "N" 
    & c3can= "N" & c3cap= "N" then c2cn= "Y";
    else c2cn= "N";
    if crcllwsc = "Y" & ctcaepn = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" & c3pne = "N" & c3ane = "N" 
    & c3ape = "N" & c3apn = "N" & c3cne= "N" & c3cpe= "N" &  c3cpn= "N" & c3cae= "N" 
    & c3can= "N" & c3cap= "N" then c2cp= "Y";
    else c2cp= "N";
    if crcllwsc = "Y" & ctcaeahl = "Y" & c5capne = "N" & c4apne = "N" 
    & c4cpne = "N" & c4cane = "N" & c4cape = "N" & c4capn = "N" & c3pne = "N" & c3ane = "N" 
    & c3ape = "N" & c3apn = "N" & c3cne= "N" & c3cpe= "N" &  c3cpn= "N" & c3cae= "N" 
    & c3can= "N" & c3cap= "N" then c2ca= "Y";
    else c2ca= "N";
  end;
run;

*Merges required sdtm.mh & sdtm.vs datasets to dm;
%combinesdtm(MH);
%combinesdtm(VS);

%macro sort1(data1=, key=, out1=, dup=);
proc sort data = &data1.  out = &out1. &dup.;
  by &key.;
run;

%mend sort1;
%sort1(data1=mh(where=(mhterm="BLADDER" & mhscat = "FIRST DIAGNOSIS")), key=usubjid, 
       out1=mh_s(keep=usubjid mhstdtc), dup=nodupkey);*Sorts HM dataset that meets the required condition;

%sort1(data1=adsl3, key=usubjid, out1=adsl3_s);*Sorts main dataset;

%sort1(data1=vs(where=(vstestcd in("HEIGHT", "WEIGHT") & vsblfl = "Y")), key=usubjid, 
       out1=vs_s(keep=usubjid vstestcd vsstresn));*Sorts vs datset;

*Transposes the vs dataset to obtain height and weight as wide dataset;
proc transpose data = vs_s out=vs_t(drop = _name_ _label_);
  by usubjid;
  var vsstresn;
  id vstestcd;
run;

*Merges mh and vs datasets to the main dataset;
%macro merge (data= , var= );
data &data.;
  merge &var.;
  by usubjid;
  if a;
run;
%mend merge;
%merge(data= adsl4, var= adsl3_s(in=a) mh_s vs_t);

*Obtains vital signs baseline tests;
data adsl5;
  length bmiblg1 wghtblg1 $20;
  set adsl4;
  if ~missing(height) then heightb_ = height/100;
  weightbl =weight;
  heightbl = height;
  if cmiss(weightbl, heightbl)=0 then bmibl = weightbl/(heightb_**2);
  if ~missing(weightbl) then do;
    if  weightbl lt 70 then wghtblg1 = "<70";
    else if 70=<weightbl<90 then wghtblg1 = ">=70 - <90";
    else if weightbl>=90 then wghtblg1 = ">=90";
  end;
  if wghtblg1 = "<70" then wgtblg1n = 1;
  else if wghtblg1 = ">=70 - <90" then wgtblg1n = 2;
  else if wghtblg1 = ">=90" then wgtblg1n = 3;
  if ~missing(bmibl) then do;
    if  bmibl lt 25 then bmiblg1 = "Normal (<25)";
    else if 25=<bmibl<30 then bmiblg1 = "Overweight (25-30)";
    else if bmibl>=30 then bmiblg1 = "Obese (>30)";
  end;
  if bmiblg1 = "Normal (<25)" then bmiblg1n = 1;
  else if bmiblg1 = "Overweight (25-30)" then bmiblg1n = 2;
  else if bmiblg1 = "Obese (>30)" then bmiblg1n = 3;
  if advage = "Y" or redps = "Y" or cmdcom = "Y" then crbpiefl ="Y";
run;

*Brings in the ds dataset;
%combinesdtm(DS);

%macro data_1(data= , set=,  cond1=);
data &data.;
  set &set.;
  where &cond1.;
run;
%mend data_1;
%data_1(data=ds_1, set = ds, cond1= dsdecod = "RANDOMIZATION CODE ALLOCATED" & ~missing(dsstdtc));

*merges in the ds dataset ;
%sort1(data1=ds_1, key=usubjid dsstdtc, out1=ds1_s(keep=usubjid dsstdtc));

*Obtains the latest records;
data ds2;
  set ds1_s;
  by usubjid dsstdtc;
  if last.usubjid;
run;

%merge(data= adsl6, var= adsl5(in=a) ds2);*Merges in the ds dataset;

*Derives the randomization dates and flag from ds;
data adsl7(drop = dsstdtc);
  set adsl6;
  if ~missing(dsstdtc) then do;
    randfl = "Y";
    randdtc = dsstdtc;
    randdt = input(dsstdtc, yymmdd10.);
    fasfl = "Y";
    format randdt date9.;
  end;
  else do;
    randfl ="N";
    fasfl = "N";
  end;
run;

*Derives Date of discontinuation***************************;
%data_1(data = ds_2, set = ds, cond1= ~missing(dsscat));*Obtains ds records with non missing dates;

%sort1(data1=ds_2, key=usubjid dsscat, 
out1=ds2_s(keep=usubjid dscat dsscat module dsdecod dsstdtc dsterm));*Sorts the ds dataset;

*Obatins latest records from ds;
data ds3_;
  set ds2_s;
  mod_= module;
  by usubjid dsscat;
  if last.usubjid & not first.usubjid or first.usubjid & not last.usubjid;*Picks records with both olapa and durva;
run;

%sort1(data1=ds3_, key=usubjid dsstdtc, out1=ds3_s);*Sorts ds dataset by start of disposition date;

*Obtains reason of discontinuation and date of discontinuation****************;
data ds3;
  length  dctreas $200;
  set ds3_s;
  by usubjid dsstdtc;
  if index(dsterm, "TREATMENT STOPPED DUE TO")>0 & dscat = "DISPOSITION EVENT" then dctreas = dsdecod;
  if index(dsterm, "TREATMENT STOPPED DUE TO")>0 then dctdt = input(dsstdtc, yymmdd10.);
  format dctdt date9.;
  if last.usubjid;
run;

%merge(data= adsl8, var= adsl7(in=a) ds3);*Merges the ds dataset to the main dataset;

*Derives End status variables;
data adsl9;
  set adsl8;
  if dscat = "DISPOSITION EVENT" then do;
    if index(dsterm, "TREATMENT STOPPED DUE TO")>0 then eotstt = "DISCONTINUED";
  end;
  else if saffl = "Y" then eotstt = "ONGOING";
  else eotstt = "NOT TREATED";
run;

*Reads in the ds dataset;
%data_1(data = ds_3, set = ds, 
cond1= index(dsterm, "TREATMENT STOPPED DUE TO")=0 & dscat ="DISPOSITION EVENT");

%sort1(data1=ds_3, key=usubjid dsstdtc, 
out1=ds3a_s(keep=usubjid dsstdtc module dsdecod dsspfy dscat dsterm));*Sorts the ds dataset;

*Obtains latest record of the ds dataset;
data ds4(drop = module);
  set ds3a_s;
  by usubjid dsstdtc;
  if last.usubjid;
run;

%merge(data= adsl10, var= adsl9(in=a) ds4);*Merges in the ds dataset to the main dataset;

*Obtains full analysis flags and discontinuation date;
data adsl11;
  length  dcsreas $200;
  set adsl10;
  if index(dsterm, "TREATMENT STOPPED DUE TO")=0 then eosstt = "DISCONTINUED";
  else eosstt = "ONGOING";
  if index(dsterm, "TREATMENT STOPPED DUE TO")=0 then do;
    if dsspfy = "HRR ENRICHMENT" then dcsreas = "HRR ENRICHMENT";
    else dcsreas = dsdecod;
  end;
  if ~missing(dcsreas) then dcsdt = input(dsstdtc, yymmdd10.);
  pop1fld = "HRRm subgroup";
  dthdtf = "";
  if fasfl = "N" then fasxl = "Not Randomized";
  else fasxl = "";
  dthdt = input(dthdtc, yymmdd10.);  
  format dcsdt dthdt date9.;
run;

*Time from Diagnosis to Randomization derivation*****;

%sort1(data1=ds_3, key=usubjid dsstdtc, 
out1=ds3a_s(keep=usubjid dsstdtc module dsdecod dsspfy dscat dsterm));*Sorts the ds dataset;

%merge(data= adsl11_a, var= adsl11(in=a) ds4);*Merges the ds dataset to the main dataset;

data adsl12;
  set adsl11;
  mhsdt= input(mhstdtc, yymmdd10.);
  if cmiss(randdt, mhsdt)=0 then diff1=(randdt - mhsdt + 1 )/30.4375;
  if ~missing(diff1) then do;
    if diff1<=6 then group01n = 1;
    else group01n = 2;
  end;
  if group01n = 1 then group01 = "<= 6 months";
  else if group01n = 2 then group01 = "> 6 months";
run;

*Start Date of subsequent therapy & other race variables derivations;
%combinesdtm(CM);

%data_1(data= cm_1, set = cm, 
cond1= cmcat = "CANCER THERAPY" & cmstrf='AFTER' & cmtrt not in('RADIOTHERAPY'));*Obtains records that meet the conditions;

%sort1(data1=cm_1, key=usubjid cmstdtc, out1=cm1_s(keep=usubjid cmstdtc));*Sorts the cm dataset by start dates;

*Obtains earliest records;
data cm2;
  set cm1_s;
  by usubjid cmstdtc;
  if first.usubjid;
run;

%merge(data= adsl13, var= adsl12(in=a) cm2);*Merges cm dataset to the main dataset;

data adsl14;
  set adsl13;
  sbtstdtc = cmstdtc;
  raceoth = "";
run;

*Vulnerable elders survey variables from qs dataset;
%combinesdtm(QS);

%data_1(data= qs_1, set = qs, cond1= module = "VES13");*Obtains records that meet the conditions;

%sort1(data1=qs_1, key=usubjid, out1=qs1_s(keep=usubjid qstestcd qsstresn));*Sorts qs dataset by usubjid;

*Transposing the qstestcd to a wider dataset;
proc transpose data = qs1_s out = qs1_t(drop = _name_ _label_);
  by usubjid;
  id qstestcd;
  var qsstresn;
run;

*Derives ve13scr;
data qs2(keep = usubjid ve13scr score1 score2 score3 score4);
  set qs1_t;
  if   75 <= vesq01 < 85 then score1 =1;
  else if vesq01 >= 85 then score1 =3;
  else score1 =0;
  if vesq02 in(1, 2) then score2 =1;
  else score2 =0;
  if vesq03a in(4, 5) then score3_1 =1;
  else score3_1 =0;
  if vesq03b in(4, 5) then score3_2 =1;
  else score3_2 =0;
  if vesq03c in(4, 5) then score3_3 =1;
  else score3_3 =0;
  if vesq03d in(4, 5) then score3_4 =1;
  else score3_4 =0;
  if vesq03e in(4, 5) then score3_5 =1;
  else score3_5 =0;
  if vesq03f in(4, 5) then score3_6 =1;
  else score3_6 =0;
  score3_ = sum(of score3_1-score3_6);
  if score3_ >= 2 then score3 = 2;
  else score3 = score3_;
  if vesq04a eq 1 & vesq04a1 eq 1 then score4_1 =1;
  else score4_1 =0;
  if vesq04a eq 3 & vesq04a2 eq 1 then score4_2 =1;
  else score4_2 =0;
  if vesq04b eq 1 & vesq04b1 eq 1 then score4_3 =1;
  else score4_3 =0;
  if vesq04b eq 3 & vesq04b2 eq 1 then score4_4 =1;
  else score4_4 =0;
  if vesq04c eq 1 & vesq04c1 eq 1 then score4_5 =1;
  else score4_5 =0;
  if vesq04c eq 3 & vesq04c2 eq 1 then score4_6 =1;
  else score4_6 =0;
  if vesq04d eq 1 & vesq04d1 eq 1 then score4_7 =1;
  else score4_7 =0;
  if vesq04d eq 3 & vesq04d2 eq 1 then score4_8 =1;
  else score4_8 =0;
  if vesq04e eq 1 & vesq04e1 eq 1 then score4_9 =1;
  else score4_9 =0;
  if vesq04e eq 3 & vesq04e2 eq 1 then score4_10 =1;
  else score4_10 =0;
  if score4_1 = 1 or score4_2 = 1 or score4_3 = 1 or score4_4 = 1 or score4_5 = 1 or score4_6 = 1  
  or score4_7 = 1 or score4_8 = 1 or score4_9 = 1 or score4_10 = 1 then score4 = 4;
  else score4 = 0;
  ve13scr = sum(of score1 - score4);
run;

*Merges the qs dataset to the main dataset;
%merge(data= adsl15, var= adsl14(in=a) qs2);

*Obtains the vulnerables grouping and group numbers;
data adsl16;
  length ve13gr1 $4;
  set adsl15;
  if  .< ve13scr <3 then ve13gr1n =1;
  else if  ve13scr >= 3 then ve13gr1n =2;
  if  ve13gr1n =1 then ve13gr1 = '< 3' ;
  else if  ve13gr1n =2 then ve13gr1 = '>= 3';
run;

*Derives the covariate variables;

*Reads in the lb dataset;
%data_1(data= lb_1, set = sdtm.lb, cond1 = lbtestcd = "TC25IC25");*Obtains records that meet the conditions;

%sort1(data1=lb_1, key=usubjid lbdtc, out1=lb1_s(keep=usubjid lbdtc lbstresc ));*Sorts lb dataset by subject and date;

*Obtains latest records;
data lb2;
  set lb1_s;
  by usubjid lbdtc;
  if last.usubjid;
run;

%merge(data= adsl16_a, var= adsl16(in=a) lb2);*Merges the lb datset to the main dataset;

data adsl17;
  length covar1 8 covar1d $80;
  set adsl16_a;
  if lbstresc="HIGH PD-L1 STATUS" then covar1=1;
  else if lbstresc="LOW/NEGATIVE PD-L1 STATUS" then covar1=2;
  else if missing(lbstresc) then covar1=3;
  if covar1=1 then covar1d="PD-L1 High Expression";
  else if covar1=2 then covar1d="PD-L1 Low Expression";
  else if covar1=3 then covar1d="Missing";
run;
*Derives the eCDF HRR and BRCA status;
%combinesdtm(MI);

%data_1(data= mi_1, set = mi, 
cond1 = mitestcd not in ("LT90") & mistresc in("POSITIVE", "NEGATIVE"));*Obtains records that meet the conditions;

%sort1(data1=mi_1, key=usubjid mistresc, out1=mi1_s(keep=usubjid mistresc mitestcd));

data mi2;
  length hrrstat $19;
  set mi1_s;
  by usubjid mistresc;
  if last.usubjid;
  if mistresc = "POSITIVE" then hrrstat = "HRRm";
  else if mistresc = "NEGATIVE" then hrrstat = "HRRwt";
  else if mistresc not in("POSITIVE", "NEGATIVE")  then hrrstat = "";
run;

*Obtains latest subject records with mitestcd in ('LN12','LN13');
%data_1(data= mi_2, set = mi, 
cond1 = mitestcd in ('LN12','LN13') & mistresc in("POSITIVE", "NEGATIVE"));*Obtains records that meet the conditions;

%sort1(data1=mi_2, key=usubjid mistresc, out1=mi2_s(keep=usubjid mistresc mitestcd));*Sorts the MI datset;

*Obtains latest records;
data mi3;
  set mi2_s;
  by usubjid mistresc;
  if last.usubjid;
run;

%merge(data= adsl17_, var= adsl17(in=a) mi2 mi3);*Merges the MI datasets to the main dataset;

*brcastat derivation;
data adsl18;
  length brcastat $19;
  set adsl17_;
  if mitestcd in ('LN12','LN13') then do;
    if mistresc = "POSITIVE" then brcastat = "BRCAm";
    else if mistresc = "NEGATIVE" then do;
      if hrrstat = "HRRm" then brcastat = "BRCAwt (HRRm)";
      else if hrrstat = "HRRwt" then brcastat = "BRCAwt (HRRwt)";
    end;
    else if mistresc not in("POSITIVE", "NEGATIVE")  then brcastat = "";
  end;
run;  

*Derives ecog performance status;

*Reads in the qs dataset;
%data_1(data= qs_a, set = qs, 
cond1 = qstestcd = "ECOG101" & visit in ('Screening', 'Re-screening'));*Obtains records that meet the conditions;

%sort1(data1=qs_a, key=usubjid qsdtc, out1=qs_a_s(keep=usubjid qsstresn qsdtc qsblfl));*Sorts qs dataset by subject and date;

*Derives ecog status from qs latest records;
data qs_b(keep = usubjid ecogse ecgge2se);
  set qs_a_s;
  by usubjid qsdtc;
  if last.usubjid;
  ecogse = qsstresn;
  if ~missing(ecogse) then do;
    if ecogse>=2 then ecgge2se = "Y";
    else if ecogse<2 then ecgge2se = "N";
  end;
run;

%data_1(data= qs_c, set = qs, 
cond1 = qstestcd = "ECOG101" & qsblfl = "Y");*Obtains records that meet the conditions;

%sort1(data1=qs_c, key=usubjid qsdtc, out1=qs_c_s(keep=usubjid qsstresn qsdtc qsblfl));*Sorts qs dataset by subject and date;

*obains the latest record from the qs dataset;
data qs_d;
  set qs_c_s;
  by usubjid qsdtc;
  if last.usubjid;
run;

%merge(data= adsl19_, var= adsl18(in=a) qs_b qs_d);*Merges qs dataset to the main dataset;

*Obtains ecog baseline status;
data adsl19;
  set adsl19_;
  if qsblfl = "Y" then ecogbe = qsstresn;
  if ~missing(ecogbe) then do;
    if ecogbe>=2 then ecgge2be = "Y";
    else if ecogbe<2 then ecgge2be = "N";
  end;
run;

*Derives smoking status status******;
%combinesdtm(SU);

*Sorts su dataset by subject and occurence;
proc sort data = su;
  by usubjid suoccur;
run;

*Derives smoking status;
data su1;
  keep usubjid smokstat smoksta2 packyear;
  set su;
  by usubjid suoccur;
  if first.usubjid then packyear = sudose;
  else packyear + sudose;
  if last.usubjid;
  if suoccur = "Y" then smokstat = "Y";
  else if suoccur = "N" then smokstat = "N";
  else smokstat = "";
  if suoccur = "Y" & suenrtpt='ONGOING' then smoksta2 = "Current smoker";
  else if suoccur = "Y" & suenrtpt='BEFORE' then smoksta2 = "Ex-smoker";
  else if suoccur = "N" then smoksta2 = "Non-smoker";
  else smoksta2 = "";
run;

%merge(data= adsl20, var= adsl19(in=a) su1);*Merges su dataset to the main dataset;

*Derives prior treatment and immuno-oncology;
%data_1(data= cm_a, set = cm, 
cond1 = cmcat='CANCER THERAPY' & cmstrf='BEFORE');*Obtains records that meet the conditions;

%sort1(data1=cm_a, key=usubjid cmstdtc, out1=cm_a_s(keep=usubjid cmstdtc cmscat cmcat cmstrf));*Sorts cmdataset by subject and date;

*obains the latest record from the cm dataset;
data cm_b;
  set cm_a_s;
  by usubjid cmstdtc;
  if first.usubjid;
run;

%data_1(data= cm_c, set = cm, 
cond1 = cmcat='CANCER THERAPY' & cmscat='IMMUNOTHERAPY' & cmstrf='BEFORE');*Obtains records that meet the conditions;

%sort1(data1=cm_c, key=usubjid cmstdtc, out1=cm_c_s(keep=usubjid cmstdtc cmscat cmcat cmstrf));*Sorts cm dataset by subject and start date;

*obains the latest record from the cm dataset;
data cm_d;
  set cm_c_s;
  by usubjid cmstdtc;
  if first.usubjid;
run;

%merge(data= adsl21, var= adsl20(in=a) cm_b cm_d);*Merges cm dataset to the main dataset;

*Obtain prior treat and prior immuno-oncology;
data adsl22;
  set adsl21;
  if cmcat='CANCER THERAPY' & cmstrf='BEFORE' then pritrt = "Y";
  else pritrt = "N"; 
  if cmcat='CANCER THERAPY' & cmscat='IMMUNOTHERAPY' & cmstrf='BEFORE' then priio = "Y";
  else priio = "N";
run; 

*Derives Visceral metastasis ;
%combinesdtm(FA);

data fa1(keep=usubjid fatestcd viscmete fatestcd fastresc fadtc faloc module where =(viscmete ne ""));
  set fa;
  if fatestcd = "LOCADMET" & fastresc in ("METASTATIC", "LOCALLY ADVANCED AND METASTATIC") 
  & faloc not in ("LYMPH NODES", "BLADDER", "RENAL PELVIS", "URETER", "URETHRA") then viscmete = "Y"; 
  else if module in ("PATHGOM", "PATHGEN") then do;
    if faloc in ("RENAL PELVIS", "URETER", "URETHRA") & fastresc = "BLADDER" then viscmete = "Y";;
    if faloc = "BLADDER" & fastresc in ("RENAL PELVIS", "URETER", "URETHRA") then viscmete = "Y";
    if faloc in ("RENAL PELVIS", "URETER", "URETHRA") & fastresc in ("RENAL PELVIS", "URETER", "URETHRA")  then viscmete = "N";
    if faloc = "BLADDER" & fastresc = "BLADDER"  then viscmete = "N";
  end;
  else if faloc = "LYMPH NODES"  then viscmete = "N";
  else if ~missing(faloc) then viscmete = "N";
run;

%sort1(data1=fa1, key=usubjid viscmete, 
out1=fa1_s(keep=usubjid fatestcd fastresc faloc viscmete));*Sorts fa dataset by subject and vicmete;

*obains the latest record from the fa dataset;
data fa2;
  set fa1_s;
  by usubjid viscmete;
  if last.usubjid;
run;

%merge(data= adsl23, var= adsl22(in=a) fa2);*Merges fa dataset to the main dataset;

*Derives Bajorin Risk index;
data adsl24;
  set adsl23;
  if viscmete='Y' & ecgge2se='Y' then bajorine = "2";
  else if viscmete='Y' & ecgge2se='N' or  viscmete='N' & ecgge2se='Y' then bajorine = "1";
  else if viscmete='N' & ecgge2se='N' then bajorine = "0";
run;

*Derives pk population flags ;
%combinesdtm(PC);

*Durva pk flag derivation ;
data pc1;
  length dpkxl $200;
  set pc;
  if pctestcd = "DURVA" & pcorres not in ("", "Not Tested", "<0.0200", "<0.1000", "BLQ<(50.0)") then dpkfl= "Y"; 
  else  do;
    dpkfl= "N";
    dpkxl = "No Post-dose PK concentration data available";
  end;
run;

%sort1(data1=pc1, key=usubjid dpkfl, 
out1=pc1_s(keep=usubjid pcdtc dpkfl dpkxl pctestcd));*Sorts the pc dataset by subject and durva flags;

*Obtains latest records to pick subjects with pk flags;
data pc1_a;
  set pc1_s;
  by usubjid dpkfl;
  if last.usubjid;
run;

*Olapa pk flag derivation ;
data pc2;
  length opkxl $200;
  set pc;
  if pctestcd = "OLAPA" & pcorres not in ("", "Not Tested", "<0.0200", "<0.1000",  "BLQ<(50.0)") then opkfl= "Y";
  else do;
    opkfl= "N"; 
    opkxl = "No Post-dose PK concentration data available";
  end;
run;

%sort1(data1=pc2, key=usubjid opkfl, 
out1=pc2_s(keep=usubjid pcdtc opkfl opkxl pctestcd));*Sorts the pc dataset by subject and olapa flags;

*Obtains latest records to pick subjects with pk flags;
data pc2_a;
  set pc2_s;
  by usubjid opkfl;
  if last.usubjid;
run;

%merge(data= adsl25, var= adsl24(in=a) pc1_a pc2_a);*Merges the pc dataset to the main dataset;

data adsl26;
  length stratf2_ $8 dpkxl opkxl $200;
  set adsl25;
  if opkfl = "" or dpkfl = "" then do;
    opkfl = "N";
    dpkfl = "N";
  end;
  if (opkfl = "N" or dpkfl = "N") & missing(pctestcd) then do;
    dpkxl = "Patient hasn’t received any study treatment";
    opkxl = "Patient hasn’t received any study treatment";
  end;
  patient_ = input(patient, best.);
  stratf2_ = stratf2a;
  siteid_ = put(input(siteid, best.),z5.);
  drop patient stratf2a siteid;
  rename patient_ = patient stratf2_ = stratf2a siteid_ = siteid;
run;

*Sets attributes;
data adsl_f;
  keep studyid usubjid subjid patient siteid arm armcd trt01an trt01pn actarm actarmcd bmibl
  country dcsreas dcsdt dctreas dctdt group01n group01 heightbl fasxl dpkxl opkxl safxl 
  smokstat smoksta2 packyear strata stratan stratf1a stratf2a trt01a trt01p weightbl wghtblg1
  dthdt eosstt eotstt randdt randdtc dthdtc rficdtc trtedt trtedtm trtsdt trtsdtm rfstdtc rfendtc dthdtf 
  dthfl enrlfl fasfl dpkfl opkfl pop1fl pop1fld randfl recipfl saffl covar1 covar1d age agegr1 agegr1n
  agegr2 agegr2n ageu raceoth race sex ethnic sbtstdtc hrrstat brcastat ecogse ecgge2se ecogbe 
  ecgge2be ecogi viscmete viscmeti bajorine pritrt  priio bmiblg1 bmiblg1n wgtblg1n crcllwsc 
  ctcaeahl ctcaepn nyhachf ecogge2 c2ca c2cp c2cn c2ce c2ap c2an c2ae c2pn c2pe c2ne c3cap c3can
  c3cae c3cpn c3cpe c3cne c3apn c3ape c3ane c3pne c4capn c4cape c4cane c4cpne c4apne c5capne 
  ve13scr ve13gr1n ve13gr1 advage redps cmdcom cospfy cispiefl crbpiefl;
  attrib
  studyid  label = 'Study Identifier'                         length =$21
  usubjid  label = 'Unique Subject Identifier'                length =$30
  subjid   label = 'Subject Identifier for the Study'         length =$8
  patient  label = 'Randomization Code'                       length = 8
  siteid   label = 'Study Site Identifier'                    length =$5
  arm      label = 'Description of Planned Arm'               length =$200
  armcd    label = 'Planned Arm Code'                         length =$20
  trt01an  label = 'Actual Treatment for Period 01 (N)'       length = 8
  trt01pn  label = 'Planned Treatment for Period 01 (N)'      length = 8
  actarm   label = 'Description of Actual Arm'                length =$200
  actarmcd label = 'Actual Arm Code'                          length =$20
  bmibl    label = 'Baseline Body Mass Index'                 length = 8
  country  label = 'Country'                                  length =$3
  dcsreas  label = 'Reason for Discontinuation from Study'    length =$200
  dcsdt    label = 'Date of Discontinuation from Study'       length = 8
  dctreas  label = 'Reason for Discontinuation of Treatment'  length =$200
  dctdt    label = 'Date of Discontinuation of Treatment'     length = 8
  group01  label = 'Time from Diagnosis to Randomization'     length =$40
  group01n label = 'Time from Diagnosis to Randomization (N)' length = 8
  heightbl label = 'Baseline Height (cm)'                     length = 8
  fasxl    label = 'Reason for Excl. From FAS Pop'            length =$200
  dpkxl    label = 'Reason for Excl. from Durvalumab PK Pop'  length =$200
  opkxl    label = 'Reason for Excl. from Olaparib PK Pop'    length =$200
  safxl    label = 'Reason for Excl. from Safety Pop'         length =$200
  smokstat label = 'Smoking Status'                           length =$2
  smoksta2 label = 'Smoking Status 2'                         length =$20
  packyear label = 'Total Pack Years'                         length = 8
  strata   label = 'Randomized Strata'                        length =$200
  stratan  label = 'Randomized Strata (N)'                    length = 8
  stratf1a label = 'Stratification Factor-HRR status'         length =$200
  stratf2a label = 'Stratification Factor-Bajorin Risk index' length =$8
  trt01a   label = 'Actual Treatment for Period 01'           length =$40
  trt01p   label = 'Planned Treatment for Period 01'          length =$40
  weightbl label = 'Baseline Weight (kg)'                     length = 8
  wghtblg1 label = 'Pooled Baseline Weight (kg) Grouping 1'   length =$20
  dthdt    label = 'Date of Death'                            length = 8
  dthdtc   label = 'Date/Time of Death'                       length = $19
  eosstt   label = 'End of Study Status'                      length =$200
  eotstt   label = 'End of Treatment Status'                  length =$200
  randdt   label = 'Date of Randomization'                    length = 8
  randdtc  label = 'Date of Randomization (C)'                length = $19
  rficdtc  label = 'Date/Time of Informed Consent'            length = $19
  trtedt   label = 'Date of Last Exposure to Treatment'       length = 8
  trtedtm  label = 'Datetime of Last Exposure to Treatment'   length = 8
  trtsdt   label = 'Date of First Exposure to Treatment'      length = 8
  trtsdtm  label = 'Datetime of First Exposure to Treatment'  length = 8
  rfstdtc  label = 'Subject Reference Start Date/Time'        length = $19
  rfendtc  label = 'Subject Reference End Date/Time'          length = $19
  dthdtf   label = 'Date of Death Imputation Flag'            length =$2
  dthfl    label = 'Subject Death Flag'                       length =$1
  enrlfl   label = 'Enrolled Population Flag'                 length =$2
  fasfl    label = 'Full Analysis Set Population Flag'        length =$2
  dpkfl    label = 'Durvalumab PK Population Flag'            length =$2
  opkfl    label = 'Olaparib PK Population Flag'              length =$2
  pop1fl   label = 'Population 1 Flag'                        length =$2
  pop1fld  label = 'Population 1 Flag Description'            length =$200
  randfl   label = 'Randomized Population Flag'               length =$2
  recipfl  label = 'Subject Received Investigational Product' length =$2
  saffl    label = 'Safety Population Flag'                   length =$2
  covar1   label = 'Covariate 1'                              length = 8
  covar1d  label = 'Covariate definition 1'                   length =$80
  age      label = 'Age'                                      length = 8
  agegr1   label = 'Pooled Age Group 1'                       length =$20
  agegr1n  label = 'Pooled Age Group 1 (N)'                   length = 8
  agegr2   label = 'Pooled Age Group 2'                       length =$20
  agegr2n  label = 'Pooled Age Group 2 (N)'                   length = 8
  ageu     label = 'Age Units'                                length =$10
  raceoth  label = 'Other Race Specification'                 length =$200
  race     label = 'Race'                                     length =$60
  sex      label = 'Sex'                                      length =$1
  ethnic   label = 'Ethnicity'                                length =$60
  sbtstdtc label = 'Start Date of Subsequent Therapy'         length =$19
  hrrstat  label = 'HRR Status - eCRF'                        length =$19
  brcastat label = 'BRCA Status - eCRF'                       length =$19
  ecogse   label = 'Screening ECOG Performance Status - eCRF' length = 8
  ecgge2se label = 'Screening ECOG GE 2 - eCRF'               length =$2
  ecogbe   label = 'Baseline ECOG Performance Status - eCRF'  length = 8
  ecgge2be label = 'Baseline ECOG GE 2 - eCRF'                length =$2
  ecogi    label = 'Baseline ECOG Performance Status - IVRS'  length = 8
  viscmete label = 'Visceral metastasis - eCRF'               length =$2
  viscmeti label = 'Visceral metastasis - IVRS'               length =$2
  bajorine label = 'Bajorin Risk index - eCRF'                length =$8
  pritrt   label = 'Prior Treatment'                          length =$2
  priio    label = 'Prior immuno-oncology'                    length =$2
  bmiblg1  label = 'Pooled Baseline BMI (kg/m2) Grouping 1'   length =$20
  bmiblg1n label = 'Pooled Baseline BMI (kg/m2) Group 1 (N)'  length = 8
  wgtblg1n label = 'Pooled Baseline Weight (kg) Group 1 (N)'  length = 8
  crcllwsc label = 'CrCl LT 60mL/min'                         length =$2
  ctcaeahl label = 'CTCAE Grd. GE 2 Audiometric Hearing Loss' length =$2
  ctcaepn  label = 'CTCAE Grade GE 2 Peripheral Neuropathy'   length =$2
  nyhachf  label = 'NYHA Class III Heart Failure'             length =$2
  ecogge2  label = 'ECOG GE 2 - IVRS'                         length =$2
  c2ca     label = 'CrCl LT 60 / CTCAE GE 2 AHL'              length =$2
  c2cp     label = 'CrCl LT 60 / CTCAE GE 2 PN'               length =$2
  c2cn     label = 'CrCl LT 60 / NYHA HF'                     length =$2
  c2ce     label = 'CrCl LT 60 / ECOG GE 2'                   length =$2
  c2ap     label = 'CTCAE GE 2 AHL / PN '                     length =$2
  c2an     label = 'CTCAE GE 2 AHL / NYHA'                    length =$2
  c2ae     label = 'CTCAE GE 2 AHL / ECOG GE 2'               length =$2
  c2pn     label = 'CTCAE GE 2 PN / NYHA'                     length =$2
  c2pe     label = 'CTCAE GE 2 PN / ECOG GE 2'                length =$2
  c2ne     label = 'NYHA / ECOG GE 2'                         length =$2
  c3cap    label = 'CrCl LT 60 / CTCAE GE 2 AHL / PN'         length =$2
  c3can    label = 'CrCl LT 60 / CTCAE GE 2 AHL / NYHA'       length =$2
  c3cae    label = 'CrCl LT 60 / CTCAE GE 2 AHL / ECOG GE 2'  length =$2
  c3cpn    label = 'CrCl LT 60 / CTCAE GE 2 PN / NYHA'        length =$2
  c3cpe    label = 'CrCl LT 60 / CTCAE GE 2 PN / ECOG GE 2'   length =$2
  c3cne    label = 'CrCl LT 60 / NYHA / ECOG GE 2'            length =$2
  c3apn    label = 'CTCAE GE 2 AHL / PN / NYHA'               length =$2
  c3ape    label = 'CTCAE GE 2 AHL / PN / ECOG GE 2'          length =$2
  c3ane    label = 'CTCAE GE 2 AHL / NYHA / ECOG GE 2'        length =$2
  c3pne    label = 'CTCAE GE 2 PN / NYHA / ECOG GE 2'         length =$2
  c4capn   label = 'CrCl LT 60/CTCAE GE 2 AHL/PN/NYHA'        length =$2
  c4cape   label = 'CrCl LT 60/CTCAE GE 2 AHL/PN/ECOG GE 2'   length =$2
  c4cane   label = 'CrCl LT 60/CTCAE GE 2 AHL/NYHA/ECOG GE 2' length =$2
  c4cpne   label = 'CrCl LT 60/CTCAE GE 2 PN/NYHA/ECOG GE 2'  length =$2
  c4apne   label = 'CTCAE GE 2 AHL/PN/NYHA/ECOG GE 2'         length =$2
  c5capne  label = 'CrCl LT 60 / AHL / PN / NYHA / ECOG GE 2' length =$2
  ve13scr  label = 'Vulnerable Elders Survey 13 Score'        length = 8
  ve13gr1n label = 'Vulnerable Elders Survey 13 Group 1 (N)'  length = 8
  ve13gr1  label = 'Vulnerable Elders Survey 13 Group 1'      length =$4
  advage   label = 'Advanced Age'                             length =$2
  redps    label = 'Reduced Performance Status'               length =$2
  cmdcom   label = 'Complex Medical Comorbidity(ies)'         length =$2
  cospfy   label = 'Specify Comorbility(ies)'                 length =$200
  cispiefl label = 'Cisplatin Ineligible Flag'                length =$2
  crbpiefl label = 'Carboplatin Ineligible Flag'              length =$2;
  set adsl26; 
run;

*Saves the adsl dataset to the adam library;
data adam.adsl(label = "Subject-Level Analysis Dataset");
  set adsl_f;
run;

%checklog;







