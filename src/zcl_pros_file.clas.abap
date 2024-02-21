class ZCL_PROS_FILE definition
  public
  final
  create public .

public section.

  methods SEND_FILE
    importing
      !IV_ID type ZDE_PROS_INTERFACE_ID
    changing
      !CT_DATA type STANDARD TABLE
    exceptions
      NO_TYPE
      NO_CONFIGURATION .
protected section.
private section.

  methods CONVERT_TO_CSV
    importing
      !IT_DATA type STANDARD TABLE
    exporting
      !ET_DATA type TRUXS_T_TEXT_DATA .
  methods CONVERT_TO_XML
    importing
      !IT_DATA type STANDARD TABLE
      !IS_CONFIGURATION type ZTPROS_INTERF
    exporting
      !EV_XML type STRING .
  methods SEND_LOCAL
    importing
      !IV_CONFIGURATION type ZTPROS_INTERF
      !IT_DATA type STANDARD TABLE .
  methods SEND_FTP
    importing
      !IV_CONFIGURATION type ZTPROS_INTERF
      !IT_DATA type STANDARD TABLE .
  methods SET_TITLES
    changing
      !CT_DATA type STANDARD TABLE .
  methods SEND_FTP_2
    importing
      !IV_CONFIGURATION type ZTPROS_INTERF
      !IT_DATA type STANDARD TABLE .
ENDCLASS.



CLASS ZCL_PROS_FILE IMPLEMENTATION.


  METHOD convert_to_csv.

    DATA: convtab TYPE truxs_t_text_data.

    CALL FUNCTION 'SAP_CONVERT_TO_CSV_FORMAT'
      EXPORTING
        i_field_seperator    = ';'
      TABLES
        i_tab_sap_data       = it_data "dyntab
      CHANGING
        i_tab_converted_data = et_data
      EXCEPTIONS
        conversion_failed    = 1
        OTHERS               = 2.

  ENDMETHOD.


  METHOD convert_to_xml.

    DATA: lv_xml_result TYPE xstring,
          lv_string     TYPE string.

    FIELD-SYMBOLS: <fs_data> TYPE any.
*



    CASE is_configuration-id.
      WHEN 01. "Customer Master

        DATA: lt_customer TYPE ztt_pros_customer.
        lt_customer = it_data.

        CALL TRANSFORMATION zt_pros_customer
           SOURCE customer = lt_customer[]
           RESULT XML lv_xml_result.

      WHEN 02. "Product Master

        DATA: lt_product TYPE ztt_pros_product.
        lt_product = it_data.

        CALL TRANSFORMATION zt_pros_product
           SOURCE product = lt_product[]
           RESULT XML lv_xml_result.

      WHEN 03. "Condition Data

        DATA: lt_condition_data TYPE ztt_pros_condition_data.
        lt_condition_data = it_data.

        CALL TRANSFORMATION zt_pros_condition_data
           SOURCE condition_data = lt_condition_data[]
           RESULT XML lv_xml_result.

    ENDCASE.


    CALL FUNCTION 'ECATT_CONV_XSTRING_TO_STRING'
      EXPORTING
        im_xstring = lv_xml_result
*       IM_ENCODING       = 'UTF-8'
      IMPORTING
        ex_string  = ev_xml.


  ENDMETHOD.


  METHOD send_file.

    DATA: lt_csv           TYPE truxs_t_text_data,
          lv_xml           TYPE string,
          lt_xml           TYPE STANDARD TABLE OF string,
          ls_configuration TYPE ztpros_interf,
          lv_file_name     TYPE string,
          lv_file_type     TYPE char10.

*** Get configuration from Interface ID
    SELECT SINGLE *
    FROM ztpros_interf
      INTO ls_configuration
      WHERE id = iv_id.

    IF sy-subrc IS NOT INITIAL.
      RAISE no_configuration.
    ENDIF.

    CLEAR lv_file_name.

*** Convert file to the correct format
    CASE ls_configuration-file_type.

      WHEN 'CSV'.

        me->set_titles( CHANGING ct_data = ct_data ).

        me->convert_to_csv( EXPORTING it_data = ct_data
                            IMPORTING et_data = lt_csv ).



        CASE ls_configuration-destination_type.
          WHEN 'LOCAL'.
            me->send_local( EXPORTING iv_configuration = ls_configuration
                                      it_data          = lt_csv ).

*          WHEN 'FTP'.
*            me->send_ftp_2( EXPORTING iv_configuration = ls_configuration
*                                      it_data          = ct_data ).

        ENDCASE.

      WHEN 'XML'.

        me->convert_to_xml( EXPORTING it_data = ct_data
                                      is_configuration = ls_configuration
                            IMPORTING ev_xml  = lv_xml ).

        CONCATENATE ls_configuration-destination
                    ls_configuration-file_name
                    '_' sy-datum sy-uzeit
                    '.' ls_configuration-file_type INTO lv_file_name.

        APPEND lv_xml TO lt_xml.

        CASE ls_configuration-destination_type.
          WHEN 'LOCAL'.
            me->send_local( EXPORTING iv_configuration = ls_configuration
                                      it_data          = lt_xml ).

*          WHEN 'FTP'.
*            me->send_ftp( EXPORTING iv_configuration = ls_configuration
*                                      it_data          = ct_data ).


        ENDCASE.

      WHEN OTHERS.

        RAISE no_type.

    ENDCASE.




  ENDMETHOD.


  METHOD send_ftp.

    TYPES: tv_ftp_line(255)       TYPE c.

    CONSTANTS: lc_key  TYPE i VALUE 26101957,
               lc_dest TYPE rfcdes-rfcdest VALUE 'ZPROS_SAPFTP'.
    "  lc_dest TYPE rfcdes-rfcdest VALUE 'ZPROS_SAPFTP'. "'SAPFTP'.


    DATA: lv_lenght   TYPE i,
          lv_dhdl     TYPE i,
          lv_host(64) TYPE c VALUE 'ftp.iccginc.com', "FTP Adresi
          lt_data     TYPE STANDARD TABLE OF tv_ftp_line,
          lv_dpwd     TYPE char30.


    DATA: lv_file_name TYPE char50.
    CONCATENATE iv_configuration-destination
                iv_configuration-file_name
                '_' sy-datum sy-uzeit
                '.' iv_configuration-file_type INTO lv_file_name.

*****
    TYPES: BEGIN OF ty_iresult,
            rec(450),
           END OF ty_iresult,
           ty_t_iresult TYPE STANDARD TABLE OF ty_iresult.

    DATA : iresult TYPE ty_t_iresult,
           ls_iresult TYPE ty_iresult.

         ls_iresult-rec = 'hola mundo'.
         APPEND ls_iresult to iresult.
*****

    lv_lenght = strlen( iv_configuration-password ).

* Below Function module is used to Encrypt the Password.
    CALL FUNCTION 'HTTP_SCRAMBLE'
      EXPORTING
        source      = iv_configuration-password
        sourcelen   = lv_lenght
        key         = lc_key
      IMPORTING
        destination = lv_dpwd. " Encyrpted Password

* Connects to the FTP Server as specified by user.
    CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
      EXPORTING
        text = 'Connecting to FTP Server'.

* Below function module is used to connect the FTP Server.
* It Accepts only Encrypted Passwords.
* This Function module will provide a handle to perform different
* operations on the FTP Server via FTP Commands.
    CALL FUNCTION 'FTP_CONNECT'
      EXPORTING
        user            = iv_configuration-user_name   " FTP USER-NAME
        password        = lv_dpwd                      " FTP PASSWORD
        host            = lv_host "'ftp.iccginc.com' "'ZPROS_SAPFTP' "iv_configuration-destination " FTP IP-ADDRESS
        rfc_destination = lc_dest " RFC Destination 'SAPFTP'
      IMPORTING
        handle          = lv_dhdl
                          EXCEPTIONS
                          not_connected.

    IF sy-subrc NE 0.

      FORMAT COLOR COL_NEGATIVE.

      WRITE:/ 'Error in Connection'.

    ELSE.

      WRITE:/ 'FTP Connection is opened '.

    ENDIF.

    CALL FUNCTION 'FTP_COMMAND'
      EXPORTING
        handle        = lv_dhdl
        command       = 'set passive on'
      TABLES
        data          = lt_data
      EXCEPTIONS
        command_error = 1
        tcpip_error   = 2.

**Transferring the data from internal table to FTP Server.
    CALL FUNCTION 'FTP_R3_TO_SERVER'
      EXPORTING
        handle         = lv_dhdl
        fname          = lv_file_name " FILE NAME 'MATERIAL_DATA.txt'
        character_mode = 'X'
      TABLES
        text           = iresult "it_data " CONCATENATED MATERIAL DATA
      EXCEPTIONS
        tcpip_error    = 1
        command_error  = 2
        data_error     = 3
        OTHERS         = 4.

    IF sy-subrc <> 0.

      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno

      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

    ELSE.

      WRITE:/ 'File has created on FTP Server'.

    ENDIF.

    CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
      EXPORTING
        text = 'File has created on FTP Server'.

*To Disconnect the FTP Server.

    CALL FUNCTION 'FTP_DISCONNECT'
      EXPORTING
        handle = lv_dhdl.

*To Disconnect the Destination.

    CALL FUNCTION 'RFC_CONNECTION_CLOSE'
      EXPORTING
        destination = lc_dest
      EXCEPTIONS
        OTHERS      = 1.

  ENDMETHOD.


  METHOD send_ftp_2.

    CONSTANTS: lc_key  TYPE i VALUE 26101957,
               lc_dest TYPE rfcdes-rfcdest VALUE 'ZPROS_SAPFTP'. "'SAPFTP'.


    DATA: lv_lenght TYPE i,
          lv_dhdl   TYPE i,
          lv_dpwd   TYPE c.

    DATA: lv_file_name TYPE char50.


****
    DATA: lv_destination TYPE rfcdest,
          lv_uri         TYPE string.

    DATA: lo_http_client TYPE REF TO cl_http_client,
          lo_client      TYPE REF TO if_http_client,
          lo_utility     TYPE REF TO cl_http_utility,
          lv_xstring     TYPE xstring.

    DATA: lt_product TYPE ztt_pros_product.
    lt_product = it_data.

    CALL TRANSFORMATION zt_pros_product
       SOURCE product = lt_product[]
       RESULT XML lv_xstring.

    CONCATENATE iv_configuration-destination
                iv_configuration-file_name
                '_' sy-datum sy-uzeit
                '.' iv_configuration-file_type INTO lv_file_name.


    lv_destination = iv_configuration-destination.

    TRY .


        CALL METHOD cl_http_client=>create_by_destination
          EXPORTING
            destination                = lc_dest "lv_destination
          IMPORTING
            client                     = lo_client
          EXCEPTIONS
            argument_not_found         = 1
            destination_not_found      = 2
            destination_no_authority   = 3
            plugin_not_active          = 4
            internal_error             = 5
            oa2c_set_token_error       = 6
            oa2c_missing_authorization = 7
            oa2c_invalid_config        = 8
            oa2c_invalid_parameters    = 9
            oa2c_invalid_scope         = 10
            oa2c_invalid_grant         = 11
            OTHERS                     = 12.
        IF sy-subrc <> 0.
*    Implement suitable error handling here
        ENDIF.

*****
*        DATA: lo_lo_rest_client          TYPE REF TO cl_rest_http_client.
*
*        CREATE OBJECT lo_lo_rest_client
*          EXPORTING
*            io_http_client = lo_client.
*
*        CASE sy-subrc.
*          WHEN 1. " http_communication_failure.
*          WHEN 2. " http_invalid_state.
*          WHEN 3. " http_processing_failed.
*          WHEN 4. " others.
*        ENDCASE.

        "lo_request = lo_lo_rest_client->if_lo_rest_client~create_request_entity( ).
*****



*****
       DATA: lo_rest_client          TYPE REF TO cl_rest_http_client.

        CREATE OBJECT lo_rest_client
          EXPORTING
            io_http_client = lo_client.


        DATA: lo_request_entity  TYPE REF TO if_rest_entity,
              lo_response_entity TYPE REF TO if_rest_entity,
              lt_params          TYPE tihttpnvp,
              wa_params          TYPE ihttpnvp.

        "CONSTANTS lc_media_type TYPE string VALUE if_rest_media_type=>gc_appl_json.
        CONSTANTS lc_media_type TYPE string VALUE if_rest_media_type=>GC_APPL_XML.




*        wa_params-name = 'charset'.
*        wa_params-value = 'utf-8'.
*        APPEND wa_params TO lt_params.
*
*        TRY.
*            lo_rest_client->refresh_request( ).
*            lo_rest_client->if_lo_rest_client~set_request_header( iv_name  = if_http_header_fields_sap=>request_uri
*                                                                  iv_value = iv_resource_name ).
*            lo_request_entity = lo_rest_client->if_lo_rest_client~create_request_entity( ).
*            lo_request_entity->set_content_type( iv_media_type = lc_media_type
*                                                 it_parameter  = lt_params ).
*            lo_request_entity->set_string_data( iv_request ).
*
*            lo_rest_client->if_lo_rest_client~post( lo_request_entity ).
*
*            lo_response_entity = lo_rest_client->if_lo_rest_client~get_response_entity( ).
*            ev_string          = lo_response_entity->get_string_data( ).
*            ev_status_code     = lo_rest_client->if_lo_rest_client~get_status( ).
*
*          CATCH cx_lo_rest_client_exception cx_root.
*            ev_status_code = 0.
*        ENDTRY.

*****
        lv_uri = lv_file_name.

        CALL METHOD cl_http_utility=>set_request_uri
          EXPORTING
            request = lo_client->request
            uri     = lv_uri
*           multivalue = 0
          .

        lo_client->request->set_header_field( name  = '~request_method'
                                              value = 'PUT' ).
        "value = 'PUT' ).
        " value = 'GET' ).

        lo_client->request->set_header_field( name  = '~server_protocal'
                                              value = 'HTTP/1.0' ).

*    lo_client->request->set_header_field( name  = 'content_type'
*                                          value = lv_xstring ).

        lo_client->request->set_data( data = lv_xstring ).

*****
*DATA: lv_timeout TYPE i.

        CALL METHOD lo_client->send
*          EXPORTING
*            timeout                    = lv_timeout
          EXCEPTIONS
            http_communication_failure = 1
            http_invalid_state         = 2
            http_processing_failed     = 3
            http_invalid_timeout       = 4
            OTHERS                     = 5.
        IF sy-subrc <> 0.
*         Implement suitable error handling here
        ENDIF.

        CALL METHOD lo_client->receive
*          EXCEPTIONS
*            http_communication_failure = 1
*            http_invalid_state         = 2
*            http_processing_failed     = 3
*            others                     = 4
          .
        IF sy-subrc <> 0.
*         Implement suitable error handling here
        ENDIF.



        " DATA: lo_request     TYPE REF TO if_rest_entity.


*****
        "     lo_client->request->set_content_type( iv_media_type = lv_xstring ).




        CALL METHOD lo_client->close
          EXCEPTIONS
            http_invalid_state = 1
            OTHERS             = 2.
        IF sy-subrc <> 0.
*     Implement suitable error handling here
        ENDIF.

      CATCH cx_root .

        CALL METHOD lo_client->close
          EXCEPTIONS
            http_invalid_state = 1
            OTHERS             = 2.
        IF sy-subrc <> 0.
*     Implement suitable error handling here
        ENDIF.

    ENDTRY.







  ENDMETHOD.


  METHOD send_local.

    DATA: lv_file_name     TYPE string.

    CONCATENATE iv_configuration-destination
                iv_configuration-file_name
                '_' sy-datum sy-uzeit
                '.' iv_configuration-file_type INTO lv_file_name.

    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
        filename                = lv_file_name "'C:\example.csv'
      " filetype                = lv_file_type
      TABLES
        data_tab                = it_data
      EXCEPTIONS
        file_write_error        = 1
        no_batch                = 2
        gui_refuse_filetransfer = 3
        invalid_type            = 4
        no_authority            = 5
        unknown_error           = 6
        header_not_allowed      = 7
        separator_not_allowed   = 8
        filesize_not_allowed    = 9
        header_too_long         = 10
        dp_error_create         = 11
        dp_error_send           = 12
        dp_error_write          = 13
        unknown_dp_error        = 14
        access_denied           = 15
        dp_out_of_memory        = 16
        disk_full               = 17
        dp_timeout              = 18
        file_not_found          = 19
        dataprovider_exception  = 20
        control_flush_error     = 21
        OTHERS                  = 22.
    IF sy-subrc <> 0.
* Implement suitable error handling here

    ENDIF.

  ENDMETHOD.


  METHOD set_titles.



*********

    DATA : l_typedesc  TYPE REF TO cl_abap_typedescr,
           l_struc     TYPE REF TO cl_abap_structdescr,
           "tl_fieldtab TYPE abap_compdescr_tab,
           tl_fieldtab TYPE STANDARD TABLE OF dfies,
           lv_titles   TYPE string,
           lv_name_s   TYPE string,
           lv_name     TYPE ddobjname.

    FIELD-SYMBOLS : <itab_line> TYPE any,
                    <fs_row_m>  TYPE dfies,
*                    <fs_row_m>  TYPE abap_compdescr,
                    "<fs_dd04l>  TYPE dd04l,
                    "<fs_dd04t>  TYPE dd04t,
                    <fs_field>  TYPE dfies,
                    <fs_data>   TYPE any.

    READ TABLE ct_data ASSIGNING <itab_line> INDEX 1.
    CHECK sy-subrc IS INITIAL.

*Call the static method of the structure descriptor describe_by_data
    CALL METHOD cl_abap_structdescr=>describe_by_data
      EXPORTING
        p_data      = <itab_line>
      RECEIVING
        p_descr_ref = l_typedesc.

    CHECK sy-subrc IS INITIAL.

*Get name of the table
    CALL METHOD l_typedesc->get_relative_name
      RECEIVING
        p_relative_name = lv_name_s.

    lv_name = lv_name_s.

*The method returns a reference of a type descriptor class therefore
*we need to Cast the type descriptor to a more specific class i.e
*Structure Descriptor.
*    l_struc ?= l_typedesc.

*Use the Attribute COMPONENTS of the structure Descriptor class to get
*the field names of the structure
*    tl_fieldtab =  l_struc->components.


** Get data domains from structure
    CALL FUNCTION 'DDIF_FIELDINFO_GET'
      EXPORTING
        tabname        = lv_name
        langu          = sy-langu
      TABLES
        dfies_tab      = tl_fieldtab
      EXCEPTIONS
        not_found      = 1
        internal_error = 2
        OTHERS         = 3.

    CHECK tl_fieldtab[] IS NOT INITIAL.

    APPEND INITIAL LINE TO ct_data ASSIGNING <fs_data>.

    LOOP AT tl_fieldtab ASSIGNING <fs_row_m>.

*      READ TABLE tl_fieldtab ASSIGNING <fs_field> WITH KEY tabname = iv_nombre
*                                                           fieldname = <fs_row_m>-name.
*      IF sy-subrc IS INITIAL.
*        lv_title = <fs_field>-scrtext_m. "Descripción
*      ELSE.
*        lv_title = <fs_row_m>-name. "Nombre técnico
*      ENDIF.
*
      ASSIGN COMPONENT <fs_row_m>-fieldname OF STRUCTURE l_struc TO <fs_field>.
      IF sy-subrc IS INITIAL.
        <fs_field> = <fs_field>-fieldname. "Descripción
      ENDIF.

*      IF sy-tabix = 1.
*        lv_titles = <fs_row_m>-fieldname.
*      ELSE.
*        CONCATENATE lv_titles <fs_row_m>-fieldname INTO lv_titles SEPARATED BY ';'.
*      ENDIF.

*    IF vl_primer_pasada EQ abap_false.
*
**      cv_titulos = <fs_row_m>-name.
*      cv_titulos = lv_title.
*      vl_primer_pasada = abap_true.
*
*    ELSE.
*
**** Se concatena al título la descripción de los campos
*        CONCATENATE cv_titulos lv_title INTO cv_titulos SEPARATED BY cl_abap_char_utilities=>horizontal_tab.
*
****        concatenate cv_titulos <fs_row_m>-name INTO cv_titulos SEPARATED BY cl_abap_char_utilities=>horizontal_tab.
*      "$. Endregion Mod # T 15913  - JB - 18.04.2017
*
*    ENDIF.

    ENDLOOP.

    "<fs_data> = lv_titles.
    "APPEND ls_data TO ct_data.

  ENDMETHOD.
ENDCLASS.
