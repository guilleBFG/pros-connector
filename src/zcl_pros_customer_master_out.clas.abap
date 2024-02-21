class ZCL_PROS_CUSTOMER_MASTER_OUT definition
  public
  final
  create public .

public section.

  interfaces ZIF_PROS_INTERFACE_OUT .
protected section.
private section.

  data GT_CUSTOMER type ZTT_PROS_CUSTOMER .
  data GT_SHIP type ZTT_PROS_SOLD_SHIP_ASSN .
  data GV_LOG_HANDLE type BALLOGHNDL .
  data GT_SOLD_SHIP type ZTT_PROS_SOLD_SHIP_ASSN .
ENDCLASS.



CLASS ZCL_PROS_CUSTOMER_MASTER_OUT IMPLEMENTATION.


  METHOD zif_pros_interface_out~extract.

    TYPES: BEGIN OF ty_t077x,
             ktokd TYPE t077x-ktokd,
             txt30 TYPE t077x-txt30,
           END OF ty_t077x,
           ty_t_t077x TYPE STANDARD TABLE OF ty_t077x.

    TYPES: BEGIN OF ty_knvp,
             kunnr TYPE knvp-kunnr,
             parvw TYPE knvp-parvw,
             kunn2 TYPE knvp-kunn2,
           END OF ty_knvp,
           ty_t_knvp TYPE STANDARD TABLE OF ty_knvp.


    CONSTANTS: lc_bill_to TYPE tpar-parvw VALUE 'BP',
               lc_ship_to TYPE tpar-parvw VALUE 'SH',
               lc_sign    TYPE char01 VALUE 'I',
               lc_option  TYPE char02 VALUE 'EQ'.

    DATA: lt_kna1      TYPE STANDARD TABLE OF kna1,
          lt_t077x     TYPE ty_t_t077x,
          lt_knvp      TYPE ty_t_knvp,
          lt_customer  TYPE ztt_pros_customer,
          lt_ship_sold TYPE ztt_pros_sold_ship_assn,
          ls_customer  TYPE zes_pros_customer,
          ls_ship_sold TYPE zes_pros_sold_ship_assn,
          lr_parvw     TYPE RANGE OF knvp-parvw,
          ls_parvw     LIKE LINE OF lr_parvw.

    FIELD-SYMBOLS: <fs_kna1>  TYPE kna1,
                   <fs_t077x> TYPE ty_t077x,
                   <fs_knvp>  TYPE ty_knvp.

    SELECT *
      FROM kna1
      INTO TABLE lt_kna1
      WHERE erdat IN it_created_on
        AND updat IN it_changed_on.

    IF sy-subrc IS NOT INITIAL.
      RAISE EXCEPTION TYPE zcx_pros_exception.
       " EXPORTING MSGV1 = 'No data found'.
*      RAISE no_data_found.
    ENDIF.

    SELECT ktokd txt30
      FROM t077x
      INTO TABLE lt_t077x
      FOR ALL ENTRIES IN lt_kna1
      WHERE ktokd = lt_kna1-ktokd
        AND spras = 'E'.


    ls_parvw-sign   = lc_sign.
    ls_parvw-option = lc_option.
    ls_parvw-low    = lc_bill_to.
    APPEND ls_parvw TO lr_parvw.

    ls_parvw-low    = lc_ship_to.
    APPEND ls_parvw TO lr_parvw.

    SELECT kunnr parvw kunn2
      FROM knvp
      INTO TABLE lt_knvp
      FOR ALL ENTRIES IN lt_kna1
        WHERE kunnr = lt_kna1-kunnr
          AND parvw IN lr_parvw.

    LOOP AT lt_kna1 ASSIGNING <fs_kna1>.

      ls_customer-parent_cust      = <fs_kna1>-kunnr.
      ls_customer-parent_cust_desc = <fs_kna1>-name1.
      ls_customer-account          = ''.
      ls_customer-account_desc     = ''.
      ls_customer-cust_group       = <fs_kna1>-ktokd.
      ls_customer-customer         = <fs_kna1>-kunnr.
      ls_customer-customer_desc    = <fs_kna1>-name1.
      ls_customer-cust_type        = <fs_kna1>-dear4.
      ls_customer-area             = <fs_kna1>-j_1kftind.
      ls_customer-industry         = <fs_kna1>-brsch.
      ls_customer-preferred_currency_code = <fs_kna1>-uwaer.
      ls_customer-delete_flag             = <fs_kna1>-nodel.
      ls_customer-extraction_time         = sy-datum.

      READ TABLE lt_t077x ASSIGNING <fs_t077x> WITH KEY ktokd = <fs_kna1>-ktokd.
      IF sy-subrc IS INITIAL.
        ls_customer-cust_group_desc  = <fs_t077x>-txt30.
      ENDIF.

      READ TABLE lt_knvp ASSIGNING <fs_knvp> WITH KEY kunnr = <fs_kna1>-kunnr
                                                      parvw = lc_bill_to.
      IF sy-subrc IS INITIAL.
        ls_customer-sold_to_cust     = <fs_knvp>-kunn2.
      ENDIF.


      READ TABLE lt_knvp ASSIGNING <fs_knvp> WITH KEY kunnr = <fs_kna1>-kunnr
                                                      parvw = lc_ship_to.
      IF sy-subrc IS INITIAL.
        ls_customer-ship_to_cust     = <fs_knvp>-kunn2.
      ENDIF.

      APPEND ls_customer TO lt_customer.
      CLEAR ls_customer.

    ENDLOOP.

    IF lt_customer IS INITIAL.
      RAISE EXCEPTION TYPE zcx_pros_exception .
    ENDIF.

    gt_customer = lt_customer.

    LOOP AT lt_knvp ASSIGNING <fs_knvp>.

      READ TABLE lt_kna1 ASSIGNING <fs_kna1> WITH KEY kunnr = <fs_knvp>-kunn2.

      IF sy-subrc IS INITIAL.

        IF <fs_knvp>-parvw = lc_bill_to.
          ls_ship_sold-sold_to = <fs_kna1>-kunnr.
        ELSEIF <fs_knvp>-parvw = lc_ship_to.
          ls_ship_sold-ship_to = <fs_kna1>-kunnr.
        ENDIF.

        ls_ship_sold-delete_flag             = <fs_kna1>-nodel.
        ls_ship_sold-extraction_time         = sy-datum.
        APPEND ls_ship_sold TO lt_ship_sold.

      ENDIF.

      CLEAR ls_ship_sold.

    ENDLOOP.

  ENDMETHOD.


  METHOD zif_pros_interface_out~log.

    DATA: ls_msg        TYPE bal_s_msg,
          lt_log_handle TYPE BAL_T_LOGH.

***Create message

    ls_msg-msgty = iv_msgty.         "Message type
    ls_msg-msgid = iv_msgid.         "Message id
    ls_msg-msgno = iv_msgno.         "Message number
    ls_msg-msgv1 = iv_msgv1.         "Text that you want to pass as message
    ls_msg-msgv2 = iv_msgv2.         "Text that you want to pass as message
    ls_msg-msgv3 = iv_msgv3.         "Text that you want to pass as message
    ls_msg-msgv4 = iv_msgv4.         "Text that you want to pass as message
    ls_msg-probclass = 2.

    CALL FUNCTION 'BAL_LOG_MSG_ADD'
      EXPORTING
        i_log_handle = gv_log_handle
        i_s_msg      = ls_msg
     EXCEPTIONS
       log_not_found             = 1
       msg_inconsistent          = 2
       log_is_full               = 3
       OTHERS                    = 4.

    CHECK sy-subrc IS INITIAL.

    INSERT gv_log_handle INTO TABLE lt_log_handle.

***Save message
    CALL FUNCTION 'BAL_DB_SAVE'
     EXPORTING
       i_client               = sy-mandt
       i_save_all             = abap_true
       i_t_log_handle         = lt_log_handle
     EXCEPTIONS
       log_not_found          = 1
       save_not_allowed       = 2
       numbering_error        = 3
       OTHERS                 = 4.

    IF sy-subrc EQ 0.

      REFRESH: lt_log_handle.

    ENDIF.

  ENDMETHOD.


  METHOD zif_pros_interface_out~run.

    CONSTANTS: lc_object TYPE balobj_d VALUE 'PROSCONN/MASTER'.

    DATA: ls_log     TYPE bal_s_log,
          lv_message TYPE string.

    DATA: lx_root      TYPE REF TO cx_root,
          lx_exception TYPE REF TO zcx_pros_exception.

*** Create initial the log errors
    ls_log-object = lc_object.  "Object name
    ls_log-aluser = sy-uname.   "Username
    ls_log-alprog = sy-repid.   "Report name

*    me->log(IV_MSGTY
*IV_MSGID
*IV_MSGNO
*IV_MSGV1
*IV_MSGV2
*IV_MSGV3
*IV_MSGV4) .

    CALL FUNCTION 'BAL_LOG_CREATE'
      EXPORTING
        i_s_log                 = ls_log
      IMPORTING
        e_log_handle            = gv_log_handle
      EXCEPTIONS
        log_header_inconsistent = 1
        OTHERS                  = 2.

    TRY .

        me->zif_pros_interface_out~extract( EXPORTING it_created_on = it_created_on
                                                      it_changed_on = it_changed_on ).

        me->zif_pros_interface_out~transform( ).

        me->zif_pros_interface_out~send( ).

      CATCH zcx_pros_exception INTO lx_exception.
        "CATCH cx_root INTO lx_root.
        lv_message = lx_exception->if_message~get_text( ).
*        CALL METHOD lx_root->if_message~get_text
*          RECEIVING
*            result = lv_message
*            .


    ENDTRY.

  ENDMETHOD.


  METHOD zif_pros_interface_out~send.

    CONSTANTS: lc_id TYPE zde_pros_interface_id VALUE '01'.

    DATA: lo_file TYPE REF TO zcl_pros_file.

    CREATE OBJECT lo_file.

    CALL METHOD lo_file->send_file
      EXPORTING
        iv_id            = lc_id
      CHANGING
        ct_data          = gt_customer
      EXCEPTIONS
        no_type          = 1
        no_configuration = 2
        OTHERS           = 3.
    IF sy-subrc <> 0.
*     Implement suitable error handling here

    ENDIF.



  ENDMETHOD.


  method ZIF_PROS_INTERFACE_OUT~TRANSFORM.
  endmethod.
ENDCLASS.
