Having established that CMS69-bmi_0.3.000 test cases do not include any cases where
- 'denominator-exclusion' = 1 AND
- 'denominator-exception'    = 1
and that the fqm code in MeasureReportBuilder.ts may not be capable of robustly handling that case, we endeavor to create a new test case bundle to test that assumption. This bundle will contain clinical information that satisfies 'denominator-exclusion' = 1 AND 'denominator-except' = 1 and then run it through fqm and HAPI see what happens. 

I'll be using just the first 8 characters of patient ids in this process because they are more manageable and in this Measure are unique.  Consider case 097cbc7a which has 'denominator-exclusion' = 1 and case c1df0273 which has 'denominator-exception' = 1. The new case id will be 1627be3a-9ca2-4829-b0ec-9a5559617ab8 or 1627be3a. Both cases are in the initial-population and have numerator = 0. 