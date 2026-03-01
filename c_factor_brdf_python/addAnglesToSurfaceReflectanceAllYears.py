import pandas as pd
import glob
import os
import click

@click.command()
@click.option("--ci",       "-i", type=int, help="The core's id",               default=1)
@click.option("--cn",       "-n", type=int, help="The number of cores",         default=1)
@click.option('--dir_path', "-s", type=str, help='Directory path for Landsat data files', default='/gpfs/sharedfs1/zhulab/Kexin/ProjectTACValidation/LandsatData/')
@click.option("--target",   "-t", type=str, help="The directory of working on", default='SurfaceReflectance')
def main(ci, cn, dir_path, target):
    """This script processes Landsat surface reflectance files to add angles from TOA reflectance files."""    
    print('#######################################################')
    print('Working on adding solar angles on the surface reflectance table')
    print('ci: {}'.format(ci))
    print('cn: {}'.format(cn))
    print('dir_path: {}'.format(dir_path))
    print('target: {}'.format(target))

    # create the output directory if it doesn't exist
    target_out = target + "Angles"
    output_dir = os.path.join(dir_path, target_out)
    os.makedirs(output_dir, exist_ok=True)

    # Access all surface reflectance files
    surface_paths = glob.glob(os.path.join(dir_path, target, 'Sample*_surface_reflectance_*53.csv'))
    # surface_paths = glob.glob(os.path.join(dir_path, target, 'random_samples_10000_surface_reflectance_*.csv'))
    if not surface_paths:
        raise FileNotFoundError("No surface reflectance files found in the specified directory.")
    # Sort the surface reflectance files
    surface_paths.sort()
    
    # Process each task
    tasks_range = range(ci - 1, len(surface_paths), cn)
    for i in tasks_range:
        surface_path = surface_paths[i]
        print("***********************************************************")
        print("Working for {}".format(surface_path))
        # Check if the output file exists
        output_filename = os.path.basename(surface_path).replace('.csv', '_angles.csv')
        output_path = os.path.join(output_dir, output_filename)
        if os.path.isfile(output_path):
            print(f"File {output_filename} already exists. Skipping...")
            continue
        
        # Read the surface reflectance file
        df_surface = pd.read_csv(surface_path, dtype={'plotid': int}) 
        # Generate the toa reflectance file name by replacing the 'surface' to 'toa' in the file name
        
        # Locate TOA file ending in _2000_2024.csv
        toa_name = os.path.basename(surface_path).replace('surface', 'toa').replace('.csv', '_2000_2024.csv')
        toa_path = os.path.join(dir_path, 'TOAReflectance', toa_name)

        if not os.path.exists(toa_path):
            print(f"TOA file not found for {surface_path}: {toa_path}")
            continue

        # Read and select angle columns
        df_toa = pd.read_csv(toa_path, dtype={'plotid': int})
        angle_cols = ['plotid', 'year', 'doy', 'saa', 'sza', 'vaa', 'vza']
        df_angles = df_toa[angle_cols]
        
        
        # toa_name = os.path.basename(surface_path).replace('surface', 'toa')
        # # add * to the end of the file name to match the TOA reflectance files
        # toa_name = toa_name.replace('.csv', '_*.csv')
        # # Access the TOA reflectance data (2000 - 2024) for this surface reflectance file
        # toa_paths = glob.glob(os.path.join(dir_path, 'TOAReflectance', toa_name))
        
        # # Check if the TOA reflectance files exist
        # if not toa_paths:
        #     raise FileNotFoundError(f"No TOA reflectance files found for {surface_path} in the specified directory.")
        # # Sort the TOA reflectance files
        # toa_paths.sort()
        
        # # Collect TOA files for years 2000–2024
        # all_toa_dfs = []
        # # Build TOA file prefix
        # toa_prefix = os.path.basename(surface_path).replace('surface', 'toa').replace('.csv', '')
        
        # for year in range(2000, 2025):
        #     toa_pattern = f"{toa_prefix}_{year}_{year}.csv"
        #     toa_path = os.path.join(dir_path, 'TOAReflectance', toa_pattern)
        #     if os.path.exists(toa_path):
        #         df_toa = pd.read_csv(toa_path, dtype={'plotid': int})
        #         angle_cols = ['plotid', 'year', 'doy', 'saa', 'sza', 'vaa', 'vza']
        #         df_angles = df_toa[angle_cols]
        #         all_toa_dfs.append(df_angles)
        #     else:
        #         print(f"Warning: TOA file for year {year} not found: {toa_pattern}")

        # # Combine all TOA angle data into one DataFrame
        # if not all_toa_dfs:
        #     print(f"No TOA files found for {surface_path}, skipping.")
        #     continue

        # df_all_angles = pd.concat(all_toa_dfs, ignore_index=True)

        # Merge surface and angle data
        df_merged = pd.merge(df_surface, df_angles, on=['plotid', 'year', 'doy'], how='left')

        # Save the merged dataframe to a new file
        df_merged.to_csv(output_path, index=False)
        print(f"File saved as {output_filename}")


if __name__ == "__main__":
    main()



