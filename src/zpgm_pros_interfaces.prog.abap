*&---------------------------------------------------------------------*
*& Report ZINTERFACES
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpgm_pros_interfaces.

"INCLUDE zinterfaces_top.
INCLUDE zinterfaces_scr.
INCLUDE zinterfaces_f01.

INITIALIZATION.


AT SELECTION-SCREEN OUTPUT.
  PERFORM f_set_screen.


START-OF-SELECTION.
  PERFORM f_set_action.
