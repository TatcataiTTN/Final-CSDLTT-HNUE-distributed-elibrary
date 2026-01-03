# Literature Review Criteria

## For: Reliability Improvement of Satellite-Based QKD Systems

---

## 1. Overview

This document establishes the systematic criteria for conducting a comprehensive literature review on satellite-based Quantum Key Distribution (QKD) systems, with particular focus on reliability improvement techniques related to the work by Nguyen et al. (2021).

---

## 2. Search Strategy

### 2.1 Database Sources

| Database | Type | Priority | Access |
|----------|------|----------|--------|
| **IEEE Xplore** | Engineering/Communications | Primary | Institutional |
| **arXiv** | Preprints (quant-ph, physics.optics) | Primary | Open |
| **Nature Portfolio** | High-impact journals | Primary | Institutional |
| **Optica Publishing** | Optical engineering | Secondary | Institutional |
| **Springer** | Review articles | Secondary | Institutional |
| **Google Scholar** | Citation tracking | Supporting | Open |
| **Web of Science** | Impact metrics | Supporting | Institutional |

### 2.2 Search Terms and Boolean Queries

#### Primary Search Queries

```
Query 1: Satellite QKD Core
("satellite QKD" OR "satellite quantum key distribution" OR "space-to-ground QKD")
AND ("FSO" OR "free-space optical" OR "optical wireless")

Query 2: Atmospheric Effects
("atmospheric turbulence" OR "scintillation" OR "Gamma-Gamma")
AND ("quantum" OR "optical communication")
AND ("satellite" OR "space")

Query 3: CV-QKD Systems
("continuous variable QKD" OR "CV-QKD" OR "coherent state QKD")
AND ("heterodyne" OR "homodyne" OR "coherent detection")

Query 4: Error Handling
("error correction" OR "reconciliation" OR "ARQ" OR "retransmission")
AND ("QKD" OR "quantum cryptography")

Query 5: Vietnamese Research
("PTIT" OR "Vietnam" OR "Vietnamese")
AND ("QKD" OR "quantum key distribution" OR "FSO")
```

#### Secondary Search Queries

```
Query 6: Modulation Schemes
("QPSK" OR "BPSK" OR "phase shift keying")
AND ("quantum" OR "QKD")

Query 7: Detection Techniques
("dual threshold" OR "heterodyne detection" OR "APD")
AND ("FSO" OR "free-space" OR "satellite")

Query 8: Channel Models
("Hufnagel-Valley" OR "turbulence profile" OR "refractive index structure")
AND ("satellite" OR "optical link")

Query 9: Micius Satellite
("Micius" OR "Chinese quantum satellite")
AND ("QKD" OR "entanglement")

Query 10: Security Analysis
("quantum bit error rate" OR "QBER" OR "eavesdropping")
AND ("satellite" OR "FSO")
```

### 2.3 Citation Tracking

Starting from key papers, perform forward and backward citation analysis:

**Seed Papers:**
1. Bennett & Brassard (1984) - BB84 Protocol
2. Liao et al. (2017) - Micius QKD
3. Nguyen et al. (2021) - Reliability Improvement (PTIT)
4. Pirandola et al. (2020) - QKD Advances Review
5. Al-Habash et al. (2001) - Gamma-Gamma Model

---

## 3. Selection Criteria

### 3.1 Inclusion Criteria

| Criterion | Specification | Rationale |
|-----------|---------------|-----------|
| **Time Period** | 1984 - 2025 | From BB84 to present |
| **Publication Type** | Peer-reviewed journals, major conferences | Quality assurance |
| **Language** | English (Vietnamese with English abstract) | Accessibility |
| **Relevance** | Direct relation to satellite FSO/QKD | Focus |
| **Quality Threshold** | Impact factor > 2.0 OR citations > 50 | Significance |
| **Protocol Type** | DV-QKD, CV-QKD, hybrid | Comprehensive coverage |
| **Link Type** | Satellite-to-ground, ground-to-satellite | Primary focus |

### 3.2 Exclusion Criteria

| Criterion | Rationale |
|-----------|-----------|
| Purely theoretical quantum mechanics without practical application | Out of scope |
| Terrestrial-only FSO without satellite context | Not applicable |
| Non-peer-reviewed (except arXiv from major groups) | Quality control |
| Outdated technology (>20 years) without recent citations | Relevance |
| Non-optical quantum communication (RF, acoustic) | Different domain |
| Quantum computing (not communication) | Different field |

### 3.3 Quality Assessment Rubric

**Scoring: 1 (Low) to 5 (High)**

| Criterion | Weight | 5 | 4 | 3 | 2 | 1 |
|-----------|--------|---|---|---|---|---|
| **Relevance** | 25% | Direct satellite QKD | FSO/QKD general | Related optical comm. | Tangential | Marginal |
| **Methodology** | 20% | Rigorous experimental | Comprehensive simulation | Standard analysis | Limited analysis | Weak |
| **Validation** | 20% | Real satellite data | Lab experiment | Extensive simulation | Basic simulation | None |
| **Citation Impact** | 15% | >100 | 50-100 | 20-50 | 10-20 | <10 |
| **Recency** | 10% | <2 years | 2-5 years | 5-10 years | 10-15 years | >15 years |
| **Vietnamese Context** | 10% | PTIT/Vietnam direct | ASEAN region | East Asia | Global with relevance | Global general |

**Minimum Score for Inclusion:** 2.5 (weighted average)

---

## 4. Thematic Categories

### Category 1: Foundational QKD Protocols

**Scope:** Original QKD protocol designs and security proofs

**Key Topics:**
- BB84 protocol and variants
- E91 (entanglement-based) protocol
- Decoy state methods
- Security proofs and bounds

**Essential Papers:**
| Paper | Year | Contribution |
|-------|------|--------------|
| Bennett & Brassard | 1984 | BB84 protocol |
| Ekert | 1991 | E91 protocol |
| Gisin et al. | 2002 | QKD review |
| Scarani et al. | 2009 | Security analysis |
| Lo et al. | 2005 | Decoy states |

**Relevance to Nguyen 2021:** Provides protocol foundation for QPSK-based scheme

### Category 2: Continuous-Variable QKD

**Scope:** CV-QKD protocols using coherent/squeezed states

**Key Topics:**
- Gaussian modulation
- Coherent state protocols
- Heterodyne/homodyne detection
- Security analysis for CV systems

**Essential Papers:**
| Paper | Year | Contribution |
|-------|------|--------------|
| Grosshans et al. | 2003 | Gaussian CV-QKD |
| Leverrier | 2015 | CV security proof |
| Weedbrook et al. | 2012 | CV-QKD review |
| Dequal et al. | 2021 | Satellite CV-QKD feasibility |

**Relevance to Nguyen 2021:** Heterodyne detection methodology

### Category 3: Satellite QKD Experiments

**Scope:** Experimental demonstrations of satellite quantum communication

**Key Topics:**
- Micius satellite program
- Ground station design
- Link budget analysis
- Achieved key rates

**Essential Papers:**
| Paper | Year | Contribution |
|-------|------|--------------|
| Liao et al. | 2017 | First satellite QKD |
| Yin et al. | 2017 | 1200 km entanglement |
| Liao et al. | 2018 | Intercontinental QKD |
| Chen et al. | 2021 | Integrated network |

**Relevance to Nguyen 2021:** Validates satellite QKD feasibility, provides benchmark parameters

### Category 4: Atmospheric Channel Models

**Scope:** Turbulence modeling and characterization

**Key Topics:**
- Gamma-Gamma distribution
- Hufnagel-Valley profile
- Scintillation index
- Rytov variance

**Essential Papers:**
| Paper | Year | Contribution |
|-------|------|--------------|
| Al-Habash et al. | 2001 | Gamma-Gamma model |
| Andrews & Phillips | 2005 | Laser propagation textbook |
| Vasylyev et al. | 2016 | Quantum atmospheric channels |
| Ma et al. | 2015 | Satellite downlink coherent |

**Relevance to Nguyen 2021:** Core channel model adopted

### Category 5: FSO Link Budget and Design

**Scope:** System-level design for free-space optical links

**Key Topics:**
- Free-space loss
- Beam spreading
- Pointing errors
- Link availability

**Essential Papers:**
| Paper | Year | Contribution |
|-------|------|--------------|
| Kaushal & Kaddoum | 2017 | FSO challenges review |
| Farid & Hranilovic | 2007 | Pointing errors |
| Bonato et al. | 2009 | Satellite QKD feasibility |
| Toyoshima | 2021 | Space laser trends |

**Relevance to Nguyen 2021:** Loss mechanism modeling

### Category 6: Detection Technologies

**Scope:** Single-photon and coherent detection systems

**Key Topics:**
- APD characteristics
- SNSPD performance
- Heterodyne receivers
- Noise analysis

**Essential Papers:**
| Paper | Year | Contribution |
|-------|------|--------------|
| Miao et al. | 2005 | Background noise analysis |
| Sibson et al. | 2017 | Chip-based QKD |
| Tomamichel et al. | 2012 | Finite-key analysis |

**Relevance to Nguyen 2021:** DT/HD receiver design basis

### Category 7: Error Correction and Reconciliation

**Scope:** Post-processing techniques for QKD

**Key Topics:**
- CASCADE protocol
- LDPC codes
- Privacy amplification
- Finite-size effects

**Essential Papers:**
| Paper | Year | Contribution |
|-------|------|--------------|
| Brassard & Salvail | 1994 | CASCADE |
| Elkouss et al. | 2011 | LDPC for QKD |
| Tomamichel et al. | 2012 | Finite-key bounds |

**Relevance to Nguyen 2021:** Alternative to FEC via retransmission

### Category 8: Vietnamese/PTIT Research

**Scope:** Research from Vietnamese institutions

**Key Topics:**
- PTIT contributions
- Regional collaborations
- Vietnam space technology
- Local atmospheric conditions

**Essential Papers:**
| Paper | Year | Contribution |
|-------|------|--------------|
| Trinh et al. | 2018 | DT/DD for QKD |
| Nguyen et al. | 2021 | Retransmission scheme |
| Nguyen et al. | 2023 | CV-QKD optimization |

**Relevance to Nguyen 2021:** Direct context and prior work

---

## 5. Data Extraction Protocol

### 5.1 Extraction Form

For each included paper, extract:

```
================================================================================
PAPER EXTRACTION FORM
================================================================================

IDENTIFICATION
--------------
Paper_ID:          [Unique identifier, e.g., LIAO2017]
Title:             [Full title]
Authors:           [Author list]
Year:              [Publication year]
Venue:             [Journal/Conference]
DOI:               [Digital Object Identifier]
Access:            [Open/Institutional/Restricted]

CLASSIFICATION
--------------
Primary_Category:       [1-8 from above]
Secondary_Categories:   [List of additional relevant categories]
Quality_Score:          [Calculated from rubric]

CONTENT SUMMARY
---------------
Abstract_Summary:       [2-3 sentence summary]

Key_Contributions:
  1. [First contribution]
  2. [Second contribution]
  3. [Third contribution]

METHODOLOGY
-----------
Type:              [Theoretical/Simulation/Experimental/Hybrid]
Key_Techniques:    [List of methods used]
Validation:        [How results were validated]
Assumptions:       [Key assumptions made]

TECHNICAL DETAILS
-----------------
QKD_Protocol:      [BB84/E91/CV-QKD/Custom]
Modulation:        [Polarization/Phase/Amplitude/Gaussian]
Detection:         [SPD/Homodyne/Heterodyne/Direct]
Channel_Model:     [Log-normal/Gamma-Gamma/Other]
Link_Type:         [Uplink/Downlink/Both]

Key_Equations:
  - Equation 1: [Description]
  - Equation 2: [Description]

Key_Parameters:
  | Parameter | Value | Units |
  |-----------|-------|-------|
  | [Name]    | [Val] | [Unit]|

KEY_RESULTS
-----------
Quantitative_Results:
  - [Result 1 with numerical value]
  - [Result 2 with numerical value]

Performance_Metrics:
  - QBER: [Value if reported]
  - Key_Rate: [Value if reported]
  - Distance: [Value if reported]
  - Loss: [Value if reported]

CRITICAL ANALYSIS
-----------------
Strengths:
  1. [Strength 1]
  2. [Strength 2]

Limitations:
  1. [Limitation 1]
  2. [Limitation 2]

RELEVANCE TO NGUYEN 2021
------------------------
Connection_Points:
  - QPSK_Modulation: [Relevant/Not relevant]
  - Heterodyne_Detection: [Relevant/Not relevant]
  - Atmospheric_Model: [Relevant/Not relevant]
  - Retransmission: [Relevant/Not relevant]
  - Security_Analysis: [Relevant/Not relevant]

Specific_Connections:
  [Describe how this paper relates to Nguyen 2021]

NOTES
-----
Additional_Observations:
  [Any other relevant notes]

================================================================================
```

### 5.2 Synthesis Matrix

Create comparison matrix across papers:

| Paper | Year | Protocol | Detection | Channel | Error_Handling | Key_Result |
|-------|------|----------|-----------|---------|----------------|------------|
| [ID]  | YYYY | [Type]   | [Type]    | [Model] | [Method]       | [Metric]   |

---

## 6. Analysis Framework

### 6.1 Chronological Analysis

Track evolution of:
- Protocol development (1984 -> present)
- Experimental demonstrations (2015 -> present)
- Channel modeling advances
- Vietnamese research contributions

### 6.2 Thematic Synthesis

For each theme, identify:
1. **Consensus points:** What is generally agreed upon?
2. **Debates:** What remains contested?
3. **Gaps:** What is missing from the literature?
4. **Trends:** What are emerging directions?

### 6.3 Gap Analysis Matrix

| Research Area | Well-Studied | Partially Studied | Under-Studied | Nguyen 2021 Contribution |
|---------------|--------------|-------------------|---------------|--------------------------|
| [Area 1]      | [Topics]     | [Topics]          | [Topics]      | [Contribution]           |

### 6.4 Comparative Framework

**Comparison Dimensions:**

| Dimension | Options | Nguyen 2021 Choice |
|-----------|---------|-------------------|
| QKD Type | DV-QKD, CV-QKD | QPSK-based (CV-like) |
| Modulation | BPSK, QPSK, Gaussian | QPSK |
| Detection | Direct, Homodyne, Heterodyne | Heterodyne |
| Threshold | Single, Dual | Dual |
| Error Handling | FEC, ARQ, None | ARQ |
| Channel Model | Log-normal, Gamma-Gamma | Gamma-Gamma |
| Link Direction | Uplink, Downlink | Downlink |
| Validation | Theory, Simulation, Experiment | Simulation |

---

## 7. Reporting Structure

### 7.1 Literature Review Chapter Outline

```
Chapter X: Literature Review

X.1 Introduction
    X.1.1 Scope and Objectives
    X.1.2 Search Methodology
    X.1.3 Paper Selection Process

X.2 Foundational QKD Protocols
    X.2.1 BB84 Protocol
    X.2.2 Security Foundations
    X.2.3 Evolution and Variants

X.3 Continuous-Variable QKD
    X.3.1 Gaussian Modulation
    X.3.2 Coherent Detection Schemes
    X.3.3 Security Analysis

X.4 Satellite QKD Demonstrations
    X.4.1 Micius Satellite Program
    X.4.2 Key Achievements
    X.4.3 Lessons Learned

X.5 Atmospheric Channel Modeling
    X.5.1 Turbulence Characterization
    X.5.2 Gamma-Gamma Distribution
    X.5.3 Multi-Layer Models

X.6 Detection and Error Handling
    X.6.1 Detection Technologies
    X.6.2 FEC Approaches
    X.6.3 ARQ for QKD (Gap Identified)

X.7 Vietnamese Research Contributions
    X.7.1 PTIT Research Group
    X.7.2 Prior Work Context
    X.7.3 Regional Significance

X.8 Research Gaps and Opportunities
    X.8.1 Identified Gaps
    X.8.2 Nguyen 2021 Contributions
    X.8.3 Future Directions

X.9 Summary
```

### 7.2 Quality Metrics

Track during review process:
- Total papers screened: [N]
- Papers included: [N]
- Papers excluded: [N] (with reasons)
- Papers by category: [Distribution]
- Papers by year: [Distribution]
- Average quality score: [Value]

---

## 8. Tools and Templates

### 8.1 Reference Management

Use **Zotero** or **Mendeley** with:
- Consistent tagging by category
- PDF attachment storage
- BibTeX export for LaTeX

### 8.2 Data Management

- Excel/Google Sheets for extraction forms
- Synthesis matrices for comparison
- PRISMA flow diagram for selection process

### 8.3 Writing Tools

- LaTeX for final document
- Markdown for drafts
- Overleaf for collaboration

---

## 9. Timeline for Literature Review

| Week | Activity | Deliverable |
|------|----------|-------------|
| 1 | Database searches, initial screening | Search results log |
| 2 | Full-text review, quality assessment | Inclusion list |
| 3-4 | Data extraction (Categories 1-4) | Extraction forms |
| 5-6 | Data extraction (Categories 5-8) | Extraction forms |
| 7 | Synthesis and gap analysis | Synthesis matrix |
| 8 | Writing and revision | Draft chapter |

---

## 10. Checklist

### Pre-Review
- [ ] Define research questions clearly
- [ ] Set up reference management system
- [ ] Create extraction form template
- [ ] Obtain database access

### During Review
- [ ] Document all search queries and results
- [ ] Apply inclusion/exclusion criteria consistently
- [ ] Complete extraction form for each paper
- [ ] Track quality scores

### Post-Review
- [ ] Create synthesis matrices
- [ ] Identify gaps and opportunities
- [ ] Write summary of findings
- [ ] Connect to research objectives

---

**Document Version:** 1.0
**Created:** December 2025
**Purpose:** Systematic literature review methodology
