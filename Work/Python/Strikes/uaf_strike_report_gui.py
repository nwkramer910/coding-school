#!/usr/bin/env python3
"""
GUI wrapper for UAF Strike Report Generator
Provides easy-to-use interface for pasting and processing UAF Telegram posts
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
import os
from datetime import datetime
from uaf_strike_report_generator import (
    StrikeDataParser,
    ExcelHandler,
    WordDocumentGenerator
)


class StrikeReportGUI:
    """GUI application for UAF Strike Report Generator."""

    def __init__(self, root):
        self.root = root
        self.root.title("UAF Strike Report Generator")
        self.root.geometry("900x700")

        # Set minimum window size
        self.root.minsize(700, 500)

        self.setup_ui()

    def setup_ui(self):
        """Setup the user interface."""
        # Main container with padding
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

        # Configure grid weights for resizing
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(0, weight=1)
        main_frame.rowconfigure(1, weight=1)
        main_frame.rowconfigure(3, weight=1)

        # Title
        title_label = ttk.Label(
            main_frame,
            text="UAF Strike Report Generator",
            font=('Helvetica', 16, 'bold')
        )
        title_label.grid(row=0, column=0, pady=(0, 10), sticky=tk.W)

        # Input section
        input_frame = ttk.LabelFrame(main_frame, text="Input: UAF Telegram Post (English Translation)", padding="5")
        input_frame.grid(row=1, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 10))
        input_frame.columnconfigure(0, weight=1)
        input_frame.rowconfigure(0, weight=1)

        # Text area for input
        self.input_text = scrolledtext.ScrolledText(
            input_frame,
            wrap=tk.WORD,
            width=80,
            height=12,
            font=('Courier', 10)
        )
        self.input_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

        # Placeholder text
        placeholder = (
            "Paste the English-translated UAF Telegram post here...\n\n"
            "Example:\n"
            "On the night of October 21-22, Russian forces launched 75 Shahed-type drones...\n"
        )
        self.input_text.insert('1.0', placeholder)
        self.input_text.config(fg='gray')

        # Bind events for placeholder behavior
        self.input_text.bind('<FocusIn>', self.on_input_focus_in)
        self.input_text.bind('<FocusOut>', self.on_input_focus_out)

        # Options frame
        options_frame = ttk.Frame(main_frame)
        options_frame.grid(row=2, column=0, sticky=(tk.W, tk.E), pady=(0, 10))

        # Output options
        ttk.Label(options_frame, text="Generate:").grid(row=0, column=0, padx=(0, 10))

        self.generate_excel = tk.BooleanVar(value=True)
        self.generate_word = tk.BooleanVar(value=True)

        ttk.Checkbutton(
            options_frame,
            text="Excel Tracking Sheet",
            variable=self.generate_excel
        ).grid(row=0, column=1, padx=5)

        ttk.Checkbutton(
            options_frame,
            text="Word Document",
            variable=self.generate_word
        ).grid(row=0, column=2, padx=5)

        # Buttons frame
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=2, column=0, sticky=tk.E, pady=(0, 10))

        # Process button
        self.process_btn = ttk.Button(
            button_frame,
            text="Process Report",
            command=self.process_report,
            style='Accent.TButton'
        )
        self.process_btn.grid(row=0, column=0, padx=5)

        # Clear button
        ttk.Button(
            button_frame,
            text="Clear",
            command=self.clear_input
        ).grid(row=0, column=1, padx=5)

        # Results/Status section
        results_frame = ttk.LabelFrame(main_frame, text="Results & Status", padding="5")
        results_frame.grid(row=3, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        results_frame.columnconfigure(0, weight=1)
        results_frame.rowconfigure(0, weight=1)

        # Results text area
        self.results_text = scrolledtext.ScrolledText(
            results_frame,
            wrap=tk.WORD,
            width=80,
            height=15,
            font=('Courier', 9),
            state='disabled'
        )
        self.results_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

        # Configure text tags for colored output
        self.results_text.tag_config('success', foreground='green')
        self.results_text.tag_config('error', foreground='red')
        self.results_text.tag_config('warning', foreground='orange')
        self.results_text.tag_config('info', foreground='blue')
        self.results_text.tag_config('bold', font=('Courier', 9, 'bold'))

    def on_input_focus_in(self, event):
        """Remove placeholder text when user clicks in the input area."""
        if self.input_text.get('1.0', 'end-1c') == self.input_text.cget('fg') == 'gray':
            current_text = self.input_text.get('1.0', 'end-1c')
            if 'Paste the English-translated' in current_text:
                self.input_text.delete('1.0', tk.END)
                self.input_text.config(fg='black')

    def on_input_focus_out(self, event):
        """Restore placeholder if input is empty."""
        if not self.input_text.get('1.0', 'end-1c').strip():
            placeholder = (
                "Paste the English-translated UAF Telegram post here...\n\n"
                "Example:\n"
                "On the night of October 21-22, Russian forces launched 75 Shahed-type drones...\n"
            )
            self.input_text.delete('1.0', tk.END)
            self.input_text.insert('1.0', placeholder)
            self.input_text.config(fg='gray')

    def clear_input(self):
        """Clear the input text area."""
        self.input_text.delete('1.0', tk.END)
        self.input_text.config(fg='black')
        self.clear_results()

    def clear_results(self):
        """Clear the results text area."""
        self.results_text.config(state='normal')
        self.results_text.delete('1.0', tk.END)
        self.results_text.config(state='disabled')

    def append_result(self, text, tag=None):
        """Append text to results area with optional tag."""
        self.results_text.config(state='normal')
        if tag:
            self.results_text.insert(tk.END, text, tag)
        else:
            self.results_text.insert(tk.END, text)
        self.results_text.see(tk.END)
        self.results_text.config(state='disabled')
        self.root.update_idletasks()

    def process_report(self):
        """Process the UAF report and generate outputs."""
        # Get input text
        input_text = self.input_text.get('1.0', 'end-1c').strip()

        # Validate input
        if not input_text or 'Paste the English-translated' in input_text:
            messagebox.showwarning(
                "No Input",
                "Please paste the UAF Telegram post text before processing."
            )
            return

        # Check if at least one output option is selected
        if not self.generate_excel.get() and not self.generate_word.get():
            messagebox.showwarning(
                "No Output Selected",
                "Please select at least one output option (Excel or Word)."
            )
            return

        # Clear previous results
        self.clear_results()

        # Disable process button
        self.process_btn.config(state='disabled')

        try:
            # Parse data
            self.append_result("=" * 60 + "\n", 'bold')
            self.append_result("UAF STRIKE REPORT PROCESSING\n", 'bold')
            self.append_result("=" * 60 + "\n\n", 'bold')

            self.append_result("Step 1: Parsing text data...\n", 'info')
            parser = StrikeDataParser(input_text)
            data = parser.parse_all()
            self.append_result("✓ Parsing complete\n\n", 'success')

            # Display parsed data summary
            self.append_result("Extracted Data Summary:\n", 'bold')
            self.append_result("-" * 60 + "\n")
            self.append_result(f"Date: {data.get('date_phrase') or 'NULL'}\n")
            self.append_result(f"Total Drones: {data.get('total_drones') or 'NULL'}\n")
            self.append_result(f"Total Missiles: {data.get('total_missiles') or 'NULL'}\n")
            self.append_result(f"Total Air Targets: {data.get('total_air_targets') or 'NULL'}\n")
            self.append_result("-" * 60 + "\n\n")

            # Check for NULL values
            null_fields = []
            for key, value in data.items():
                if value is None and key not in ['impact_info', 'drone_launch_locations', 'missile_launch_locations']:
                    null_fields.append(key)

            if null_fields:
                self.append_result(f"⚠ Warning: {len(null_fields)} field(s) could not be extracted:\n", 'warning')
                for field in null_fields[:5]:  # Show first 5
                    self.append_result(f"  - {field}\n", 'warning')
                if len(null_fields) > 5:
                    self.append_result(f"  ... and {len(null_fields) - 5} more\n", 'warning')
                self.append_result("\n")

            # Generate Excel
            if self.generate_excel.get():
                self.append_result("Step 2: Updating Excel tracking sheet...\n", 'info')
                excel_handler = ExcelHandler()
                excel_handler.load_or_create()
                excel_handler.append_data(data)
                excel_handler.save()
                self.append_result("✓ Excel file updated: RUAF_Strikes_in_UA.xlsx\n\n", 'success')

            # Generate Word document
            word_filename = None
            if self.generate_word.get():
                self.append_result("Step 3: Generating Word document...\n", 'info')
                doc_generator = WordDocumentGenerator(data, input_text)
                word_filename = doc_generator.generate()
                self.append_result(f"✓ Word document created: {word_filename}\n\n", 'success')

            # Final summary
            self.append_result("=" * 60 + "\n", 'bold')
            self.append_result("PROCESSING COMPLETE\n", 'bold')
            self.append_result("=" * 60 + "\n", 'bold')
            self.append_result("\nGenerated Files:\n", 'info')
            if self.generate_excel.get():
                self.append_result(f"  • RUAF_Strikes_in_UA.xlsx\n")
            if self.generate_word.get():
                self.append_result(f"  • {word_filename}\n")

            # Show success message
            messagebox.showinfo(
                "Success",
                "Strike report processed successfully!\n\n"
                f"Files saved in: {os.getcwd()}"
            )

        except Exception as e:
            self.append_result(f"\n✗ ERROR: {str(e)}\n", 'error')
            messagebox.showerror(
                "Processing Error",
                f"An error occurred while processing the report:\n\n{str(e)}"
            )

        finally:
            # Re-enable process button
            self.process_btn.config(state='normal')


def main():
    """Main entry point for the GUI application."""
    root = tk.Tk()

    # Set application icon/style if available
    try:
        # Try to use a better theme if available
        style = ttk.Style()
        available_themes = style.theme_names()
        if 'clam' in available_themes:
            style.theme_use('clam')
        elif 'alt' in available_themes:
            style.theme_use('alt')
    except:
        pass

    app = StrikeReportGUI(root)
    root.mainloop()


if __name__ == '__main__':
    main()
