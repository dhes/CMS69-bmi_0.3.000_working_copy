{
  "resourceType": "Observation",
  "meta": {
    "profile": [
      "http://hl7.org/fhir/us/core/StructureDefinition/us-core-bmi"
    ]
  },
  "status": "final",
  "category": [
    {
      "coding": [
        {
          "system": "http://terminology.hl7.org/CodeSystem/observation-category",
          "code": "vital-signs",
          "display": "Vital Signs"
        }
      ]
    }
  ],
  "code": {
    "coding": [
      {
        "system": "http://loinc.org",
        "code": "39156-5",
        "display": "Body mass index (BMI) [Ratio]",
        "userSelected": true
      }
    ]
  },
  "subject": {
    "reference": "Patient/{patientId}"
  },
  "effectiveDateTime": "{dateTime}",
  "valueQuantity": {
    "value": {bmi},
    "unit": "kg/m2",
    "system": "http://unitsofmeasure.org",
    "code": "kg/m2"
  }
}