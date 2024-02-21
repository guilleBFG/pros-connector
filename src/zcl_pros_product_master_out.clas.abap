class ZCL_PROS_PRODUCT_MASTER_OUT definition
  public
  final
  create public .

public section.

  interfaces ZIF_PROS_INTERFACE_OUT .
protected section.
private section.

  data GT_PRODUCT type ZTT_PROS_PRODUCT .
ENDCLASS.



CLASS ZCL_PROS_PRODUCT_MASTER_OUT IMPLEMENTATION.


  METHOD zif_pros_interface_out~extract.

    CONSTANTS: lc_spras TYPE spras VALUE 'E'.

    DATA: lt_mara  TYPE STANDARD TABLE OF mara,
          lt_t023t TYPE STANDARD TABLE OF t023t,
          lt_makt  TYPE STANDARD TABLE OF makt,
          lt_tvtyt TYPE STANDARD TABLE OF tvtyt.


    DATA: ls_product TYPE zes_pros_product.

    FIELD-SYMBOLS: <fs_mara>  TYPE mara,
                   <fs_t023t> TYPE t023t,
                   <fs_makt>  TYPE makt,
                   <fs_tvtyt> TYPE tvtyt.

    SELECT *
      FROM mara
      INTO TABLE lt_mara.

    CHECK sy-subrc IS INITIAL.

    SELECT *
      FROM t023t
      INTO TABLE lt_t023t
      FOR ALL ENTRIES IN lt_mara
      WHERE matkl = lt_mara-matkl
        AND spras = lc_spras.

    SELECT *
      FROM makt
      INTO TABLE lt_makt
      FOR ALL ENTRIES IN lt_mara
      WHERE matnr = lt_mara-matnr
        AND spras = lc_spras.

    SELECT *
      FROM tvtyt
      INTO TABLE lt_tvtyt
      FOR ALL ENTRIES IN lt_mara
      WHERE traty = lt_mara-vhart
        AND spras = lc_spras.

    LOOP AT lt_mara ASSIGNING <fs_mara>.

      ls_product-prod_group = <fs_mara>-matkl. "Material Group

      ls_product-prod_line = ''.
      ls_product-prod_line_desc = ''.
      ls_product-base_prod = ''.
      ls_product-base_prod_desc = ''.
      ls_product-pack_type = <fs_mara>-vhart. "Packaging Material Type
      ls_product-product = <fs_mara>-matnr. "Material Number
      ls_product-cust_spec = ''.
      ls_product-active_flag = ''.
      ls_product-stock_flag = ''.
      ls_product-prod_code = ''.
      ls_product-grade = <fs_mara>-fashgrd. "Fashion Grade
      ls_product-preferred_uom_code = <fs_mara>-meins. "Base Unit of Measure
      ls_product-delete_flag = ''.
      ls_product-extraction_time = sy-datum.


      READ TABLE lt_t023t ASSIGNING <fs_t023t> WITH KEY matkl = <fs_mara>-matkl.
      IF sy-subrc IS INITIAL.
        ls_product-prod_group_desc = <fs_t023t>-wgbez. "Material Group Description
      ENDIF.

      READ TABLE lt_makt ASSIGNING <fs_makt> WITH KEY matnr = <fs_mara>-matnr.
      IF sy-subrc IS INITIAL.
        ls_product-product_desc = <fs_makt>-maktx. "Material Description
      ENDIF.

      READ TABLE lt_tvtyt ASSIGNING <fs_tvtyt> WITH KEY traty = <fs_mara>-vhart.
      IF sy-subrc IS INITIAL.
        ls_product-pack_type_desc = <fs_tvtyt>-vtext. "Packaging Material Types Description
      ENDIF.

      APPEND ls_product TO gt_product.

      CLEAR ls_product.

    ENDLOOP.

  ENDMETHOD.


  method ZIF_PROS_INTERFACE_OUT~RUN.

    me->zif_pros_interface_out~extract( ).

*    me->zif_pros_interface_out~transform( ).

    me->zif_pros_interface_out~send( ).

  endmethod.


  METHOD zif_pros_interface_out~send.

    CONSTANTS: lc_id TYPE zde_pros_interface_id VALUE '02'.

    DATA: lo_file TYPE REF TO zcl_pros_file.

    CREATE OBJECT lo_file.

    CALL METHOD lo_file->send_file
      EXPORTING
        iv_id            = lc_id
      CHANGING
        ct_data          = gt_product
      EXCEPTIONS
        no_type          = 1
        no_configuration = 2
        OTHERS           = 3.
    IF sy-subrc <> 0.
*     Implement suitable error handling here

    ENDIF.

  ENDMETHOD.
ENDCLASS.
