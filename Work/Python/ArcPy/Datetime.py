# Add a field datetime (type = date) to every feature class in the map

import arcpy

def add_datetime_field_to_active_map():
    aprx = arcpy.mp.ArcGISProject("CURRENT")
    m = aprx.activeMap

    for layer in m.listLayers():
        if layer.isFeatureLayer:
            try:
                fc_path = layer.dataSource
                field_names = [f.name for f in arcpy.ListFields(fc_path)]
                
                if "datetime" not in field_names:
                    arcpy.AddField_management(fc_path, "datetime", "DATE")
                    print(f"✅ Added 'datetime' field to: {layer.name}")
                else:
                    print(f"⚠️ Field 'datetime' already exists in: {layer.name}")
            except Exception as e:
                print(f"❌ Error processing {layer.name}: {e}")

# Run it
add_datetime_field_to_active_map()


# NEW CODE BLOCK #



# calculate the field datetime for every feature class in a map based on the name of the FC
# For example, an fc might be named ClaimedUkrainianCounteroffensivesMAR102025.shp
# The index [-10:-8] of that name will be "10", which is what we want the day to be. 
# Changed the fixed_year or fixed_month if you are using a different month/year
# to do it manually, the code it datetime.datetime(year,m,d)

from datetime import datetime

def update_datetime_field_day_only(fixed_year=2025, fixed_month=4):
    m = aprx.activeMap
    
    #for map_obj in aprx.listMaps():   use these if you want to do it for every map in your project
        #for layer in map_obj.listLayers():
    for layer in m.listLayers():    
        if layer.isFeatureLayer:
            try:
                fc_path = layer.dataSource
                fc_name = arcpy.Describe(fc_path).name
                print("fc name is " + str(fc_name))

                # Extract 2-digit day from characters [-10:-8] ([-13:-11] for CoT naming convention)
                try:
                    day_str = fc_name[-10:-8]
                    day = int(day_str)
                    target_date = datetime(fixed_year, fixed_month, day)
                except Exception as e:
                    print(f"Could not extract day from '{fc_name}': {e}")
                    continue

                # Update datetime field if it exists
                fields = [f.name for f in arcpy.ListFields(fc_path)]
                if "datetime" in fields:
                    with arcpy.da.UpdateCursor(fc_path, ["datetime"]) as cursor:
                        for row in cursor:
                            row[0] = target_date
                            cursor.updateRow(row)
                    print(f"Updated '{layer.name}' with date {target_date.strftime('%Y-%m-%d')}.")
                else:
                    print(f"Skipped {layer.name} — no 'datetime' field found.")
            except Exception as e:
                print(f"Error processing {layer.name}: {e}")

# Run the function
update_datetime_field_day_only()

