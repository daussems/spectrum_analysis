pro ps_plot_Kyri,ver ; <-- 0: IDL plot, 1: PS plot 

;   Created by: 
;     D. Aussems: 25-03-2013
;   Modified by:
 ;    D. Aussems: 01-12-2014

;   This program calulates the electron temperature (T_e) and electron density (n_e) from the intensity spectrum of a tungsten plasma. 
;   See list below for used transition lines. The intensity of each line (integration) is calculated. The values are used to make a 
;   Boltzmann plot, which is linearly fitted. From the slope, and intersect T_e, and n_e are calculated.  
;   
;   Pixel   Wavelength  Lower E.   Upper E.  g   A         Up trans.   Low trans.    Rel. Int.
;   [-]     [nm]        [eV]       [eV]      [-] [s^-1]    [-]         [-]           [au]
;   114     407.4358    0.36591    3.40809   7   1.00E+07  5d5(6S)6s   5d5(6S)6p     600
;  

   ;  Open common variables:
    @common_intens_data_test
   ; @common_intensid
    
    
;******************] INITIALIZING PARAMETERS [*******************
    
    ; set up directory
    home_path = '/home/emc/aussems/My Documents/Experiments/spectrum_analysis2/' 
    cd, home_path 
    file_light_sphere = home_path+'light_sphere.dat'
    calibration_file = home_path + '2014-11-05 12_46_59 Magnum_Calibration_Middle_06156.1_5000ms_Window_1.9106E-5A 61.spe'
    calibration_background_file = home_path + '2014-11-05 12_49_05 Magnum_BCK_Middle_06156.1_5000ms_Window 62.spe'
    
    ; information on lines
    lambda = [397.007,388.905,383.538,379.790,377.063,375.015,373.435,372.194,371.197]    
    gi = [72,98,128,162,200,242,288,338,392]
    Ai = [9.73E+05,4.39E+05,2.22E+05,1.22E+05,7.12E+04,4.40E+04,2.83E+04,1.89E+04,1.30E+04]
    energy = [13.22,13.32,13.39,13.43,13.46,13.49,13.51,13.52,13.53]
    
    ; over-write information form spe_button
    fname = home_path + '2014-10-31 13_30_04 Magnum_D_10000ms 17.spe'
    background_file = home_path + '2014-10-31 13_29_36 Magnum_D_BKG_10000ms 16.spe'
    peak    = [1469,1174,992,872,788,727,680,645,616]
    
    ; spectral information
    int_time_calibration = 5000e-3 ; [s]
    int_time_experiment = 500e-3 ; [s] 
    L = 1.6e-2 ;[m] plasma depth
    
    ; calbration information
    power_integrating_sphere_manufacture = 3.452e-5  ; [A]
    power_integrating_sphere_calibration = 1.9106e-5  ; [A]
    factor_power = power_integrating_sphere_manufacture / power_integrating_sphere_calibration   
    grating_setting = '06156.1'
    pxlwv_A = 0.0283 ; wavelength = pxlwv_A * #pixel + pxlwv_B  at grating_setting '06156.1'
    pxlwv_B = 354.65
    pixel_per_fiber = 1385./40.
    pixels_per_datapoint = round(1385./10); 10 datapoints (so 4 fibres per datapoint)
    n_pixel = 2048
    
    
    ;calculation solid angle
    surface_grating = 104. ;mm
    focal_length_spectrometer = 1000. ;mm
    fnum_spectrometer = surface_grating / focal_length_spectrometer
    fnum_outgoing = 0.9*fnum_spectrometer  ;= 10 % smaller due to fiber
    magnification_lens = 5.11
    fnum_source = 1./5.*fnum_outgoing ; 
    solid_angle = 1./4.*!pi*fnum_source^2 ; srad
    
    ; calculation surface area 
    relative_frac_light_fibres = 765./1385. ; ~0.55
    distance_fibre_array = 18 ;mm
    area_source = !pi*(2.*2.54e-2/2.)^2 ;[m^2] ; A = pi*r^2
    
    
    ; display options
    min_x    = 0      ; start pixel
    max_x    = 2048-1 ; end pixel
    
    
    
;******************] LOAD DATA [*******************
    
    
    ; load data
    read_winx, fname, data, info=info1
  
    ; calculate intensity calibration factor

    calibration,n_pixel,power_integrating_sphere,factor_power,file_light_sphere,calibration_file,calibration_background_file,int_time_calibration,correct_area
    
    stop
    
    ; correct for arc duration, and emission area
    data=data/int_time*correct_f
    

for fiber=0,9 do begin
  

    ;**************] FIND TRANSITION LINES [*************    
    
    find_lines, data, interest
        

    ;**************] Calculate intensity chosen transition lines [*************
    
    ; define arrays for data
    peak = peak
    npeaks = n_elements(peak) 
    intensity=make_array(npeaks,2)
    
    integrate_intensity,peak,npeaks,data,intensity
      
    
    ; *****************] Make Boltzmann plot [****************************    
         
    ; calculate n/g (y_r) for transitionlines   
    y_r = alog(4.*!pi*intensity[*,1]/(Ai*gi*L))    
    y_r = y_r[where(finite(y_r))]
    energy = energy[where(finite(y_r))]
    
    ; do Boltzmann fit 
    fit_boltzmann,y_r,energy, data, intensity,npeaks, A, B, SI, T_e,n_e, err_Te, err_ne, noise, fname,ver
    
    
    ;*******************] Plot Spectrum & Boltzmann  [*********************
    
    plot_graphs,fname, data, peakk, peak, energy, y_r, energyk, y_rk, A, B, ver, min_x, max_x,T_e,n_e,err_Te,err_ne
    
  
endfor

    
  
;*******************] Save data  [*********************
;   
;      if ver eq 1 then begin
;    ; save everything into file
;    save_boltzmann_data, i, energy, y_r, energyk, y_rk, A, B, SI, T_e, err_Te,n_e, err_ne, noise, L, peak, fname, intensity, column_area, gi,Ai
;    endif

end



