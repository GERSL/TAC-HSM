############################################################
Data Access: /home/kes20012/GEE-LandsatTimeSeries
    1. downloadLandsatTS.ipynb
       Generate token to access GEE.
    2. downloadLandsatTS.py
       Download Landsat time series (toa and sr) from GEE for given lat/lon.

############################################################
Preprocess - BRDF correction: /home/kes20012/c_factor_brdf_python
    1. addAnglesToSurfaceReflectance.py
    2. normalizeBRDF.py

############################################################
Preprocess - Sensor-to-sensor harmonization: ./L57_L89_Harmonization
    1. prepareHarmonizeL78.m
       Extract Landsat time series for each sample pixel from the csv file (each csv file contains 100 pixels).  
    2. runTIFSinglePixel.m
       Obtain L57 and L89 harmonization coefficients using TIF
    3. plotL57L89Scatter_densityPlot.m
       Visulize the before- and after-harmonization data
        
############################################################
Analysis: ./RFmodel
    1. runTAC_Landsat_allSample.m
       Run TAC for all forest sample points from the 10,000 random sample.
    2. preparePredictorVariables.m
       Extract climate variables and forest cover as predictor variables for random forest regression.
    3. prepareResponseVariable.m
       Extract TACs as the response variable for random forest regression.
    4. trainRFmodel.m
       Build random forest models 
    5. testRFmodel.m (optional)
       Run random forest models to obtain predicted TACs

    6. runTAC_Landsat_FieldSample.m
       Run TAC for field sample points (53).
    7. preparePredictorVariableFieldSample.m
       Extract climate variables and forest cover for the field samples.
    8. prepareResponseVariableFieldSample.m
       Extract TACs as the response variable.
    9. extractEnhancedTAC.m
       Obtain enhanced TAC for field samples by substracting TAC|Xac.

Export Outcoms: ./HSM_TAC_Correlation
    1. 
        
    
       
       
        
