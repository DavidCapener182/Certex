// Auto-generated AOO template library from Audit temps 1/2/3 sources.

export const aooFramework = {
  "sourceSequence": [
    {
      "order": 1,
      "title": "Regulatory framework, checklist design, and platform capabilities",
      "fileName": "Audit temps 1.md"
    },
    {
      "order": 2,
      "title": "Production-ready JSON templates and baseline question sets",
      "fileName": "Audit temps 2.md"
    },
    {
      "order": 3,
      "title": "Expanded JSON templates with fuller question banks",
      "fileName": "Audit temps 3.md"
    }
  ],
  "regulatoryFramework": [
    "Health and Safety at Work Act 1974 and Management Regulations 1999: identify hazards, assess risk, and control risk.",
    "Regulatory Reform (Fire Safety) Order 2005: responsible person must complete and maintain fire risk assessment records.",
    "LOLER 1998 and PUWER 1998: lifting and work equipment must be suitable, maintained, and periodically examined.",
    "Pressure Systems Safety Regulations 2000: written scheme of examination and scheduled pressure checks are required.",
    "COSHH 2002: hazardous substance risks and controls must be assessed and documented.",
    "Control of Asbestos Regulations 2012: asbestos register and management plan duties.",
    "GDPR and ICO storage limitation guidance: personal data retained only as long as justified."
  ],
  "keyAuditTypesFromSourceOne": [
    "Health and safety management audits",
    "Workplace and environment inspections",
    "Fire risk assessments",
    "LOLER and PUWER equipment inspections",
    "Scaffold and access inspections",
    "PSSR pressure system audits",
    "COSHH audits",
    "Asbestos management audits",
    "Legionella and water safety checks",
    "Additional inspections including electrical safety, gas safety, DSE, and sector specific checks"
  ],
  "checklistDesignRules": [
    "Support yes/no/na answers with weighted scoring and critical fail handling.",
    "Capture evidence per question including photos, comments, and documents.",
    "Require corrective actions with assignee and due date for non-compliance.",
    "Track records and retention periods by regime and GDPR policy."
  ],
  "platformCapabilities": [
    "Custom form builder with conditional show or hide logic.",
    "Mobile and offline data capture with deferred sync.",
    "Evidence capture including photos with metadata and optional signatures.",
    "Auto scoring and immediate issue assignment workflows.",
    "Dashboard and report export support for compliance evidence packs."
  ],
  "pwaValidationRules": [
    "Capture audit level geolocation and support geofence checks.",
    "Enforce required answers and required evidence before completion.",
    "Run conditional showIf rules for remediation questions.",
    "Allow offline capture and queued sync when connectivity returns.",
    "Auto create corrective actions when critical questions fail."
  ],
  "workflowStages": [
    "Start audit",
    "Answer checklist questions",
    "Evaluate critical failures",
    "Create corrective actions",
    "Score and determine pass or fail",
    "Close audit with evidence retained"
  ],
  "templateSchema": {
    "type": "object",
    "required": [
      "auditId",
      "templateId",
      "date",
      "questions"
    ],
    "properties": {
      "auditId": {
        "type": "string"
      },
      "templateId": {
        "type": "string"
      },
      "date": {
        "type": "string",
        "format": "date-time"
      },
      "auditor": {
        "type": "string"
      },
      "location": {
        "type": "object",
        "required": [
          "lat",
          "lon"
        ],
        "properties": {
          "lat": {
            "type": "number"
          },
          "lon": {
            "type": "number"
          },
          "name": {
            "type": "string"
          }
        }
      },
      "questions": {
        "type": "array",
        "items": {
          "type": "object",
          "required": [
            "id",
            "text",
            "type",
            "weight"
          ],
          "properties": {
            "id": {
              "type": "string"
            },
            "category": {
              "type": "string"
            },
            "text": {
              "type": "string"
            },
            "type": {
              "type": "string",
              "enum": [
                "boolean",
                "text",
                "select",
                "numeric"
              ]
            },
            "options": {
              "type": "object"
            },
            "weight": {
              "type": "number"
            },
            "critical": {
              "type": "boolean"
            },
            "required": {
              "type": "boolean"
            },
            "evidence": {
              "type": "object",
              "properties": {
                "photo": {
                  "type": "boolean"
                },
                "comment": {
                  "type": "boolean"
                },
                "signature": {
                  "type": "boolean"
                }
              }
            },
            "showIf": {
              "type": "string"
            }
          }
        }
      },
      "findings": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "questionId": {
              "type": "string"
            },
            "actionRequired": {
              "type": "boolean"
            },
            "description": {
              "type": "string"
            },
            "assignedTo": {
              "type": "string"
            },
            "priority": {
              "type": "string"
            }
          }
        }
      }
    }
  }
};

const aooTemplateCatalogBase = [
  {
    "templateId": "HSA",
    "name": "Health & Safety System Audit",
    "category": "HS",
    "regime": "HS",
    "scoringModel": "weighted_sections",
    "licenceModel": "multi_use",
    "passScore": 29,
    "maxScore": 36,
    "passPercent": 81,
    "criticalQuestionIds": [
      "HSA1",
      "HSA2",
      "HSA3",
      "HSA5",
      "HSA8"
    ],
    "retentionGuidance": "Risk assessments about 5 years, accident books 3 years, training logs 5 years, personal data under GDPR storage limitation.",
    "regulatoryAnchors": [
      "Health and Safety at Work Act 1974",
      "Management of Health and Safety at Work Regulations 1999"
    ],
    "autoActions": [
      {
        "questionId": "HSA2",
        "action": "Review all risk assessments",
        "assignee": "Safety Manager",
        "dueWithinDays": 30
      },
      {
        "questionId": "HSA5",
        "action": "Restore machinery inspection and maintenance schedule",
        "assignee": "Engineering Lead",
        "dueWithinDays": 14
      }
    ],
    "auditIdExample": "HSA-2026-07",
    "sourceCoverage": [
      1,
      2,
      3
    ],
    "source2Questions": [
      {
        "id": "HSA1",
        "category": "Policy & Management",
        "text": "Is there a current, signed Health & Safety policy displayed?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA2",
        "category": "Risk Assessment",
        "text": "Have all significant workplace risks been assessed and documented?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA3",
        "category": "Accidents",
        "text": "Is the accident book up to date and are reportable injuries (RIDDOR) recorded?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": false,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA4",
        "category": "Inspections",
        "text": "Are routine safety inspections (fire checks, machine guards, etc.) logged weekly?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA5",
        "category": "Training",
        "text": "Have all staff received induction and job-specific safety training, and are records available?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA6",
        "category": "Protective Measures",
        "text": "Is appropriate PPE (e.g. hard hats, gloves) provided and used where required?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA7",
        "category": "Legislation & Permits",
        "text": "Are required permits (e.g. Hot Work Permit) issued where applicable?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA8",
        "category": "Records",
        "text": "Are H&S records (assessments, inspections, training) retained per policy?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA9",
        "category": "Finding",
        "text": "If any non-compliance was found above, list corrective actions taken:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "HSA1 == 0 || HSA2 == 0 || HSA5 == 0 || HSA6 == 0"
      }
    ],
    "source3Questions": [
      {
        "id": "HSA1",
        "category": "Policy",
        "text": "Is a current H&S policy signed by management and displayed?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA2",
        "category": "Risk",
        "text": "Have risk assessments been done for all significant hazards?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA3",
        "category": "Training",
        "text": "Is staff training (induction, equipment use) documented and up to date?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA4",
        "category": "Accidents",
        "text": "Is the accident book up to date and are RIDDOR reports logged?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA5",
        "category": "Equipment",
        "text": "Is all machinery inspected and maintained (maintenance log current)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA6",
        "category": "Hazards",
        "text": "Are hazardous substances assessed (COSHH) and controls implemented?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA7",
        "category": "First Aid",
        "text": "Are sufficient first aiders available and records kept?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA8",
        "category": "Emergency",
        "text": "Are emergency exits, alarms, and fire instructions in place?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA9",
        "category": "Records",
        "text": "Are H&S records (risk assessments, permits) retained per policy?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA10",
        "category": "Review",
        "text": "Have risk assessments and policies been reviewed in the last 12 months?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA11",
        "category": "Manual Handling",
        "text": "Are manual handling risk assessments documented where heavy lifting occurs?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA12",
        "category": "Finding",
        "text": "If any critical item is No, describe immediate actions taken:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "HSA1 == 0 || HSA2 == 0 || HSA3 == 0 || HSA5 == 0 || HSA8 == 0"
      }
    ],
    "questions": [
      {
        "id": "HSA1",
        "category": "Policy",
        "text": "Is a current H&S policy signed by management and displayed?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA2",
        "category": "Risk",
        "text": "Have risk assessments been done for all significant hazards?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA3",
        "category": "Training",
        "text": "Is staff training (induction, equipment use) documented and up to date?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA4",
        "category": "Accidents",
        "text": "Is the accident book up to date and are RIDDOR reports logged?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA5",
        "category": "Equipment",
        "text": "Is all machinery inspected and maintained (maintenance log current)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA6",
        "category": "Hazards",
        "text": "Are hazardous substances assessed (COSHH) and controls implemented?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA7",
        "category": "First Aid",
        "text": "Are sufficient first aiders available and records kept?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA8",
        "category": "Emergency",
        "text": "Are emergency exits, alarms, and fire instructions in place?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA9",
        "category": "Records",
        "text": "Are H&S records (risk assessments, permits) retained per policy?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA10",
        "category": "Review",
        "text": "Have risk assessments and policies been reviewed in the last 12 months?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA11",
        "category": "Manual Handling",
        "text": "Are manual handling risk assessments documented where heavy lifting occurs?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "HSA12",
        "category": "Finding",
        "text": "If any critical item is No, describe immediate actions taken:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "HSA1 == 0 || HSA2 == 0 || HSA3 == 0 || HSA5 == 0 || HSA8 == 0"
      }
    ]
  },
  {
    "templateId": "FRA",
    "name": "Fire Risk Assessment",
    "category": "FRA",
    "regime": "FRA",
    "scoringModel": "risk_aggregate",
    "licenceModel": "multi_use",
    "passScore": 21,
    "maxScore": 26,
    "passPercent": 81,
    "criticalQuestionIds": [
      "FRA1",
      "FRA2",
      "FRA3"
    ],
    "retentionGuidance": "Keep each fire risk assessment until superseded plus 6 years, drill and training logs about 3 to 5 years.",
    "regulatoryAnchors": [
      "Regulatory Reform (Fire Safety) Order 2005"
    ],
    "autoActions": [
      {
        "questionId": "FRA1",
        "action": "Update fire risk assessment",
        "assignee": "Facilities Manager",
        "dueWithinDays": 30
      },
      {
        "questionId": "FRA2",
        "action": "Clear and secure escape routes",
        "assignee": "Site Manager",
        "dueWithinDays": 1
      }
    ],
    "auditIdExample": "FRA-2026-07",
    "sourceCoverage": [
      1,
      2,
      3
    ],
    "source2Questions": [
      {
        "id": "FRA1",
        "category": "Fire Plan",
        "text": "Is there a documented Fire Risk Assessment on file (updated within 2 years)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA2",
        "category": "Escape Routes",
        "text": "Are all escape routes clear of obstructions and clearly marked (including directional signage)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA3",
        "category": "Fire Doors",
        "text": "Are fire doors present and able to self-close (not wedged open)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA4",
        "category": "Alarm System",
        "text": "Is the fire alarm system tested and logged (monthly test record present)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA5",
        "category": "Extinguishers",
        "text": "Have fire extinguishers been inspected within the last 12 months (stamped and logged)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA6",
        "category": "Drills/Training",
        "text": "Have fire drills been conducted in the past year, and are training records available?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA7",
        "category": "Hazard Sources",
        "text": "Are ignition sources (e.g. open flames, hot work) controlled/isolated according to FRA recommendations?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA8",
        "category": "Plan",
        "text": "If any deficiencies were found (escape route issues, blocked exits, etc.), describe action taken:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "FRA2 == 0 || FRA3 == 0 || FRA4 == 0 || FRA5 == 0"
      }
    ],
    "source3Questions": [
      {
        "id": "FRA1",
        "category": "Documentation",
        "text": "Is a current Fire Risk Assessment (FRA) documented and accessible?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA2",
        "category": "Escape Routes",
        "text": "Are all exits/escape routes unobstructed and clearly signed?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA3",
        "category": "Doors",
        "text": "Are fire doors in working order and not propped open?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA4",
        "category": "Alarm",
        "text": "Is the fire alarm system tested regularly and records kept?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA5",
        "category": "Equipment",
        "text": "Are fire extinguishers serviced within 12 months and properly placed?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA6",
        "category": "Training",
        "text": "Have staff been trained in fire procedures within the last 12 months?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA7",
        "category": "Hazards",
        "text": "Are ignition sources controlled (no open flames/hot work without permits)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA8",
        "category": "Drills",
        "text": "Are regular fire drills conducted and logged?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA9",
        "category": "Emergency",
        "text": "Are emergency lights and signage tested and functional?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA10",
        "category": "Action",
        "text": "If any escape routes were blocked, describe corrective actions taken:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "FRA2 == 0"
      }
    ],
    "questions": [
      {
        "id": "FRA1",
        "category": "Documentation",
        "text": "Is a current Fire Risk Assessment (FRA) documented and accessible?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA2",
        "category": "Escape Routes",
        "text": "Are all exits/escape routes unobstructed and clearly signed?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA3",
        "category": "Doors",
        "text": "Are fire doors in working order and not propped open?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA4",
        "category": "Alarm",
        "text": "Is the fire alarm system tested regularly and records kept?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA5",
        "category": "Equipment",
        "text": "Are fire extinguishers serviced within 12 months and properly placed?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA6",
        "category": "Training",
        "text": "Have staff been trained in fire procedures within the last 12 months?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA7",
        "category": "Hazards",
        "text": "Are ignition sources controlled (no open flames/hot work without permits)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA8",
        "category": "Drills",
        "text": "Are regular fire drills conducted and logged?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA9",
        "category": "Emergency",
        "text": "Are emergency lights and signage tested and functional?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FRA10",
        "category": "Action",
        "text": "If any escape routes were blocked, describe corrective actions taken:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "FRA2 == 0"
      }
    ]
  },
  {
    "templateId": "LOLER",
    "name": "LOLER Lifting Equipment Audit",
    "category": "LOLER",
    "regime": "LOLER",
    "scoringModel": "weighted_sections",
    "licenceModel": "multi_use",
    "passScore": 21,
    "maxScore": 26,
    "passPercent": 81,
    "criticalQuestionIds": [
      "LIF1",
      "LIF2",
      "LIF5"
    ],
    "retentionGuidance": "Keep thorough examination certificates at least 2 years, commonly retained for 3 years as good practice.",
    "regulatoryAnchors": [
      "LOLER 1998"
    ],
    "autoActions": [
      {
        "questionId": "LIF1",
        "action": "Arrange overdue LOLER exam",
        "assignee": "Maintenance Team",
        "dueWithinDays": 14
      },
      {
        "questionId": "LIF5",
        "action": "Upload valid thorough examination certificates",
        "assignee": "Compliance Coordinator",
        "dueWithinDays": 7
      }
    ],
    "auditIdExample": "LOLER-2026-07",
    "sourceCoverage": [
      1,
      2,
      3
    ],
    "source2Questions": [
      {
        "id": "LIF1",
        "category": "Equipment",
        "text": "Is each lifting device (crane/hoist) within its LOLER examination interval?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LIF2",
        "category": "Markings",
        "text": "Are safe working loads (SWL) clearly marked on all lifting equipment?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LIF3",
        "category": "Inspections",
        "text": "Are daily pre-use checks performed and recorded for lifting accessories (e.g. chains, slings)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LIF4",
        "category": "Defects",
        "text": "If any equipment is taken out of service due to defects, is the action logged with dates?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "LIF1 == 0"
      },
      {
        "id": "LIF5",
        "category": "Records",
        "text": "Are LOLER thorough examination certificates available and up to date?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LIF6",
        "category": "Operators",
        "text": "Are lifting equipment operators trained and certified as required?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      }
    ],
    "source3Questions": [
      {
        "id": "LIF1",
        "category": "Exam",
        "text": "Is each lifting device (hoist/crane) within its LOLER exam interval?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LIF2",
        "category": "Labels",
        "text": "Are safe working load (SWL) labels legible on all lifting gear?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LIF3",
        "category": "Inspections",
        "text": "Are daily pre-use checks done and recorded for slings/chains?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LIF4",
        "category": "Defects",
        "text": "If any defects found, is defective equipment tagged out and logged?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "LIF1 == 0"
      },
      {
        "id": "LIF5",
        "category": "Certificate",
        "text": "Are thorough exam certificates for lifting gear available and up to date?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LIF6",
        "category": "Training",
        "text": "Are operators trained/certified (e.g. CISRS for cranes)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LIF7",
        "category": "Maintenance",
        "text": "Is maintenance (e.g. lubrication, load chain replacement) logged?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LIF8",
        "category": "Action",
        "text": "If any gear is overdue exam, list remedy action:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "LIF1 == 0"
      }
    ],
    "questions": [
      {
        "id": "LIF1",
        "category": "Exam",
        "text": "Is each lifting device (hoist/crane) within its LOLER exam interval?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LIF2",
        "category": "Labels",
        "text": "Are safe working load (SWL) labels legible on all lifting gear?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LIF3",
        "category": "Inspections",
        "text": "Are daily pre-use checks done and recorded for slings/chains?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LIF4",
        "category": "Defects",
        "text": "If any defects found, is defective equipment tagged out and logged?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "LIF1 == 0"
      },
      {
        "id": "LIF5",
        "category": "Certificate",
        "text": "Are thorough exam certificates for lifting gear available and up to date?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LIF6",
        "category": "Training",
        "text": "Are operators trained/certified (e.g. CISRS for cranes)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LIF7",
        "category": "Maintenance",
        "text": "Is maintenance (e.g. lubrication, load chain replacement) logged?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LIF8",
        "category": "Action",
        "text": "If any gear is overdue exam, list remedy action:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "LIF1 == 0"
      }
    ]
  },
  {
    "templateId": "PUWER",
    "name": "PUWER Work Equipment Audit",
    "category": "PUWER",
    "regime": "PUWER",
    "scoringModel": "weighted_sections",
    "licenceModel": "multi_use",
    "passScore": 18,
    "maxScore": 22,
    "passPercent": 82,
    "criticalQuestionIds": [
      "WKE1",
      "WKE2",
      "WKE4"
    ],
    "retentionGuidance": "Keep maintenance and inspection records for equipment life plus 2 years, training records around 5 years.",
    "regulatoryAnchors": [
      "PUWER 1998"
    ],
    "autoActions": [
      {
        "questionId": "WKE4",
        "action": "Install or repair machine guards",
        "assignee": "Safety Engineer",
        "dueWithinDays": 7
      },
      {
        "questionId": "WKE2",
        "action": "Recover maintenance backlog",
        "assignee": "Maintenance Supervisor",
        "dueWithinDays": 14
      }
    ],
    "auditIdExample": "PUWER-2026-07",
    "sourceCoverage": [
      1,
      2,
      3
    ],
    "source2Questions": [
      {
        "id": "WKE1",
        "category": "Suitability",
        "text": "Is all work equipment (machinery, tools) suitable for its intended use?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "WKE2",
        "category": "Maintenance",
        "text": "Is equipment maintained in good repair (maintenance logs up to date)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "WKE3",
        "category": "Inspections",
        "text": "Are inspections performed when equipment is installed/altered and at recommended intervals?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "WKE4",
        "category": "Guards/Controls",
        "text": "Are all guards and emergency stops present and functional on machinery?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "WKE5",
        "category": "Training",
        "text": "Have operators been trained on safe use of each machine (records kept)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      }
    ],
    "source3Questions": [
      {
        "id": "WKE1",
        "category": "Suitability",
        "text": "Is equipment suitable for its intended use (no ad-hoc modifications)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "WKE2",
        "category": "Maintenance",
        "text": "Is work equipment maintained (maintenance log up to date)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "WKE3",
        "category": "Inspections",
        "text": "Are inspections done after installation or alterations (documented)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "WKE4",
        "category": "Guards",
        "text": "Are machine guards and emergency stops present and tested?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "WKE5",
        "category": "Training",
        "text": "Are users trained/instructed with records kept?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "WKE6",
        "category": "Lockout",
        "text": "Are Lockout/Tagout procedures used during maintenance?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "WKE7",
        "category": "Finding",
        "text": "If any critical fail (e.g. guard missing), describe the fix:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "WKE4 == 0"
      }
    ],
    "questions": [
      {
        "id": "WKE1",
        "category": "Suitability",
        "text": "Is equipment suitable for its intended use (no ad-hoc modifications)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "WKE2",
        "category": "Maintenance",
        "text": "Is work equipment maintained (maintenance log up to date)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "WKE3",
        "category": "Inspections",
        "text": "Are inspections done after installation or alterations (documented)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "WKE4",
        "category": "Guards",
        "text": "Are machine guards and emergency stops present and tested?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "WKE5",
        "category": "Training",
        "text": "Are users trained/instructed with records kept?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "WKE6",
        "category": "Lockout",
        "text": "Are Lockout/Tagout procedures used during maintenance?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "WKE7",
        "category": "Finding",
        "text": "If any critical fail (e.g. guard missing), describe the fix:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "WKE4 == 0"
      }
    ]
  },
  {
    "templateId": "PSSR",
    "name": "PSSR Pressure Systems Audit",
    "category": "PSSR",
    "regime": "PSSR",
    "scoringModel": "weighted_sections",
    "licenceModel": "multi_use",
    "passScore": 13,
    "maxScore": 16,
    "passPercent": 81,
    "criticalQuestionIds": [
      "PRS1",
      "PRS2"
    ],
    "retentionGuidance": "Keep written scheme and exam records for life of system plus at least 2 years.",
    "regulatoryAnchors": [
      "Pressure Systems Safety Regulations 2000"
    ],
    "autoActions": [
      {
        "questionId": "PRS1",
        "action": "Create written scheme of examination",
        "assignee": "Pressure Engineer",
        "dueWithinDays": 21
      },
      {
        "questionId": "PRS2",
        "action": "Schedule overdue pressure examination",
        "assignee": "Maintenance Lead",
        "dueWithinDays": 7
      }
    ],
    "auditIdExample": "PSSR-2026-07",
    "sourceCoverage": [
      1,
      2,
      3
    ],
    "source2Questions": [
      {
        "id": "PRS1",
        "category": "Scheme",
        "text": "Is there a valid Written Scheme of Examination (WSE) for each pressure vessel?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "PRS2",
        "category": "Examinations",
        "text": "Are pressure systems examined and tested per the WSE schedule (records kept)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "PRS3",
        "category": "Markings",
        "text": "Are vessels marked with working pressure and manufacturer details?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "PRS4",
        "category": "Maintenance",
        "text": "Is there evidence of regular maintenance (valves, seals) for the pressure system?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      }
    ],
    "source3Questions": [
      {
        "id": "PRS1",
        "category": "Written Scheme",
        "text": "Is a current Written Scheme of Examination (WSE) in place for each pressure system?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "PRS2",
        "category": "Examination",
        "text": "Are pressure systems examined per the WSE schedule and records kept?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "PRS3",
        "category": "Maintenance",
        "text": "Are maintenance records (valve servicing, leak checks) up to date?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "PRS4",
        "category": "Safety Devices",
        "text": "Are safety valves and pressure gauges tested/calibrated as required?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "PRS5",
        "category": "Action",
        "text": "If any exam overdue or device faulty, detail corrective actions:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "PRS2 == 0 || PRS4 == 0"
      }
    ],
    "questions": [
      {
        "id": "PRS1",
        "category": "Written Scheme",
        "text": "Is a current Written Scheme of Examination (WSE) in place for each pressure system?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "PRS2",
        "category": "Examination",
        "text": "Are pressure systems examined per the WSE schedule and records kept?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "PRS3",
        "category": "Maintenance",
        "text": "Are maintenance records (valve servicing, leak checks) up to date?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "PRS4",
        "category": "Safety Devices",
        "text": "Are safety valves and pressure gauges tested/calibrated as required?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "PRS5",
        "category": "Action",
        "text": "If any exam overdue or device faulty, detail corrective actions:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "PRS2 == 0 || PRS4 == 0"
      }
    ]
  },
  {
    "templateId": "COSHH",
    "name": "COSHH Hazardous Substances Audit",
    "category": "COSHH",
    "regime": "COSHH",
    "scoringModel": "weighted_sections",
    "licenceModel": "multi_use",
    "passScore": 18,
    "maxScore": 22,
    "passPercent": 82,
    "criticalQuestionIds": [
      "CSH1",
      "CSH3"
    ],
    "retentionGuidance": "Keep COSHH assessments and SDS while substances are used and typically at least 5 years after last use.",
    "regulatoryAnchors": [
      "COSHH 2002"
    ],
    "autoActions": [
      {
        "questionId": "CSH1",
        "action": "Conduct COSHH assessment for all hazardous substances",
        "assignee": "Safety Officer",
        "dueWithinDays": 14
      },
      {
        "questionId": "CSH3",
        "action": "Implement missing control measures",
        "assignee": "Operations Manager",
        "dueWithinDays": 7
      }
    ],
    "auditIdExample": "COSHH-2026-07",
    "sourceCoverage": [
      1,
      2,
      3
    ],
    "source2Questions": [
      {
        "id": "CSH1",
        "category": "Assessment",
        "text": "Have COSHH risk assessments been carried out for all hazardous substances?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "CSH2",
        "category": "SDS",
        "text": "Are Safety Data Sheets available for all substances and are workers aware of them?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": false,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "CSH3",
        "category": "Controls",
        "text": "Have appropriate control measures (ventilation, PPE, spill kits) been implemented?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "CSH4",
        "category": "Training",
        "text": "Are staff trained in handling hazardous substances (documentation of training)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "CSH5",
        "category": "Storage",
        "text": "Are chemicals stored safely (segregation, labeling, containment) and log accessible?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": true,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      }
    ],
    "source3Questions": [
      {
        "id": "CSH1",
        "category": "Assessment",
        "text": "Have COSHH risk assessments been completed for all chemicals?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "CSH2",
        "category": "SDS",
        "text": "Are Safety Data Sheets (SDS) available for each substance and accessible?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": false,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "CSH3",
        "category": "Controls",
        "text": "Have control measures (ventilation, PPE) been implemented per COSHH assessments?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "CSH4",
        "category": "Spill Response",
        "text": "Is a spill kit available and staff trained in spill response?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "CSH5",
        "category": "Storage",
        "text": "Are chemicals stored safely (labeled containers, segregated by hazard class)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "CSH6",
        "category": "First Aid",
        "text": "Are emergency showers/eyewashes present and functional (tested)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "CSH7",
        "category": "Action",
        "text": "If controls are missing, list steps to implement them:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "CSH3 == 0"
      }
    ],
    "questions": [
      {
        "id": "CSH1",
        "category": "Assessment",
        "text": "Have COSHH risk assessments been completed for all chemicals?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "CSH2",
        "category": "SDS",
        "text": "Are Safety Data Sheets (SDS) available for each substance and accessible?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": false,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "CSH3",
        "category": "Controls",
        "text": "Have control measures (ventilation, PPE) been implemented per COSHH assessments?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "CSH4",
        "category": "Spill Response",
        "text": "Is a spill kit available and staff trained in spill response?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "CSH5",
        "category": "Storage",
        "text": "Are chemicals stored safely (labeled containers, segregated by hazard class)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "CSH6",
        "category": "First Aid",
        "text": "Are emergency showers/eyewashes present and functional (tested)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "CSH7",
        "category": "Action",
        "text": "If controls are missing, list steps to implement them:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "CSH3 == 0"
      }
    ]
  },
  {
    "templateId": "ASBESTOS",
    "name": "Asbestos Management Audit",
    "category": "ASBESTOS",
    "regime": "ASBESTOS",
    "scoringModel": "weighted_sections",
    "licenceModel": "multi_use",
    "passScore": 15,
    "maxScore": 18,
    "passPercent": 83,
    "criticalQuestionIds": [
      "ASM1",
      "ASM2"
    ],
    "retentionGuidance": "Keep asbestos register and plan at least 6 years after final ACM removal; training records around 5 years.",
    "regulatoryAnchors": [
      "Control of Asbestos Regulations 2012"
    ],
    "autoActions": [
      {
        "questionId": "ASM1",
        "action": "Commission updated asbestos survey",
        "assignee": "Facilities Manager",
        "dueWithinDays": 30
      },
      {
        "questionId": "ASM2",
        "action": "Create or refresh asbestos management plan",
        "assignee": "Compliance Lead",
        "dueWithinDays": 30
      }
    ],
    "auditIdExample": "ASB-2026-07",
    "sourceCoverage": [
      1,
      2,
      3
    ],
    "source2Questions": [
      {
        "id": "ASM1",
        "category": "Survey/Register",
        "text": "Is there a current asbestos survey/register covering all areas (and updated within last 2 years)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ASM2",
        "category": "Management Plan",
        "text": "Is an asbestos management plan in place and reviewed annually?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ASM3",
        "category": "Condition Checks",
        "text": "Are ACMs inspected (e.g. physical condition checks) and results logged (see next inspection date)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ASM4",
        "category": "Awareness",
        "text": "Have relevant staff been informed about ACM locations and risks (training record)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      }
    ],
    "source3Questions": [
      {
        "id": "ASM1",
        "category": "Survey",
        "text": "Is there a current asbestos survey/register covering the premises?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ASM2",
        "category": "Plan",
        "text": "Is an asbestos management plan in place and reviewed annually?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ASM3",
        "category": "Condition",
        "text": "Are asbestos-containing materials (ACMs) inspected/monitored and records updated?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ASM4",
        "category": "Access",
        "text": "Are site workers informed of ACM locations (signage or register accessible)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ASM5",
        "category": "Removal",
        "text": "If ACM removal was done, were licensed contractors used and air-clearance certificates obtained?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ASM6",
        "category": "Action",
        "text": "If the survey is outdated, specify plan to update it:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "ASM1 == 0"
      }
    ],
    "questions": [
      {
        "id": "ASM1",
        "category": "Survey",
        "text": "Is there a current asbestos survey/register covering the premises?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ASM2",
        "category": "Plan",
        "text": "Is an asbestos management plan in place and reviewed annually?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ASM3",
        "category": "Condition",
        "text": "Are asbestos-containing materials (ACMs) inspected/monitored and records updated?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ASM4",
        "category": "Access",
        "text": "Are site workers informed of ACM locations (signage or register accessible)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ASM5",
        "category": "Removal",
        "text": "If ACM removal was done, were licensed contractors used and air-clearance certificates obtained?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ASM6",
        "category": "Action",
        "text": "If the survey is outdated, specify plan to update it:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "ASM1 == 0"
      }
    ]
  },
  {
    "templateId": "LEGIONELLA",
    "name": "Legionella and Water Safety Audit",
    "category": "LEGIONELLA",
    "regime": "LEGIONELLA",
    "scoringModel": "weighted_sections",
    "licenceModel": "multi_use",
    "passScore": 12,
    "maxScore": 15,
    "passPercent": 80,
    "criticalQuestionIds": [
      "LEG1",
      "LEG2"
    ],
    "retentionGuidance": "Keep legionella risk assessments and temperature logs for at least 5 years.",
    "regulatoryAnchors": [
      "ACoP L8 / HSG274"
    ],
    "autoActions": [
      {
        "questionId": "LEG2",
        "action": "Restore compliant hot and cold water temperatures",
        "assignee": "Maintenance Manager",
        "dueWithinDays": 2
      },
      {
        "questionId": "LEG1",
        "action": "Refresh legionella risk assessment",
        "assignee": "Water Hygiene Contractor",
        "dueWithinDays": 21
      }
    ],
    "auditIdExample": "LEG-2026-07",
    "sourceCoverage": [
      1,
      2,
      3
    ],
    "source2Questions": [
      {
        "id": "LEG1",
        "category": "Assessment",
        "text": "Is there a current Legionella risk assessment for the water system?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LEG2",
        "category": "Temperature Control",
        "text": "Is hot water stored ≥60°C and distributed ≥50°C? (Check sentinel outlet temps)",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LEG3",
        "category": "Monitoring",
        "text": "Are sentinel outlet temperatures logged monthly (hot/cold) as required by risk assessment?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LEG4",
        "category": "Cleaning",
        "text": "Are tanks flushed/cleaned per schedule (logs reviewed)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      }
    ],
    "source3Questions": [
      {
        "id": "LEG1",
        "category": "Assessment",
        "text": "Is there a current Legionella risk assessment for water systems?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LEG2",
        "category": "TempControl",
        "text": "Are hot water systems storing ≥60°C and cold ≤20°C?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LEG3",
        "category": "Monitoring",
        "text": "Are sentinel outlet temperatures logged monthly (hot/cold)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LEG4",
        "category": "Cleaning",
        "text": "Are water storage tanks cleaned/inspected on schedule (records)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LEG5",
        "category": "Action",
        "text": "If temp limits not met, describe remedial actions:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "LEG2 == 0"
      }
    ],
    "questions": [
      {
        "id": "LEG1",
        "category": "Assessment",
        "text": "Is there a current Legionella risk assessment for water systems?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LEG2",
        "category": "TempControl",
        "text": "Are hot water systems storing ≥60°C and cold ≤20°C?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LEG3",
        "category": "Monitoring",
        "text": "Are sentinel outlet temperatures logged monthly (hot/cold)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LEG4",
        "category": "Cleaning",
        "text": "Are water storage tanks cleaned/inspected on schedule (records)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "LEG5",
        "category": "Action",
        "text": "If temp limits not met, describe remedial actions:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "LEG2 == 0"
      }
    ]
  },
  {
    "templateId": "ELECTRICAL",
    "name": "Electrical Safety Audit (EICR/PAT)",
    "category": "ELECTRICAL",
    "regime": "ELECTRICAL",
    "scoringModel": "weighted_sections",
    "licenceModel": "multi_use",
    "passScore": 15,
    "maxScore": 18,
    "passPercent": 83,
    "criticalQuestionIds": [
      "ELE1"
    ],
    "retentionGuidance": "Retain EICR certificates for at least 5 years and PAT logs around 3 years.",
    "regulatoryAnchors": [
      "Electricity at Work Regulations 1989"
    ],
    "autoActions": [
      {
        "questionId": "ELE1",
        "action": "Arrange EICR inspection",
        "assignee": "Facilities Engineer",
        "dueWithinDays": 14
      }
    ],
    "auditIdExample": "ELEC-2026-07",
    "sourceCoverage": [
      1,
      2,
      3
    ],
    "source2Questions": [
      {
        "id": "ELE1",
        "category": "Fixed Wiring",
        "text": "Has the fixed electrical installation been inspected by a qualified engineer within the last 5 years (EICR)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ELE2",
        "category": "Portable Appliances",
        "text": "Is portable appliance testing (PAT) up to date (e.g. annual for high-risk appliances)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ELE3",
        "category": "Visual Inspection",
        "text": "Are visible cable runs and sockets damage-free and suitable (cable exposed or frayed)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ELE4",
        "category": "RCD Protection",
        "text": "Is RCD (residual current device) protection in place for socket circuits (test log present)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      }
    ],
    "source3Questions": [
      {
        "id": "ELE1",
        "category": "FixedIns",
        "text": "Is the fixed wiring inspected/testing certificate (EICR) up to date (<5 years)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ELE2",
        "category": "Appliances",
        "text": "Are portable appliances PAT tested as per schedule (labels/log present)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ELE3",
        "category": "VisualCheck",
        "text": "Are cables and plugs damage-free and in good condition?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ELE4",
        "category": "RCD",
        "text": "Are RCDs installed on circuits and tested monthly (log)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ELE5",
        "category": "Lighting",
        "text": "Is emergency lighting tested monthly (and logs up to date)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ELE6",
        "category": "Action",
        "text": "If inspection is overdue, describe action:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "ELE1 == 0"
      }
    ],
    "questions": [
      {
        "id": "ELE1",
        "category": "FixedIns",
        "text": "Is the fixed wiring inspected/testing certificate (EICR) up to date (<5 years)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ELE2",
        "category": "Appliances",
        "text": "Are portable appliances PAT tested as per schedule (labels/log present)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ELE3",
        "category": "VisualCheck",
        "text": "Are cables and plugs damage-free and in good condition?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ELE4",
        "category": "RCD",
        "text": "Are RCDs installed on circuits and tested monthly (log)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ELE5",
        "category": "Lighting",
        "text": "Is emergency lighting tested monthly (and logs up to date)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ELE6",
        "category": "Action",
        "text": "If inspection is overdue, describe action:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "ELE1 == 0"
      }
    ]
  },
  {
    "templateId": "SCAFFOLD",
    "name": "Scaffold and Access Equipment Audit",
    "category": "SCAFFOLD",
    "regime": "SCAFFOLD",
    "scoringModel": "weighted_sections",
    "licenceModel": "multi_use",
    "passScore": 13,
    "maxScore": 16,
    "passPercent": 81,
    "criticalQuestionIds": [
      "SCF1",
      "SCF2"
    ],
    "retentionGuidance": "Keep scaffold inspection logs for project duration and at least 1 year; training records around 3 to 5 years.",
    "regulatoryAnchors": [
      "Work at Height Regulations 2005"
    ],
    "autoActions": [
      {
        "questionId": "SCF1",
        "action": "Inspect scaffold immediately",
        "assignee": "Site Foreman",
        "dueWithinDays": 1
      },
      {
        "questionId": "SCF2",
        "action": "Repair or isolate unsafe scaffold section",
        "assignee": "Scaffold Contractor",
        "dueWithinDays": 1
      }
    ],
    "auditIdExample": "SCF-2026-07",
    "sourceCoverage": [
      1,
      2,
      3
    ],
    "source2Questions": [
      {
        "id": "SCF1",
        "category": "Inspections",
        "text": "Is all scaffold equipment inspected by a competent person before first use and at weekly intervals (records up to date)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "SCF2",
        "category": "Condition",
        "text": "Is scaffold in good condition (no damaged fittings, properly braced)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "SCF3",
        "category": "Training",
        "text": "Are workers trained in scaffold erection/use and is evidence of training available?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "SCF4",
        "category": "Platforms",
        "text": "Are working platforms fully boarded and guardrails fitted?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      }
    ],
    "source3Questions": [
      {
        "id": "SCF1",
        "category": "Inspection",
        "text": "Has the scaffold been inspected before use and within the last 7 days?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "SCF2",
        "category": "Condition",
        "text": "Is the scaffold in good condition (no broken parts, properly braced)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "SCF3",
        "category": "Training",
        "text": "Are personnel erecting/using scaffold trained/certified (records)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "SCF4",
        "category": "Access",
        "text": "Is safe access provided (ladders or stairs) and guardrails in place?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "SCF5",
        "category": "Action",
        "text": "If any critical fail, detail immediate corrective action:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "SCF1 == 0 || SCF2 == 0"
      }
    ],
    "questions": [
      {
        "id": "SCF1",
        "category": "Inspection",
        "text": "Has the scaffold been inspected before use and within the last 7 days?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "SCF2",
        "category": "Condition",
        "text": "Is the scaffold in good condition (no broken parts, properly braced)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "SCF3",
        "category": "Training",
        "text": "Are personnel erecting/using scaffold trained/certified (records)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "SCF4",
        "category": "Access",
        "text": "Is safe access provided (ladders or stairs) and guardrails in place?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "SCF5",
        "category": "Action",
        "text": "If any critical fail, detail immediate corrective action:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "SCF1 == 0 || SCF2 == 0"
      }
    ]
  },
  {
    "templateId": "FOOD",
    "name": "Food Hygiene Audit",
    "category": "FOOD",
    "regime": "FOOD",
    "scoringModel": "weighted_sections",
    "licenceModel": "multi_use",
    "passScore": 16,
    "maxScore": 20,
    "passPercent": 80,
    "criticalQuestionIds": [
      "FDH1",
      "FDH2"
    ],
    "retentionGuidance": "Keep temperature and cleaning logs for 1 to 2 years and food safety training records for about 3 years.",
    "regulatoryAnchors": [
      "Food Safety Act 1990",
      "Food Hygiene (England) Regulations 2013"
    ],
    "autoActions": [
      {
        "questionId": "FDH2",
        "action": "Repair or recalibrate refrigeration",
        "assignee": "Kitchen Manager",
        "dueWithinDays": 1
      },
      {
        "questionId": "FDH1",
        "action": "Deep clean food prep zones and verify sanitation",
        "assignee": "Duty Manager",
        "dueWithinDays": 1
      }
    ],
    "auditIdExample": "FOOD-2026-07",
    "sourceCoverage": [
      1,
      2,
      3
    ],
    "source2Questions": [
      {
        "id": "FDH1",
        "category": "Cleanliness",
        "text": "Are food preparation and storage areas clean and hygienic (including fridge/freezer cleanliness)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FDH2",
        "category": "Temperature",
        "text": "Are hot foods held ≥63°C and cold foods ≤8°C? (Check logs or take readings)",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FDH3",
        "category": "Pest Control",
        "text": "Is there evidence of an active pest control (bait stations, logs reviewed)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FDH4",
        "category": "Staff Hygiene",
        "text": "Are staff following hygiene practices (handwashing, gloves) and trained in food safety?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FDH5",
        "category": "Records",
        "text": "Are food safety logs (temperature, cleaning schedules) maintained and up to date?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      }
    ],
    "source3Questions": [
      {
        "id": "FDH1",
        "category": "Cleanliness",
        "text": "Are food prep surfaces and floors clean and sanitized?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FDH2",
        "category": "Temperature",
        "text": "Are refrigerators/freezers at correct temperatures (≤8°C for fridge, ≤-18°C freezer)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FDH3",
        "category": "Pests",
        "text": "Is there evidence of pest control (no droppings/traps inspected)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FDH4",
        "category": "Allergens",
        "text": "Are allergen notices displayed and staff aware of handling procedures?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FDH5",
        "category": "Hygiene",
        "text": "Are staff wearing clean uniforms and following handwashing procedures?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FDH6",
        "category": "TempLogs",
        "text": "Are food temperature logs (cooking, holding) maintained daily?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FDH7",
        "category": "Action",
        "text": "If any critical fail, note corrective action taken:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "FDH1 == 0 || FDH2 == 0"
      }
    ],
    "questions": [
      {
        "id": "FDH1",
        "category": "Cleanliness",
        "text": "Are food prep surfaces and floors clean and sanitized?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FDH2",
        "category": "Temperature",
        "text": "Are refrigerators/freezers at correct temperatures (≤8°C for fridge, ≤-18°C freezer)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FDH3",
        "category": "Pests",
        "text": "Is there evidence of pest control (no droppings/traps inspected)?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FDH4",
        "category": "Allergens",
        "text": "Are allergen notices displayed and staff aware of handling procedures?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 2,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FDH5",
        "category": "Hygiene",
        "text": "Are staff wearing clean uniforms and following handwashing procedures?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FDH6",
        "category": "TempLogs",
        "text": "Are food temperature logs (cooking, holding) maintained daily?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "FDH7",
        "category": "Action",
        "text": "If any critical fail, note corrective action taken:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "FDH1 == 0 || FDH2 == 0"
      }
    ]
  },
  {
    "templateId": "WORKPLACE",
    "name": "Workplace and Environment Inspection",
    "category": "WORKPLACE",
    "regime": "WORKPLACE",
    "scoringModel": "weighted_sections",
    "licenceModel": "multi_use",
    "passScore": 18,
    "maxScore": 22,
    "passPercent": 82,
    "criticalQuestionIds": [
      "ENV1",
      "ENV3"
    ],
    "retentionGuidance": "Keep inspection logs and corrective action evidence for at least 3 years.",
    "regulatoryAnchors": [
      "Health and Safety at Work Act 1974"
    ],
    "autoActions": [
      {
        "questionId": "ENV1",
        "action": "Clear blocked walkways and exits",
        "assignee": "Site Supervisor",
        "dueWithinDays": 1
      },
      {
        "questionId": "ENV3",
        "action": "Rectify unsafe plant or machinery conditions",
        "assignee": "Engineering Supervisor",
        "dueWithinDays": 2
      }
    ],
    "auditIdExample": "WORKPLACE-2026-01",
    "sourceCoverage": [
      1
    ],
    "source2Questions": [],
    "source3Questions": [],
    "questions": [
      {
        "id": "ENV1",
        "category": "Housekeeping",
        "text": "Are floors, aisles, and exits clear of obstruction with slip and trip hazards controlled?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ENV2",
        "category": "PPE and Behaviour",
        "text": "Are workers using the required PPE and following local safety instructions?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ENV3",
        "category": "Plant and Equipment",
        "text": "Is site equipment free from visible defects with controls and emergency stops operational?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": true,
          "comment": false,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ENV4",
        "category": "Safety Information",
        "text": "Are safety signs, notices, and emergency information visible and current?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 3,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "ENV5",
        "category": "Action",
        "text": "If any unsafe conditions are found, describe immediate control measures and owners:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "ENV1 == 0 || ENV3 == 0"
      }
    ]
  },
  {
    "templateId": "SUPPLEMENTAL",
    "name": "Supplemental Statutory Checks (Gas, DSE, Sector Specific)",
    "category": "SUPPLEMENTAL",
    "regime": "SUPPLEMENTAL",
    "scoringModel": "weighted_sections",
    "licenceModel": "multi_use",
    "passScore": 14,
    "maxScore": 18,
    "passPercent": 78,
    "criticalQuestionIds": [
      "SUP1",
      "SUP2"
    ],
    "retentionGuidance": "Retain statutory certificates and assessment records in line with site policy and applicable law.",
    "regulatoryAnchors": [
      "Gas Safety Regulations",
      "DSE Regulations",
      "Sector specific statutory guidance"
    ],
    "autoActions": [
      {
        "questionId": "SUP1",
        "action": "Arrange annual gas safety inspection",
        "assignee": "Facilities Manager",
        "dueWithinDays": 7
      },
      {
        "questionId": "SUP2",
        "action": "Complete outstanding DSE assessments",
        "assignee": "HR and HSE Lead",
        "dueWithinDays": 30
      }
    ],
    "auditIdExample": "SUPPLEMENTAL-2026-01",
    "sourceCoverage": [
      1
    ],
    "source2Questions": [],
    "source3Questions": [],
    "questions": [
      {
        "id": "SUP1",
        "category": "Gas Safety",
        "text": "Are gas appliances and pipework covered by a valid annual safety inspection certificate?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 5,
        "critical": true,
        "required": true,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "SUP2",
        "category": "DSE",
        "text": "Have DSE workstation assessments been completed for office based staff and tracked for review?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": true,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "SUP3",
        "category": "Sector Specific",
        "text": "Are sector specific statutory checks completed and documented for this location?",
        "type": "boolean",
        "options": {
          "yes": 1,
          "no": 0
        },
        "weight": 4,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": true,
          "signature": false
        },
        "showIf": null
      },
      {
        "id": "SUP4",
        "category": "Action",
        "text": "List corrective actions for any overdue statutory checks:",
        "type": "text",
        "weight": 1,
        "critical": false,
        "required": false,
        "evidence": {
          "photo": false,
          "comment": false,
          "signature": false
        },
        "showIf": "SUP1 == 0 || SUP2 == 0 || SUP3 == 0"
      }
    ]
  }
];

const DEFAULT_BOOLEAN_CONTROL_TARGET = 28;

const booleanControlTargetByRegime = {
  HS: 40,
  FRA: 34,
  LOLER: 32,
  PUWER: 30,
  PSSR: 28,
  COSHH: 30,
  ASBESTOS: 28,
  LEGIONELLA: 28,
  ELECTRICAL: 30,
  SCAFFOLD: 28,
  FOOD: 30,
  WORKPLACE: 26,
  SUPPLEMENTAL: 24,
};

const templateFocusAreasByRegime = {
  HS: [
    'policy governance',
    'leadership accountability',
    'risk assessment lifecycle',
    'incident management',
    'training and competence',
    'contractor management',
    'permit to work controls',
    'safety communications',
    'housekeeping and welfare',
    'emergency preparedness',
  ],
  FRA: [
    'fire risk assessment governance',
    'escape route management',
    'fire door integrity',
    'alarm and detection systems',
    'extinguisher and suppression controls',
    'emergency lighting',
    'evacuation drills',
    'hot work and ignition controls',
    'fire warden competence',
    'post-incident review',
  ],
  LOLER: [
    'lifting register accuracy',
    'thorough examination scheduling',
    'safe working load labelling',
    'pre-use checks',
    'defect quarantine controls',
    'lifting accessory integrity',
    'operator competence',
    'maintenance planning',
    'lifting plans and supervision',
    'post-lift review',
  ],
  PUWER: [
    'equipment suitability',
    'guarding and interlocks',
    'isolation and lockout',
    'maintenance routines',
    'inspection routines',
    'operator instructions',
    'training and authorisation',
    'change control',
    'defect reporting',
    'management review',
  ],
  PSSR: [
    'written scheme governance',
    'examination scheduling',
    'safety valve assurance',
    'pressure gauge calibration',
    'leak detection controls',
    'isolation and venting',
    'competent person oversight',
    'maintenance routines',
    'emergency response readiness',
    'trend review and escalation',
  ],
  COSHH: [
    'hazard inventory control',
    'coshh assessment lifecycle',
    'safety data sheet currency',
    'engineering controls',
    'ppe selection and use',
    'storage and segregation',
    'spill response readiness',
    'exposure monitoring',
    'occupational health surveillance',
    'waste and disposal controls',
  ],
  ASBESTOS: [
    'asbestos register governance',
    'survey validity',
    'management plan controls',
    'acm condition inspections',
    'contractor communication',
    'permit controls for intrusive works',
    'licensed removal assurance',
    'air monitoring and clearance',
    'training and awareness',
    'reinspection scheduling',
  ],
  LEGIONELLA: [
    'risk assessment governance',
    'water temperature controls',
    'sentinel outlet monitoring',
    'tank inspections and cleaning',
    'flushing routines',
    'dead leg control',
    'biocide treatment controls',
    'sampling and analysis',
    'contractor performance review',
    'escalation and incident response',
  ],
  ELECTRICAL: [
    'fixed installation certification',
    'portable appliance control',
    'rcd testing controls',
    'emergency lighting testing',
    'distribution board integrity',
    'cable and socket condition',
    'electrical isolation procedures',
    'authorised person competence',
    'contractor verification',
    'defect remediation tracking',
  ],
  SCAFFOLD: [
    'design and handover controls',
    'weekly inspection routines',
    'post-weather reinspection',
    'platform and edge protection',
    'access and egress safety',
    'tagging and status marking',
    'component condition checks',
    'erector competence',
    'user briefing and supervision',
    'defect escalation controls',
  ],
  FOOD: [
    'haccp and food safety plans',
    'cleaning and sanitisation',
    'cold chain controls',
    'cooking and holding temperatures',
    'allergen management',
    'cross-contamination prevention',
    'pest control monitoring',
    'staff hygiene and welfare',
    'supplier and traceability records',
    'corrective action verification',
  ],
  WORKPLACE: [
    'walkway and egress control',
    'lighting and visibility',
    'noise and environmental conditions',
    'ergonomic risks',
    'manual handling controls',
    'first aid readiness',
    'safety signage',
    'housekeeping standards',
    'supervisory checks',
    'shift handover safety',
  ],
  SUPPLEMENTAL: [
    'gas safety certification',
    'dse assessment controls',
    'sector specific statutory checks',
    'third-party inspection controls',
    'insurance condition compliance',
    'warranty and service obligations',
    'regulatory horizon scanning',
    'management assurance reviews',
    'document retention controls',
    'escalation for overdue checks',
  ],
};

const controlPromptLibrary = [
  {
    category: 'Records',
    weight: 4,
    critical: true,
    required: true,
    evidence: { photo: false, comment: true, signature: false },
    build: (area) => `Are current records available to demonstrate compliance for ${area}?`,
  },
  {
    category: 'Frequency',
    weight: 4,
    critical: true,
    required: true,
    evidence: { photo: false, comment: true, signature: false },
    build: (area) => `Were scheduled checks for ${area} completed within required intervals and signed off?`,
  },
  {
    category: 'Physical Condition',
    weight: 5,
    critical: true,
    required: true,
    evidence: { photo: true, comment: true, signature: false },
    build: (area) => `Is physical condition for ${area} acceptable with no immediate defects or uncontrolled hazards?`,
  },
  {
    category: 'Functional Testing',
    weight: 4,
    critical: false,
    required: false,
    evidence: { photo: false, comment: true, signature: false },
    build: (area) => `Are test, calibration, or functional verification results for ${area} in date and within limits?`,
  },
  {
    category: 'Control Effectiveness',
    weight: 4,
    critical: true,
    required: true,
    evidence: { photo: true, comment: true, signature: false },
    build: (area) => `Are control measures for ${area} implemented and effective in day-to-day operation?`,
  },
  {
    category: 'Labelling and Signage',
    weight: 3,
    critical: false,
    required: false,
    evidence: { photo: true, comment: true, signature: false },
    build: (area) => `Are required labels, warning signs, and status tags for ${area} legible and current?`,
  },
  {
    category: 'Defect Closure',
    weight: 4,
    critical: true,
    required: false,
    evidence: { photo: false, comment: true, signature: false },
    build: (area) => `Were defects identified in ${area} corrected within target timescales with closure evidence?`,
  },
  {
    category: 'Competence',
    weight: 3,
    critical: false,
    required: false,
    evidence: { photo: false, comment: true, signature: false },
    build: (area) => `Are personnel performing ${area} tasks competent, authorised, and supported by current training records?`,
  },
  {
    category: 'Emergency and Isolation',
    weight: 3,
    critical: true,
    required: false,
    evidence: { photo: false, comment: true, signature: false },
    build: (area) => `Are emergency, fail-safe, or isolation controls connected to ${area} functional when tested?`,
  },
  {
    category: 'Contractor Control',
    weight: 3,
    critical: false,
    required: false,
    evidence: { photo: false, comment: true, signature: false },
    build: (area) => `Are contractor activities affecting ${area} controlled through permit, briefing, and supervision?`,
  },
  {
    category: 'Trend and Escalation',
    weight: 3,
    critical: false,
    required: false,
    evidence: { photo: false, comment: true, signature: false },
    build: (area) => `Are recurring issues related to ${area} trended and escalated when repeat failures occur?`,
  },
  {
    category: 'Inspection Evidence',
    weight: 3,
    critical: false,
    required: false,
    evidence: { photo: true, comment: true, signature: false },
    build: (area) => `Has current-cycle photographic or documentary evidence been captured for ${area}?`,
  },
];

function getTemplateFocusAreas(template) {
  const regimeKey = String(template?.regime || '').toUpperCase();
  if (Array.isArray(templateFocusAreasByRegime[regimeKey])) {
    return templateFocusAreasByRegime[regimeKey];
  }
  return [
    'governance controls',
    'inspection controls',
    'training controls',
    'record management controls',
    'corrective action controls',
    'operational controls',
    'emergency controls',
    'contractor controls',
    'management review controls',
    'continuous improvement controls',
  ];
}

function getBooleanControlTargetForTemplate(template) {
  const explicitTarget = Number(template?.targetBooleanControls || template?.targetControls || 0);
  if (Number.isFinite(explicitTarget) && explicitTarget > 0) {
    return Math.max(18, Math.round(explicitTarget));
  }

  const regimeKey = String(template?.regime || '').toUpperCase();
  if (Number.isFinite(booleanControlTargetByRegime[regimeKey])) {
    return booleanControlTargetByRegime[regimeKey];
  }

  return DEFAULT_BOOLEAN_CONTROL_TARGET;
}

function normalizeQuestionText(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/\(verification cycle[^)]*\)/g, '')
    .replace(/[\u2018\u2019']/g, '')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

const complianceQuestionAdditionsByTemplateId = {
  HSA: [
    {
      id: 'HSA13',
      category: 'Welfare',
      text: 'Are welfare facilities (toilets, drinking water, wash stations) available, clean, and adequate?',
      weight: 3,
      critical: true,
      required: true,
      evidence: { photo: true, comment: true, signature: false },
    },
    {
      id: 'HSA14',
      category: 'Contractor Control',
      text: 'Are contractors inducted, supervised, and briefed on site hazards before work starts?',
      weight: 3,
      critical: true,
      required: true,
      evidence: { photo: false, comment: true, signature: false },
    },
    {
      id: 'HSA15',
      category: 'Emergency Preparedness',
      text: 'Are emergency procedures documented, communicated, and supported by regular drill records?',
      weight: 3,
      critical: true,
      required: true,
      evidence: { photo: false, comment: true, signature: false },
    },
  ],
  FRA: [
    {
      id: 'FRA11',
      category: 'Evacuation',
      text: 'Are fire assembly point locations clearly marked and communicated to staff and visitors?',
      weight: 3,
      critical: true,
      required: true,
      evidence: { photo: true, comment: true, signature: false },
    },
    {
      id: 'FRA12',
      category: 'Detection Coverage',
      text: 'Do smoke and fire detection systems provide adequate coverage for all occupied risk areas?',
      weight: 4,
      critical: true,
      required: true,
      evidence: { photo: false, comment: true, signature: false },
    },
    {
      id: 'FRA13',
      category: 'Training',
      text: 'Where expected, are staff trained in extinguisher selection and safe use?',
      weight: 2,
      critical: false,
      required: false,
      evidence: { photo: false, comment: true, signature: false },
    },
  ],
  LOLER: [
    {
      id: 'LIF9',
      category: 'Register',
      text: 'Is a complete and current lifting equipment register maintained for all applicable assets and accessories?',
      weight: 3,
      critical: true,
      required: true,
      evidence: { photo: false, comment: true, signature: false },
    },
    {
      id: 'LIF10',
      category: 'Planned Maintenance',
      text: 'Is planned preventative maintenance for lifting equipment scheduled, completed, and logged?',
      weight: 3,
      critical: false,
      required: false,
      evidence: { photo: false, comment: true, signature: false },
    },
    {
      id: 'LIF11',
      category: 'Lifting Risk Assessment',
      text: 'Are lifting operations covered by current risk assessments and method statements where required?',
      weight: 3,
      critical: false,
      required: false,
      evidence: { photo: false, comment: true, signature: false },
    },
  ],
  PUWER: [
    {
      id: 'WKE8',
      category: 'Instructions',
      text: 'Are operator manuals and safe-use instructions available at point of use and understood by users?',
      weight: 3,
      critical: false,
      required: false,
      evidence: { photo: true, comment: true, signature: false },
    },
    {
      id: 'WKE9',
      category: 'Isolation',
      text: 'Are isolation points clearly labelled and lockout locations identifiable for relevant equipment?',
      weight: 3,
      critical: true,
      required: true,
      evidence: { photo: true, comment: true, signature: false },
    },
  ],
  PSSR: [
    {
      id: 'PRS6',
      category: 'Identification',
      text: 'Are pressure vessels and key system components clearly identified and labelled with required details?',
      weight: 3,
      critical: false,
      required: false,
      evidence: { photo: true, comment: true, signature: false },
    },
    {
      id: 'PRS7',
      category: 'Incidents',
      text: 'Are overpressure, leak, and pressure-system incidents logged, investigated, and closed with actions?',
      weight: 3,
      critical: true,
      required: true,
      evidence: { photo: false, comment: true, signature: false },
    },
  ],
  COSHH: [
    {
      id: 'CSH8',
      category: 'Labelling',
      text: 'Are all chemical containers clearly labelled with hazard information and handling instructions?',
      weight: 3,
      critical: true,
      required: true,
      evidence: { photo: true, comment: true, signature: false },
    },
    {
      id: 'CSH9',
      category: 'Disposal',
      text: 'Is there a controlled process for segregating and disposing of unused or expired hazardous substances?',
      weight: 3,
      critical: false,
      required: false,
      evidence: { photo: false, comment: true, signature: false },
    },
  ],
  ASBESTOS: [
    {
      id: 'ASM7',
      category: 'Awareness Training',
      text: 'Have relevant staff and contractors received asbestos awareness training with current records?',
      weight: 3,
      critical: true,
      required: true,
      evidence: { photo: false, comment: true, signature: false },
    },
    {
      id: 'ASM8',
      category: 'Pre-Work Survey',
      text: 'Are refurbishment or demolition works pre-checked with suitable asbestos survey information before intrusive work?',
      weight: 4,
      critical: true,
      required: true,
      evidence: { photo: false, comment: true, signature: false },
    },
  ],
  LEGIONELLA: [
    {
      id: 'LEG6',
      category: 'Flushing',
      text: 'Are infrequently used outlets included in a routine flushing and drain-down programme with records?',
      weight: 3,
      critical: false,
      required: false,
      evidence: { photo: false, comment: true, signature: false },
    },
    {
      id: 'LEG7',
      category: 'Review on Change',
      text: 'Has the legionella risk assessment been reviewed after significant system or occupancy changes?',
      weight: 3,
      critical: true,
      required: true,
      evidence: { photo: false, comment: true, signature: false },
    },
  ],
  ELECTRICAL: [
    {
      id: 'ELE7',
      category: 'Labelling',
      text: 'Are circuits, distribution boards, and key electrical assets correctly labelled for safe identification?',
      weight: 3,
      critical: false,
      required: false,
      evidence: { photo: true, comment: true, signature: false },
    },
    {
      id: 'ELE8',
      category: 'Isolation',
      text: 'Are electrical isolators clearly marked, accessible, and functionally verified?',
      weight: 3,
      critical: true,
      required: true,
      evidence: { photo: true, comment: true, signature: false },
    },
  ],
  SCAFFOLD: [
    {
      id: 'SCF6',
      category: 'Stability',
      text: 'Are scaffold ties, anchors, and stability controls installed as designed and visibly secure?',
      weight: 4,
      critical: true,
      required: true,
      evidence: { photo: true, comment: true, signature: false },
    },
    {
      id: 'SCF7',
      category: 'Post-Weather Checks',
      text: 'Is scaffold re-inspected and recorded after severe weather, impact, or significant alteration?',
      weight: 3,
      critical: true,
      required: true,
      evidence: { photo: false, comment: true, signature: false },
    },
  ],
  FOOD: [
    {
      id: 'FDH8',
      category: 'Competence',
      text: 'Do food handlers hold current food hygiene training records appropriate to their role?',
      weight: 3,
      critical: false,
      required: false,
      evidence: { photo: false, comment: true, signature: false },
    },
    {
      id: 'FDH9',
      category: 'Waste Management',
      text: 'Is food and general waste stored, segregated, and removed hygienically to prevent contamination?',
      weight: 3,
      critical: false,
      required: false,
      evidence: { photo: true, comment: true, signature: false },
    },
  ],
  WORKPLACE: [
    {
      id: 'ENV6',
      category: 'Environmental Conditions',
      text: 'Are ventilation and heating systems functioning and suitable for safe occupancy?',
      weight: 3,
      critical: false,
      required: false,
      evidence: { photo: false, comment: true, signature: false },
    },
    {
      id: 'ENV7',
      category: 'Ergonomics',
      text: 'Where office work is carried out, are DSE or ergonomic workstation assessments completed and actions tracked?',
      weight: 3,
      critical: false,
      required: false,
      evidence: { photo: false, comment: true, signature: false },
    },
  ],
  SUPPLEMENTAL: [
    {
      id: 'SUP5',
      category: 'Review Frequency',
      text: 'Are DSE assessments reviewed at least annually and when role or workstation conditions change?',
      weight: 3,
      critical: false,
      required: false,
      evidence: { photo: false, comment: true, signature: false },
    },
    {
      id: 'SUP6',
      category: 'Annual Certification',
      text: 'Are annual statutory certificates (including gas safety where applicable) tracked and renewed before expiry?',
      weight: 4,
      critical: true,
      required: true,
      evidence: { photo: false, comment: true, signature: false },
    },
  ],
};

const generatedGovernanceQuestionCategoryPrefixes = [
  'documentation:',
  'ownership:',
  'frequency:',
  'competence:',
  'physical condition:',
  'testing:',
  'records:',
  'corrective action:',
  'emergency:',
  'communication:',
  'contractors:',
  'change control:',
];

function isGeneratedGovernanceQuestion(question) {
  const questionId = String(question?.id || '')
    .trim()
    .toUpperCase();
  if (/^[A-Z0-9]{2,12}A\d{3,4}$/.test(questionId)) {
    return true;
  }

  const category = String(question?.category || '').trim().toLowerCase();
  if (generatedGovernanceQuestionCategoryPrefixes.some((prefix) => category.startsWith(prefix))) {
    return true;
  }

  const text = normalizeQuestionText(question?.text);
  return (
    text.startsWith('is there an approved current documented procedure for') ||
    text.startsWith('is an accountable owner named for') ||
    text.startsWith('are required inspections and checks for') ||
    text.startsWith('do personnel responsible for') ||
    text.startsWith('is field condition for') ||
    text.startsWith('are defects and non conformances for') ||
    text.startsWith('are changes impacting')
  );
}

function buildComplianceAdditionQuestion(addition, templateId, index) {
  const fallbackId = `${templateId}-ADD-${index + 1}`;
  return {
    id: String(addition?.id || fallbackId).trim() || fallbackId,
    category: String(addition?.category || 'Compliance').trim() || 'Compliance',
    text: String(addition?.text || '').trim(),
    type: 'boolean',
    options: { yes: 1, no: 0 },
    weight: Math.max(1, Number(addition?.weight || 3)),
    critical: Boolean(addition?.critical),
    required: Boolean(addition?.required),
    evidence: {
      photo: Boolean(addition?.evidence?.photo),
      comment: addition?.evidence?.comment !== false,
      signature: Boolean(addition?.evidence?.signature),
    },
    showIf: null,
  };
}

function inflateTemplateQuestions(template) {
  const sourceQuestions = Array.isArray(template?.questions) ? template.questions.filter(Boolean) : [];
  const existingBooleanQuestions = sourceQuestions.filter(
    (question) => String(question?.type || '').toLowerCase() === 'boolean'
  );
  const nonBooleanQuestions = sourceQuestions.filter(
    (question) => String(question?.type || '').toLowerCase() !== 'boolean'
  );

  const seenTexts = new Set();
  const seenIds = new Set();
  const dedupedBooleanQuestions = [];
  existingBooleanQuestions.forEach((question) => {
    if (isGeneratedGovernanceQuestion(question)) {
      return;
    }

    const normalizedId = String(question?.id || '')
      .trim()
      .toUpperCase();
    if (normalizedId && seenIds.has(normalizedId)) {
      return;
    }

    const normalized = normalizeQuestionText(question?.text);
    if (!normalized || seenTexts.has(normalized)) {
      return;
    }

    if (normalizedId) {
      seenIds.add(normalizedId);
    }
    seenTexts.add(normalized);
    dedupedBooleanQuestions.push(question);
  });

  const templateIdKey = String(template?.templateId || '').toUpperCase();
  const configuredAdditions = Array.isArray(complianceQuestionAdditionsByTemplateId[templateIdKey])
    ? complianceQuestionAdditionsByTemplateId[templateIdKey]
    : [];
  const complianceAdditions = configuredAdditions
    .map((addition, index) => buildComplianceAdditionQuestion(addition, templateIdKey || 'TMP', index))
    .filter((question) => {
      const normalizedId = String(question?.id || '')
        .trim()
        .toUpperCase();
      const normalizedText = normalizeQuestionText(question?.text);
      if (!normalizedText) {
        return false;
      }
      if (normalizedId && seenIds.has(normalizedId)) {
        return false;
      }
      if (seenTexts.has(normalizedText)) {
        return false;
      }
      if (normalizedId) {
        seenIds.add(normalizedId);
      }
      seenTexts.add(normalizedText);
      return true;
    });

  const targetBooleanControlCount = getBooleanControlTargetForTemplate(template);
  const premiumBooleanQuestions = [...dedupedBooleanQuestions, ...complianceAdditions];

  if (premiumBooleanQuestions.length >= targetBooleanControlCount) {
    return [...premiumBooleanQuestions.slice(0, targetBooleanControlCount), ...nonBooleanQuestions];
  }

  const existingIds = new Set(
    sourceQuestions
      .map((question) => String(question?.id || '').trim().toUpperCase())
      .filter(Boolean)
  );
  premiumBooleanQuestions.forEach((question) => {
    const questionId = String(question?.id || '').trim().toUpperCase();
    if (questionId) {
      existingIds.add(questionId);
    }
  });

  const generatedBooleanQuestions = [];
  const focusAreas = getTemplateFocusAreas(template);
  const idPrefix = `${String(templateIdKey || template?.regime || 'TMP')
    .replace(/[^A-Za-z0-9]/g, '')
    .toUpperCase()
    .slice(0, 8)}D`;
  let idCounter = 1;

  for (const area of focusAreas) {
    for (const prompt of controlPromptLibrary) {
      if (premiumBooleanQuestions.length + generatedBooleanQuestions.length >= targetBooleanControlCount) {
        break;
      }

      const questionText = prompt.build(area);
      const normalizedText = normalizeQuestionText(questionText);
      if (!normalizedText || seenTexts.has(normalizedText)) {
        continue;
      }
      seenTexts.add(normalizedText);

      let questionId = '';
      do {
        questionId = `${idPrefix}${String(idCounter).padStart(3, '0')}`;
        idCounter += 1;
      } while (existingIds.has(questionId.toUpperCase()));
      existingIds.add(questionId.toUpperCase());

      generatedBooleanQuestions.push({
        id: questionId,
        category: `${prompt.category}: ${area}`,
        text: questionText,
        type: 'boolean',
        options: { yes: 1, no: 0 },
        weight: Math.max(1, Number(prompt.weight || 3)),
        critical: Boolean(prompt.critical),
        required: Boolean(prompt.required),
        evidence: {
          photo: Boolean(prompt?.evidence?.photo),
          comment: prompt?.evidence?.comment !== false,
          signature: Boolean(prompt?.evidence?.signature),
        },
        showIf: null,
      });
    }

    if (premiumBooleanQuestions.length + generatedBooleanQuestions.length >= targetBooleanControlCount) {
      break;
    }
  }

  return [...premiumBooleanQuestions, ...generatedBooleanQuestions, ...nonBooleanQuestions];
}

function inflateAooTemplateCatalog(catalog = []) {
  return catalog.map((template) => {
    const expandedQuestions = inflateTemplateQuestions(template);
    const recalculatedMaxScore = expandedQuestions.reduce((total, question) => {
      return total + Number(question?.weight || 0);
    }, 0);
    const passPercent =
      Number(template?.passPercent) ||
      Math.round((Number(template?.passScore || 0) / Math.max(1, Number(template?.maxScore || 1))) * 100);
    const recalculatedPassScore = Math.ceil(Math.max(1, recalculatedMaxScore) * (passPercent / 100));
    const recalculatedCriticalQuestionIds = expandedQuestions
      .filter((question) => String(question?.type || '').toLowerCase() === 'boolean' && Boolean(question?.critical))
      .map((question) => String(question?.id || '').trim())
      .filter(Boolean);

    return {
      ...template,
      questions: expandedQuestions,
      maxScore: Math.max(1, recalculatedMaxScore),
      passScore: Math.max(1, Math.min(Math.max(1, recalculatedMaxScore), recalculatedPassScore)),
      passPercent,
      criticalQuestionIds:
        recalculatedCriticalQuestionIds.length > 0
          ? recalculatedCriticalQuestionIds
          : Array.isArray(template?.criticalQuestionIds)
            ? template.criticalQuestionIds
            : [],
    };
  });
}

export const aooTemplateCatalog = inflateAooTemplateCatalog(aooTemplateCatalogBase);

const onlyBooleanControls = (questions = []) => {
  const seen = new Set();
  return questions
    .filter((question) => String(question?.type || '').toLowerCase() === 'boolean')
    .map((question) => String(question.text || '').trim())
    .filter((questionText) => {
      if (!questionText) {
        return false;
      }
      const key = normalizeQuestionText(questionText);
      if (!key || seen.has(key)) {
        return false;
      }
      seen.add(key);
      return true;
    });
};

export const templateRegimeOptions = Array.from(
  new Set(aooTemplateCatalog.map((template) => String(template.regime || '').trim()).filter(Boolean))
);

export const templateCategoryOptions = [
  { value: 'HS', label: 'General H&S' },
  { value: 'FRA', label: 'FRA' },
  { value: 'LOLER', label: 'LOLER' },
  { value: 'PUWER', label: 'PUWER' },
  { value: 'PSSR', label: 'PSSR' },
  { value: 'COSHH', label: 'COSHH' },
  { value: 'ASBESTOS', label: 'Asbestos' },
  { value: 'LEGIONELLA', label: 'Legionella' },
  { value: 'ELECTRICAL', label: 'Electrical' },
  { value: 'SCAFFOLD', label: 'Scaffold' },
  { value: 'FOOD', label: 'Food Hygiene' },
  { value: 'WORKPLACE', label: 'Workplace' },
  { value: 'SUPPLEMENTAL', label: 'Supplemental' },
  { value: 'RA', label: 'Risk Assessment' },
  { value: 'RAMS', label: 'RAMS' },
];

export const defaultInspectionTemplates = aooTemplateCatalog.map((template, index) => ({
  id: `TPL-AOO-${String(index + 1).padStart(2, '0')}`,
  regime: template.regime,
  name: template.name,
  version: '1.0',
  active: true,
  controls: onlyBooleanControls(template.questions),
  sourceCoverage: template.sourceCoverage,
  templateId: template.templateId,
  passScore: template.passScore,
  maxScore: template.maxScore,
  visibility: 'global',
  ownerCompanyId: '',
  ownerCompanyName: '',
}));

export const defaultTemplateBlueprints = aooTemplateCatalog.map((template, index) => {
  const templateId = `TPLX-${String(index + 1).padStart(4, '0')}`;
  const publishedAt = `2026-02-${String(Math.min(28, 10 + index)).padStart(2, '0')}T08:00:00Z`;

  const mandatoryEvidenceBlocks = (template.questions || []).filter((question) => {
    if (!question || typeof question !== 'object') {
      return false;
    }
    const evidence = question.evidence || {};
    return Boolean(evidence.photo || evidence.comment || evidence.signature || question.required);
  }).length;

  const versions =
    templateId === 'TPLX-0001'
      ? [
          { version: '1.0', changelog: 'Initial release', publishedAt: '2026-02-01T08:00:00Z', hash: 'tplx0001v1' },
          {
            version: '1.1',
            changelog: 'Expanded with AOO source set coverage and mandatory evidence mappings',
            publishedAt,
            hash: 'tplx0001v11',
          },
        ]
      : [
          {
            version: '1.0',
            changelog: 'Built from AOO source pack (temps 1, 2, 3)',
            publishedAt,
            hash: `tplx${String(index + 1).padStart(4, '0')}v1`,
          },
        ];

  return {
    id: templateId,
    ownerOrgId: 'incert',
    name: template.name,
    category: template.category,
    schemaVersion: '1.0',
    scoringModel: template.scoringModel,
    licenceModel: template.licenceModel,
    status: 'published',
    currentVersion: templateId === 'TPLX-0001' ? '1.1' : '1.0',
    blockTypes: ['section', 'yes_no_na', 'single_select', 'risk_matrix', 'photo', 'action_trigger', 'signature'],
    mandatoryEvidenceBlocks,
    signatures: {
      auditorRequired: true,
      operatorRequired: template.category === 'FRA' || template.category === 'FOOD',
    },
    publishedAt,
    versions,
    sourceCoverage: template.sourceCoverage,
    regulatoryAnchors: template.regulatoryAnchors,
    retentionGuidance: template.retentionGuidance,
    passThreshold: {
      passScore: template.passScore,
      maxScore: template.maxScore,
      passPercent: template.passPercent,
      criticalQuestionIds: template.criticalQuestionIds,
    },
    autoActions: template.autoActions,
    schemaDefinition: aooFramework.templateSchema,
    pwaValidationRules: aooFramework.pwaValidationRules,
    checklistDesignRules: aooFramework.checklistDesignRules,
    workflowStages: aooFramework.workflowStages,
    sourceQuestionSetCounts: {
      source2: Array.isArray(template.source2Questions) ? template.source2Questions.length : 0,
      source3: Array.isArray(template.source3Questions) ? template.source3Questions.length : 0,
      merged: Array.isArray(template.questions) ? template.questions.length : 0,
    },
    questionBank: template.questions,
  };
});

export const defaultTemplateListings = aooTemplateCatalog.map((template, index) => ({
  id: `LST-${String(index + 1).padStart(4, '0')}`,
  templateId: `TPLX-${String(index + 1).padStart(4, '0')}`,
  priceModel: index <= 2 ? 'multi_use' : 'subscription',
  price: 99 + index * 25,
  currency: 'GBP',
  tags: [
    String(template.category || '').toLowerCase(),
    'aoo',
    ...(template.sourceCoverage.includes(3) ? ['expanded'] : ['source1']),
  ],
  previewAssets: Math.max(1, Math.floor((template.questions?.length || 1) / 3)),
  qualityRating: Number((4.6 + (index % 4) * 0.1).toFixed(1)),
  vettingTier: index <= 2 ? 'verified' : index <= 7 ? 'reviewed' : 'community',
  status: 'active',
}));
