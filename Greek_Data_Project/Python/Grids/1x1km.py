import arcpy
import os
import uuid

def create_1km_subgrid_for_10km_tile(fishnet_10km, target_tilename, output_workspace):
    """
    Creates 1x1km grid for a specific 10x10km tile identified by its TileName.
    Includes Northing and Easting fields with centroid coordinates.
    
    Parameters:
    fishnet_10km - Input 10km fishnet feature class
    target_tilename - The TileName of the specific 10km tile to process
    output_workspace - Geodatabase where output will be stored
    """
    print(f"Creating 1km subgrid for 10km tile with TileName '{target_tilename}'...")
    
    # Set output path with the target_tilename in the name (sanitize it for file naming)
    safe_tilename = target_tilename.replace(".", "_")
    output_1km = os.path.join(output_workspace, f"fishnet_1km_from_{safe_tilename}")
    
    # Create a unique name for temporary files
    temp_prefix = "temp_" + str(uuid.uuid4()).replace("-", "")[:8]
    temp_1km = os.path.join(output_workspace, f"{temp_prefix}_1km")
    
    # Delete existing outputs if they exist
    for output in [output_1km, temp_1km]:
        if arcpy.Exists(output):
            arcpy.Delete_management(output)
    
    # Create empty feature class
    spatial_ref = arcpy.Describe(fishnet_10km).spatialReference
    arcpy.CreateFeatureclass_management(output_workspace, os.path.basename(output_1km), "POLYGON", 
                                      spatial_reference=spatial_ref)
    
    # Add fields to output
    arcpy.AddField_management(output_1km, "TileName", "TEXT", field_length=20)
    arcpy.AddField_management(output_1km, "Easting", "DOUBLE", field_precision=15, field_scale=3)
    arcpy.AddField_management(output_1km, "Northing", "DOUBLE", field_precision=15, field_scale=3)
    
    # Check if TileName field exists in input
    tilename_field = None
    for field in arcpy.ListFields(fishnet_10km):
        if field.name.upper() == "TILENAME":
            tilename_field = field.name
            break
    
    if not tilename_field:
        print("ERROR: TileName field not found in the 10km fishnet. Please add this field first.")
        return None
    
    # Create a SQL query to select only the specific tile by TileName
    query = f"{tilename_field} = '{target_tilename}'"
    
    # Process the specific 10km tile
    found_target = False
    with arcpy.da.SearchCursor(fishnet_10km, ["OID@", "SHAPE@", tilename_field], query) as cursor:
        for row in cursor:
            tile_id, shape_10km, tile_name = row
                
            found_target = True
            print(f"Processing 10km tile with ID {tile_id} and TileName {tile_name}...")
            
            # Get the extent of the 10km tile
            extent_10km = shape_10km.extent
            
            # Delete temporary 1km fishnet if it exists
            if arcpy.Exists(temp_1km):
                arcpy.Delete_management(temp_1km)
            
            # Create 1km fishnet (10x10 cells within the 10km tile)
            arcpy.CreateFishnet_management(
                out_feature_class=temp_1km,
                origin_coord=f"{extent_10km.XMin} {extent_10km.YMin}",
                y_axis_coord=f"{extent_10km.XMin} {extent_10km.YMin + 1}",
                cell_width="1000",
                cell_height="1000",
                number_rows="10",
                number_columns="10",
                corner_coord=f"{extent_10km.XMax} {extent_10km.YMax}",
                labels="NO_LABELS",
                template=shape_10km,
                geometry_type="POLYGON"
            )
            
            # Process and name 1km tiles
            with arcpy.da.SearchCursor(temp_1km, ["OID@", "SHAPE@"]) as cursor_1km:
                for i, row_1km in enumerate(cursor_1km, 1):
                    oid_1km, shape_1km = row_1km
                    
                    # Calculate the position within the 10km grid
                    centroid = shape_1km.centroid
                    x_rel = (centroid.X - extent_10km.XMin) / (extent_10km.XMax - extent_10km.XMin)
                    y_rel = (centroid.Y - extent_10km.YMin) / (extent_10km.YMax - extent_10km.YMin)
                    
                    col_1km = int(x_rel * 10)
                    row_1km = int(y_rel * 10)
                    
                    # Calculate sequential ID (1-100)
                    col_1km = max(0, min(9, col_1km))
                    row_1km = max(0, min(9, row_1km))
                    tile_id_1km = row_1km * 10 + col_1km + 1
                    
                    # Format 1km tile name
                    tile_str_1km = f"{tile_id_1km:03d}"
                    tile_name_1km = f"{tile_name}.{tile_str_1km}"
                    
                    # Get centroid coordinates for Easting and Northing
                    easting = centroid.X
                    northing = centroid.Y
                    
                    # Insert the 1km tile into the output with coordinates
                    with arcpy.da.InsertCursor(output_1km, ["SHAPE@", "TileName", "Easting", "Northing"]) as insert_cursor:
                        insert_cursor.insertRow([shape_1km, tile_name_1km, easting, northing])
            
            # Clean up temporary files
            if arcpy.Exists(temp_1km):
                arcpy.Delete_management(temp_1km)
    
    if not found_target:
        print(f"ERROR: Could not find 10km tile with TileName '{target_tilename}'")
        return None
    
    # Count features in output
    count = int(arcpy.GetCount_management(output_1km).getOutput(0))
    print(f"Created {count} 1km tiles for 10km tile '{target_tilename}'")
    print("Fields added: TileName, Easting (X), Northing (Y)")
    
    print(f"1km subgrid creation complete for 10km tile '{target_tilename}'.")
    return output_1km

def get_user_inputs():
    """
    Interactive function to get user inputs for 1km grid creation
    """
    # Get input 10km fishnet path
    while True:
        fishnet_10km = input("\nEnter the path to your 10km fishnet feature class: ")
        if arcpy.Exists(fishnet_10km):
            break
        else:
            print("Feature class does not exist. Please try again.")
    
    # Check if TileName field exists
    has_tilename = False
    for field in arcpy.ListFields(fishnet_10km):
        if field.name.upper() == "TILENAME":
            has_tilename = True
            break
    
    if not has_tilename:
        print("ERROR: The 10km fishnet does not have a TileName field.")
        return None
    
    # Get target TileName
    target_tilename = input("\nEnter the TileName of the 10km tile you want to process: ")
    
    # Get output workspace
    while True:
        output_workspace = input("Enter the path to your output geodatabase: ")
        if arcpy.Exists(output_workspace):
            break
        else:
            print("Geodatabase does not exist. Please try again.")
    
    return {
        'fishnet_10km': fishnet_10km,
        'target_tilename': target_tilename,
        'output_workspace': output_workspace
    }

# Example usage:
if __name__ == "__main__":
    print("=== 1km Subgrid Creator with Coordinates ===")
    print("This tool creates 1km subgrids for a specific 10km tile.")
    print("Includes TileName, Easting, and Northing fields.")
    
    # Option 1: Interactive mode
    use_interactive = input("Do you want to use interactive mode? (y/n, default=y): ")
    
    if use_interactive.lower() != 'n':
        # Get inputs from user
        inputs = get_user_inputs()
        if inputs:
            # Execute the function
            output_1km = create_1km_subgrid_for_10km_tile(
                inputs['fishnet_10km'], 
                inputs['target_tilename'], 
                inputs['output_workspace']
            )
    else:
        # Option 2: Direct parameters
        # Set your input feature class and output workspace
        fishnet_10km = r"C:\Users\Nate\Documents\ArcGIS\Projects\Grids\Grids.gdb\fishnet_10km"
        output_workspace = r"C:\Users\Nate\Documents\ArcGIS\Projects\Grids\Grids.gdb"
        
        # Specify which 10km tile to process by TileName
        target_tilename = "001.001"  # Change this to the TileName of the tile you want to process
        
        # Execute the function
        output_1km = create_1km_subgrid_for_10km_tile(
            fishnet_10km, target_tilename, output_workspace)