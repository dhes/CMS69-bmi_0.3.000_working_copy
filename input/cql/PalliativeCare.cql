library PalliativeCare version '1.15.002'

using QICore version '6.0.0'

include FHIRHelpers version '4.4.000' called FHIRHelpers
include QICoreCommon version '4.0.000' called QICoreCommon
include Status version '1.13.000' called Status

codesystem "LOINC": 'http://loinc.org'

valueset "Palliative Care Encounter": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.101.12.1090'
valueset "Palliative Care Intervention": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.198.12.1135'
valueset "Palliative Care Diagnosis": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.1167'

code "Functional Assessment of Chronic Illness Therapy - Palliative Care Questionnaire (FACIT-Pal)": '71007-9' from "LOINC" display 'Functional Assessment of Chronic Illness Therapy - Palliative Care Questionnaire (FACIT-Pal)'

parameter "Measurement Period" Interval<DateTime> // default Interval[@2026-01-01T00:00:00.0, @2026-12-31T23:59:59.999]

context Patient

define "Real Time Mode":
  Coalesce(year from start of "Measurement Period" = 1900, false)

define "Palliative Care Assessment":
  (([ObservationScreeningAssessment: "Functional Assessment of Chronic Illness Therapy - Palliative Care Questionnaire (FACIT-Pal)"]).isAssessmentPerformed()) PalliativeAssessment
    where if "Real Time Mode" then
        true
      else PalliativeAssessment.effective.toInterval() overlaps day of "Measurement Period"

define "Palliative Care Problem Diagnosis":
  ([ConditionProblemsHealthConcerns: "Palliative Care Diagnosis"]) PalliativeProblemDiagnosis
    where if "Real Time Mode" then
        true
      else PalliativeProblemDiagnosis.prevalenceInterval() overlaps day of "Measurement Period"

define "Palliative Care Encounter Diagnosis":
  ([ConditionEncounterDiagnosis: "Palliative Care Diagnosis"]) PalliativeEncounterDiagnosis
    where if "Real Time Mode" then
        true
      else PalliativeEncounterDiagnosis.prevalenceInterval() overlaps day of "Measurement Period"

define "Palliative Care Encounters":
  (([Encounter: "Palliative Care Encounter"]).isEncounterPerformed()) PalliativeEncounter
    where if "Real Time Mode" then
        true
      else PalliativeEncounter.period.toInterval() overlaps day of "Measurement Period"

define "Palliative Care Interventions":
  (([Procedure: "Palliative Care Intervention"]).isInterventionPerformed()) PalliativeIntervention
    where if "Real Time Mode" then
        true
      else PalliativeIntervention.performed.toInterval() overlaps day of "Measurement Period"

define "Has Palliative Care in the Measurement Period":
  exists "Palliative Care Assessment"
    or exists "Palliative Care Problem Diagnosis"
    or exists "Palliative Care Encounter Diagnosis"
    or exists "Palliative Care Encounters"
    or exists "Palliative Care Interventions"