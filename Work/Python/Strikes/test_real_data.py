#!/usr/bin/env python3
"""
Test script with real UAF data from November 8, 2024
"""

import sys
import os

# Add current directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from uaf_strike_report_generator import StrikeDataParser, NumberFormatter

# Real UAF Telegram post text from November 8, 2024
REAL_UAF_TEXT = """
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


def test_real_data():
    """Test the parser with real UAF data."""
    print("=" * 70)
    print("TESTING WITH REAL UAF DATA (November 8, 2024)")
    print("=" * 70)
    print()

    parser = StrikeDataParser(REAL_UAF_TEXT)
    data = parser.parse_all()

    print("EXPECTED vs ACTUAL:")
    print("-" * 70)

    tests = [
        ("Date phrase", "November 8", data.get('date_phrase')),
        ("Total drones", 458, data.get('total_drones')),
        ("Total missiles", 45, data.get('total_missiles')),
        ("Total air targets", 503, data.get('total_air_targets')),
        ("Shahed count", 300, data.get('shahed_count')),
        ("Drones shot down", 406, data.get('drones_shot_down')),
        ("Iskanders M/KN-23 fired", 25, None),  # Check later
        ("Iskanders K fired", 10, None),
        ("Kinzhal fired", 7, data.get('kinzhal_fired')),
        ("Kalibr fired", 3, data.get('kalibr_fired')),
    ]

    # Check Iskanders separately (formatted as string)
    iskanders_fired = data.get('iskanders_fired')
    print(f"{'Iskanders fired':<25} Expected: '10 Isk-K, 25 Isk-M/KN-23'")
    print(f"{'':<25} Actual:   '{iskanders_fired}'")

    if iskanders_fired:
        if '10' in iskanders_fired and '25' in iskanders_fired:
            print(f"{'':<25} ✓ PASS\n")
        else:
            print(f"{'':<25} ✗ FAIL\n")
    else:
        print(f"{'':<25} ✗ FAIL (NULL)\n")

    # Check other fields
    passed = 0
    failed = 0

    for label, expected, actual in tests:
        status = "✓ PASS" if actual == expected else "✗ FAIL"
        if actual == expected:
            passed += 1
        else:
            failed += 1

        print(f"{label:<25} Expected: {expected}")
        print(f"{'':<25} Actual:   {actual}")
        print(f"{'':<25} {status}\n")

    # Check impact info
    print("-" * 70)
    print("IMPACT INFORMATION:")
    print("-" * 70)
    impact_info = data.get('impact_info', {})

    print(f"Hits: {impact_info.get('hits')}")
    print(f"  Expected: '26 missiles and 52 drones hit 25' (or similar)")
    if impact_info.get('hits') and '26' in str(impact_info.get('hits')) and '52' in str(impact_info.get('hits')):
        print("  ✓ PASS\n")
        passed += 1
    else:
        print("  ✗ FAIL\n")
        failed += 1

    print(f"Debris: {impact_info.get('debris')}")
    print(f"  Expected: '4' or '4 locations'")
    if impact_info.get('debris') and '4' in str(impact_info.get('debris')):
        print("  ✓ PASS\n")
        passed += 1
    else:
        print("  ✗ FAIL\n")
        failed += 1

    print(f"Target oblasts: {impact_info.get('target_oblasts')}")
    print(f"  Expected: 'Kyiv, Dnipropetrovsk, and Poltava'")
    if impact_info.get('target_oblasts') and 'Kyiv' in str(impact_info.get('target_oblasts')):
        print("  ✓ PASS\n")
        passed += 1
    else:
        print("  ✗ FAIL\n")
        failed += 1

    print("=" * 70)
    print(f"RESULTS: {passed} passed, {failed} failed")
    print("=" * 70)

    return failed == 0


if __name__ == '__main__':
    success = test_real_data()
    sys.exit(0 if success else 1)
