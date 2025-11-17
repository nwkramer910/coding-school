#!/usr/bin/env python3
"""
Phase 2: Unit Mentions Commit Script - GUI Version
Version: 2.0
Date: 2024-11-08

GUI application for reviewing staged unit mentions and committing them
to the authoritative unit_positions table.
"""

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime
from typing import List, Dict, Optional
import sys

# Configuration
ANALYST_NAME = 'nkramer'
DB_HOST = 'localhost'
DB_NAME = 'russianorbatukraine'
DB_USER = 'postgres'
DB_PASSWORD = 'Sep10mber'
DB_PORT = 5432
SRID = 4326


# ============================================================================
# DATABASE CONNECTION AND QUERY FUNCTIONS
# ============================================================================

class DatabaseManager:
    """Handles all database operations."""

    def __init__(self):
        self.conn = None

    def connect(self, password: str) -> bool:
        """Connect to PostgreSQL database."""
        try:
            self.conn = psycopg2.connect(
                host=DB_HOST,
                database=DB_NAME,
                user=DB_USER,
                password=password,
                port=DB_PORT
            )
            return True
        except psycopg2.Error as e:
            messagebox.showerror("Connection Error", f"Failed to connect to database:\n{e}")
            return False

    def get_pending_units(self) -> List[Dict]:
        """Get summary of units with pending mentions."""
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

        with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query)
            return cur.fetchall()

    def get_unit_mentions(self, unit_identifier: str) -> List[Dict]:
        """Get all pending mentions for a specific unit."""
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
                ST_Y(um.location) as latitude,
                ST_X(um.location) as longitude,
                um.location,
                um.location_precision,
                um.operational_condition,
                um.status,
                um.reinforced,
                um.action,
                um.is_detached_element,
                um.is_main_body,
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

        with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, (unit_identifier, unit_identifier))
            return cur.fetchall()

    def get_source_details(self, source_id: int) -> Optional[Dict]:
        """Get details for a specific source."""
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

        with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, (source_id,))
            return cur.fetchone()

    def commit_position(self, aggregated_data: Dict) -> Optional[int]:
        """Insert aggregated record into unit_positions."""
        if aggregated_data['location'] is not None:
            query = """
                INSERT INTO unit_positions (
                    unit_key, observation_date, tactical_area_id, operational_area_id,
                    adm4_pcode, location, operational_condition, status,
                    reinforced, action, source_id, source_url, analyst, created_date
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, CURRENT_TIMESTAMP
                )
                RETURNING observation_id
            """
            params = (
                aggregated_data['unit_key'],
                aggregated_data['observation_date'],
                aggregated_data['tactical_area_id'],
                aggregated_data['operational_area_id'],
                aggregated_data['adm4_pcode'],
                aggregated_data['location'],
                aggregated_data['operational_condition'],
                aggregated_data['status'],
                aggregated_data['reinforced'],
                aggregated_data['action'],
                aggregated_data.get('source_id'),
                aggregated_data.get('source_url'),
                aggregated_data['analyst']
            )
        else:
            query = """
                INSERT INTO unit_positions (
                    unit_key, observation_date, tactical_area_id, operational_area_id,
                    adm4_pcode, location, operational_condition, status,
                    reinforced, action, source_id, source_url, analyst, created_date
                ) VALUES (
                    %s, %s, %s, %s, %s, NULL, %s, %s, %s, %s, %s, %s, %s, CURRENT_TIMESTAMP
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
                aggregated_data.get('source_id'),
                aggregated_data.get('source_url'),
                aggregated_data['analyst']
            )

        try:
            with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute(query, params)
                result = cur.fetchone()
                return result['observation_id']
        except psycopg2.Error as e:
            messagebox.showerror("Database Error", f"Failed to commit position:\n{e}")
            return None

    def mark_mentions_committed(self, mention_ids: List[int], observation_id: int) -> bool:
        """Mark mentions as committed."""
        query = """
            UPDATE unit_mentions
            SET committed_date = CURRENT_TIMESTAMP,
                committed_to_position_id = %s
            WHERE mention_id = ANY(%s)
        """

        try:
            with self.conn.cursor() as cur:
                cur.execute(query, (observation_id, mention_ids))
                return True
        except psycopg2.Error as e:
            messagebox.showerror("Database Error", f"Failed to mark mentions:\n{e}")
            return False

    def load_symbology_reference_data(self) -> Dict:
        """Load symbology reference data for dropdowns."""
        reference_data = {}

        try:
            with self.conn.cursor() as cur:
                # Load identity codes
                cur.execute("SELECT code, description FROM reference.identity_codes ORDER BY code")
                reference_data['identity_'] = [(row[0], f"{row[0]} - {row[1]}") for row in cur.fetchall()]

                # Load symbolset codes
                cur.execute("SELECT code, description FROM reference.symbolset_codes ORDER BY code")
                reference_data['symbolset'] = [(row[0], f"{row[0]} - {row[1]}") for row in cur.fetchall()]

                # Load symbolentity codes
                cur.execute("SELECT code, display_name FROM reference.symbology_entity_codes ORDER BY code")
                reference_data['symbolentity'] = [(row[0], f"{row[0]} - {row[1]}") for row in cur.fetchall()]

                # Load echelon codes
                cur.execute("SELECT code, description FROM reference.echelon_codes ORDER BY hierarchy_level")
                reference_data['echelon'] = [(row[0], f"{row[0]} - {row[1]}") for row in cur.fetchall()]

                # Load modifier1 codes
                cur.execute("SELECT code, description FROM reference.modifier_1_amplifiers ORDER BY code")
                reference_data['modifier1'] = [(None, "-- None --")] + [(row[0], f"{row[0]} - {row[1]}") for row in cur.fetchall()]

                # Load modifier2 codes
                cur.execute("SELECT code, description FROM reference.modifier_2_amplifiers ORDER BY code")
                modifier2_results = cur.fetchall()
                if modifier2_results:
                    reference_data['modifier2'] = [(None, "-- None --")] + [(row[0], f"{row[0]} - {row[1]}") for row in modifier2_results]
                else:
                    reference_data['modifier2'] = [(None, "-- None --")]

                return reference_data

        except psycopg2.Error as e:
            messagebox.showerror("Database Error", f"Failed to load reference data:\n{e}")
            return {}

    def insert_unknown_unit(self, unknown_unit_data: Dict) -> bool:
        """Insert new unknown unit with symbology."""
        query = """
            INSERT INTO unknown_units (
                unknown_unit_key, provisional_name, unknown_category, element_type,
                parent_unit_key, parent_unit_name, estimated_echelon,
                identity_, context, symbolset, symbolentity,
                modifier1, modifier2, specialentitysubtype, echelon, hq_indicator,
                uniquedesignation, higherformation,
                current_lat, current_long, last_observed,
                operational_area_id, tactical_area_id,
                operational_condition, status, reinforced,
                discovered_by, analyst_notes, tracking_priority,
                first_mentioned, last_mentioned, mention_count,
                created_date, updated_date
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s, %s,
                %s, %s, 1,
                CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
            )
        """

        try:
            with self.conn.cursor() as cur:
                cur.execute(query, (
                    unknown_unit_data['unknown_unit_key'],
                    unknown_unit_data.get('provisional_name', 'Unknown Unit'),
                    unknown_unit_data['unknown_category'],
                    unknown_unit_data.get('element_type'),
                    unknown_unit_data.get('parent_unit_key'),
                    unknown_unit_data.get('parent_unit_name'),
                    unknown_unit_data.get('estimated_echelon'),
                    unknown_unit_data.get('identity_'),
                    unknown_unit_data.get('context', 0),
                    unknown_unit_data.get('symbolset'),
                    unknown_unit_data.get('symbolentity'),
                    unknown_unit_data.get('modifier1'),
                    unknown_unit_data.get('modifier2'),
                    unknown_unit_data.get('specialentitysubtype'),
                    unknown_unit_data.get('echelon'),
                    unknown_unit_data.get('hq_indicator', 0),
                    unknown_unit_data.get('uniquedesignation', 'UNK'),
                    unknown_unit_data.get('higherformation'),
                    unknown_unit_data.get('current_lat'),
                    unknown_unit_data.get('current_long'),
                    unknown_unit_data.get('last_observed'),
                    unknown_unit_data.get('operational_area_id'),
                    unknown_unit_data.get('tactical_area_id'),
                    unknown_unit_data.get('operational_condition'),
                    unknown_unit_data.get('status'),
                    unknown_unit_data.get('reinforced'),
                    unknown_unit_data.get('discovered_by', ANALYST_NAME),
                    unknown_unit_data.get('analyst_notes'),
                    unknown_unit_data.get('tracking_priority', 3),
                    unknown_unit_data.get('first_mentioned'),
                    unknown_unit_data.get('last_mentioned')
                ))
                return True
        except psycopg2.Error as e:
            messagebox.showerror("Database Error", f"Failed to insert unknown unit:\n{e}")
            return False

    def close(self):
        """Close database connection."""
        if self.conn:
            self.conn.close()


# ============================================================================
# LOGIN SCREEN
# ============================================================================

class LoginScreen(tk.Frame):
    """Database login screen."""

    def __init__(self, parent, on_success):
        super().__init__(parent)
        self.on_success = on_success
        self.db = DatabaseManager()

        self.pack(fill=tk.BOTH, expand=True)
        self.create_widgets()

    def create_widgets(self):
        # Center frame
        center_frame = ttk.Frame(self, padding="20")
        center_frame.place(relx=0.5, rely=0.5, anchor=tk.CENTER)

        # Title
        ttk.Label(center_frame, text="Phase 2: Unit Mentions Commit",
                 font=('Arial', 16, 'bold')).grid(row=0, column=0, columnspan=2, pady=10)

        # Database info
        ttk.Label(center_frame, text=f"Database: {DB_NAME}").grid(row=1, column=0, columnspan=2, pady=5)
        ttk.Label(center_frame, text=f"Host: {DB_HOST}").grid(row=2, column=0, columnspan=2, pady=5)
        ttk.Label(center_frame, text=f"User: {DB_USER}").grid(row=3, column=0, columnspan=2, pady=5)

        # Password field
        ttk.Label(center_frame, text="Password:").grid(row=4, column=0, sticky=tk.E, pady=10, padx=5)
        self.password_var = tk.StringVar()
        password_entry = ttk.Entry(center_frame, textvariable=self.password_var, show="*", width=30)
        password_entry.grid(row=4, column=1, pady=10, padx=5)
        password_entry.bind('<Return>', lambda e: self.login())
        password_entry.focus()

        # Login button
        ttk.Button(center_frame, text="Connect", command=self.login).grid(row=5, column=0, columnspan=2, pady=10)

    def login(self):
        password = self.password_var.get()
        if not password:
            messagebox.showwarning("Input Required", "Please enter password")
            return

        if self.db.connect(password):
            self.on_success(self.db)


# ============================================================================
# PENDING MENTIONS SUMMARY SCREEN
# ============================================================================

class PendingUnitsScreen(tk.Frame):
    """Screen showing all units with pending mentions."""

    def __init__(self, parent, db: DatabaseManager, on_process_units):
        super().__init__(parent)
        self.db = db
        self.on_process_units = on_process_units
        self.units = []

        self.pack(fill=tk.BOTH, expand=True)
        self.create_widgets()
        self.load_data()

    def create_widgets(self):
        # Header
        header_frame = ttk.Frame(self, padding="10")
        header_frame.pack(fill=tk.X)

        ttk.Label(header_frame, text="Pending Mentions Summary",
                 font=('Arial', 14, 'bold')).pack(side=tk.LEFT)

        # Table frame
        table_frame = ttk.Frame(self, padding="10")
        table_frame.pack(fill=tk.BOTH, expand=True)

        # Create Treeview
        columns = ("#", "Unit ID", "Unit Name", "Mentions", "Areas", "Date Range")
        self.tree = ttk.Treeview(table_frame, columns=columns, show='headings', height=15)

        # Define headings
        self.tree.heading("#", text="#")
        self.tree.heading("Unit ID", text="Unit ID")
        self.tree.heading("Unit Name", text="Unit Name")
        self.tree.heading("Mentions", text="Mentions")
        self.tree.heading("Areas", text="Areas")
        self.tree.heading("Date Range", text="Date Range")

        # Define column widths
        self.tree.column("#", width=50)
        self.tree.column("Unit ID", width=100)
        self.tree.column("Unit Name", width=300)
        self.tree.column("Mentions", width=80)
        self.tree.column("Areas", width=80)
        self.tree.column("Date Range", width=200)

        # Scrollbars
        vsb = ttk.Scrollbar(table_frame, orient="vertical", command=self.tree.yview)
        hsb = ttk.Scrollbar(table_frame, orient="horizontal", command=self.tree.xview)
        self.tree.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)

        # Grid layout
        self.tree.grid(row=0, column=0, sticky='nsew')
        vsb.grid(row=0, column=1, sticky='ns')
        hsb.grid(row=1, column=0, sticky='ew')

        table_frame.columnconfigure(0, weight=1)
        table_frame.rowconfigure(0, weight=1)

        # Selection frame
        selection_frame = ttk.Frame(self, padding="10")
        selection_frame.pack(fill=tk.X)

        ttk.Label(selection_frame, text="Select units to process (e.g., '1-5' or '1,3,5'):").pack(side=tk.LEFT, padx=5)
        self.selection_var = tk.StringVar()
        ttk.Entry(selection_frame, textvariable=self.selection_var, width=30).pack(side=tk.LEFT, padx=5)
        ttk.Button(selection_frame, text="Process Selected Units",
                  command=self.process_units).pack(side=tk.LEFT, padx=5)

    def load_data(self):
        """Load pending units from database."""
        self.units = self.db.get_pending_units()

        # Clear existing items
        for item in self.tree.get_children():
            self.tree.delete(item)

        # Add units to tree
        for idx, unit in enumerate(self.units, 1):
            unit_id = unit['unit_identifier']
            unit_name = unit['unit_name'] or 'Unknown Unit'
            mention_count = unit['mention_count']
            area_count = unit['area_count']
            date_range = f"{unit['earliest_date'].date()} to {unit['latest_date'].date()}"

            self.tree.insert('', tk.END, values=(idx, unit_id, unit_name, mention_count, area_count, date_range))

    def process_units(self):
        """Parse selection and start processing."""
        selection = self.selection_var.get().strip()
        if not selection:
            messagebox.showwarning("Input Required", "Please enter unit numbers to process")
            return

        try:
            selected_indices = self.parse_selection(selection)
            if not selected_indices:
                messagebox.showwarning("Invalid Selection", "No valid unit numbers selected")
                return

            # Get selected units
            selected_units = [self.units[i-1] for i in selected_indices if 0 < i <= len(self.units)]

            if not selected_units:
                messagebox.showwarning("Invalid Selection", "Selected unit numbers are out of range")
                return

            self.on_process_units(selected_units)

        except ValueError as e:
            messagebox.showerror("Invalid Input", f"Invalid selection format:\n{e}")

    def parse_selection(self, selection: str) -> List[int]:
        """Parse selection string into list of indices."""
        indices = []
        parts = selection.split(',')

        for part in parts:
            part = part.strip()
            if '-' in part:
                # Range
                start, end = part.split('-')
                start, end = int(start.strip()), int(end.strip())
                indices.extend(range(start, end + 1))
            else:
                # Single number
                indices.append(int(part))

        return sorted(set(indices))


# ============================================================================
# UNIT PROCESSING SCREEN
# ============================================================================

class UnitProcessingScreen(tk.Frame):
    """Screen for processing individual units."""

    def __init__(self, parent, db: DatabaseManager, units: List[Dict], on_complete):
        super().__init__(parent)
        self.db = db
        self.units = units
        self.on_complete = on_complete
        self.current_index = 0
        self.processed_units = []
        self.current_mentions = []
        self.symbology_reference_data = {}
        self.symbology_vars = {}

        # Load symbology reference data
        self.symbology_reference_data = self.db.load_symbology_reference_data()

        self.pack(fill=tk.BOTH, expand=True)
        self.create_widgets()
        self.load_unit()

    def create_widgets(self):
        # Header
        header_frame = ttk.Frame(self, padding="10")
        header_frame.pack(fill=tk.X)

        self.header_label = ttk.Label(header_frame, text="", font=('Arial', 14, 'bold'))
        self.header_label.pack(side=tk.LEFT)

        self.progress_label = ttk.Label(header_frame, text="")
        self.progress_label.pack(side=tk.RIGHT)

        # Mentions table
        table_frame = ttk.LabelFrame(self, text="Pending Mentions", padding="10")
        table_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)

        columns = ("ID", "Date", "Tac Area", "Source", "Self?", "Cred", "Location", "OpCond", "Status", "Action")
        self.tree = ttk.Treeview(table_frame, columns=columns, show='headings', height=8)

        for col in columns:
            self.tree.heading(col, text=col)
            if col == "ID":
                self.tree.column(col, width=50)
            elif col in ("Date", "Tac Area", "Self?", "Cred", "OpCond", "Status"):
                self.tree.column(col, width=80)
            elif col == "Source":
                self.tree.column(col, width=200)
            elif col == "Location":
                self.tree.column(col, width=100)
            else:
                self.tree.column(col, width=150)

        vsb = ttk.Scrollbar(table_frame, orient="vertical", command=self.tree.yview)
        self.tree.configure(yscrollcommand=vsb.set)

        self.tree.grid(row=0, column=0, sticky='nsew')
        vsb.grid(row=0, column=1, sticky='ns')

        table_frame.columnconfigure(0, weight=1)
        table_frame.rowconfigure(0, weight=1)

        # Source selection frame
        source_frame = ttk.LabelFrame(self, text="Source Selection", padding="10")
        source_frame.pack(fill=tk.X, padx=10, pady=5)

        # Definitive source question
        definitive_frame = ttk.Frame(source_frame)
        definitive_frame.pack(fill=tk.X, pady=5)

        ttk.Label(definitive_frame, text="Is there a definitive source? If yes, enter mention ID. If no, enter 0:",
                 font=('Arial', 10, 'bold')).pack(side=tk.LEFT, padx=5)
        self.definitive_var = tk.StringVar(value="0")
        definitive_entry = ttk.Entry(definitive_frame, textvariable=self.definitive_var, width=10)
        definitive_entry.pack(side=tk.LEFT, padx=5)
        self.definitive_var.trace('w', self.on_definitive_change)

        # Dropdown frame (shown when definitive is 0)
        self.dropdown_frame = ttk.Frame(source_frame)
        self.dropdown_frame.pack(fill=tk.X, pady=5)

        # Create dropdown rows
        dropdown_labels = [
            ("Location Source:", "location_source"),
            ("Operational Condition Source:", "op_condition_source"),
            ("Status Source:", "status_source"),
            ("Action Source:", "action_source"),
            ("Unit Type:", "unit_type"),
            ("Reinforced:", "reinforced")
        ]

        self.dropdown_vars = {}
        for idx, (label, var_name) in enumerate(dropdown_labels):
            row_frame = ttk.Frame(self.dropdown_frame)
            row_frame.grid(row=idx, column=0, sticky=tk.W, pady=2)

            ttk.Label(row_frame, text=label, width=30).pack(side=tk.LEFT, padx=5)

            var = tk.StringVar()
            self.dropdown_vars[var_name] = var

            if var_name == "unit_type":
                combo = ttk.Combobox(row_frame, textvariable=var, width=40, state='readonly')
                combo['values'] = [
                    'Known Unit - Main Body',
                    'Known Unit - Detached Element',
                    'Unknown Subordinate Element (za)',
                    'Unknown Asset (zb)'
                ]
                combo.current(0)
            elif var_name == "reinforced":
                combo = ttk.Combobox(row_frame, textvariable=var, width=30)
                combo['values'] = ['', '+', '-', '(+)', '(-)']
            else:
                combo = ttk.Combobox(row_frame, textvariable=var, width=30, state='readonly')

            combo.pack(side=tk.LEFT, padx=5)

        # Preview frame
        preview_frame = ttk.LabelFrame(self, text="Preview", padding="10")
        preview_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)

        self.preview_text = scrolledtext.ScrolledText(preview_frame, height=8, wrap=tk.WORD)
        self.preview_text.pack(fill=tk.BOTH, expand=True)

        # Navigation buttons
        button_frame = ttk.Frame(self, padding="10")
        button_frame.pack(fill=tk.X)

        ttk.Button(button_frame, text="< Skip", command=self.skip_unit).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Process & Next >", command=self.process_and_next).pack(side=tk.RIGHT, padx=5)

        # Create symbology side pane (initially hidden)
        self.create_symbology_pane()

        # Bind unit_type change to show/hide symbology pane
        self.dropdown_vars['unit_type'].trace('w', self.on_unit_type_changed)

    def create_symbology_pane(self):
        """Create collapsible symbology side pane for unknown units."""
        # Create side pane frame (pack to right side)
        self.symbology_pane = ttk.LabelFrame(self, text="Unknown Unit Symbology", padding="10")
        # Don't pack it yet - will be shown/hidden based on selection

        # Scrollable frame for symbology fields
        canvas = tk.Canvas(self.symbology_pane, width=300)
        scrollbar = ttk.Scrollbar(self.symbology_pane, orient="vertical", command=canvas.yview)
        scrollable_frame = ttk.Frame(canvas)

        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )

        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)

        canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        row = 0

        # Provisional Name
        ttk.Label(scrollable_frame, text="Provisional Name:", font=('Arial', 9, 'bold')).grid(row=row, column=0, sticky=tk.W, pady=5)
        row += 1
        self.symbology_vars['provisional_name'] = tk.StringVar()
        ttk.Entry(scrollable_frame, textvariable=self.symbology_vars['provisional_name'], width=30).grid(row=row, column=0, pady=2, sticky=tk.EW)
        row += 1

        # Element Type
        ttk.Label(scrollable_frame, text="Element Type:").grid(row=row, column=0, sticky=tk.W, pady=5)
        row += 1
        self.symbology_vars['element_type'] = tk.StringVar()
        ttk.Entry(scrollable_frame, textvariable=self.symbology_vars['element_type'], width=30).grid(row=row, column=0, pady=2, sticky=tk.EW)
        row += 1

        # Parent Unit
        ttk.Label(scrollable_frame, text="Parent Unit Key:").grid(row=row, column=0, sticky=tk.W, pady=5)
        row += 1
        self.symbology_vars['parent_unit_key'] = tk.StringVar()
        ttk.Entry(scrollable_frame, textvariable=self.symbology_vars['parent_unit_key'], width=30).grid(row=row, column=0, pady=2, sticky=tk.EW)
        row += 1

        # Parent Unit Name
        ttk.Label(scrollable_frame, text="Parent Unit Name:").grid(row=row, column=0, sticky=tk.W, pady=5)
        row += 1
        self.symbology_vars['parent_unit_name'] = tk.StringVar()
        ttk.Entry(scrollable_frame, textvariable=self.symbology_vars['parent_unit_name'], width=30).grid(row=row, column=0, pady=2, sticky=tk.EW)
        row += 1

        ttk.Separator(scrollable_frame, orient='horizontal').grid(row=row, column=0, sticky='ew', pady=10)
        row += 1

        # Required Symbology Fields
        ttk.Label(scrollable_frame, text="Required Symbology:", font=('Arial', 9, 'bold', 'underline')).grid(row=row, column=0, sticky=tk.W)
        row += 1

        # Identity (MUST HAVE)
        tk.Label(scrollable_frame, text="Identity *", fg="red", font=('Arial', 9)).grid(row=row, column=0, sticky=tk.W, pady=2)
        row += 1
        self.symbology_vars['identity_'] = ttk.Combobox(scrollable_frame,
            values=[item[1] for item in self.symbology_reference_data.get('identity_', [])],
            state='readonly', width=28)
        self.symbology_vars['identity_'].grid(row=row, column=0, pady=2, sticky=tk.EW)
        row += 1

        # Symbol Set (MUST HAVE)
        tk.Label(scrollable_frame, text="Symbol Set *", fg="red", font=('Arial', 9)).grid(row=row, column=0, sticky=tk.W, pady=2)
        row += 1
        self.symbology_vars['symbolset'] = ttk.Combobox(scrollable_frame,
            values=[item[1] for item in self.symbology_reference_data.get('symbolset', [])],
            state='readonly', width=28)
        self.symbology_vars['symbolset'].grid(row=row, column=0, pady=2, sticky=tk.EW)
        row += 1

        # Symbol Entity (MUST HAVE)
        tk.Label(scrollable_frame, text="Symbol Entity *", fg="red", font=('Arial', 9)).grid(row=row, column=0, sticky=tk.W, pady=2)
        row += 1
        self.symbology_vars['symbolentity'] = ttk.Combobox(scrollable_frame,
            values=[item[1] for item in self.symbology_reference_data.get('symbolentity', [])],
            state='readonly', width=28)
        self.symbology_vars['symbolentity'].grid(row=row, column=0, pady=2, sticky=tk.EW)
        row += 1

        # Echelon (MUST HAVE)
        tk.Label(scrollable_frame, text="Echelon *", fg="red", font=('Arial', 9)).grid(row=row, column=0, sticky=tk.W, pady=2)
        row += 1
        self.symbology_vars['echelon'] = ttk.Combobox(scrollable_frame,
            values=[item[1] for item in self.symbology_reference_data.get('echelon', [])],
            state='readonly', width=28)
        self.symbology_vars['echelon'].grid(row=row, column=0, pady=2, sticky=tk.EW)
        row += 1

        ttk.Separator(scrollable_frame, orient='horizontal').grid(row=row, column=0, sticky='ew', pady=10)
        row += 1

        # Optional Fields
        ttk.Label(scrollable_frame, text="Optional Symbology:", font=('Arial', 9, 'bold', 'underline')).grid(row=row, column=0, sticky=tk.W)
        row += 1

        # Modifier 1
        ttk.Label(scrollable_frame, text="Modifier 1:").grid(row=row, column=0, sticky=tk.W, pady=2)
        row += 1
        self.symbology_vars['modifier1'] = ttk.Combobox(scrollable_frame,
            values=[item[1] for item in self.symbology_reference_data.get('modifier1', [])],
            state='readonly', width=28)
        self.symbology_vars['modifier1'].grid(row=row, column=0, pady=2, sticky=tk.EW)
        row += 1

        # Modifier 2
        ttk.Label(scrollable_frame, text="Modifier 2:").grid(row=row, column=0, sticky=tk.W, pady=2)
        row += 1
        self.symbology_vars['modifier2'] = ttk.Combobox(scrollable_frame,
            values=[item[1] for item in self.symbology_reference_data.get('modifier2', [])],
            state='readonly', width=28)
        self.symbology_vars['modifier2'].grid(row=row, column=0, pady=2, sticky=tk.EW)
        row += 1

        # Analyst Notes
        ttk.Label(scrollable_frame, text="Analyst Notes:").grid(row=row, column=0, sticky=tk.W, pady=5)
        row += 1
        self.symbology_vars['analyst_notes_text'] = scrolledtext.ScrolledText(scrollable_frame, width=30, height=4)
        self.symbology_vars['analyst_notes_text'].grid(row=row, column=0, pady=2, sticky=tk.EW)
        row += 1

        scrollable_frame.columnconfigure(0, weight=1)

    def on_unit_type_changed(self, *args):
        """Show or hide symbology pane based on unit type selection."""
        unit_type = self.dropdown_vars['unit_type'].get()

        if unit_type in ['Unknown Subordinate Element (za)', 'Unknown Asset (zb)']:
            # Show symbology pane
            self.symbology_pane.pack(side=tk.BOTTOM, fill=tk.BOTH, padx=10, pady=5)
        else:
            # Hide symbology pane
            self.symbology_pane.pack_forget()

    def load_unit(self):
        """Load current unit's mentions."""
        if self.current_index >= len(self.units):
            self.on_complete(self.processed_units)
            return

        unit = self.units[self.current_index]
        unit_id = unit['unit_identifier']
        unit_name = unit['unit_name'] or 'Unknown Unit'

        self.header_label.config(text=f"Processing: {unit_id} - {unit_name}")
        self.progress_label.config(text=f"Unit {self.current_index + 1} of {len(self.units)}")

        # Load mentions
        self.current_mentions = self.db.get_unit_mentions(unit_id)

        # Clear tree
        for item in self.tree.get_children():
            self.tree.delete(item)

        # Populate tree
        for mention in self.current_mentions:
            self.tree.insert('', tk.END, values=(
                mention['mention_id'],
                mention['observation_date'].strftime('%Y-%m-%d'),
                mention['tactical_area_id'] or 'N/A',
                mention['source_name'][:30],
                'Y' if mention['source_self_reported'] else 'N',
                mention['source_credibility'] or 'N/A',
                'Exact' if mention['latitude'] else 'Area',
                mention['operational_condition'] or 'N/A',
                mention['status'] or 'N/A',
                (mention['action'] or '')[:20]
            ))

        # Populate dropdowns with source options
        self.populate_source_dropdowns()

        # Show/hide dropdown frame
        self.on_definitive_change()

    def populate_source_dropdowns(self):
        """Populate source dropdowns based on available mentions."""
        # Get unique sources
        sources = {}
        for mention in self.current_mentions:
            source_id = mention['source_id']
            if source_id not in sources:
                sources[source_id] = {
                    'id': source_id,
                    'name': mention['source_name'],
                    'origin': mention['source_origin'],
                    'self': mention['source_self_reported'],
                    'cred': mention['source_credibility']
                }

        # Build display strings
        source_options = []
        for source in sources.values():
            label = f"{source['name']} ({source['origin']}, "
            if source['self']:
                label += "self-reported, "
            label += f"cred: {source['cred'] or 'N/A'})"
            source_options.append((source['id'], label))

        # Update dropdowns
        for var_name in ['location_source', 'op_condition_source', 'status_source', 'action_source']:
            # Find the combobox widget
            for child in self.dropdown_frame.winfo_children():
                for widget in child.winfo_children():
                    if isinstance(widget, ttk.Combobox) and str(widget['textvariable']) == str(self.dropdown_vars[var_name]):
                        widget['values'] = [label for _, label in source_options]
                        if source_options:
                            widget.current(0)
                        # Store mapping
                        widget.source_map = {label: sid for sid, label in source_options}
                        break

    def on_definitive_change(self, *args):
        """Show/hide dropdown frame based on definitive source input."""
        definitive = self.definitive_var.get().strip()
        if definitive == '0' or not definitive:
            self.dropdown_frame.pack(fill=tk.X, pady=5)
        else:
            self.dropdown_frame.pack_forget()

    def process_and_next(self):
        """Process current unit and move to next."""
        definitive = self.definitive_var.get().strip()

        try:
            if definitive and definitive != '0':
                # Use definitive source
                mention_id = int(definitive)
                mention = next((m for m in self.current_mentions if m['mention_id'] == mention_id), None)
                if not mention:
                    messagebox.showerror("Invalid Input", f"Mention ID {mention_id} not found")
                    return

                aggregated = self.create_aggregated_from_definitive(mention)
            else:
                # Use dropdowns
                aggregated = self.create_aggregated_from_dropdowns()

            if aggregated:
                self.processed_units.append(aggregated)
                self.current_index += 1
                self.load_unit()

        except ValueError as e:
            messagebox.showerror("Invalid Input", str(e))

    def skip_unit(self):
        """Skip current unit."""
        self.current_index += 1
        self.load_unit()

    def extract_symbology_data(self) -> Optional[Dict]:
        """Extract and validate symbology data from the pane."""
        # Get values from dropdowns
        def get_code_from_display(combobox, reference_key):
            """Extract code from 'code - description' display format."""
            display = combobox.get()
            if not display or display == "-- None --":
                return None
            # Extract code from "code - description" format
            parts = display.split(' - ')
            if parts:
                try:
                    return int(parts[0])
                except ValueError:
                    return None
            return None

        # Validate required fields
        required_fields = ['identity_', 'symbolset', 'symbolentity', 'echelon']
        for field in required_fields:
            value = self.symbology_vars[field].get()
            if not value or value == "":
                messagebox.showerror("Validation Error", f"{field} is required for unknown units")
                return None

        # Extract all symbology data
        symbology_data = {
            'provisional_name': self.symbology_vars['provisional_name'].get() or None,
            'element_type': self.symbology_vars['element_type'].get() or None,
            'parent_unit_key': self.symbology_vars['parent_unit_key'].get() or None,
            'parent_unit_name': self.symbology_vars['parent_unit_name'].get() or None,
            'identity_': get_code_from_display(self.symbology_vars['identity_'], 'identity_'),
            'symbolset': get_code_from_display(self.symbology_vars['symbolset'], 'symbolset'),
            'symbolentity': get_code_from_display(self.symbology_vars['symbolentity'], 'symbolentity'),
            'echelon': get_code_from_display(self.symbology_vars['echelon'], 'echelon'),
            'modifier1': get_code_from_display(self.symbology_vars['modifier1'], 'modifier1'),
            'modifier2': get_code_from_display(self.symbology_vars['modifier2'], 'modifier2'),
            'analyst_notes': self.symbology_vars['analyst_notes_text'].get("1.0", tk.END).strip() or None
        }

        return symbology_data

    def create_aggregated_from_definitive(self, mention: Dict) -> Dict:
        """Create aggregated data from a single definitive mention."""
        source = self.db.get_source_details(mention['source_id'])

        return {
            'unit_key': mention['unit_key'] or mention['unknown_unit_key'],
            'observation_date': mention['observation_date'],
            'tactical_area_id': mention['tactical_area_id'],
            'operational_area_id': mention['operational_area_id'],
            'adm4_pcode': mention['adm4_pcode'],
            'location': mention['location'],
            'latitude': mention['latitude'],
            'longitude': mention['longitude'],
            'operational_condition': mention['operational_condition'],
            'status': mention['status'],
            'reinforced': mention['reinforced'],
            'action': mention['action'],
            'analyst': ANALYST_NAME,
            'is_main_body': True,
            'source_id': mention['source_id'],
            'source_url': f"Definitive source: {source['source_name']} ({source['source_origin']}, credibility: {source['source_credibility'] or 'N/A'}).",
            'source_attribution': f"Definitive source: {source['source_name']} ({source['source_origin']}, credibility: {source['source_credibility'] or 'N/A'}).",
            'mention_ids': [mention['mention_id']]
        }

    def create_aggregated_from_dropdowns(self) -> Optional[Dict]:
        """Create aggregated data from dropdown selections."""
        # Get selected sources
        location_source_label = self.dropdown_vars['location_source'].get()
        op_cond_source_label = self.dropdown_vars['op_condition_source'].get()
        status_source_label = self.dropdown_vars['status_source'].get()
        action_source_label = self.dropdown_vars['action_source'].get()
        unit_type = self.dropdown_vars['unit_type'].get()
        reinforced = self.dropdown_vars['reinforced'].get()

        if not location_source_label:
            messagebox.showerror("Input Required", "Please select a location source")
            return None

        # Get source IDs from labels
        location_source_id = None
        op_cond_source_id = None
        status_source_id = None
        action_source_id = None

        for child in self.dropdown_frame.winfo_children():
            for widget in child.winfo_children():
                if isinstance(widget, ttk.Combobox):
                    var = str(widget['textvariable'])
                    if var == str(self.dropdown_vars['location_source']) and hasattr(widget, 'source_map'):
                        location_source_id = widget.source_map.get(location_source_label)
                    elif var == str(self.dropdown_vars['op_condition_source']) and hasattr(widget, 'source_map'):
                        op_cond_source_id = widget.source_map.get(op_cond_source_label)
                    elif var == str(self.dropdown_vars['status_source']) and hasattr(widget, 'source_map'):
                        status_source_id = widget.source_map.get(status_source_label)
                    elif var == str(self.dropdown_vars['action_source']) and hasattr(widget, 'source_map'):
                        action_source_id = widget.source_map.get(action_source_label)

        # Get mentions by source
        location_mention = next((m for m in self.current_mentions if m['source_id'] == location_source_id), None)
        if not location_mention:
            messagebox.showerror("Error", "Could not find mention for selected location source")
            return None

        # Determine unit key based on unit type
        unit_key = None
        is_unknown_unit = False

        if unit_type in ['Unknown Subordinate Element (za)', 'Unknown Asset (zb)']:
            # Auto-generate unknown unit key
            is_unknown_unit = True
            category = 'a' if unit_type == 'Unknown Subordinate Element (za)' else 'b'

            try:
                with self.db.conn.cursor() as cur:
                    cur.execute("SELECT functions.generate_unknown_unit_key(%s)", (category,))
                    unit_key = cur.fetchone()[0]
                    self.db.conn.commit()
                    print(f"Auto-generated unknown unit key: {unit_key}")
            except Exception as e:
                messagebox.showerror("Key Generation Error", f"Failed to generate unknown unit key: {e}")
                return None

            # Extract and validate symbology data
            symbology_data = self.extract_symbology_data()
            if not symbology_data:
                return None  # Validation failed

            # Create unknown_units entry with symbology
            unknown_unit_data = {
                'unknown_unit_key': unit_key,
                'unknown_category': category,
                'provisional_name': symbology_data.get('provisional_name', f'Unknown {category.upper()} Unit'),
                'element_type': symbology_data.get('element_type'),
                'parent_unit_key': symbology_data.get('parent_unit_key'),
                'parent_unit_name': symbology_data.get('parent_unit_name'),
                'estimated_echelon': symbology_data.get('echelon'),
                'identity_': symbology_data.get('identity_'),
                'context': 0,
                'symbolset': symbology_data.get('symbolset'),
                'symbolentity': symbology_data.get('symbolentity'),
                'modifier1': symbology_data.get('modifier1'),
                'modifier2': symbology_data.get('modifier2'),
                'echelon': symbology_data.get('echelon'),
                'current_lat': location_mention.get('latitude'),
                'current_long': location_mention.get('longitude'),
                'last_observed': location_mention.get('observation_date'),
                'operational_area_id': location_mention.get('operational_area_id'),
                'tactical_area_id': location_mention.get('tactical_area_id'),
                'analyst_notes': symbology_data.get('analyst_notes'),
                'first_mentioned': min(m['observation_date'] for m in self.current_mentions),
                'last_mentioned': max(m['observation_date'] for m in self.current_mentions)
            }

            # Insert into unknown_units
            if not self.db.insert_unknown_unit(unknown_unit_data):
                return None  # Insert failed

        else:
            # Use existing unit_key for known units
            unit_key = location_mention['unit_key'] or location_mention['unknown_unit_key']

        # Build aggregated data
        is_main_body = (unit_type == 'Known Unit - Main Body')
        if unit_type == 'Known Unit - Detached Element' or is_unknown_unit:
            reinforced = '-'

        aggregated = {
            'unit_key': unit_key,
            'observation_date': max(m['observation_date'] for m in self.current_mentions),
            'tactical_area_id': location_mention['tactical_area_id'],
            'operational_area_id': location_mention['operational_area_id'],
            'adm4_pcode': location_mention['adm4_pcode'],
            'location': location_mention['location'],
            'latitude': location_mention['latitude'],
            'longitude': location_mention['longitude'],
            'operational_condition': None,
            'status': None,
            'reinforced': reinforced if reinforced else None,
            'action': None,
            'analyst': ANALYST_NAME,
            'is_main_body': is_main_body,
            'is_unknown_unit': is_unknown_unit,
            'source_id': location_mention['source_id'],
            'mention_ids': [m['mention_id'] for m in self.current_mentions]
        }

        # Get assessment data from selected sources
        if op_cond_source_id:
            op_cond_mention = next((m for m in self.current_mentions if m['source_id'] == op_cond_source_id), None)
            if op_cond_mention:
                aggregated['operational_condition'] = op_cond_mention['operational_condition']

        if status_source_id:
            status_mention = next((m for m in self.current_mentions if m['source_id'] == status_source_id), None)
            if status_mention:
                aggregated['status'] = status_mention['status']

        if action_source_id:
            action_mention = next((m for m in self.current_mentions if m['source_id'] == action_source_id), None)
            if action_mention:
                aggregated['action'] = action_mention['action']

        # Build source attribution and source_url
        location_source = self.db.get_source_details(location_source_id)
        source_parts = []

        self_reported = 'Y' if location_source['source_self_reported'] else 'N'
        source_parts.append(
            f"Location: {location_source['source_name']} "
            f"({location_source['source_origin']}, self-reported: {self_reported})"
        )

        # Add assessment sources
        assessment_sources = []
        for source_id in [op_cond_source_id, status_source_id, action_source_id]:
            if source_id and source_id != location_source_id:
                source = self.db.get_source_details(source_id)
                if source:
                    assessment_sources.append(
                        f"{source['source_name']} "
                        f"({source['source_origin']}, credibility: {source['source_credibility'] or 'N/A'})"
                    )

        if assessment_sources:
            source_parts.append(f"Assessment: {', '.join(assessment_sources)}")

        aggregated['source_attribution'] = '. '.join(source_parts) + '.'
        aggregated['source_url'] = '. '.join(source_parts) + '.'

        return aggregated


# ============================================================================
# REVIEW PROCESSED UNITS SCREEN
# ============================================================================

class ReviewScreen(tk.Frame):
    """Screen for reviewing all processed units before final commit."""

    def __init__(self, parent, db: DatabaseManager, processed_units: List[Dict], on_submit):
        super().__init__(parent)
        self.db = db
        self.processed_units = processed_units
        self.on_submit = on_submit

        self.pack(fill=tk.BOTH, expand=True)
        self.create_widgets()
        self.load_data()

    def create_widgets(self):
        # Header
        header_frame = ttk.Frame(self, padding="10")
        header_frame.pack(fill=tk.X)

        ttk.Label(header_frame, text="Review Processed Units",
                 font=('Arial', 14, 'bold')).pack(side=tk.LEFT)

        ttk.Label(header_frame, text=f"Total: {len(self.processed_units)} units").pack(side=tk.RIGHT)

        # Table
        table_frame = ttk.Frame(self, padding="10")
        table_frame.pack(fill=tk.BOTH, expand=True)

        columns = ("Unit Key", "Date", "Tac Area", "Location", "OpCond", "Status", "Reinforced", "Type", "Sources")
        self.tree = ttk.Treeview(table_frame, columns=columns, show='headings', height=15)

        for col in columns:
            self.tree.heading(col, text=col)
            if col == "Unit Key":
                self.tree.column(col, width=100)
            elif col in ("Date", "Tac Area", "OpCond", "Status", "Reinforced", "Type"):
                self.tree.column(col, width=80)
            elif col == "Location":
                self.tree.column(col, width=150)
            else:
                self.tree.column(col, width=200)

        vsb = ttk.Scrollbar(table_frame, orient="vertical", command=self.tree.yview)
        hsb = ttk.Scrollbar(table_frame, orient="horizontal", command=self.tree.xview)
        self.tree.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)

        self.tree.grid(row=0, column=0, sticky='nsew')
        vsb.grid(row=0, column=1, sticky='ns')
        hsb.grid(row=1, column=0, sticky='ew')

        table_frame.columnconfigure(0, weight=1)
        table_frame.rowconfigure(0, weight=1)

        # Edit frame
        edit_frame = ttk.Frame(self, padding="10")
        edit_frame.pack(fill=tk.X)

        ttk.Label(edit_frame, text="Edit unit (enter unit_key):").pack(side=tk.LEFT, padx=5)
        self.edit_var = tk.StringVar()
        ttk.Entry(edit_frame, textvariable=self.edit_var, width=15).pack(side=tk.LEFT, padx=5)
        ttk.Button(edit_frame, text="Edit", command=self.edit_unit).pack(side=tk.LEFT, padx=5)

        # Submit button
        button_frame = ttk.Frame(self, padding="10")
        button_frame.pack(fill=tk.X)

        ttk.Button(button_frame, text="Submit All", command=self.submit_all).pack(side=tk.RIGHT, padx=5)

    def load_data(self):
        """Load processed units into table."""
        # Clear tree
        for item in self.tree.get_children():
            self.tree.delete(item)

        # Add units
        for unit in self.processed_units:
            location_str = ""
            if unit['latitude'] and unit['longitude']:
                location_str = f"{unit['latitude']:.4f}, {unit['longitude']:.4f}"
            elif unit.get('adm4_pcode'):
                location_str = f"Settlement: {unit['adm4_pcode']}"
            elif unit['tactical_area_id']:
                location_str = f"Area: {unit['tactical_area_id']}"

            self.tree.insert('', tk.END, values=(
                unit['unit_key'],
                unit['observation_date'].strftime('%Y-%m-%d'),
                unit['tactical_area_id'] or 'N/A',
                location_str,
                unit['operational_condition'] or 'N/A',
                unit['status'] or 'N/A',
                unit['reinforced'] or 'N/A',
                'Main' if unit['is_main_body'] else 'Detached',
                unit['source_attribution'][:30] + '...'
            ))

    def edit_unit(self):
        """Open edit dialog for selected unit."""
        unit_key = self.edit_var.get().strip()
        if not unit_key:
            messagebox.showwarning("Input Required", "Please enter a unit key to edit")
            return

        unit = next((u for u in self.processed_units if u['unit_key'] == unit_key), None)
        if not unit:
            messagebox.showerror("Not Found", f"Unit {unit_key} not found in processed units")
            return

        EditUnitDialog(self, unit, self.on_unit_edited)

    def on_unit_edited(self, updated_unit: Dict):
        """Callback when unit is edited."""
        # Update in list
        for i, unit in enumerate(self.processed_units):
            if unit['unit_key'] == updated_unit['unit_key']:
                self.processed_units[i] = updated_unit
                break

        # Reload display
        self.load_data()

    def go_back(self):
        """Go back to unit processing."""
        # For now, just show message
        messagebox.showinfo("Info", "Back button - would return to unit processing")

    def submit_all(self):
        """Submit all processed units to database."""
        if not self.processed_units:
            messagebox.showwarning("Nothing to Submit", "No units to commit")
            return

        result = messagebox.askyesno(
            "Confirm Submit",
            f"Are you sure you want to commit {len(self.processed_units)} units to the database?\n\n"
            "This action cannot be undone."
        )

        if result:
            self.on_submit(self.processed_units)


# ============================================================================
# EDIT UNIT DIALOG
# ============================================================================

class EditUnitDialog(tk.Toplevel):
    """Dialog for editing a processed unit."""

    def __init__(self, parent, unit: Dict, on_save):
        super().__init__(parent)
        self.unit = unit.copy()  # Work on a copy
        self.on_save = on_save

        self.title(f"Edit Unit: {unit['unit_key']}")
        self.geometry("600x500")
        self.create_widgets()

    def create_widgets(self):
        # Create scrollable frame
        canvas = tk.Canvas(self)
        scrollbar = ttk.Scrollbar(self, orient="vertical", command=canvas.yview)
        scrollable_frame = ttk.Frame(canvas)

        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )

        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)

        # Fields
        fields = [
            ("Unit Key:", "unit_key", "readonly"),
            ("Observation Date:", "observation_date", "readonly"),
            ("Tactical Area ID:", "tactical_area_id", "entry"),
            ("Operational Area ID:", "operational_area_id", "entry"),
            ("Settlement PCode:", "adm4_pcode", "entry"),
            ("Latitude:", "latitude", "entry"),
            ("Longitude:", "longitude", "entry"),
            ("Operational Condition:", "operational_condition", "entry"),
            ("Status:", "status", "entry"),
            ("Reinforced:", "reinforced", "entry"),
            ("Action:", "action", "text"),
            ("Source Attribution:", "source_attribution", "text"),
        ]

        self.vars = {}
        row = 0

        for label_text, field_name, field_type in fields:
            ttk.Label(scrollable_frame, text=label_text).grid(row=row, column=0, sticky=tk.W, padx=5, pady=5)

            if field_type == "readonly":
                value = str(self.unit[field_name])
                ttk.Label(scrollable_frame, text=value).grid(row=row, column=1, sticky=tk.W, padx=5, pady=5)
            elif field_type == "entry":
                var = tk.StringVar(value=str(self.unit[field_name]) if self.unit[field_name] is not None else "")
                self.vars[field_name] = var
                ttk.Entry(scrollable_frame, textvariable=var, width=40).grid(row=row, column=1, sticky=tk.W, padx=5, pady=5)
            elif field_type == "text":
                var = tk.StringVar(value=str(self.unit[field_name]) if self.unit[field_name] else "")
                self.vars[field_name] = var
                text_widget = tk.Text(scrollable_frame, width=40, height=3)
                text_widget.insert('1.0', var.get())
                text_widget.grid(row=row, column=1, sticky=tk.W, padx=5, pady=5)
                # Store text widget reference
                self.vars[field_name + "_widget"] = text_widget

            row += 1

        # Position type
        ttk.Label(scrollable_frame, text="Position Type:").grid(row=row, column=0, sticky=tk.W, padx=5, pady=5)
        self.position_type_var = tk.StringVar(value="Main Body" if self.unit['is_main_body'] else "Detached Element")
        ttk.Combobox(scrollable_frame, textvariable=self.position_type_var,
                    values=['Main Body', 'Detached Element'], state='readonly', width=37).grid(row=row, column=1, sticky=tk.W, padx=5, pady=5)

        # Buttons
        button_frame = ttk.Frame(self)
        ttk.Button(button_frame, text="Save", command=self.save).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Cancel", command=self.destroy).pack(side=tk.LEFT, padx=5)

        # Pack everything
        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
        button_frame.pack(fill=tk.X, pady=10)

    def save(self):
        """Save changes and close."""
        # Update unit from vars
        for field_name, var in self.vars.items():
            if field_name.endswith("_widget"):
                continue

            if field_name + "_widget" in self.vars:
                # Text widget
                text_widget = self.vars[field_name + "_widget"]
                value = text_widget.get('1.0', tk.END).strip()
            else:
                value = var.get().strip()

            # Convert to appropriate type
            if field_name in ('tactical_area_id', 'operational_area_id', 'status'):
                self.unit[field_name] = int(value) if value and value != 'None' else None
            elif field_name in ('latitude', 'longitude'):
                self.unit[field_name] = float(value) if value and value != 'None' else None
            else:
                self.unit[field_name] = value if value and value != 'None' else None

        self.unit['is_main_body'] = (self.position_type_var.get() == 'Main Body')

        self.on_save(self.unit)
        self.destroy()


# ============================================================================
# MAIN APPLICATION
# ============================================================================

class CommitMentionsApp(tk.Tk):
    """Main application window."""

    def __init__(self):
        super().__init__()

        self.title("Phase 2: Unit Mentions Commit - GUI")
        self.geometry("1200x800")

        self.db = None
        self.current_screen = None

        self.show_login()

    def show_login(self):
        """Show login screen."""
        self.clear_screen()
        self.current_screen = LoginScreen(self, self.on_login_success)

    def on_login_success(self, db: DatabaseManager):
        """Called when login succeeds."""
        self.db = db
        self.show_pending_units()

    def show_pending_units(self):
        """Show pending units summary."""
        self.clear_screen()
        self.current_screen = PendingUnitsScreen(self, self.db, self.on_start_processing)

    def on_start_processing(self, units: List[Dict]):
        """Called when user selects units to process."""
        self.clear_screen()
        self.current_screen = UnitProcessingScreen(self, self.db, units, self.on_processing_complete)

    def on_processing_complete(self, processed_units: List[Dict]):
        """Called when all units are processed."""
        if not processed_units:
            messagebox.showinfo("Complete", "No units were processed")
            self.show_pending_units()
            return

        self.clear_screen()
        self.current_screen = ReviewScreen(self, self.db, processed_units, self.on_final_submit)

    def on_final_submit(self, processed_units: List[Dict]):
        """Called when user submits all processed units."""
        try:
            # Start transaction
            committed_count = 0

            for unit in processed_units:
                # Commit to unit_positions
                observation_id = self.db.commit_position(unit)
                if observation_id is None:
                    self.db.conn.rollback()
                    messagebox.showerror("Error", f"Failed to commit unit {unit['unit_key']}")
                    return

                # Mark mentions as committed
                if not self.db.mark_mentions_committed(unit['mention_ids'], observation_id):
                    self.db.conn.rollback()
                    messagebox.showerror("Error", f"Failed to mark mentions for unit {unit['unit_key']}")
                    return

                # Note: russian_units/unknown_units are now updated automatically
                # by the trig_update_unit_from_position trigger on unit_positions

                committed_count += 1

            # Commit transaction
            self.db.conn.commit()

            messagebox.showinfo(
                "Success",
                f"Successfully committed {committed_count} units to database!"
            )

            # Return to pending units screen
            self.show_pending_units()

        except Exception as e:
            self.db.conn.rollback()
            messagebox.showerror("Error", f"Failed to commit units:\n{e}")

    def clear_screen(self):
        """Clear current screen."""
        if self.current_screen:
            self.current_screen.destroy()
            self.current_screen = None

    def on_closing(self):
        """Handle window close."""
        if self.db:
            self.db.close()
        self.destroy()


# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

def main():
    """Main entry point."""
    app = CommitMentionsApp()
    app.protocol("WM_DELETE_WINDOW", app.on_closing)
    app.mainloop()


if __name__ == '__main__':
    main()
