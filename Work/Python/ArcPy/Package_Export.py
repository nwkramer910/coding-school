import arcpy

p = arcpy.mp.ArcGISProject("CURRENT")

arcpy.management.PackageProject(
    in_project=p.filePath,
    output_file=r'C:\temp\Ukraine_CoT_v1.9.8.1.ppkx',
    sharing_internal='INTERNAL',  
    package_as_template='PROJECT_PACKAGE',
    include_toolboxes='NO_TOOLBOXES',
    include_history_items='NO_HISTORY_ITEMS'
)

print("Package created successfully!")

arcpy.management.SharePackage(
    in_package=r'C:\temp\Ukraine_CoT_v1.9.8.1.ppkx',
    username='',
    password='',
    summary='Ukraine CoT Project Package',
    tags='Ukraine, CoT',
    organization='TRUE'
)

print("Package uploaded to ArcGIS Online!")