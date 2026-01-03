# Research Proposal

## Enhanced Reliability and Performance Analysis of Satellite-Based Quantum Key Distribution Systems with Advanced Modulation and Retransmission Techniques

**Based on:** Nguyen et al. (2021) - "Reliability improvement of satellite-based quantum key distribution systems using retransmission scheme"

**Student:** [Your Name]
**Program:** Master Space - Earth Observation, Astrophysics, Satellite Technology
**Institution:** USTH / PTIT

---

## 1. Research Title

**"Enhanced Reliability and Performance Analysis of Satellite-Based Quantum Key Distribution Systems with Advanced Modulation and Retransmission Techniques"**

---

## 2. Executive Summary

This research proposal addresses the critical challenge of reliability in satellite-based Quantum Key Distribution (QKD) systems. Building upon the foundational work by Nguyen et al. (2021) from PTIT, this study aims to further develop, analyze, and potentially extend the QPSK-based QKD protocol with dual-threshold/heterodyne detection and key retransmission scheme for satellite-to-ground quantum communication links.

**Key Focus Areas:**
- Physical layer optimization (QPSK modulation + DT/HD receiver)
- Link layer reliability enhancement (ARQ retransmission)
- Analytical modeling (3-D Markov chain)
- Performance evaluation under realistic atmospheric conditions

---

## 3. Problem Statement

### 3.1 Background

Quantum Key Distribution (QKD) provides information-theoretic security based on the laws of quantum mechanics, making it fundamentally resistant to computational attacks including those from future quantum computers. While fiber-based QKD has achieved commercial deployment, its range is limited to ~400 km due to exponential signal attenuation.

Satellite-based QKD offers a solution for global-scale secure communication by exploiting:
- Lower atmospheric losses compared to fiber attenuation
- Vacuum of space with negligible photon absorption
- LEO satellite coverage for global key distribution

### 3.2 Technical Challenges

| Challenge | Impact | Current Solutions | Limitations |
|-----------|--------|-------------------|-------------|
| **Atmospheric Turbulence** | Random intensity fluctuations (scintillation), beam wander | Adaptive optics, spatial diversity | Complex, expensive |
| **Free-Space Path Loss** | >40 dB loss for LEO satellites | High-power transmitters, large apertures | Power limited on satellite |
| **Weather Effects** | Variable attenuation (0.1 - >10 dB/km) | Weather monitoring, link scheduling | Reduces availability |
| **Beam Spreading** | Reduced power collection efficiency | Narrow beam design, precise pointing | Tracking challenges |
| **QBER Degradation** | High error rates under turbulent conditions | FEC, error correction | Computational overhead |
| **Key Loss** | Failed transmissions, buffer overflow | FEC, retransmission | Not optimized for QKD |

### 3.3 Research Gap

Current approaches to reliability improvement in satellite QKD primarily rely on:
1. **Forward Error Correction (FEC):** Computationally expensive, fixed redundancy
2. **Adaptive modulation:** Complex to implement for quantum systems
3. **Spatial/temporal diversity:** Requires multiple receivers or extended passes

**The gap addressed by this research:**
- No systematic study of ARQ-based retransmission for satellite QKD
- Limited analysis of QPSK modulation combined with heterodyne detection for QKD
- Lack of analytical framework for Key Loss Rate (KLR) prediction

---

## 4. Research Objectives

### 4.1 Primary Objectives

**Objective 1: Design and Optimize QPSK-Based QKD Protocol**
- Develop phase encoding scheme based on BB84 principles
- Optimize dual-threshold decision levels for QBER/P_sift trade-off
- Characterize receiver sensitivity improvement with heterodyne detection

**Objective 2: Develop Key Retransmission Scheme**
- Design ARQ protocol adapted for quantum key transmission
- Determine optimal number of retransmissions (M) for different conditions
- Analyze latency vs. reliability trade-offs

**Objective 3: Create Analytical Framework**
- Derive QBER expressions incorporating all channel effects
- Develop 3-D Markov chain model for KLR analysis
- Validate analytical results against Monte Carlo simulations

### 4.2 Secondary Objectives

**Objective 4: Performance Evaluation**
- Analyze system under weak and strong turbulence conditions
- Evaluate weather impact on system reliability
- Compare with conventional schemes (SIM/BPSK, QPSK-DD)

**Objective 5: Security Analysis**
- Characterize security against unauthorized receiver attack
- Determine minimum Eve-Bob distance for secure operation
- Analyze information leakage under proposed scheme

---

## 5. Research Questions

| ID | Research Question | Methodology |
|----|-------------------|-------------|
| **RQ1** | How does QPSK modulation with heterodyne detection compare to conventional QKD schemes in terms of QBER and required transmitted power? | Analytical derivation + numerical simulation |
| **RQ2** | What is the optimal dual-threshold coefficient (varsigma) for different turbulence conditions to balance QBER and sifting probability? | Parameter sweep optimization |
| **RQ3** | How many retransmissions (M) are optimal to minimize KLR while limiting latency? | 3-D Markov chain analysis |
| **RQ4** | What are the security boundaries (Eve-Bob distance) under the proposed scheme? | Security analysis with URA model |
| **RQ5** | How does weather variability affect system reliability and what adaptive strategies are effective? | Multi-weather scenario simulation |

---

## 6. Methodology

### 6.1 Research Approach

```
+-------------------------------------------------------------------+
|                    RESEARCH METHODOLOGY                            |
+-------------------------------------------------------------------+
|                                                                    |
|  Phase 1: THEORETICAL FOUNDATION                                   |
|  +------------------+    +------------------+    +----------------+ |
|  | Literature       |    | Mathematical     |    | Channel Model  | |
|  | Review           |--->| Derivations      |--->| Development    | |
|  | (QKD, FSO, ATM)  |    | (QBER, KLR)      |    | (Gamma-Gamma)  | |
|  +------------------+    +------------------+    +----------------+ |
|           |                      |                      |          |
|           v                      v                      v          |
|  Phase 2: SYSTEM DESIGN                                            |
|  +------------------+    +------------------+    +----------------+ |
|  | QPSK Modulator   |    | DT/HD Receiver   |    | ARQ Protocol   | |
|  | Design           |--->| Optimization     |--->| Specification  | |
|  | (MZM config)     |    | (threshold)      |    | (Markov)       | |
|  +------------------+    +------------------+    +----------------+ |
|           |                      |                      |          |
|           v                      v                      v          |
|  Phase 3: IMPLEMENTATION                                           |
|  +------------------+    +------------------+    +----------------+ |
|  | MATLAB/Python    |    | Monte Carlo      |    | Validation     | |
|  | Simulation       |--->| Analysis         |--->| Against        | |
|  | Framework        |    |                  |    | Analytical     | |
|  +------------------+    +------------------+    +----------------+ |
|           |                      |                      |          |
|           v                      v                      v          |
|  Phase 4: ANALYSIS                                                 |
|  +------------------+    +------------------+    +----------------+ |
|  | Performance      |    | Security         |    | Comparative    | |
|  | Evaluation       |--->| Analysis         |--->| Study          | |
|  | (QBER, KLR)      |    | (URA, Eve)       |    | (vs. baseline) | |
|  +------------------+    +------------------+    +----------------+ |
|                                                                    |
+-------------------------------------------------------------------+
```

### 6.2 Phase Details

#### Phase 1: Theoretical Foundation (Months 1-3)

**Task 1.1: Literature Review**
- QKD protocols (BB84, CV-QKD, satellite demonstrations)
- FSO channel models (Gamma-Gamma, Hufnagel-Valley)
- Atmospheric effects on optical communication
- Error handling in quantum systems

**Task 1.2: Mathematical Framework**
- Derive QBER expression for QPSK-DT/HD
- Develop joint probability expressions
- Formulate noise variance model

**Task 1.3: Channel Model**
- Implement Hufnagel-Valley turbulence profile
- Model free-space loss, atmospheric attenuation
- Characterize beam spreading effects

**Deliverables:**
- D1.1: Literature review document
- D1.2: Mathematical derivation report
- D1.3: Channel model specification

#### Phase 2: System Design (Months 4-6)

**Task 2.1: QPSK Modulator Design**
- Specify MZM configuration for phase encoding
- Define Alice's bases (A1, A2) and phase states
- Establish bit-to-phase mapping

**Task 2.2: DT/HD Receiver Optimization**
- Design heterodyne detection circuit
- Optimize dual-threshold selection algorithm
- Characterize noise performance

**Task 2.3: ARQ Protocol Specification**
- Define key retransmission procedure
- Specify ACK/NACK signaling
- Design buffer management strategy

**Deliverables:**
- D2.1: System architecture document
- D2.2: Protocol specification
- D2.3: Parameter optimization guidelines

#### Phase 3: Analytical Framework (Months 7-9)

**Task 3.1: 3-D Markov Chain Model**
- Define state space (n, s, m)
- Derive transition probability matrix
- Solve balance equations

**Task 3.2: KLR Derivation**
- Calculate steady-state probabilities
- Derive KLR expression
- Validate against special cases

**Task 3.3: Simulation Implementation**
- Develop MATLAB/Python simulation framework
- Implement Monte Carlo validation
- Create visualization tools

**Deliverables:**
- D3.1: Analytical model documentation
- D3.2: Simulation code and documentation
- D3.3: Validation report

#### Phase 4: Numerical Analysis (Months 10-12)

**Task 4.1: Performance Evaluation**
- QBER vs. system parameters
- KLR vs. transmitted power and retransmissions
- Weather impact analysis

**Task 4.2: Security Analysis**
- Eve's QBER vs. distance
- Security boundary determination
- Information leakage quantification

**Task 4.3: Comparative Study**
- Comparison with SIM/BPSK-DT
- Comparison with QPSK-DT/DD
- Improvement quantification

**Deliverables:**
- D4.1: Numerical results and analysis
- D4.2: Comparative study report
- D4.3: Final thesis/publication manuscript

### 6.3 Tools and Resources

| Tool | Purpose | Availability |
|------|---------|--------------|
| MATLAB | Numerical simulation, visualization | Licensed at USTH |
| Python (NumPy, SciPy) | Alternative implementation | Open source |
| LaTeX | Document preparation | Open source |
| Git | Version control | Open source |
| Literature databases | Paper access | IEEE, Springer, arXiv |

---

## 7. Expected Contributions

### 7.1 Scientific Contributions

| Contribution | Type | Novelty | Impact |
|--------------|------|---------|--------|
| **C1:** QPSK-based QKD protocol with DT/HD detection | System Design | First integration | Improved receiver sensitivity (20 dB) |
| **C2:** Key retransmission scheme for satellite QKD | Protocol Innovation | Novel application of ARQ | Enhanced reliability (>1000x KLR reduction) |
| **C3:** 3-D Markov chain model for KLR analysis | Analytical Framework | New modeling approach | Enables performance prediction |
| **C4:** Comprehensive parameter optimization | Numerical Results | Detailed analysis | Practical design guidelines |

### 7.2 Practical Implications

1. **Design Guidelines:** Optimal parameter selection for satellite QKD systems
2. **Performance Benchmarks:** Quantitative metrics for system evaluation
3. **Security Boundaries:** Clear requirements for secure operation
4. **Vietnamese Context:** Foundation for future quantum satellite development

---

## 8. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Mathematical complexity | Medium | High | Seek expert guidance, use symbolic computation |
| Simulation convergence | Low | Medium | Validate against analytical results, use established methods |
| Limited experimental data | High | Medium | Use published Micius results for validation |
| Scope creep | Medium | High | Maintain focus on defined objectives, regular progress review |
| Time constraints | Medium | High | Prioritize core deliverables, maintain schedule flexibility |

---

## 9. Timeline

```
Month:  1   2   3   4   5   6   7   8   9  10  11  12
        |---|---|---|---|---|---|---|---|---|---|---|
Phase 1 [=========]
  T1.1  [===]
  T1.2      [===]
  T1.3          [===]
Phase 2         [=========]
  T2.1          [===]
  T2.2              [===]
  T2.3                  [===]
Phase 3                     [=========]
  T3.1                      [===]
  T3.2                          [===]
  T3.3                              [===]
Phase 4                                 [=========]
  T4.1                                  [===]
  T4.2                                      [===]
  T4.3                                          [===]

Milestones:
M1 (Month 3):  Literature review & mathematical framework complete
M2 (Month 6):  System design & protocol specification complete
M3 (Month 9):  Analytical framework & simulation validated
M4 (Month 12): Final analysis & thesis complete
```

---

## 10. Expected Outcomes

### 10.1 Publications

1. **Journal Paper:** IEEE Access or Photonic Network Communications
   - Title: "Enhanced Reliability Analysis of Satellite QKD with QPSK-DT/HD and Key Retransmission"
   - Target: Q1/Q2 journal

2. **Conference Paper:** IEEE ISCIT or similar
   - Preliminary results presentation

### 10.2 Thesis

- Master's thesis fulfilling USTH graduation requirements
- Comprehensive documentation of methodology and results

### 10.3 Knowledge Transfer

- Contribution to PTIT research group's expertise
- Foundation for future doctoral research
- Support for Vietnamese quantum communication development

---

## 11. Budget (Estimated)

| Item | Cost (VND) | Notes |
|------|------------|-------|
| Software licenses | 0 | MATLAB available, Python free |
| Literature access | 0 | Institutional subscription |
| Computing resources | 0 | University facilities |
| Conference travel | 5,000,000 | If presenting at ISCIT |
| Publication fees | 3,000,000 | Open access option |
| **Total** | **8,000,000** | |

---

## 12. References

[1] C. H. Bennett and G. Brassard, "Quantum cryptography: Public key distribution and coin tossing," in Proc. IEEE Int. Conf. Computers, Systems and Signal Processing, 1984.

[2] S.-K. Liao et al., "Satellite-to-ground quantum key distribution," Nature, vol. 549, pp. 43-47, 2017.

[3] N. D. Nguyen et al., "Reliability improvement of satellite-based quantum key distribution systems using retransmission scheme," Photonic Network Communications, vol. 42, pp. 53-64, 2021.

[4] V. Scarani et al., "The security of practical quantum key distribution," Rev. Mod. Phys., vol. 81, pp. 1301-1350, 2009.

[5] M. A. Al-Habash et al., "Mathematical model for the irradiance probability density function of a laser beam propagating through turbulent media," Optical Engineering, vol. 40, pp. 1554-1562, 2001.

[6] P. V. Trinh et al., "Design and security analysis of QKD protocol over free-space optics using dual-threshold/direct-detection," IEEE Access, vol. 6, pp. 4159-4175, 2018.

---

## 13. Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Student | | | |
| Supervisor | | | |
| Program Director | | | |

---

**Document Version:** 1.0
**Created:** December 2025
**Status:** DRAFT - For Review
