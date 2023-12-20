*******************************************************************;
*Program Name       : advs.sas
*Protocol/Study     : D933IC00003
*Type               : ADAM
*Description        : To produce advs adam dataset.
*Author             : Stephen Kangu
*
*Date created       : 05/07/2023
*Input datasets     : adam.adsl sdtm.vs
*
*Macro used         : %checklog %create_seq %avisit_window %combinesdtm
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

*combination of suppvs and vs datasets ;
%combinesdtm(vs);

*subsetting the dataset to only those where tests were perfomed;
data vs_1;
  set vs;
  if vsperf eq 'Yes' then do;
    param=strip(vstest)||' ('||strip(vsorresu)||')';
    if vsstresn ne .;
    output;
  end;
run;

*datastep to merge adsl and our vs dataset;
data vs_1s;
  merge vs_1(in=a) adam.adsl;
  by usubjid;
  if a;
run;

data vs_2;
  length atpt $40.;
  set vs_1s(rename=(vsdtc=vs));
  aval=vsstresn;
  *imputing time part of vsdtc;
  if length(vs)=10 then vsdtc=strip(vs)||'T00:00';
  else vsdtc=vs;
  if vsdtc ne '' then adt=input(vsdtc,e8601da.);
  *setting atpt and atptn variables depending on visits ;
  if visit in ('End of Treatment','Unscheduled') then do;
    atpt='Pre-dose';
    atptn=2;
  end;
  else do;
    atpt=vstpt;
    atptn=vstptnum;
  end;
  *creating aphase based on epoch;
  if epoch in ("safety follow-up" "long-term safety follow-up" "overall survival follow-up") then do;aphase="follow-up";end;
  else If epoch ne '' then do;
    If TRTSDT= . or TRTSDT > ADT and ADT> . then aphase="SCREENING";
    If ADT > TRTEDT and TRTEDT > . then aphase= "FOLLOW-UP";
    else  aphase = "TREATMENT";
  end;
  else do;aphase=epoch;end;
run;

data vs_3;
  set vs_2;
  *converting dates to numeric;
  if length(vsdtc) eq 16 then adtm=input(vsdtc,b8601dt.);
  if vsdtc ne '' then vsdtc1=input(vsdtc,yymmdd10.);
  dco=input("&dcodate.",yymmdd10.);
  *finding the minimum value of the available variables to create anl01fl;
  if  trtedt ne . and vsdtc1 ne . then ff=Min( DCO, vsdtc1, TRTEDT+30);
  else if trtedt eq .  and vsdtc1 ne . then ff=Min( DCO, vsdtc1);
  else if vsdtc1 eq .  and trtedt eq . then ff= DCO;
  else if vsdtc1 eq .  and trtedt ne . then ff=Min( DCO,  TRTEDT+30);
  if trtsdtm le adtm and adt le ff then anl01fl='Y';
run;

*setting out vsblfl observations to obtain base after merging back;
proc sort data =vs_3 out=vsb_1(keep=usubjid vstestcd vsstresn vsblfl rename=( vsstresn=base vsblfl=blf));
  by usubjid vstestcd ;
  where vsblfl='Y';
run;

proc sort data=vs_3 out=vs_4;
  by usubjid vstestcd ;
run;

*merging back obsevations with vsblfl to obtain base values;
data vs_5;
  merge vs_4 vsb_1;
  by usubjid vstestcd ;
run;

data vs_6;
  set vs_5;
  if aval ne . and base ne . then chg=aval-base;*calculating change between base and results;
  *direct mapping of variables;
  ablfl=vsblfl;
  paramcd=vstestcd;
  aval=vsstresn;
  ady=vsdy;
run;

proc sort data=vs_6 out=vs_7;
  by usubjid paramcd descending aval vsdtc1;
run;

*obtaining avisit and avisitn variables through macro;
%avisit_window(dm=advs, dsin=vs_7, dsout=vs_7v, xxdtc=ADT, xxdy=ADY, treatst=TRTSDT, dctdate=TRTEDT);

data vs_8a vs_8b1;
  set vs_7v;
  *creating anl02fl and anl03fl flags;
  by usubjid paramcd descending aval vsdtc1;
  if first.paramcd and anl01fl='Y' then anl02fl='Y'; 
  if last.paramcd and anl01fl='Y' then anl03fl='Y';
  if anl01fl='Y' then output vs_8b1;*splitting datasets to create al05fl flag later;
  else output vs_8a;
run;
 
proc sort data=vs_8b1 out=vs_8b2;
  by usubjid visitnum paramcd vsdtc1;
run;

*creation of anl05fl depending on anl01fl;
data vs_8b3;
  set vs_8b2;
  by usubjid visitnum paramcd vsdtc1;
  if first.paramcd then anl05fl='Y';
run;

data vs_9;
  set vs_8b3 vs_8a;
  *direct mapping of variables where aval ne '' ;
  where aval ne .;
  trta=trt01a;
  trtp=trt01p;
  trtan=trt01an;
  trtpn=trt01pn;
  format adtm DATETIME18.;
run;

*generating sequence aseq;
%create_seq(DSIN = vs_9 ,KEY = STUDYID USUBJID ADTM ATPTN PARAMCD ,DSOUT = vs_10 ,LEVEL   = RDB);

*sorting datasets and keeping required variables;
proc sort data=vs_10 out=vs_11(keep=studyid usubjid aseq vsseq visitnum visit visitdy subjid arm armcd trta trtan trtp
                trtpn trt01a trt01an trt01p trt01pn actarm actarmcd adt ady aphase atpt atptn avisit avisitn aval base 
                chg param paramcd ablfl anl01fl anl02fl anl03fl anl05fl adtm randdt trtedt trtsdt trtedtm trtsdtm dthdt 
               dthdtf dthdtc dctdt age ageu enrlfl fasfl sbtstdtc ethnic);
  by studyid usubjid adtm atptn paramcd;
run;

*outlining dataset to appear in a certain order;
data adam.advs(label='Vital Signs, Analysis Data');
attrib
STUDYID  label = 'Study Identifier'                         length =$21
USUBJID  label = 'Unique Subject Identifier'                length =$30
ASEQ     label = 'Analysis Sequence Number'                 length = 8
VSSEQ    label = 'Sequence Number'                          length = 8
VISITNUM label = 'Visit Number'                             length = 8
VISIT    label = 'Visit Name'                               length =$40
VISITDY  label = 'Planned Study Day of Visit'               length = 8
SUBJID   label = 'Subject Identifier for the Study'         length =$8
ARM      label = 'Description of Planned Arm'               length =$200
ARMCD    label = 'Planned Arm Code'                         length =$20
TRTA     label = 'Actual Treatment'                         length =$40
TRTAN    label = 'Actual Treatment (N)'                     length = 8
TRTP     label = 'Planned Treatment'                        length =$40
TRTPN    label = 'Planned Treatment (N)'                    length = 8
TRT01A   label = 'Actual Treatment for Period 01'           length =$40
TRT01AN  label = 'Actual Treatment for Period 01 (N)'       length = 8
TRT01P   label = 'Planned Treatment for Period 01'          length =$40
TRT01PN  label = 'Planned Treatment for Period 01 (N)'      length = 8
ACTARM   label = 'Description of Actual Arm'                length =$200
ACTARMCD label = 'Actual Arm Code'                          length =$20
ADT      label = 'Analysis Date'                            length = 8
ADY      label = 'Analysis Relative Day'                    length = 8
APHASE   label = 'Phase'                                    length =$40
ATPT     label = 'Analysis Timepoint'                       length =$40
ATPTN    label = 'Analysis Timepoint (N)'                   length = 8
AVISIT   label = 'Analysis Visit'                           length =$40
AVISITN  label = 'Analysis Visit (N)'                       length = 8
AVAL     label = 'Analysis Value'                           length = 8
BASE     label = 'Baseline Value '                          length = 8
CHG      label = 'Change from Baseline'                     length = 8
PARAM    label = 'Parameter'                                length =$200
PARAMCD  label = 'Parameter Code'                           length =$8
ABLFL    label = 'Baseline Record Flag'                     length =$2
ANL01FL  label = 'Analysis Flag 01'                         length =$2
ANL02FL  label = 'Analysis Flag 02'                         length =$2
ANL03FL  label = 'Analysis Flag 03'                         length =$2
ANL05FL  label = 'Analysis Flag 05'                         length =$2
ADTM     label = 'Analysis Datetime'                        length = 8
RANDDT   label = 'Date of Randomization'                    length = 8
TRTEDT   label = 'Date of Last Exposure to Treatment'       length = 8
TRTSDT   label = 'Date of First Exposure to Treatment'      length = 8
TRTEDTM  label = 'Datetime of Last Exposure to Treatment'   length = 8
TRTSDTM  label = 'Datetime of First Exposure to Treatment'  length = 8
DTHDT    label = 'Date of Death'                            
DTHDTF   label = 'Date of Death Imputation Flag'            length =$2
DTHDTC   label = 'Date/Time of Death'                        
DCTDT    label = 'Date of Discontinuation of Treatment'     length = 8
AGE      label = 'Age'                                      length = 8
AGEU     label = 'Age Units'                                length =$10
ENRLFL   label = 'Enrolled Population Flag'                 length =$2
FASFL    label = 'Full Analysis Set Population Flag'        length =$2
SBTSTDTC label = 'Start Date of Subsequent Therapy'         
ETHNIC   label = 'Ethnicity'                                length =$60
;
  set vs_11;
run;


%checklog;
