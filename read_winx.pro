pro read_WinX, filename, $ ;;; <-- filename of the stored data
               data,     $ ;;; --> array of measured intensities (wavelength, Nstripes, Nscans)
               info=info, $  ;;; --> structure with information about the measurement
               dark_pixel=dark_pixel  ;;; <-- array with index of out-of-order pixels

;--------------------------------------------------------------------
; This procedure reads the data from binary files produced by the 
; WinSpec programme from RoperScientific, i.e. PI CCD-cameras
;
; The file structure of the respective files can be found at the end
; of this routine.
;--------------------------------------------------------------------
 

 ;; declare the header size:
 header      = bytarr(4100)

 ;; prepare structure with ROI-information:
 ROI_struct = {startx :0,  $
               endx   :0,  $
               groupx :0,  $
               starty :0,  $
               endy   :0,  $
               groupy :0   }


 ;; Open input file:
 openr, unit, filename, /get_lun,  error=error
 if error ne 0l then begin
    print,  !err_string
    data = -1
    return
 endif



 ;; Read file header
 ;; ----------------
  readu, unit, header


 ;; dimensions and type of stored data:
 xDimDet         = uint(header[6:7], 0)
 yDimDet         = uint(header[18:19], 0)
 xDim            = uint(header[42:43], 0)
 yDim            = uint(header[656:657], 0)
 NumScan         = long(header[664:667], 0)
 NumFrames       = long(header[1446:1449], 0)
 NumAccumulation = long(header[668:671], 0)
 datatype        = fix(header[108:109], 0)
 byteorder, xDimDet, yDimDet, xDim, yDim, datatype, $   ;;; change byte order if necessary
   /sswap, /swap_if_big_endian
 byteorder, NumScan, NumFrames, NumAccumulation, $
   /lswap, /swap_if_big_endian

;help, datatype
;print, datatype
;; Activate datatype of 0, 1, 2 D.Nishijima@20050614 
 case datatype of         ;;; convert WinX-datatype to IDL-datatype
    0: datatype_IDL = 4       ;;; Float
    1: datatype_IDL = 3       ;;; Long Integer
    2: datatype_IDL = 2       ;;; Integer
    3: datatype_IDL = 12      ;;; Unsigned Integer
    else:message, 'No recognized data type!'
 endcase

 ;; is data a glued file?
 SpecGlueFlag       = fix(header[76:77], 0)
 byteorder, SpecGlueFlag, /sswap, /swap_if_big_endian
 tmp                = header[78:93]
 byteorder, tmp, /lswap, /swap_if_big_endian
 tmp                = float(tmp, 0, 4)
 SpecGlueStartWlNm  = tmp[0]
 SpecGlueEndWlNm    = tmp[1]
 SpecGlueMinOvrlpNm = tmp[2]
 SpecGlueFinalResNm = tmp[3]

 ;; defined regions of interest:
 NumExpROI = fix(header[1488:1489], 0) > 1
 NumROI    = fix(header[1510:1511], 0) > 1
 byteorder, NumExpROI, NumROI, /sswap, /swap_if_big_endian
 NumROI    = NumExpROI < 14
 ROI       = replicate(ROI_struct, NumROI)
 for i=0, NumROI-1 do begin
    tmp1 = uint(header[1512+i*12:1513+i*12], 0)
    tmp2 = uint(header[1514+i*12:1515+i*12], 0)
    tmp3 = uint(header[1516+i*12:1517+i*12], 0)
    tmp4 = uint(header[1518+i*12:1519+i*12], 0)
    tmp5 = uint(header[1520+i*12:1521+i*12], 0)
    tmp6 = uint(header[1522+i*12:1523+i*12], 0)
    byteorder, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, $
      /sswap, /swap_if_big_endian
    ROI[i].startx = tmp1
    ROI[i].endx   = tmp2
    ROI[i].groupx = tmp3
    ROI[i].starty = tmp4
    ROI[i].endy   = tmp5
    ROI[i].groupy = tmp6
 endfor
 
  ;; Experiment Local Time by D.Nishijima:20050909
 ExperimentTimeLocal = ''
 ExperimentTimeLocal = string(header[172:178])
; print, ExperimentTimeLocal
 
 ;; spectrometer settings:
 SpecCenterWl_nm = float(header[72:75], 0)
 SpecNumGrooves  = float(header[650:653], 0)

 ;; CCD camera settings:
 exp_sec         = float(header[10:13], 0)
 DetTemperature  = float(header[36:39], 0)
 ReadoutTime     = float(header[672:675], 0)
 HWAccumFlag     = fix(header[1432:1433], 0)
 Cleans          = uint(header[618:619], 0)
 NumSkpPerCln    = uint(header[620:621], 0)
 
; Damien's variables
delay_time = float(header[122:125], 0)
pulse_width = float(header[118:121], 0)
;PImax_mode = ''
PImax_mode = uint(header[146:147])
mode = uint(header[8:9])
exp_sec = float(header[10:13], 0)
shut_type = uint(header[1474:1475])
date = ''
date = string(header[20:29])

 byteorder, SpecCenterWl_nm, SpecNumGrooves, exp_sec, DetTemperature, ReadoutTime, $
   /lswap, /swap_if_big_endian
 byteorder, HWAccumFlag, Cleans, NumSkpPerCln, $
   /sswap, /swap_if_big_endian
 
 avg_dispersion = 0.0  ;; D.Nishijima: 20110114

 ;; information about wavelength calibration:
 xCalibValid     = fix(header[3098])
 if xCalibValid then begin
    xCalibString    = string(header[3018:3057])
    xCalibPolyOrder = fix(header[3101])
    xCalibCount     = fix(header[3102])
    tmp             = header[3103:3318]
    byteorder, tmp, /l64swap, /swap_if_big_endian
    if (xCalibCount) gt 0 then begin
       xCalibPixPos = double(tmp,   0, xCalibCount)
       xCalibValue  = double(tmp,  80, xCalibCount)
    endif else begin
       xCalibPixPos = 0.
       xCalibValue  = 0.
    endelse
    xCalibCoeff     = double(tmp, 160, xCalibPolyOrder+1)
    if SpecGlueFlag then begin  ;; Glue Yes, D.NIshijima: 20110114 ==> +1L
      wavel         = poly(lindgen(xDim)+1L, xCalibCoeff)
    endif else begin  ;; Glue No, D.NIshijima: 20110114 ==> +ROI[0].startx
      wavel         = poly(lindgen(xDim)+ROI[0].startx, xCalibCoeff)
    endelse
    
    ;; D.Nishijima: 20110114
    avg_dispersion = (wavel[xDim-1] - wavel[0])/(xDim - 1.0)  ;; nm/pixel
    
 endif else begin
    xCalibString    = ''
    xCalibPolyOrder = 0
    xCalibCount     = 0
    xCalibPixPos    = 0
    xCalibValue     = 0
    xCalibCoeff     = 0
    wavel           = fltarr(xDim)
 endelse    

;;test stuff
;;
;; -- Dimension data file --
; case datatype of
;   0: begin
;        type='  FLOATING POINT'
;        data=fltarr(xDim,yDim,numframes)
;      end
;   1: begin
;        type='  LONG INTEGER'
;        data=lonarr(xDim,yDim,numframes)
;      end
;   2: begin
;        type='  INTEGER'
;        data=intarr(xDim,yDim,numframes)
;      end
;   3: begin
;        type='  UNSIGNED INTEGER'
;        if float(!version.release) lt 5.2 then begin
;           data=intarr(xDim,yDim,numframes)
;        endif else begin
;     data=uintarr(xDim,yDim,numframes)
;        endelse
;      end
; endcase
;
;; -- Read data and close file --
;; point_lun,lun,0   
; readu,unit,data;,header,data    
;


 ;; Read the data itself according to the file contents, which is
 ;; described by the flags of the file header:
 ;; -------------------------------------------------------------
 tmp = make_array(xDim, yDim, NumFrames, type=datatype_IDL)
 
 
 readu, unit, tmp

 ;; change the byte order:
 case datatype_IDL of
    2: byteorder, tmp, /sswap, /swap_if_big_endian
    3: byteorder, tmp, /lswap, /swap_if_big_endian
    4: byteorder, tmp, /lswap, /swap_if_big_endian
    12:byteorder, tmp, /sswap, /swap_if_big_endian
 endcase

 ;; extract the data as an IDL datatype:
 data = fix(tmp, 0, xDim, yDim, NumFrames, type=datatype_IDL)

 ;; Close the input file:
 free_lun, unit


 ;; set data of dark pixel as average over neighbours:
 if keyword_set(dark_pixel) then begin
    for d=0l, n_elements(dark_pixel)-1l do $
      data[dark_pixel[d], *, *] = (data[dark_pixel[d]-1, *, *] + $
                                   data[dark_pixel[d]+1, *, *])/2.
 endif


 ;; build header structure for returning:
 info = {grooves         :SpecNumGrooves,     $
         wav_mid         :SpecCenterWl_nm,    $
         xDimDet         :xDimDet,            $
         yDimDet         :yDimDet,            $
         xDim            :xDim,               $
         yDim            :yDim,               $
         GlueFlag        :SpecGlueFlag,       $
         GlueStartWlNm   :SpecGlueStartWlNm,  $
         GlueEndWlNm     :SpecGlueEndWlNm,    $
         GlueMinOvrlNm   :SpecGlueMinOvrlpNm, $
         GlueFinalResNm  :SpecGlueFinalResNm, $
         DetTemp         :DetTemperature,     $
         exptime         :exp_sec,            $
         readout         :ReadoutTime,        $
         cleans          :Cleans,             $
         NumSkipPerClean :NumSkpPerCln,       $
         NScans          :NumScan,            $
         NFrames         :NumFrames,          $
         NROIExp         :NumExpROI,          $
         NROI            :NumROI,             $
         ROI             :ROI,                $
         NAccumulation   :NumAccumulation,    $
         xCalibValid     :xCalibValid,        $
         xCalibString    :xCalibString,       $
         xCalibPolyOrder :xCalibPolyOrder,    $
         xCalibCoeff     :xCalibCoeff,        $
         wavel           :wavel,              $
         ExperiTimeLoc   :ExperimentTimeLocal,$  ;; D.Nishijima: 20050909
         avg_dispersion  :avg_dispersion,     $  ;; D.Nishijima: 20110114
         delay_time      :delay_time,         $
         pulse_width     :pulse_width,        $
         PImax_mode      :PImax_mode,         $
         mode            :mode,               $             
         exp_sec         :exp_sec,            $          
         date            :date,               $      
         shut_type       :shut_type,          $               
         background      :fltarr(xDim, yDim)  }  ;;; just for compatibility with read_zeb.pro
 

 
 return
end

;====================================================================

;                                  WINHEAD.TXT

;                            $Date: 7/14/00 3:35p $

;                Header Structure For WinView/WinSpec (WINX) Files

;    The current data file used for WINX files consists of a 4100 (1004 Hex)
;    byte header followed by the data.

;    Beginning with Version 2.5, many more items were added to the header to
;    make it a complete as possible record of the data collection.  This includes
;    spectrograph and pulser information.  Much of these additions were accomplished
;    by recycling old information which had not been used in many versions.
;    All data files created under previous 2.x versions of WinView/WinSpec CAN
;    still be read correctly.  HOWEVER, files created under the new versions
;    (2.5 and higher) CANNOT be read by previous versions of WinView/WinSpec
;    OR by the CSMA software package.

;              ***************************************************

;                                    Decimal Byte
;                                       Offset
;                                    -----------
;  SHORT   ControllerVersion              0  Hardware Version
;  SHORT   LogicOutput                    2  Definition of Output BNC
;  WORD    AmpHiCapLowNoise               4  Amp Switching Mode
;  WORD    xDimDet                        6  Detector x dimension of chip.
;  SHORT   mode                           8  timing mode
;  float   exp_sec                       10  alternitive exposure, in sec.
;  SHORT   VChipXdim                     14  Virtual Chip X dim
;  SHORT   VChipYdim                     16  Virtual Chip Y dim
;  WORD    yDimDet                       18  y dimension of CCD or detector.
;  char    date[DATEMAX]                 20  date
;  SHORT   VirtualChipFlag               30  On/Off
;  char    Spare_1[2]                    32
;  SHORT   noscan                        34  Old number of scans - should always be -1
;  float   DetTemperature                36  Detector Temperature Set
;  SHORT   DetType                       40  CCD/DiodeArray type
;  WORD    xdim                          42  actual # of pixels on x axis
;  SHORT   stdiode                       44  trigger diode
;  float   DelayTime                     46  Used with Async Mode
;  WORD    ShutterControl                50  Normal, Disabled Open, Disabled Closed
;  SHORT   AbsorbLive                    52  On/Off
;  WORD    AbsorbMode                    54  Reference Strip or File
;  SHORT   CanDoVirtualChipFlag          56  T/F Cont/Chip able to do Virtual Chip
;  SHORT   ThresholdMinLive              58  On/Off
;  float   ThresholdMinVal               60  Threshold Minimum Value
;  SHORT   ThresholdMaxLive              64  On/Off
;  float   ThresholdMaxVal               66  Threshold Maximum Value
;  SHORT   SpecAutoSpectroMode           70  T/F Spectrograph Used
;  float   SpecCenterWlNm                72  Center Wavelength in Nm
;  SHORT   SpecGlueFlag                  76  T/F File is Glued
;  float   SpecGlueStartWlNm             78  Starting Wavelength in Nm
;  float   SpecGlueEndWlNm               82  Starting Wavelength in Nm
;  float   SpecGlueMinOvrlpNm            86  Minimum Overlap in Nm
;  float   SpecGlueFinalResNm            90  Final Resolution in Nm
;  SHORT   PulserType                    94  0=None, PG200=1, PTG=2, DG535=3
;  SHORT   CustomChipFlag                96  T/F Custom Chip Used
;  SHORT   XPrePixels                    98  Pre Pixels in X direction
;  SHORT   XPostPixels                  100  Post Pixels in X direction
;  SHORT   YPrePixels                   102  Pre Pixels in Y direction 
;  SHORT   YPostPixels                  104  Post Pixels in Y direction
;  SHORT   asynen                       106  asynchron enable flag  0 = off
;  SHORT   datatype                     108  experiment datatype
;                                             0 =   FLOATING POINT
;                                             1 =   LONG INTEGER
;                                             2 =   INTEGER
;                                             3 =   UNSIGNED INTEGER
;  SHORT   PulserMode                   110  Repetitive/Sequential
;  USHORT  PulserOnChipAccums           112  Num PTG On-Chip Accums
;  DWORD   PulserRepeatExp              114  Num Exp Repeats (Pulser SW Accum)
;  float   PulseRepWidth                118  Width Value for Repetitive pulse (usec)
;  float   PulseRepDelay                122  Width Value for Repetitive pulse (usec)
;  float   PulseSeqStartWidth           126  Start Width for Sequential pulse (usec)
;  float   PulseSeqEndWidth             130  End Width for Sequential pulse (usec)
;  float   PulseSeqStartDelay           134  Start Delay for Sequential pulse (usec)
;  float   PulseSeqEndDelay             138  End Delay for Sequential pulse (usec)
;  SHORT   PulseSeqIncMode              142  Increments: 1=Fixed, 2=Exponential
;  SHORT   PImaxUsed                    144  PI-Max type controller flag
;  SHORT   PImaxMode                    146  PI-Max mode
;  SHORT   PImaxGain                    148  PI-Max Gain
;  SHORT   BackGrndApplied              150  1 if background subtraction done
;  SHORT   PImax2nsBrdUsed              152  T/F PI-Max 2ns Board Used
;  WORD    minblk                       154  min. # of strips per skips
;  WORD    numminblk                    156  # of min-blocks before geo skps
;  SHORT   SpecMirrorLocation[2]        158  Spectro Mirror Location, 0=Not Present
;  SHORT   SpecSlitLocation[4]          162  Spectro Slit Location, 0=Not Present
;  SHORT   CustomTimingFlag             170  T/F Custom Timing Used
;  char    ExperimentTimeLocal[TIMEMAX] 172  Experiment Local Time as hhmmss\0
;  char    ExperimentTimeUTC[TIMEMAX]   179  Experiment UTC Time as hhmmss\0
;  SHORT   ExposUnits                   186  User Units for Exposure
;  WORD    ADCoffset                    188  ADC offset
;  WORD    ADCrate                      190  ADC rate
;  WORD    ADCtype                      192  ADC type
;  WORD    ADCresolution                194  ADC resolution
;  WORD    ADCbitAdjust                 196  ADC bit adjust
;  WORD    gain                         198  gain
;  char    Comments[5][COMMENTMAX]      200  File Comments
;  WORD    geometric                    600  geometric ops: rotate 0x01,
;                                             reverse 0x02, flip 0x04
;  char    xlabel[LABELMAX]             602  intensity display string
;  WORD    cleans                       618  cleans
;  WORD    NumSkpPerCln                 620  number of skips per clean.
;  SHORT   SpecMirrorPos[2]             622  Spectrograph Mirror Positions
;  float   SpecSlitPos[4]               626  Spectrograph Slit Positions
;  SHORT   AutoCleansActive             642  T/F
;  SHORT   UseContCleansInst            644  T/F
;  SHORT   AbsorbStripNum               646  Absorbance Strip Number
;  SHORT   SpecSlitPosUnits             648  Spectrograph Slit Position Units
;  float   SpecGrooves                  650  Spectrograph Grating Grooves
;  SHORT   srccmp                       654  number of source comp. diodes
;  WORD    ydim                         656  y dimension of raw data.
;  SHORT   scramble                     658  0=scrambled,1=unscrambled
;  SHORT   ContinuousCleansFlag         660  T/F Continuous Cleans Timing Option
;  SHORT   ExternalTriggerFlag          662  T/F External Trigger Timing Option
;  long    lnoscan                      664  Number of scans (Early WinX)
;  long    lavgexp                      668  Number of Accumulations
;  float   ReadoutTime                  672  Experiment readout time
;  SHORT   TriggeredModeFlag            676  T/F Triggered Timing Option
;  char    Spare_2[10]                  678  
;  char    sw_version[FILEVERMAX]       688  Version of SW creating this file
;  SHORT   type                         704   1 = new120 (Type II)             
;                                             2 = old120 (Type I )           
;                                             3 = ST130                      
;                                             4 = ST121                      
;                                             5 = ST138                      
;                                             6 = DC131 (PentaMax)           
;                                             7 = ST133 (MicroMax/SpectroMax)
;                                             8 = ST135 (GPIB)               
;                                             9 = VICCD                      
;                                            10 = ST116 (GPIB)               
;                                            11 = OMA3 (GPIB)                
;                                            12 = OMA4                       
;  SHORT   flatFieldApplied             706  1 if flat field was applied.
;  char    Spare_3[16]                  708  
;  SHORT   kin_trig_mode                724  Kinetics Trigger Mode
;  char    dlabel[LABELMAX]             726  Data label.
;  char    Spare_4[436]                 742
;  char    PulseFileName[HDRNAMEMAX]   1178  Name of Pulser File with
;                                             Pulse Widths/Delays (for Z-Slice)
;  char    AbsorbFileName[HDRNAMEMAX]  1298 Name of Absorbance File (if File Mode)
;  DWORD   NumExpRepeats               1418  Number of Times experiment repeated
;  DWORD   NumExpAccums                1422  Number of Time experiment accumulated
;  SHORT   YT_Flag                     1426  Set to 1 if this file contains YT data
;  float   clkspd_us                   1428  Vert Clock Speed in micro-sec
;  SHORT   HWaccumFlag                 1432  set to 1 if accum done by Hardware.
;  SHORT   StoreSync                   1434  set to 1 if store sync used
;  SHORT   BlemishApplied              1436  set to 1 if blemish removal applied
;  SHORT   CosmicApplied               1438  set to 1 if cosmic ray removal applied
;  SHORT   CosmicType                  1440  if cosmic ray applied, this is type
;  float   CosmicThreshold             1442  Threshold of cosmic ray removal.  
;  long    NumFrames                   1446  number of frames in file.         
;  float   MaxIntensity                1450  max intensity of data (future)    
;  float   MinIntensity                1454  min intensity of data (future)    
;  char    ylabel[LABELMAX]            1458  y axis label.                     
;  WORD    ShutterType                 1474  shutter type.                     
;  float   shutterComp                 1476  shutter compensation time.        
;  WORD    readoutMode                 1480  readout mode, full,kinetics, etc  
;  WORD    WindowSize                  1482  window size for kinetics only.    
;  WORD    clkspd                      1484  clock speed for kinetics & frame transfer
;  WORD    interface_type              1486  computer interface                
;                                             (isa-taxi, pci, eisa, etc.)             
;  SHORT   NumROIsInExperiment         1488  May be more than the 10 allowed in
;                                             this header (if 0, assume 1)            
;  char    Spare_5[16]                 1490                                    
;  WORD    controllerNum               1506  if multiple controller system will
;                                             have controller number data came from.  
;                                             this is a future item.                  
;  WORD    SWmade                      1508  Which software package created this file 
;  SHORT   NumROI                      1510  number of ROIs used. if 0 assume 1.      
;                                      1512 - 1630  ROI information      
;  struct ROIinfo {                                                   
;   unsigned int startx                left x start value.               
;   unsigned int endx                  right x value.                    
;   unsigned int groupx                amount x is binned/grouped in hw. 
;   unsigned int starty                top y start value.                
;   unsigned int endy                  bottom y value.                   
;   unsigned int groupy                amount y is binned/grouped in hw. 
;  } ROIinfoblk[ROIMAX]                   ROI Starting Offsets:          
;                                                  ROI  1 = 1512         
;                                                  ROI  2 = 1524         
;                                                  ROI  3 = 1536         
;                                                  ROI  4 = 1548         
;                                                  ROI  5 = 1560         
;                                                  ROI  6 = 1572         
;                                                  ROI  7 = 1584         
;                                                  ROI  8 = 1596         
;                                                  ROI  9 = 1608         
;                                                  ROI 10 = 1620         
;  char    FlatField[HDRNAMEMAX]       1632  Flat field file name.       
;  char    background[HDRNAMEMAX]      1752  background sub. file name.  
;  char    blemish[HDRNAMEMAX]         1872  blemish file name.          
;  float   file_header_ver             1992  version of this file header 
;  char    YT_Info[1000]               1996-2996  Reserved for YT information
;  LONG    WinView_id                  2996  == 0x01234567L if file created by WinX

;-------------------------------------------------------------------------------

;                        START OF X CALIBRATION STRUCTURE

;  double        offset                3000  offset for absolute data scaling
;  double        factor                3008  factor for absolute data scaling
;  char          current_unit          3016  selected scaling unit           
;  char          reserved1             3017  reserved                        
;  char          string[40]            3018  special string for scaling      
;  char          reserved2[40]         3058  reserved                        
;  char          calib_valid           3098  flag if calibration is valid    
;  char          input_unit            3099  current input units for         
;                                            "calib_value"                  
;  char          polynom_unit          3100  linear UNIT and used            
;                                            in the "polynom_coeff"         
;  char          polynom_order         3101  ORDER of calibration POLYNOM    
;  char          calib_count           3102  valid calibration data pairs    
;  double        pixel_position[10]    3103  pixel pos. of calibration data  
;  double        calib_value[10]       3183  calibration VALUE at above pos  
;  double        polynom_coeff[6]      3263  polynom COEFFICIENTS            
;  double        laser_position        3311  laser wavenumber for relativ WN 
;  char          reserved3             3319  reserved                        
;  unsigned char new_calib_flag        3320  If set to 200, valid label below
;  char          calib_label[81]       3321  Calibration label (NULL term'd) 
;  char          expansion[87]         3402  Calibration Expansion area      

;-------------------------------------------------------------------------------

;                        START OF Y CALIBRATION STRUCTURE

;  double        offset                3489  offset for absolute data scaling
;  double        factor                3497  factor for absolute data scaling
;  char          current_unit          3505  selected scaling unit           
;  char          reserved1             3506  reserved                        
;  char          string[40]            3507  special string for scaling      
;  char          reserved2[40]         3547  reserved                        
;  char          calib_valid           3587  flag if calibration is valid    
;  char          input_unit            3588  current input units for         
;                                            "calib_value"                   
;  char          polynom_unit          3589  linear UNIT and used            
;                                            in the "polynom_coeff"          
;  char          polynom_order         3590  ORDER of calibration POLYNOM    
;  char          calib_count           3591  valid calibration data pairs    
;  double        pixel_position[10]    3592  pixel pos. of calibration data  
;  double        calib_value[10]       3672  calibration VALUE at above pos  
;  double        polynom_coeff[6]      3752  polynom COEFFICIENTS            
;  double        laser_position        3800  laser wavenumber for relativ WN 
;  char          reserved3             3808  reserved                        
;  unsigned char new_calib_flag        3809  If set to 200, valid label below
;  char          calib_label[81]       3810  Calibration label (NULL term'd) 
;  char          expansion[87]         3891  Calibration Expansion area      

;                         END OF CALIBRATION STRUCTURES

;    ---------------------------------------------------------------------

;  char    Istring[40]                 3978  special intensity scaling string
;  char    Spare_6[80]                 4018
;  SHORT   lastvalue                   4098  Always the LAST value in the header
;                        /* 4100 Start of Data */


;Definitions of array sizes:
;    HDRNAMEMAX  = 120     Max char str length for file name
;    USERINFOMAX = 1000    User information space
;    COMMENTMAX  = 80      User comment string max length (5 comments)
;    LABELMAX    = 16      Label string max length
;    FILEVERMAX  = 16      File version string max length
;    DATEMAX     = 10      String length of file creation date string as ddmmmyyyy\0
;    ROIMAX      = 10      Max size of roi array of structures
;    TIMEMAX     = 7       Max time store as hhmmss\0

;

;                      READING STRIPS AND FRAMES OF DATA
;                     -----------------------------------

;    The data follows the header beginning at offset 4100.

;    Data is still stored as sequential points.  The X, Y and Frame dimensions
;    are determined by the header.
;    The X dimension of the stored data is in "xdim" ( Offset 42  ).
;    The Y dimension of the stored data is in "ydim" ( Offset 656 ).
;    The number of frames of data stored is in "NumFrames" ( Offset 1446 ).

;    Thus (modifying the example above):

;        char header[4100];
;        unsigned int X_dimension;
;        unsigned int Y_dimension;
;        long         Num_frames;

;             /* Now there is Direct Access of data dimensions */
;        X_dimension = (unsigned int)header[42];
;        Y_dimension = (unsigned int)header[664];
;        Num_frames  = (long)header[1446];
