# UIL Number Sense Materials - Architecture

## Overview

The `uil_number_sense/` directory serves as an **archive and reference** for original UIL (University Interscholastic League) Number Sense test materials. It provides historical context and source material for data extraction, but is **not actively used by the app at runtime**.

---

## Directory Structure

```
uil_number_sense/
├── elementary/          # Elementary level test materials
├── middle_school/       # Middle school level test materials
└── high_school/         # High school level test materials
```

Each directory contains organized archives of UIL Number Sense tests by year and variant.

---

## Purpose & Role

| Component | Purpose |
|-----------|---------|
| **Storage** | Preserve original UIL test PDFs for historical reference |
| **Source** | Serve as source material for external **PDF extraction process** |
| **Validation** | Enable cross-checking extracted data against originals |
| **Archive** | Maintain complete audit trail for compliance/documentation |

---

## Relationship to Pipeline

```
uil_number_sense/ (PDFs - Source)
         │
         │ [External PDF Extraction Tool]
         │ (Not part of this project)
         │
         ▼
pipeline/extracted/ (JSON - Structured Data)
         │
         │ [build_db.py]
         │
         ▼
app/assets/db/questions.db (SQLite Database)
         │
         ▼
Flutter App (Runtime)
```

**Key Point**: The pipeline **does not** directly process files from `uil_number_sense/`. Instead, extracted JSON files in `pipeline/extracted/` are the pipeline's input.

---

## Expected Contents

### Elementary Level
- UIL Number Sense test papers for elementary school
- Organized by year (2020-2025 ideally)
- Each year typically has variants (A, B, C)

### Middle School
- UIL Number Sense test papers for middle school
- Same organizational structure as elementary

### High School
- UIL Number Sense test papers for high school (advanced level)
- Same organizational structure as elementary

---

## File Organization Standards

```
uil_number_sense/
├── elementary/
│   ├── 2023_test_a.pdf
│   ├── 2023_test_b.pdf
│   ├── 2023_test_c.pdf
│   ├── 2024_test_a.pdf
│   ├── 2024_test_b.pdf
│   ├── 2024_test_c.pdf
│   └── ...
├── middle_school/
│   └── [Same structure]
└── high_school/
    └── [Same structure]
```

**Naming Convention**: `{YEAR}_test_{VARIANT}.pdf`
- `YEAR`: Integer (2020, 2021, ..., 2025)
- `VARIANT`: Single letter (a, b, or c)

---

## Data Extraction Workflow

### Step 1: Extract PDFs
**Tool**: External PDF extraction software
**Input**: `uil_number_sense/{level}/{year}_test_{variant}.pdf`
**Output**: JSON structure
**Process**:
```
1. Parse PDF pages
2. Identify problems (numbered 1-30 typically)
3. Extract problem statement (LaTeX format preferred)
4. Extract answer
5. Identify approximate/exact answer requirement
6. Output structured JSON
```

### Step 2: Generate JSON
**Format**: See [`pipeline/ARCHITECTURE.md`](../pipeline/ARCHITECTURE.md#extracted-data-pipelineextracted) for schema

**Output Path**: `pipeline/extracted/{level}/{year}_test_{variant}.json`

**Example**:
```json
{
  "source": {
    "school_level": "elementary",
    "year": 2024,
    "test": "a",
    "pdf_source": "uil_number_sense/elementary/2024_test_a.pdf"
  },
  "questions": [
    {
      "n": 1,
      "latex": "\\text{What is } 12 \\times 11?",
      "answer": "132",
      "approx": false,
      "category": "1.2.1"  ← Link to trick ID
    }
  ]
}
```

### Step 3: Link & Validate
- Map problem categories to trick IDs in `pipeline/taxonomy/tricks.json`
- Verify all referenced tricks exist
- Cross-check with original PDFs for accuracy

### Step 4: Build Database
```bash
cd pipeline
python build_db.py
```
See [`pipeline/ARCHITECTURE.md`](../pipeline/ARCHITECTURE.md#build-process-build_dbpy) for details.

---

## Maintenance & Updates

### Annual Update Cycle (Recommended)

| Quarter | Activity |
|---------|----------|
| **Q1** | New test results released; download and archive |
| **Q2** | Extract PDF → JSON; validate categories |
| **Q3** | Build updated database; test app |
| **Q4** | Release app update with new data |

### Adding New Tests
1. Download official UIL Number Sense tests
2. Place in appropriate directory: `uil_number_sense/{level}/{year}_test_{variant}.pdf`
3. Follow extraction workflow above
4. Commit to git with descriptive commit message

### Versioning & Releases
- Tag releases: `v1.0_2024_data`, `v1.1_2025_data`
- Keep git history for audit trail
- Archive old PDFs to separate backup location if storage is limited

---

## Reference & Documentation

### Official Resources
- **UIL Website**: https://www.uiltexas.org/ (official tests)
- **Number Sense**: Test rules, sample problems, preparation materials
- **Archives**: Historical test papers (typically public)

### Internal Documentation
- [`ARCHITECTURE.md`](../ARCHITECTURE.md) - System overview
- [`pipeline/ARCHITECTURE.md`](../pipeline/ARCHITECTURE.md) - Data pipeline details
- [`app/ARCHITECTURE.md`](../app/ARCHITECTURE.md) - App architecture

---

## Quality Assurance

### Verification Checklist Before Release
- [ ] All PDFs present for current test cycle
- [ ] Extraction process completed without errors
- [ ] JSON structure validated
- [ ] All trick categories match `taxonomy/tricks.json`
- [ ] Database builds successfully
- [ ] App queries run without errors
- [ ] Results sample-checked for accuracy
- [ ] Version/release notes updated

---

## Known Limitations & Notes

| Limitation | Impact |
|-----------|--------|
| **PDF Format Variability** | Extraction tool must handle OCR/scanned PDFs vs digital PDFs |
| **LaTeX Conversion** | Manual review needed to ensure correct LaTeX representation |
| **Historical Data** | Older tests may have different problem formats |
| **Storage Size** | PDFs can be large; consider archival for pre-2020 tests |
| **Copyright** | UIL tests are copyrighted; use only for authorized purposes |

---

## Quick Reference

| Item | Location | Details |
|------|----------|---------|
| **Elementary Tests** | `elementary/` | Grades 1-5 approximate |
| **Middle School Tests** | `middle_school/` | Grades 6-8 approximate |
| **High School Tests** | `high_school/` | Grades 9-12 |
| **Extracted Data** | `../pipeline/extracted/` | JSON input for pipeline |
| **Pipeline Script** | `../pipeline/build_db.py` | Builds database from extracted data |
| **Output Database** | `../app/assets/db/questions.db` | Production app database |

---

## Troubleshooting

### Problem: PDF extraction produces incomplete data
**Possible Causes**:
- PDF is image/scanned (requires OCR)
- PDF format not standard
- LaTeX formulas not recognized

**Solution**:
1. Manually review PDF
2. Adjust extraction tool settings
3. Consider manual transcription if critical problem

### Problem: Extracted JSON has wrong categories
**Cause**: Problem mapped to incorrect trick ID

**Solution**:
1. Verify correct trick ID in `pipeline/taxonomy/tricks.json`
2. Update JSON manually if needed
3. Re-run `pipeline/build_db.py`

### Problem: Database build fails due to missing PDFs
**Cause**: Expected PDF not present in this directory

**Solution**:
1. Check directory structure matches naming convention
2. Verify file permissions
3. Re-download/copy missing PDFs

---

## Summary

The `uil_number_sense/` directory is a **reference archive** that:
- ✅ Stores original UIL test materials for validation and audit
- ✅ Serves as source for manual extraction to JSON
- ✅ Maintains historical record for future analysis
- ❌ Does NOT directly power the app (extracted data does)
- ❌ Does NOT require runtime access (archived)

**Key Takeaway**: Keep this directory organized and maintained as a **single source of truth** for original test data. All processing happens downstream in the pipeline.

