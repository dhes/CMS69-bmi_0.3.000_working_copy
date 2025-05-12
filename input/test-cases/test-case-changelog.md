# Test Case Changelog: CMS69-bmi_0.3.000

## 2025-04-19

### Patient ID: 260e1fc8-227f-4c16-bfc6-22625380a12c
**Issue:** Observation.valueQuantity is missing `system` and `code` fields  
**Details:**  
```json
"valueQuantity": {
  "value": 30,
  "unit": "kg/m2"
}
```
**Proposed edit:**
```json
"valueQuantity": {
  "value": 30,
  "unit": "kg/m2",
  "system": "http://unitsofmeasure.org",
  "code": "kg/m2"
}
```

### Patient ID: 57858042-c2aa-49f4-b401-1f1fd9ab289a
**Issue:** Observation.valueQuantity is missing `system` and `code` fields  
**Details:**  
```json
"valueQuantity": {
  "value": 25.0,
  "unit": "kg/m2"
}
```
**Proposed edit:**
```json
"valueQuantity": {
  "value": 25.0,
  "unit": "kg/m2",
  "system": "http://unitsofmeasure.org",
  "code": "kg/m2"
}
```

### Patient ID: 6d26d364-a06c-49e6-84df-280ec6b7a8a3
**Issue:** Observation.valueQuantity is missing `system` and `code` fields  
**Details:**  
```json
"valueQuantity": {
  "value": 30.0,
  "unit": "kg/m2"
}
```
**Proposed edit:**
```json
"valueQuantity": {
  "value": 30.0,
  "unit": "kg/m2",
  "system": "http://unitsofmeasure.org",
  "code": "kg/m2"
}
```

### Patient ID: 736b5472-4a6f-4278-80d3-373d1c78c4c5
**Issue:** Observation.valueQuantity is missing `system` and `code` fields  
**Details:**  
```json
"valueQuantity": {
  "value": 28.0,
  "unit": "kg/m2"
}
```
**Proposed edit:**
```json
"valueQuantity": {
  "value": 28.0,
  "unit": "kg/m2",
  "system": "http://unitsofmeasure.org",
  "code": "kg/m2"
}
```
Similar pattern for patients:
- 7ac9722f-8763-4380-a741-53ee4bb9881
- 88a2b45a-7866-445a-8242-91ec0ebb7646
- b98fcec4-23a5-41bd-82d8-bad2f50ffc9c
- c1df0273-aad8-41a8-859c-edd204bb4f16

### Patient ID: 659f9c7b-5c1c-475f-bfcb-77c246fa7a28
**Issue:** Observation contains redundant valueBoolean": "true"
**Proposed edit:** Remove that line. 

### Patient ID: 8c89947a-a52b-4a41-86a8-166b0560355b
**Issues:** 
- Observation contains redundant valueBoolean": "true"
- Observation is status: "amended" which does not meet  QICoreObservationNotDone profile
**Proposed edit:** 
- Remove redundant valueBoolean": "true"
- change "amended" to "cancelled"

### Patient ID: c1df0273-aad8-41a8-859c-edd204bb4f1
**Issues:**
- patient file name and description indicate that the patient has a low BMI, but the actual recorded BMI value is normal. 
**Proposed edit:** 
- set the BMI to 18.4 in the test case
**Notes:*
This patient file name and test-case description are 'CMS69FHIR-v0.3.000-DENEXCEPPass-MedicalReasonNoReferralForLowBMI.json' and 'Enc first day of MP, BMI Low at 24.9, no referral where weight assessment might be performed.' In the test case MeasureReport the denominator exception =1 and the numerator is 0. Apparently the author is attempting to establish a denominator-exception based on "Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI". 

Rerunning fqm report against the corrected file results in counts that match result in expected values. 

### Patient ID: 6553adbf-2a30-4861-97e6-cca7d2274f01, a4a1ed63..., b98fcec4...
**Issues:**
- expected denominator-exception = 1; actual = 0
**Proposed edit:** 

**Notes**
This patient's file name is CMS69FHIR-v0.3.000-DENEXCEPPass-NoFollowUpPlanMedicalReasonMedicationForAboveNormalBMI and description is "Adult, Enc first 30 minutes of the first day of the MP, BMI result above normal, no f/u plan due to medical reason". The assigned BMI value is 25. High BMI in the cql is defined as "BMI.value >= 25 'kg/m2'", so the value in the test-case appears correct (testing an edge case). So the discrepancy may be from the "Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI" values. In the cql identifier "Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI", the section "union [MedicationNotRequested: "Medications for Below Normal BMI"] ) NoBMIFollowUp" there is a comment
```
          // TODO: https://oncprojectracking.healthit.gov/support/projects/MADIE/issues/MADIE-2124
          // Expecting 4 failures until this translator issue is incorporated into MADiE
```
which may account for the discrepancy. 

That completes the first round of discrepancy analysis. 
