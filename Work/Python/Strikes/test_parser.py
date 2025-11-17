#!/usr/bin/env python3
"""
Test script for UAF Strike Report Generator
Tests parsing functionality with sample input
"""

import sys
import os

# Add current directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from uaf_strike_report_generator import StrikeDataParser, NumberFormatter

# Sample UAF Telegram post text
SAMPLE_TEXT = """
On the night of October 21-22, Russian forces launched 75 Shahed-type drones, Gerbera-type
drones, and other UAVs from Kursk Oblast and Primorsko-Akhtarsk. The Ukrainian Air Force
reported that roughly 60 of these were Shahed drones. Russian forces also launched 3
Iskander-K cruise missiles from Voronezh Oblast, 5 Iskander-M ballistic missiles from Kursk
Oblast, 4 Kh-101 cruise missiles from strategic bombers, 2 Kalibr cruise missiles from the
Black Sea, and 6 S-300 surface-to-air missiles from occupied territories.

The Ukrainian Air Force reported that Ukrainian forces downed 45 drones, 2 Iskander-K cruise
missiles, 3 Iskander-M ballistic missiles, 3 Kh-101 cruise missiles, 1 Kalibr cruise missile,
and 4 S-300 missiles.

The Ukrainian Air Force reported that 5 missiles and 8 drones hit critical infrastructure in
Kyiv Oblast. Drone debris fell on residential areas in Dnipropetrovsk Oblast. The Russian
strikes primarily targeted energy infrastructure in Kyiv Oblast and also affected Kharkiv,
Poltava, and Sumy Oblasts. Ukrainian officials reported that the strikes damaged electrical
infrastructure in Kyiv and Kharkiv Oblasts.
"""


def test_parser():
    """Test the data parser."""
    print("=== Testing UAF Strike Report Parser ===\n")

    parser = StrikeDataParser(SAMPLE_TEXT)
    data = parser.parse_all()

    print("Parsed Data:")
    print("-" * 60)

    # Test date parsing
    print(f"Date phrase: {data.get('date_phrase')}")

    # Test drone data
    print(f"\nDrone Data:")
    print(f"  Total drones: {data.get('total_drones')}")
    print(f"  Shahed count: {data.get('shahed_count')}")
    print(f"  Drones shot down: {data.get('drones_shot_down')}")

    # Test missile data
    print(f"\nMissile Data:")
    print(f"  Iskanders fired: {data.get('iskanders_fired')}")
    print(f"  Iskanders shot down: {data.get('iskanders_shot_down')}")
    print(f"  S-300/400 fired: {data.get('s300_400_fired')}")
    print(f"  S-300/400 shot down: {data.get('s300_400_shot_down')}")
    print(f"  Kh-101 fired: {data.get('kh101_fired')}")
    print(f"  Kh-101 shot down: {data.get('kh101_shot_down')}")
    print(f"  Kalibr fired: {data.get('kalibr_fired')}")
    print(f"  Kalibr shot down: {data.get('kalibr_shot_down')}")

    # Test totals
    print(f"\nTotals:")
    print(f"  Total missiles: {data.get('total_missiles')}")
    print(f"  Total air targets: {data.get('total_air_targets')}")

    # Test impact info
    print(f"\nImpact Information:")
    impact_info = data.get('impact_info', {})
    print(f"  Hits: {impact_info.get('hits')}")
    print(f"  Debris: {impact_info.get('debris')}")
    print(f"  Target oblasts: {impact_info.get('target_oblasts')}")
    print(f"  Damage: {impact_info.get('damage')}")

    print("\n" + "=" * 60)
    print("Testing Number Formatter:")
    print("-" * 60)

    test_numbers = [1, 5, 10, 12, 13, 45, 100, None]
    for num in test_numbers:
        formatted = NumberFormatter.format(num)
        print(f"  {num} -> {formatted}")

    print("\n=== Test Complete ===\n")

    # Verify key data points
    print("Verification:")
    errors = []

    if data.get('total_drones') != 75:
        errors.append(f"Expected 75 drones, got {data.get('total_drones')}")

    if data.get('shahed_count') != 60:
        errors.append(f"Expected 60 Shaheds, got {data.get('shahed_count')}")

    if data.get('drones_shot_down') != 45:
        errors.append(f"Expected 45 drones shot down, got {data.get('drones_shot_down')}")

    if errors:
        print("FAILED - Errors found:")
        for error in errors:
            print(f"  - {error}")
    else:
        print("PASSED - All key data points extracted correctly!")


if __name__ == '__main__':
    test_parser()
