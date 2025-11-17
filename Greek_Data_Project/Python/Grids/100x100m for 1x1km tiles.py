import arcpy
import os
import uuid

def create_100m_subgrid_for_1km_tile(fishnet_1km, target_tilename, output_workspace):
    """
    Creates 100x100m grid for a specific 1x1km tile identified by its TileName.
    Includes Northing and Easting fields with centroid coordinates.
    
    Parameters:
    fishnet_1km - Input 1km fishnet feature class
    target_tilename - The TileName of the specific 1km tile to process
    output_workspace - Geodatabase where output will be stored
    """
    print(f"Creating 100m subgrid for 1km tile with TileName '{target_tilename}'...")
    
    # Set output path with the target_tilename in the name (sanitize it for file naming)
    safe_tilename = target_tilename.replace(".", "_")
    output_100m = os.path.join(output_workspace, f"fishnet_100m_from_{safe_tilename}")
    
    # Create a unique name for temporary files
    temp_prefix = "temp_" + str(uuid.uuid4()).replace("-", "")[:8]
    temp_100m = os.path.join(output_workspace, f"{temp_prefix}_100m")
    
    # Delete existing outputs if they exist
    for output in [output_100m, temp_100m]:
        if arcpy.Exists(output):
            arcpy.Delete_management(output)
    
    # Create empty feature class
    spatial_ref = arcpy.Describe(fishnet_1km).spatialReference
    arcpy.CreateFeatureclass_management(output_workspace, os.path.basename(output_100m), "POLYGON", 
                                       spatial_reference=spatial_ref)
    
    # Add fields to output
    arcpy.AddField_management(output_100m, "TileName", "TEXT", field_length=30)
    arcpy.AddField_management(output_100m, "Easting", "DOUBLE", field_precision=15, field_scale=3)
    arcpy.AddField_management(output_100m, "Northing", "DOUBLE", field_precision=15, field_scale=3)
    
    # Check if TileName field exists in input
    tilename_field = None
    for field in arcpy.ListFields(fishnet_1km):
        if field.name.upper() == "TILENAME":
            tilename_field = field.name
            break
    
    if not tilename_field:
        print("ERROR: TileName field not found in the 1km fishnet. Please add this field first.")
        return None
    
    # Create a SQL query to select only the specific tile by TileName
    query = f"{tilename_field} = '{target_tilename}'"
    
    # Process the specific 1km tile
    found_target = False
    with arcpy.da.SearchCursor(fishnet_1km, ["OID@", "SHAPE@", tilename_field], query) as cursor:
        for row in cursor:
            tile_id, shape_1km, tile_name = row
                
            found_target = True
            print(f"Processing 1km tile with ID {tile_id} and TileName {tile_name}...")
            
            # Get the extent of the 1km tile
            extent_1km = shape_1km.extent
            
            # Delete temporary 100m fishnet if it exists
            if arcpy.Exists(temp_100m):
                arcpy.Delete_management(temp_100m)
            
            # Create 100m fishnet (10x10 cells within the 1km tile)
            print("Creating 100m fishnet...")
            arcpy.CreateFishnet_management(
                out_feature_class=temp_100m,
                origin_coord=f"{extent_1km.XMin} {extent_1km.YMin}",
                y_axis_coord=f"{extent_1km.XMin} {extent_1km.YMin + 0.1}",
                cell_width="100",
                cell_height="100",
                number_rows="10",
                number_columns="10",
                corner_coord=f"{extent_1km.XMax} {extent_1km.YMax}",
                labels="NO_LABELS",
                template=shape_1km,
                geometry_type="POLYGON"
            )
            
            # Process and name 100m tiles
            print("Processing and naming 100m tiles...")
            with arcpy.da.SearchCursor(temp_100m, ["OID@", "SHAPE@"]) as cursor_100m:
                for i, row_100m in enumerate(cursor_100m, 1):
                    oid_100m, shape_100m = row_100m
                    
                    # Calculate the position within the 1km grid
                    centroid = shape_100m.centroid
                    x_rel = (centroid.X - extent_1km.XMin) / (extent_1km.XMax - extent_1km.XMin)
                    y_rel = (centroid.Y - extent_1km.YMin) / (extent_1km.YMax - extent_1km.YMin)
                    
                    col_100m = int(x_rel * 10)
                    row_100m = int(y_rel * 10)
                    
                    # Calculate sequential ID (1-100)
                    col_100m = max(0, min(9, col_100m))
                    row_100m = max(0, min(9, row_100m))
                    tile_id_100m = row_100m * 10 + col_100m + 1
                    
                    # Format 100m tile name
                    tile_str_100m = f"{tile_id_100m:03d}"
                    tile_name_100m = f"{tile_name}.{tile_str_100m}"
                    
                    # Get centroid coordinates for Easting and Northing
                    easting = centroid.X
                    northing = centroid.Y
                    
                    # Insert the 100m tile into the output
                    with arcpy.da.InsertCursor(output_100m, ["SHAPE@", "TileName", "Easting", "Northing"]) as insert_cursor:
                        insert_cursor.insertRow([shape_100m, tile_name_100m, easting, northing])
            
            # Clean up temporary files
            if arcpy.Exists(temp_100m):
                arcpy.Delete_management(temp_100m)
    
    if not found_target:
        print(f"ERROR: Could not find 1km tile with TileName '{target_tilename}'")
        return None
    
    # Count features in output
    count = int(arcpy.GetCount_management(output_100m).getOutput(0))
    print(f"Created {count} 100m tiles for 1km tile '{target_tilename}'")
    print("Fields added: TileName, Easting (X), Northing (Y)")
    
    print(f"100m subgrid creation complete for 1km tile '{target_tilename}'.")
    return output_100m

def get_user_inputs():
    """
    Interactive function to get user inputs for 100m grid creation
    """
    # Get input 1km fishnet path
    while True:
        fishnet_1km = input("\nEnter the path to your 1km fishnet feature class: ")
        if arcpy.Exists(fishnet_1km):
            break
        else:
            print("Feature class does not exist. Please try again.")
    
    # Check if TileName field exists
    has_tilename = False
    for field in arcpy.ListFields(fishnet_1km):
        if field.name.upper() == "TILENAME":
            has_tilename = True
            break
    
    if not has_tilename:
        print("ERROR: The 1km fishnet does not have a TileName field.")
        return None
    
    # Get target TileName
    target_tilename = input("\nEnter the TileName of the 1km tile you want to process: ")
    
    # Get output workspace
    while True:
        output_workspace = input("Enter the path to your output geodatabase: ")
        if arcpy.Exists(output_workspace):
            break
        else:
            print("Geodatabase does not exist. Please try again.")
    
    return {
        'fishnet_1km': fishnet_1km,
        'target_tilename': target_tilename,
        'output_workspace': output_workspace
    }

# Example usage:
if __name__ == "__main__":
    print("=== 100m Subgrid Creator with Coordinates ===")
    print("This tool creates 100m subgrids for a specific 1km tile.")
    print("Includes TileName, Easting, and Northing fields.")
    print("This will create 100 features (10x10 grid).")
    
    # Option 1: Interactive mode
    use_interactive = input("Do you want to use interactive mode? (y/n, default=y): ")
    
    if use_interactive.lower() != 'n':
        # Get inputs from user
        inputs = get_user_inputs()
        if inputs:
            # Execute the function
            output_100m = create_100m_subgrid_for_1km_tile(
                inputs['fishnet_1km'], 
                inputs['target_tilename'], 
                inputs['output_workspace']
            )
    else:
        # Option 2: Direct parameters
        # Set your input feature class and output workspace
        fishnet_1km = r"C:\Users\Nate\Documents\ArcGIS\Projects\Grids\Grids.gdb\fishnet_1km"
        output_workspace = r"C:\Users\Nate\Documents\ArcGIS\Projects\Grids\Grids.gdb"
        
        # Specify which 1km tile to process by TileName
        target_tilename = "001.001.001"  # Change this to the TileName of the tile you want to process
        
        # Execute the function
        output_100m = create_100m_subgrid_for_1km_tile(
            fishnet_1km, target_tilename, output_workspace)