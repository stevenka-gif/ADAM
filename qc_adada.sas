*******************************************************************;
*Program Name       : qc_adada.sas
*Protocol/Study     : D933IC00003
*Type               : ADAM
*Description        : To qc adada adada dataset.
*Author             : Stephen Kangu
*
*Date created       : 19/07/2023
*Input datasets     : adam.adsl adam.adlb
*
*Macro used         : %checklog %createseq
*Function used      : 
*
*******************************************************************;
*
*Change History     :
*Reason for change  :
*Date changed       :
*
*******************************************************************;

libname adam1 'P:\Training Area\PhaPharma\PRAXIS2\Data\Analysis\original';

data adada1(drop=aseq);
  length crit1 crit2 crit4 crit3 crit7 crit8 crit9 crit10 crit11 crit12 $200
         crit1fl crit2fl crit3fl crit4fl crit7fl crit8fl crit9fl crit10fl crit11fl crit12fl $2;
  set adam1.adlb(rename=(aval=avv base=abb));
  where paramcd in ('LM86' 'LM85' 'LN72');
  if paramcd eq 'LM85' then do;
  if avalc  eq '4' or avalc eq '8' or avalc eq '32' or avalc eq '256' or avalc eq '16' then aval=input(avalc,best12.);
  *if aval not in ('Positive' 'Negative') and index(avalc,'<') lt 1 then aval=input(avalc,best12.);;
  *deriving base and analysis value  ; 
  if basec  eq '4' or basec eq '8' or basec eq '32' or basec eq '256' or basec eq '16' then base=input(basec,best12.);
    if aval ne . and base ne . then avb=aval/base;
    if avb le 4 and ady lt 1 then do;
      crit8='Treatment-boosted ADA';
      crit8fl='Y';
    end;
  end;
  if paramcd eq 'LM86' then do;
    *derivation of criteria 1 and its flag;
    if ablfl eq 'Y' and avalc eq 'Positive' then do;
      crit1='ADA positive at baseline';
      crit1fl='Y';
    end;
    *derivation of criteria 2 and its flag;
    if ady gt 1 and avalc eq 'Positive' then do;
      crit2='ADA positive post-baseline';
      crit2fl='Y';
    end;
    *derivation of criteria 8 and its flag;
    if ablfl='Y' and avalc eq 'Positive' then do;
      crit8='Treatment-boosted ADA';
      crit8fl='Y';
    end;
    *derivation of criteria 2 and its flag;
    if ablfl='Y' and avalc in ( 'Positive' 'Negative') and ady gt 1 then do;
      crit12='Treatment-boosted ADA';
      crit12fl='Y';
    end;
  end;
  *derivation of criteria 3 and its flag;
  if crit1fl = 'y' and crit2fl = 'y' then do;
    crit3='ADA positive post-baseline and positive at baseline';
    crit3fl='Y';
  end;
  *derivation of criteria 4 and its flag;
  if crit1fl ne 'y' and crit2fl = 'y' then do;
    crit4='ADA positive post-baseline and not detected at baseline';
    crit4fl='Y';
  end;
  *derivation of criteria 7 and its flag;
  if crit1fl='Y' or crit2fl='Y' then do;
    crit7='Any ADA positive (baseline or post-baseline)';
    crit7fl='Y';
  end;
  *derivation of criteria 10 and its flag;
  if crit1fl='Y' and crit2fl ne 'Y' then do;
    crit10fl='Y';
    crit10='ADA not detected post-baseline and positive at baseline';
  end;
  *derivation of criteria 9 and its flag;
  if crit4fl eq 'Y' or crit8fl eq 'Y' then do;
    crit9='ADA incidence';
    crit9fl='Y';
  end;
  *derivation of criteria 11 and its flag;
  if paramcd eq 'LN72' then do;
    if avalc='Positive' then do;
      crit11='Any nAb positive';
      crit11fl='Y';
    end;
  end;
run;

*sorting to subset the data for lm86 parmcd to create criteria 5;
proc sort data=adada1 out=adada_a;
  by usubjid ady;
  where paramcd eq 'LM86';
run;

data ff(keep=usubjid ady1);
  set adada_a;
  by usubjid ady;
  ady1=ady;
  if first.usubjid;
run;

data bb(keep=diff usubjid avalc ady);
  merge ff adada_a;
  by usubjid;
  diff=abs(ady1-ady);
  if diff ge 112 ;/*and first.usubjid ne 1 and last.usubjid and avalc='Positive';*/
run;

or the difference in ADY between the first and last AVALC = 'POSITIVE' records is >= 112

*selecting the very last positive result post baseline;
data adada_b(keep=usubjid avalc ady crit5 crit5fl);
  set adada_a;
  by usubjid ady;
  if first.usubjid ne 1 and last.usubjid gt 0 and avalc eq 'Positive' then do;
    crit5='Persistent Positive';
    crit5fl='Y';
  end;
  if crit5 ne '';
run;


data adada1_m;
  *merging the dataset to obtain  criteria 6 and 5 alongside their flags;
  merge adada_b adada1;
  by usubjid;
  if crit2fl='Y' and crit5fl='Y' then do;
    crit6='Transient Positive';
    crit6fl='Y';
  end;
run;

*creating sequence variable to make records ;
%create_seq(DSIN = adada1_m ,KEY  = STUDYID USUBJID PARAMCD ADTM LBSEQ,DSOUT = adada2,LEVEL   = RDB);

*keeping required variables and setting the lables and lengths;
data adada3(keep=studyid usubjid lbseq aseq lbscat lbstat visitnum visit visitdy lbdtc module subjid arm armcd actarm actarmcd trta trtan
trtp trtpn trt01a trt01an trt01p trt01pn adt adtm atmf ady avisit avisitn aval avalc base basec
param paramcd parcat1 ablfl anl01fl anl02fl anl03fl anl05fl crit1 crit1fl crit2 crit2fl crit3
crit3fl crit4 crit4fl crit5 crit5fl crit6 crit6fl crit7 crit7fl crit8 crit8fl crit9 crit9fl 
crit10 crit10fl crit11 crit11fl crit12 crit12fl siteid randdt randfl trtedt trtsdt trtedtm 
trtsdtm dthdt dthdtf dthdtc dthfl strata stratan stratf1a stratf2a dctdt age ageu 
enrlfl fasfl sbtstdtc pop1fl pop1fld race recipfl saffl covar1 covar1d sex ethnic);
  attrib
STUDYID  label = 'Study Identifier'                         length =$21
USUBJID  label = 'Unique Subject Identifier'                length =$30
LBSEQ    label = 'Sequence Number'                          length = 8
ASEQ     label = 'Analysis Sequence Number'                 length = 8
LBSCAT   label = 'Subcategory for Lab Test'                 length =$40
LBSTAT   label = 'Completion Status'                        length =$8
VISITNUM label = 'Visit Number'                             length = 8
VISIT    label = 'Visit Name'                               length =$40
VISITDY  label = 'Planned Study Day of Visit'               length = 8
LBDTC    label = 'Date/Time of Specimen Collection'         
MODULE   label = 'Source Module Short Name'                 length =$8
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
ADT      label = 'Analysis Date'                            length = 8
ADTM     label = 'Analysis Datetime'                        length = 8
ATMF     label = 'Analysis Time Imputation Flag'            length =$2
ADY      label = 'Analysis Relative Day'                    length = 8
AVISIT   label = 'Analysis Visit'                           length =$40
AVISITN  label = 'Analysis Visit (N)'                       length = 8
AVAL     label = 'Analysis Value'                           length = 8
AVALC    label = 'Analysis Value (C)'                       length =$200
BASE     label = 'Baseline Value'                           length = 8
BASEC    label = 'Baseline Value (C)'                       length =$200
PARAM    label = 'Parameter'                                length =$200
PARAMCD  label = 'Parameter Code'                           length =$8
PARCAT1  label = 'Parameter Category 1'                     length =$40
ABLFL    label = 'Baseline Record Flag'                     length =$2
ANL01FL  label = 'Analysis Flag 01'                         length =$2
ANL02FL  label = 'Analysis Flag 02'                         length =$2
ANL03FL  label = 'Analysis Flag 03'                         length =$2
ANL05FL  label = 'Analysis Flag 05'                         length =$2
CRIT1    label = 'Analysis Criterion 1'                     length =$200
CRIT1FL  label = 'Criterion 1 Evaluation Result Flag'       length =$2
CRIT2    label = 'Analysis Criterion 2'                     length =$200
CRIT2FL  label = 'Criterion 2 Evaluation Result Flag'       
CRIT3    label = 'Analysis Criterion 3'                     length =$200
CRIT3FL  label = 'Criterion 3 Evaluation Result Flag'       length =$2
CRIT4    label = 'Analysis Criterion 4'                     length =$200
CRIT4FL  label = 'Criterion 4 Evaluation Result Flag'       length =$2
CRIT5    label = 'Analysis Criterion 5'                     length =$200
CRIT5FL  label = 'Criterion 5 Evaluation Result Flag'       length =$2
CRIT6    label = 'Analysis Criterion 6'                     length =$200
CRIT6FL  label = 'Criterion 6 Evaluation Result Flag'       length =$2
CRIT7    label = 'Analysis Criterion 7'                     length =$200
CRIT7FL  label = 'Criterion 7 Evaluation Result Flag'       length =$2
CRIT8    label = 'Analysis Criterion 8'                     length =$200
CRIT8FL  label = 'Criterion 8 Evaluation Result Flag'       length =$2
CRIT9    label = 'Analysis Criterion 9'                     length =$200
CRIT9FL  label = 'Criterion 9 Evaluation Result Flag'       length =$2
CRIT10   label = 'Analysis Criterion 10'                    length =$200
CRIT10FL label = 'Criterion 10 Evaluation Result Flag'      length =$2
CRIT11   label = 'Analysis Criterion 11'                    length =$200
CRIT11FL label = 'Criterion 11 Evaluation Result Flag'      length =$2
CRIT12   label = 'Analysis Criterion 12'                    length =$200
CRIT12FL label = 'Criterion 12 Evaluation Result Flag'      length =$2
SITEID   label = 'Study Site Identifier'                    length =$5
RANDDT   label = 'Date of Randomization'                    length = 8
RANDFL   label = 'Randomized Population Flag'               length =$2
TRTEDT   label = 'Date of Last Exposure to Treatment'       length = 8
TRTSDT   label = 'Date of First Exposure to Treatment'      length = 8
TRTEDTM  label = 'Datetime of Last Exposure to Treatment'   length = 8
TRTSDTM  label = 'Datetime of First Exposure to Treatment'  length = 8
DTHDT    label = 'Date of Death'                            length = 8
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
ETHNIC   label = 'Ethnicity'                                length =$60
;
  set adada2;
run;

*labelling the dataset;
data adada4(label='ADA Results, Analysis Data');
  set adada3;
run;

proc compare base=adada4 compare=xx listall;
run;


%checklog;
