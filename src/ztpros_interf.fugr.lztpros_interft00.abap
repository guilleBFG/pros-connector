*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTPROS_INTERF...................................*
DATA:  BEGIN OF STATUS_ZTPROS_INTERF                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTPROS_INTERF                 .
CONTROLS: TCTRL_ZTPROS_INTERF
            TYPE TABLEVIEW USING SCREEN '0002'.
*.........table declarations:.................................*
TABLES: *ZTPROS_INTERF                 .
TABLES: ZTPROS_INTERF                  .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
