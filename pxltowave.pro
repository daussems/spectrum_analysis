function pxltowave, pxl

@common_intens_data_test

; pxlwv_A = slope define in ps_plot_Kyri 
; pxlwv_B = offset define in ps_plot_Kyri


pxln = pxl*pxlwv_A+pxlwv_B
return,pxln

end
