import psycopg2
from datetime import datetime
import re

def parse_coordinates(coord_string):
    """
    Parse coordinates in format like "34.9433928°E 51.1356086°N"
    Returns (latitude, longitude) or None if invalid
    """
    if not coord_string:
        return None
        
    try:
        parts = coord_string.strip().split()
        lat = None
        lon = None
        
        for part in parts:
            clean = part.replace('°', '').strip()
            
            if 'N' in clean.upper():
                lat = float(clean.replace('N', '').replace('n', ''))
            elif 'S' in clean.upper():
                lat = -float(clean.replace('S', '').replace('s', ''))
            elif 'E' in clean.upper():
                lon = float(clean.replace('E', '').replace('e', ''))
            elif 'W' in clean.upper():
                lon = -float(clean.replace('W', '').replace('w', ''))
        
        if lat is not None and lon is not None:
            return (lat, lon)
            
    except Exception as e:
        print(f"Error parsing coordinates '{coord_string}': {e}")
    
    return None

def batch_insert_unit_mentions(units_data):
    """
    Inserts unit mentions into unit_mentions table (Phase 2 workflow).

    units_data: list of dicts with 'unit_key' or 'unknown_unit_key' and either:
        - 'pcode': Ukrainian settlement PCODE (stored as adm4_pcode)
        - 'coordinates': String like "34.9433928°E 51.1356086°N"
        - 'lat' and 'lon': Direct numeric values

    Unit identification (provide ONE of these):
        - 'unit_key': Known unit key (x#####, y#####) for russian_units
        - 'unknown_unit_key': Unknown unit key OR 'AUTO_A'/'AUTO_B' for auto-generation
          - Use 'AUTO_A' for subordinate elements (drone company, assault element)
          - Use 'AUTO_B' for assets (TOS-A1, arty battery)
          - Actual key will be auto-generated as za##### or zb#####

    Assessment fields (all optional):
        - 'status': Status code integer (0-5)
        - 'reinforced': '+', '-', '±', '+/-', or NULL
        - 'operational_condition': Operational condition code string ('100', '110', etc.)
        - 'credibility': Credibility code (1-6)
        - 'reliability': Reliability code (text: 'A'-'F')
        - 'action': Unit activity/current tasking

    Source attribution fields:
        - 'source_id': Foreign key to sources table (optional)
        - 'source_url': URL to source material
        - 'source_excerpt': Text excerpt from source (optional)

    Location fields:
        - 'tactical_area_id': Foreign key to tactical_areas (optional)
        - 'location_precision': 'exact', 'settlement', 'area', 'direction' (optional)

    Command relationship fields (all optional):
        - 'new_parent_unit_key': New parent unit
        - 'new_opcon_unit_key': New operational control unit
        - 'new_adcon_unit_key': New administrative control unit
        - 'command_change_date': Date of command relationship change

    Detached element fields (all optional):
        - 'is_detached_element': Boolean
        - 'is_main_body': Boolean
        - 'element_size_estimate': 'company', 'battalion', etc.
        - 'element_description': Free text description
        - 'detachment_timeframe_start': Date
        - 'detachment_timeframe_end': Date

    Review workflow fields:
        - 'review_status': Default 'pending'
        - 'priority': Integer 1-5, default 3

    Analyst fields:
        - 'analyst': Required, defaults to 'nkramer'
        - 'analyst_notes': Free text notes
        - 'observation_date': Timestamp, defaults to now()

    Examples:
    [
        {
            'unit_key': 'x47084',  # Known unit
            'pcode': 'UA6302504001',
            'status': 0,
            'reinforced': '+',
            'operational_condition': '110',
            'credibility': 2,
            'reliability': 'C',
            'action': 'Assaulting toward Pokrovsk',
            'source_id': '0001'
            'source_url': 'https://t.me/example/12345',
            'analyst': 'nkramer',
        },
        {
            'unknown_unit_key': 'AUTO_A',  # Auto-generate subordinate element key
            'tactical_area_id': 14,
            'action': 'Unidentified drone company operating near Pokrovsk',
            'source_url': 'https://t.me/example/67890',
            'analyst': 'nkramer',
        }
    ]
    """
    conn = psycopg2.connect(
        host="localhost",
        database="russianorbatukraine",
        user="postgres",
        password="Sep10mber"
    )
    cur = conn.cursor()

    conn.set_session(autocommit=True)

    results = []

    for unit in units_data:
        try:
            location_geom = None
            adm4_pcode = None
            location_note = ""

            # Auto-generate unknown unit keys if requested
            if 'unknown_unit_key' in unit and unit['unknown_unit_key'] in ['AUTO_A', 'AUTO_B']:
                category = 'a' if unit['unknown_unit_key'] == 'AUTO_A' else 'b'
                cur.execute("SELECT functions.generate_unknown_unit_key(%s)", (category,))
                generated_key = cur.fetchone()[0]
                unit['unknown_unit_key'] = generated_key
                print(f"Auto-generated unknown unit key: {generated_key}")

            # Handle observation_date
            if 'observation_date' in unit:
                if isinstance(unit['observation_date'], str):
                    obs_date = datetime.strptime(unit['observation_date'], '%Y-%m-%d %H:%M:%S')
                else:
                    obs_date = unit['observation_date']
            else:
                obs_date = datetime.now()

            # Consolidate source_url from multiple possible fields
            source_url = unit.get('source_url')
            if not source_url:
                source_url = unit.get('ru_source') or unit.get('ua_source') or unit.get('geo_source')

            # Tactical area ID (primary location method)
            if 'tactical_area_id' in unit and unit['tactical_area_id']:
                location_note = f"Tactical Area: {unit['tactical_area_id']}"

            # Option 1: PCODE provided (legacy/optional)
            elif 'pcode' in unit and unit['pcode']:
                settlement_pcode = unit['pcode']
                location_note = f"PCODE: {settlement_pcode}"

            # Option 2: Coordinate string provided (legacy/optional)
            elif 'coordinates' in unit and unit['coordinates']:
                coords = parse_coordinates(unit['coordinates'])
                if coords:
                    lat, lon = coords
                    location_geom = f"ST_SetSRID(ST_MakePoint({lon}, {lat}), 4326)"
                    location_note = f"Coords: {lat:.6f}°N, {lon:.6f}°E"
                else:
                    results.append({
                        'unit_key': unit['unit_key'],
                        'action': 'Failed',
                        'location': f"Invalid coordinates: {unit['coordinates']}"
                    })
                    continue

            # Option 3: Direct lat/lon provided (legacy/optional)
            elif 'lat' in unit and 'lon' in unit:
                lat = unit['lat']
                lon = unit['lon']
                location_geom = f"ST_SetSRID(ST_MakePoint({lon}, {lat}), 4326)"
                location_note = f"Coords: {lat:.6f}°N, {lon:.6f}°E"

            else:
                # No location data provided - this is acceptable
                location_note = "No location data"

            # Build analyst_notes (combining notes and location_note)
            analyst_notes = unit.get('analyst_notes') or unit.get('notes', '')
            if analyst_notes and location_note:
                full_notes = f"{analyst_notes}. {location_note}"
            elif location_note:
                full_notes = location_note
            else:
                full_notes = analyst_notes
            
            # INSERT INTO unit_mentions (append-only, no updates)
            if location_geom:
                cur.execute(f"""
                    INSERT INTO unit_mentions (
                        unit_key,
                        unknown_unit_key,
                        source_id,
                        observation_date,
                        tactical_area_id,
                        adm4_pcode,
                        location,
                        location_precision,
                        operational_condition,
                        status,
                        reinforced,
                        action,
                        new_parent_unit_key,
                        new_opcon_unit_key,
                        new_adcon_unit_key,
                        command_change_date,
                        is_detached_element,
                        is_main_body,
                        element_size_estimate,
                        element_description,
                        detachment_timeframe_start,
                        detachment_timeframe_end,
                        credibility,
                        reliability,
                        confidence_level,
                        review_status,
                        analyst,
                        analyst_notes,
                        priority,
                        source_url,
                        source_excerpt,
                        created_date
                    ) VALUES (
                        %s, %s, %s, %s, %s, %s, {location_geom}, %s,
                        %s, %s, %s, %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                    )
                    RETURNING mention_id
                """, (
                    unit.get('unit_key'),
                    unit.get('unknown_unit_key'),
                    unit.get('source_id'),
                    obs_date,
                    unit.get('tactical_area_id'),
                    None,  # adm4_pcode (NULL when coordinates provided)
                    unit.get('location_precision'),
                    unit.get('operational_condition'),
                    unit.get('status'),
                    unit.get('reinforced'),
                    unit.get('action'),
                    unit.get('new_parent_unit_key'),
                    unit.get('new_opcon_unit_key'),
                    unit.get('new_adcon_unit_key'),
                    unit.get('command_change_date'),
                    unit.get('is_detached_element', False),
                    unit.get('is_main_body', False),
                    unit.get('element_size_estimate'),
                    unit.get('element_description'),
                    unit.get('detachment_timeframe_start'),
                    unit.get('detachment_timeframe_end'),
                    unit.get('credibility'),
                    unit.get('reliability'),
                    unit.get('confidence_level', 'Medium'),
                    unit.get('review_status', 'pending'),
                    unit.get('analyst', 'nkramer'),
                    full_notes,
                    unit.get('priority', 3),
                    source_url,
                    unit.get('source_excerpt'),
                    obs_date
                ))
            else:
                cur.execute("""
                    INSERT INTO unit_mentions (
                        unit_key,
                        unknown_unit_key,
                        source_id,
                        observation_date,
                        tactical_area_id,
                        adm4_pcode,
                        location,
                        location_precision,
                        operational_condition,
                        status,
                        reinforced,
                        action,
                        new_parent_unit_key,
                        new_opcon_unit_key,
                        new_adcon_unit_key,
                        command_change_date,
                        is_detached_element,
                        is_main_body,
                        element_size_estimate,
                        element_description,
                        detachment_timeframe_start,
                        detachment_timeframe_end,
                        credibility,
                        reliability,
                        confidence_level,
                        review_status,
                        analyst,
                        analyst_notes,
                        priority,
                        source_url,
                        source_excerpt,
                        created_date
                    ) VALUES (
                        %s, %s, %s, %s, %s, %s, NULL, %s,
                        %s, %s, %s, %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                    )
                    RETURNING mention_id
                """, (
                    unit.get('unit_key'),
                    unit.get('unknown_unit_key'),
                    unit.get('source_id'),
                    obs_date,
                    unit.get('tactical_area_id'),
                    adm4_pcode,
                    unit.get('location_precision'),
                    unit.get('operational_condition'),
                    unit.get('status'),
                    unit.get('reinforced'),
                    unit.get('action'),
                    unit.get('new_parent_unit_key'),
                    unit.get('new_opcon_unit_key'),
                    unit.get('new_adcon_unit_key'),
                    unit.get('command_change_date'),
                    unit.get('is_detached_element', False),
                    unit.get('is_main_body', False),
                    unit.get('element_size_estimate'),
                    unit.get('element_description'),
                    unit.get('detachment_timeframe_start'),
                    unit.get('detachment_timeframe_end'),
                    unit.get('credibility'),
                    unit.get('reliability'),
                    unit.get('confidence_level', 'Medium'),
                    unit.get('review_status', 'pending'),
                    unit.get('analyst', 'nkramer'),
                    full_notes,
                    unit.get('priority', 3),
                    source_url,
                    unit.get('source_excerpt'),
                    obs_date
                ))

            mention_id = cur.fetchone()[0]

            results.append({
                'unit_key': unit['unit_key'],
                'action': f'Inserted mention (ID: {mention_id})',
                'location': location_note
            })
            
        except Exception as e:
            results.append({
                'unit_key': unit.get('unit_key', 'Unknown'),
                'action': 'Failed',
                'location': str(e)
            })
            print(f"Error processing unit {unit.get('unit_key')}: {e}")

    conn.commit()
    cur.close()
    conn.close()

    return results



if __name__ == "__main__":
    units_test = [
        #218th TR
        {
            'unit_key': 'x82588',
            'pcode': 'UA2310007029',
            'status': 0,
            'reinforced': '-',
            'operational_condition': '150',
            'credibility': 1,
            'reliability': 'B',
            'action': 'Seizing Uspenivka',
            'source_id': '0002',
            'source_url': 'https://t.me/voin_dv/17584',
            'source_excerpt': 'o	RU MoD credited on NOV 7 127th MRD (5th CAA) with seizing Uspenivka, and Belousov credited 218th Tank Regiment in particular ',
            'tactical_area_id': 14,
            'location_precision': 'settlement',
            'is_detached_element': False,
            'is_main_body': True,
            'element_size_estimate': 'platoon',
            'priority': 4,
            'analyst': 'nkramer',
            'analyst_notes': 'Unit confirmed via multiple sources'
        }
    ]

    results = batch_insert_unit_mentions(units_test)
    for r in results:
        print(f"{r['unit_key']}: {r['action']} - {r['location']}")