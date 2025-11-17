"""
This script exports shapefiles like normal, but also calculates the area while doing so, 
and prints it out for you to copoy and paste at the end. 

It calculates geodesic area using the Europe Albers Equal Area Conic projection.

It exports FCs and Infiltration points too.
"""

import sys 
import time
import zipfile
import arcpy
import os

# Define folder paths. 
daily_output_folder = r"C:\Your\Path\Here"
aprx = arcpy.mp.ArcGISProject("CURRENT")  # This accesses the current ArcGIS Pro project
m = aprx.activeMap

# To allow overwriting outputs change overwriteOutput option to True.
arcpy.env.overwriteOutput = True

# calcualates the area if true, not if false.
areacalc = True

# Record the start time
start_time = time.perf_counter()

# Deselection code
for layer in m.listLayers():
    if layer.isFeatureLayer:
        arcpy.management.SelectLayerByAttribute(layer, "CLEAR_SELECTION")
        print(f"Selection cleared for {layer.name}.")


# Feature classes to export
Assessed_Russian_controlled_Ukrainian_Territory = "CoT\\Control of Terrain in Ukraine\\Assessed Russian-controlled Ukrainian Territory"
Assessed_Russian_Advances_in_Ukraine = "CoT\\Control of Terrain in Ukraine\\Assessed Russian Advances in Ukraine"
Claimed_Russian_Control_over_Ukrainian_Territory = "CoT\\Control of Terrain in Ukraine\\Claimed Russian Control over Ukrainian Territory"
Claimed_Ukrainian_Counteroffensives = "CoT\\Control of Terrain in Ukraine\\Claimed Ukrainian Counteroffensives"
Reported_Ukrainian_Partisan_Warfare = "CoT\\Control of Terrain in Ukraine\\Reported Ukrainian Partisan Warfare"
Assessed_Russian_Infiltration_Areas_in_Ukraine = "CoT\\Control of Terrain in Ukraine\\Assessed Russian Infiltration Areas in Ukraine"
Russian_Advances_in_Russia = "CoT\\Control of Terrain in Russia\\Russian Advances in Russia"
Claimed_Russian_Advances_in_Russia = "CoT\\Control of Terrain in Russia\\Claimed Russian Advances in Russia"
Ukrainian_Advances_in_Russia = "CoT\\Control of Terrain in Russia\\Ukrainian Advances in Russia"


FCs = "Fighting Circle Guide"

features_to_calculate_area = [
    Assessed_Russian_controlled_Ukrainian_Territory,
    Assessed_Russian_Advances_in_Ukraine,
    Ukrainian_Advances_in_Russia
]

# Get the formatted date in 'DDMONYYYY' format
formatted_date1 = time.strftime('%d%b%Y').upper()

# Get the formatted date in 'MONDDYYYY' format
formatted_date2 = time.strftime('%b%d%Y').upper()

# Get the formatted date in 'Month D, YYYY' format
formatted_date3 = time.strftime('%B %d, %Y')

# Naming conventions of exports
ExportName_CoT =  f"UkraineControlMapAO{formatted_date1}"
ExportName_RUAdvances = f"AssessedRussianAdvancesinUkraine{formatted_date2}"
ExportName_RUClaims = f"ClaimedRussianTerritoryinUkraine{formatted_date2}"
ExportName_UAFCO = f"ClaimedUkrainianCounteroffensives{formatted_date2}"
ExportName_Partisan = f"ReportedUkrainianPartisanWarfare{formatted_date2}"
ExportName_KurskRUAdvances = f"Kursk Incursion Russian Advances in Russia {formatted_date3}"
ExportName_KurskRUClaims = f"Kursk Incursion Russian Claims in Russia {formatted_date3}"
ExportName_KurskUAAdvances = f"Kursk Incursion Ukrainian Advances in Russia {formatted_date3}"
ExportName_RUInfils = f"AssessedRussianInfiltrationAreasinUkraine{formatted_date2}"

ExportName_FCs = f"Fighting Circles {formatted_date2}"

# User input prompts for conditional exports
print("\n--- Export Configuration ---")

partisan_input = input("Export Partisan Warfare layer? (y/n): ").lower()
export_partisan = partisan_input.startswith('y') or partisan_input == 'yes'

russia_cot_input = input("Export CoT in Russia shapefiles? (y/n): ").lower()
export_russia_cot = russia_cot_input.startswith('y') or russia_cot_input == 'yes'

print("--- Configuration Complete ---\n")

def area_display(areas):
## This just rolls out the areas list that we have been appending the area to each time the export_and_zip function war run.
    print("\n\n") #put a bit of space between us and the zipping
    for area in areas:
        print(area)

def area_calc(feature_class, temp_layer):
    ## CALCULATE AREA OF TEMP LAYER ##

    # Field where the geodesic area will be stored - already exists in layers, just overwriting it
    field_name_km = "Area_KM"
    coordinate_system = arcpy.SpatialReference(102013)  # The Well-Known ID (WKID) for "Europe Albers Equal Area Conic"

    #Calculate the geodesic area for each feature in the temporary layer
    arcpy.CalculateGeometryAttributes_management(
        in_features = temp_layer, # whatever the output name calls the new layer
        geometry_property = [[field_name_km, "AREA_GEODESIC"]],  # Specify GEODESIC_AREA
        area_unit = "SQUARE_KILOMETERS",
        coordinate_system = coordinate_system # Specify CRS
    )       
    try:
        with arcpy.da.SearchCursor(temp_layer, [field_name_km]) as cursor:
            sum_area = sum(row[0] for row in cursor if row[0] is not None)
        areas.append(f"Area of {feature_class} is {sum_area} km²")
    except Exception as e:
        print(f"Error processing {output_name}: {e}")

areas = [] #make an empty list that we will append all areas to, and then display at the end.

# Helper function to export and zip the shapefile
def export_and_zip(feature_class, output_name):
    # Reload the feature class to ensure it's up-to-date
    arcpy.management.MakeFeatureLayer(feature_class, "temp_layer")

    # Export the feature class to a shapefile
    output_shapefile = os.path.join(daily_output_folder, f"{output_name}")
    arcpy.conversion.ExportFeatures("temp_layer", output_shapefile)

    # Wait briefly to ensure the file has been fully written
    time.sleep(2)

    ## CALCULATE AREA OF TEMP LAYER ##
    if areacalc:
        if feature_class in features_to_calculate_area:
            # Field where the geodesic area will be stored - already exists in layers, just overwriting it
            field_name = "Area_KM"
            coordinate_system = arcpy.SpatialReference(102013)  # The Well-Known ID (WKID) for "Europe Albers Equal Area Conic"
        
            #Calculate the geodesic area for each feature in the temporary layer
            arcpy.CalculateGeometryAttributes_management(
                in_features = output_name, # whatever the output name calls the new layer
                geometry_property = [[field_name, "AREA_GEODESIC"]],  # Specify GEODESIC_AREA
                area_unit = "SQUARE_KILOMETERS",
                coordinate_system = coordinate_system # Specify CRS
            )
                
            try:
                with arcpy.da.SearchCursor(output_name, [field_name]) as cursor:
                    sum_area = sum(row[0] for row in cursor if row[0] is not None)
                areas.append(f"Area of {output_name} is {sum_area} km2")
            except Exception as e:
                print(f"Error processing {output_name}: {e}")
    
    # Define the list of associated shapefile components (no extra .shp added)
    shapefile_components = [
        f"{output_shapefile}.shp",  # The main shapefile
        f"{output_shapefile}.shx",  # Shape index file
        f"{output_shapefile}.dbf",  # Attribute data file
        f"{output_shapefile}.prj",  # Projection file
        f"{output_shapefile}.sbn",  # Spatial index file
        f"{output_shapefile}.sbx",  # Spatial index file (alternate)
        f"{output_shapefile}.cpg",  # Character encoding file
        f"{output_shapefile}.shp.xml"  # Metadata XML
    ]

    # Check if all components exist before proceeding
    missing_files = [file for file in shapefile_components if not os.path.exists(file)]
    if missing_files:
        print(f"Error: Missing files for {output_name}: {', '.join(missing_files)}")
    else:
        # Create a zip file for the shapefile
        zip_filename = os.path.join(daily_output_folder, f"{output_name}.zip")

        # Create and write to the zip file
        with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for file in shapefile_components:
                zipf.write(file, os.path.basename(file))  # Add each file to the zip
	# Remove the original shapefiles (loose files) after zipping them
        for file in shapefile_components:
            try:
                os.remove(file)
            except Exception as e:
                print(f"Error deleting {file}: {e}")
        
        # Optionally, remove the temporary layer from ArcGIS
        try:
            arcpy.management.Delete("temp_layer")
            print(f"Removed temporary layer: {output_name}")
        except Exception as e:
            print(f"Error removing temporary layer: {e}")
        print(f"Exported and zipped {output_name}")

    # BEFORE REMOVING THE NEWLY EXPORTED SHAPEFILE LAYER, CALCULATE THE AREA ##
        
	  # Remove the newly exported shapefile layer from the "Working Map"
        map_view = None
        for map in aprx.listMaps():
            if map.name == "Working Map":
                map_view = map
                break

        if map_view is None:
            print("Error: 'Working Map' not found in the project.")
        else:
            # Now you can safely use map_view to remove the layer
            layers = map_view.listLayers()
            for layer in layers:
                if layer.name == output_name:
                    map_view.removeLayer(layer)  # Remove the layer from the map
                    print(f"Removed {output_name} from the map")
                    break

areas = [] #make an empty list that we will append all areas to, and then display at the end.

# Helper function to export and zip the shapefile
def export_and_zip(feature_class, output_name):
    # Reload the feature class to ensure it's up-to-date
    arcpy.management.MakeFeatureLayer(feature_class, "temp_layer")

    # Export the feature class to a shapefile
    output_shapefile = os.path.join(daily_output_folder, f"{output_name}")
    arcpy.conversion.ExportFeatures("temp_layer", output_shapefile)

    # Wait briefly to ensure the file has been fully written
    time.sleep(2)

    ## CALCULATE AREA OF TEMP LAYER ##
    if areacalc:
        if feature_class in features_to_calculate_area:
            # Field where the geodesic area will be stored - already exists in layers, just overwriting it
            field_name = "Area_KM"
            coordinate_system = arcpy.SpatialReference(102013)  # The Well-Known ID (WKID) for "Europe Albers Equal Area Conic"
        
            #Calculate the geodesic area for each feature in the temporary layer
            arcpy.CalculateGeometryAttributes_management(
                in_features = output_name, # whatever the output name calls the new layer
                geometry_property = [[field_name, "AREA_GEODESIC"]],  # Specify GEODESIC_AREA
                area_unit = "SQUARE_KILOMETERS",
                coordinate_system = coordinate_system # Specify CRS
            )
                
            try:
                with arcpy.da.SearchCursor(output_name, [field_name]) as cursor:
                    sum_area = sum(row[0] for row in cursor if row[0] is not None)
                areas.append(f"Area of {output_name} is {sum_area} km2")
            except Exception as e:
                print(f"Error processing {output_name}: {e}")
    
    # Define the list of associated shapefile components (no extra .shp added)
    shapefile_components = [
        f"{output_shapefile}.shp",  # The main shapefile
        f"{output_shapefile}.shx",  # Shape index file
        f"{output_shapefile}.dbf",  # Attribute data file
        f"{output_shapefile}.prj",  # Projection file
        f"{output_shapefile}.sbn",  # Spatial index file
        f"{output_shapefile}.sbx",  # Spatial index file (alternate)
        f"{output_shapefile}.cpg",  # Character encoding file
        f"{output_shapefile}.shp.xml"  # Metadata XML
    ]

    # Check if all components exist before proceeding
    missing_files = [file for file in shapefile_components if not os.path.exists(file)]
    if missing_files:
        print(f"Error: Missing files for {output_name}: {', '.join(missing_files)}")
    else:
        # Create a zip file for the shapefile
        zip_filename = os.path.join(daily_output_folder, f"{output_name}.zip")

        # Create and write to the zip file
        with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for file in shapefile_components:
                zipf.write(file, os.path.basename(file))  # Add each file to the zip
	# Remove the original shapefiles (loose files) after zipping them
        for file in shapefile_components:
            try:
                os.remove(file)
            except Exception as e:
                print(f"Error deleting {file}: {e}")
        
        # Optionally, remove the temporary layer from ArcGIS
        try:
            arcpy.management.Delete("temp_layer")
            print(f"Removed temporary layer: {output_name}")
        except Exception as e:
            print(f"Error removing temporary layer: {e}")
        print(f"Exported and zipped {output_name}")

    # BEFORE REMOVING THE NEWLY EXPORTED SHAPEFILE LAYER, CALCULATE THE AREA ##
        
	  # Remove the newly exported shapefile layer from the "Working Map"
        map_view = None
        for map in aprx.listMaps():
            if map.name == "Working Map":
                map_view = map
                break

        if map_view is None:
            print("Error: 'Working Map' not found in the project.")
        else:
            # Now you can safely use map_view to remove the layer
            layers = map_view.listLayers()
            for layer in layers:
                if layer.name == output_name:
                    map_view.removeLayer(layer)  # Remove the layer from the map
                    print(f"Removed {output_name} from the map")
                    break

def export_zip_points(feature_class, output_name):
    # Reload the feature class to ensure it's up-to-date
    arcpy.management.MakeFeatureLayer(feature_class, "temp_layer")

    # Export the feature class to a shapefile
    output_shapefile = os.path.join(daily_output_folder, f"{output_name}")
    arcpy.conversion.ExportFeatures("temp_layer", output_shapefile)

    # Wait briefly to ensure the file has been fully written
    time.sleep(2)
    
    # Define the list of associated shapefile components (no extra .shp added)
    shapefile_components = [
        f"{output_shapefile}.shp",  # The main shapefile
        f"{output_shapefile}.shx",  # Shape index file
        f"{output_shapefile}.dbf",  # Attribute data file
        f"{output_shapefile}.prj",  # Projection file
        f"{output_shapefile}.sbn",  # Spatial index file
        f"{output_shapefile}.sbx",  # Spatial index file (alternate)
        f"{output_shapefile}.cpg",  # Character encoding file
        f"{output_shapefile}.shp.xml"  # Metadata XML
    ]

    # Check if all components exist before proceeding
    missing_files = [file for file in shapefile_components if not os.path.exists(file)]
    if missing_files:
        print(f"Error: Missing files for {output_name}: {', '.join(missing_files)}")
    else:
        # Create a zip file for the shapefile
        zip_filename = os.path.join(daily_output_folder, f"{output_name}.zip")

        # Create and write to the zip file
        with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for file in shapefile_components:
                zipf.write(file, os.path.basename(file))  # Add each file to the zip
	# Remove the original shapefiles (loose files) after zipping them
        for file in shapefile_components:
            try:
                os.remove(file)
            except Exception as e:
                print(f"Error deleting {file}: {e}")
        
        # Optionally, remove the temporary layer from ArcGIS
        try:
            arcpy.management.Delete("temp_layer")
            print(f"Removed temporary layer: {output_name}")
        except Exception as e:
            print(f"Error removing temporary layer: {e}")
        print(f"Exported and zipped {output_name}")
        
	  # Remove the newly exported shapefile layer from the "Working Map"
        map_view = None
        for map in aprx.listMaps():
            if map.name == "Working Map":
                map_view = map
                break

        if map_view is None:
            print("Error: 'Working Map' not found in the project.")
        else:
            # Now you can safely use map_view to remove the layer
            layers = map_view.listLayers()
            for layer in layers:
                if layer.name == output_name:
                    map_view.removeLayer(layer)  # Remove the layer from the map
                    print(f"Removed {output_name} from the map")
                    break

# Always export these layers
export_and_zip(Assessed_Russian_controlled_Ukrainian_Territory, ExportName_CoT)
export_and_zip(Assessed_Russian_Advances_in_Ukraine, ExportName_RUAdvances)
export_and_zip(Claimed_Russian_Control_over_Ukrainian_Territory, ExportName_RUClaims)
export_and_zip(Claimed_Ukrainian_Counteroffensives, ExportName_UAFCO)
export_and_zip(Assessed_Russian_Infiltration_Areas_in_Ukraine, ExportName_RUInfils)

# Conditional export: Partisan Warfare
if export_partisan:
    export_and_zip(Reported_Ukrainian_Partisan_Warfare, ExportName_Partisan)
    print("✓ Partisan Warfare exported")
else:
    print("✗ Partisan Warfare skipped")

# Conditional export: Russia CoT layers
if export_russia_cot:
    export_and_zip(Russian_Advances_in_Russia, ExportName_KurskRUAdvances)
    export_and_zip(Claimed_Russian_Advances_in_Russia, ExportName_KurskRUClaims)
    export_and_zip(Ukrainian_Advances_in_Russia, ExportName_KurskUAAdvances)
    print("✓ Russia CoT layers exported")
else:
    print("✗ Russia CoT layers skipped")

# Always export Fighting Circles
export_zip_points(FCs, ExportName_FCs)

area_display(areas)

# Record the end time
end_time = time.perf_counter()
# Calculate the duration
duration = end_time - start_time
# Display the duration
print(f"Script execution time: {duration:.4f} seconds")
