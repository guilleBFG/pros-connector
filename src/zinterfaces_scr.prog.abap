*&---------------------------------------------------------------------*
*& Include          ZINTERFACES_SCR
*&---------------------------------------------------------------------*
TABLES: kna1.

SELECTION-SCREEN BEGIN OF BLOCK block WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_conf RADIOBUTTON GROUP rd01 USER-COMMAND u1 DEFAULT 'X',
              p_log  RADIOBUTTON GROUP rd01,
              p_int  RADIOBUTTON GROUP rd01,
              p_intd RADIOBUTTON GROUP rd01.

  SELECTION-SCREEN BEGIN OF BLOCK block2 WITH FRAME TITLE TEXT-002.
    PARAMETERS: p_cust RADIOBUTTON GROUP rd02 MODIF ID m3,
                p_prod RADIOBUTTON GROUP rd02 MODIF ID m3,
                p_cond RADIOBUTTON GROUP rd02 MODIF ID m3.

  SELECTION-SCREEN END OF BLOCK block2.

  SELECTION-SCREEN BEGIN OF BLOCK block3 WITH FRAME TITLE TEXT-002.
    SELECT-OPTIONS: s_erdat FOR kna1-erdat MODIF ID m2,
                    s_updat FOR kna1-updat MODIF ID m2.

  SELECTION-SCREEN END OF BLOCK block3.


SELECTION-SCREEN END OF BLOCK block.
