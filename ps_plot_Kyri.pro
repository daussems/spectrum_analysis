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
    @common_intens_data
    @common_intensid
    
    
    ;******************] INITIALIZING PARAMETERS [*******************
    
    ; set up directory
    home_path = '/home/emc/aussems/My Documents/Experiments/Intensity_peak' 
    cd, home_path 
    ; information on lines
    energy =  [3.40809, 5.36244,  3.26913,  5.14527,  3.25208,  3.24705,  5.33555,  2.65994,  3.24705,  2.97124,  2.97124]
    gi=       [7,       9,        5,        7,        5,        7,        11,       3,        7,        5,        5]
    Ai=       [1E7,     9.3E6,    3.04E6,   9.3E6,    1.24E7,   3.6E6,    5.4E6,    1000000,  1.4E6,    272000,   1.9E6]
    ; over-write information form spe_button
    spefiles = ['/home/emc/aussems/My Documents/Experiments/Intensity_peak' $
                '/home/emc/aussems/My Documents/Experiments/Intensity_peak' 
               ]
    peak    = [ 114,147, 260, 264, 278, 284, 288, 551, 568, 626, 691 ]  
    ; spectral information
    int_time =  ; integration time
    L = 1.6e-2
    pxlwv_A = 0.13318
    pxlwv_B = 392.41898
    ; display options
    min_x    = 0
    max_x    = 714
    
    ;******************] LOAD DATA [*******************
    
    ; load file name
    fname = spefiles[i]
    
    ; load data
    read_winx, spefiles[i], data, info=info1
    
    ; calculate intensity calibration factor
    calibration, correct_f
    
    ; correct for arc duration, and emission area
    data=data/int_time*correct_f
    
    ;data=data/(((t_arc)-0.1)*1e-3)*correct_f*column_area/emis_area

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

    
    ;*******************] Save data  [*********************
    
    if ver eq 1 then begin
    ; save everything into file
    save_boltzmann_data, i, energy, y_r, energyk, y_rk, A, B, SI, T_e, err_Te,n_e, err_ne, noise, L, peak, fname, intensity, column_area, gi,Ai
    endif

  
end



