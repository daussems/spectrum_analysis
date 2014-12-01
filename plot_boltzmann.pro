pro plot_boltzmann, energy,$ ;<--
    y_r, $ ;<--
    energyk, $ ;<--
    y_rk, $ ;<--
    A, $ ;<--
    B,$ ;<--
    peak,$ ; <--
    peakk,$ ; <--
    T_e,$ ; <--
    n_e,$ ; <--
    err_Te,$ ; <--
    err_ne ; <--

    ; assign plot limits
    maxint=max(y_r)+0.3*(max(y_r)-min(y_r))
    minint=min(y_r)-0.3*(max(y_r)-min(y_r))
    minen=min(energy)*0.8
    maxen=max(energy)*1.2
       
    plot,energy,y_r,ys=1,xs=1,xrange=[minen,maxen], yrange=[minint,maxint],psym=1,/nodata, $
      xtitl='Energy [eV]',ytitl=textoidl("n/g [m^{-3}]"),title='n/g as function of energy',position=[0.15, 0.60, 0.95, 0.95], background=!p.background
      
    ; oplot,energyk,y_rk,psym=1
    
    for t = 0, n_elements(peakk)-1 do begin
    ;  xyouts, energyk[t],y_rk[t], string(peakk[t],   format='(I4.1)' )
    endfor
    
    ;plot transition lines
    oplot,energy,y_r, color=100, psym=1
    oplot,energy,(B*energy+A)
    
    for q = 0, n_elements(y_r)-1 do begin
      xyouts, energy[q]+0.1,y_r[q], string(pxltowave(peak[q]),   format='(F0.1)' ), color=100
    endfor
    
    ; plot n_e and T_e
    xyouts, 4.3,(0.9*(maxint-minint)+minint), 'T_e = '+string(T_e,   format='(G0.2)' )+' +/- '+string(err_Te,   format='(G0.2)' ) , CHARSIZE=1.0, CHARTHICK=1
    xyouts, 4.3,(0.83*(maxint-minint)+minint), 'n_e = '+string(n_e,   format='(E0.2)' )+' +/- '+string(err_ne,   format='(E0.2)' ) , CHARSIZE=1.0, CHARTHICK=1
   

      
end