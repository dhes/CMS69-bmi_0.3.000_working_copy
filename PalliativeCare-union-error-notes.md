# addressing PalliativeCare union error

## this PalliativeCare Clause

```([ConditionProblemsHealthConcerns: "Palliative Care Diagnosis"])
    union ([ConditionEncounterDiagnosis: "Palliative Care Diagnosis"])
```

## this validation error
```
*FAILURE*: 2 errors, 5 warnings, 1 notes
  Error @ Condition.category[0].coding[1].display (line 20, col6): Wrong Display Name 'Diagnosis' for http://snomed.info/sct#441874000. Valid display is one of 2 choices: 'Seen by palliative care service' (en) or 'Seen by palliative care service (finding)' (en) (for the language(s) 'en')
  Error @ Condition (line 1, col2): Slice 'Condition.category:us-core': a matching slice is required, but not found (from http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-condition-problems-health-concerns|6.0.0). Note that other slices are allowed in addition to this required slice
  Information @ Condition.category[0] (line 20, col6): This element does not match any known slice defined in the profile http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-condition-problems-health-concerns|6.0.0 (this may not be a problem, but you should check that it's not intended to match a slice)
  Warning @ Condition.category[0] (line 20, col6): None of the codings provided are in the value set 'Condition Category Codes' (http://hl7.org/fhir/ValueSet/condition-category|4.0.1), and a coding should come from this value set unless it has no suitable code (note that the validator cannot judge what is suitable) (codes = http://terminology.hl7.org/CodeSystem/condition-category#problem-list-item, http://snomed.info/sct#441874000)
  Warning @ Condition.code (line 35, col4): None of the codings provided are in the value set 'US Core Condition Codes' (http://hl7.org/fhir/us/core/ValueSet/us-core-condition-code|6.1.0), and a coding should come from this value set unless it has no suitable code (note that the validator cannot judge what is suitable) (codes = http://snomed.info/sct#441874000)
  Warning @ Condition.code.coding[0].system (line 35, col4): A definition for CodeSystem 'http://snomed.info/sct' version '2022-03' could not be found, so the code cannot be validated. Valid versions: [http://snomed.info/sct/11000146104/version/20240930,http://snomed.info/sct/11000172109/version/20231115,http://snomed.info/sct/2011000195101/version/20230607,http://snomed.info/sct/20611000087101/version/20220930,http://snomed.info/sct/32506021000036107/version/20230731,http://snomed.info/sct/45991000052106/version/20220531,http://snomed.info/sct/45991000052106/version/20231130,http://snomed.info/sct/554471000005108/version/20250331,http://snomed.info/sct/731000124108/version/20250301,http://snomed.info/sct/827022005/version/20241216,http://snomed.info/sct/83821000000107/version/20230412,http://snomed.info/sct/900000000000207008/version/20240201,http://snomed.info/sct/900000000000207008/version/20240801,http://snomed.info/sct/900000000000207008/version/20250201]
  Warning @ Condition.code (line 35, col4): Unable to check whether the code is in the value set 'http://hl7.org/fhir/us/core/ValueSet/us-core-condition-code|6.1.0' because the code system http://snomed.info/sct|2022-03 was not found
  Warning @ Condition (line 1, col2): Constraint failed: dom-6: 'A resource should have narrative for robust management' (defined in http://hl7.org/fhir/StructureDefinition/DomainResource) (Best Practice Recommendation)
```
on patient *5d48c* with encounter *28c0b633-0691-4a48-8349-ab80e2f438d1* that has this .catetory element
```
  "category": [
    {
      "coding": [
        {
          "system": "http://terminology.hl7.org/CodeSystem/condition-category",
          "code": "problem-list-item",
          "display": "Problem List Item"
        },
        {
          "system": "http://snomed.info/sct",
          "code": "441874000",
          "display": "Diagnosis"
        }
      ]
    }
  ]
```
Previously we noted apparent failure of the CQL to process this properly, apparently failing silently, presumably due to the union always returning null, possible to the way it is handling the choice list `list<choice<QICore.ConditionProblemsHealthConcerns,QICore.ConditionEncounterDiagnosis>>`. We implemented a 'fix' in v1.15.001 which split that statement into two 'exists' which returned expected results.

Since that time we discovered that our application.yaml was not configured appropriately for MADiE cases. We had
```
hapi:fhir:cr:cql:data:profile_mode:OFF
```
where we needed
```
hapi:fhir:cr:cql:data:profile_mode:ENFORCED
```
Now the question arises whether the *profile_mode setting may have interfere with processing of the *list<choice>* union. 

This looks even more important when we learn that the Encounter.category element is failing validation tests. 

These tests will be run on a version of the server with PalliatveCare version 1.15.000 running. 

### Trial 1 - fix the Condition.category[0].coding[1].display error

These versions will be saved in `input/test-resources-experimental/5d4cb-condition-union/trial-1.json`. See that folder for the full Condition resources. In this trial we replace "Diagnosis" with "Seen by palliative care service (finding)". As in every other experimental case (from now on...) all prior resources with hard-coded ids are expunged. See ThunderClient/maintenance/experimental Encounters/patient 5d4cb for example

#### Result

Fails on 
```
Denominator Exclusion = 1
MeasureScore is Absent
```
### Trial 2 - Slice 'Condition.category:us-core': a matching slice is required, but not found

This Error looks more important, but there could be more than one cause. The .category element in question (to repeat) is
```
      "category": [ {
        "coding": [ {
          "system": "http://terminology.hl7.org/CodeSystem/condition-category",
          "code": "problem-list-item",
          "display": "Problem List Item"
        }, {
          "system": "http://snomed.info/sct",
          "code": "441874000",
          "display": "Diagnosis"
        } ]
      } ]
```
so it *has* a .coding element that *looks like* it should conform, but the validator definitely does not like it. It might be helpful to step back a bit on this resource. It also has a .code element of 
```
      "code": {
        "coding": [ {
          "system": "http://snomed.info/sct",
          "version": "2022-03",
          "code": "441874000",
          "display": "Seen by palliative care service (finding)",
          "userSelected": true
        } ]
      }
```
which replicates the coding[1] element of the .category element. So it almost looks like somebody made a cut-and-paste error. So we'll try removing the second .category.coding element entire. 
```

```