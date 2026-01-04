# Detailed Analysis: Reliability Improvement of Satellite-Based QKD Systems Using Retransmission Scheme

**Paper:** Nguyen et al. (2021) - Photonic Network Communications
**DOI:** 10.1007/s11107-021-00934-y
**Authors:** Nam D. Nguyen, Hang T. T. Phan, Hien T. T. Pham, Vuong V. Mai, Ngoc T. Dang
**Institution:** Posts and Telecommunications Institute of Technology (PTIT), Vietnam

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Detailed Paper Overview](#2-detailed-paper-overview)
3. [Research Proposal Framework](#3-research-proposal-framework)
4. [Literature Review Criteria](#4-literature-review-criteria)
5. [Comprehensive Literature Review](#5-comprehensive-literature-review)
6. [Critical Analysis](#6-critical-analysis)
7. [Future Research Directions](#7-future-research-directions)

---

## 1. Executive Summary

### 1.1 Core Problem Addressed

The paper addresses the fundamental challenge of **reliability in satellite-based Quantum Key Distribution (QKD)** systems. Despite the theoretical promise of QKD for unconditional security, practical satellite-to-ground quantum communication faces severe performance degradation due to:

- **Atmospheric turbulence** causing signal fading
- **Free-space path loss** over long distances (600+ km)
- **Weather-dependent attenuation**
- **Beam spreading** and pointing errors
- **Receiver noise** affecting detection accuracy

### 1.2 Key Innovations

| Innovation | Description | Impact |
|------------|-------------|--------|
| **QPSK-based QKD Protocol** | Optical Quadrature Phase-Shift Keying modulation for key encoding | Higher spectral efficiency than BPSK |
| **Dual-Threshold/Heterodyne Detection (DT/HD)** | Two-threshold decision with heterodyne receiver | 20 dB improvement in receiver sensitivity |
| **Key Retransmission Scheme** | ARQ-based protocol at link layer | Significant KLR reduction |
| **3-D Markov Chain Model** | Novel analytical framework | Enables KLR performance analysis |

### 1.3 Quantitative Results

- **QBER Improvement:** Achieves QBER < 10^-3 with proper DT coefficient selection
- **Power Gain:** 20 dB reduction in required transmitted power vs. SIM/BPSK-DT
- **KLR Reduction:**
  - M=1 retransmission: 10x improvement
  - M=4 retransmissions: >1000x improvement
- **Security Distance:** Eve must be >30m from Bob to maintain security (QBER_Eve > 10^-2)

---

## 2. Detailed Paper Overview

### 2.1 System Architecture

```
+-------------------------------------------------------------------------+
|                           LINK LAYER                                     |
|  +------------------+                         +------------------+        |
|  |  Key             | <----- ACK/NACK ------- |  Key             |        |
|  |  Retransmission  |                         |  Retransmission  |        |
|  +--------+---------+                         +--------+---------+        |
+-----------|--------------------------------------------|------------------+
            |              PHYSICAL LAYER                |
  +---------v---------+                         +--------v---------+
  |   ALICE           |                         |     BOB          |
  |   (Satellite)     |                         |  (Ground Station)|
  |                   |                         |                  |
  |  +-------------+  |      FSO Channel        |  +--------------+|
  |  |Key          |  |                         |  |Photo         ||
  |  |Generator    |  |                         |  |Detector      ||
  |  +------+------+  |                         |  +------+-------+|
  |         v         |   Losses:               |         v        |
  |  +-------------+  |   - Free-space (L_FS)   |  +--------------+|
  |  |Buffer       |  |   - Atmospheric (h_a)   |  |Coupler +     ||
  |  +------+------+  |   - Beam spread (h_l)   |  |Local         ||
  |         v         |   - Turbulence (h_f)    |  |Oscillator    ||
  |  +-------------+  |                         |  +------+-------+|
  |  |QPSK         |--+------------------------>|         v        |
  |  |Modulator    |  |                         |  +--------------+|
  |  |(MZM)        |  |                         |  |BPF + LPF     ||
  |  +-------------+  |                         |  +------+-------+|
  |                   |                         |         v        |
  |  Bases: A1, A2    |                         |  +--------------+|
  |  phi_A in {pi/4,  |                         |  |Dual          ||
  |  3pi/4, 5pi/4,    |                         |  |Threshold     ||
  |  -pi/4}           |                         |  |Detection     ||
  |                   |                         |  +------+-------+|
  +-------------------+                         |         v        |
                                                |  Output: 0, 1, X |
                                                +------------------+
```

### 2.2 QPSK-Based QKD Protocol (Based on BB84)

#### 2.2.1 Phase Encoding Table

| Alice | Bit | phi_1 | phi_2 | phi_A | Bob | phi_B | phi_A - phi_B | Current | Detected Bit |
|-------|-----|-------|-------|-------|-----|-------|---------------|---------|--------------|
| A1 | 0 | 0 | pi/2 | pi/4 | B1 | pi/4 | 0 | I0 | 0 |
| A1 | 0 | 0 | pi/2 | pi/4 | B2 | -pi/4 | pi/2 | 0 | X (discard) |
| A1 | 1 | pi | 3pi/2 | 5pi/4 | B1 | pi/4 | pi | I1 | 1 |
| A1 | 1 | pi | 3pi/2 | 5pi/4 | B2 | -pi/4 | -pi/2 | 0 | X (discard) |
| A2 | 0 | 0 | -pi/2 | -pi/4 | B1 | pi/4 | -pi/2 | 0 | X (discard) |
| A2 | 0 | 0 | -pi/2 | -pi/4 | B2 | -pi/4 | 0 | I0 | 0 |
| A2 | 1 | pi | pi/2 | 3pi/4 | B1 | pi/4 | pi/2 | 0 | X (discard) |
| A2 | 1 | pi | pi/2 | 3pi/4 | B2 | -pi/4 | pi | I1 | 1 |

#### 2.2.2 Protocol Steps

1. **Key Encoding (Alice):**
   - Random base selection (A1 or A2)
   - Phase modulation via dual MZM: phi_A = (phi_1 + phi_2)/2
   - Optical carrier: E_T = sqrt(P_T * G_T) * exp[-i(2*pi*f_c*t + phi_A)]

2. **Transmission:**
   - FSO channel with combined losses
   - Received power: P_R = (1/L_FS) * G_T * P_T * h_a * h_l * h_f(t) * G_R

3. **Detection (Bob):**
   - Random base selection (B1 or B2)
   - Heterodyne mixing with LO
   - Dual-threshold decision: 0 if i >= d0, 1 if i <= d1, X otherwise

4. **Sifting:**
   - Bob announces detection times (not values)
   - Alice discards bits where Bob detected "X"
   - ~50% of bits remain as sifted key

### 2.3 Channel Model - Mathematical Framework

#### 2.3.1 Free-Space Loss

```
L_FS = (4*pi*D_S / lambda)^2
```

Where:
- D_S = (H_S - H_beta) / cos(zeta) : Free-space propagation distance
- H_S = 600 km : Satellite altitude
- H_beta = 20 km : Atmospheric altitude threshold
- zeta = 50 deg : Zenith angle
- lambda = 1550 nm : Wavelength

#### 2.3.2 Atmospheric Attenuation (Beer-Lambert Law)

```
h_a = exp(-gamma * D_beta)
```

Where:
- gamma : Weather-dependent attenuation coefficient (dB/km)
  - Very clear: 0 <= gamma <= 0.5
  - Light rain/mist: 0.5 <= gamma <= 1.53
  - Haze/medium rain: 1.54 <= gamma <= 2.68
- D_beta = (H_beta - H_G) / cos(zeta) : Atmospheric propagation distance

#### 2.3.3 Beam Spreading Loss

```
h_l(r; D_SG) = A0 * exp(-2*r^2 / omega_Deq^2)
```

Where:
- omega_D = 50 m : Beam width at ground station
- A0 = [erf(v)]^2 : Fraction of collected power at r=0
- v = sqrt(pi) * a / (sqrt(2) * omega_D)
- a = 0.31 m : Detection aperture radius

#### 2.3.4 Atmospheric Turbulence (Gamma-Gamma Distribution)

```
f_hf(h_f) = [2*K_{alpha-beta}(2*sqrt(alpha*beta*h_f)) * (alpha*beta)^((alpha+beta)/2)]
            / [Gamma(alpha)*Gamma(beta)] * h_f^((alpha+beta)/2 - 1)
```

**Rytov Variance:**
```
sigma_R^2 = 2.25 * k^(7/6) * sec(zeta)^(11/6) * integral[H_G to H_beta] C_n^2(h)*(h - H_G)^(5/6) dh
```

**Hufnagel-Valley Model:**
```
C_n^2(h) = 0.00594*(w/27)^2 * (10^-5 * h)^10 * exp(-h/1000)
           + 2.7e-16 * exp(-h/1500)
           + C_n^2(0) * exp(-h/100)
```

Where:
- Weak turbulence: C_n^2(0) = 5e-15
- Strong turbulence: C_n^2(0) = 7e-12
- w = 21 m/s : Wind speed

### 2.4 Performance Metrics

#### 2.4.1 Quantum Bit Error Rate (QBER)

```
QBER = P_error / P_sift
```

Where:
```
P_error = P_{A,B}(0,1) + P_{A,B}(1,0)
P_sift = P_{A,B}(0,0) + P_{A,B}(0,1) + P_{A,B}(1,0) + P_{A,B}(1,1)
```

Joint probabilities:
```
P_{A,B}(a,0) = (1/2) * integral[0 to inf] Q((d0 - I_a)/sigma_n) * f_hf(h_f) dh_f
P_{A,B}(a,1) = (1/2) * integral[0 to inf] Q((I_a - d1)/sigma_n) * f_hf(h_f) dh_f
```

#### 2.4.2 Dual-Threshold Selection

```
d0 = E[i0] + varsigma * sqrt(sigma_n^2)
d1 = E[i1] - varsigma * sqrt(sigma_n^2)
```

Where varsigma is the DT scale coefficient:
- Weak turbulence: 0.7 <= varsigma <= 2.4
- Strong turbulence: 1.4 <= varsigma <= 2.8

#### 2.4.3 Noise Variance

```
sigma_n^2 = 2*q*g_bar^(2+x)*[R*(P_R + P_LO) + I_d]*Delta_f + (4*k_B*T / R_L)*Delta_f
```

### 2.5 Link Layer - Key Retransmission Scheme

#### 2.5.1 Quantum Key Error Rate (QKER)

```
QKER = 1 - (1 - QBER)^(l_bs * P_sift)
```

Where l_bs = 3e6 bits : Length of bit sequence

#### 2.5.2 Channel State Transition Probabilities

```
p_BB = QKER * (1 - tau_bs/tau_0)
p_GG = (1 - QKER) * (1 - tau_bs/tau_0)
p_BG = 1 - p_BB
p_GB = 1 - p_GG
```

Where:
- tau_bs = l_bs / R_b : Time slot duration
- tau_0 = sqrt(lambda*D_beta / w) : Turbulence coherent time

#### 2.5.3 3-D Markov Chain Model

States: (n, s, m) where:
- n in [0, C] : Buffer queue length
- s in {B, G} : Channel state (Bad/Good)
- m in [1, M] : Retransmission attempt number

**Key Loss Rate:**
```
KLR = Sum_{s in {B,G}} Sum_{m=0}^M pi(C,s,m) + Sum_{n=0}^{C-1} pi(n,B,M)
```

### 2.6 System Parameters

| Parameter | Symbol | Value |
|-----------|--------|-------|
| **Physical Constants** | | |
| Electron charge | q | 1.6e-19 C |
| Boltzmann constant | k_B | 1.38e-23 W/K/Hz |
| **Receiver Parameters** | | |
| Bit rate | R_b | 10 Gbps |
| Load resistor | R_L | 50 Ohm |
| Excess noise factor | x | 0.8 (InGaAs APD) |
| Avalanche multiplication | g_bar | 10 |
| Responsivity | R | 0.8 |
| Temperature | T | 298 K |
| Dark current | I_d | 3 nA |
| **Channel Parameters** | | |
| Wavelength | lambda | 1550 nm |
| Satellite altitude | H_S | 600 km |
| Ground station height | H_G | 5 m |
| Atmospheric altitude | H_beta | 20 km |
| Zenith angle | zeta | 50 deg |
| Wind speed | w | 21 m/s |
| Beam width | omega_D | 50 m |
| Aperture radius | a | 0.31 m |
| Tx telescope gain | G_T | 120 dB |
| Rx telescope gain | G_R | 121 dB |
| **Link Layer Parameters** | | |
| Flow throughput | H | 185 seq/s |
| Bit sequence length | l_bs | 3e6 bits |

---

## 3. Research Proposal Framework

### 3.1 Research Title

**"Enhanced Reliability and Performance Analysis of Satellite-Based Quantum Key Distribution Systems with Advanced Modulation and Retransmission Techniques"**

### 3.2 Research Background

#### 3.2.1 Problem Statement

Satellite-based QKD systems face fundamental reliability challenges:

1. **Physical Layer Challenges:**
   - Atmospheric turbulence causes random intensity fluctuations (scintillation)
   - Free-space path loss exceeds 40 dB for LEO satellites
   - Pointing errors reduce collected power
   - Background noise degrades signal-to-noise ratio

2. **Protocol Challenges:**
   - ~50% key loss during sifting process (inherent to BB84-like protocols)
   - QBER increases under turbulent conditions
   - Error correction cannot handle arbitrarily high error rates
   - FEC adds computational overhead and reduces efficiency

3. **System Challenges:**
   - Limited satellite pass duration (~10 minutes for LEO)
   - Variable channel conditions within single pass
   - Need for real-time adaptation
   - Trade-off between security and key generation rate

### 3.3 Research Objectives

#### Primary Objectives:

1. **Design and optimize a QPSK-based QKD protocol** that:
   - Reduces QBER compared to conventional schemes
   - Improves receiver sensitivity via heterodyne detection
   - Adapts threshold levels to channel conditions

2. **Develop a key retransmission scheme** that:
   - Compensates for transmission failures
   - Operates without complex FEC
   - Minimizes latency while maximizing reliability

3. **Create analytical framework** for:
   - QBER prediction under various atmospheric conditions
   - KLR analysis using Markov chain modeling
   - Optimization of system parameters

#### Secondary Objectives:

4. Validate system performance under:
   - Weak and strong turbulence conditions
   - Various weather scenarios
   - Different transmitted power levels

5. Analyze security against unauthorized receiver attack (URA)

### 3.4 Research Methodology

#### Phase 1: Theoretical Foundation (Months 1-3)
- Literature review of QKD protocols and FSO channel models
- Mathematical derivation of QBER expressions
- Development of channel model incorporating all loss mechanisms

#### Phase 2: System Design (Months 4-6)
- QPSK modulator design with MZM configuration
- DT/HD receiver optimization
- Retransmission protocol specification

#### Phase 3: Analytical Framework (Months 7-9)
- 3-D Markov chain model development
- Balance equation solution methodology
- KLR derivation and validation

#### Phase 4: Numerical Analysis (Months 10-12)
- MATLAB/Python simulation implementation
- Parameter optimization studies
- Comparative performance analysis

### 3.5 Expected Contributions

| Contribution | Type | Impact |
|--------------|------|--------|
| QPSK-based QKD protocol with DT/HD | System Design | Improved receiver sensitivity |
| Key retransmission scheme | Protocol Innovation | Enhanced reliability |
| 3-D Markov chain for KLR analysis | Analytical Framework | Enables performance prediction |
| Comprehensive parameter optimization | Numerical Results | Practical design guidelines |

### 3.6 Research Questions

**RQ1:** How does QPSK modulation with heterodyne detection compare to conventional QKD schemes in terms of QBER and required transmitted power?

**RQ2:** What is the optimal dual-threshold coefficient for different turbulence conditions to balance QBER and sifting probability?

**RQ3:** How many retransmissions are optimal to minimize KLR while limiting latency?

**RQ4:** What are the security boundaries (Eve-Bob distance) under the proposed scheme?

---

## 4. Literature Review Criteria

### 4.1 Paper Selection Criteria

#### 4.1.1 Inclusion Criteria

| Criterion | Specification |
|-----------|---------------|
| **Time Period** | 1984 (BB84 protocol) to 2025 |
| **Publication Type** | Peer-reviewed journals, major conferences |
| **Language** | English (Vietnamese with English abstract) |
| **Relevance** | Direct relation to satellite FSO/QKD |
| **Quality** | Impact factor > 2.0 or citation count > 50 |

#### 4.1.2 Exclusion Criteria

| Criterion | Rationale |
|-----------|-----------|
| Purely theoretical quantum mechanics | Lacks practical application |
| Terrestrial-only FSO | Not applicable to satellite context |
| Non-peer-reviewed (except major arXiv preprints) | Quality assurance |
| Outdated technology (>20 years without citations) | Relevance |

### 4.2 Thematic Categories

#### Category 1: Foundational QKD Protocols
**Search Terms:** "BB84", "E91", "QKD protocol", "quantum cryptography"
**Key Papers:** Bennett & Brassard (1984), Ekert (1991), Gisin et al. (2002)
**Focus:** Theoretical foundations, security proofs

#### Category 2: Continuous-Variable QKD
**Search Terms:** "CV-QKD", "Gaussian modulation", "coherent states"
**Key Papers:** Grosshans et al. (2003), Leverrier (2015)
**Focus:** Protocol variants, security analysis

#### Category 3: Satellite QKD Experiments
**Search Terms:** "Micius satellite", "satellite QKD", "space-to-ground"
**Key Papers:** Liao et al. (2017), Yin et al. (2017, 2020)
**Focus:** Experimental results, system parameters

#### Category 4: Atmospheric Channel Models
**Search Terms:** "Gamma-Gamma", "Hufnagel-Valley", "atmospheric turbulence", "scintillation"
**Key Papers:** Al-Habash et al. (2001), Vasylyev et al. (2016)
**Focus:** Turbulence modeling, fading statistics

#### Category 5: FSO Link Budget
**Search Terms:** "free-space optical", "link budget", "pointing error", "beam spreading"
**Key Papers:** Kaushal & Kaddoum (2017), Farid & Hranilovic (2007)
**Focus:** Loss mechanisms, system design

#### Category 6: Detection and Error Correction
**Search Terms:** "single-photon detector", "heterodyne detection", "error correction QKD"
**Key Papers:** Tomamichel et al. (2012), Sibson et al. (2017)
**Focus:** Detection technologies, finite-key analysis

#### Category 7: Vietnamese Research Contributions
**Search Terms:** "PTIT", "Vietnam QKD", "Ngoc Dang"
**Key Papers:** Nguyen et al. (2021, 2023), Trinh et al. (2018)
**Focus:** Local research context

#### Category 8: Review Articles
**Search Terms:** "QKD review", "satellite quantum communication survey"
**Key Papers:** Pirandola et al. (2020), Bedington et al. (2017)
**Focus:** State-of-the-art synthesis

### 4.3 Quality Assessment Matrix

| Criterion | Weight | Scoring (1-5) |
|-----------|--------|---------------|
| Relevance to satellite QKD | 25% | Direct=5, Related=3, Tangential=1 |
| Methodological rigor | 20% | Rigorous=5, Standard=3, Weak=1 |
| Experimental validation | 20% | Comprehensive=5, Partial=3, None=1 |
| Citation impact | 15% | >100=5, 50-100=4, 20-50=3, 10-20=2, <10=1 |
| Recency | 10% | <2yr=5, 2-5yr=4, 5-10yr=3, >10yr=2 |
| Vietnamese context | 10% | Direct=5, ASEAN=3, Global=1 |

### 4.4 Data Extraction Template

For each paper reviewed:

```
PAPER_ID: [Unique identifier]
TITLE: [Full title]
AUTHORS: [Author list]
YEAR: [Publication year]
JOURNAL/CONFERENCE: [Venue]
DOI: [Digital Object Identifier]

CATEGORY: [Primary thematic category]
SECONDARY_CATEGORIES: [Additional relevant categories]

ABSTRACT_SUMMARY: [2-3 sentences]

KEY_CONTRIBUTIONS:
1. [Contribution 1]
2. [Contribution 2]
3. [Contribution 3]

METHODOLOGY:
- Theoretical/Experimental/Simulation
- Key techniques used
- Validation approach

RELEVANT_EQUATIONS:
- [Equation 1 with explanation]
- [Equation 2 with explanation]

KEY_RESULTS:
- [Quantitative result 1]
- [Quantitative result 2]

LIMITATIONS:
- [Limitation 1]
- [Limitation 2]

RELEVANCE_TO_NGUYEN_2021:
- Connection to QPSK modulation
- Connection to atmospheric modeling
- Connection to retransmission schemes

QUALITY_SCORE: [Calculated from matrix]

NOTES: [Additional observations]
```

### 4.5 Synthesis Framework

#### 4.5.1 Comparison Dimensions

| Dimension | Sub-categories |
|-----------|----------------|
| **QKD Type** | DV-QKD, CV-QKD, Hybrid |
| **Modulation** | BPSK, QPSK, Gaussian, Polarization |
| **Detection** | Direct, Homodyne, Heterodyne |
| **Channel Model** | Log-normal, Gamma-Gamma, Negative exponential |
| **Error Handling** | FEC, ARQ, Hybrid |
| **Link Type** | Uplink, Downlink, Bidirectional |
| **Validation** | Simulation only, Experimental, Deployed |

#### 4.5.2 Gap Analysis Framework

For each research area, identify:
1. What has been well-studied?
2. What contradictions exist in the literature?
3. What remains unexplored?
4. How does Nguyen et al. (2021) address these gaps?

---

## 5. Comprehensive Literature Review

### 5.1 Introduction

This literature review provides a comprehensive analysis of satellite-based Quantum Key Distribution (QKD) systems, with particular focus on the reliability improvement techniques proposed by Nguyen et al. (2021). The review synthesizes research across multiple domains: foundational QKD protocols, atmospheric channel modeling, detection technologies, and Vietnamese research contributions.

### 5.2 Foundational QKD Protocols

#### 5.2.1 The BB84 Protocol

The seminal work by Bennett and Brassard (1984) established the foundation for all subsequent QKD research. The BB84 protocol encodes key bits using four non-orthogonal quantum states:

**Key Properties:**
- Two conjugate bases (rectilinear and diagonal)
- Four polarization states: |H>, |V>, |+>, |->
- ~50% key loss during sifting (basis mismatch)
- Security guaranteed by quantum no-cloning theorem

**Relevance to Nguyen et al. (2021):**
The QPSK-based protocol directly maps the four BB84 polarization states to four phase states of optical carrier, enabling similar security properties with improved detection characteristics.

#### 5.2.2 Security Foundations

Scarani et al. (2009) provided comprehensive security analysis establishing:

1. **Information-theoretic security:** Eve's information bounded by QBER
2. **Privacy amplification:** Compression ratio determined by error rate
3. **Finite-key effects:** Security degradation for short keys
4. **Composable security:** Real-world protocol composition

**Critical threshold:** QBER < 11% for unconditional security with one-way reconciliation

### 5.3 Continuous-Variable QKD

#### 5.3.1 Gaussian-Modulated CV-QKD

Grosshans et al. (2003) demonstrated CV-QKD using Gaussian-modulated coherent states:

**Advantages over DV-QKD:**
- Compatible with standard telecom components
- No single-photon detectors required
- Higher key rates at short distances
- Continuous alphabet encoding

**Challenges:**
- More stringent security requirements
- Shorter maximum distance
- Sensitive to excess noise

#### 5.3.2 Heterodyne Detection

The use of heterodyne detection in CV-QKD was analyzed by Leverrier (2015):

**Benefits:**
- Simultaneous measurement of both quadratures
- Improved noise characteristics
- 3 dB penalty compensated by doubled information

**Nguyen et al. (2021) Connection:**
The DT/HD receiver combines dual-threshold decision with heterodyne detection, achieving 20 dB improvement over direct detection schemes.

### 5.4 Satellite QKD Experiments

#### 5.4.1 The Micius Satellite Program

Liao et al. (2017) reported the first satellite-to-ground QKD demonstration:

| Parameter | Value |
|-----------|-------|
| Satellite altitude | ~500 km |
| Ground station | Xinglong, China |
| Wavelength | 850 nm |
| Key rate | 1.1 kbps at 1200 km |
| QBER | ~1.1% |
| Protocol | BB84 with decoy states |

**Key achievements:**
- Demonstrated feasibility of satellite QKD
- Channel loss ~40 dB (less than equivalent fiber)
- Key generation during ~10-minute pass

#### 5.4.2 Entanglement Distribution

Yin et al. (2017) achieved satellite-based entanglement distribution over 1,200 km:

**Results:**
- Bell parameter S = 2.37 +/- 0.09 > 2 (classical limit)
- Demonstrates quantum correlations preserved through atmosphere
- Foundation for device-independent QKD

#### 5.4.3 Intercontinental QKD

Liao et al. (2018) demonstrated intercontinental quantum communication:

**Configuration:**
- Trusted relay at Micius satellite
- Ground stations in China (Beijing, Xinglong) and Europe (Graz, Vienna)
- Distance: 7,600 km total

**Implications:**
- Global quantum network feasible with satellite constellation
- Trusted node architecture demonstrated
- Latency considerations for key management

### 5.5 Atmospheric Channel Models

#### 5.5.1 Turbulence Characterization

The atmosphere introduces intensity fluctuations (scintillation) modeled by various distributions.

**Log-normal distribution (weak turbulence):**
```
f_I(I) = 1/(I*sqrt(2*pi*sigma_ln^2)) * exp[-(ln(I/I0))^2/(2*sigma_ln^2)]
```

**Gamma-Gamma distribution (weak to strong turbulence):**
```
f_I(I) = 2*(alpha*beta)^((alpha+beta)/2) / (Gamma(alpha)*Gamma(beta))
         * I^((alpha+beta)/2-1) * K_{alpha-beta}(2*sqrt(alpha*beta*I))
```

Al-Habash et al. (2001) established Gamma-Gamma as the preferred model for moderate-to-strong turbulence.

**Nguyen et al. (2021) Adoption:**
Uses Gamma-Gamma distribution with Hufnagel-Valley profile for altitude-dependent turbulence characterization.

#### 5.5.2 Altitude-Dependent Turbulence

The Hufnagel-Valley model provides C_n^2(h) profile:

```
C_n^2(h) = A*exp(-h/700) + 5.94e-53*(w/27)^2*h^10*exp(-h/1000)
           + 2.7e-16*exp(-h/1500)
```

**Key insight:** Turbulence concentrated below 20 km altitude

Ma et al. (2015) applied this to satellite-to-ground coherent optical communications, demonstrating spatial diversity benefits.

#### 5.5.3 Weather Effects

Liorni et al. (2019) analyzed weather dependence of satellite QKD:

| Condition | Attenuation (dB/km) | Impact on QKD |
|-----------|---------------------|---------------|
| Clear | 0.1-0.5 | Minimal |
| Haze | 0.5-2 | Moderate |
| Light rain | 2-5 | Significant |
| Heavy rain | >10 | Link failure |

### 5.6 Detection Technologies

#### 5.6.1 Single-Photon Detection

For DV-QKD, single-photon detectors are required:

| Technology | Efficiency | Dark count | Timing jitter |
|------------|------------|------------|---------------|
| Si-APD (visible) | 70% | 100 Hz | 50 ps |
| InGaAs-APD (telecom) | 25% | 10 kHz | 100 ps |
| SNSPD | >90% | <10 Hz | <50 ps |

Miao et al. (2005) analyzed background noise in satellite QKD, establishing timing window optimization for noise rejection.

#### 5.6.2 Coherent Detection for CV-QKD

Heterodyne detection configuration:
- Signal mixed with strong local oscillator
- Photodetector measures beating signal
- Both quadratures accessible

Advantages for satellite QKD:
- No single-photon detector requirement
- Higher bandwidth capability
- Better noise characteristics

### 5.7 Error Handling Approaches

#### 5.7.1 Forward Error Correction

Traditional QKD uses FEC for information reconciliation:

**CASCADE protocol:**
- Iterative binary search
- Interactive communication
- Efficiency ~90-95%

**LDPC codes:**
- Near-Shannon limit performance
- Lower latency than CASCADE
- Rate-adaptive variants available

#### 5.7.2 ARQ Retransmission

Nguyen et al. (2021) pioneered ARQ application to QKD:

**Advantages over FEC:**
- No computational overhead
- Simple implementation
- Adapts naturally to channel variations

**Key innovation:**
- 3-D Markov chain model for analysis
- Optimal retransmission number determination
- Quantified reliability improvement

### 5.8 Vietnamese Research Contributions

#### 5.8.1 PTIT Research Group

Led by Prof. Ngoc T. Dang, the PTIT group has made significant contributions:

**Trinh et al. (2018):** Design and security analysis of QKD protocol over FSO using dual-threshold/direct-detection
- First systematic analysis of DT detection for QKD
- Security boundaries under eavesdropping attacks
- Foundation for subsequent DT/HD work

**Nguyen et al. (2021):** Current paper under review
- Key retransmission scheme
- 3-D Markov chain model
- Comprehensive performance analysis

**Nguyen et al. (2023):** Enhancing design and performance analysis of satellite CV-QKD free space system using DT/HD scheme
- Extended analysis to CV-QKD
- Optimization framework for system parameters
- Comparison with alternative approaches

#### 5.8.2 Regional Context

Vietnamese research aligns with regional quantum communication initiatives:
- ASEAN quantum network planning
- Vietnam National Space Center capabilities
- USTH graduate research programs

### 5.9 Comparative Analysis

#### 5.9.1 Modulation Scheme Comparison

| Scheme | Key Rate | Sensitivity | Complexity | Reference |
|--------|----------|-------------|------------|-----------|
| Polarization BB84 | Low | High | Simple | Liao 2017 |
| SIM/BPSK | Medium | Medium | Medium | Trinh 2018 |
| QPSK-DT/DD | High | High | Medium | Vu 2019 |
| **QPSK-DT/HD** | **High** | **Very High** | **Medium** | **Nguyen 2021** |

#### 5.9.2 Error Handling Comparison

| Method | Efficiency | Latency | Complexity | Reliability |
|--------|------------|---------|------------|-------------|
| CASCADE | 90-95% | High | High | Fixed |
| LDPC | 95%+ | Medium | High | Fixed |
| **ARQ (Nguyen)** | **Variable** | **Low** | **Low** | **Adaptive** |

### 5.10 Research Gaps Identified

#### Gap 1: Tropical Atmosphere Modeling
- Most models based on mid-latitude conditions
- Vietnam-specific turbulence profiles needed
- Monsoon season effects unexplored

#### Gap 2: LEO Constellation Integration
- Single satellite analysis predominant
- Handover optimization not addressed
- Multi-link diversity unexploited

#### Gap 3: Practical Implementation
- Most work simulation-only
- Ground station optimization needed
- Cost-effective solutions required

#### Gap 4: Hybrid Classical-Quantum Systems
- Coexistence with classical optical links
- Wavelength sharing strategies
- Integrated network architectures

---

## 6. Critical Analysis

### 6.1 Strengths of Nguyen et al. (2021)

1. **Novel Integration:** First work combining QPSK modulation, DT/HD detection, and ARQ retransmission for satellite QKD

2. **Comprehensive Channel Model:** Includes all major loss mechanisms (free-space, atmospheric, beam spreading, turbulence)

3. **Rigorous Analysis:** 3-D Markov chain model provides analytical tractability

4. **Practical Focus:** Parameters based on realistic satellite system (LEO at 600 km)

5. **Significant Improvement:** 20 dB power gain and >1000x KLR reduction

### 6.2 Limitations and Assumptions

1. **Idealized Pointing:** Perfect beam tracking assumed
2. **No Finite-Key Analysis:** Security proof assumes asymptotic regime
3. **Single Link:** No satellite constellation consideration
4. **Simplified Eavesdropper Model:** Only URA scenario analyzed
5. **Simulation Only:** No experimental validation

### 6.3 Comparison with State-of-the-Art

| Aspect | Nguyen 2021 | Micius (Liao 2017) | CV-QKD (Dequal 2021) |
|--------|-------------|--------------------|-----------------------|
| Protocol | QPSK-based | BB84 + decoy | Gaussian CV-QKD |
| Detection | Heterodyne | Single-photon | Homodyne |
| Wavelength | 1550 nm | 850 nm | 1550 nm |
| Key rate | 10 Gbps design | 1.1 kbps achieved | ~Mbps potential |
| Validation | Simulation | Experimental | Feasibility study |
| Reliability | ARQ scheme | FEC | Post-processing |

---

## 7. Future Research Directions

### 7.1 Immediate Extensions

1. **Finite-Key Security Analysis**
   - Incorporate finite-size corrections
   - Establish minimum key length requirements
   - Security bounds under practical conditions

2. **Experimental Validation**
   - Ground-based testbed implementation
   - Emulated satellite channel
   - Component characterization

3. **Pointing Error Integration**
   - Realistic tracking model
   - Impact on QBER and KLR
   - Mitigation strategies

### 7.2 Medium-Term Research

1. **LEO Constellation Optimization**
   - Multi-satellite coverage analysis
   - Handover protocol design
   - Geographic optimization for Vietnam

2. **Hybrid FSO/RF Architecture**
   - Classical channel for retransmission signaling
   - Weather-adaptive link switching
   - Reliability enhancement

3. **Machine Learning Integration**
   - Channel prediction for adaptive modulation
   - Optimal threshold selection
   - Anomaly detection for security

### 7.3 Long-Term Vision

1. **Vietnamese Quantum Satellite**
   - Payload design specifications
   - Ground station network planning
   - International collaboration framework

2. **Regional Quantum Network**
   - ASEAN connectivity
   - Cross-border key distribution
   - Standardization contributions

3. **Commercial Applications**
   - Banking and finance sector
   - Government communications
   - Healthcare data protection

---

## Appendix A: Key Equations Summary

### A.1 Channel Model

| Equation | Description | Reference |
|----------|-------------|-----------|
| L_FS = (4*pi*D_S/lambda)^2 | Free-space loss | Eq. (1) |
| h_a = exp(-gamma*D_beta) | Atmospheric attenuation | Eq. (2) |
| h_l(r) = A0*exp(-2*r^2/omega_Deq^2) | Beam spreading loss | Eq. (5) |
| f_hf(h_f) = Gamma-Gamma PDF | Turbulence fading | Eq. (6) |

### A.2 Performance Metrics

| Equation | Description | Reference |
|----------|-------------|-----------|
| QBER = P_error/P_sift | Quantum bit error rate | Eq. (17) |
| QKER = 1-(1-QBER)^(l_bs*P_sift) | Quantum key error rate | Eq. (26) |
| KLR = Sum(pi(C,s,m)) + Sum(pi(n,B,M)) | Key loss rate | Eq. (30) |

### A.3 Detection Thresholds

| Equation | Description | Reference |
|----------|-------------|-----------|
| d0 = E[i0] + varsigma*sqrt(sigma_n^2) | Upper threshold | Eq. (24) |
| d1 = E[i1] - varsigma*sqrt(sigma_n^2) | Lower threshold | Eq. (24) |

---

**Document Version:** 1.0
**Last Updated:** December 2025
**Author:** Analysis based on Nguyen et al. (2021), PTIT Vietnam
**Purpose:** Master's Research - USTH Space & Earth Observation Program
