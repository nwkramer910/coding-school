import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox, filedialog
from datetime import datetime
from tkcalendar import DateEntry
import psycopg2
import subprocess
import os
import pandas as pd
import textwrap
import json
from mentions import batch_insert_unit_mentions

class UnitMentionsGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Unit Mentions Data Entry")
        self.root.geometry("1600x800")  # Wider to accommodate two panes

        # List to store units before submission
        self.units_to_submit = []

        # Excel data storage
        self.excel_data = None

        # Load database configuration
        self.db_config = self.load_db_config()

        # Load operational areas from database
        self.operational_areas = {}  # Maps area_name -> area_id
        self.load_operational_areas()

        # Load tactical areas from database - separated by type
        self.tactical_areas_frontal = {}  # Maps area_name -> area_id (frontal only)
        self.tactical_areas_rear = {}  # Maps area_name -> area_id (rear only)
        self.tactical_areas_full = {}  # Maps area_name -> (area_id, [op_area_ids], area_type)
        self.load_tactical_areas()

        # Load sources from database
        self.sources = {}  # Maps source_name -> source_id
        self.load_sources()

        # Create PanedWindow for left/right split
        paned_window = ttk.PanedWindow(root, orient=tk.HORIZONTAL)
        paned_window.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        # LEFT PANE (40% width) - Form inputs
        left_frame = ttk.Frame(paned_window, width=640)  # 40% of 1600
        paned_window.add(left_frame, weight=40)

        # RIGHT PANE (60% width) - Data display
        right_frame = ttk.Frame(paned_window, width=960)  # 60% of 1600
        paned_window.add(right_frame, weight=60)

        # Create main container with scrollbar for LEFT PANE
        main_container = ttk.Frame(left_frame)
        main_container.pack(fill=tk.BOTH, expand=True)

        # Create canvas and scrollbar
        canvas = tk.Canvas(main_container)
        scrollbar = ttk.Scrollbar(main_container, orient="vertical", command=canvas.yview)
        scrollable_frame = ttk.Frame(canvas)

        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )

        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)

        # Pack canvas and scrollbar
        canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        # Initialize form fields
        self.fields = {}

        # === UNIT IDENTIFICATION ===
        unit_frame = ttk.LabelFrame(scrollable_frame, text="Unit Identification", padding=10)
        unit_frame.grid(row=0, column=0, columnspan=2, sticky=(tk.W, tk.E), padx=5, pady=5)

        ttk.Label(unit_frame, text="Unit Key:").grid(row=0, column=0, sticky=tk.W, pady=2)
        self.fields['unit_key'] = ttk.Entry(unit_frame, width=20)
        self.fields['unit_key'].grid(row=0, column=1, sticky=(tk.W, tk.E), pady=2)

        # Add search button
        ttk.Button(unit_frame, text="Search Units", command=self.open_unit_search).grid(row=0, column=2, padx=5, pady=2)

        # Add "Add New Unit" button underneath Unit Key
        ttk.Button(unit_frame, text="➕ Add New Unit", command=self.launch_insert_unit_gui).grid(row=1, column=0, columnspan=2, sticky=tk.W, pady=5)

        # === LOCATION DATA ===
        location_frame = ttk.LabelFrame(scrollable_frame, text="Location Data", padding=10)
        location_frame.grid(row=1, column=0, columnspan=2, sticky=(tk.W, tk.E), padx=5, pady=5)

        ttk.Label(location_frame, text="Operational Area:").grid(row=0, column=0, sticky=tk.W, pady=2)
        self.fields['operational_area'] = ttk.Combobox(location_frame, width=40, state='readonly')
        op_area_names = [''] + sorted(self.operational_areas.keys())
        self.fields['operational_area']['values'] = op_area_names
        self.fields['operational_area'].grid(row=0, column=1, sticky=(tk.W, tk.E), pady=2)
        self.fields['operational_area'].bind('<<ComboboxSelected>>', self.on_operational_area_changed)

        ttk.Label(location_frame, text="Frontal Tactical Area:").grid(row=1, column=0, sticky=tk.W, pady=2)
        self.fields['tactical_area_frontal'] = ttk.Combobox(location_frame, width=40, state='readonly')
        frontal_area_names = [''] + sorted(self.tactical_areas_frontal.keys())
        self.fields['tactical_area_frontal']['values'] = frontal_area_names
        self.fields['tactical_area_frontal'].grid(row=1, column=1, sticky=(tk.W, tk.E), pady=2)
        self.fields['tactical_area_frontal'].bind('<<ComboboxSelected>>', self.on_frontal_area_selected)

        ttk.Label(location_frame, text="Rear Tactical Area:").grid(row=2, column=0, sticky=tk.W, pady=2)
        self.fields['tactical_area_rear'] = ttk.Combobox(location_frame, width=40, state='readonly')
        rear_area_names = [''] + sorted(self.tactical_areas_rear.keys())
        self.fields['tactical_area_rear']['values'] = rear_area_names
        self.fields['tactical_area_rear'].grid(row=2, column=1, sticky=(tk.W, tk.E), pady=2)
        self.fields['tactical_area_rear'].bind('<<ComboboxSelected>>', self.on_rear_area_selected)

        # === ASSESSMENT DATA ===
        assessment_frame = ttk.LabelFrame(scrollable_frame, text="Assessment Data", padding=10)
        assessment_frame.grid(row=2, column=0, columnspan=2, sticky=(tk.W, tk.E), padx=5, pady=5)

        ttk.Label(assessment_frame, text="Status:").grid(row=0, column=0, sticky=tk.W, pady=2)
        self.fields['status'] = ttk.Combobox(assessment_frame, width=27,
            values=['', '0 - Present', '1 - Anticipated/Planned', '2 - Present/Fully Capable',
                   '3 - Present/Damaged', '4 - Present/Destroyed', '5 - Present/Full to Capacity'])
        self.fields['status'].set('0 - Present')
        self.fields['status'].grid(row=0, column=1, sticky=(tk.W, tk.E), pady=2)

        ttk.Label(assessment_frame, text="Reinforced:").grid(row=1, column=0, sticky=tk.W, pady=2)
        self.fields['reinforced'] = ttk.Combobox(assessment_frame, width=27,
            values=['', '+', '-', '±', '+/-'])
        self.fields['reinforced'].set('-')
        self.fields['reinforced'].grid(row=1, column=1, sticky=(tk.W, tk.E), pady=2)

        ttk.Label(assessment_frame, text="Operational Condition:").grid(row=2, column=0, sticky=tk.W, pady=2)
        self.fields['operational_condition'] = ttk.Combobox(assessment_frame, width=27,
            values=['', '100 - Fully Operational', '110 - Substantially Operational',
                   '120 - Marginally Operational', '130 - Not Operational',
                   '140 - Effectiveness Unknown', '150 - Not Applicable'])
        self.fields['operational_condition'].set('140 - Effectiveness Unknown')
        self.fields['operational_condition'].grid(row=2, column=1, sticky=(tk.W, tk.E), pady=2)

        ttk.Label(assessment_frame, text="Action:").grid(row=3, column=0, sticky=tk.W, pady=2)
        self.fields['action'] = ttk.Entry(assessment_frame, width=30)
        self.fields['action'].grid(row=3, column=1, sticky=(tk.W, tk.E), pady=2)

        # === SOURCE ATTRIBUTION ===
        source_frame = ttk.LabelFrame(scrollable_frame, text="Source Attribution", padding=10)
        source_frame.grid(row=3, column=0, columnspan=2, sticky=(tk.W, tk.E), padx=5, pady=5)

        ttk.Label(source_frame, text="Source URL:").grid(row=0, column=0, sticky=tk.W, pady=2)
        self.fields['source_url'] = ttk.Entry(source_frame, width=50)
        self.fields['source_url'].grid(row=0, column=1, sticky=(tk.W, tk.E), pady=2)

        ttk.Label(source_frame, text="Source:").grid(row=1, column=0, sticky=tk.W, pady=2)
        self.fields['source'] = ttk.Combobox(source_frame, width=47, state='readonly')
        source_names = [''] + sorted(self.sources.keys())
        self.fields['source']['values'] = source_names
        self.fields['source'].grid(row=1, column=1, sticky=(tk.W, tk.E), pady=2)

        ttk.Label(source_frame, text="Source Excerpt:").grid(row=2, column=0, sticky=tk.W, pady=2)
        self.fields['source_excerpt'] = scrolledtext.ScrolledText(source_frame, width=50, height=3)
        self.fields['source_excerpt'].grid(row=2, column=1, sticky=(tk.W, tk.E), pady=2)

        ttk.Label(source_frame, text="Credibility:").grid(row=3, column=0, sticky=tk.W, pady=2)
        self.fields['credibility'] = ttk.Combobox(source_frame, width=47,
            values=['', '1 - Confirmed by other sources', '2 - Usually reliable',
                   '3 - Fairly reliable', '4 - Not usually reliable',
                   '5 - Unreliable', '6 - Cannot be judged'])
        self.fields['credibility'].grid(row=3, column=1, sticky=(tk.W, tk.E), pady=2)

        ttk.Label(source_frame, text="Reliability:").grid(row=4, column=0, sticky=tk.W, pady=2)
        self.fields['reliability'] = ttk.Combobox(source_frame, width=47,
            values=['', 'A - Confirmed', 'B - Probably true', 'C - Possibly true',
                   'D - Doubtfully true', 'E - Improbable', 'F - Cannot be judged'])
        self.fields['reliability'].grid(row=4, column=1, sticky=(tk.W, tk.E), pady=2)

        # === ANALYST DATA ===
        analyst_frame = ttk.LabelFrame(scrollable_frame, text="Analyst Data", padding=10)
        analyst_frame.grid(row=4, column=0, columnspan=2, sticky=(tk.W, tk.E), padx=5, pady=5)

        ttk.Label(analyst_frame, text="Analyst:").grid(row=0, column=0, sticky=tk.W, pady=2)
        self.fields['analyst'] = ttk.Entry(analyst_frame, width=30)
        self.fields['analyst'].insert(0, 'nkramer')
        self.fields['analyst'].grid(row=0, column=1, sticky=(tk.W, tk.E), pady=2)

        ttk.Label(analyst_frame, text="Observation Date:").grid(row=1, column=0, sticky=tk.W, pady=2)
        self.fields['observation_date'] = DateEntry(
            analyst_frame,
            width=27,
            background='darkblue',
            foreground='white',
            borderwidth=2,
            date_pattern='yyyy-mm-dd'
        )
        self.fields['observation_date'].grid(row=1, column=1, sticky=(tk.W, tk.E), pady=2)

        ttk.Label(analyst_frame, text="Analyst Notes:").grid(row=2, column=0, sticky=tk.W, pady=2)
        self.fields['analyst_notes'] = scrolledtext.ScrolledText(analyst_frame, width=50, height=3)
        self.fields['analyst_notes'].grid(row=2, column=1, sticky=(tk.W, tk.E), pady=2)

        ttk.Label(analyst_frame, text="Priority:").grid(row=3, column=0, sticky=tk.W, pady=2)
        self.fields['priority'] = ttk.Combobox(analyst_frame, width=27,
            values=['1 - Urgent', '2 - High', '3 - Medium', '4 - Low', '5 - Very Low'])
        self.fields['priority'].set('3 - Medium')
        self.fields['priority'].grid(row=3, column=1, sticky=(tk.W, tk.E), pady=2)

        # === DETACHED ELEMENT ===
        detached_frame = ttk.LabelFrame(scrollable_frame, text="Detached Element (Optional)", padding=10)
        detached_frame.grid(row=5, column=0, columnspan=2, sticky=(tk.W, tk.E), padx=5, pady=5)

        self.fields['is_detached_element'] = tk.BooleanVar()
        ttk.Checkbutton(detached_frame, text="Is Detached Element",
            variable=self.fields['is_detached_element']).grid(row=0, column=0, columnspan=2, sticky=tk.W, pady=2)

        self.fields['is_main_body'] = tk.BooleanVar()
        ttk.Checkbutton(detached_frame, text="Is Main Body",
            variable=self.fields['is_main_body']).grid(row=1, column=0, columnspan=2, sticky=tk.W, pady=2)

        ttk.Label(detached_frame, text="Element Size:").grid(row=2, column=0, sticky=tk.W, pady=2)
        self.fields['element_size_estimate'] = ttk.Combobox(detached_frame, width=27,
            values=['', 'company', 'battalion', 'reinforced_company', 'reinforced_battalion', 'platoon'])
        self.fields['element_size_estimate'].grid(row=2, column=1, sticky=(tk.W, tk.E), pady=2)

        ttk.Label(detached_frame, text="Element Description:").grid(row=3, column=0, sticky=tk.W, pady=2)
        self.fields['element_description'] = ttk.Entry(detached_frame, width=50)
        self.fields['element_description'].grid(row=3, column=1, sticky=(tk.W, tk.E), pady=2)

        # === COMMAND RELATIONSHIPS ===
        command_frame = ttk.LabelFrame(scrollable_frame, text="Command Relationships (Optional)", padding=10)
        command_frame.grid(row=6, column=0, columnspan=2, sticky=(tk.W, tk.E), padx=5, pady=5)

        ttk.Label(command_frame, text="New Parent Unit:").grid(row=0, column=0, sticky=tk.W, pady=2)
        self.fields['new_parent_unit_key'] = ttk.Entry(command_frame, width=30)
        self.fields['new_parent_unit_key'].grid(row=0, column=1, sticky=(tk.W, tk.E), pady=2)

        ttk.Label(command_frame, text="New OPCON Unit:").grid(row=1, column=0, sticky=tk.W, pady=2)
        self.fields['new_opcon_unit_key'] = ttk.Entry(command_frame, width=30)
        self.fields['new_opcon_unit_key'].grid(row=1, column=1, sticky=(tk.W, tk.E), pady=2)

        ttk.Label(command_frame, text="New ADCON Unit:").grid(row=2, column=0, sticky=tk.W, pady=2)
        self.fields['new_adcon_unit_key'] = ttk.Entry(command_frame, width=30)
        self.fields['new_adcon_unit_key'].grid(row=2, column=1, sticky=(tk.W, tk.E), pady=2)

        ttk.Label(command_frame, text="Command Change Date:").grid(row=3, column=0, sticky=tk.W, pady=2)
        self.fields['command_change_date'] = ttk.Entry(command_frame, width=30)
        self.fields['command_change_date'].grid(row=3, column=1, sticky=(tk.W, tk.E), pady=2)

        # === BUTTONS ===
        button_frame = ttk.Frame(scrollable_frame)
        button_frame.grid(row=7, column=0, columnspan=2, pady=10)

        ttk.Button(button_frame, text="Add Unit to List", command=self.add_unit).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Clear Form", command=self.clear_form).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Submit All Units", command=self.submit_all).pack(side=tk.LEFT, padx=5)

        # === UNITS LIST ===
        list_frame = ttk.LabelFrame(scrollable_frame, text="Units Ready to Submit", padding=10)
        list_frame.grid(row=8, column=0, columnspan=2, sticky=(tk.W, tk.E), padx=5, pady=5)

        self.units_listbox = tk.Listbox(list_frame, height=6, width=100)
        self.units_listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        list_scrollbar = ttk.Scrollbar(list_frame, orient="vertical", command=self.units_listbox.yview)
        list_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.units_listbox.configure(yscrollcommand=list_scrollbar.set)

        ttk.Button(list_frame, text="Remove Selected", command=self.remove_unit).pack(pady=5)

        # === RIGHT PANE SETUP ===
        self.setup_right_pane(right_frame)

    def setup_right_pane(self, parent):
        """Setup the right pane with Alcamenes button and data display"""
        # Title for right pane
        title_label = ttk.Label(parent, text="Raw Data Viewer", font=('Arial', 14, 'bold'))
        title_label.pack(pady=(10, 10))

        # Button to launch Alcamenes
        button_frame = ttk.Frame(parent)
        button_frame.pack(pady=10)

        ttk.Button(button_frame, text="Launch Alcamenes Document Search",
                  command=self.launch_alcamenes, width=30).pack()

        ttk.Button(button_frame, text="Load Excel File",
                  command=self.load_excel_file, width=30).pack(pady=(5, 0))

        # Data display area
        data_frame = ttk.LabelFrame(parent, text="Document Data (Date, Paragraph, Section)", padding=10)
        data_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        # Create Treeview for displaying Excel data with horizontal scrollbar too
        tree_scroll_y = ttk.Scrollbar(data_frame, orient='vertical')
        tree_scroll_y.pack(side=tk.RIGHT, fill=tk.Y)

        tree_scroll_x = ttk.Scrollbar(data_frame, orient='horizontal')
        tree_scroll_x.pack(side=tk.BOTTOM, fill=tk.X)

        # Create Treeview with custom style for grid lines
        style = ttk.Style()
        style.configure("Custom.Treeview", rowheight=60)  # Increase row height for wrapping

        self.data_tree = ttk.Treeview(data_frame,
                                     columns=('Date', 'Paragraph', 'Section'),
                                     show='headings',
                                     yscrollcommand=tree_scroll_y.set,
                                     xscrollcommand=tree_scroll_x.set,
                                     style="Custom.Treeview")
        tree_scroll_y.config(command=self.data_tree.yview)
        tree_scroll_x.config(command=self.data_tree.xview)

        # Define column headings
        self.data_tree.heading('Date', text='Date')
        self.data_tree.heading('Paragraph', text='Paragraph')
        self.data_tree.heading('Section', text='Section')

        # Define column widths and stretch
        self.data_tree.column('Date', width=100, stretch=False)
        self.data_tree.column('Paragraph', width=500, stretch=True)  # Allow paragraph to expand
        self.data_tree.column('Section', width=150, stretch=False)

        # Configure tags for alternating row colors (grid effect)
        self.data_tree.tag_configure('oddrow', background='white')
        self.data_tree.tag_configure('evenrow', background='#f0f0f0')

        self.data_tree.pack(fill=tk.BOTH, expand=True)

        # Add context menu for copying
        self.create_context_menu()

        # Bind double-click to show full paragraph in copyable dialog
        self.data_tree.bind('<Double-Button-1>', self.show_paragraph_dialog)

    def create_context_menu(self):
        """Create right-click context menu for copying data"""
        self.context_menu = tk.Menu(self.data_tree, tearoff=0)
        self.context_menu.add_command(label="Copy Paragraph", command=self.copy_paragraph)
        self.context_menu.add_command(label="Copy Date", command=self.copy_date)
        self.context_menu.add_command(label="Copy Section", command=self.copy_section)
        self.context_menu.add_separator()
        self.context_menu.add_command(label="Copy Entire Row", command=self.copy_row)

        # Bind right-click to show context menu
        self.data_tree.bind('<Button-3>', self.show_context_menu)

    def show_context_menu(self, event):
        """Show context menu on right-click"""
        # Select row under cursor
        row_id = self.data_tree.identify_row(event.y)
        if row_id:
            self.data_tree.selection_set(row_id)
            self.context_menu.post(event.x_root, event.y_root)

    def copy_paragraph(self):
        """Copy paragraph text to clipboard"""
        selection = self.data_tree.selection()
        if selection:
            item = selection[0]
            values = self.data_tree.item(item, 'values')
            if len(values) > 1:
                self.root.clipboard_clear()
                self.root.clipboard_append(values[1])  # Paragraph is column 1
                messagebox.showinfo("Copied", "Paragraph copied to clipboard")

    def copy_date(self):
        """Copy date to clipboard"""
        selection = self.data_tree.selection()
        if selection:
            item = selection[0]
            values = self.data_tree.item(item, 'values')
            if len(values) > 0:
                self.root.clipboard_clear()
                self.root.clipboard_append(values[0])  # Date is column 0
                messagebox.showinfo("Copied", "Date copied to clipboard")

    def copy_section(self):
        """Copy section to clipboard"""
        selection = self.data_tree.selection()
        if selection:
            item = selection[0]
            values = self.data_tree.item(item, 'values')
            if len(values) > 2:
                self.root.clipboard_clear()
                self.root.clipboard_append(values[2])  # Section is column 2
                messagebox.showinfo("Copied", "Section copied to clipboard")

    def copy_row(self):
        """Copy entire row to clipboard"""
        selection = self.data_tree.selection()
        if selection:
            item = selection[0]
            values = self.data_tree.item(item, 'values')
            row_text = f"Date: {values[0]}\nParagraph: {values[1]}\nSection: {values[2]}"
            self.root.clipboard_clear()
            self.root.clipboard_append(row_text)
            messagebox.showinfo("Copied", "Entire row copied to clipboard")

    def show_paragraph_dialog(self, event):
        """Show paragraph in a dialog where user can select and copy text"""
        selection = self.data_tree.selection()
        if not selection:
            return

        item = selection[0]
        values = self.data_tree.item(item, 'values')

        if len(values) < 2:
            return

        # Create dialog window
        dialog = tk.Toplevel(self.root)
        dialog.title("Paragraph Text")
        dialog.geometry("600x400")

        # Add label
        ttk.Label(dialog, text="Select and copy text below:", font=('Arial', 10, 'bold')).pack(pady=10)

        # Add text widget with paragraph content
        text_widget = tk.Text(dialog, wrap=tk.WORD, font=('Arial', 10))
        text_widget.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        # Insert paragraph text (remove wrapping newlines, use original)
        paragraph_text = values[1].replace('\n', ' ')
        text_widget.insert('1.0', paragraph_text)

        # Make text selectable but not editable
        text_widget.config(state='normal')

        # Add close button
        ttk.Button(dialog, text="Close", command=dialog.destroy).pack(pady=10)

    def launch_alcamenes(self):
        """Launch AlcamenesGUI.py"""
        try:
            # Path to AlcamenesGUI.py
            alcamenes_path = os.path.join(
                os.path.dirname(os.path.dirname(__file__)),
                'Alcamenes',
                'AlcamenesGUI.py'
            )

            # Launch in separate process
            subprocess.Popen(['python', alcamenes_path])
            messagebox.showinfo("Launched", "AlcamenesGUI has been launched. When you're done, click 'Load Excel File' to import the data.")

        except Exception as e:
            messagebox.showerror("Error", f"Failed to launch AlcamenesGUI: {str(e)}")

    def load_excel_file(self):
        """Load Excel file and display first 3 columns with wrapped text"""
        try:
            # Open file dialog to select Excel file
            file_path = filedialog.askopenfilename(
                title="Select Excel File from Alcamenes",
                filetypes=[("Excel files", "*.xlsx"), ("All files", "*.*")]
            )

            if not file_path:
                return

            # Read Excel file
            df = pd.read_excel(file_path, engine='openpyxl')

            # Clear existing data
            for item in self.data_tree.get_children():
                self.data_tree.delete(item)

            # Insert first 3 columns with text wrapping and alternating colors
            for index, row in df.iterrows():
                # Wrap paragraph text to fit width (approx 70 chars per line)
                paragraph = str(row.get('Paragraph', ''))
                wrapped_paragraph = '\n'.join(textwrap.wrap(paragraph, width=70))

                values = (
                    row.get('Date', ''),
                    wrapped_paragraph,
                    row.get('Section', '')
                )

                # Apply alternating row colors
                tag = 'evenrow' if index % 2 == 0 else 'oddrow'
                self.data_tree.insert('', tk.END, values=values, tags=(tag,))

            self.excel_data = df
            messagebox.showinfo("Success", f"Loaded {len(df)} rows from Excel file")

        except Exception as e:
            messagebox.showerror("Error", f"Failed to load Excel file: {str(e)}")

    def load_tactical_areas(self):
        """Load tactical areas from database with operational area associations and area_type"""
        try:
            conn = psycopg2.connect(**self.db_config)
            cur = conn.cursor()

            # Query tactical areas with their operational area associations and area_type
            cur.execute("""
                SELECT DISTINCT
                    ta.tactical_area_id,
                    ta.tactical_area_name,
                    ta.area_type,
                    COALESCE(
                        ARRAY_AGG(toa.operational_area_id) FILTER (WHERE toa.is_active = TRUE),
                        ARRAY[]::INTEGER[]
                    ) as operational_area_ids
                FROM spatial_ref.tactical_areas ta
                LEFT JOIN spatial_ref.tactical_operational_associations toa
                    ON ta.tactical_area_id = toa.tactical_area_id
                WHERE active = TRUE
                GROUP BY ta.tactical_area_id, ta.tactical_area_name, ta.area_type
                ORDER BY ta.tactical_area_name
            """)

            for tactical_area_id, tactical_area_name, area_type, operational_area_ids in cur.fetchall():
                # Store in type-specific dictionaries
                if area_type == 'frontal':
                    self.tactical_areas_frontal[tactical_area_name] = tactical_area_id
                elif area_type in ['rear', 'deep_rear']:  # Group rear types together
                    self.tactical_areas_rear[tactical_area_name] = tactical_area_id

                # Store full info including area_type
                self.tactical_areas_full[tactical_area_name] = (tactical_area_id, operational_area_ids or [], area_type)

            cur.close()
            conn.close()

        except Exception as e:
            messagebox.showerror("Database Error", f"Failed to load tactical areas: {str(e)}")
            # If database load fails, continue with empty dict
            self.tactical_areas_frontal = {}
            self.tactical_areas_rear = {}
            self.tactical_areas_full = {}

    def load_db_config(self):
        """Load database configuration from db_config.json"""
        try:
            config_path = os.path.join(os.path.dirname(__file__), 'db_config.json')
            with open(config_path, 'r') as f:
                config = json.load(f)
            return config
        except FileNotFoundError:
            messagebox.showerror("Configuration Error",
                f"db_config.json not found at {config_path}\n"
                "Please create a db_config.json file with database credentials.")
            raise
        except json.JSONDecodeError as e:
            messagebox.showerror("Configuration Error",
                f"Invalid JSON in db_config.json: {str(e)}")
            raise
        except Exception as e:
            messagebox.showerror("Configuration Error",
                f"Failed to load db_config.json: {str(e)}")
            raise

    def load_operational_areas(self):
        """Load operational areas from database"""
        try:
            conn = psycopg2.connect(**self.db_config)
            cur = conn.cursor()

            # Query operational areas table
            cur.execute("""
                SELECT area_id, name
                FROM spatial_ref.operational_areas
                WHERE active = TRUE
                ORDER BY name
            """)

            for area_id, name in cur.fetchall():
                self.operational_areas[name] = area_id

            cur.close()
            conn.close()

        except Exception as e:
            messagebox.showerror("Database Error", f"Failed to load operational areas: {str(e)}")
            # If database load fails, continue with empty dict
            self.operational_areas = {}

    def on_operational_area_changed(self, event=None):
        """Filter frontal and rear tactical areas when operational area is selected"""
        selected_op_area = self.fields['operational_area'].get()

        if not selected_op_area:
            # If no operational area selected, show all tactical areas
            frontal_names = [''] + sorted(self.tactical_areas_frontal.keys())
            rear_names = [''] + sorted(self.tactical_areas_rear.keys())
        else:
            # Filter tactical areas by operational area (many-to-many)
            selected_op_area_id = self.operational_areas.get(selected_op_area)

            # Filter frontal areas
            filtered_frontal = {
                name: area_id
                for name, (area_id, op_area_ids, area_type) in self.tactical_areas_full.items()
                if selected_op_area_id in op_area_ids and area_type == 'frontal'
            }
            frontal_names = [''] + sorted(filtered_frontal.keys())

            # Filter rear areas
            filtered_rear = {
                name: area_id
                for name, (area_id, op_area_ids, area_type) in self.tactical_areas_full.items()
                if selected_op_area_id in op_area_ids and area_type in ['rear', 'deep_rear']
            }
            rear_names = [''] + sorted(filtered_rear.keys())

        # Update both tactical area dropdowns
        self.fields['tactical_area_frontal']['values'] = frontal_names
        self.fields['tactical_area_frontal'].set('')  # Clear current selection
        self.fields['tactical_area_rear']['values'] = rear_names
        self.fields['tactical_area_rear'].set('')  # Clear current selection

    def on_frontal_area_selected(self, event=None):
        """Clear rear area when frontal area is selected"""
        if self.fields['tactical_area_frontal'].get():
            self.fields['tactical_area_rear'].set('')

    def on_rear_area_selected(self, event=None):
        """Clear frontal area when rear area is selected"""
        if self.fields['tactical_area_rear'].get():
            self.fields['tactical_area_frontal'].set('')

    def load_sources(self):
        """Load sources from database"""
        try:
            conn = psycopg2.connect(**self.db_config)
            cur = conn.cursor()

            # Query sources table
            cur.execute("""
                SELECT source_id, source_name
                FROM reference.sources
                WHERE source_id IS NOT NULL
                ORDER BY source_name
            """)

            for source_id, source_name in cur.fetchall():
                self.sources[source_name] = source_id

            cur.close()
            conn.close()

        except Exception as e:
            messagebox.showerror("Database Error", f"Failed to load sources: {str(e)}")
            # If database load fails, continue with empty dict
            self.sources = {}

    def open_unit_search(self):
        """Open unit search dialog"""
        search_window = tk.Toplevel(self.root)
        search_window.title("Search Units")
        search_window.geometry("600x500")

        # Search frame
        search_frame = ttk.Frame(search_window, padding=10)
        search_frame.pack(fill=tk.X)

        ttk.Label(search_frame, text="Search by unit name:").pack(side=tk.LEFT, padx=5)
        search_entry = ttk.Entry(search_frame, width=30)
        search_entry.pack(side=tk.LEFT, padx=5)

        # Variable to store search results
        search_results = []

        def perform_search():
            """Search russian_units table"""
            search_term = search_entry.get().strip()
            if not search_term:
                messagebox.showwarning("Search", "Please enter a search term")
                return

            try:
                conn = psycopg2.connect(**self.db_config)
                cur = conn.cursor()

                # Search for units matching the pattern
                cur.execute("""
                    SELECT unit_key, unit_name, mun_number, unit_type, parent_unit
                    FROM russian_units
                    WHERE unit_name ILIKE %s
                    ORDER BY unit_name
                    LIMIT 100
                """, (f'%{search_term}%',))

                results = cur.fetchall()
                cur.close()
                conn.close()

                # Clear previous results
                results_listbox.delete(0, tk.END)
                search_results.clear()

                if not results:
                    results_listbox.insert(tk.END, "No units found")
                else:
                    for unit_key, unit_name, mun_number, unit_type, parent_unit in results:
                        search_results.append((unit_key, unit_name))
                        parent_display = f"Parent: {parent_unit}" if parent_unit else "No parent"
                        display_text = f"{unit_name} ({unit_key}) - {mun_number or 'N/A'} - {unit_type or 'N/A'} - {parent_display}"
                        results_listbox.insert(tk.END, display_text)

            except Exception as e:
                messagebox.showerror("Search Error", f"Failed to search units: {str(e)}")

        def select_unit():
            """Select unit from results and close dialog"""
            selection = results_listbox.curselection()
            if not selection:
                messagebox.showwarning("Selection", "Please select a unit")
                return

            if search_results:  # Make sure we have valid results
                index = selection[0]
                if index < len(search_results):
                    unit_key, unit_name = search_results[index]
                    # Set the unit_key field in main form
                    self.fields['unit_key'].delete(0, tk.END)
                    self.fields['unit_key'].insert(0, unit_key)
                    search_window.destroy()

        ttk.Button(search_frame, text="Search", command=perform_search).pack(side=tk.LEFT, padx=5)

        # Results frame
        results_frame = ttk.LabelFrame(search_window, text="Search Results", padding=10)
        results_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        # Results listbox with scrollbar
        results_scrollbar = ttk.Scrollbar(results_frame)
        results_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        results_listbox = tk.Listbox(results_frame, height=15, yscrollcommand=results_scrollbar.set)
        results_listbox.pack(fill=tk.BOTH, expand=True)
        results_scrollbar.config(command=results_listbox.yview)

        # Add double-click to select
        results_listbox.bind('<Double-Button-1>', lambda e: select_unit())

        # Buttons frame
        button_frame = ttk.Frame(search_window, padding=10)
        button_frame.pack(fill=tk.X)

        ttk.Button(button_frame, text="Select Unit", command=select_unit).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Cancel", command=search_window.destroy).pack(side=tk.LEFT, padx=5)

        # Bind Enter key to search
        search_entry.bind('<Return>', lambda e: perform_search())
        search_entry.focus()

    def launch_insert_unit_gui(self):
        """Launch insert_unit_gui.py and wait for it to close"""
        try:
            # Path to insert_unit_gui.py (same directory as this file)
            insert_unit_path = os.path.join(
                os.path.dirname(__file__),
                'insert_unit_gui.py'
            )

            if not os.path.exists(insert_unit_path):
                messagebox.showerror("Error", f"Cannot find insert_unit_gui.py at:\n{insert_unit_path}")
                return

            # Launch and wait for it to close (blocking)
            result = subprocess.run(['python', insert_unit_path])

            if result.returncode == 0:
                messagebox.showinfo("Success", "Unit added successfully! You can now search for it in the unit search.")
            else:
                messagebox.showwarning("Closed", "Insert unit window closed.")

        except Exception as e:
            messagebox.showerror("Error", f"Failed to launch insert_unit_gui.py: {str(e)}")

    def extract_code_from_dropdown(self, value):
        """Extract code from dropdown value like '0 - Present' -> 0"""
        if not value or value == '':
            return None
        # If it's already a number, return it
        if isinstance(value, (int, float)):
            return value
        # Handle status codes (integers)
        if value[0].isdigit() and ' - ' in value:
            return int(value.split(' - ')[0])
        # Handle text codes (A-F)
        elif value[0].isalpha() and ' - ' in value:
            return value.split(' - ')[0]
        # Handle operational condition codes
        elif value.startswith(('100', '110', '120', '130', '140', '150')):
            return value.split(' - ')[0]
        return value

    def get_form_data(self):
        """Extract data from form fields"""
        data = {'unit_key': self.fields['unit_key'].get().strip()}

        # Location data (convert tactical_area name to ID)
        # Check frontal first
        tactical_area_frontal = self.fields['tactical_area_frontal'].get()
        if tactical_area_frontal and tactical_area_frontal in self.tactical_areas_frontal:
            data['tactical_area_id'] = self.tactical_areas_frontal[tactical_area_frontal]
        else:
            # Check rear
            tactical_area_rear = self.fields['tactical_area_rear'].get()
            if tactical_area_rear and tactical_area_rear in self.tactical_areas_rear:
                data['tactical_area_id'] = self.tactical_areas_rear[tactical_area_rear]

        # Assessment data
        status_val = self.extract_code_from_dropdown(self.fields['status'].get())
        if status_val is not None:
            data['status'] = status_val

        if self.fields['reinforced'].get():
            data['reinforced'] = self.fields['reinforced'].get()

        op_cond = self.extract_code_from_dropdown(self.fields['operational_condition'].get())
        if op_cond:
            data['operational_condition'] = op_cond

        if self.fields['action'].get().strip():
            data['action'] = self.fields['action'].get().strip()

        # Source attribution
        if self.fields['source_url'].get().strip():
            data['source_url'] = self.fields['source_url'].get().strip()

        # Convert source name to source_id
        source_name = self.fields['source'].get()
        if source_name and source_name in self.sources:
            data['source_id'] = self.sources[source_name]

        if self.fields['source_excerpt'].get('1.0', tk.END).strip():
            data['source_excerpt'] = self.fields['source_excerpt'].get('1.0', tk.END).strip()

        cred_val = self.extract_code_from_dropdown(self.fields['credibility'].get())
        if cred_val:
            data['credibility'] = int(cred_val) if isinstance(cred_val, int) else (int(cred_val) if str(cred_val).isdigit() else None)

        rel_val = self.extract_code_from_dropdown(self.fields['reliability'].get())
        if rel_val:
            data['reliability'] = rel_val

        # Analyst data
        if self.fields['analyst'].get().strip():
            data['analyst'] = self.fields['analyst'].get().strip()
        if self.fields['observation_date'].get().strip():
            obs_date = self.fields['observation_date'].get().strip()
            # If only date provided (YYYY-MM-DD), append default time 13:30:00
            if len(obs_date) == 10 and obs_date.count('-') == 2:
                data['observation_date'] = obs_date + ' 13:30:00'
            else:
                data['observation_date'] = obs_date
        if self.fields['analyst_notes'].get('1.0', tk.END).strip():
            data['analyst_notes'] = self.fields['analyst_notes'].get('1.0', tk.END).strip()

        priority_val = self.extract_code_from_dropdown(self.fields['priority'].get())
        if priority_val:
            data['priority'] = int(priority_val) if isinstance(priority_val, int) else (int(priority_val) if str(priority_val).isdigit() else 3)

        # Detached element
        if self.fields['is_detached_element'].get():
            data['is_detached_element'] = True
        if self.fields['is_main_body'].get():
            data['is_main_body'] = True
        if self.fields['element_size_estimate'].get():
            data['element_size_estimate'] = self.fields['element_size_estimate'].get()
        if self.fields['element_description'].get().strip():
            data['element_description'] = self.fields['element_description'].get().strip()

        # Command relationships
        if self.fields['new_parent_unit_key'].get().strip():
            data['new_parent_unit_key'] = self.fields['new_parent_unit_key'].get().strip()
        if self.fields['new_opcon_unit_key'].get().strip():
            data['new_opcon_unit_key'] = self.fields['new_opcon_unit_key'].get().strip()
        if self.fields['new_adcon_unit_key'].get().strip():
            data['new_adcon_unit_key'] = self.fields['new_adcon_unit_key'].get().strip()
        if self.fields['command_change_date'].get().strip():
            data['command_change_date'] = self.fields['command_change_date'].get().strip()

        return data

    def add_unit(self):
        """Add current form data to the units list"""
        try:
            data = self.get_form_data()

            # Validate required fields
            if not data.get('unit_key'):
                messagebox.showerror("Error", "Unit Key is required!")
                return

            self.units_to_submit.append(data)

            # Add to listbox - show area name instead of ID
            # Check which tactical area field has a value
            tactical_area_name = self.fields['tactical_area_frontal'].get() or self.fields['tactical_area_rear'].get() or 'N/A'
            action = data.get('action', 'N/A')
            display_str = f"{data['unit_key']} - Area: {tactical_area_name} - {action}"
            self.units_listbox.insert(tk.END, display_str)

            messagebox.showinfo("Success", f"Unit {data['unit_key']} added to list!")
            self.clear_form()

        except Exception as e:
            messagebox.showerror("Error", f"Failed to add unit: {str(e)}")

    def remove_unit(self):
        """Remove selected unit from the list"""
        selection = self.units_listbox.curselection()
        if selection:
            index = selection[0]
            self.units_listbox.delete(index)
            del self.units_to_submit[index]

    def clear_form(self):
        """Clear all form fields"""
        # Clear text entries
        for key, widget in self.fields.items():
            if isinstance(widget, DateEntry):
                # Skip DateEntry here, handle it below in reset defaults
                continue
            elif isinstance(widget, ttk.Entry):
                widget.delete(0, tk.END)
            elif isinstance(widget, ttk.Combobox):
                widget.set('')
            elif isinstance(widget, scrolledtext.ScrolledText):
                widget.delete('1.0', tk.END)
            elif isinstance(widget, tk.BooleanVar):
                widget.set(False)

        # Reset defaults
        self.fields['status'].set('0 - Present')
        self.fields['reinforced'].set('-')
        self.fields['operational_condition'].set('140 - Effectiveness Unknown')
        self.fields['analyst'].insert(0, 'nkramer')
        self.fields['observation_date'].set_date(datetime.now().date())
        self.fields['priority'].set('3 - Medium')

    def submit_all(self):
        """Submit all units to the database"""
        if not self.units_to_submit:
            messagebox.showerror("Error", "No units to submit!")
            return

        try:
            results = batch_insert_unit_mentions(self.units_to_submit)

            # Display results
            result_msg = "\n".join([f"{r['unit_key']}: {r['action']} - {r['location']}" for r in results])
            messagebox.showinfo("Submission Complete", f"Successfully submitted {len(results)} unit(s):\n\n{result_msg}")

            # Clear the list
            self.units_to_submit.clear()
            self.units_listbox.delete(0, tk.END)

        except Exception as e:
            messagebox.showerror("Error", f"Failed to submit units: {str(e)}")

def main():
    root = tk.Tk()
    app = UnitMentionsGUI(root)
    root.mainloop()

if __name__ == "__main__":
    main()
