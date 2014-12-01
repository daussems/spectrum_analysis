pro fit_boltzmann,y_r,$ ; <-- n/g
    energy,$ ; <--
    data,$ ; <--
    intensity,$ ; <--
    npeaks,$ ; <--
    A, $ ; --> intersect fit 
    B, $ ; --> slope 
    SI, $ ; --> uncertainty 
    T_e, $ ;-->
    n_e,$ ;-->
    err_Te, $ ;-->
    err_ne, $ ;-->
    noise, $ ;-->
    fname,$ ;<--
    ver ;<--
       
            
    ; declare fit parameters
    A=0.
    B=0.
    SI=make_array(6)
    
    ; do the fit
    result = linfit(energy,y_r,sigma=sigma)
    A_err = sigma[0]
    B_err = sigma[1]
    SI[1] = A_err
    SI[2] = B_err
    A = result[0]
    B = result[1]
    
    ; calculating T_e
    T_e = -1/B
    err_Te = T_e * sqrt((B_err/B)^2)
    
    ; calculate n_e
    ng = exp(A + B * 7.86403)
    err_ng = exp(A + B * 7.86403) * sqrt( (7.86403 * abs(B_err))^2 + abs(A_err)^2 )
    
    n_e=1e10*sqrt(ng*2.*3./(5.3e-11^3*1e20)*(T_e/4./!pi/13.6 )^(1.5))
    err_ne=1e10*sqrt(ng*2.*3./(5.3e-11^3*1e20)*(T_e/4./!pi/13.6 )^(1.5))*((3./4.*err_Te/T_e)^2+(1./2.*err_ng/ng)^2)

    ; determine noise, signal, and maximum intensity
    x=findgen(715)
    result3 = poly_fit(x, data[*,0,0],7,yfitx) 
    noise = total(abs(yfitx-data[*,0,0]))


    ; make file dir and name
    tmp_spefile = strsplit(fname, '/', /extract)
    n_tmp_spefile = n_elements(tmp_spefile)
    fdir = strtrim(tmp_spefile[n_tmp_spefile-2], 2)
    FILE_MKDIR, 'Pictures/'+fdir    
    ffname = ''
    ffname = strtrim(tmp_spefile[n_tmp_spefile-1], 2)
    tmp = strsplit(ffname, '.', /extract)
    tmp = strtrim(tmp[0],2)
    
    
    ; choose to plot in IDL, or make PS file
    if (ver eq 1) then begin
      set_plot,'ps'
      device,/encaps,file='Pictures/'+fdir+'/'+tmp+'_noise.eps',/col,bits=8
    endif else  device, decomposed = 0
   
    ; multi plot
    !P.MULTI = [0, 1, 2]
    
    ; define color red
    TVLCT, [[255], [0], [0]], 100
    
;    ;plot noise, and fit
;    plot,x,yfitx,psym=1
;    oplot,x,data[*,0,0], color=100, psym=1
   
    if ver eq 1 then begin
      device,/close
      set_plot,'x'
    endif



end