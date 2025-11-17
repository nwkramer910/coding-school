import arcpy
import os
import uuid

def create_1km_subgrid_for_100km_tile(fishnet_100km, target_tilename, output_workspace):
    """
    Creates 1x1km grid for a specific 100x100km tile identified by its TileName.
    Includes Northing and Easting fields with centroid coordinates.
    """
    print(f"Creating 1km subgrid for 100km tile with TileName '{target_tilename}'...")
    
    # Set output path with the target_tilename in the name (sanitize it for file naming)
    safe_tilename = str(target_tilename).replace(".", "_")
    output_1km = os.path.join(output_workspace, f"fishnet_1km_from_100km_{safe_tilename}")
    
    # Create unique name for temporary file
    temp_prefix = "temp_" + str(uuid.uuid4()).replace("-", "")[:8]
    temp_1km = os.path.join(output_workspace, f"{temp_prefix}_1km")
    
    # Delete existing outputs if they exist
    for output in [output_1km, temp_1km]:
        if arcpy.Exists(output):
            arcpy.Delete_management(output)
    
    # Create empty feature class for 1km grid
    spatial_ref = arcpy.Describe(fishnet_100km).spatialReference
    arcpy.CreateFeatureclass_management(output_workspace, os.path.basename(output_1km), "POLYGON", 
                                       spatial_reference=spatial_ref)
    
    # Add fields to output
    arcpy.AddField_management(output_1km, "TileName", "TEXT", field_length=25)
    arcpy.AddField_management(output_1km, "Easting", "DOUBLE", field_precision=15, field_scale=3)
    arcpy.AddField_management(output_1km, "Northing", "DOUBLE", field_precision=15, field_scale=3)
    
    # Create SQL query for numeric TileName field
    query = f"TileName = {target_tilename}"
    print(f"Using query: {query}")
    
    # Process the specific 100km tile
    found_target = False
    
    with arcpy.da.SearchCursor(fishnet_100km, ["OID@", "SHAPE@", "TileName"], query) as cursor:
        for row in cursor:
            tile_id, shape_100km, tile_name = row
                
            found_target = True
            print(f"Processing 100km tile with ID {tile_id} and TileName {tile_name}...")
            
            # Get the extent of the 100km tile
            extent_100km = shape_100km.extent
            
            # Create 1km fishnet directly (100x100 cells within the 100km tile)
            if arcpy.Exists(temp_1km):
                arcpy.Delete_management(temp_1km)
                
            print("Creating 1km fishnet (10,000 tiles)...")
            arcpy.CreateFishnet_management(
                out_feature_class=temp_1km,
                origin_coord=f"{extent_100km.XMin} {extent_100km.YMin}",
                y_axis_coord=f"{extent_100km.XMin} {extent_100km.YMin + 1}",
                cell_width="1000",
                cell_height="1000",
                number_rows="100",
                number_columns="100",
                corner_coord=f"{extent_100km.XMax} {extent_100km.YMax}",
                labels="NO_LABELS",
                template=shape_100km,
                geometry_type="POLYGON"
            )
            
            print("Processing and naming 1km tiles...")
            # Process and name 1km tiles
            tiles_created = 0
            with arcpy.da.SearchCursor(temp_1km, ["OID@", "SHAPE@"]) as cursor_1km:
                for row_1km in cursor_1km:
                    oid_1km, shape_1km = row_1km
                    
                    # Get centroid coordinates
                    centroid = shape_1km.centroid
                    easting = centroid.X
                    northing = centroid.Y
                    
                    # Calculate which 10km tile this 1km tile belongs to
                    x_rel_100km = (easting - extent_100km.XMin) / (extent_100km.XMax - extent_100km.XMin)
                    y_rel_100km = (northing - extent_100km.YMin) / (extent_100km.YMax - extent_100km.YMin)
                    
                    # Determine 10km tile position (0-9 in each direction)
                    col_10km = int(x_rel_100km * 10)
                    row_10km = int(y_rel_100km * 10)
                    
                    # Handle edge cases
                    col_10km = max(0, min(9, col_10km))
                    row_10km = max(0, min(9, row_10km))
                    
                    # Calculate 10km tile ID (1-100)
                    tile_id_10km = row_10km * 10 + col_10km + 1
                    
                    # Calculate position within the 10km tile
                    # Get the extent of the theoretical 10km tile
                    km10_tile_xmin = extent_100km.XMin + col_10km * 10000
                    km10_tile_ymin = extent_100km.YMin + row_10km * 10000
                    
                    # Calculate relative position within this 10km tile
                    x_rel_10km = (easting - km10_tile_xmin) / 10000
                    y_rel_10km = (northing - km10_tile_ymin) / 10000
                    
                    # Determine 1km tile position within 10km tile (0-9 in each direction)
                    col_1km = int(x_rel_10km * 10)
                    row_1km = int(y_rel_10km * 10)
                    
                    # Handle edge cases
                    col_1km = max(0, min(9, col_1km))
                    row_1km = max(0, min(9, row_1km))
                    
                    # Calculate 1km tile ID within 10km tile (1-100)
                    tile_id_1km = row_1km * 10 + col_1km + 1
                    
                    # Format tile names
                    tile_str_10km = f"{tile_id_10km:03d}"
                    tile_str_1km = f"{tile_id_1km:03d}"
                    tile_name_1km = f"{int(tile_name):03d}.{tile_str_10km}.{tile_str_1km}"
                    
                    # Insert the 1km tile into the output with coordinates
                    with arcpy.da.InsertCursor(output_1km, ["SHAPE@", "TileName", "Easting", "Northing"]) as insert_cursor:
                        insert_cursor.insertRow([shape_1km, tile_name_1km, easting, northing])
                        tiles_created += 1
                    
                    # Progress reporting
                    if tiles_created % 1000 == 0:
                        print(f"Created {tiles_created} tiles so far...")
            
            # Clean up temporary files
            if arcpy.Exists(temp_1km):
                arcpy.Delete_management(temp_1km)
    
    if not found_target:
        print(f"ERROR: Could not find 100km tile with TileName '{target_tilename}'")
        return None
    
    # Count features in output
    count = int(arcpy.GetCount_management(output_1km).getOutput(0))
    print(f"Created {count} 1km tiles for 100km tile '{target_tilename}'")
    print("Fields added: TileName, Easting (X), Northing (Y)")
    
    print(f"1km subgrid creation complete for 100km tile '{target_tilename}'.")
    return output_1km

# Direct execution - no if __name__ check
print("=== 1km Subgrid Creator from 100km Tile ===")

# Set your parameters here
fishnet_100km = r"C:\Users\Nate\Documents\ArcGIS\Projects\Grids\Grids.gdb\grid_100x100km"  # UPDATE THIS PATH
target_tilename = 1  # Change this to the tile number you want (1, 2, 3, etc.)
output_workspace = r"C:\Users\Nate\Documents\ArcGIS\Projects\Grids\Grids.gdb"  # UPDATE THIS PATH

# Execute the function
output_1km = create_1km_subgrid_for_100km_tile(fishnet_100km, target_tilename, output_workspace)