*&---------------------------------------------------------------------*
*& Include          ZINTERFACES_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form f_set_screen
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_set_screen .

  LOOP AT SCREEN.
    CASE abap_true.
      WHEN p_conf.
        "Configuration screen
        IF screen-group1 = 'M3'.
          screen-active = 0.
        ENDIF.

*** Dates filter only for Run Delta mode
        IF screen-group1 = 'M2'.
          screen-active = 0.
        ENDIF.
      WHEN p_log.
        "Log screen
        IF screen-group1 = 'M3'.
          screen-active = 1.
        ENDIF.

*** Dates filter only for Run Delta mode
        IF screen-group1 = 'M2'.
          screen-active = 0.
        ENDIF.

      WHEN p_int.
        "Interfaces screen
        IF screen-group1 = 'M3'.
          screen-active = 1.
        ENDIF.

*** Dates filter only for Run Delta mode
        IF screen-group1 = 'M2'.
          screen-active = 0.
        ENDIF.
      WHEN p_intd.
        IF screen-group1 = 'M3'.
          screen-active = 1.
        ENDIF.

*** Dates filter only for Run Delta mode
        IF screen-group1 = 'M2'.
          screen-active = 1.
        ENDIF.
    ENDCASE.


    MODIFY SCREEN.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_set_action
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_set_action .


  CASE abap_true.

    WHEN p_conf.

      PERFORM f_maintain_view.

    WHEN p_log.

      PERFORM f_log.

    WHEN p_int.

      PERFORM f_run_full_interface.

    WHEN p_intd.

      PERFORM f_run_delta_interface.

  ENDCASE.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_maintain_view
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_maintain_view .

  DATA: lc_config   TYPE dd02v-tabname VALUE 'ZTPROS_INTERF'.

  CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
    EXPORTING
      action                       = 'U'
      view_name                    = lc_config  "maint.View
    EXCEPTIONS
      client_reference             = 1
      foreign_lock                 = 2
      invalid_action               = 3
      no_clientindependent_auth    = 4
      no_database_function         = 5
      no_editor_function           = 6
      no_show_auth                 = 7
      no_tvdir_entry               = 8
      no_upd_auth                  = 9
      only_show_allowed            = 10
      system_failure               = 11
      unknown_field_in_dba_sellist = 12
      view_not_found               = 13
      OTHERS                       = 14.
  IF sy-subrc NE 0.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_log
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_log .

  DATA: lv_object TYPE balhdr-object.

  CASE abap_true.
    WHEN p_cust.
      lv_object = '/UIF/LREP'.
    WHEN p_prod.
      lv_object = ''.
    WHEN p_cond.
      lv_object = ''.
  ENDCASE.

  CALL FUNCTION 'APPL_LOG_DISPLAY'
    EXPORTING
      object                    = lv_object
    " date_from                 = lv_date_from
    " date_to                   = lv_date_to
      suppress_selection_dialog = 'X'
      "IMPORTING
    " number_of_protocols       = lv_number
    EXCEPTIONS
      no_authority              = 1
      OTHERS                    = 2.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_run_full_interface
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_run_full_interface .

  DATA: lo_interface TYPE REF TO zif_pros_interface_out.

  DATA: lt_created_on TYPE ztt_pros_date_range,
        lt_changed_on TYPE ztt_pros_date_range.

  FIELD-SYMBOLS: <fs_erdat> LIKE s_erdat,
                 <fs_date>  TYPE zes_pros_date_range.

  CASE abap_true.

    WHEN p_cust.

      CREATE OBJECT lo_interface TYPE zcl_pros_customer_master_out.

    WHEN p_prod.

      CREATE OBJECT lo_interface TYPE zcl_pros_product_master_out.

    WHEN p_cond.

      CREATE OBJECT lo_interface TYPE zcl_pros_condition_data_out.

  ENDCASE.

  lo_interface->run( ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_run_delta_interface
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_run_delta_interface .

  DATA: lo_interface TYPE REF TO zif_pros_interface_out.

  DATA: lt_created_on TYPE ztt_pros_date_range,
        lt_changed_on TYPE ztt_pros_date_range.

  FIELD-SYMBOLS: <fs_erdat> LIKE s_erdat,
                 <fs_date>  TYPE zes_pros_date_range.

  CASE abap_true.

    WHEN p_cust.

      CREATE OBJECT lo_interface TYPE zcl_pros_customer_master_out.

    WHEN p_prod.

      CREATE OBJECT lo_interface TYPE zcl_pros_product_master_out.

    WHEN p_cond.

      CREATE OBJECT lo_interface TYPE zcl_pros_condition_data_out.

  ENDCASE.

*** Parameters for Delta run
  LOOP AT s_erdat ASSIGNING <fs_erdat>.

    APPEND INITIAL LINE TO lt_created_on ASSIGNING <fs_date>.

    <fs_date>-sign = <fs_erdat>-sign.
    <fs_date>-option = <fs_erdat>-option.
    <fs_date>-low = <fs_erdat>-low.
    <fs_date>-high = <fs_erdat>-high.

  ENDLOOP.

  LOOP AT s_updat ASSIGNING <fs_erdat>.

    APPEND INITIAL LINE TO lt_changed_on ASSIGNING <fs_date>.

    <fs_date>-sign = <fs_erdat>-sign.
    <fs_date>-option = <fs_erdat>-option.
    <fs_date>-low = <fs_erdat>-low.
    <fs_date>-high = <fs_erdat>-high.

  ENDLOOP.

  lo_interface->run( EXPORTING it_created_on = lt_created_on
                               it_changed_on = lt_changed_on ).

ENDFORM.
