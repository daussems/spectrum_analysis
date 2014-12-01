pro calibration, correct_f


n_pixel = 715
wave_vect = pxltowave(findgen(n_pixel))

read_sphere, n_pixel, wave_vect, emiss_vect_mW, emiss_vect_ph

;background


fname = '/home/emc/aussems/My Documents/Experiments/Intensity_peak/Data/20130117/b4400.SPE'
read_winx, fname, bdata1, info=info1

; calibration data

fname = '/home/emc/aussems/My Documents/Experiments/Intensity_peak/Data/20130117/c4200.SPE'
read_winx, fname, cdata1, info=info1

;plot,wave_vect,emiss_vect_ph

LoadCT, 0


tmp_emission=make_array(715)
background=make_array(715)

for i = 0,715-1 do begin
background[i] = mean(bdata1[i,0,*])
tmp_emission[i] = mean(cdata1[i,0,*])
endfor

emission = tmp_emission -  background

y_ln = alog(emission)

result = poly_fit(wave_vect[100:700], y_ln[100:700],3,yfit=yfitx1)
y_fit = result[0] + result[1]*wave_vect^1 + result[2]*wave_vect^2 + result[3]*wave_vect^3

yfit_normal = exp(y_fit) 

;plot,emission,/ylog
;oplot,yfit_normal
;stop

;plot,emission
;oplot,yfit_normal
;stop

I_data = yfit_normal /20e-3

correct_f = emiss_vect_ph/ I_data

;plot,wave_vect,correct_f


end




