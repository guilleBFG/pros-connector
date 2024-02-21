class ZCL_PROS_CONDITION_DATA_OUT definition
  public
  final
  create public .

public section.

  interfaces ZIF_PROS_INTERFACE_OUT .
protected section.
private section.

  data GT_CONDITION_DATA type ZTT_PROS_CONDITION_DATA .
ENDCLASS.



CLASS ZCL_PROS_CONDITION_DATA_OUT IMPLEMENTATION.


  METHOD zif_pros_interface_out~extract.

    DATA: lt_konh  TYPE TABLE OF konh,
          lt_konp  TYPE TABLE OF konp,
          lt_t685t TYPE TABLE OF t685t.

    DATA: ls_condition_data TYPE zes_pros_condition_data.

    FIELD-SYMBOLS: <fs_konh>  TYPE konh,
                   <fs_t685t> TYPE t685t,
                   <fs_konp>  TYPE konp.

    CONSTANTS: lc_e TYPE spras VALUE 'E'.

    SELECT *
      FROM konh "Conditions (Header)
      INTO TABLE lt_konh.

    CHECK sy-subrc IS INITIAL.

    SELECT *
      FROM t685t "Conditions: Types: Texts
      INTO TABLE lt_t685t
      FOR ALL ENTRIES IN lt_konh
      WHERE kvewe = lt_konh-kvewe
        AND kappl = lt_konh-kappl
        AND kschl = lt_konh-kschl
        AND spras = lc_e.

    SELECT *
      FROM konp "Conditions (Item)
      INTO TABLE lt_konp
      FOR ALL ENTRIES IN lt_konh
      WHERE knumh = lt_konh-knumh.

    LOOP AT lt_konh ASSIGNING <fs_konh>.
      ls_condition_data-action = ''.
      ls_condition_data-base_per_quantity = ''.

      ls_condition_data-condition_table_id = <fs_konh>-kotabnr. "Number of the Condition Table
      ls_condition_data-condition_type     = <fs_konh>-kschl.   "Condition Type
      ls_condition_data-currency_code      = ''.
      "ls_condition_data-element_record = ''.
      ls_condition_data-end_service_date   = ''.
      ls_condition_data-extraction_time    = sy-datum.
      "ls_condition_data-formula_record = ''.
      "ls_condition_data-formula_rule = ''.
      ls_condition_data-key_values = ''.
      "ls_condition_data-scale_record = ''.


      ls_condition_data-start_service_date = ''.
      ls_condition_data-updated_by = ''.
      ls_condition_data-valid_from_date = <fs_konh>-datab. "Valid-From Date
      ls_condition_data-valid_to_date   = <fs_konh>-datbi. "Valid To Date

      READ TABLE lt_t685t ASSIGNING <fs_t685t> WITH KEY kvewe = <fs_konh>-kvewe
                                                        kappl = <fs_konh>-kappl
                                                        kschl = <fs_konh>-kschl.
      IF sy-subrc IS INITIAL.
        ls_condition_data-condition_value    = <fs_t685t>-vtext. "Name: Conditions: Types: Texts
      ENDIF.

      READ TABLE lt_konp ASSIGNING <fs_konp> WITH KEY knumh = <fs_konh>-knumh.
      IF sy-subrc IS INITIAL.
        ls_condition_data-scale_currency_code = <fs_konp>-konws. "Scale Currency
        ls_condition_data-scale_uom_code = <fs_konp>-konms.      "Condition Scale Unit of Measure
        ls_condition_data-base_uom_code = <fs_konp>-meins.       "Base Unit of Measure
      ENDIF.

      APPEND ls_condition_data TO gt_condition_data.
      CLEAR ls_condition_data.

    ENDLOOP.

  ENDMETHOD.


  METHOD zif_pros_interface_out~run.

    me->zif_pros_interface_out~extract( ).

*    me->zif_pros_interface_out~transform( ).

    me->zif_pros_interface_out~send( ).

  ENDMETHOD.


  method ZIF_PROS_INTERFACE_OUT~SEND.

    CONSTANTS: lc_id TYPE zde_pros_interface_id VALUE '03'.

    DATA: lo_file TYPE REF TO zcl_pros_file.

    CREATE OBJECT lo_file.

    CALL METHOD lo_file->send_file
      EXPORTING
        iv_id            = lc_id
      CHANGING
        ct_data          = gt_condition_data
      EXCEPTIONS
        no_type          = 1
        no_configuration = 2
        OTHERS           = 3.
    IF sy-subrc <> 0.
*     Implement suitable error handling here

    ENDIF.

  endmethod.
ENDCLASS.
