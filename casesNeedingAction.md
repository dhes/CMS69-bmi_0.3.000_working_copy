|family|given|ID|Needs?|Action|0 or null?|
|---|---|---|---|---|---|
|HighBMIAndConditionEndsBeforeInterventionPerformed|NUMERFail|2ba91529-b875-4f1a-ac6c-c23be1a32051|This is a technical (charting) deficiency. This patient has been weighed, has a BMI of 30 recorded, and has been counselled. The only problem is that the Condition resource has .abatementPeriod.end that is before the date of the counselling Procedure. Treatment was appropriate. The action should be to correct (probably delete) the abatementPeriod element. The second option would be to record a reason in the Procedure resource. It should cause the care to flip to 1, but still would leave a troublesome Condition.abatementInterval. This is an edge case that would require some fairly detailed logic to implement.|Correct (delete) Condition.abatementPeriod|0|
|Patient18DayOfEncounter|DENOMPass|393a06aa-0b3f-48ef-93c5-5daa57437969|This is a zero score case I missed the first time around. In spite of familyName description, patient is 21, so this becomes a 'no BMI' example like f65baba5. Same action.|Record BMI|0|
|HighBMIAndInterventionOrderedFollowUpConditionEndsB4InterventionOrder|NUMERFail|671be65d-db2a-42c1-8b8b-1c9062e54cc9|Patient is mis-named and the chart is miscoded (by design as an edge case, I suspect). Patient has a low BMI but is miscoded as high. Since the (appropriate) ServiceRequest has no .reason code, the also references the Condition. But that fails because the coded condition is high BMI. The fix is to correct the Condition code. This action prompt is moderately difficult to code.|Correct Condition.code|0|
|Patient18DayOfEncounter|DENOMPass|78749fe6-5f29-4c18-9d17-58cac067faf1|No visits in 2025. Incidentally 2026 Encounter is not possible in Real Time. There might be a cut and paste error because the patient is 21, not 18.|Record BMI|0|
|LowBMIAndInterventionOrderedFollowUpConditionEndsB4InterventionOrder|NUMERFail|9d4f40f0-bc27-4173-957f-718a08e8c123|Analagous to HighBMIAndConditionEndsBeforeInterventionPerformed but low BMI instances. Same suggested action.|Correct (delete) Condition.abatement|0|
|ObeseDxEndsBeforeIntervention|NUMERFail|a21cd712-baa6-4054-a9b0-204304a82ffe|ServiceRequest too old and also has no .reason, with BMI Condition prematurely abated|Correct (delete) Condition.abatement; High BMI follow up|0|
|LowBMIAndConditionEndsBeforeInterventionPerformed (1)|NUMERFail|ab71ff66-51b9-4ea0-965f-e1f304465f24||Correct (delete) Condition.abatement|0|
|Age18HasEnc|IPPPass|b0a1d689-7c26-4715-a5dc-6a0401be81c5||Record BMI|0|
|Patient18LastDayOfEncounter|DENOMPass|bc5688ae-6db7-4031-b29b-db81977db71f||Record BMI|0|
|LowBMIAndInterventionPerformedCondition|NUMERPass|c892a8e0-3ccf-41fa-ad88-40829d75673d|Underweight dx ended last day of prior year MP|Correct (delete) Condition.abatementPeriod|0|
|Patient18DayOfEncounter|DENOMPass|d06e3c1f-05d2-4ac7-b3ba-60e39d067201|This gets null score in MP mode.|Encounter with BMI|0|
|EncounterOneDayAfterMP|IPFail|f65baba5-c58d-4741-8c09-cae2c3f47373|Day one Encounter in Current Period but wrong type.|Encounter with BMI|0|
|VirtualEncounter|IPPFail|fa42b3d4-47c6-410a-8628-cc8b4b26cb0b|Virtual encounters are expressly excluded. I guess you can't measure a virtual weight. Action: have a visit.|Encounter with BMI|0|
|DischargeToHospiceFacilityAfterMP|DENEXFail|10dd8ab7-886b-4536-beae-9e3b426b18b9|DC to Hospice occurs in (hypothetical) future. As of the end of 2025 the patient has been weighed and received appropriate treatment. This case scores 1 for the MP 2025 and 0 in Real Time. In the real time scenarios this case is not possible.|none|null|
|DischargeToHospiceFacilityAfterMP|DENEXFail|20f7bf1a-d019-4563-a02d-2061c90beed0|This patient actually scores a 1 in realtime from 2025-01-01, until they are discharged to Hospice later in the year, which nulls the score for the 2025 MP. Practitioner did everything right, but no credit. The Measure Score would be a finer instrument if the P still got credit if the right thing was done before Hospice started! But no action to take here. |None|null|
|DischargeToHospiceFacilityAfterMP|DENEXFail|7744953d-92eb-4dd4-95ce-2b41c9e72c5|This is another case which is implausible in Real Time, because it contains a future (2026) Encounter. It is (oddly) labelled a DENEXFail even though the MP 2025 patient score is one. In other words, the Practitioner did everything right and will get credit for it. No action needed. |none|null|
|Patient17DayOfEncounter|IPPFail|aea52a37-e79c-4bc7-b78d-37f75c529743|too young...||null|



## Summary

|Action|Count|discriminator|
|---|---|---|
|Record BMI|4|"Needs Screening" and exists "Qualifying Encounter During Day Of Measurement Period"|
|Encounter and BMI|3|"Needs Screening" and not exists "Qualifying Encounter During Day Of Measurement Period"|
|Correct (delete) Condition.abatement|5||
|Correct Condition.code|1||

"Needs Screening" might be better named as "Needs BMI". Then you could add "Needs Encounter" so that |Encounter and BMI| might be selected by "Needs Screening" and "Needs BMI". BMI is not coupled to Encounter, that is to say a BMI recorded without a companion encounter will pass eCQM requirements. So in the |BMI| case a Practitioner could call in a patient just to measure BMI. However in the |Encounter and BMI| case it makes more sense to have a Encounter during which you measure BMI. The question is how much of this detail to lay out to the P in the prompts. 

Oops -- you also need patient who fail denominator due to absence of Encounter. Some of those may already have a BMI, in which case you only need an encounter. After checking, I see there are no test cases like that. 