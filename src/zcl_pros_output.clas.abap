class ZCL_PROS_OUTPUT definition
  public
  final
  create public .

public section.

  methods SEND_FTP .
  methods SEND_FILE .
  methods CONVERT_XML .
  methods CONVERT_CSV
    importing
      !IT_DATA type DATA .
protected section.
private section.
ENDCLASS.



CLASS ZCL_PROS_OUTPUT IMPLEMENTATION.


  method CONVERT_CSV.
  endmethod.


  method CONVERT_XML.
  endmethod.


  method SEND_FILE.
  endmethod.


  method SEND_FTP.
  endmethod.
ENDCLASS.
