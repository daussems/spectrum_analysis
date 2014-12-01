pro plot_graphs, fname,$ ;<-- 
    data,$ ; <--
    peakk,$ ; <--
    peak,$ ; <--
    energy,$ ;<--
    y_r, $ ;<--
    energyk, $ ;<--
    y_rk, $ ;<--
    A, $ ;<--
    B, $ ;<--
    ver,$  ; <-- 
    min_x,$ ; <--
    max_x,$ ; <-- 
    T_e,$ ; <--
    n_e,$ ; <--
    err_Te,$ ; <--
    err_ne ; <--
    
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
      device,/encaps,file='Pictures/'+fdir+'/'+tmp+'.eps',/col,bits=8
    endif else  device, decomposed = 0
   
    ; multi plot
    !P.MULTI = [0, 1, 2]
    
    ; define color red
    TVLCT, [[255], [0], [0]], 100
    
    
    draw_spectrum, data, peakk, peak, min_x, max_x
  
    plot_boltzmann, energy, y_r, energyk, y_rk, A, B, peak,peakk,T_e,n_e,err_Te,err_ne
    

    if ver eq 1 then begin
      device,/close
      set_plot,'x'
    endif
    
end
