#!/usr/bin/env python3
"""
Paper Download Script for Satellite-Based QKD Literature Review
================================================================

This script downloads research papers related to the Literature Review of:
"Reliability improvement of satellite-based quantum key distribution systems
using retransmission scheme" by Nguyen et al. (2021)

Folder structure mirrors the existing Reference_Papers organization.

Usage:
    python download_papers.py [--category CATEGORY] [--tier TIER] [--dry-run]

Examples:
    python download_papers.py                    # Download all papers
    python download_papers.py --category Satellite_QKD
    python download_papers.py --tier 1           # Download Tier 1 (Essential) only
    python download_papers.py --dry-run          # Show what would be downloaded
"""

import os
import sys
import json
import time
import urllib.request
import urllib.error
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass
from datetime import datetime

# ============================================================================
# CONFIGURATION
# ============================================================================

# Base output directory (same level as existing Reference_Papers)
BASE_DIR = Path(__file__).parent.parent / "Reference_Papers_Extended"

# Folder structure matching existing Reference_Papers
CATEGORIES = {
    "01_Foundational": "Foundational QKD papers (BB84, E91, early reviews)",
    "02_Satellite_QKD": "Satellite QKD experiments (Micius, etc.)",
    "03_CV_QKD": "Continuous-Variable QKD papers",
    "04_Atmospheric_Channel": "Atmospheric turbulence and channel models",
    "05_Detection_Schemes": "Dual-threshold, heterodyne, and other detection",
    "06_Error_Correction": "LDPC, CASCADE, Polar codes, ARQ methods",
    "07_Security_Analysis": "Security proofs and finite-key analysis",
    "08_LEO_Constellation": "LEO satellite networks and handover",
    "09_Vietnamese_PTIT": "Vietnamese and PTIT research contributions",
    "10_Review_Papers": "Comprehensive review articles",
    "11_Recent_Advances": "Papers from 2022-2025",
}

# ============================================================================
# PAPER DATABASE
# ============================================================================

@dataclass
class Paper:
    """Represents a research paper to download."""
    id: str
    title: str
    authors: str
    year: int
    journal: str
    category: str
    tier: int  # 1=Essential, 2=Important, 3=Supporting, 4=Reference
    doi: Optional[str] = None
    arxiv_id: Optional[str] = None
    url: Optional[str] = None
    filename: Optional[str] = None
    notes: str = ""

# Complete paper database
PAPERS: List[Paper] = [
    # ========================================================================
    # TIER 1 - ESSENTIAL PAPERS
    # ========================================================================

    # Satellite QKD Experiments
    Paper(
        id="chen2021_integrated",
        title="An integrated space-to-ground quantum communication network over 4,600 kilometres",
        authors="Chen, Y.-A. et al.",
        year=2021,
        journal="Nature",
        category="02_Satellite_QKD",
        tier=1,
        doi="10.1038/s41586-020-03093-8",
        notes="First integrated satellite-fiber network, 150 users"
    ),
    Paper(
        id="liao2017_micius",
        title="Satellite-to-ground quantum key distribution",
        authors="Liao, S.-K. et al.",
        year=2017,
        journal="Nature",
        category="02_Satellite_QKD",
        tier=1,
        doi="10.1038/nature23655",
        arxiv_id="1707.00542",
        notes="First Micius satellite QKD demonstration"
    ),
    Paper(
        id="yin2017_entanglement",
        title="Satellite-based entanglement distribution over 1200 kilometers",
        authors="Yin, J. et al.",
        year=2017,
        journal="Science",
        category="02_Satellite_QKD",
        tier=1,
        doi="10.1126/science.aan3211",
        notes="Record entanglement distribution"
    ),
    Paper(
        id="liao2018_intercontinental",
        title="Satellite-relayed intercontinental quantum network",
        authors="Liao, S.-K. et al.",
        year=2018,
        journal="Physical Review Letters",
        category="02_Satellite_QKD",
        tier=1,
        doi="10.1103/PhysRevLett.120.030501",
        notes="China-Austria QKD"
    ),

    # CV-QKD
    Paper(
        id="dequal2021_cvqkd_satellite",
        title="Feasibility of satellite-to-ground continuous-variable quantum key distribution",
        authors="Dequal, D. et al.",
        year=2021,
        journal="npj Quantum Information",
        category="03_CV_QKD",
        tier=1,
        doi="10.1038/s41534-020-00336-4",
        notes="CV-QKD satellite feasibility study"
    ),

    # Vietnamese PTIT
    Paper(
        id="trinh2018_dtdd",
        title="Design and Security Analysis of QKD Protocol Over Free-Space Optics Using Dual-Threshold/Direct-Detection",
        authors="Trinh, P.V. et al.",
        year=2018,
        journal="IEEE Access",
        category="09_Vietnamese_PTIT",
        tier=1,
        doi="10.1109/ACCESS.2018.2796046",
        notes="First DT detection for QKD - PTIT"
    ),
    Paper(
        id="nguyen2023_cvqkd_dthd",
        title="Enhancing Design and Performance Analysis of Satellite CV-QKD Free Space System Using Dual-Threshold/Heterodyne Scheme",
        authors="Nguyen, T.V. et al.",
        year=2023,
        journal="IEEE Access",
        category="09_Vietnamese_PTIT",
        tier=1,
        doi="10.1109/ACCESS.2023.3323247",
        notes="Extended DT/HD to CV-QKD - PTIT"
    ),

    # Review
    Paper(
        id="pirandola2020_advances",
        title="Advances in quantum cryptography",
        authors="Pirandola, S. et al.",
        year=2020,
        journal="Advances in Optics and Photonics",
        category="10_Review_Papers",
        tier=1,
        doi="10.1364/AOP.361502",
        notes="Comprehensive 225-page review"
    ),

    # ========================================================================
    # TIER 2 - IMPORTANT PAPERS
    # ========================================================================

    # Atmospheric Channel
    Paper(
        id="vasylyev2016_atmospheric",
        title="Atmospheric quantum channels with weak and strong turbulence",
        authors="Vasylyev, D. et al.",
        year=2016,
        journal="Physical Review A",
        category="04_Atmospheric_Channel",
        tier=2,
        doi="10.1103/PhysRevA.94.012311",
        notes="Gamma-Gamma turbulence for QKD"
    ),
    Paper(
        id="liorni2019_weather",
        title="Satellite-based links for quantum key distribution: beam effects and weather dependence",
        authors="Liorni, C. et al.",
        year=2019,
        journal="New Journal of Physics",
        category="04_Atmospheric_Channel",
        tier=2,
        doi="10.1088/1367-2630/ab41b2",
        notes="Weather impact on satellite QKD"
    ),
    Paper(
        id="ma2015_downlink",
        title="Performance analysis of satellite-to-ground downlink coherent optical communications with Gamma-Gamma turbulence",
        authors="Ma, J. et al.",
        year=2015,
        journal="Applied Optics",
        category="04_Atmospheric_Channel",
        tier=2,
        doi="10.1364/AO.54.007575",
        notes="Satellite downlink Gamma-Gamma model"
    ),

    # Security Analysis
    Paper(
        id="scarani2009_security",
        title="The security of practical quantum key distribution",
        authors="Scarani, V. et al.",
        year=2009,
        journal="Reviews of Modern Physics",
        category="07_Security_Analysis",
        tier=2,
        doi="10.1103/RevModPhys.81.1301",
        notes="Foundational security framework"
    ),
    Paper(
        id="xu2020_realistic",
        title="Secure quantum key distribution with realistic devices",
        authors="Xu, F. et al.",
        year=2020,
        journal="Reviews of Modern Physics",
        category="07_Security_Analysis",
        tier=2,
        doi="10.1103/RevModPhys.92.025002",
        notes="Realistic device security"
    ),
    Paper(
        id="tomamichel2012_finite",
        title="Tight finite-key analysis for quantum cryptography",
        authors="Tomamichel, M. et al.",
        year=2012,
        journal="Nature Communications",
        category="07_Security_Analysis",
        tier=2,
        doi="10.1038/ncomms1631",
        notes="Finite-key security framework"
    ),

    # Recent Advances
    Paper(
        id="orsucci2025_architectures",
        title="Assessment of Practical Satellite QKD Architectures for Current and Near-Future Missions",
        authors="Orsucci, D. et al.",
        year=2025,
        journal="Int. J. Satellite Communications and Networking",
        category="11_Recent_Advances",
        tier=2,
        doi="10.1002/sat.1544",
        arxiv_id="2404.05668",
        notes="State-of-the-art architecture comparison"
    ),
    Paper(
        id="mueller2025_ldpc_cascade",
        title="Performance of Cascade and LDPC Codes for Information Reconciliation on Industrial QKD Systems",
        authors="Mueller, R. et al.",
        year=2025,
        journal="IET Quantum Communication",
        category="06_Error_Correction",
        tier=2,
        doi="10.1049/qtc2.70003",
        arxiv_id="2408.15758",
        notes="Industrial error correction comparison"
    ),

    # ========================================================================
    # TIER 3 - SUPPORTING PAPERS
    # ========================================================================

    # Foundational
    Paper(
        id="alhabash2001_gammagamma",
        title="Mathematical model for the irradiance probability density function in turbulent media",
        authors="Al-Habash, M.A. et al.",
        year=2001,
        journal="Optical Engineering",
        category="04_Atmospheric_Channel",
        tier=3,
        doi="10.1117/1.1386641",
        notes="Original Gamma-Gamma derivation"
    ),
    Paper(
        id="grosshans2003_cvqkd",
        title="Quantum key distribution using Gaussian-modulated coherent states",
        authors="Grosshans, F. et al.",
        year=2003,
        journal="Nature",
        category="03_CV_QKD",
        tier=3,
        doi="10.1038/nature01289",
        notes="Foundational CV-QKD paper"
    ),
    Paper(
        id="leverrier2015_composable",
        title="Composable security proof for continuous-variable quantum key distribution with coherent states",
        authors="Leverrier, A.",
        year=2015,
        journal="Physical Review Letters",
        category="03_CV_QKD",
        tier=3,
        doi="10.1103/PhysRevLett.114.070501",
        notes="CV-QKD composable security"
    ),

    # Error Correction
    Paper(
        id="milicevic2018_ldpc",
        title="Quasi-cyclic multi-edge LDPC codes for long-distance quantum cryptography",
        authors="Milicevic, M. et al.",
        year=2018,
        journal="npj Quantum Information",
        category="06_Error_Correction",
        tier=3,
        doi="10.1038/s41534-018-0070-6",
        notes="Optimized LDPC for QKD"
    ),
    Paper(
        id="rcldpc_polar2024",
        title="RC-LDPC-Polar Codes for Information Reconciliation in CV-QKD",
        authors="Various",
        year=2024,
        journal="Entropy",
        category="06_Error_Correction",
        tier=3,
        doi="10.3390/e27101025",
        notes="Combined error correction approach"
    ),

    # LEO Constellation
    Paper(
        id="networking2022_constellation",
        title="Networking Feasibility of Quantum Key Distribution Constellation Networks",
        authors="Various",
        year=2022,
        journal="Entropy",
        category="08_LEO_Constellation",
        tier=3,
        doi="10.3390/e24020298",
        notes="LEO network optimization"
    ),
    Paper(
        id="greek2021_leo",
        title="LEO Satellites Constellation-to-Ground QKD Links: Greek Quantum Communication Infrastructure Paradigm",
        authors="Various",
        year=2021,
        journal="Photonics",
        category="08_LEO_Constellation",
        tier=3,
        doi="10.3390/photonics8120544",
        notes="Greece LEO QKD infrastructure"
    ),

    # Detection Schemes
    Paper(
        id="kish2020_cvqkd_satellite",
        title="Feasibility assessment for practical continuous variable quantum key distribution over the satellite-to-Earth channel",
        authors="Kish, S. et al.",
        year=2020,
        journal="Quantum Engineering",
        category="05_Detection_Schemes",
        tier=3,
        doi="10.1002/que2.50",
        notes="CV-QKD practical feasibility"
    ),

    # ========================================================================
    # TIER 4 - REFERENCE PAPERS
    # ========================================================================

    Paper(
        id="bennett1984_bb84",
        title="Quantum cryptography: Public key distribution and coin tossing",
        authors="Bennett, C.H. and Brassard, G.",
        year=1984,
        journal="IEEE Int. Conf. Computers, Systems and Signal Processing",
        category="01_Foundational",
        tier=4,
        url="https://arxiv.org/abs/2003.06557",
        notes="Original BB84 protocol"
    ),
    Paper(
        id="ekert1991_e91",
        title="Quantum cryptography based on Bell's theorem",
        authors="Ekert, A.K.",
        year=1991,
        journal="Physical Review Letters",
        category="01_Foundational",
        tier=4,
        doi="10.1103/PhysRevLett.67.661",
        notes="E91 entanglement-based protocol"
    ),
    Paper(
        id="gisin2002_review",
        title="Quantum cryptography",
        authors="Gisin, N. et al.",
        year=2002,
        journal="Reviews of Modern Physics",
        category="10_Review_Papers",
        tier=4,
        doi="10.1103/RevModPhys.74.145",
        notes="Early comprehensive review"
    ),
    Paper(
        id="bedington2017_progress",
        title="Progress in satellite quantum key distribution",
        authors="Bedington, R. et al.",
        year=2017,
        journal="npj Quantum Information",
        category="10_Review_Papers",
        tier=4,
        doi="10.1038/s41534-017-0031-5",
        notes="Satellite QKD progress review"
    ),
    Paper(
        id="kaushal2017_space",
        title="Optical communication in space: Challenges and mitigation techniques",
        authors="Kaushal, H. and Kaddoum, G.",
        year=2017,
        journal="IEEE Communications Surveys & Tutorials",
        category="04_Atmospheric_Channel",
        tier=4,
        doi="10.1109/COMST.2016.2603518",
        notes="Space optical communication survey"
    ),
    Paper(
        id="pan2022_micius_review",
        title="Micius quantum experiments in space",
        authors="Pan, J.-W. et al.",
        year=2022,
        journal="Reviews of Modern Physics",
        category="02_Satellite_QKD",
        tier=4,
        doi="10.1103/RevModPhys.94.035001",
        notes="Comprehensive Micius review"
    ),

    # Vietnamese PTIT - Additional
    Paper(
        id="vu2019_hap",
        title="HAP-Aided Relaying Satellite FSO/QKD Systems for Secure Vehicular Networks",
        authors="Vu, M.Q. et al.",
        year=2019,
        journal="IEEE VTC-2019 Spring",
        category="09_Vietnamese_PTIT",
        tier=4,
        notes="HAP-aided QKD - PTIT"
    ),
    Paper(
        id="vu2023_network_coding",
        title="Network Coding Aided Hybrid EB/PM Satellite-based FSO/QKD Systems",
        authors="Vu, M.Q. et al.",
        year=2023,
        journal="ITC-CSCC 2023",
        category="09_Vietnamese_PTIT",
        tier=4,
        notes="Network coding for satellite QKD - PTIT"
    ),
]

# ============================================================================
# DOWNLOAD FUNCTIONS
# ============================================================================

def create_directory_structure():
    """Create the category folder structure."""
    print("\n" + "="*60)
    print("Creating Directory Structure")
    print("="*60)

    BASE_DIR.mkdir(parents=True, exist_ok=True)

    for folder, description in CATEGORIES.items():
        folder_path = BASE_DIR / folder
        folder_path.mkdir(exist_ok=True)

        # Create README for each folder
        readme_path = folder_path / "README.md"
        if not readme_path.exists():
            with open(readme_path, 'w') as f:
                f.write(f"# {folder.replace('_', ' ')}\n\n")
                f.write(f"{description}\n\n")
                f.write("## Papers in this folder\n\n")
                f.write("| Filename | Authors | Year | Notes |\n")
                f.write("|----------|---------|------|-------|\n")

        print(f"  [+] {folder}/")

    print(f"\nBase directory: {BASE_DIR}")

def generate_filename(paper: Paper) -> str:
    """Generate a standardized filename for a paper."""
    # Format: AuthorYear_ShortTitle.pdf
    first_author = paper.authors.split(',')[0].split('.')[-1].strip()
    first_author = first_author.replace(' ', '')

    # Shorten title
    words = paper.title.split()[:4]
    short_title = '_'.join(w for w in words if w.lower() not in
                          ['a', 'an', 'the', 'of', 'for', 'and', 'in', 'on', 'to'])
    short_title = ''.join(c for c in short_title if c.isalnum() or c == '_')

    return f"{first_author}{paper.year}_{short_title[:30]}.pdf"

def get_download_url(paper: Paper) -> Optional[str]:
    """Get the download URL for a paper."""
    # Try arXiv first (usually open access)
    if paper.arxiv_id:
        return f"https://arxiv.org/pdf/{paper.arxiv_id}.pdf"

    # Direct URL if provided
    if paper.url:
        return paper.url

    # For DOI, construct Sci-Hub URL (for educational purposes)
    # Note: Users should ensure they have legal access
    if paper.doi:
        # Return DOI URL - user can manually download
        return f"https://doi.org/{paper.doi}"

    return None

def download_paper(paper: Paper, dry_run: bool = False) -> bool:
    """Download a single paper."""
    filename = paper.filename or generate_filename(paper)
    filepath = BASE_DIR / paper.category / filename

    url = get_download_url(paper)

    if dry_run:
        print(f"  [DRY RUN] Would download: {filename}")
        print(f"            URL: {url}")
        print(f"            To: {filepath}")
        return True

    if filepath.exists():
        print(f"  [SKIP] Already exists: {filename}")
        return True

    if not url:
        print(f"  [WARN] No URL available: {filename}")
        return False

    print(f"  [DOWN] Downloading: {filename}")
    print(f"         URL: {url}")

    # For arXiv, we can directly download
    if 'arxiv.org' in url:
        try:
            headers = {'User-Agent': 'Mozilla/5.0 (Research Paper Downloader)'}
            req = urllib.request.Request(url, headers=headers)

            with urllib.request.urlopen(req, timeout=30) as response:
                with open(filepath, 'wb') as f:
                    f.write(response.read())

            print(f"         [OK] Saved to {filepath}")
            return True

        except urllib.error.URLError as e:
            print(f"         [ERR] Download failed: {e}")
            return False
        except Exception as e:
            print(f"         [ERR] Error: {e}")
            return False
    else:
        # For DOI links, save the URL info for manual download
        info_file = filepath.with_suffix('.info.txt')
        with open(info_file, 'w') as f:
            f.write(f"Title: {paper.title}\n")
            f.write(f"Authors: {paper.authors}\n")
            f.write(f"Year: {paper.year}\n")
            f.write(f"Journal: {paper.journal}\n")
            f.write(f"DOI: {paper.doi}\n")
            f.write(f"URL: {url}\n")
            f.write(f"\nNotes: {paper.notes}\n")
            f.write(f"\n--- Manual download required ---\n")
            f.write(f"Visit: {url}\n")

        print(f"         [INFO] Created info file (manual download required)")
        return True

def create_download_report(papers: List[Paper], results: Dict[str, bool]):
    """Create a download status report."""
    report_path = BASE_DIR / "DOWNLOAD_REPORT.md"

    with open(report_path, 'w') as f:
        f.write("# Paper Download Report\n\n")
        f.write(f"**Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")

        # Statistics
        total = len(papers)
        success = sum(1 for v in results.values() if v)
        failed = total - success

        f.write("## Summary\n\n")
        f.write(f"- Total papers: {total}\n")
        f.write(f"- Downloaded/Skipped: {success}\n")
        f.write(f"- Failed/Manual: {failed}\n\n")

        # By tier
        f.write("## By Tier\n\n")
        for tier in range(1, 5):
            tier_papers = [p for p in papers if p.tier == tier]
            tier_success = sum(1 for p in tier_papers if results.get(p.id, False))
            tier_name = {1: "Essential", 2: "Important", 3: "Supporting", 4: "Reference"}[tier]
            f.write(f"- Tier {tier} ({tier_name}): {tier_success}/{len(tier_papers)}\n")

        f.write("\n## By Category\n\n")
        for cat in CATEGORIES:
            cat_papers = [p for p in papers if p.category == cat]
            if cat_papers:
                cat_success = sum(1 for p in cat_papers if results.get(p.id, False))
                f.write(f"- {cat}: {cat_success}/{len(cat_papers)}\n")

        # Detailed list
        f.write("\n## Detailed Status\n\n")
        f.write("| Paper | Year | Status | Category |\n")
        f.write("|-------|------|--------|----------|\n")

        for paper in sorted(papers, key=lambda p: (p.tier, p.year)):
            status = "OK" if results.get(paper.id, False) else "MANUAL"
            short_title = paper.title[:50] + "..." if len(paper.title) > 50 else paper.title
            f.write(f"| {short_title} | {paper.year} | {status} | {paper.category} |\n")

    print(f"\n[+] Report saved to: {report_path}")

def create_bibtex_file(papers: List[Paper]):
    """Create a BibTeX file with all paper references."""
    bib_path = BASE_DIR / "all_references.bib"

    with open(bib_path, 'w') as f:
        f.write("% Auto-generated BibTeX file\n")
        f.write(f"% Generated: {datetime.now().strftime('%Y-%m-%d')}\n\n")

        for paper in papers:
            f.write(f"@article{{{paper.id},\n")
            f.write(f"  title={{{paper.title}}},\n")
            f.write(f"  author={{{paper.authors}}},\n")
            f.write(f"  year={{{paper.year}}},\n")
            f.write(f"  journal={{{paper.journal}}},\n")
            if paper.doi:
                f.write(f"  doi={{{paper.doi}}},\n")
            if paper.arxiv_id:
                f.write(f"  eprint={{{paper.arxiv_id}}},\n")
                f.write(f"  archivePrefix={{arXiv}},\n")
            f.write(f"  note={{{paper.notes}}}\n")
            f.write("}\n\n")

    print(f"[+] BibTeX file saved to: {bib_path}")

# ============================================================================
# MAIN FUNCTION
# ============================================================================

def main():
    """Main download function."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Download papers for Satellite-Based QKD Literature Review"
    )
    parser.add_argument(
        '--category', '-c',
        help="Download only papers from specific category"
    )
    parser.add_argument(
        '--tier', '-t',
        type=int,
        choices=[1, 2, 3, 4],
        help="Download only papers from specific tier (1=Essential, 4=Reference)"
    )
    parser.add_argument(
        '--dry-run', '-n',
        action='store_true',
        help="Show what would be downloaded without downloading"
    )
    parser.add_argument(
        '--list', '-l',
        action='store_true',
        help="List all papers in database"
    )

    args = parser.parse_args()

    print("\n" + "="*60)
    print("Satellite-Based QKD Literature Paper Downloader")
    print("="*60)

    # Filter papers
    papers = PAPERS

    if args.category:
        papers = [p for p in papers if args.category.lower() in p.category.lower()]
        print(f"\nFiltering by category: {args.category}")

    if args.tier:
        papers = [p for p in papers if p.tier == args.tier]
        tier_names = {1: "Essential", 2: "Important", 3: "Supporting", 4: "Reference"}
        print(f"\nFiltering by tier: {args.tier} ({tier_names[args.tier]})")

    if args.list:
        print("\n" + "-"*60)
        print("Paper Database")
        print("-"*60)
        for paper in sorted(papers, key=lambda p: (p.tier, p.category, p.year)):
            print(f"\n[Tier {paper.tier}] {paper.id}")
            print(f"  Title: {paper.title}")
            print(f"  Authors: {paper.authors}")
            print(f"  Year: {paper.year}")
            print(f"  Category: {paper.category}")
            if paper.doi:
                print(f"  DOI: {paper.doi}")
            if paper.arxiv_id:
                print(f"  arXiv: {paper.arxiv_id}")
        print(f"\nTotal: {len(papers)} papers")
        return

    print(f"\nTotal papers to process: {len(papers)}")

    # Create directory structure
    create_directory_structure()

    # Download papers
    print("\n" + "="*60)
    print("Downloading Papers")
    print("="*60)

    results = {}
    for i, paper in enumerate(papers, 1):
        print(f"\n[{i}/{len(papers)}] {paper.title[:50]}...")
        results[paper.id] = download_paper(paper, dry_run=args.dry_run)

        # Rate limiting for arXiv
        if paper.arxiv_id and not args.dry_run:
            time.sleep(3)  # Be nice to arXiv servers

    # Create reports
    if not args.dry_run:
        create_download_report(papers, results)
        create_bibtex_file(papers)

    # Summary
    print("\n" + "="*60)
    print("Download Summary")
    print("="*60)
    success = sum(1 for v in results.values() if v)
    print(f"  Processed: {len(papers)}")
    print(f"  Success: {success}")
    print(f"  Failed/Manual: {len(papers) - success}")

    if args.dry_run:
        print("\n[DRY RUN] No files were actually downloaded")

    print(f"\nOutput directory: {BASE_DIR}")
    print("\nDone!")

if __name__ == "__main__":
    main()
