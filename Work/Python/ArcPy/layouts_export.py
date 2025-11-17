import sys 
import time
import zipfile
import arcpy
import os

output_folder = r"C:\Users\nkramer\OneDrive - Institute of the Study of War\ISW Files\Exports\20251015" #Your Path Here
aprx = arcpy.mp.ArcGISProject("CURRENT")  # This accesses the current ArcGIS Pro project

# Get the formatted date in 'Month D, YYYY' format
formatted_date = time.strftime('%B %#d, %Y')

# List of layout names you want to export (modify this list)
layouts_to_export = [
    
    # "Russo-Ukrainian War",

    # Tier 1    
    
    # "Sumy Direction",
    # "Kharkiv Direction",
    # "Luhansk Oblast",
    # "Borova-Lyman Direction",
    # "Donetsk Oblast",
    # "Kostyantynivka-Druzhkivka Tactical Area",
    # "Pokrovsk Direction",
    # "Zaporizhia Oblast",
    # "Kherson Direction",

    # Tier 2
    
    # "Kupyansk Direction",
    # "Lyman Tactical Area",
    # "Dobropillya Tactical Area",
    # "Novopavlivka Direction",
    # "Eastern Dnipropetrovsk Direction",
    # "Eastern Zaporizhia",
    # "Zaporizhzhia City Direction",

    # Tier 3
    
    # "Tetkino",
    # "Lyptsi Direction",
    # "Velykyi Burluk Direction", 
    # "Siversk Direction",
    # "Orikhiv Direction",

    # Cities
    
    # "Pokrovsk and Myrnohrad",
    # "Kostyantynivka",
    # "Chasiv Yar",
    # "Vovchansk",
    # "Kupyansk City"
    ]    

'''
This section defines which layouts have field forts, railroads, and geodesic circle displayed
This is necessary because all layouts are using the same map

DO NOT EDIT! DO NOT EDIT! DO NOT EDIT! DO NOT EDIT! DO NOT EDIT! DO NOT EDIT! DO NOT EDIT! DO NOT EDIT!
Unless we are making a call about modifying what we are displaying, and you are prepared to edit the legend as well
'''

layouts_with_RU_field_forts = [
    "Sumy Direction",
    "Tetkino",
    "Kharkiv Direction",
    "Luhansk Oblast",
    "Kupyansk Direction",
    "Borova-Lyman Direction",
    "Donetsk Oblast",
    "Kostyantynivka-Druzhkivka Tactical Area",
    "Eastern Dnipropetrovsk Oblast",
    "Orikhiv Direction",
    "Zaporizhia Direction",
    "Kamyanske Direction",
    "Kherson Direction",
    "Lyman Tactical Area",
]

layouts_with_railways = [
    "Sumy Direction",
    "Tetkino",
    "Kostyantynivka-Druzhkivka Tactical Area",
    "Pokrovsk Direction",   
]

layouts_with_circle = [
    "Kharkiv Direction",
]

layouts_with_ZNPP = [
    "Kherson Direction",
]

layers_to_turn_off = ["Fighting Circle Guide", "EditsToday"]
fieldforts = "Russian Field Fortifications"
railways = "Selected Railroads"
circle = "Kharkiv Geodesic Circle"
ZNPP = "Kherson Buildings"

# Iterate through each layout in the project
for layout in aprx.listLayouts():
    # Check if the layout's name is in the list of layouts to export
    if layout.name in layouts_to_export:
        print(f"Processing layout: {layout.name}")

        map_frame_elements = layout.listElements('MAPFRAME_ELEMENT')

        # Identify map frame in layout
        map_frame = None
        for frame in map_frame_elements:
            if frame.name == "Map Frame": ### Map in Layout MUST BE CALLED "Map Frame" ###
                map_frame = frame
                
        map = map_frame.map
        
        # Check if the FCs/Edits exist in the map
        layer_found = False
        for layer in map.listLayers():
            if layer.name in layers_to_turn_off: # if FCs/Edits exist in the map
                layer.visible = False  # Turn off the layer
                layer_found = True
                print(f"Turning off layer: {layer.name} in layout: {layout.name}")

        # set the starting positions to be turned off
        map.listLayers(fieldforts)[0].visible = False # turn off field forts
        map.listLayers(railways)[0].visible = False # turn off railways
        map.listLayers(circle)[0].visible = False  # turn off circles
        map.listLayers(ZNPP)[0].visible = False  # turn off circles

        # Check if need field forts
        if layout.name in layouts_with_RU_field_forts:
            map.listLayers(fieldforts)[0].visible = True # turn on field forts
        # Check if need railways
        if layout.name in layouts_with_railways:
            map.listLayers(railways)[0].visible = True # turn on railways
        # Check if need circle
        if layout.name in layouts_with_circle:
            map.listLayers(circle)[0].visible = True  # turn on circles
        if layout.name in layouts_with_ZNPP:
            map.listLayers(ZNPP)[0].visible = True  # turn on circles
        
        # Define the name of the PNG file (same as the layout name)
        output_png = os.path.join(output_folder, f"{layout.name} {formatted_date}.png")
        
        # Print progress
        print(f"Exporting layout: {layout.name} to {output_png}")
        
        # Export the layout to PNG with 190 DPI resolution and 8-bit colors.
        layout.exportToPNG(output_png, resolution=190, color_mode="8-BIT_ADAPTIVE_PALETTE")
        # Add a 5-second delay before processing the next layout
        time.sleep(5)
        
        # Restore the layer visibility to anything we turned off
        for layer in map.listLayers():
            if layer.name in layers_to_turn_off:
                layer.visible = True  # Restore visibility
                print(f"Restoring visibility for layer: {layer.name} in layout: {layout.name}")

                # Check if need field forts
        if layout.name in layouts_with_RU_field_forts:
            map.listLayers(fieldforts)[0].visible = False # turn off field forts
        # Check if need railways
        if layout.name in layouts_with_railways:
            map.listLayers(railways)[0].visible = False # turn off railways
        # Check if need circle
        if layout.name in layouts_with_circle:
            map.listLayers(circle)[0].visible = False  # turn off circles
        if layout.name in layouts_with_ZNPP:
            map.listLayers(ZNPP)[0].visible = False  # turn off circles
    
print("Export process complete! \U0001F642")