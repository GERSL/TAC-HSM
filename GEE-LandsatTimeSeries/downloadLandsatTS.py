# the location file is required by this script, like, this "/gpfs/sharedfs1/zhulab/Shi/ProjectGlobalGreening/Location/global_sinusoidal_samples_10k_distance_6k_sets/global_sinusoidal_samples_10k_distance_6k_set1.csv"


__author__ = 'yang'
# Updated on May 17, 2023 by Shi
# Support to download Landsat Collection 2 surface reflectance and surface temperature data at points, 2/5/2024

import os
import datetime
import time
import sys
from pathlib import Path
import click
import numpy as np
import pandas as pd
import geopandas as gpd
import ee

###################################################################################
ee.Initialize()  
###################################################################################

# when location is provided with a file path of .csv, the function will collect each of points in the table recorded.
# location = "/gpfs/sharedfs1/zhulab/Shi/ProjectGlobalGreening/Location/global_sinusoidal_samples_10k_distance_6k_sets/global_sinusoidal_samples_10k_distance_6k_set1.csv"
# /gpfs/sharedfs1/zhulab/Shi/ProjectGlobalGreening/LandsatData/TOAReflectance2023/global_sinusoidal_samples_10k_distance_6k_set1_toa_reflectance_040001_040100.csv
# when location is provided with lat,long, the function will collect the point of the long,lat
# location = "-79.0942, 35.9782"

# world_sinusoidal
# 'PROJCS["World_Sinusoidal",GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137.0,298.257223563]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Sinusoidal"],PARAMETER["False_Easting",0.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",0.0],UNIT["Meter",1.0]]'

# coordinates

@click.command()
@click.option("--ci",          "-i", default=1, type=int, help="The core's id")
@click.option("--cn",          "-n", default=1, type=int, help="The number of cores")
@click.option("--location",    "-l", default="./Location/Sample_multipleInPlot_forest_cover.csv", type=str, help="The filepath of the pixel's location")
@click.option("--destination", "-d", default="./LandsatData/TOAReflectance", type=str, help="The desttination of the downloaded data")
@click.option("--number",      "-n", default=100, type=int, help="The number of the points per file")
@click.option("--datalevel",   "-e", default='toa', type=str, help="Level of Landsat prodcut, such as toa, sr")
@click.option("--startyear",   "-s", default=2000, type=int, help="Year of starting")
@click.option("--endyear",     "-z", default=2024, type=int, help="Year of ending")
@click.option("--proj",        "-p", default='', type=str, help="Projection of the points; world_sinusoidal or coordinates")
@click.option("--oncesave",    "-o", default=1, type=int, help="Only one-time saving after all the data were downloaded, to save IO resource, value can be 0 or 1")
def main(ci, cn, location, destination, number, datalevel, startyear, endyear, proj, oncesave):
    # msg of core
    print('\n*****************************************************************************************************')
    if datalevel == 'sr':
        print('* Downloading Landsat Collection 2 surface reflectance and surface temperature data at points')
    else:
        print('* Downloading Landsat Collection 2 TOA reflectance data at points')
    
    print('* Core: {:04d}/{:04d}\n'.format(ci, cn))

    # setup global variables
    global NUMBER_PER_FILE
    global CORE_ID
    global CORE_NUMBER
    global ONCE_SAVE
    global DATA_LEVEL
    global PROJCS
   

    NUMBER_PER_FILE = number
    CORE_ID = ci
    CORE_NUMBER = cn
    ONCE_SAVE = oncesave > 0
    DATA_LEVEL = datalevel
    if proj == 'world_sinusoidal':
        PROJCS = 'PROJCS["World_Sinusoidal",GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137.0,298.257223563]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Sinusoidal"],PARAMETER["False_Easting",0.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",0.0],UNIT["Meter",1.0]]'
    else:
        PROJCS = ''

    location=location.strip().split(',')
    
   
    if len(location) == 2:
        location = [float(location[0]), float(location[1])]
        processPlot(location, destination, startyear, endyear)
    elif len(location) == 1:
        location = location[0]
        if Path(location).suffix == '.csv':
            # start up processing downloading
            processPlots(location, destination, startyear, endyear)


def applyScaleFactors(image):
    # see details from https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LC09_C02_T1_L2#bands
    opticalBands = image.select('SR_B.').multiply(0.0000275).add(-0.2)
    thermalBands = image.select('ST_B.*').multiply(0.00341802).add(149.0)
    return (image.addBands(opticalBands, None, True)
            .addBands(thermalBands, None, True))

def applyScaleFactorsTOA(image):
  SAABand = image.select('SAA').multiply(0.01)
  SZABand = image.select('SZA').multiply(0.01)
  VAABand = image.select('VAA').multiply(0.01)
  VZABand = image.select('VZA').multiply(0.01)
  return (image.addBands(SAABand, None, True)
            .addBands(SZABand, None, True)
            .addBands(VAABand, None, True)
            .addBands(VZABand, None, True))


def fillMask(image):
  qa = image.select('QA_PIXEL')
  fill = qa.bitwiseAnd(1) #Fill
  return fill.Not().rename('fill')


def generateCollection():
  def stack_renamer_l4_7(img):
    band_list = ['SR_B1','SR_B2','SR_B3','SR_B4','SR_B5','SR_B7','ST_B6','QA_PIXEL']
    name_list = ['BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'SWIR2', 'TEMP','QA_PIXEL']
    mask = fillMask(img)
    bands = applyScaleFactors(img)
    return bands.updateMask(mask).select(band_list, name_list)

  def stack_renamer_l8(img):
    band_list = ['SR_B2', 'SR_B3', 'SR_B4', 'SR_B5', 'SR_B6', 'SR_B7', 'ST_B10','QA_PIXEL']
    name_list = ['BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'SWIR2', 'TEMP','QA_PIXEL']
    mask = fillMask(img)
    bands = applyScaleFactors(img)
    return bands.updateMask(mask).select(band_list, name_list)

  # Get collections
  l9_filtered = (ee.ImageCollection('LANDSAT/LC09/C02/T1_L2')
                 .map(stack_renamer_l8))

  l9_filtered2 = (ee.ImageCollection('LANDSAT/LC09/C02/T2_L2')
                 .map(stack_renamer_l8))

  l8_filtered = (ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')
                 .map(stack_renamer_l8))

  l8_filtered2 = (ee.ImageCollection('LANDSAT/LC08/C02/T2_L2')
                 .map(stack_renamer_l8))


  l7_filtered = (ee.ImageCollection('LANDSAT/LE07/C02/T1_L2')
                 .map(stack_renamer_l4_7))

  l5_filtered = (ee.ImageCollection('LANDSAT/LT05/C02/T1_L2')
                 .map(stack_renamer_l4_7))

  l4_filtered = (ee.ImageCollection('LANDSAT/LT04/C02/T1_L2')
                 .map(stack_renamer_l4_7))


  merged_collections = (ee.ImageCollection(l5_filtered)
      .merge(l7_filtered)
      .merge(l8_filtered)
      .merge(l9_filtered)
      .merge(l4_filtered)
      .merge(l8_filtered2)
      .merge(l9_filtered2))

  return merged_collections


def generateCollectionTOAReflectance():
  def stack_renamer_l4_5_toa(img):
    band_list = ['B1','B2','B3','B4','B5','B7','B6', 'SAA', 'SZA', 'VAA', 'VZA', 'QA_PIXEL']
    name_list = ['BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'SWIR2', 'TEMP', 'SAA', 'SZA', 'VAA', 'VZA', 'QA_PIXEL']
    mask = fillMask(img)
    bands = applyScaleFactorsTOA(img)
    return bands.updateMask(mask).select(band_list, name_list)
  def stack_renamer_l7_toa(img):
    band_list = ['B1','B2','B3','B4','B5','B7','B6_VCID_1', 'SAA', 'SZA', 'VAA', 'VZA', 'QA_PIXEL']
    name_list = ['BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'SWIR2', 'TEMP', 'SAA', 'SZA', 'VAA', 'VZA', 'QA_PIXEL']
    mask = fillMask(img)
    bands = applyScaleFactorsTOA(img)
    return bands.updateMask(mask).select(band_list, name_list)
  def stack_renamer_l8_9_toa(img):
    band_list = ['B2', 'B3', 'B4', 'B5', 'B6', 'B7', 'B10', 'SAA', 'SZA', 'VAA', 'VZA', 'QA_PIXEL']
    name_list = ['BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'SWIR2', 'TEMP', 'SAA', 'SZA', 'VAA', 'VZA', 'QA_PIXEL']
    mask = fillMask(img)
    bands = applyScaleFactorsTOA(img)
    return bands.updateMask(mask).select(band_list, name_list)

  # Get collections
  l9_filtered = (ee.ImageCollection('LANDSAT/LC09/C02/T1_TOA')
                 .map(stack_renamer_l8_9_toa))

  l9_filtered2 = (ee.ImageCollection('LANDSAT/LC09/C02/T2_TOA')
                 .map(stack_renamer_l8_9_toa))

  l8_filtered = (ee.ImageCollection('LANDSAT/LC08/C02/T1_TOA')
                 .map(stack_renamer_l8_9_toa))

  l8_filtered2 = (ee.ImageCollection('LANDSAT/LC08/C02/T2_TOA')
                 .map(stack_renamer_l8_9_toa))


  l7_filtered = (ee.ImageCollection('LANDSAT/LE07/C02/T1_TOA')
                 .map(stack_renamer_l7_toa))

  l5_filtered = (ee.ImageCollection('LANDSAT/LT05/C02/T1_TOA')
                 .map(stack_renamer_l4_5_toa))

  l4_filtered = (ee.ImageCollection('LANDSAT/LT04/C02/T1_TOA')
                 .map(stack_renamer_l4_5_toa))


  merged_collections = (ee.ImageCollection(l5_filtered)
      .merge(l7_filtered)
      .merge(l8_filtered)
      .merge(l9_filtered)
      .merge(l4_filtered)
      .merge(l8_filtered2)
      .merge(l9_filtered2))

  return merged_collections


###################################################################################

def extractSpectral(point, plotid, start_year, end_year):
    success = False
    tries = 1
    idle = 1
    max_tries = 20

    target_bands_sr  = ['BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'SWIR2', 'TEMP', 'QA_PIXEL']
    target_bands_toa = ['BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'SWIR2', 'TEMP', 'SAA', 'SZA', 'VAA', 'VZA', 'QA_PIXEL']
    

    while not success:
        try:
            results = []
            if DATA_LEVEL == 'sr':
                target_bands = target_bands_sr
                refls = ee.ImageCollection(generateCollection().filterBounds(point).filter(ee.Filter.calendarRange(start_year, end_year, 'year')))
            if DATA_LEVEL == 'toa':
                target_bands = target_bands_toa
                refls = ee.ImageCollection(generateCollectionTOAReflectance().filterBounds(point).filter(ee.Filter.calendarRange(start_year, end_year, 'year')))

            if refls.size().getInfo() == 0:
                return results


            if tries <= max_tries - 2: # try twice
                crs = ee.Image(refls.first()).select('SWIR1').projection().crs() # previous version
                refls = refls.select(target_bands) \
                    .getRegion(geometry=point.transform(crs, 1), scale=30, crs=crs).getInfo()  # If unspecified, defaults to EPSG:4326.
            else:
                # note: some polar images do not have crs, and when we use those images as reference of the projection, it will be failed.
                # to address this issue, we moved back one year to find the crs till it is found.
                # e.g., LC09_L2SP_023246_20230823_20230825_02_T2
                # last time, we use this code to get the crs, but # not sure how this will work on
                crs = ee.Image(refls.first()).select('SWIR1').projection().wkt()
                refls = refls.select(target_bands) \
                    .getRegion(geometry=point.transform(crs, 1), scale=30, crs=crs).getInfo()  # If unspecified, defaults to EPSG:4326.
                   
                print(f'\t\tID {plotid}: wkt() was used instead of crs() to get the projection.')
                #refls = refls.select(target_bands) \
                #    .getRegion(geometry=point, scale=30).getInfo()  # If unspecified, defaults to EPSG:4326.

            # the first elements is always the metadata
            if len(refls) > 1:
                for refl in refls[1:]:
                    iids = refl[0].split('_')
                    sensor = iids[-3]
                    ppprrr = iids[-2]
                    imgyear = iids[-1][0:4]
                    imgmonth = iids[-1][4:6]
                    imgday = iids[-1][6:]
                    yod = datetime.date(int(imgyear), int(imgmonth), int(imgday)).timetuple().tm_yday
                    spectrals = refl[4:]
                    if not np.isin(None, spectrals): # exclude any observations with None
                        this_row = [sensor, str(plotid), ppprrr, imgyear, str(yod)] + list(map(str, spectrals))
                        results.append(','.join(this_row))

            success = True
            # return results
        except Exception as e:
            success = False
            tries += 1
            idle += 1

            if idle > 5:
                idle = 1
            time.sleep(idle)

            if tries > max_tries:
                # force to exist
                success = True
                print(e)
                sys.exit(1)
            print(f'\t\t{plotid} exception: ', e)

    return results

def writelines2csv(file_handler, line_str):
    file_handler.writelines('\n'.join(line_str))
    file_handler.writelines('\n')
    file_handler.flush()

def extractPoint(plot_id, x, y, file_handler, start_year = 1982, end_year = 2050, save = True):
    results = []
    x = float(x)
    y = float(y)
   
    if PROJCS == '': # no projection and Construct a point from coordinates.
        pixel = ee.Geometry.Point([x, y])
    else:
        pixel = ee.Geometry.Point([x, y], ee.Projection(PROJCS))
   
    results += extractSpectral(pixel, plot_id, start_year, end_year)
    # exclude None in the results
    if len(results) > 0:
        if save:
            writelines2csv(file_handler, results)
   
    return results


def processPlot(plot_location, out_dir, start_year, end_year):
    # define the field for sr and toa
    if DATA_LEVEL == 'sr':
        datalevelname = 'surface_reflectance'
        fields = ['sensor,plotid,ppprrr,year,doy,blue,green,red,nir,swir1,swir2,temp,qa_pixel']
    if DATA_LEVEL == 'toa':
        datalevelname = 'toa_reflectance'
        fields = ['sensor,plotid,ppprrr,year,doy,blue,green,red,nir,swir1,swir2,temp,saa, sza,vaa,vza,qa_pixel']
        # fields = ['sensor,plotid,ppprrr,year,doy,saa,sza,vaa,vza,qa_pixel'] # ks 20250723: only save the angles and qa_pixel, to save space
   
    # create the outputing directory
    Path(out_dir).mkdir(parents=True, exist_ok=True)

    plot_location = list(map(str, plot_location))
    spectral_file = os.path.join(out_dir, 'lon_'+str(plot_location[0]) + '_lat_' + str(plot_location[1]) + '_'+ datalevelname + '.csv')
    if os.path.isfile(spectral_file):
        print('Exist {}'.format(spectral_file))
    else:
        # delete the .part
        if os.path.isfile(spectral_file+ '.part'):
            os.remove(spectral_file+ '.part')
       
        start = time.time()
        with open(spectral_file+ '.part', 'a') as oufh:
            # write the tiles
            writelines2csv(oufh, fields)
            # process each of plots
            print('Processing the point lon = {}/ lat = {} with {}'.format(str(plot_location[0]), str(plot_location[1]), DATA_LEVEL.lower()))
            extractPoint(0, plot_location[0], plot_location[1], oufh, start_year, end_year)
       

        # rename the file as a regular filename and display the msg
        os.rename(spectral_file+ '.part', spectral_file) # revise as the regular filename, that does not have .part
        print("Finish downloading {} with {:0.2f} mins\n".format(spectral_file, (time.time() - start)/60))

   
def processPlots(plot_file, out_dir, start_year, end_year):
   
    # define the field for sr and toa
    if DATA_LEVEL == 'sr':
        datalevelname = 'surface_reflectance'
        fields = ['sensor,plotid,ppprrr,year,doy,blue,green,red,nir,swir1,swir2,temp,qa_pixel']
    if DATA_LEVEL == 'toa':
        datalevelname = 'toa_reflectance'
        fields = ['sensor,plotid,ppprrr,year,doy,blue,green,red,nir,swir1,swir2,temp,saa,sza,vaa,vza,qa_pixel']
        # fields = ['sensor,plotid,ppprrr,year,doy,saa,sza,vaa,vza,qa_pixel']
   
    # read the sample list
    if Path(plot_file).suffix == '.shp':
        all_samples = gpd.read_file(plot_file)
    if Path(plot_file).suffix == '.csv':
        all_samples = pd.read_csv(plot_file)
    all_samples = all_samples.sort_values(by=["sampleID"], ascending=True)

    # define the filenames, with list, according to number per file
    basefilename = Path(plot_file).stem
    part_files = ["{}_{}_{:06d}_{:06d}".format(basefilename, datalevelname, istart+1, min(istart+NUMBER_PER_FILE, len(all_samples.index)) ) for istart in range(0, len(all_samples.index), NUMBER_PER_FILE)]

    # create the outputing directory
    Path(out_dir).mkdir(parents=True, exist_ok=True)

    # Process each task
    for ipart in range(CORE_ID - 1, len(part_files), CORE_NUMBER):

        part_file = part_files[ipart]+'_'+str(start_year)+'_'+str(end_year)
        start = time.time()
        spectral_file = os.path.join(out_dir, part_file + '.csv')

        if os.path.isfile(spectral_file):
            print('Exist {}'.format(spectral_file))
        else:
            # delete the .part
            if os.path.isfile(spectral_file+ '.part'):
                os.remove(spectral_file+ '.part')
           
            # start up download new one
            # sample_indexs = part_file.split('_')[-2:]
            # ks 20250723: revise the sample_indexs to be the sampleID, not start_year
            sample_indexs = part_file.split('_')[-4:-2]
            all_samples_part = all_samples[int(sample_indexs[0])-1: int(sample_indexs[1])]

            if not ONCE_SAVE:
                with open(spectral_file+ '.part', 'a') as oufh:
                    # write the tiles
                    writelines2csv(oufh, fields)
                    # process each of plots
                    for index, sample_row in all_samples_part.iterrows():
                        print('Processing plot id {0:09d}'.format(sample_row['plotid']))
                        extractPoint(sample_row['plotid'], sample_row['X'], sample_row['Y'], oufh, start_year, end_year)
            else:
                # process each of plots
                plot_lts_all = fields.copy()
                for index, sample_row in all_samples_part.iterrows():
                    print('Processing sample id {0:09d}'.format(int(sample_row['sampleID'])))
                    # if int(sample_row['plotid']) != 40585: continue
                    # plot_lts = extractPoint(sample_row['plotid'], sample_row['X'], sample_row['Y'], '', start_year, end_year, save = False)
                    plot_lts = extractPoint(sample_row['sampleID'], sample_row['sampleLon'], sample_row['sampleLat'], '', start_year, end_year, save = False)
                    if len(plot_lts) > 0:
                        plot_lts_all.extend(plot_lts)
               
                # save all the data downloaded at the last to save I/O resource
                with open(spectral_file+ '.part', 'a') as oufh:
                   writelines2csv(oufh, plot_lts_all)


            # rename the file as a regular filename and display the msg
            os.rename(spectral_file+ '.part', spectral_file) # revise as the regular filename, that does not have .part
            print("Finish downloading {} with {:0.2f} mins\n".format(spectral_file, (time.time() - start)/60))


# Main function
if __name__ == "__main__":
    main()
