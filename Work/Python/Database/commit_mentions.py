#!/usr/bin/env python3
"""
Phase 2: Unit Mentions Commit Script
Version: 1.0
Date: 2024-11-07

This script handles the analyst workflow for reviewing staged unit mentions
and committing them to the authoritative unit_positions table.
"""

import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime, timedelta
import sys
from typing import List, Dict, Optional, Tuple
from prettytable import PrettyTable

# Configuration
ANALYST_NAME = 'nkramer'
DB_HOST = 'localhost'
DB_NAME = 'russianorbatukraine'
DB_USER = 'postgres'
DB_PASSWORD = 'Sep10mber'  # Will prompt for password
DB_PORT = 5432
SRID = 4326

# Color codes for terminal output (optional)
try:
    from colorama import init, Fore, Style
    init()
    COLOR_ENABLED = True
except ImportError:
    COLOR_ENABLED = False
    # Fallback if colorama not installed
    class Fore:
        RED = ''
        GREEN = ''
        YELLOW = ''
        CYAN = ''
        RESET = ''
    class Style:
        RESET_ALL = ''


# ============================================================================
# DATABASE CONNECTION HANDLING
# ============================================================================

def connect_db() -> psycopg2.extensions.connection:
    """
    Establish connection to PostgreSQL database.

    Returns:
        Database connection object
    """
    global DB_PASSWORD

    if DB_PASSWORD is None:
        from getpass import getpass
        DB_PASSWORD = getpass(f"Enter password for PostgreSQL user '{DB_USER}': ")

    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            port=DB_PORT
        )
        print(f"{Fore.GREEN}✓ Connected to database: {DB_NAME}{Style.RESET_ALL}")
        return conn
    except psycopg2.Error as e:
        print(f"{Fore.RED}✗ Database connection failed: {e}{Style.RESET_ALL}")
        sys.exit(1)


# ============================================================================
# FR-1: DATABASE QUERY FUNCTIONS
# ============================================================================

def get_pending_mentions(conn) -> List[Dict]:
    """
    Query all pending mentions with source details.

    Args:
        conn: Database connection

    Returns:
        List of dictionaries with mention and source data
    """
    query = """
        SELECT
            um.mention_id,
            COALESCE(um.unit_key, um.unknown_unit_key) as unit_identifier,
            um.unit_key,
            um.unknown_unit_key,
            um.source_id,
            um.observation_date,
            um.tactical_area_id,
            um.operational_area_id,
            um.adm4_pcode,
            um.location,
            um.location_precision,
            um.operational_condition,
            um.status,
            um.reinforced,
            um.action,
            um.is_detached_element,
            um.is_main_body,
            um.element_size_estimate,
            um.element_description,
            um.credibility,
            um.reliability,
            um.confidence_level,
            um.analyst_notes,
            s.source_name,
            s.source_origin,
            s.self as source_self_reported,
            s.source_credibility,
            s.source_reliability
        FROM unit_mentions um
        JOIN sources s ON um.source_id = s.source_id
        WHERE um.review_status = 'pending'
          AND um.committed_date IS NULL
        ORDER BY
            unit_identifier,
            um.observation_date DESC
    """

    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(query)
        return cur.fetchall()


def get_mentions_by_unit(conn) -> List[Dict]:
    """
    Group pending mentions by unit identifier.
    Show count, areas, date range for each unit.

    Args:
        conn: Database connection

    Returns:
        List of dictionaries with unit summary data
    """
    query = """
        SELECT
            COALESCE(um.unit_key, um.unknown_unit_key) as unit_identifier,
            COUNT(*) as mention_count,
            MIN(um.observation_date) as earliest_date,
            MAX(um.observation_date) as latest_date,
            COUNT(DISTINCT um.tactical_area_id) as area_count,
            STRING_AGG(DISTINCT CAST(um.tactical_area_id AS TEXT), ', ') as tactical_areas,
            ru.unit_name
        FROM unit_mentions um
        LEFT JOIN russian_units ru ON um.unit_key = ru.unit_key
        WHERE um.review_status = 'pending'
          AND um.committed_date IS NULL
        GROUP BY
            COALESCE(um.unit_key, um.unknown_unit_key),
            ru.unit_name
        ORDER BY
            MAX(um.observation_date) DESC
    """

    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(query)
        return cur.fetchall()


def get_unit_mentions(conn, unit_identifier: str) -> List[Dict]:
    """
    Get all pending mentions for a specific unit.

    Args:
        conn: Database connection
        unit_identifier: The unit_key or unknown_unit_key

    Returns:
        List of dictionaries with full mention details
    """
    query = """
        SELECT
            um.mention_id,
            um.unit_key,
            um.unknown_unit_key,
            um.source_id,
            um.observation_date,
            um.tactical_area_id,
            um.operational_area_id,
            um.adm4_pcode,
            ST_AsText(um.location) as location_wkt,
            ST_Y(um.location) as latitude,
            ST_X(um.location) as longitude,
            um.location_precision,
            um.operational_condition,
            um.status,
            um.reinforced,
            um.action,
            um.is_detached_element,
            um.is_main_body,
            um.element_size_estimate,
            um.element_description,
            um.credibility,
            um.reliability,
            um.confidence_level,
            um.analyst_notes,
            s.source_name,
            s.source_origin,
            s.self as source_self_reported,
            s.source_credibility,
            s.source_reliability
        FROM unit_mentions um
        JOIN sources s ON um.source_id = s.source_id
        WHERE (um.unit_key = %s OR um.unknown_unit_key = %s)
          AND um.review_status = 'pending'
          AND um.committed_date IS NULL
        ORDER BY um.observation_date DESC
    """

    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(query, (unit_identifier, unit_identifier))
        return cur.fetchall()


def get_source_details(conn, source_id: int) -> Optional[Dict]:
    """
    Get details for a specific source.

    Args:
        conn: Database connection
        source_id: The source ID

    Returns:
        Dictionary with source details or None
    """
    query = """
        SELECT
            source_id,
            source_name,
            source_origin,
            self as source_self_reported,
            source_credibility,
            source_reliability
        FROM sources
        WHERE source_id = %s
    """

    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(query, (source_id,))
        return cur.fetchone()


# ============================================================================
# FR-2: INTERACTIVE SELECTION INTERFACE
# ============================================================================

def display_pending_summary(conn):
    """Display summary of all pending mentions grouped by unit."""
    units = get_mentions_by_unit(conn)

    if not units:
        print(f"\n{Fore.YELLOW}No pending mentions to process.{Style.RESET_ALL}")
        return False

    print(f"\n{Fore.CYAN}{'='*80}")
    print(f"PENDING MENTIONS SUMMARY")
    print(f"{'='*80}{Style.RESET_ALL}\n")

    table = PrettyTable()
    table.field_names = ["#", "Unit ID", "Unit Name", "Count", "Areas", "Date Range"]
    table.align["Unit Name"] = "l"
    table.align["Date Range"] = "l"

    for idx, unit in enumerate(units, 1):
        unit_id = unit['unit_identifier']
        unit_name = unit['unit_name'] or 'Unknown Unit'
        count = unit['mention_count']
        areas = f"{unit['area_count']} areas"
        date_range = f"{unit['earliest_date'].date()} to {unit['latest_date'].date()}"

        table.add_row([idx, unit_id, unit_name[:40], count, areas, date_range])

    print(table)
    return True


def select_unit_for_review(conn) -> Optional[str]:
    """
    Allow analyst to select which unit to process.

    Args:
        conn: Database connection

    Returns:
        Selected unit_identifier or None to exit
    """
    units = get_mentions_by_unit(conn)

    if not units:
        return None

    while True:
        choice = input(f"\n{Fore.CYAN}Select observation # to process (or 'q' to quit): {Style.RESET_ALL}").strip()

        if choice.lower() == 'q':
            return None

        try:
            idx = int(choice) - 1
            if 0 <= idx < len(units):
                return units[idx]['unit_identifier']
            else:
                print(f"{Fore.RED}Invalid selection. Please choose 1-{len(units)}.{Style.RESET_ALL}")
        except ValueError:
            print(f"{Fore.RED}Invalid input. Please enter a number or 'q'.{Style.RESET_ALL}")


def select_mentions_to_aggregate(conn, unit_identifier: str) -> Optional[List[int]]:
    """
    Display all pending mentions for a unit and allow analyst to select which to aggregate.

    Args:
        conn: Database connection
        unit_identifier: The unit to show mentions for

    Returns:
        List of selected mention_ids or None to cancel
    """
    mentions = get_unit_mentions(conn, unit_identifier)

    if not mentions:
        print(f"{Fore.YELLOW}No pending mentions found for unit {unit_identifier}.{Style.RESET_ALL}")
        return None

    print(f"\n{Fore.CYAN}{'='*120}")
    print(f"PENDING MENTIONS FOR UNIT: {unit_identifier}")
    print(f"{'='*120}{Style.RESET_ALL}\n")

    table = PrettyTable()
    table.field_names = ["ID", "Date", "Tac Area", "Source", "Self?", "Cred", "Loc", "Status", "Action"]
    table.align["Source"] = "l"
    table.align["Action"] = "l"

    for mention in mentions:
        mention_id = mention['mention_id']
        date = mention['observation_date'].strftime('%Y-%m-%d')
        tac_area = mention['tactical_area_id'] or 'N/A'
        source = mention['source_name'][:30]
        self_reported = 'Y' if mention['source_self_reported'] else 'N'
        cred = mention['source_credibility'] or 'N/A'
        location = 'Exact' if mention['latitude'] else 'Area'
        status = mention['status'] or 'N/A'
        action = (mention['action'] or '')[:30]

        table.add_row([mention_id, date, tac_area, source, self_reported, cred, location, status, action])

    print(table)

    # Check for potential issues
    date_span = (max(m['observation_date'] for m in mentions) -
                 min(m['observation_date'] for m in mentions)).days
    if date_span > 7:
        print(f"{Fore.YELLOW}⚠ Warning: Mentions span {date_span} days. Consider if data is stale.{Style.RESET_ALL}")

    area_count = len(set(m['tactical_area_id'] for m in mentions if m['tactical_area_id']))
    if area_count > 1:
        print(f"{Fore.YELLOW}⚠ Warning: Mentions from {area_count} different areas. Check for detached elements.{Style.RESET_ALL}")

    while True:
        choice = input(f"\n{Fore.CYAN}Enter mention IDs to aggregate (comma-separated, or 'c' to cancel): {Style.RESET_ALL}").strip()

        if choice.lower() == 'c':
            return None

        try:
            mention_ids = [int(x.strip()) for x in choice.split(',')]

            # Validate all IDs exist
            valid_ids = [m['mention_id'] for m in mentions]
            invalid = [mid for mid in mention_ids if mid not in valid_ids]

            if invalid:
                print(f"{Fore.RED}Invalid mention IDs: {invalid}{Style.RESET_ALL}")
                continue

            return mention_ids
        except ValueError:
            print(f"{Fore.RED}Invalid input. Please enter comma-separated numbers.{Style.RESET_ALL}")


def select_location_source(conn, mention_ids: List[int]) -> Optional[int]:
    """
    Allow analyst to select which source to use for location data.

    Args:
        conn: Database connection
        mention_ids: List of selected mention IDs

    Returns:
        Selected source_id or None to cancel
    """
    query = """
        SELECT DISTINCT
            um.source_id,
            s.source_name,
            s.source_origin,
            s.self as source_self_reported,
            s.source_credibility,
            COUNT(um.mention_id) as mention_count,
            SUM(CASE WHEN um.location IS NOT NULL THEN 1 ELSE 0 END) as has_exact_location
        FROM unit_mentions um
        JOIN sources s ON um.source_id = s.source_id
        WHERE um.mention_id = ANY(%s)
        GROUP BY um.source_id, s.source_name, s.source_origin, s.self, s.source_credibility
        ORDER BY s.self DESC, s.source_credibility ASC
    """

    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(query, (mention_ids,))
        sources = cur.fetchall()

    print(f"\n{Fore.CYAN}{'='*80}")
    print(f"SELECT LOCATION SOURCE")
    print(f"{'='*80}{Style.RESET_ALL}\n")

    table = PrettyTable()
    table.field_names = ["#", "Source ID", "Source Name", "Origin", "Self?", "Cred", "Exact Locs"]
    table.align["Source Name"] = "l"

    for idx, source in enumerate(sources, 1):
        source_id = source['source_id']
        name = source['source_name'][:40]
        origin = source['source_origin']
        self_reported = f"{Fore.GREEN}YES{Style.RESET_ALL}" if source['source_self_reported'] else "No"
        cred = source['source_credibility'] or 'N/A'
        exact_locs = f"{source['has_exact_location']}/{source['mention_count']}"

        table.add_row([idx, source_id, name, origin, self_reported, cred, exact_locs])

    print(table)

    while True:
        choice = input(f"\n{Fore.CYAN}Select source # for location data (or 'c' to cancel): {Style.RESET_ALL}").strip()

        if choice.lower() == 'c':
            return None

        try:
            idx = int(choice) - 1
            if 0 <= idx < len(sources):
                return sources[idx]['source_id']
            else:
                print(f"{Fore.RED}Invalid selection. Please choose 1-{len(sources)}.{Style.RESET_ALL}")
        except ValueError:
            print(f"{Fore.RED}Invalid input. Please enter a number or 'c'.{Style.RESET_ALL}")


def select_assessment_sources(conn, mention_ids: List[int]) -> Optional[Dict[str, int]]:
    """
    Allow analyst to select which sources to use for assessment data.

    Args:
        conn: Database connection
        mention_ids: List of selected mention IDs

    Returns:
        Dictionary mapping field names to source_ids or None to cancel
    """
    query = """
        SELECT DISTINCT
            um.source_id,
            s.source_name,
            s.source_origin,
            s.source_credibility,
            COUNT(um.mention_id) as mention_count,
            SUM(CASE WHEN um.operational_condition IS NOT NULL THEN 1 ELSE 0 END) as has_op_condition,
            SUM(CASE WHEN um.status IS NOT NULL THEN 1 ELSE 0 END) as has_status,
            SUM(CASE WHEN um.action IS NOT NULL THEN 1 ELSE 0 END) as has_action
        FROM unit_mentions um
        JOIN sources s ON um.source_id = s.source_id
        WHERE um.mention_id = ANY(%s)
        GROUP BY um.source_id, s.source_name, s.source_origin, s.source_credibility
        ORDER BY s.source_credibility ASC
    """

    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(query, (mention_ids,))
        sources = cur.fetchall()

    print(f"\n{Fore.CYAN}{'='*80}")
    print(f"SELECT ASSESSMENT SOURCES")
    print(f"{'='*80}{Style.RESET_ALL}\n")

    table = PrettyTable()
    table.field_names = ["#", "Source ID", "Source Name", "Origin", "Cred", "OpCond", "Status", "Action"]
    table.align["Source Name"] = "l"

    for idx, source in enumerate(sources, 1):
        source_id = source['source_id']
        name = source['source_name'][:40]
        origin = source['source_origin']
        cred = source['source_credibility'] or 'N/A'
        op_cond = f"{source['has_op_condition']}/{source['mention_count']}"
        status = f"{source['has_status']}/{source['mention_count']}"
        action = f"{source['has_action']}/{source['mention_count']}"

        table.add_row([idx, source_id, name, origin, cred, op_cond, status, action])

    print(table)

    assessment_sources = {}

    # Select source for operational_condition
    while True:
        choice = input(f"\n{Fore.CYAN}Select source # for operational_condition (or 'skip'/'c'): {Style.RESET_ALL}").strip()

        if choice.lower() == 'c':
            return None
        if choice.lower() == 'skip':
            break

        try:
            idx = int(choice) - 1
            if 0 <= idx < len(sources):
                assessment_sources['operational_condition'] = sources[idx]['source_id']
                break
            else:
                print(f"{Fore.RED}Invalid selection. Please choose 1-{len(sources)}.{Style.RESET_ALL}")
        except ValueError:
            print(f"{Fore.RED}Invalid input. Please enter a number, 'skip', or 'c'.{Style.RESET_ALL}")

    # Select source for status
    while True:
        choice = input(f"\n{Fore.CYAN}Select source # for status (or 'skip'/'c'): {Style.RESET_ALL}").strip()

        if choice.lower() == 'c':
            return None
        if choice.lower() == 'skip':
            break

        try:
            idx = int(choice) - 1
            if 0 <= idx < len(sources):
                assessment_sources['status'] = sources[idx]['source_id']
                break
            else:
                print(f"{Fore.RED}Invalid selection. Please choose 1-{len(sources)}.{Style.RESET_ALL}")
        except ValueError:
            print(f"{Fore.RED}Invalid input. Please enter a number, 'skip', or 'c'.{Style.RESET_ALL}")

    # Select source(s) for action - allow multiple
    while True:
        choice = input(f"\n{Fore.CYAN}Select source #(s) for action (comma-separated, or 'skip'/'c'): {Style.RESET_ALL}").strip()

        if choice.lower() == 'c':
            return None
        if choice.lower() == 'skip':
            break

        try:
            indices = [int(x.strip()) - 1 for x in choice.split(',')]
            if all(0 <= idx < len(sources) for idx in indices):
                assessment_sources['action'] = [sources[idx]['source_id'] for idx in indices]
                break
            else:
                print(f"{Fore.RED}Invalid selection. Please choose numbers 1-{len(sources)}.{Style.RESET_ALL}")
        except ValueError:
            print(f"{Fore.RED}Invalid input. Please enter comma-separated numbers, 'skip', or 'c'.{Style.RESET_ALL}")

    return assessment_sources


def confirm_main_body_or_detached() -> Optional[Tuple[bool, str]]:
    """
    Ask analyst if this is main body or detached element.

    Returns:
        Tuple of (is_main_body: bool, reinforced_value: str) or None to cancel
    """
    print(f"\n{Fore.CYAN}{'='*80}")
    print(f"CONFIRM POSITION TYPE")
    print(f"{'='*80}{Style.RESET_ALL}\n")

    while True:
        choice = input(f"{Fore.CYAN}Is this MAIN BODY or DETACHED element? (m/d/c): {Style.RESET_ALL}").strip().lower()

        if choice == 'c':
            return None

        if choice == 'm':
            is_main_body = True
            # Ask for reinforced modifier
            reinforced = input(f"{Fore.CYAN}Enter reinforced modifier (or press Enter for none): {Style.RESET_ALL}").strip()
            if not reinforced:
                reinforced = None
            return (is_main_body, reinforced)

        elif choice == 'd':
            is_main_body = False
            reinforced = '-'  # Detached elements always use '-'
            print(f"{Fore.YELLOW}Detached element: reinforced will be set to '-'{Style.RESET_ALL}")
            return (is_main_body, reinforced)

        else:
            print(f"{Fore.RED}Invalid input. Please enter 'm' for main body, 'd' for detached, or 'c' to cancel.{Style.RESET_ALL}")


# ============================================================================
# FR-3: DATA AGGREGATION LOGIC
# ============================================================================

def aggregate_mention_data(
    conn,
    mention_ids: List[int],
    location_source_id: int,
    assessment_sources: Dict[str, int],
    is_main_body: bool,
    reinforced: Optional[str]
) -> Optional[Dict]:
    """
    Aggregate data from selected mentions based on analyst's source choices.

    Args:
        conn: Database connection
        mention_ids: List of mention IDs to aggregate
        location_source_id: Source ID to use for location data
        assessment_sources: Dict mapping field names to source IDs
        is_main_body: True if this is main body position
        reinforced: Reinforced modifier value

    Returns:
        Dictionary with aggregated data for INSERT or None if validation fails
    """
    # Get all selected mentions
    query = """
        SELECT
            um.*,
            ST_Y(um.location) as latitude,
            ST_X(um.location) as longitude,
            s.source_name,
            s.source_origin,
            s.self as source_self_reported,
            s.source_credibility
        FROM unit_mentions um
        JOIN sources s ON um.source_id = s.source_id
        WHERE um.mention_id = ANY(%s)
    """

    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(query, (mention_ids,))
        mentions = cur.fetchall()

    # Validation: Check all mentions are from same unit
    unit_identifiers = set()
    for m in mentions:
        uid = m['unit_key'] or m['unknown_unit_key']
        unit_identifiers.add(uid)

    if len(unit_identifiers) > 1:
        print(f"{Fore.RED}✗ Error: Selected mentions are from different units: {unit_identifiers}{Style.RESET_ALL}")
        return None

    unit_identifier = unit_identifiers.pop()

    # Get location data from selected source
    location_mention = next((m for m in mentions if m['source_id'] == location_source_id), None)
    if not location_mention:
        print(f"{Fore.RED}✗ Error: Location source ID {location_source_id} not found in selected mentions.{Style.RESET_ALL}")
        return None

    # Build aggregated record
    aggregated = {
        'unit_key': unit_identifier,
        'observation_date': max(m['observation_date'] for m in mentions),  # Use latest date
        'tactical_area_id': location_mention['tactical_area_id'],
        'operational_area_id': location_mention['operational_area_id'],
        'adm4_pcode': location_mention['adm4_pcode'],
        'location': location_mention['location'],
        'latitude': location_mention['latitude'],
        'longitude': location_mention['longitude'],
        'operational_condition': None,
        'status': None,
        'reinforced': reinforced,
        'action': None,
        'analyst': ANALYST_NAME,
        'is_main_body': is_main_body
    }

    # Get assessment data from selected sources
    if 'operational_condition' in assessment_sources:
        op_cond_mention = next((m for m in mentions if m['source_id'] == assessment_sources['operational_condition']), None)
        if op_cond_mention:
            aggregated['operational_condition'] = op_cond_mention['operational_condition']

    if 'status' in assessment_sources:
        status_mention = next((m for m in mentions if m['source_id'] == assessment_sources['status']), None)
        if status_mention:
            aggregated['status'] = status_mention['status']

    if 'action' in assessment_sources:
        action_sources = assessment_sources['action'] if isinstance(assessment_sources['action'], list) else [assessment_sources['action']]
        actions = []
        for source_id in action_sources:
            action_mention = next((m for m in mentions if m['source_id'] == source_id), None)
            if action_mention and action_mention['action']:
                actions.append(action_mention['action'])
        if actions:
            aggregated['action'] = '; '.join(actions)

    # Build source attribution string
    location_source = get_source_details(conn, location_source_id)
    source_parts = []

    # Location attribution
    self_reported = 'Y' if location_source['source_self_reported'] else 'N'
    source_parts.append(
        f"Location: {location_source['source_name']} "
        f"({location_source['source_origin']}, self-reported: {self_reported})"
    )

    # Assessment attribution
    assessment_source_ids = set()
    for field, source_id in assessment_sources.items():
        if isinstance(source_id, list):
            assessment_source_ids.update(source_id)
        else:
            assessment_source_ids.add(source_id)

    # Remove location source if it's also used for assessment
    assessment_source_ids.discard(location_source_id)

    if assessment_source_ids:
        assessment_parts = []
        for source_id in assessment_source_ids:
            source = get_source_details(conn, source_id)
            if source:
                assessment_parts.append(
                    f"{source['source_name']} "
                    f"({source['source_origin']}, credibility: {source['source_credibility'] or 'N/A'})"
                )
        if assessment_parts:
            source_parts.append(f"Assessment: {', '.join(assessment_parts)}")

    aggregated['source'] = '. '.join(source_parts) + '.'

    return aggregated


# ============================================================================
# FR-4: DATABASE COMMIT OPERATIONS
# ============================================================================

def commit_to_unit_positions(conn, aggregated_data: Dict) -> Optional[int]:
    """
    INSERT aggregated record into unit_positions table.

    Args:
        conn: Database connection
        aggregated_data: Dictionary with aggregated data

    Returns:
        New observation_id or None on failure
    """
    # Build INSERT statement
    if aggregated_data['location'] is not None:
        # Location is already a PostGIS geometry object from the query
        query = """
            INSERT INTO unit_positions (
                unit_key,
                observation_date,
                tactical_area_id,
                operational_area_id,
                adm4_pcode,
                location,
                operational_condition,
                status,
                reinforced,
                action,
                source,
                analyst,
                created_date
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, CURRENT_TIMESTAMP
            )
            RETURNING observation_id
        """

        params = (
            aggregated_data['unit_key'],
            aggregated_data['observation_date'],
            aggregated_data['tactical_area_id'],
            aggregated_data['operational_area_id'],
            aggregated_data['adm4_pcode'],
            aggregated_data['location'],  # Already a geometry object
            aggregated_data['operational_condition'],
            aggregated_data['status'],
            aggregated_data['reinforced'],
            aggregated_data['action'],
            aggregated_data['source'],
            aggregated_data['analyst']
        )
    else:
        # No location, insert NULL
        query = """
            INSERT INTO unit_positions (
                unit_key,
                observation_date,
                tactical_area_id,
                operational_area_id,
                adm4_pcode,
                location,
                operational_condition,
                status,
                reinforced,
                action,
                source,
                analyst,
                created_date
            ) VALUES (
                %s, %s, %s, %s, %s, NULL, %s, %s, %s, %s, %s, %s, CURRENT_TIMESTAMP
            )
            RETURNING observation_id
        """

        params = (
            aggregated_data['unit_key'],
            aggregated_data['observation_date'],
            aggregated_data['tactical_area_id'],
            aggregated_data['operational_area_id'],
            aggregated_data['adm4_pcode'],
            aggregated_data['operational_condition'],
            aggregated_data['status'],
            aggregated_data['reinforced'],
            aggregated_data['action'],
            aggregated_data['source'],
            aggregated_data['analyst']
        )

    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, params)
            result = cur.fetchone()
            return result['observation_id']
    except psycopg2.Error as e:
        print(f"{Fore.RED}✗ Error inserting into unit_positions: {e}{Style.RESET_ALL}")
        return None


def mark_mentions_committed(conn, mention_ids: List[int], observation_id: int) -> bool:
    """
    Mark unit_mentions as committed with link to observation_id.

    Args:
        conn: Database connection
        mention_ids: List of mention IDs to mark as committed
        observation_id: The observation_id they were committed to

    Returns:
        True on success, False on failure
    """
    query = """
        UPDATE unit_mentions
        SET committed_date = CURRENT_TIMESTAMP,
            committed_to_position_id = %s
        WHERE mention_id = ANY(%s)
    """

    try:
        with conn.cursor() as cur:
            cur.execute(query, (observation_id, mention_ids))
            return True
    except psycopg2.Error as e:
        print(f"{Fore.RED}✗ Error marking mentions as committed: {e}{Style.RESET_ALL}")
        return False


def update_russian_units_if_main_body(conn, aggregated_data: Dict) -> bool:
    """
    Update russian_units table with current position if this is main body.

    Args:
        conn: Database connection
        aggregated_data: Dictionary with aggregated data

    Returns:
        True on success or if not applicable, False on failure
    """
    unit_key = aggregated_data['unit_key']

    # Only update if main body and confirmed unit (x##### or y#####)
    if not aggregated_data['is_main_body']:
        return True  # Not an error, just not applicable

    if not (unit_key.startswith('x') or unit_key.startswith('y')):
        return True  # Unknown unit, skip update

    # Only update if we have location
    if aggregated_data['latitude'] is None or aggregated_data['longitude'] is None:
        return True  # No location to update

    query = """
        UPDATE russian_units
        SET current_lat = %s,
            current_long = %s,
            current_tactical_area_id = %s,
            current_operational_area_id = %s
        WHERE unit_key = %s
    """

    try:
        with conn.cursor() as cur:
            cur.execute(query, (
                aggregated_data['latitude'],
                aggregated_data['longitude'],
                aggregated_data['tactical_area_id'],
                aggregated_data['operational_area_id'],
                unit_key
            ))
            return True
    except psycopg2.Error as e:
        print(f"{Fore.RED}✗ Error updating russian_units: {e}{Style.RESET_ALL}")
        return False


# ============================================================================
# FR-5: ERROR HANDLING AND VALIDATIONS
# ============================================================================

def validate_mentions_pending(conn, mention_ids: List[int]) -> bool:
    """
    Check that all mention_ids are in 'approved' status and not yet committed.

    Args:
        conn: Database connection
        mention_ids: List of mention IDs to validate

    Returns:
        True if all valid, False otherwise
    """
    query = """
        SELECT mention_id, review_status, committed_date
        FROM unit_mentions
        WHERE mention_id = ANY(%s)
    """

    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(query, (mention_ids,))
        mentions = cur.fetchall()

    if len(mentions) != len(mention_ids):
        print(f"{Fore.RED}✗ Error: Some mention IDs not found in database.{Style.RESET_ALL}")
        return False

    for m in mentions:
        if m['review_status'] != 'pending':
            print(f"{Fore.RED}✗ Error: Mention {m['mention_id']} has status '{m['review_status']}', expected 'approved'.{Style.RESET_ALL}")
            return False
        if m['committed_date'] is not None:
            print(f"{Fore.RED}✗ Error: Mention {m['mention_id']} is already committed.{Style.RESET_ALL}")
            return False

    return True


# ============================================================================
# FR-6: CONFIRMATION AND AUDIT
# ============================================================================

def display_commit_preview(aggregated_data: Dict, mention_ids: List[int]):
    """
    Show analyst what will be committed before executing.

    Args:
        aggregated_data: Dictionary with aggregated data
        mention_ids: List of mention IDs being committed
    """
    print(f"\n{Fore.CYAN}{'='*80}")
    print(f"COMMIT PREVIEW")
    print(f"{'='*80}{Style.RESET_ALL}\n")

    print(f"Unit:                {aggregated_data['unit_key']}")
    print(f"Mentions Count:      {len(mention_ids)}")
    print(f"Mention IDs:         {', '.join(map(str, mention_ids))}")
    print(f"Observation Date:    {aggregated_data['observation_date']}")
    print(f"Tactical Area:       {aggregated_data['tactical_area_id']}")
    print(f"Operational Area:    {aggregated_data['operational_area_id']}")
    print(f"Settlement:          {aggregated_data['adm4_pcode'] or 'N/A'}")

    if aggregated_data['latitude'] and aggregated_data['longitude']:
        print(f"Location:            {aggregated_data['latitude']:.6f}, {aggregated_data['longitude']:.6f}")
    else:
        print(f"Location:            Area-level only")

    print(f"Op Condition:        {aggregated_data['operational_condition'] or 'N/A'}")
    print(f"Status:              {aggregated_data['status'] or 'N/A'}")
    print(f"Reinforced:          {aggregated_data['reinforced'] or 'N/A'}")
    print(f"Action:              {aggregated_data['action'][:60] if aggregated_data['action'] else 'N/A'}")
    print(f"Position Type:       {'MAIN BODY' if aggregated_data['is_main_body'] else 'DETACHED ELEMENT'}")
    print(f"\nSource Attribution:\n{aggregated_data['source']}")
    print(f"\nAnalyst:             {aggregated_data['analyst']}")


def confirm_commit() -> bool:
    """
    Get final confirmation from analyst before committing.

    Returns:
        True to proceed, False to cancel
    """
    while True:
        choice = input(f"\n{Fore.CYAN}Proceed with commit? (y/n): {Style.RESET_ALL}").strip().lower()
        if choice == 'y':
            return True
        elif choice == 'n':
            return False
        else:
            print(f"{Fore.RED}Invalid input. Please enter 'y' or 'n'.{Style.RESET_ALL}")


def log_commit_action(observation_id: int, mention_ids: List[int], analyst: str):
    """
    Log successful commit to audit file.

    Args:
        observation_id: The new observation_id
        mention_ids: List of mention IDs committed
        analyst: Analyst name
    """
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_entry = f"{timestamp} | Analyst: {analyst} | observation_id: {observation_id} | mention_ids: {mention_ids}\n"

    try:
        with open('/home/user/workflow_scripts/Database_Architecture/commit_audit.log', 'a') as f:
            f.write(log_entry)
    except Exception as e:
        print(f"{Fore.YELLOW}⚠ Warning: Could not write to audit log: {e}{Style.RESET_ALL}")


# ============================================================================
# MAIN WORKFLOW LOOP
# ============================================================================

def continue_processing() -> bool:
    """
    Ask if analyst wants to process another unit.

    Returns:
        True to continue, False to exit
    """
    while True:
        choice = input(f"\n{Fore.CYAN}Process another unit? (y/n): {Style.RESET_ALL}").strip().lower()
        if choice == 'y':
            return True
        elif choice == 'n':
            return False
        else:
            print(f"{Fore.RED}Invalid input. Please enter 'y' or 'n'.{Style.RESET_ALL}")


def main():
    """Main workflow loop for committing mentions."""
    print(f"\n{Fore.CYAN}{'='*80}")
    print(f"PHASE 2: UNIT MENTIONS COMMIT SCRIPT")
    print(f"Version 1.0")
    print(f"Analyst: {ANALYST_NAME}")
    print(f"{'='*80}{Style.RESET_ALL}\n")

    # Connect to database
    conn = connect_db()

    try:
        while True:
            # Show pending mentions summary
            has_pending = display_pending_summary(conn)
            if not has_pending:
                break

            # Analyst selects unit to process
            unit_identifier = select_unit_for_review(conn)
            if unit_identifier is None:
                break

            # Analyst selects mentions to aggregate
            mention_ids = select_mentions_to_aggregate(conn, unit_identifier)
            if mention_ids is None:
                continue

            # Validate mentions are pending
            if not validate_mentions_pending(conn, mention_ids):
                continue

            # Analyst selects location source
            location_source_id = select_location_source(conn, mention_ids)
            if location_source_id is None:
                continue

            # Analyst selects assessment sources
            assessment_sources = select_assessment_sources(conn, mention_ids)
            if assessment_sources is None:
                continue

            # Analyst confirms main body or detached
            result = confirm_main_body_or_detached()
            if result is None:
                continue
            is_main_body, reinforced = result

            # Aggregate data
            aggregated_data = aggregate_mention_data(
                conn,
                mention_ids,
                location_source_id,
                assessment_sources,
                is_main_body,
                reinforced
            )

            if aggregated_data is None:
                continue

            # Preview and confirm
            display_commit_preview(aggregated_data, mention_ids)

            if not confirm_commit():
                print(f"{Fore.YELLOW}Commit cancelled by analyst.{Style.RESET_ALL}")
                continue

            # Execute commit in transaction
            try:
                # Start transaction
                observation_id = commit_to_unit_positions(conn, aggregated_data)
                if observation_id is None:
                    conn.rollback()
                    print(f"{Fore.RED}✗ Commit failed. Transaction rolled back.{Style.RESET_ALL}")
                    continue

                if not mark_mentions_committed(conn, mention_ids, observation_id):
                    conn.rollback()
                    print(f"{Fore.RED}✗ Commit failed. Transaction rolled back.{Style.RESET_ALL}")
                    continue

                # Update russian_units if main body
                if is_main_body:
                    if not update_russian_units_if_main_body(conn, aggregated_data):
                        conn.rollback()
                        print(f"{Fore.RED}✗ Commit failed. Transaction rolled back.{Style.RESET_ALL}")
                        continue

                # Commit transaction
                conn.commit()

                # Log success
                log_commit_action(observation_id, mention_ids, ANALYST_NAME)
                print(f"\n{Fore.GREEN}✓ Successfully committed observation_id {observation_id}{Style.RESET_ALL}")

            except psycopg2.Error as e:
                conn.rollback()
                print(f"{Fore.RED}✗ Database error: {e}{Style.RESET_ALL}")
                print(f"{Fore.RED}Transaction rolled back.{Style.RESET_ALL}")
                continue

            # Ask if analyst wants to continue
            if not continue_processing():
                break

    finally:
        conn.close()
        print(f"\n{Fore.CYAN}Database connection closed. Goodbye!{Style.RESET_ALL}\n")


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n\n{Fore.YELLOW}Script interrupted by user. Exiting...{Style.RESET_ALL}\n")
        sys.exit(0)
    except Exception as e:
        print(f"\n{Fore.RED}✗ Unexpected error: {e}{Style.RESET_ALL}\n")
        import traceback
        traceback.print_exc()
        sys.exit(1)
