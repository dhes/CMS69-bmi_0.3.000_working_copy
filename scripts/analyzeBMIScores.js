#!/usr/bin/env node

// scripts/analyzeBMIScores.js
const fs = require('fs').promises;
const path = require('path');
const dotenv = require('dotenv');

// Load environment variables from parent directory .env file
dotenv.config({ path: path.join(__dirname, '../.env') });

// Use dynamic import for fetch since we're in CommonJS
let fetch;
(async () => {
  fetch = (await import('node-fetch')).default;
})();

class BMIPatientScoreAnalyzer {
  constructor(fhirServerUrl) {
    this.fhirServerUrl = fhirServerUrl.endsWith('/') ? fhirServerUrl.slice(0, -1) : fhirServerUrl;
  }

  /**
   * Get all patient IDs from the test cases directory
   */
  async getPatientIds(testCasesDir) {
    try {
      const entries = await fs.readdir(testCasesDir, { withFileTypes: true });
      return entries
        .filter(entry => entry.isDirectory())
        .map(entry => entry.name)
        .sort();
    } catch (error) {
      console.error(`Error reading test cases directory: ${error}`);
      throw error;
    }
  }

  /**
   * Evaluate BMI measure for a single patient
   */
  async evaluatePatient(patientId) {
    const requestBody = {
      resourceType: "Parameters",
      parameter: [
        {
          name: "subject",
          valueString: `Patient/${patientId}`
        },
        {
          name: "parameters",
          resource: {
            resourceType: "Parameters",
            parameter: [
              {
                name: "Measurement Period",
                valuePeriod: {
                  start: "1900-01-01T00:00:00-10:00",
                  end: "1900-12-31T23:59:00-10:00"
                }
              }
            ]
          }
        }
      ]
    };

    try {
      const response = await fetch(
        `${this.fhirServerUrl}/Library/CMS69FHIRPCSBMIScreenAndFollowUp/$evaluate`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(requestBody)
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const result = await response.json();
      
      return this.extractPatientScore(patientId, result);
    } catch (error) {
      console.error(`Error evaluating patient ${patientId}:`, error);
      return {
        patientId,
        patientScore: null,
        error: error.message || 'Unknown error'
      };
    }
  }

  /**
   * Extract Patient Score and related metrics from evaluation result
   */
  extractPatientScore(patientId, result) {
    const parameters = result.parameter || [];
    
    let patientScore = null;
    let denominatorExceptions = undefined;
    let denominatorExclusions = undefined;
    let numerator = undefined;
    let denominator = undefined;

    parameters.forEach(param => {
      switch (param.name) {
        case 'Patient Score':
          patientScore = param.valueInteger;
          break;
        case 'Denominator Exceptions':
          denominatorExceptions = param.valueBoolean;
          break;
        case 'Denominator Exclusions':
          denominatorExclusions = param.valueBoolean;
          break;
        case 'Numerator':
          numerator = param.valueBoolean;
          break;
        case 'Denominator':
          denominator = param.valueBoolean;
          break;
      }
    });

    return {
      patientId,
      patientScore,
      denominatorExceptions,
      denominatorExclusions,
      numerator,
      denominator
    };
  }

  /**
   * Analyze all patients and generate CSV report
   */
  async analyzeAllPatients(testCasesDir, outputPath = './bmi-patient-scores.csv') {
    console.log('🔍 Discovering patient IDs...');
    const patientIds = await this.getPatientIds(testCasesDir);
    console.log(`📋 Found ${patientIds.length} patients to analyze`);

    const results = [];
    let completed = 0;

    for (const patientId of patientIds) {
      console.log(`⚖️ Evaluating patient ${patientId} (${completed + 1}/${patientIds.length})`);
      
      const result = await this.evaluatePatient(patientId);
      results.push(result);
      completed++;

      // Add small delay to avoid overwhelming the server
      if (completed < patientIds.length) {
        await new Promise(resolve => setTimeout(resolve, 100));
      }
    }

    console.log('📊 Generating CSV report...');
    await this.generateCSVReport(results, outputPath);
    
    console.log(`✅ Analysis complete! Results saved to: ${outputPath}`);
    return results;
  }

  /**
   * Generate CSV report from results
   */
  async generateCSVReport(results, outputPath) {
    const headers = [
      'Patient ID',
      'Patient Score', 
      'Denominator',
      'Numerator',
      'Denominator Exclusions',
      'Denominator Exceptions',
      'Error'
    ];

    const csvRows = [headers.join(',')];

    results.forEach(result => {
      const row = [
        result.patientId,
        result.patientScore?.toString() || '',
        result.denominator?.toString() || '',
        result.numerator?.toString() || '',
        result.denominatorExclusions?.toString() || '',
        result.denominatorExceptions?.toString() || '',
        result.error || ''
      ];
      csvRows.push(row.join(','));
    });

    const csvContent = csvRows.join('\n');
    await fs.writeFile(outputPath, csvContent, 'utf8');
  }

  /**
   * Generate summary statistics
   */
  generateSummary(results) {
    const total = results.length;
    const successful = results.filter(r => r.error === undefined).length;
    const errors = total - successful;
    
    const score0 = results.filter(r => r.patientScore === 0).length;
    const score1 = results.filter(r => r.patientScore === 1).length;
    const scoreNull = results.filter(r => r.patientScore === null).length;

    const exceptions = results.filter(r => r.denominatorExceptions === true).length;
    const exclusions = results.filter(r => r.denominatorExclusions === true).length;

    console.log('\n📈 SUMMARY STATISTICS:');
    console.log(`Total Patients: ${total}`);
    console.log(`Successful Evaluations: ${successful}`);
    console.log(`Errors: ${errors}`);
    console.log('');
    console.log('Patient Scores:');
    console.log(`  Score 0 (No Intervention): ${score0}`);
    console.log(`  Score 1 (Intervention Documented): ${score1}`);
    console.log(`  Score Null/Error: ${scoreNull}`);
    console.log('');
    console.log('Measure Population:');
    console.log(`  Denominator Exceptions: ${exceptions}`);
    console.log(`  Denominator Exclusions: ${exclusions}`);
    
    if (score0 > 0) {
      console.log('\n🎯 ALIGNMENT OPPORTUNITIES:');
      console.log(`${score0} patients scored 0 - potential for improvement through alignment guide`);
    }
  }
}

// Main execution
async function runBMIAnalysis() {
  // Import fetch if not already done
  if (!fetch) {
    fetch = (await import('node-fetch')).default;
  }

  // Configuration - load from .env file
  const fhirServerUrl = process.env.FHIR_SERVER_URL;
  
  if (!fhirServerUrl) {
    console.error('❌ FHIR_SERVER_URL not found in .env file');
    console.error('Please check the .env file at:', path.join(__dirname, '../.env'));
    process.exit(1);
  }
  const testCasesDir = path.join(__dirname, '../input/tests/measure/CMS69FHIRPCSBMIScreenAndFollowUp');
  const outputPath = path.join(__dirname, '../bmi-patient-scores.csv');

  console.log('🚀 Starting BMI Patient Score Analysis...');
  console.log(`📁 Test Cases Directory: ${testCasesDir}`);
  console.log(`🌐 FHIR Server: ${fhirServerUrl}`);
  console.log(`📄 Output File: ${outputPath}`);
  console.log('');

  const analyzer = new BMIPatientScoreAnalyzer(fhirServerUrl);
  
  try {
    const results = await analyzer.analyzeAllPatients(testCasesDir, outputPath);
    analyzer.generateSummary(results);
    console.log('🎉 Analysis completed successfully!');
  } catch (error) {
    console.error('💥 Analysis failed:', error);
    process.exit(1);
  }
}

// Run the analysis
runBMIAnalysis().catch(console.error);