pro save_boltzmann_data, i,$ ;<-- fileindex 
    energy,$ ;<--
    y_r,$ ;<--
    energyk,$ ;<--
    y_rk,$ ;<--
    A, $ ;<--
    B, $ ;<--
    SI, $ ;<--
    T_e, $ ;<--
    err_Te,$ ;<--
    n_e,$ ;<--
    err_ne,$ ;<--
    noise,$ ;<--
    L,$ ;<--   
    peak,$ ;<--
    fname,$ ; <--
    intensity,$ ;<--
    column_area,$ ;<--
    gi,$ ;<--
    Ai ;<--

;; D.Aussems: 20130325

@common_intens_data

;calculate signal, maximum intensity
signal = total(intensity[*,1])
intens_max = max(intensity[*,1])
intens_avg = mean(intensity[*,1])    
    
; calculate wavelength
wavelength = make_array(n_elements(peak))
for f=0,n_elements(peak)-1 do wavelength[f] = pxltowave(peak[f])


filenameonly = ''
tmp_spefile = strsplit(fname, '/', /extract)
n_tmp_spefile = n_elements(tmp_spefile)
filenameonly = strtrim(tmp_spefile[n_tmp_spefile-1], 2)
fdir = strtrim(tmp_spefile[n_tmp_spefile-2], 2)
FILE_MKDIR, 'Save_data/'+fdir
tmp = strsplit(filenameonly, '.', /extract)
tmp = strtrim(tmp[0],2)
outfile = 'Save_data/'+fdir+'/'+tmp+'.dat'

E_inf = 7.86403

; write save file
openw, lun,outfile , /get_lun, width=2000
  
  printf, lun, 'Saved on: '+systime()
  printf, lun, 'spefile:'
  printf, lun, fname
  printf, lun, ''
  
  printf, lun, '*********] Input [*********'
  printf, lun, ''
  printf, lun, 'Parameters for boltzmann fitting'
  printf, lun, 'Plasma depth [m] = '+ strtrim(L, 2)
  printf, lun, 'Ionization limit [eV] = '+ strtrim(E_inf, 2)
  printf, lun, ''
  
  printf, lun, '*********] Output [*********'

  
  printf, lun, ''
  printf, lun, 'Avg intensity [ph/s/m^2/sr] = '+strtrim(intens_avg, 2)
  printf, lun, 'Max intensity [ph/s/m^2/sr] = '+strtrim(intens_max, 2)
  printf, lun, 'Total intensity [ph/s/m^2/sr] = '+strtrim(signal, 2)
  printf, lun, '"Noise" [ph/s/m^2/sr] = '+strtrim(noise, 2)
  printf, lun, '' 
  printf, lun, 'Fitting results'
  printf, lun, 'A = '+strtrim(A, 2)
  printf, lun, 'A error = '+strtrim(SI[1], 2)
  printf, lun, 'B = '+strtrim(B, 2)
  printf, lun, 'B error = '+strtrim(SI[2], 2)
  printf, lun, ''
  printf, lun, 'Electron density and temperature results'
  printf, lun, 'T_e [eV] = '+strtrim(T_e, 2)
  printf, lun, 'T_e error [eV] = '+strtrim(err_Te, 2)
  printf, lun, 'n_e [m^-3] = '+strtrim(n_e, 2)
  printf, lun, 'T_e error [m^-3] = '+strtrim(err_ne, 2)

  printf, lun, ''
  para_name1 = 'Energy[eV] n/g [m^-3] Wavelength [nm] Intensity [ph/s/m^2/sr] A [s^-1] g [-]'
  printf, lun, para_name1
  for j = 0, n_elements(energy)-1 do begin
    printf, lun, energy[j],y_r[j],wavelength[j],intensity[j,1],Ai[j],gi[j]
  endfor  

free_lun, lun



end
