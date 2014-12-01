pro draw_spectrum, data,$ ; <--
    peakk,$ ; <--
    peak,$ ; <--
    min_x,$ ;<--
    max_x ; <--
    
  ymax = max(data[min_x:max_x,0,0])*1.1
  
  wavelength = pxltowave(findgen(n_elements(data[*,0,0])))
  
  ; plot spectrum
  plot,wavelength,data[*,0,0],ys=1,xs=1,xrange=[pxltowave(min_x),pxltowave(max_x)], yrange=[0,ymax], $
    xtitl='Wavelength [nm]',ytitl='Intensity [ph/s/m^2/sr/nm]',title='Intensity spectrum',thick=lth,position=[0.15, 0.10, 0.95, 0.45], color=!p.color, background=!p.background
      
  ; plot position transition lines NIST  
  for d=0,n_elements(peakk)-1 do begin
  ;  oplot, [pxltowave(peakk[d]),pxltowave(peakk[d])],[0,ymax], linestyle=2
  endfor
    
  ; plot position predefined transition lines
  for h=0,n_elements(peak)-1 do begin
   oplot, [pxltowave(peak[h]),pxltowave(peak[h])],[0,ymax], linestyle=3, color=100
  endfor
  
end    