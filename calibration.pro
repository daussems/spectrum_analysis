pro calibration,n_pixel,power_integrating_sphere,factor_power,file_light_sphere,calibration_file,calibration_background_file,int_time_calibration,correct_area

@common_intens_data_test

wave_vect = pxltowave(findgen(n_pixel))

num_rows = uint(file_lines(file_light_sphere))-1
close,/all
openr, lun, file_light_sphere, /get_lun

header =   strarr(1) 
readf, lun, header ; import header
buffer =   strarr(num_rows) 
readf, lun, buffer ; import data

; --------------------------------------
; Define variables
; --------------------------------------

wave     = fltarr(num_rows) ; wavelength [nm]
radiance = fltarr(num_rows) ; W cm-2 sr-1 nm-1

; --------------------------------------
; Import data in a put in variables
; --------------------------------------

for i = 0, num_rows-1 do begin
  line = strsplit(buffer(i),/extract)
  wave(i)     = float(line[0])
  radiance(i) = float(line[1])
end


;; Convert from [mW/(m^2 sr nm)] to [ph/(s m^2 sr nm)].

data_ph = fltarr(num_rows)
h = 6.6261e-34   ;; Planck constant in [Js]
c = 2.9979e8     ;; Speed of light in [m/s]
data_ph = 1.0e-5*wave*radiance/(h*c)

;; derive polynomial coefficients

l_ind = max(where(wave lt wave_vect(0)))
u_ind = min(where(wave gt wave_vect(n_pixel-1)))

result_ph = poly_fit(wave(l_ind:u_ind), data_ph(l_ind:u_ind), 2L, yfit=fit_ph)

;; reconstruct the emissivity with wave_vect.

emiss_vect_ph = poly(wave_vect, result_ph)

;cg_newwindow
;cgplot,wave,data_ph,/add,xrange=[300,500]
;cgOplot,wave_vect,emiss_vect_ph3,/add,color=cgcolor('green')


read_winx, calibration_file, calibration_data, info=info1

read_winx, calibration_background_file, bg_data, info=info1

emission = calibration_data -  bg_data

y_ln = alog(emission)

;cg_newwindow
;cgplot,emission,/add,yrange=[0,1000]
;cgOplot,y_ln,/add

;cgcontour,emission,nlevels=20,/fill

emiss_line = emission
correct_area = emission

for i = 0,n_pixel-1 do begin

result_fit_calibration = poly_fit(wave_vect, emission[*,i],2,yfit=yfitx1)
emiss_line[*,i] = poly(wave_vect, result_fit_calibration)
correct_factors = emiss_vect_ph/(emiss_line[*,i]/int_time_calibration)*1e-10
correct_area[*,i] = correct_factors

endfor

LoadCT, 33, NColorS=12, Bottom=1
;cgcontour,emiss_line,nlevels=20,/fill
cgcontour,correct_area,nlevels=12,/fill,Position=[0.125,0.125,0.9,0.75], C_Colors=Indgen(12)+1
cgColorbar, Range=[Min(correct_area), Max(correct_area)], Divisions=12, NColors=12, Bottom=1, $
       Position=[0.125, 0.87, 0.9, 0.94], /Discrete
stop



end




