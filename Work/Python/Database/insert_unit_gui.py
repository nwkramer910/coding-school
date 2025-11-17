#!/usr/bin/env python3
"""
GUI for inserting new units into the orbat.russian_units table.
Reads database credentials from db_config.json.
"""

import tkinter as tk
from tkinter import ttk, messagebox
import psycopg2
import json
import os
import re
from datetime import datetime


class RussianUnitsGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Russian Units Database Entry")
        self.root.state('zoomed')  # Maximize window

        # Load database config
        self.db_config = self.load_config()

        # Database connection
        self.conn = None
        self.connect_to_database()

        # Reference data storage
        self.reference_data = {}
        self.load_reference_tables()

        # Hardcoded echelon keywords for auto-population
        self.echelon_keywords = {
            'unknown': {'code': 0, 'symbol_display': '?'},
            'team/crew': {'code': 11, 'symbol_display': '∅'},
            'team': {'code': 11, 'symbol_display': '∅'},
            'crew': {'code': 11, 'symbol_display': '∅'},
            'squad': {'code': 12, 'symbol_display': '•'},
            'section': {'code': 13, 'symbol_display': '••'},
            'platoon/detachment': {'code': 14, 'symbol_display': '•••'},
            'platoon': {'code': 14, 'symbol_display': '•••'},
            'detachment': {'code': 14, 'symbol_display': '•••'},
            'company/battery/troop': {'code': 15, 'symbol_display': 'I'},
            'company': {'code': 15, 'symbol_display': 'I'},
            'battery': {'code': 15, 'symbol_display': 'I'},
            'troop': {'code': 15, 'symbol_display': 'I'},
            'battalion/squadron': {'code': 16, 'symbol_display': 'II'},
            'battalion': {'code': 16, 'symbol_display': 'II'},
            'squadron': {'code': 16, 'symbol_display': 'II'},
            'regiment/group': {'code': 17, 'symbol_display': 'III'},
            'regiment': {'code': 17, 'symbol_display': 'III'},
            'group': {'code': 17, 'symbol_display': 'III'},
            'brigade': {'code': 18, 'symbol_display': 'X'},
            'division': {'code': 21, 'symbol_display': 'XX'},
            'corps/mef': {'code': 22, 'symbol_display': 'XXX'},
            'corps': {'code': 22, 'symbol_display': 'XXX'},
            'mef': {'code': 22, 'symbol_display': 'XXX'},
            'army': {'code': 23, 'symbol_display': 'XXXX'},
            'army group/front': {'code': 24, 'symbol_display': 'XXXXX'},
            'front': {'code': 24, 'symbol_display': 'XXXXX'},
            'region/theater': {'code': 25, 'symbol_display': 'XXXXXX'},
            'region': {'code': 25, 'symbol_display': 'XXXXXX'},
            'theater': {'code': 25, 'symbol_display': 'XXXXXX'},
            'command': {'code': 26, 'symbol_display': '++'}
        }

        # Get highest y-key
        self.highest_y_key = self.get_highest_y_key()

        # Create main scrollable container
        main_canvas = tk.Canvas(root)
        main_scrollbar = tk.Scrollbar(root, orient="vertical", command=main_canvas.yview)
        self.scrollable_main = tk.Frame(main_canvas)

        self.scrollable_main.bind(
            "<Configure>",
            lambda e: main_canvas.configure(scrollregion=main_canvas.bbox("all"))
        )

        main_canvas.create_window((0, 0), window=self.scrollable_main, anchor="nw")
        main_canvas.configure(yscrollcommand=main_scrollbar.set)

        main_canvas.pack(side="left", fill="both", expand=True, padx=10, pady=10)
        main_scrollbar.pack(side="right", fill="y")

        # Store canvas for mousewheel unbinding
        self.main_canvas = main_canvas

        # Mouse wheel scrolling for main canvas
        # def _on_mousewheel(event):
        #    main_canvas.yview_scroll(int(-1*(event.delta/120)), "units")

        # def _on_mouse_button_4(event):
        #    main_canvas.yview_scroll(-1, "units")

        # def _on_mouse_button_5(event):
        #    main_canvas.yview_scroll(1, "units")

        # main_canvas.bind_all("<MouseWheel>", _on_mousewheel)
        # main_canvas.bind_all("<Button-4>", _on_mouse_button_4)
        # main_canvas.bind_all("<Button-5>", _on_mouse_button_5)

        # self._mousewheel_handler = _on_mousewheel
        # self._button_4_handler = _on_mouse_button_4
        # self._button_5_handler = _on_mouse_button_5

        # Configure grid layout (3x3 grid with KEY DATA in top-left)
        for i in range(3):
            self.scrollable_main.grid_rowconfigure(i, weight=1)
            self.scrollable_main.grid_columnconfigure(i, weight=1)

        # Dictionary to store all entry widgets
        self.entries = {}
        self.key_entries = {}

        # Create sections in grid layout
        self.create_key_data_section(self.scrollable_main)  # row=0, col=0
        self.create_symbology_section(self.scrollable_main)  # row=0, col=1
        self.create_metadata_section(self.scrollable_main)  # row=0, col=2
        self.create_superfluous_section(self.scrollable_main)  # row=1, col=0
        self.create_basing_section(self.scrollable_main)  # row=1, col=1
        self.create_foreign_keys_section(self.scrollable_main)  # row=1, col=2, span 2 rows

        # Bottom - Submit button
        button_frame = tk.Frame(root)
        button_frame.pack(fill=tk.X, padx=10, pady=10)

        submit_btn = tk.Button(button_frame, text="Insert Unit", command=self.insert_unit,
                               bg="#4CAF50", fg="white", font=("Arial", 12, "bold"),
                               height=2, cursor="hand2")
        submit_btn.pack(side=tk.RIGHT, padx=5)

        clear_btn = tk.Button(button_frame, text="Clear Form", command=self.clear_form,
                             bg="#f44336", fg="white", font=("Arial", 12, "bold"),
                             height=2, cursor="hand2")
        clear_btn.pack(side=tk.RIGHT, padx=5)

        # Set defaults after all widgets are created
        self.set_defaults()

        # Bind keyboard shortcuts
        self.root.bind('<Control-Return>', lambda e: self.insert_unit())
        self.root.bind('<Control-r>', lambda e: self.clear_form())
        self.root.bind('<Control-R>', lambda e: self.clear_form())

    def load_config(self):
        """Load database configuration from JSON file."""
        config_path = os.path.join(os.path.dirname(__file__), 'db_config.json')
        try:
            with open(config_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            messagebox.showerror("Config Error",
                               f"Database config file not found at {config_path}")
            self.root.destroy()
            return None
        except json.JSONDecodeError:
            messagebox.showerror("Config Error",
                               "Invalid JSON in database config file")
            self.root.destroy()
            return None

    def connect_to_database(self):
        """Establish connection to PostgreSQL database."""
        try:
            self.conn = psycopg2.connect(
                host=self.db_config['database']['host'],
                port=self.db_config['database']['port'],
                dbname=self.db_config['database']['dbname'],
                user=self.db_config['database']['user'],
                password=self.db_config['database']['password']
            )
        except psycopg2.Error as e:
            messagebox.showerror("Database Connection Error",
                               f"Failed to connect to database:\n{str(e)}")
            self.root.destroy()

    def get_highest_y_key(self):
        """Get the highest unit_key starting with 'y' (excluding y99999-y99994)."""
        if not self.conn:
            return "N/A"

        try:
            cursor = self.conn.cursor()
            cursor.execute("""
                SELECT unit_key
                FROM orbat.russian_units
                WHERE unit_key LIKE 'y%'
                  AND unit_key NOT IN ('y99999', 'y99998', 'y99997', 'y99996', 'y99995', 'y99994')
                ORDER BY unit_key DESC
                LIMIT 1
            """)
            result = cursor.fetchone()
            cursor.close()
            return result[0] if result else "None found"
        except psycopg2.Error as e:
            return f"Error: {str(e)}"

    def load_reference_tables(self):
        """Load all reference table data for dropdowns."""
        if not self.conn:
            return

        cursor = self.conn.cursor()

        try:
            # Load identity codes
            cursor.execute("SELECT code, description FROM reference.identity_codes ORDER BY code")
            self.reference_data['identity_'] = [(row[0], f"{row[0]} - {row[1]}") for row in cursor.fetchall()]

            # Load symbolset codes
            cursor.execute("SELECT code, description FROM reference.symbolset_codes ORDER BY code")
            self.reference_data['symbolset'] = [(row[0], f"{row[0]} - {row[1]}") for row in cursor.fetchall()]

            # Load symbolentity codes
            cursor.execute("SELECT code, display_name FROM reference.symbology_entity_codes ORDER BY code")
            self.reference_data['symbolentity'] = [(row[0], f"{row[0]} - {row[1]}") for row in cursor.fetchall()]

            # Load echelon codes with symbol_display
            cursor.execute("SELECT code, description, symbol_display FROM reference.echelon_codes ORDER BY hierarchy_level")
            self.reference_data['echelon'] = [(row[0], f"{row[0]} - {row[1]}", row[2]) for row in cursor.fetchall()]

            # Load modifier1 codes
            cursor.execute("SELECT code, description FROM reference.modifier_1_amplifiers ORDER BY code")
            self.reference_data['modifier1'] = [(None, "-- None --")] + [(row[0], f"{row[0]} - {row[1]}") for row in cursor.fetchall()]

            # Load modifier2 codes
            cursor.execute("SELECT code, description FROM reference.modifier_2_amplifiers ORDER BY code")
            modifier2_results = cursor.fetchall()
            if modifier2_results:
                self.reference_data['modifier2'] = [(None, "-- None --")] + [(row[0], f"{row[0]} - {row[1]}") for row in modifier2_results]
            else:
                self.reference_data['modifier2'] = [(None, "-- None --")]
                print("Warning: No data found in modifier_2_amplifiers table")

            # Load status codes
            cursor.execute("SELECT code, description FROM reference.status_codes ORDER BY code")
            self.reference_data['status'] = [(None, "-- None --")] + [(row[0], f"{row[0]} - {row[1]}") for row in cursor.fetchall()]

            # Load reinforcement codes
            cursor.execute("SELECT code, description FROM reference.reinforcement_codes ORDER BY code")
            self.reference_data['reinforced'] = [(None, "-- None --")] + [(row[0], f"{row[0]} - {row[1]}") for row in cursor.fetchall()]

        except psycopg2.Error as e:
            messagebox.showerror("Reference Data Error",
                               f"Failed to load reference tables:\n{str(e)}")
        finally:
            cursor.close()

    # def bind_combobox_mousewheel(self, combobox):
        """Bind/unbind mousewheel to prevent page scrolling when using dropdown."""
    #    def on_enter(event):
    #        self.main_canvas.unbind_all("<MouseWheel>")
    #        self.main_canvas.unbind_all("<Button-4>")
    #        self.main_canvas.unbind_all("<Button-5>")

    #    def on_leave(event):
    #        self.main_canvas.bind_all("<MouseWheel>", self._mousewheel_handler)
    #        self.main_canvas.bind_all("<Button-4>", self._button_4_handler)
    #        self.main_canvas.bind_all("<Button-5>", self._button_5_handler)

    def validate_field(self, field_name, widget):
        """Validate a field and update its visual state."""
        value = widget.get().strip() if hasattr(widget, 'get') else None

        if value:
            # Valid - green border
            widget.config(highlightbackground="green", highlightcolor="green", highlightthickness=1)
        else:
            # Invalid/empty - light red border
            widget.config(highlightbackground="#ffcccc", highlightcolor="#ffcccc", highlightthickness=1)

    def validate_combobox(self, field_name, widget, event=None):
        """Validate a combobox and update its visual state."""
        # For ttk.Combobox, we need to use style or other methods as config doesn't work the same
        value = widget.get().strip()

        if value:
            # Valid - change background via style or configure
            try:
                widget.configure(background="lightgreen")
            except:
                pass  # ttk widgets don't always support direct bg config
        else:
            # Invalid/empty
            try:
                widget.configure(background="#ffcccc")
            except:
                pass

    def create_key_data_section(self, parent):
        """Create the KEY DATA section (HEADLINE DATA) in top-left."""
        key_frame = tk.LabelFrame(parent, text="KEY DATA (Required)",
                                 font=("Arial", 11, "bold"), padx=8, pady=8)
        key_frame.grid(row=0, column=0, sticky="nsew", padx=5, pady=5)

        row = 0

        # unit_key (MUST HAVE)
        tk.Label(key_frame, text="Unit Key *", font=("Arial", 9, "bold"), fg="red").grid(row=row, column=0, sticky="w", pady=2)
        self.key_entries['unit_key'] = tk.Entry(key_frame, width=30)
        self.key_entries['unit_key'].grid(row=row, column=1, pady=2)
        self.key_entries['unit_key'].bind('<KeyRelease>', lambda e: [self.on_unit_key_change(e), self.validate_field('unit_key', self.key_entries['unit_key'])])
        row += 1

        # Highest y-key label
        self.highest_y_label = tk.Label(key_frame, text=f"Highest y-key: {self.highest_y_key}",
                                        font=("Arial", 7), fg="blue")
        self.highest_y_label.grid(row=row, column=0, columnspan=2, sticky="w", pady=(0, 3))
        row += 1

        # mun_number (MUST HAVE, auto-generated)
        tk.Label(key_frame, text="MUN Number *", font=("Arial", 9, "bold"), fg="red").grid(row=row, column=0, sticky="w", pady=2)
        self.key_entries['mun_number'] = tk.Entry(key_frame, width=30, bg="#ffffcc")
        self.key_entries['mun_number'].grid(row=row, column=1, pady=2)
        self.key_entries['mun_number'].bind('<KeyRelease>', lambda e: [self.auto_generate_russianunitnumber(e), self.validate_field('mun_number', self.key_entries['mun_number'])])
        row += 1

        # unit_name (MUST HAVE)
        tk.Label(key_frame, text="Unit Name *", font=("Arial", 9, "bold"), fg="red").grid(row=row, column=0, sticky="w", pady=2)
        self.key_entries['unit_name'] = tk.Entry(key_frame, width=30)
        self.key_entries['unit_name'].grid(row=row, column=1, pady=2)
        self.key_entries['unit_name'].bind('<KeyRelease>', lambda e: [self.on_unit_name_change(e), self.validate_field('unit_name', self.key_entries['unit_name'])])
        row += 1

        # unit_type (optional)
        tk.Label(key_frame, text="Unit Type", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.key_entries['unit_type'] = tk.Entry(key_frame, width=30)
        self.key_entries['unit_type'].grid(row=row, column=1, pady=2)
        row += 1

        # parent_unit (MUST HAVE)
        tk.Label(key_frame, text="Parent Unit *", font=("Arial", 9, "bold"), fg="red").grid(row=row, column=0, sticky="w", pady=2)
        self.key_entries['parent_unit'] = tk.Entry(key_frame, width=30)
        self.key_entries['parent_unit'].grid(row=row, column=1, pady=2)
        self.key_entries['parent_unit'].bind('<KeyRelease>', lambda e: [self.auto_generate_higherformation(e), self.validate_field('parent_unit', self.key_entries['parent_unit'])])
        row += 1

    def create_symbology_section(self, parent):
        """Create SYMBOLOGY DATA section."""
        frame = tk.LabelFrame(parent, text="SYMBOLOGY DATA",
                             font=("Arial", 11, "bold"), padx=8, pady=8)
        frame.grid(row=0, column=1, sticky="nsew", padx=5, pady=5)

        # Configure grid
        frame.grid_columnconfigure(1, weight=1)

        row = 0

        # MUST HAVE fields
        tk.Label(frame, text="Required Fields:", font=("Arial", 9, "bold", "underline")).grid(row=row, column=0, columnspan=2, sticky="w", pady=(0, 3))
        row += 1

        # identity_ (MUST HAVE, DROPDOWN, DEFAULT=6)
        tk.Label(frame, text="Identity *", font=("Arial", 9, "bold"), fg="red").grid(row=row, column=0, sticky="w", pady=2)
        self.entries['identity_'] = ttk.Combobox(frame, values=[item[1] for item in self.reference_data['identity_']], state="readonly", width=50)
        self.entries['identity_'].grid(row=row, column=1, pady=2, sticky="ew")
#        self.bind_combobox_mousewheel(self.entries['identity_'])
        self.entries['identity_'].bind('<<ComboboxSelected>>', lambda e: self.validate_combobox('identity_', self.entries['identity_']))
        row += 1

        # symbolset (MUST HAVE, DROPDOWN, DEFAULT=10)
        tk.Label(frame, text="Symbol Set *", font=("Arial", 9, "bold"), fg="red").grid(row=row, column=0, sticky="w", pady=2)
        self.entries['symbolset'] = ttk.Combobox(frame, values=[item[1] for item in self.reference_data['symbolset']], state="readonly", width=50)
        self.entries['symbolset'].grid(row=row, column=1, pady=2, sticky="ew")
#        self.bind_combobox_mousewheel(self.entries['symbolset'])
        self.entries['symbolset'].bind('<<ComboboxSelected>>', lambda e: self.validate_combobox('symbolset', self.entries['symbolset']))
        row += 1

        # symbolentity (MUST HAVE, DROPDOWN)
        tk.Label(frame, text="Symbol Entity *", font=("Arial", 9, "bold"), fg="red").grid(row=row, column=0, sticky="w", pady=2)
        self.entries['symbolentity'] = ttk.Combobox(frame, values=[item[1] for item in self.reference_data['symbolentity']], state="readonly", width=100)
        self.entries['symbolentity'].grid(row=row, column=1, pady=2, sticky="ew")
#        self.bind_combobox_mousewheel(self.entries['symbolentity'])
        self.entries['symbolentity'].bind('<<ComboboxSelected>>', lambda e: self.validate_combobox('symbolentity', self.entries['symbolentity']))
        row += 1

        # echelon (MUST HAVE, DROPDOWN, AUTO-POPULATED)
        tk.Label(frame, text="Echelon *", font=("Arial", 9, "bold"), fg="red").grid(row=row, column=0, sticky="w", pady=2)
        self.entries['echelon'] = ttk.Combobox(frame, values=[item[1] for item in self.reference_data['echelon']], state="readonly", width=50)
        self.entries['echelon'].grid(row=row, column=1, pady=2, sticky="ew")
#        self.bind_combobox_mousewheel(self.entries['echelon'])
        self.entries['echelon'].bind('<<ComboboxSelected>>', lambda e: self.validate_combobox('echelon', self.entries['echelon']))
        row += 1

        # echelonlabel (MUST HAVE, TEXT, AUTO-POPULATED)
        tk.Label(frame, text="Echelon Label *", font=("Arial", 9, "bold"), fg="red").grid(row=row, column=0, sticky="w", pady=2)
        self.entries['echelonlabel'] = tk.Entry(frame, width=50, bg="#ffffcc")
        self.entries['echelonlabel'].grid(row=row, column=1, pady=2, sticky="ew")
        self.entries['echelonlabel'].bind('<KeyRelease>', lambda e: self.validate_field('echelonlabel', self.entries['echelonlabel']))
        row += 1

        # CAN BE CREATED fields
        tk.Label(frame, text="Auto-Generated:", font=("Arial", 9, "bold", "underline")).grid(row=row, column=0, columnspan=2, sticky="w", pady=(5, 3))
        row += 1

        # uniquedesignation (MUST HAVE, CAN BE CREATED)
        tk.Label(frame, text="Unique Designation *", font=("Arial", 9, "bold"), fg="red").grid(row=row, column=0, sticky="w", pady=2)
        self.entries['uniquedesignation'] = tk.Entry(frame, width=50, bg="#ffffcc")
        self.entries['uniquedesignation'].grid(row=row, column=1, pady=2, sticky="ew")
        self.entries['uniquedesignation'].bind('<KeyRelease>', lambda e: self.validate_field('uniquedesignation', self.entries['uniquedesignation']))
        row += 1

        # higherformation (MUST HAVE, CAN BE CREATED)
        tk.Label(frame, text="Higher Formation *", font=("Arial", 9, "bold"), fg="red").grid(row=row, column=0, sticky="w", pady=2)
        self.entries['higherformation'] = tk.Entry(frame, width=50, bg="#ffffcc")
        self.entries['higherformation'].grid(row=row, column=1, pady=2, sticky="ew")
        self.entries['higherformation'].bind('<KeyRelease>', lambda e: self.validate_field('higherformation', self.entries['higherformation']))
        row += 1

        # DROPDOWN fields (optional)
        tk.Label(frame, text="Optional:", font=("Arial", 9, "bold", "underline")).grid(row=row, column=0, columnspan=2, sticky="w", pady=(5, 3))
        row += 1

        # modifier1
        tk.Label(frame, text="Modifier 1", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['modifier1'] = ttk.Combobox(frame, values=[item[1] for item in self.reference_data['modifier1']], state="readonly", width=50)
        self.entries['modifier1'].grid(row=row, column=1, pady=2, sticky="ew")
#        self.bind_combobox_mousewheel(self.entries['modifier1'])
        row += 1

        # modifier2
        tk.Label(frame, text="Modifier 2", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['modifier2'] = ttk.Combobox(frame, values=[item[1] for item in self.reference_data['modifier2']], state="readonly", width=50)
        self.entries['modifier2'].grid(row=row, column=1, pady=2, sticky="ew")
#        self.bind_combobox_mousewheel(self.entries['modifier2'])
        row += 1

        # status
        tk.Label(frame, text="Status", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['status'] = ttk.Combobox(frame, values=[item[1] for item in self.reference_data['status']], state="readonly", width=50)
        self.entries['status'].grid(row=row, column=1, pady=2, sticky="ew")
#        self.bind_combobox_mousewheel(self.entries['status'])
        row += 1

        # reinforced
        tk.Label(frame, text="Reinforced", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['reinforced'] = ttk.Combobox(frame, values=[item[1] for item in self.reference_data['reinforced']], state="readonly", width=50)
        self.entries['reinforced'].grid(row=row, column=1, pady=2, sticky="ew")
#        self.bind_combobox_mousewheel(self.entries['reinforced'])
        row += 1

        # context (DEFAULT = 0)
        tk.Label(frame, text="Context", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['context'] = tk.Entry(frame, width=50)
        self.entries['context'].insert(0, "0")
        self.entries['context'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # specialentitysubtype
        tk.Label(frame, text="Special Entity Subtype", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['specialentitysubtype'] = tk.Entry(frame, width=50)
        self.entries['specialentitysubtype'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # hq_indicator
        tk.Label(frame, text="HQ Indicator", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['hq_indicator'] = tk.Entry(frame, width=50)
        self.entries['hq_indicator'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # specialheadquarters
        tk.Label(frame, text="Special Headquarters", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['specialheadquarters'] = tk.Entry(frame, width=50)
        self.entries['specialheadquarters'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

    def create_metadata_section(self, parent):
        """Create METADATA section."""
        frame = tk.LabelFrame(parent, text="METADATA",
                             font=("Arial", 11, "bold"), padx=8, pady=8)
        frame.grid(row=0, column=2, sticky="nsew", padx=5, pady=5)

        frame.grid_columnconfigure(1, weight=1)

        row = 0

        # MUST HAVE fields
        tk.Label(frame, text="Required:", font=("Arial", 9, "bold", "underline")).grid(row=row, column=0, columnspan=2, sticky="w", pady=(0, 3))
        row += 1

        # creator (MUST HAVE)
        tk.Label(frame, text="Creator *", font=("Arial", 9, "bold"), fg="red").grid(row=row, column=0, sticky="w", pady=2)
        self.entries['creator'] = tk.Entry(frame, width=30)
        self.entries['creator'].grid(row=row, column=1, pady=2, sticky="ew")
        self.entries['creator'].bind('<KeyRelease>', lambda e: self.validate_field('creator', self.entries['creator']))
        row += 1

        # CAN BE CREATED fields
        tk.Label(frame, text="Auto-Generated:", font=("Arial", 9, "bold", "underline")).grid(row=row, column=0, columnspan=2, sticky="w", pady=(5, 3))
        row += 1

        # russianunitnumber (MUST HAVE, CAN BE CREATED)
        tk.Label(frame, text="Russian Unit Number *", font=("Arial", 9, "bold"), fg="red").grid(row=row, column=0, sticky="w", pady=2)
        self.entries['russianunitnumber'] = tk.Entry(frame, width=30, bg="#ffffcc")
        self.entries['russianunitnumber'].grid(row=row, column=1, pady=2, sticky="ew")
        self.entries['russianunitnumber'].bind('<KeyRelease>', lambda e: self.validate_field('russianunitnumber', self.entries['russianunitnumber']))
        row += 1

        # OTHER fields
        tk.Label(frame, text="Optional:", font=("Arial", 9, "bold", "underline")).grid(row=row, column=0, columnspan=2, sticky="w", pady=(5, 3))
        row += 1

        # editor
        tk.Label(frame, text="Editor", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['editor'] = tk.Entry(frame, width=30)
        self.entries['editor'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # last_observed
        tk.Label(frame, text="Last Observed", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['last_observed'] = tk.Entry(frame, width=30)
        self.entries['last_observed'].grid(row=row, column=1, pady=2, sticky="ew")
        tk.Label(frame, text="(YYYY-MM-DD HH:MM:SS)", font=("Arial", 7), fg="gray").grid(row=row+1, column=0, columnspan=2, sticky="w")
        row += 2

        # current_lat
        tk.Label(frame, text="Current Latitude", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['current_lat'] = tk.Entry(frame, width=30)
        self.entries['current_lat'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # current_long
        tk.Label(frame, text="Current Longitude", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['current_long'] = tk.Entry(frame, width=30)
        self.entries['current_long'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

    def create_superfluous_section(self, parent):
        """Create SUPERFLUOUS DATA section."""
        frame = tk.LabelFrame(parent, text="SUPERFLUOUS DATA",
                             font=("Arial", 11, "bold"), padx=8, pady=8)
        frame.grid(row=1, column=0, sticky="nsew", padx=5, pady=5)

        frame.grid_columnconfigure(1, weight=1)

        row = 0

        # direction
        tk.Label(frame, text="Direction", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['direction'] = tk.Entry(frame, width=30)
        self.entries['direction'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # speedunit
        tk.Label(frame, text="Speed Unit", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['speedunit'] = tk.Entry(frame, width=30)
        self.entries['speedunit'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # staffcomments
        tk.Label(frame, text="Staff Comments", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['staffcomments'] = tk.Entry(frame, width=30)
        self.entries['staffcomments'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # reliability
        tk.Label(frame, text="Reliability", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['reliability'] = tk.Entry(frame, width=30)
        self.entries['reliability'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # countrycode
        tk.Label(frame, text="Country Code", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['countrycode'] = tk.Entry(frame, width=30)
        self.entries['countrycode'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # countrylabel
        tk.Label(frame, text="Country Label", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['countrylabel'] = tk.Entry(frame, width=30)
        self.entries['countrylabel'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

    def create_basing_section(self, parent):
        """Create BASING DATA section."""
        frame = tk.LabelFrame(parent, text="BASING DATA",
                             font=("Arial", 11, "bold"), padx=8, pady=8)
        frame.grid(row=1, column=1, sticky="nsew", padx=5, pady=5)

        frame.grid_columnconfigure(1, weight=1)

        row = 0

        # basinglocation
        tk.Label(frame, text="Basing Location", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['basinglocation'] = tk.Entry(frame, width=30)
        self.entries['basinglocation'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # baselatitude
        tk.Label(frame, text="Base Latitude", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['baselatitude'] = tk.Entry(frame, width=30)
        self.entries['baselatitude'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # baselongitude
        tk.Label(frame, text="Base Longitude", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['baselongitude'] = tk.Entry(frame, width=30)
        self.entries['baselongitude'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

    def create_foreign_keys_section(self, parent):
        """Create FOREIGN KEYS section."""
        frame = tk.LabelFrame(parent, text="FOREIGN KEYS",
                             font=("Arial", 11, "bold"), padx=8, pady=8)
        frame.grid(row=1, column=2, rowspan=2, sticky="nsew", padx=5, pady=5)

        frame.grid_columnconfigure(1, weight=1)

        row = 0

        # home_facility_key
        tk.Label(frame, text="Home Facility Key", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['home_facility_key'] = tk.Entry(frame, width=25)
        self.entries['home_facility_key'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # current_facility_key
        tk.Label(frame, text="Current Facility Key", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['current_facility_key'] = tk.Entry(frame, width=25)
        self.entries['current_facility_key'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # facility_assignment_type
        tk.Label(frame, text="Facility Assignment Type", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['facility_assignment_type'] = ttk.Combobox(frame, values=["HOME_BASE", "DEPLOYED_TO", "TRAINING_AT", "IN_TRANSIT", "UNKNOWN"], width=22)
        self.entries['facility_assignment_type'].grid(row=row, column=1, pady=2, sticky="ew")
#        self.bind_combobox_mousewheel(self.entries['facility_assignment_type'])
        row += 1

        # facility_assignment_date
        tk.Label(frame, text="Facility Assignment Date", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['facility_assignment_date'] = tk.Entry(frame, width=25)
        self.entries['facility_assignment_date'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # facility_assignment_confidence
        tk.Label(frame, text="Assignment Confidence", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['facility_assignment_confidence'] = tk.Entry(frame, width=25)
        self.entries['facility_assignment_confidence'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # current_action
        tk.Label(frame, text="Current Action", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['current_action'] = tk.Entry(frame, width=25)
        self.entries['current_action'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # military_district
        tk.Label(frame, text="Military District", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['military_district'] = tk.Entry(frame, width=25)
        self.entries['military_district'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # current_operational_area_id
        tk.Label(frame, text="Operational Area ID", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['current_operational_area_id'] = tk.Entry(frame, width=25)
        self.entries['current_operational_area_id'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # current_tactical_area_id
        tk.Label(frame, text="Tactical Area ID", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['current_tactical_area_id'] = tk.Entry(frame, width=25)
        self.entries['current_tactical_area_id'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # parent_unit_key
        tk.Label(frame, text="Parent Unit Key", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['parent_unit_key'] = tk.Entry(frame, width=25)
        self.entries['parent_unit_key'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # opcon_unit_key
        tk.Label(frame, text="OPCON Unit Key", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['opcon_unit_key'] = tk.Entry(frame, width=25)
        self.entries['opcon_unit_key'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # adcon_unit_key
        tk.Label(frame, text="ADCON Unit Key", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['adcon_unit_key'] = tk.Entry(frame, width=25)
        self.entries['adcon_unit_key'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # military_district_key
        tk.Label(frame, text="Military District Key", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['military_district_key'] = tk.Entry(frame, width=25)
        self.entries['military_district_key'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # grouping_of_forces_key
        tk.Label(frame, text="Grouping of Forces Key", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['grouping_of_forces_key'] = tk.Entry(frame, width=25)
        self.entries['grouping_of_forces_key'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # combined_arms_army_key
        tk.Label(frame, text="Combined Arms Army Key", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['combined_arms_army_key'] = tk.Entry(frame, width=25)
        self.entries['combined_arms_army_key'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

        # parent_unit_legacy
        tk.Label(frame, text="Parent Unit (Legacy)", font=("Arial", 9)).grid(row=row, column=0, sticky="w", pady=2)
        self.entries['parent_unit_legacy'] = tk.Entry(frame, width=25)
        self.entries['parent_unit_legacy'].grid(row=row, column=1, pady=2, sticky="ew")
        row += 1

    def set_defaults(self):
        """Set default values for fields."""
        # Set Identity to 6
        for code, display in self.reference_data['identity_']:
            if code == 6:
                self.entries['identity_'].set(display)
                break

        # Set Symbol Set to 10
        for code, display in self.reference_data['symbolset']:
            if code == 10:
                self.entries['symbolset'].set(display)
                break

    def on_unit_key_change(self, event=None):
        """Handle unit_key changes - auto-generate MUN and russian unit number."""
        unit_key_val = self.key_entries['unit_key'].get().strip()

        # Extract 5 digits after x or y
        if unit_key_val and (unit_key_val.startswith('x') or unit_key_val.startswith('y')):
            # Extract digits after first character
            digits = re.search(r'^[xy](\d{5})', unit_key_val)
            if digits:
                mun = digits.group(1)
                self.key_entries['mun_number'].delete(0, tk.END)
                self.key_entries['mun_number'].insert(0, mun)

        # Also update russian unit number
        self.auto_generate_russianunitnumber()

    def on_unit_name_change(self, event=None):
        """Handle unit_name changes - auto-generate unique designation and echelon."""
        self.auto_generate_uniquedesignation()
        self.auto_populate_echelon()

    def auto_populate_echelon(self, event=None):
        """Auto-populate echelon and echelon label based on unit_name keywords."""
        unit_name = self.key_entries.get('unit_name', None)
        if not unit_name:
            return

        unit_name_val = unit_name.get().lower()

        # Check each word in unit_name against echelon keywords
        for word in unit_name_val.split():
            if word in self.echelon_keywords:
                echelon_info = self.echelon_keywords[word]
                code = echelon_info['code']
                symbol_display = echelon_info['symbol_display']

                # Set echelon dropdown
                for ref_code, ref_display, _ in self.reference_data['echelon']:
                    if ref_code == code:
                        self.entries['echelon'].set(ref_display)
                        break

                # Set echelon label
                self.entries['echelonlabel'].delete(0, tk.END)
                self.entries['echelonlabel'].insert(0, symbol_display)
                break

    def extract_first_cardinal(self, text):
        """Extract the first cardinal number phrase (1st, 2nd, 3rd, etc.) from text."""
        if not text:
            return ""

        # Pattern to match cardinal numbers (1st, 2nd, 3rd, etc.)
        pattern = r'\b(\d+(?:st|nd|rd|th))\b'
        match = re.search(pattern, text, re.IGNORECASE)

        if match:
            return match.group(1)
        return ""

    def auto_generate_uniquedesignation(self, event=None):
        """Auto-generate uniquedesignation from unit_name."""
        unit_name = self.key_entries.get('unit_name', None)
        if unit_name:
            cardinal = self.extract_first_cardinal(unit_name.get())
            self.entries['uniquedesignation'].delete(0, tk.END)
            self.entries['uniquedesignation'].insert(0, cardinal)

    def auto_generate_higherformation(self, event=None):
        """Auto-generate higherformation from parent_unit."""
        parent_unit = self.key_entries.get('parent_unit', None)
        if parent_unit:
            cardinal = self.extract_first_cardinal(parent_unit.get())
            self.entries['higherformation'].delete(0, tk.END)
            self.entries['higherformation'].insert(0, cardinal)

    def auto_generate_russianunitnumber(self, event=None):
        """Auto-generate russianunitnumber based on unit_key and mun_number."""
        unit_key = self.key_entries.get('unit_key', None)
        mun_number = self.key_entries.get('mun_number', None)

        if unit_key and mun_number:
            unit_key_val = unit_key.get().strip()
            mun_number_val = mun_number.get().strip()

            if unit_key_val.startswith('x') and mun_number_val:
                result = f"в/ч {mun_number_val}"
            elif unit_key_val.startswith('y'):
                result = "в/ч UNK"
            else:
                result = ""

            self.entries['russianunitnumber'].delete(0, tk.END)
            self.entries['russianunitnumber'].insert(0, result)

    def get_dropdown_value(self, combobox, reference_list):
        """Extract the code value from a dropdown selection."""
        selected = combobox.get()
        if not selected or selected == "-- None --":
            return None

        # Find the matching code from reference data
        for item in reference_list:
            code = item[0]
            display = item[1]
            if display == selected:
                return code
        return None

    def validate_required_fields(self):
        """Validate that all required fields are filled."""
        required_fields = {
            'unit_key': 'Unit Key',
            'mun_number': 'MUN Number',
            'unit_name': 'Unit Name',
            'parent_unit': 'Parent Unit',
            'identity_': 'Identity',
            'symbolset': 'Symbol Set',
            'symbolentity': 'Symbol Entity',
            'echelon': 'Echelon',
            'uniquedesignation': 'Unique Designation',
            'higherformation': 'Higher Formation',
            'echelonlabel': 'Echelon Label',
            'creator': 'Creator',
            'russianunitnumber': 'Russian Unit Number'
        }

        missing = []

        for field, label in required_fields.items():
            if field in self.key_entries:
                value = self.key_entries[field].get().strip()
            elif field in self.entries:
                widget = self.entries[field]
                if isinstance(widget, ttk.Combobox):
                    value = widget.get().strip()
                else:
                    value = widget.get().strip()
            else:
                continue

            if not value:
                missing.append(label)

        if missing:
            messagebox.showerror("Validation Error",
                               f"The following required fields are missing:\n\n" + "\n".join(f"• {field}" for field in missing))
            return False

        return True

    def insert_unit(self):
        """Insert the unit data into the database."""
        # Validate required fields
        if not self.validate_required_fields():
            return

        # Collect all data
        data = {}

        # Collect KEY DATA
        for field, widget in self.key_entries.items():
            value = widget.get().strip()
            data[field] = value if value else None

        # Collect other data
        for field, widget in self.entries.items():
            if isinstance(widget, ttk.Combobox):
                # Handle dropdown fields
                if field in ['identity_', 'symbolset', 'symbolentity', 'echelon', 'modifier1', 'modifier2', 'status', 'reinforced']:
                    data[field] = self.get_dropdown_value(widget, self.reference_data[field])
                else:
                    value = widget.get().strip()
                    data[field] = value if value else None
            else:
                value = widget.get().strip()
                data[field] = value if value else None

        # Convert numeric fields
        numeric_fields = ['context', 'specialentitysubtype', 'hq_indicator', 'specialheadquarters',
                         'direction', 'speedunit', 'home_facility_key', 'current_facility_key',
                         'current_operational_area_id', 'current_tactical_area_id']

        for field in numeric_fields:
            if field in data and data[field]:
                try:
                    data[field] = int(data[field])
                except ValueError:
                    messagebox.showerror("Validation Error",
                                       f"Field '{field}' must be a numeric value")
                    return

        # Convert float fields
        float_fields = ['baselatitude', 'baselongitude', 'current_lat', 'current_long']

        for field in float_fields:
            if field in data and data[field]:
                try:
                    data[field] = float(data[field])
                except ValueError:
                    messagebox.showerror("Validation Error",
                                       f"Field '{field}' must be a numeric value")
                    return

        # Convert timestamp fields
        timestamp_fields = ['last_observed', 'facility_assignment_date']

        for field in timestamp_fields:
            if field in data and data[field]:
                try:
                    # Try to parse the timestamp
                    datetime.strptime(data[field], '%Y-%m-%d %H:%M:%S')
                except ValueError:
                    messagebox.showerror("Validation Error",
                                       f"Field '{field}' must be in format YYYY-MM-DD HH:MM:SS")
                    return

        # Build INSERT query
        columns = []
        values = []
        placeholders = []

        for col, val in data.items():
            if val is not None and val != '':
                columns.append(col)
                values.append(val)
                placeholders.append('%s')

        query = f"""
            INSERT INTO orbat.russian_units ({', '.join(columns)})
            VALUES ({', '.join(placeholders)})
        """

        # Execute insert
        try:
            cursor = self.conn.cursor()
            cursor.execute(query, values)
            self.conn.commit()
            cursor.close()

            messagebox.showinfo("Success",
                              f"Unit '{data['unit_name']}' (Key: {data['unit_key']}) has been successfully inserted into the database!")

            # Refresh highest y-key
            self.highest_y_key = self.get_highest_y_key()
            self.highest_y_label.config(text=f"Highest y-key: {self.highest_y_key}")

            # Clear the form
            self.clear_form()

        except psycopg2.Error as e:
            self.conn.rollback()
            messagebox.showerror("Database Error",
                               f"Failed to insert unit:\n{str(e)}")

    def clear_form(self):
        """Clear all form fields."""
        # Clear KEY DATA entries
        for widget in self.key_entries.values():
            widget.delete(0, tk.END)

        # Clear other entries
        for field, widget in self.entries.items():
            if isinstance(widget, ttk.Combobox):
                widget.set('')
            else:
                widget.delete(0, tk.END)

        # Restore defaults
        self.set_defaults()
        self.entries['context'].insert(0, "0")

    def __del__(self):
        """Close database connection on exit."""
        if self.conn:
            self.conn.close()


def main():
    root = tk.Tk()
    app = RussianUnitsGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
