*******************************************************************;
*Program Name       : adcm.sas
*Protocol/Study     : D933IC00003
*Type               : ADAM
*Description        : To produce adcm adam dataset.
*Author             : Stephen Kangu
*
*Date created       : 25/07/2023
*Input datasets     : adam.adsl sdtm.cm raw.promed
*
*Macro used         : %checklog %create_seq %combinesdtm
*Function used      : 
*
*******************************************************************;
*
*Change History     :
*Reason for change  :
*Date changed       :
*
*******************************************************************;

%let dcodate       =2020-10-15;

*combination of suppcm and cm datasets ;

%combinesdtm(cm);

*imputation of the analysis end date and flagging;
data cm1;
  merge cm(in=a) adam.adsl;
  by usubjid;
  if a;
run;

*substringing dates months and years of treatment dates and cm dates to help compare nd impute;
data cm1_i;
  set cm1;
  trtsdt1=put(trtsdt,yymmdd10.);
  yy=substr(cmstdtc,1,4);
  yy1=substr(trtsdt1,1,4);
  mm=substr(cmstdtc,6,2);
  mm1=substr(cmstdtc,1,7);
  nm2=substr(trtsdt1,1,7); 
  trtedt1=put(trtedt,yymmdd10.);
  eyy=substr(cmendtc,1,4);
  eyy1=substr(trtedt1,1,4);
  emm=substr(cmendtc,6,2);
  emm1=substr(cmendtc,1,7);
  enm2=substr(trtedt1,1,7);
  nm=substr(trtedt1,6,2);
run;

*imputation of cmendtc to generate aendt;
data cm1_i2;
  set cm1_i;
  if length(cmendtc)=7 and emm1 eq enm2 then do;aendt1=trtedt1;aendtf='D';end;
  else if length(cmendtc)=7 then do;
     aendtf='D';
     *make imputations depending on the months;
     if emm in ('01' '03' '05' '07' '08' '10' '12') then aendt1=strip(cmendtc)||'-31';
     else if emm in ('04' '06' '09' '11' ) then aendt1=strip(cmendtc)||'-30';
     else if emm in ('02') and index(put((input(eyy,best12.))/4,best12.),'.') gt 0 then aendt1=strip(cmendtc)||'-28';
     else if emm in ('02') and index(put((input(eyy,best12.))/4,best12.),'.') lt 0 then aendt1=strip(cmendtc)||'-29';
  end;
  *if year is missing then check if the conditions hold to then impute;
  if length(cmendtc)=4 and eyy eq eyy1 then do;aendt1=trtedt1;aendtf='M';end;
  else if length(cmendtc)=4 then do;aendt1=strip(cmendtc)||'-12-31';aendtf='M';end;
  else if cmendtc eq '' then aendt1='';
  if aendt1 eq '' then aendt1=cmendtc;
  else aendt1=aendt1;
  *converting to numeric ;
  if aendt1 ne '' then aendt=input(aendt1,yymmdd10.);
run;

data cm1_i3;
  set cm1_i2;
  *checking dates where day is missing;
  if length(cmstdtc)=7 then do;
    if nm2 eq mm1 then do;
      if aendt ge trtsdt then do; 
        astdt1=trtsdt1;
        astdtf='D';
      end;
      else if aendt eq . and trtsdt ne . then do ;
        astdt1=trtsdt1;
        astdtf='D';
      end;
    end;
    else  do ;
      astdt1=strip(cmstdtc)||'-01';
      astdtf='D';
    end;
  end;
  *checking dates where month and dates are missing to impute;
  else if length(cmstdtc)=4 then do;
    if yy1 eq yy then do;
        if aendt ge trtsdt and aendt ne . and trtsdt ne . then do;astdt1=trtsdt1;astdtf='M';end;
        else if aendt eq . and trtsdt ne . then do;astdt1=trtsdt1;astdtf='M';end;
    end;
    else do;astdt1=strip(cmstdtc)||'-01-01';astdtf='M';end;
  end;
  *if the cmstdtc is missing then we impute the year or hence leave it blank;
  else if cmstdtc eq '' then do;
    if aendt ge trtsdt then do;astdt1=trtsdt1;astdtf='Y';end;
    else if aendt eq . and trtsdt ne . then do;astdt1=trtsdt1;astdtf='Y';end;
  end;
  else astdt1=cmstdtc;
  *converting the dates to numeric;
 if astdt1 ne '' then astdt=input(astdt1,yymmdd10.);
run;

data cm2;
  set cm1_i3;
  *array to check cmdecod: ;
  array old(7) cmdecod2-cmdecod8;
  if aendt ne . and trtsdt ne . then do;
    if aendt ge trtsdt then aendy=aendt-trtsdt+1;
    else aendy=aendt-trtsdt;
  end;
  if astdt ne . and trtsdt ne . then do;
    if astdt ge trtsdt then astdy=astdt-trtsdt+1;
    else astdy=astdt-trtsdt;
  end;
  do x=1 to 7 ;
    *checking if conditions hold to create flags;
    if atccd='L01XA' and cmstrf='BEFORE' then do;
       if  old(x) in ('CISPLATIN')  then  anl06fl='Y';
       else if  cmdecod eq 'CISPLATIN' then  anl06fl='Y';
    end;
    if atccd='L01XA' and cmstrf='BEFORE' then do;
       if  old(x) in ('CARBOPLATIN')  then  anl07fl='Y';
       else if  cmdecod eq 'CARBOPLATIN' then  anl07fl='Y';
    end;
  end;
run;

*bringing in promed dataset to obtain medpref and cm dates to make comparisons and hence create disallowed medication flag;
data promed_1(keep=usubjid cxsdat cmstdat medpref cmstdtc prohmed);
  set raw.promed;
  where prohmed='Y';
  cmstdtc=cmstdat;
  usubjid=strip(study)||'/'||strip(subject);
run;

proc sort data=promed_1 out=promed_2 ;
  by usubjid cmstdtc;
run;

proc sort data=cm2 out=cm2_s ;
  by usubjid cmstdtc;
run;

data cm3;
  merge cm2_s(in=a) promed_2;
  by usubjid cmstdtc;
  *array to check cmdecod: and create the disallowed medication flag;
  array old(7) cmdecod2-cmdecod8;
  array new(7) cmdecodxx2-cmdecodxx8;
  do y=1 to 7;
    if medpref ne '' and cmstdtc  ne '' and cmstdtc  eq cxsdat then do;*conditions to create cmdisrfl flag;
      if compress(medpref) eq compress(old(x)) then cmdisrfl='Y';
      else if  compress(medpref) eq compress(cmdecod) then cmdisrfl='Y';
    end;
    else if medpref ne '' and cmstdtc  ne '' and cmstdtc  eq cmstdat then do;
      if compress(medpref) eq compress(cmdecod) then cmdisrfl='Y';
    end;
    else cmdisrfl='';
  end;
  if a;
run;

data cm4;
  length aphase $40. atccd $18. cxbresp cxtrtst $40. ;
  set cm3(rename=(prchemo=prchemo1 atccd=atccd1 cxtrtst=cxtrtst1 cxbresp=cxbresp1));
  *generating aphase depending on conditions for epoch and trtsdt;
  If EPOCH in ("SAFETY FOLLOW-UP"  "OVERALL SURVIVAL FOLLOW-UP") then aphase= "FOLLOW-UP";
  else if epoch ne '' then aphase=epoch;
  else if epoch eq '' then do;
    if trtsdt eq  . then aphase ='SCREENING';
    else if astdt gt trtedt and trtedt ne . then aphase='FOLLOW-UP';
    else aphase='TREATMENT';
  end;
  *direct mapping variables;
  trta=trt01a;
  trtp=trt01p;
  trtpn=trt01pn;
  trtan=trt01an;
  prchemo=input(prchemo1,best12.);
  atccd=atccd1;
  cxtrtst=cxtrtst1;
  cxbresp=cxbresp1;
  format aendt date9.;
  format astdt date9.;
run;

*creating sequence of aseq;
%create_seq(DSIN = cm4 ,KEY = studyid usubjid cmcat cmscat cmdecod cmtrt astdt aendt cmspid ,DSOUT = cm4a ,LEVEL   = RDB);

*sorting dtasets and keeping required variables;
proc sort data=cm4a out=cm5(keep=studyid usubjid
cmseq aseq cmspid cmtrt cmdecod cmdecod2 cmdecod3 cmdecod4 cmdecod5 cmdecod6 cmdecod7 cmdecod8 cmcat cmscat cmindc cmdosu cmdostot 
cmstdtc cmendtc cmstdy cmendy cmstrf cmenrtpt atccd atcdtxt cmaeno cmaeno1 cmaeno2 cmaeno3 cxbresp cxtrtst prchemo subjid arm armcd 
actarm actarmcd trta trtan trtp trtpn trt01a trt01an trt01p trt01pn aendt aendtf aendy aphase astdt astdtf astdy siteid randdt randfl 
trtedt trtsdt trtedtm trtsdtm anl06fl anl07fl cmdisrfl dthdt dthdtf dthdtc dthfl strata stratan stratf1a stratf2a dctdt age ageu enrlfl 
fasfl sbtstdtc pop1fl pop1fld race recipfl saffl covar1 covar1d sex ethnic);
  by studyid usubjid cmcat cmscat cmdecod cmtrt astdt aendt cmspid;
run;

*generating attribs;
data adam.adcm(label='Concomitant Medication, Analysis Data');
attrib
STUDYID  label = 'Study Identifier'                         length=$21
USUBJID  label = 'Unique Subject Identifier'                length =$30
CMSEQ    label = 'Sequence Number'                          length = 8
ASEQ     label = 'Analysis Sequence Number'                 length = 8
CMSPID   label = 'Sponsor-Defined Identifier'               length =$40
CMTRT    label = 'Reported Name of Drug, Med, or Therapy'   length =$200
CMDECOD  label = 'Standardized Medication Name'             length =$200
CMDECOD2 label = 'Standardized Medication Name 2'           length =$200
CMDECOD3 label = 'Standardized Medication Name 3'           length =$200
CMDECOD4 label = 'Standardized Medication Name 4'           length =$200
CMDECOD5 label = 'Standardized Medication Name 5'           length =$200
CMDECOD6 label = 'Standardized Medication Name 6'           length =$200
CMDECOD7 label = 'Standardized Medication Name 7'           length =$200
CMDECOD8 label = 'Standardized Medication Name 8'           length =$200
CMCAT    label = 'Category for Medication'                  length =$40
CMSCAT   label = 'Subcategory for Medication'               length =$40
CMINDC   label = 'Indication'                               length =$200
CMDOSU   label = 'Dose Units'                               length =$20
CMDOSTOT label = 'Total Daily Dose'                         length = 8
CMSTDTC  label = 'Start Date/Time of Medication'             
CMENDTC  label = 'End Date/Time of Medication'              
CMSTDY   label = 'Study Day of Start of Medication'         length = 8
CMENDY   label = 'Study Day of End of Medication'           length = 8
CMSTRF   label = 'Start Relative to Reference Period'       length =$40
CMENRTPT label = 'End Relative to Reference Time Point'     length =$40
ATCCD    label = 'ATC Code'                                 length =$18
ATCDTXT  label = 'ATC Dictionary Text'                      length =$200
CMAENO   label = 'AE Number for Medication Taken'           length =$200
CMAENO1  label = 'AE Number for Medication Taken 1'         length =$200
CMAENO2  label = 'AE Number for Medication Taken 2'         length =$200
CMAENO3  label = 'AE Number for Medication Taken 3'         length =$200
CXBRESP  label = 'Best Response'                            length =$40
CXTRTST  label = 'Treatment Status'                         length =$40
PRCHEMO  label = 'Number of Prior Chemo Regimens'           length = 8
SUBJID   label = 'Subject Identifier for the Study'         length =$8
ARM      label = 'Description of Planned Arm'               length =$200
ARMCD    label = 'Planned Arm Code'                         length =$20
ACTARM   label = 'Description of Actual Arm'                length =$200
ACTARMCD label = 'Actual Arm Code'                          length =$20
TRTA     label = 'Actual Treatment'                         length =$40
TRTAN    label = 'Actual Treatment (N)'                     length = 8
TRTP     label = 'Planned Treatment'                        length =$40
TRTPN    label = 'Planned Treatment (N)'                    length = 8
TRT01A   label = 'Actual Treatment for Period 01'           length =$40
TRT01AN  label = 'Actual Treatment for Period 01 (N)'       length = 8
TRT01P   label = 'Planned Treatment for Period 01'          length =$40
TRT01PN  label = 'Planned Treatment for Period 01 (N)'      length = 8
AENDT    label = 'Analysis End Date'                        length = 8
AENDTF   label = 'Analysis End Date Imputation Flag'        length =$2
AENDY    label = 'Analysis End Relative Day'                length = 8
APHASE   label = 'Phase'                                    length =$40
ASTDT    label = 'Analysis Start Date'                      length = 8
ASTDTF   label = 'Analysis Start Date Imputation Flag'      length =$2
ASTDY    label = 'Analysis Start Relative Day'              length = 8
SITEID   label = 'Study Site Identifier'                    length =$5
RANDDT   label = 'Date of Randomization'                    length = 8
RANDFL   label = 'Randomized Population Flag'               length =$2
TRTEDT   label = 'Date of Last Exposure to Treatment'       length = 8
TRTSDT   label = 'Date of First Exposure to Treatment'      length = 8
TRTEDTM  label = 'Datetime of Last Exposure to Treatment'   length = 8
TRTSDTM  label = 'Datetime of First Exposure to Treatment'  length = 8
ANL06FL  label = 'Analysis Flag 06'                         length =$2
ANL07FL  label = 'Analysis Flag 07'                         length =$2
CMDISRFL label = 'Disallowed Medication Record Flag'        length =$2
DTHDT    label = 'Date of Death'                            
DTHDTF   label = 'Date of Death Imputation Flag'            length =$2
DTHDTC   label = 'Date/Time of Death'                       
DTHFL    label = 'Subject Death Flag'                       length =$1
STRATA   label = 'Randomized Strata'                        length =$200
STRATAN  label = 'Randomized Strata (N)'                    length = 8
STRATF1A label = 'Stratification Factor-HRR status'         length =$200
STRATF2A label = 'Stratification Factor-Bajorin Risk index' length =$8
DCTDT    label = 'Date of Discontinuation of Treatment'     length = 8
AGE      label = 'Age'                                      length = 8
AGEU     label = 'Age Units'                                length =$10
ENRLFL   label = 'Enrolled Population Flag'                 length =$2
FASFL    label = 'Full Analysis Set Population Flag'        length =$2
SBTSTDTC label = 'Start Date of Subsequent Therapy'         
POP1FL   label = 'Population 1 Flag'                        length =$2
POP1FLD  label = 'Population 1 Flag Description'            length =$200
RACE     label = 'Race'                                     length =$60
RECIPFL  label = 'Subject Received Investigational Product' length =$2
SAFFL    label = 'Safety Population Flag'                   length =$2
COVAR1   label = 'Covariate 1'                              length = 8
COVAR1D  label = 'Covariate definition 1'                   length =$80
SEX      label = 'Sex'                                      length =$1
ETHNIC   label = 'Ethnicity'                                length =$60;
 set cm5;
run;


%checklog;
