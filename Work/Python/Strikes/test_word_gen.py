#!/usr/bin/env python3
"""
Test the updated Word document generation with real Nov 8 data
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from uaf_strike_report_generator import StrikeDataParser, WordDocumentGenerator

# Real UAF text from Nov 8
REAL_TEXT = """
⚡️ 415 ENEMY TARGETS DESTROYED/SUPPRESSED
➖➖➖➖➖➖➖➖➖➖
On the night of November 8 (from 6:30 p.m. on November 7), the enemy launched a combined strike on critical infrastructure facilities in Ukraine using strike UAVs, air-based, ground-based, and sea-based missiles.


In total, the Air Force's radio-technical troops detected and tracked 503 air attack weapons – 45 missiles (including 32 ballistic missiles) and 458 UAVs of various types (about 300 of them were Shahed UAVs):

- 458 Shahed and Gerbera strike UAVs (other types of drones) from the directions of Kursk, Millerovo, Orel, Primorsko-Akhtarsk – RF, Gvardeyskoye – TOT AR Crimea);
- 25 Iskander-M/KN-23 ballistic missiles (from Kursk, Voronezh, and Rostov regions – Russian Federation);
- 10 Iskander-K cruise missiles (from Kursk and Voronezh regions – Russian Federation);
- 7 Kh-47M2 "Kinzhal" aeroballistic missiles (from Tambov region – Russian Federation);
- 3 "Kalibr" cruise missiles (from the Black Sea).

❗️ The main targets of the attack were Kyiv, Dnipropetrovsk, and Poltava regions.

The air attack was repelled by aviation, anti-aircraft missile forces, electronic warfare and unmanned systems units, and mobile fire groups of the Ukrainian Defense Forces.

💥According to preliminary data, as of 10:00 a.m., air defense forces shot down/suppressed 415 air targets:

- 406 Shahed and Gerbera strike UAVs (other types of drones);
- 9 missiles of various types.

Currently, 26 missiles and 52 strike UAVs have been recorded as hitting 25 locations, and debris from downed missiles has been recorded at 4 locations in various regions of Ukraine.
In addition, as of 10:00 a.m., information regarding the fall/hits of 10 enemy missiles is being verified.

✊ Let's keep the sky safe!
🇺🇦 Together – to victory!
"""

print("Testing Word Document Generation...")
print("=" * 70)

# Parse data
parser = StrikeDataParser(REAL_TEXT)
data = parser.parse_all()

print("\nParsed Locations:")
print(f"Iskander-M locations: {data.get('iskander_m_locations')}")
print(f"Iskander-K locations: {data.get('iskander_k_locations')}")
print(f"Kinzhal locations: {data.get('kinzhal_locations')}")
print(f"Kalibr locations: {data.get('kalibr_locations')}")
print(f"Drone locations: {data.get('drone_launch_locations')}")

# Generate Word document
print("\nGenerating Word document...")
doc_gen = WordDocumentGenerator(data, REAL_TEXT)
filename = doc_gen.generate()

print(f"\n✓ Document generated: {filename}")
print("\nPlease open the document to verify the format matches the published example.")
