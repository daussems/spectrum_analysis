pro find_lines, data, $; <-- 
    interest ;-->   
    
    ; Use peak finder to determine all possible transition lines from the spectrum. Skip first 150 pixels because of high noice.
    result = peakfinder(data[findgen(565)+150,0,0],findgen(565)+150,PCutoff=pcutoff,CLim=CLimits,NPeaks=npeaks,/Sort,/Opt)
    result = result[*,where(result[4,*] gt 0.1)]
    
    ; correct for skipped pixels
    peakk = result[0,*]+150
    
    ; load NIST database with tunsten transition lines 
    dataStruct = { wavelength:0.0, rel_int:0.0, Ak:0.0, Ek:0.0, gk:0.0}
    file = '/home/emc/aussems/My Documents/Experiments/Intensity_peak/data5.dat'
    nrows = File_Lines(file)
    data2 = Replicate(dataStruct, nrows)
    OpenR, lun, file, /GET_LUN
    ReadF, lun, data2
    Free_Lun, lun
    wavelength = data2.wavelength[*]
    rel_int = data2.rel_int[*]
    Ek = data2.Ek[*]
    Ak = data2.Ak[*]
    gk = data2.gk[*]
    
    ; load predefined list of peaks
    peak=[ 114,147, 260, 264, 278, 284, 288, 551, 568, 626, 691 ]
    npeaks = 11
   
    ; make array to store data in
    interest = make_array(10,n_elements(peakk))
    
    ; search peaks which correlate to NIST database's transtition lines.    
    h=0
    for f=0,n_elements(peakk)-1 do begin
      l=0
      interest_dummy = make_array(10,n_elements(peakk))
      for a=0,nrows-1 do begin
        ; if wavelength match with transition line, store data for that transition line in interest array
        if wavelength[a] lt pxltowave(peakk[f])+0.2 and wavelength[a] ge pxltowave(peakk[f])-0.2 then begin
          interest_dummy[0,l]=wavelength[a]
          interest_dummy[1,l]=peakk[f]
          interest_dummy[2,l]=rel_int[a]
          interest_dummy[3,l]=f
          interest_dummy[4,l]=l
          interest_dummy[5,l]=Ek[a]
          interest_dummy[6,l]=gk[a]
          interest_dummy[7,l]=Ak[a]
          l++
        endif
      endfor
      ; if there are more than one found transition lines per wavelength, take the transition line with the highest intensity
      if max(interest_dummy[2,*]) gt 0 then begin
        pos_max=where(interest_dummy[2,*] eq max(interest_dummy[2,*]))
        if n_elements(pos_max) eq 1 then begin
          array = make_array(10)
          array = interest_dummy[*,pos_max]
          interest[*,h] = array
          h++
        endif
      endif
    endfor
    
    ; delete empty rows
    interest1 = interest[0,*]
    vector = Where(interest1 NE 0)
    interest = interest[*,vector]

    end