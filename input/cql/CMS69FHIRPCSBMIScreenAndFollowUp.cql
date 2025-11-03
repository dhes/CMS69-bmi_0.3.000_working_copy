library CMS69FHIRPCSBMIScreenAndFollowUp version '0.3.002'

using QICore version '6.0.0'

include FHIRHelpers version '4.4.000' called FHIRHelpers
include Hospice version '6.15.002' called Hospice
include PalliativeCare version '1.15.002' called PalliativeCare
include QICoreCommon version '4.0.000' called QICoreCommon
include SupplementalDataElements version '5.1.000' called SDE

codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "LOINC": 'http://loinc.org'
codesystem "ObservationCategoryCodes": 'http://terminology.hl7.org/CodeSystem/observation-category'

valueset "Encounter to Evaluate BMI": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.600.1.1751'
valueset "Follow Up for Above Normal BMI": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.600.1.1525'
valueset "Follow Up for Below Normal BMI": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.600.1.1528'
valueset "Medical Reason": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.1007'
valueset "Medications for Above Normal BMI": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.1561'
valueset "Medications for Below Normal BMI": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.1562'
valueset "Overweight or Obese": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1047.502'
valueset "Patient Declined": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.1582'
valueset "Pregnancy or Other Related Diagnoses": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.600.1.1623'
valueset "Referrals Where Weight Assessment May Occur": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.600.1.1527'
valueset "Underweight": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.1563'

code "Body mass index (BMI) [Ratio]": '39156-5' from "LOINC" display 'Body mass index (BMI) [Ratio]'
code "Encounter for palliative care": 'Z51.5' from "ICD10CM" display 'Encounter for palliative care'
code "Functional Assessment of Chronic Illness Therapy - Palliative Care Questionnaire (FACIT-Pal)": '71007-9' from "LOINC" display 'Functional Assessment of Chronic Illness Therapy - Palliative Care Questionnaire (FACIT-Pal)'
code "virtual": 'VR' from "ActCode" display 'virtual'

parameter "Measurement Period" Interval<DateTime> default Interval[DateTime(2025,1,1,0,0,0,0,0), DateTime(2025,12,31,23,59,59,999,0)]

context Patient

define "Real Time Mode":
  Coalesce(year from start of "Measurement Period" = 1900, false)

define MeasurementPeriod: "Measurement Period" // 20261016 this identifier is never used

// Experimental: analog of "Measurement Period"
define "Current Period":
  Interval[DateTime(year from Today(), 1, 1, 0, 0, 0, 0, 0), DateTime(year from Today(), 12, 31, 23, 59, 59,999, 0)]

define "Date Of Birth": date from Patient.birthDate

define "Age In Years": AgeInYears()

define "Age In Years At Start Of Measurement Period": AgeInYearsAt(date from start of "Measurement Period")

define "Initial Population":
  if "Real Time Mode" then
    AgeInYears() >= 18
  else
    exists "Qualifying Encounter During Day Of Measurement Period" QualifyingEncounter
      where "AgeInYearsAt"(date from start of QualifyingEncounter.period) >= 18

define "Denominator":
  "Initial Population"

define "Denominator Exclusions": 
  Hospice."Has Hospice Services"
    or PalliativeCare."Has Palliative Care in the Measurement Period"
    or "Is Pregnant During Day Of Measurement Period"

define "Numerator": 
  exists "High BMI And Follow Up Provided"
    or exists "Low BMI And Follow Up Provided"
    or "Has Normal BMI"

define "Denominator Exceptions": 
  exists "Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI"
    or exists "Medical Reason Or Patient Reason For Not Performing BMI Exam"

define "BMI During Measurement Period":
  [USCoreBMIProfile] BMI
    where BMI.value > 0 'kg/m2'
      and BMI.status in { 'final', 'amended', 'corrected' }
      and if "Real Time Mode" then
        BMI.effective.toInterval() during day of "Current Period"
      else
        BMI.effective.toInterval() during day of "Measurement Period"

define "Documented Low BMI During Measurement Period":
  "BMI During Measurement Period" BMI
    // where BMI.effective.toInterval ( ) during day of "Measurement Period"
      where BMI.value < 18.5 'kg/m2'

define "Documented High BMI During Measurement Period":
  "BMI During Measurement Period" BMI
    // where BMI.effective.toInterval ( ) during day of "Measurement Period"
      where BMI.value >= 25 'kg/m2'

define "Has Normal BMI":
  exists ( "BMI During Measurement Period" BMI
      where BMI.value >= 18.5 'kg/m2'
        and BMI.value < 25 'kg/m2'
  )
    and not ( exists "Documented High BMI During Measurement Period"
        or exists "Documented Low BMI During Measurement Period"
    )

define "High BMI And Follow Up Provided":
  "Documented High BMI During Measurement Period" HighBMI
    with ( "High BMI Interventions Ordered"
      union "High BMI Interventions Performed" ) HighBMIInterventions
      such that if "Real Time Mode" then
        Coalesce(HighBMIInterventions.performed.toInterval(), HighBMIInterventions.authoredOn.toInterval()) starts during day of "Current Period"
      else
        Coalesce(HighBMIInterventions.performed.toInterval(), HighBMIInterventions.authoredOn.toInterval()) starts during day of "Measurement Period"

define "High BMI Interventions Ordered":
  ( ( [ServiceRequest: "Follow Up for Above Normal BMI"]
      union [ServiceRequest: "Referrals Where Weight Assessment May Occur"]
      union [MedicationRequest: "Medications for Above Normal BMI"] ) HighInterventionsOrdered
      where HighInterventionsOrdered.reasonCode in "Overweight or Obese"
        or ( exists [ConditionProblemsHealthConcerns: "Overweight or Obese"] OverweightObese
            where ( OverweightObese.isProblemListItem ( )
                or OverweightObese.isHealthConcern ( )
            )
              and OverweightObese.isActive ( )
              and OverweightObese.prevalenceInterval ( ) starts before or on day of HighInterventionsOrdered.authoredOn
        )
  )

define "High BMI Interventions Performed":
  ( [Procedure: "Follow Up for Above Normal BMI"] HighInterventionsPerformed
      where HighInterventionsPerformed.reasonCode in "Overweight or Obese"
        or ( exists [ConditionProblemsHealthConcerns: "Overweight or Obese"] OverweightObese
            where ( OverweightObese.isProblemListItem ( )
                or OverweightObese.isHealthConcern ( )
            )
              and OverweightObese.isActive ( )
              and OverweightObese.prevalenceInterval ( ) starts before or on day of start of HighInterventionsPerformed.performed.toInterval ( )
              and not ( OverweightObese.prevalenceInterval ( ) ends before day of start of HighInterventionsPerformed.performed.toInterval ( ) )
        )
  )

define "Medical Reason Or Patient Reason For Not Performing BMI Exam":
  [ObservationCancelled: code = "Body mass index (BMI) [Ratio]"] NoBMI
    with "Qualifying Encounter During Day Of Measurement Period" QualifyingEncounter
      such that NoBMI.effective.toInterval ( ) ends same day as start of QualifyingEncounter.period
    where NoBMI.status = 'cancelled'
      and ( NoBMI.notDoneReason in "Patient Declined"
          or NoBMI.notDoneReason in "Medical Reason"
      )

// Begin Experimental Section BMI Not Done Banner
// define "BMI Not Done Observation":
//     First(
//       "Medical Reason Or Patient Reason For Not Performing BMI Exam" R
//       sort by effective.toInterval().low desc
//     )

// define A: 
//   "Medical Reason Or Patient Reason For Not Performing BMI Exam" obs
//     let
//       notDoneReason: obs.notDoneReason,  // a QICore ObservationCancelled CodableConcept extension mapped to a notDoneReason element
//       reasonCategory: 
//         if notDoneReason in "Medical Reason"
//           then 'Medical Reason'
//         else if notDoneReason in "Patient Declined"
//          then 'Patient Reason'
//         else null,
//       reasonSystem: 
//         Last(Split(notDoneReason.codes[0].system, '/')),
//       reasonSystemCode: 
//         reasonSystem + '|' + notDoneReason.codes[0].code,
//       reasonDisplay: notDoneReason.codes[0].display
//     return Tuple {
//       category: reasonCategory,
//       bannerCode: reasonSystemCode, 
//       display: reasonDisplay,
//       bannerText: 'BMI Assessment Exception, ' + reasonCategory + ': ' + reasonDisplay
//     }

define "Assessment Not Done": 
  "Medical Reason Or Patient Reason For Not Performing BMI Exam" obs
    let
      notDoneReason: obs.notDoneReason.codes[0],  // a QICore ObservationCancelled CodableConcept extension mapped to a notDoneReason element
      reasonCategory: 
        if notDoneReason in "Medical Reason"
          then 'Medical Reason'
        else if notDoneReason in "Patient Declined"
         then 'Patient Reason'
        else null,
      reasonSystem: 
        Last(Split(notDoneReason.system, '/')),
      reasonSystemCode: 
        reasonSystem + '|' + notDoneReason.code,
      reasonDisplay: notDoneReason.display
    return Tuple {
      category: reasonCategory,
      bannerCode: reasonSystemCode, 
      display: reasonDisplay,
      bannerText: 'BMI Assessment Exception, ' + reasonCategory + ': ' + reasonDisplay
    }

// define B: A.bannerCode
// define C: A.bannerText
// define D: A.display
// define E: A.category + A.display
// define F: 

// define "BMI Not Done Category":
//   "BMI Not Done Observation" obs
//   let reasonCode: obs.notDoneReason
//   return
//     if reasonCode in "Medical Reason"
//       then 'Medical Reason'
//     else if reasonCode in "Patient Declined"
//       then 'Patient Reason'
//     else 'Unknown Reason'

// define "BMI Not Done Reason Display":
//   "BMI Not Done Observation" obs
//     let reasonExt: First(obs.extension E
//           where E.url = 'http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-notDoneReason')
//     return
//       if reasonExt is not null
//         then (reasonExt.value as System.Concept).codes[0].display
//       else 'Reason not documented'

// define Refactored1: // A proposed refactoring of "BMI Not Done Reason Display"
//   "BMI Not Done Observation".notDoneReason.codes[0].display

// define BannerSystemCode: // A proposed refactoring to expose "BMI Not Done Reason Display" system|code
//   "BMI Not Done Observation" O
//    let notDoneSystem: Last(Split(O.notDoneReason.codes[0].system, '/')),
//        notDoneCode: O.notDoneReason.codes[0].code
//   return notDoneSystem + '|' + notDoneCode


//   define "BMI Assessment Exception Banner Text":
//     if exists "Medical Reason Or Patient Reason For Not Performing BMI Exam"
//       then 'BMI Assessment Exception: ' +  "BMI Not Done Category" + ' - ' + "BMI Not Done Reason Display"
//     else null
// End of Experimental Section BMI Not Done Banner 

// Begin Experimental Section BMI Follow-Up Not Done Banner
//   define "BMI Follow-Up Not Done Resources":
//   First("Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI")

//   define "BMI Follow-Up Not Done Category":
//     if exists "Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI" 
//       then 'Medical Reason' // as of the 2026 eCQM version, "Patient refused" is not implemented
//     else null

// define "BMI Follow-Up Not Done Reason Display": 
//   if "BMI Follow-Up Not Done Resources" is ServiceNotRequested
//     // then (First("BMI Follow-Up Not Done Resources".extension E
//     //   where E.url = 'http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-reasonRefused').value as System.Concept).codes[0].display
//     then "BMI Follow-Up Not Done Resources".reasonRefused.codes[0].display
//   else if "BMI Follow-Up Not Done Resources" is MedicationNotRequested
//     then "BMI Follow-Up Not Done Resources".reasonCode.codes[0].display
//   else null

// define "BMI Follow-Up Exception Banner Text":
//   if exists "Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI"
//     then 'BMI Follow-Up Exception: ' + "BMI Follow-Up Not Done Category" + ' - ' + "BMI Follow-Up Not Done Reason Display"
//   else null

// next iteration
define "Follow Up Not Done":
  "Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI" res
    let
      notDoneReason: 
        if res is ServiceNotRequested then res.reasonRefused.codes[0]
        else if res is MedicationNotRequested then res.reasonCode.codes[0]
        else null,
      reasonCategory: 
            if notDoneReason in "Medical Reason"
              then 'Medical Reason'
            else if notDoneReason in "Patient Declined"
         then 'Patient Reason'
        else null,
      reasonSystem: 
        Last(Split(notDoneReason.system, '/')),
      reasonSystemCode: 
        reasonSystem + '|' + notDoneReason.code,
      reasonDisplay: notDoneReason.display
    return Tuple {
      category: reasonCategory,
      bannerCode: reasonSystemCode, 
      display: reasonDisplay,
      bannerText: 'Follow Up Exception, ' + reasonCategory + ': ' + reasonDisplay
    }
    // return notDoneReason  // as System.Concept

// End Experimental Section BMI Follow-Up Not Done Banner

define "Not Done Exceptions":
  "Assessment Not Done" union "Follow Up Not Done"

// define "Denominator Exceptions Banner Text":
//   Coalesce("BMI Assessment Exception Banner Text", "BMI Follow-Up Exception Banner Text")

// define "Medical Reason Or Patient Reason For Not Performing BMI Exam Display":
//   (First(First("Medical Reason Or Patient Reason For Not Performing BMI Exam").extension).value as System.Concept).codes[0].display

define "Low BMI Interventions Ordered":
  ( ( [ServiceRequest: "Follow Up for Below Normal BMI"]
    union [ServiceRequest: "Referrals Where Weight Assessment May Occur"]
      union [MedicationRequest: "Medications for Below Normal BMI"] ) LowInterventionsOrdered
      where LowInterventionsOrdered.reasonCode in "Underweight"
        or ( exists [ConditionProblemsHealthConcerns: "Underweight"] UnderweightDiagnosis
            where ( UnderweightDiagnosis.isProblemListItem ( )
                or UnderweightDiagnosis.isHealthConcern ( )
            )
              and UnderweightDiagnosis.isActive ( )
              and UnderweightDiagnosis.prevalenceInterval ( ) starts before or on day of LowInterventionsOrdered.authoredOn
        )
  )

define "Low BMI Interventions Performed":
  ( [Procedure: "Follow Up for Below Normal BMI"] LowInterventionsPerformed
      where LowInterventionsPerformed.reasonCode in "Underweight"
        or ( exists [ConditionProblemsHealthConcerns: "Underweight"] UnderweightDiagnosis
            where ( UnderweightDiagnosis.isProblemListItem ( )
                or UnderweightDiagnosis.isHealthConcern ( )
            )
              and UnderweightDiagnosis.isActive ( )
              and UnderweightDiagnosis.prevalenceInterval ( ) starts before or on day of start of LowInterventionsPerformed.performed.toInterval ( )
              and not ( UnderweightDiagnosis.prevalenceInterval ( ) ends before day of start of LowInterventionsPerformed.performed.toInterval ( ) )
        )
  )

define "Low BMI And Follow Up Provided":
  ( "Documented Low BMI During Measurement Period" LowBMI
      with ( "Low BMI Interventions Ordered"
        union "Low BMI Interventions Performed" ) LowBMIInterventions
        such that if "Real Time Mode" then
          Coalesce(LowBMIInterventions.performed.toInterval(), LowBMIInterventions.authoredOn.toInterval()) starts during day of "Current Period"
        else
          Coalesce(LowBMIInterventions.performed.toInterval(), LowBMIInterventions.authoredOn.toInterval()) starts during day of "Measurement Period"
  )

define "Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI":
  ( ( [ServiceNotRequested: "Referrals Where Weight Assessment May Occur"]
      union [ServiceNotRequested: "Follow Up for Above Normal BMI"]
      union [ServiceNotRequested: "Follow Up for Below Normal BMI"] ) NoBMIFollowUp
      with "Qualifying Encounter During Day Of Measurement Period" QualifyingEncounter
        such that NoBMIFollowUp.authoredOn same day as start of QualifyingEncounter.period
      where NoBMIFollowUp.status ~ 'completed'
        and NoBMIFollowUp.reasonRefused in "Medical Reason" // consider adding "Patient Declined" DH
  )
    union ( ( [MedicationNotRequested: "Medications for Above Normal BMI"]
        union [MedicationNotRequested: "Medications for Below Normal BMI"] ) NoBMIFollowUp
        with "Qualifying Encounter During Day Of Measurement Period" QualifyingEncounter
          such that NoBMIFollowUp.authoredOn same day as start of QualifyingEncounter.period
        where NoBMIFollowUp.status ~ 'completed'
          // TODO: https://oncprojectracking.healthit.gov/support/projects/MADIE/issues/MADIE-2124
          // Expecting 4 failures until this translator issue is incorporated into MADiE
          
          
          and NoBMIFollowUp.reasonCode in "Medical Reason"
    )

// define "Is Pregnant During Day Of Measurement Period":
//   ( [ConditionProblemsHealthConcerns: "Pregnancy or Other Related Diagnoses"] P
//     union [ConditionEncounterDiagnosis: "Pregnancy or Other Related Diagnoses"] E) PregnancyDiagnosis
//     with "Qualifying Encounter During Day Of Measurement Period" QualifyingEncounter
//       such that PregnancyDiagnosis.clinicalStatus ~ QICoreCommon."active"
//         and PregnancyDiagnosis.prevalenceInterval ( ) overlaps day of "Measurement Period"

define "Is Pregnant During Day Of Measurement Period":
  exists ( [ConditionProblemsHealthConcerns: "Pregnancy or Other Related Diagnoses"] PregnancyProblemDiagnosis
    with "Qualifying Encounter During Day Of Measurement Period" QualifyingEncounter
      such that PregnancyProblemDiagnosis.clinicalStatus ~ QICoreCommon."active"
        and if "Real Time Mode" then
          PregnancyProblemDiagnosis.prevalenceInterval() overlaps day of "Current Period"
        else
          PregnancyProblemDiagnosis.prevalenceInterval() overlaps day of "Measurement Period"
  )
  or exists ( [ConditionEncounterDiagnosis: "Pregnancy or Other Related Diagnoses"] PregnancyEncounterDiagnosis
    with "Qualifying Encounter During Day Of Measurement Period" QualifyingEncounter
      such that PregnancyEncounterDiagnosis.clinicalStatus ~ QICoreCommon."active"
        and if "Real Time Mode" then
          PregnancyEncounterDiagnosis.prevalenceInterval() overlaps day of "Current Period"
        else
          PregnancyEncounterDiagnosis.prevalenceInterval() overlaps day of "Measurement Period"
  )

define "Qualifying Encounter During Day Of Measurement Period":
  [Encounter: type in "Encounter to Evaluate BMI"] BMIEncounter
    where if "Real Time Mode" then
      BMIEncounter.period during day of "Current Period"
    else
      BMIEncounter.period during day of "Measurement Period"
      and BMIEncounter.class !~ "virtual"
      and BMIEncounter.status = 'finished'

define "SDE Ethnicity":
  SDE."SDE Ethnicity"

define "SDE Payer":
  SDE."SDE Payer"

define "SDE Race":
  SDE."SDE Race"

define "SDE Sex":
  SDE."SDE Sex"

// Experimental
define "eCQM Initial Population Exclusion Reason":
  if "Real Time Mode" then
    null
  else if AgeInYearsAt(date from start of "Measurement Period") < 18 then
    'Will not appear in quality measure score: Under 18 years old'
  else if not exists "Qualifying Encounter During Day Of Measurement Period" then
    'Will not appear in quality measure score: No qualifying encounters for BMI evaluation'
  else if Hospice."Has Hospice Services" then
    'Will not appear in quality measure score: Has Hospice Services'
  else if PalliativeCare."Has Palliative Care in the Measurement Period" then
    'Will not appear in quality measure score: Has Palliative Care'
  else if "Is Pregnant During Day Of Measurement Period" then
    'Will not appear in quality measure score: Pregnancy exclusion'
  else
    null  // Patient IS included in measure score

define "Patient Score":
  case
    when not "Included" then null
    when "Numerator" then 1
    else 0
  end

// Experimental
define "Patient Score is 0":
  if "Patient Score" = 0 then 'Document BMI and provide appropriate follow-up if needed' else false

// Experimental
define "All Goals Met":
  if "Patient Score" = 1 then 'All BMI Screening and Follow-up goals are met' else false

// Experimental 
define "Included":
  "Denominator" and 
    not "Denominator Exclusions" and 
    not "Denominator Exceptions"

// // Experimental
// define "High BMI And Follow Up Not Provided":
//   "Included" and
//   exists "Documented High BMI During Measurement Period" and
//   not exists "High BMI Interventions Ordered" // and performed

  define "High BMI And Follow Up Not Provided":
    "Included" and
    exists ( "Documented High BMI During Measurement Period" HighBMI
      without ( "High BMI Interventions Ordered"
        union "High BMI Interventions Performed" ) HighBMIInterventions
        such that if "Real Time Mode" then
          Coalesce(HighBMIInterventions.performed.toInterval(), HighBMIInterventions.authoredOn.toInterval()) starts during day of "Current Period"
        else
          Coalesce(HighBMIInterventions.performed.toInterval(), HighBMIInterventions.authoredOn.toInterval()) starts during day of "Measurement Period"
    )

// Experimental
define "High BMI Follow Up Banner":
  if ("Real Time Mode" and "High BMI And Follow Up Not Provided") then 
  'Action Required: Provide follow-up for high BMI. Consider counseling, pharmacotherapy or referral. Document intervention in patient record.'
  else null

// Experimental
define "Needs Screening":
  Included and 
  not exists "BMI During Measurement Period"

define "Needs Screening Banner":
  if "Needs Screening" then 'Action Needed: Assess BMI. Document BMI measurement in patient record. ' else null

// // Experimental
// define "Low BMI And Follow Up Not Provided":
//   "Included" and
//   exists "Documented Low BMI During Measurement Period" and
//   not exists "Low BMI Interventions Ordered" // and ...performed

define "Needs Encounter":
  Included and 
  not exists "Qualifying Encounter During Day Of Measurement Period"

define "Needs Encounter Banner":
  if "Needs Encounter" then 'Action Needed: Schedule Encounter.' else null

define "Low BMI And Follow Up Not Provided":
  "Included" and 
  exists ( "Documented Low BMI During Measurement Period" LowBMI
      without ( "Low BMI Interventions Ordered"
        union "Low BMI Interventions Performed" ) LowBMIInterventions
        such that if "Real Time Mode" then
          Coalesce(LowBMIInterventions.performed.toInterval(), LowBMIInterventions.authoredOn.toInterval()) starts during day of "Current Period"
        else
          Coalesce(LowBMIInterventions.performed.toInterval(), LowBMIInterventions.authoredOn.toInterval()) starts during day of "Measurement Period"
  )


// Experimental
define "Low BMI Follow Up Banner":
  if ("Real Time Mode" and "Low BMI And Follow Up Not Provided") then 
  'Action Required: Provide follow-up for low BMI. Consider counseling, pharmacotherapy or referral. Document intervention in patient record.'
  else null

// Experimental
define "Denominator Exception Banner":
  if "Denominator Exceptions" then
    'Clinical contraindication documented. Quality measure requirements do not apply to this patient.'
  else null