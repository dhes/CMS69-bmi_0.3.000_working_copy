By way of summary... qicore-notDoneReason occurs in six test cases. In two case these are *qicore-medicationnotrequested* profiles. The remaining four are *qicore-observationcancelled* profile. The patients are:

- qicore-medicationnotrequested
  - 08c4cc20-5ef6-4d61-976d-b2502dbc9a27
    - NoFollowUpPlanMedicalReasonMedicationForBelowNormalBMI DENEXCEPPass
      - medication shows in generic Medication Requests Card without indication of the notdone extension nor "doNotPerform": true
  - d03007f4-577d-4482-b0bd-3d3342b00698
    - NoFollowUpPlanMedicalReasonMedicationForAboveNormalBMI DENEXCEPPass
      - generic Denominator Exception Banner
      - medication shows in generic Medication Requests Card without indication of the notdone extension nor "doNotPerform": true

The route to qicore-medicationnotrequested is "Denominator Exceptions" > "Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI" > ( [MedicationNotRequested: "Medications for Above Normal BMI"] union [MedicationNotRequested: "Medications for Below Normal BMI"] ) where "Medications for Above Normal BMI" and "Medications for Below Normal BMI" are valuesets. 

We don't appear to have any test cases for the ServiceNotRequested case. Still, it would be nice to find a common pattern. For qicore-medicationnotrequested the negation extension is qicore-notDoneReason. For qicore-servicenotrequested the negation extension is qicore-doNotPerformReason. See below. 

- qicore-observationcancelled
  - 92cee7eb-4a32-4e82-9b81-60a0c4754a75
    - MedicalReasonNotPerformed DENEXCEPPass
      - detailed banner and accurate BMI status (Observation)
      - Oddly, patient has a ServiceRequest for dietary regimen even though no BMI was performed. 
  - d5a2b9f8-af1a-4d2a-affe-41d743a837e5
    - MedicalReasonNotPerformed DENEXCEPPass
      - detailed banner and accurate BMI status (Observation)
      - Oddly, patient has a ServiceRequest for dietary regimen even though no BMI was performed. 
  - aa02e077-625d-467e-ac69-04b3f6850ae0
    - MedicalReasonMedicationForAboveNormalBMI DENEXCEPPass
      - detailed banner and accurate BMI status (Observation)
      - Name is misleading. Patient has no BMI performed. Oddly, patient has an overweight medication ordered. 
  - bbadc209-08e3-43aa-bf52-4deaab479bac
    - MedicalReasonMedicationForAboveNormalBMI DENEXCEPPass
      - detailed banner and accurate BMI status (Observation)
      - Name is misleading. Patient has no BMI performed. Oddly, patient has an overweight medication ordered. 

Pathway for last two "Denominator Exceptions" > "Medical Reason Or Patient Reason For Not Performing BMI Exam" > NoBMI.notDoneReason in "Patient Declined" or NoBMI.notDoneReason in "Medical Reason" where "Patient Declined" and "Medical Reason" are valuesets. 

After looking down to the bottom of the "Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI" pathway we initially though that there were no ServiceRequest test cases. But we now know that for qicore-servicenotrequested the negation extension is qicore-doNotPerformReason. So now we have eight more test cases. Yeah!

 - 5d920c1a-cc63-4f1c-aeff-6e15227ad641
   - MedicalReasonNoFollowupPlanHighBMI DENEXCEPPass
 - 6e0063dc-7163-4744-bfb4-1a0bee7f7fa0
   - ElevatedDeclineFU DENEXCEPPass
 - 79037ea3-c83c-4862-8f13-83ebddecca69
   - MedicalReasonNoReferralHighBMI DENEXCEPPass
 - 92cee7eb-4a32-4e82-9b81-60a0c4754a75
   - MedicalReasonNotPerformed DENEXCEPPass
 - ab9a89a2-8ca9-44d6-9cfc-389b0ccb78d7
   - MedicalReasonNoReferralForLowBMI DENEXCEPPass
 - b963dbb9-adb4-4831-83b9-bc1ccfc394ee
   - MedicalReasonFollowupPlanLowBMI DENEXCEPPass
 - db66690b-01a3-4981-899b-4d0b93f7b0ab
   - HTN130DeclinedNonPharm DENEXCEPPass
 - efa1b189-c22c-43fb-a4b8-ac401607a006
   - NotRequestedReferralForHighWeight DENEXCEPPass
  
All of these are present follow the same pattern. 
 - Generic Denominator Exception Banner
 - ServiceRequest appears in general Service Requests card, appropriately labelled as *not done*

The route to qicore-servicenotrequested is "Denominator Exceptions" > "Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI" > ( [ServiceNotRequested: "Referrals Where Weight Assessment May Occur"] union [ServiceNotRequested: "Follow Up for Above Normal BMI"] union [ServiceNotRequested: "Follow Up for Below Normal BMI"] ) where all three operands are valuesets. 

Now please note that the logic for "Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI" filters by NoBMIFollowUp.reasonRefused in "Medical Reason". Some qicore-servicenotrequested have a reasonRefused extension, some have a different extension (qicore-doNotPerformReason), and some have both. So not all of the ServiceNotRequested pass the Denominator Exceptions criteria! Only five pass. As of now the draft of "BMI Follow-Up Not Done Reason Display" correctly selects those patients. 

```
define A: // draft of "BMI Follow-Up Not Done Reason Display"
  if "BMI Follow-Up Not Done Resources" is ServiceNotRequested
    then (First("BMI Follow-Up Not Done Resources".extension E
      where E.url = 'http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-reasonRefused').value as System.Concept).codes[0].display
    else null
```

How to pull out and parse all of these *medicationnotrequested* and *ServiceNotRequested* Resources with a single algorithm? Would it be possible to fold in tha already-working "Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI". "Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI" at present only includes "Medical Reasons" but we should probably anticipate possiblity that "Patient Declines" might be added later. Let's begin by creating a fresh new batch of CQL that follows the same pattern we used on *no BMI*, and see if it diverges. 

OOPS. I missed two of the qicore-medicationnotrequested profiled MedicationRequest resources because I was searching for the notDoneReason extension instead of the qicore-medicationnotrequested. , notDoneReason is actually ignored by the CQL filter. Here are all of the qicore-medicationnotrequested cases. 

- 08c4cc20-5ef6-4d61-976d-b2502dbc9a27
- a6ea66e6-c68e-4701-90a1-9859f179421f
- bbadc209-08e3-43aa-bf52-4deaab479bac
- d03007f4-577d-4482-b0bd-3d3342b00698

08c4cc20-5ef6-4d61-976d-b2502dbc9a27 and bbadc209-08e3-43aa-bf52-4deaab479bac are discussed above. One of these returns a reasonCode of "Allergy to drug (finding)"; the other three "Procedure contraindicated (situation)". "Procedure contraindicated (situation)" is not very satisfying. It seems tautological. "This medication is contraindicated because it's contraindicated". This also raises a question about design patterns. MedicationRequest.reasonCode is intended to mean the reason for prescribing the medication. But here it is used as a reason for not prescribing the medication. Seems like it should follow the ServiceNotRequest example and use an extension instead. IMHO. 