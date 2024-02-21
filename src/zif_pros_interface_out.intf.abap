interface ZIF_PROS_INTERFACE_OUT
  public .


  methods EXTRACT
    importing
      !IT_CREATED_ON type ZTT_PROS_DATE_RANGE optional
      !IT_CHANGED_ON type ZTT_PROS_DATE_RANGE optional
    raising
      ZCX_PROS_EXCEPTION .
  methods TRANSFORM .
  methods SEND .
  methods LOG
    importing
      !IV_MSGTY type SYMSGTY
      !IV_MSGID type SYMSGID
      !IV_MSGNO type SYMSGNO
      !IV_MSGV1 type SYMSGV
      !IV_MSGV2 type SYMSGV
      !IV_MSGV3 type SYMSGV
      !IV_MSGV4 type SYMSGV .
  methods RUN
    importing
      !IT_CREATED_ON type ZTT_PROS_DATE_RANGE optional
      !IT_CHANGED_ON type ZTT_PROS_DATE_RANGE optional
    raising
      ZCX_PROS_EXCEPTION .
endinterface.
