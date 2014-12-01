pro integrate_intensity, peak,$ ;<--
    npeaks,$ ; <--
    data,$ ; <--
    intensity ;-->
    
    ; define arrays for intengration
    peakr = make_array(npeaks)
    peakl = make_array(npeaks)
    
    ; loop through transition lines
    for p = 0,npeaks-1 do begin
    
      ;check if it's the real peak, else shift one pixel
      int = data[peak[p],0,0]
      
      if data[peak[p]+1,0,0] gt int and data[peak[p]+1,0,0] gt data[peak[p]-1,0,0] then begin
        peak[p]=peak[p]+1
      endif else if data[peak[p]-1,0,0] gt int then peak[p]=peak[p]-1
      
      ; find right boundary peak  
      peakr[p]=peak[p]+1
      while ((slopep(data,peakr[p]) lt 6*slopep(data,(peakr[p]+1)) or slopep(data,peakr[p]) lt slopep(data,(peakr[p]+1)))) and slopep(data,(peakr[p]+1)) gt 0  do begin
        peakr[p]++
      endwhile
      
      ; find left boundary peak
      peakl[p]=peak[p]-1
      while (slopen(data,peakl[p]) lt 6*slopen(data,(peakl[p]-1)) or slopen(data,peakr[p]) lt slopen(data,(peakr[p]-1))) and slopen(data,(peakl[p]-1)) gt 0  do begin
        peakl[p]--
      endwhile
      ;and slopen(data,(peakl[p]-1)) gt 30
      
      ; calculate background
      background = findgen(peakr[p]-peakl[p]+1)/(peakr[p]-peakl[p])*(1*data[peakr[p],0,0]-1*data[peakl[p],0,0])+1*data[peakl[p],0,0]
      
      ; make array for integration
      intens_dummy = make_array(peakr[p]-peakl[p]+1)
      lambda_dummy = make_array(peakr[p]-peakl[p]+1)
      
      m=0
      for t=peakl[p],peakr[p] do begin
        intens_dummy[m] = data[t,0,0]
        lambda_dummy[m] = pxltowave(t)
        m++
      endfor
      
      ; integrate peak
      intens_dummy=intens_dummy-background
      intensity[p,1] = int_tabulated(lambda_dummy,intens_dummy)
      
    endfor
    
    
end