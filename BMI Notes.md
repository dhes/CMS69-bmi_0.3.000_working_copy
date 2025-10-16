SNOMED|183945002 Procedure declined for religious reason (situation) miention in one patient. 

20261016 Current thoughts

Regarding the BMI banner for patient 6e006 (and one other). The banner produces a generic 'Clinical contraindication documented. Quality measure requirements do not apply to this patient.' whether the exclusion is due to a 'contraindication' ("Medical Reason") or a 'refusal' ("Patient Reason"). We need to refine this in CQL. In principal you could expose the Reason in the banner by exposing the 'code', which is available in the returned $evaluate parameter; or you could just break it down to 'contraindicated' or 'declined'. 

See patient comment.md for more detail.