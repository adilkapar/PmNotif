CLASS lhc_ZR_PM_NOTIF DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PUBLIC SECTION.
    " 1. Define the Global Buffer structure to pass data to the Saver
    TYPES: BEGIN OF ty_notif_buffer,
             cid        TYPE abp_behv_cid,
             notiftype  TYPE qmart,
             short_text TYPE qmtxt,
             plant      TYPE werks_d,
             equipment  TYPE equnr,
             wkctr      TYPE cr_objid,
             dl_codegrp TYPE qcodegrp,
             dl_code    TYPE qcode,
             d_codegrp  TYPE qcodegrp,
             d_code     TYPE qcode,
             breakdown  TYPE msaus,
           END OF ty_notif_buffer.

    CLASS-DATA gt_notif_buffer TYPE TABLE OF ty_notif_buffer.

    TYPES: BEGIN OF ty_assign_buffer,
             notif_no TYPE qmnum,
             parvw    TYPE parvw,
             partner  TYPE bu_partner,
             updkz    TYPE char1, " 'I' for Insert, 'D' for Delete
           END OF ty_assign_buffer.

    CLASS-DATA gt_assign_buffer TYPE TABLE OF ty_assign_buffer.

    TYPES: BEGIN OF ty_notif_update,
             notif_no     TYPE qmnum,
             short_text   TYPE qmtxt,
             short_text_x TYPE abap_bool,
             equipment    TYPE equnr,
             equipment_x  TYPE abap_bool,
             wkctr        TYPE cr_objid,
             wkctr_x      TYPE abap_bool,
*             dl_code      TYPE qcode,
*             dl_code_x    TYPE abap_bool,
*             d_code       TYPE qcode,
*             d_code_x     TYPE abap_bool,
           END OF ty_notif_update.

    CLASS-DATA gt_notif_update_buffer TYPE TABLE OF ty_notif_update.

    CLASS-DATA gt_notif_delete_buffer TYPE TABLE OF qmnum.


    " Buffer for Order Creation
    TYPES: BEGIN OF ty_order_buffer,
             notif_no   TYPE qmnum,
             plant      TYPE werks_d,
             short_text TYPE qmtxt,
             wkctr      TYPE arbpl,
           END OF ty_order_buffer.

    CLASS-DATA gt_order_create_buffer TYPE TABLE OF ty_order_buffer.

    TYPES: BEGIN OF ty_mail,
             uname         TYPE uname,
             subject       TYPE string,
             body          TYPE string,
             docType(1),
             docNumber(15),
           END OF ty_mail.

    CLASS-DATA gs_mail_Daata TYPE ty_mail.

    CLASS-METHODS sending_email
      IMPORTING is_mail          TYPE ty_mail
      RETURNING VALUE(rv_result) TYPE abap_bool.

  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zr_pm_notif RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zr_pm_notif RESULT result.

*    METHODS create FOR MODIFY
*      IMPORTING entities FOR CREATE zr_pm_notif.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE zr_pm_notif.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE zr_pm_notif.

    METHODS read FOR READ
      IMPORTING keys FOR READ zr_pm_notif RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK zr_pm_notif.

*    METHODS createWithPopup FOR MODIFY
*      IMPORTING keys FOR ACTION zr_pm_notif~createWithPopup RESULT result.

    METHODS createWithPopup FOR MODIFY
      IMPORTING keys FOR ACTION zr_pm_notif~createWithPopup.

    " 3. ADD: Method to handle new child rows (+)
    METHODS cba_Partner FOR MODIFY
      IMPORTING entities_cba FOR CREATE Notification\_Partner.

    " 4. ADD: Method to handle removed child rows (Delete)
    METHODS delete_partner FOR MODIFY
      IMPORTING keys FOR DELETE Partner.

    METHODS createOrder FOR MODIFY
      IMPORTING keys FOR ACTION Notification~createOrder.

ENDCLASS.

CLASS lhc_ZR_PM_NOTIF IMPLEMENTATION.

  METHOD sending_email.
    DATA: lo_send_request TYPE REF TO cl_bcs,
          lo_document     TYPE REF TO cl_document_bcs,
          lo_sender       TYPE REF TO cl_sapuser_bcs,
          lo_recipient    TYPE REF TO cl_cam_address_bcs,
          lt_body         TYPE bcsy_text,
          lv_html_string  TYPE string,
          lv_app_url      TYPE string.

    CASE sy-sysid.
      WHEN 'DS4'.
        CASE is_mail-doctype.
          WHEN 'N'.  " Notification
            lv_app_url = |https://vhapzds4ci.sap.almutahida.com.iq:44300/sap/bc/ui2/flp?sap-client=300&sap-language=EN#ZPM_BM_NOTIFY-display|.
          WHEN 'O'.  " Order
            lv_app_url = |https://vhapzds4ci.sap.almutahida.com.iq:44300/sap/bc/ui2/flp?sap-client=300&sap-language=EN#ZPM_BMORDERS-display&|
            && |/MaintenanceOrder(MaintenanceOrder='{ is_mail-docnumber }',IsActiveEntity=true)|.
          WHEN OTHERS.
            lv_app_url = |https://vhapzds4ci.sap.almutahida.com.iq:44300/sap/bc/ui2/flp?sap-client=300&sap-language=EN#ZPM_BM_NOTIFY-display|.
        ENDCASE.
      WHEN OTHERS.
        lv_app_url = 'https://sistem-adresi.com/sap/bc/ui2/flp?#Uygulama-SemantikObje'.
    ENDCASE.


    lv_html_string = |<html><body>| &&
                     | <p>{ is_mail-body }</p>| &&
                     | <br><br>| &&
                     | <p>Please click <a href="{ lv_app_url }">here</a> for open the document.</p>| &&
                     |</body></html>|.

    lt_body = cl_document_bcs=>string_to_soli( lv_html_string ).

    TRY.
        lo_send_request = cl_bcs=>create_persistent( ).

        lo_document = cl_document_bcs=>create_document(
          i_type    = 'HTM'
          i_text    = lt_body
          i_subject = CONV so_obj_des( is_mail-subject )
        ).
        lo_send_request->set_document( lo_document ).

        lo_sender = cl_sapuser_bcs=>create( sy-uname ).
        lo_send_request->set_sender( lo_sender ).

        SELECT SINGLE smtp_addr INTO @DATA(lv_smtp)
          FROM adr6 AS a
          INNER JOIN usr21 AS u ON a~addrnumber EQ u~addrnumber AND a~persnumber EQ u~persnumber
          WHERE bname EQ @is_mail-uname.

        IF lv_smtp IS NOT INITIAL.
          lo_recipient = cl_cam_address_bcs=>create_internet_address( lv_smtp ).
          lo_send_request->add_recipient( lo_recipient ).

          lo_send_request->set_send_immediately( abap_true ).
          lo_send_request->send( ).
        ENDIF.

      CATCH cx_bcs INTO DATA(lx_bcs).
    ENDTRY.
  ENDMETHOD.

  METHOD get_instance_features.

    DATA(lv_is_supervisor) = abap_false.

    " 1. Check Authorization
    AUTHORITY-CHECK OBJECT 'ZPM_NOTIF'
      ID 'ZPM_ROLE' FIELD 'SUP'
      ID 'ACTVT'    DUMMY.

    IF sy-subrc = 0.
      lv_is_supervisor = abap_true.
    ENDIF.

    " 2. CLEAN CORE: Read the buffered data to check if an order exists
    READ ENTITIES OF zr_pm_notif IN LOCAL MODE
      ENTITY Notification
      FIELDS ( MaintenanceOrder ) " <-- Adjust to your exact CDS field name
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_notif_data).

    LOOP AT keys INTO DATA(ls_key).
      DATA(lv_order_exists) = abap_false.

      " Look up the data we just read for this specific row
      READ TABLE lt_notif_data INTO DATA(ls_notif) WITH KEY %tky = ls_key-%tky.
      IF sy-subrc = 0 AND ls_notif-MaintenanceOrder IS NOT INITIAL.
        lv_order_exists = abap_true.
      ENDIF.

      APPEND VALUE #(
        %tky                = ls_key-%tky

        " NEW: Disable standard Edit/Draft creation if an Order already exists
        %update             = COND #( WHEN lv_order_exists  = abap_true
        THEN if_abap_behv=>fc-o-disabled
        ELSE if_abap_behv=>fc-o-enabled )

        %delete             = COND #( WHEN lv_order_exists  = abap_true
        THEN if_abap_behv=>fc-o-disabled
        ELSE if_abap_behv=>fc-o-enabled )

        " Partner Button Control
        %assoc-_Partner     = COND #( WHEN lv_is_supervisor = abap_true
                    OR                     lv_order_exists  = abap_true
        THEN if_abap_behv=>fc-o-enabled
        ELSE if_abap_behv=>fc-o-disabled )

        " BM Order Button Control (Grey out if Operator OR if Order exists)
        %action-createOrder = COND #( WHEN lv_is_supervisor = abap_false OR lv_order_exists = abap_true
                    THEN if_abap_behv=>fc-o-disabled
                    ELSE if_abap_behv=>fc-o-enabled )
      ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_authorizations.

    DATA: lv_update_auth TYPE abap_bool,
          lv_delete_auth TYPE abap_bool.

    lv_update_auth  = abap_false.
    lv_delete_auth  = abap_false.

    " Check UPDATE (02)
    AUTHORITY-CHECK OBJECT 'ZPM_NOTIF'
    ID 'ZPM_ROLE' DUMMY
    ID 'ACTVT'    FIELD '02'.
    IF sy-subrc = 0.
      lv_update_auth = abap_true.
    ENDIF.

    " Check DELETE (06)
    AUTHORITY-CHECK OBJECT 'ZPM_NOTIF'
    ID 'ZPM_ROLE' DUMMY
    ID 'ACTVT'    FIELD '06'.
    IF sy-subrc = 0.
      lv_delete_auth = abap_true.
    ENDIF.

    " ==============================================================
    " 1. NEW: Read the backend data to check the Order status
    " ==============================================================
    READ ENTITIES OF zr_pm_notif IN LOCAL MODE
      ENTITY Notification
      FIELDS ( MaintenanceOrder )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_notif_data).

    LOOP AT keys INTO DATA(key).

      " ==============================================================
      " 2. NEW: Determine if the order exists for this specific row
      " ==============================================================
      DATA(lv_order_exists) = abap_false.
      READ TABLE lt_notif_data INTO DATA(ls_notif) WITH KEY %tky = key-%tky.
      IF sy-subrc = 0 AND ls_notif-MaintenanceOrder IS NOT INITIAL.
        lv_order_exists = abap_true.
      ENDIF.

      DATA(lv_final_update_auth) = COND #( WHEN lv_order_exists = abap_true
                                           THEN abap_false
                                           ELSE lv_update_auth ).

      APPEND VALUE #(
        NotificationNo = key-NotificationNo

        " 1. Standard Update (Protects backend data)
        %update        = COND #( WHEN requested_authorizations-%update = if_abap_behv=>mk-on
                                 THEN COND #( WHEN lv_final_update_auth = abap_true
                                              THEN if_abap_behv=>auth-allowed
                                              ELSE if_abap_behv=>auth-unauthorized )
                                 ELSE if_abap_behv=>auth-unauthorized )

        " 2. Standard Delete (Protects backend data & hides Delete button)
        %delete        = COND #( WHEN requested_authorizations-%delete = if_abap_behv=>mk-on
                                 THEN COND #( WHEN lv_delete_auth = abap_true
                                              THEN if_abap_behv=>auth-allowed
                                              ELSE if_abap_behv=>auth-unauthorized )
                                 ELSE if_abap_behv=>auth-unauthorized )

        " 3. CRITICAL FIX: Hides the actual Fiori 'Edit' Action Button!
        %action-Edit   = COND #( WHEN requested_authorizations-%action-Edit = if_abap_behv=>mk-on
                                 THEN COND #( WHEN lv_final_update_auth = abap_true
                                              THEN if_abap_behv=>auth-allowed
                                              ELSE if_abap_behv=>auth-unauthorized )
                                 ELSE if_abap_behv=>auth-unauthorized )

      ) TO result.
    ENDLOOP.

  ENDMETHOD.

*  METHOD create.
*  ENDMETHOD.

  METHOD update.
    LOOP AT entities INTO DATA(ls_entity).

      DATA(ls_update) = VALUE lhc_zr_pm_notif=>ty_notif_update( notif_no = ls_entity-NotificationNo ).

      " Check if Notification Text was changed
      IF ls_entity-%control-ShortText = if_abap_behv=>mk-on.
        ls_update-short_text   = ls_entity-ShortText.
        ls_update-short_text_x = abap_true.
      ENDIF.

      " Check if Equipment was changed
      IF ls_entity-%control-EquipmentNo = if_abap_behv=>mk-on.
        ls_update-equipment   = ls_entity-EquipmentNo.
        ls_update-equipment_x = abap_true.
      ENDIF.

      " Check if Workcenter was changed
      IF ls_entity-%control-Workcenter = if_abap_behv=>mk-on.
        " Convert the Workcenter string back to Internal ID just like we did in Create
        IF ls_entity-Workcenter IS NOT INITIAL.
          SELECT SINGLE workcenterinternalid FROM i_workcenter
            WHERE workcenter = @ls_entity-Workcenter
            INTO @ls_update-wkctr.
        ENDIF.
        ls_update-wkctr_x = abap_true.
      ENDIF.

      " Only append to the buffer if at least one field was actually changed
      IF ls_update-short_text_x = abap_true OR
         ls_update-equipment_x  = abap_true OR
         ls_update-wkctr_x      = abap_true.

        APPEND ls_update TO lhc_zr_pm_notif=>gt_notif_update_buffer.

      ENDIF.

*      IF ls_entity-%control-BasicCode = if_abap_behv=>mk-on.
*        ls_update-dl_code   = ls_entity-BasicCode.
*        ls_update-dl_code_x = abap_true.
*      ENDIF.
*
*      IF ls_entity-%control-DetailCode = if_abap_behv=>mk-on.
*        ls_update-d_code   = ls_entity-DetailCode.
*        ls_update-d_code_x = abap_true.
*      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD delete.

    DATA: lv_is_supervisor TYPE abap_bool,
          lv_aufnr         TYPE aufnr,
          lv_partner_exist TYPE abap_bool,
          lv_objnr         TYPE j_objnr.

    " 1. Check if the current user is a Supervisor
    " (We do this outside the loop for performance!)
    lv_is_supervisor = abap_false.
    AUTHORITY-CHECK OBJECT 'ZPM_NOTIF'
    ID 'ZPM_ROLE' FIELD 'SUP'
    ID 'ACTVT'    DUMMY.
    IF sy-subrc = 0.
      lv_is_supervisor = abap_true.
    ENDIF.

    LOOP AT keys INTO DATA(key).

      " We only want to process actual notifications from the SAP database.
      IF key-%is_draft = if_abap_behv=>mk-off.

        " =========================================================
        " VALIDATION 1: Check if a PM Order is already created
        " =========================================================
        CLEAR lv_aufnr.
        " AFIH table holds the Maintenance Order header, linked by QMNUM
        SELECT SINGLE aufnr FROM afih
          INTO @lv_aufnr
          WHERE qmnum = @key-NotificationNo.

        IF sy-subrc = 0 AND lv_aufnr IS NOT INITIAL.
          " Order exists! Block deletion and send message to UI.
          APPEND VALUE #( %tky        = key-%tky
                          %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-notification.

          APPEND VALUE #( %tky = key-%tky
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = |Cannot delete: PM Order { lv_aufnr ALPHA = OUT } is already created.| )
                        ) TO reported-notification.
          CONTINUE. " Skip the rest of the loop for this row!
        ENDIF.

        " =========================================================
        " VALIDATION 2: Check if Operator & Partner assigned
        " =========================================================
        IF lv_is_supervisor = abap_false.
          " The Object Number in IHPA for Notifications is always 'QM' + Notification Number
          lv_objnr = |QM{ key-NotificationNo }|.
          CLEAR lv_partner_exist.

          SELECT SINGLE @abap_true FROM ihpa
            INTO @lv_partner_exist
            WHERE objnr = @lv_objnr
              AND kzloesch EQ @space .

          IF sy-subrc = 0 AND lv_partner_exist = abap_true.
            " Partner exists and user is an Operator! Block deletion.
            APPEND VALUE #( %tky        = key-%tky
                            %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-notification.

            APPEND VALUE #( %tky = key-%tky
                            %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                          text     = 'Notifications having Partner cant be deleted.' )
                          ) TO reported-notification.
            CONTINUE. " Skip the rest of the loop for this row!
          ENDIF.
        ENDIF.

        " =========================================================
        " IF ALL VALIDATIONS PASS, QUEUE FOR DELETION
        " =========================================================
        APPEND key-NotificationNo TO lhc_zr_pm_notif=>gt_notif_delete_buffer.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD read.

    " 1. Fetch the active data based on the keys requested by the framework
    IF keys IS NOT INITIAL.
      SELECT * FROM zr_pm_notif
        FOR ALL ENTRIES IN @keys
        WHERE NotificationNo = @keys-NotificationNo
        INTO TABLE @DATA(lt_active_data).
    ENDIF.

    " 2. Map the data back to the 'result' parameter so Fiori can build the draft
    LOOP AT lt_active_data INTO DATA(ls_active).
      INSERT VALUE #(
          %tky  = VALUE #( NotificationNo = ls_active-NotificationNo )
          " Use CORRESPONDING to automatically map all fields (Plant, Equipment, etc.)
          %data = CORRESPONDING #( ls_active )
      ) INTO TABLE result.
    ENDLOOP.


  ENDMETHOD.

  METHOD lock.
    DATA: lv_user TYPE symsgv.

    LOOP AT keys INTO DATA(key).

      CALL FUNCTION 'ENQUEUE_EIQMEL'
        EXPORTING
          qmnum          = key-NotificationNo
        EXCEPTIONS
          foreign_lock   = 1
          system_failure = 2
          OTHERS         = 3.

      IF sy-subrc <> 0.
        " 1. Capture the locking user
        lv_user = sy-msgv1.
        IF lv_user IS INITIAL.
          lv_user = 'another user'.
        ENDIF.

        " 2. Fail the action to stop the draft creation
        APPEND VALUE #( NotificationNo = key-NotificationNo
                        %fail-cause    = if_abap_behv=>cause-locked
                      ) TO failed-notification.

        " 3. THE MAGIC FIX: Append the reference DIRECTLY to %other
        " (No VALUE #( %msg = ... ) wrapper needed here!)
        APPEND new_message( id       = '00'
                            number   = '001'
                            severity = if_abap_behv_message=>severity-error
                            v1       = 'Locked in SAP GUI by user:'
                            v2       = lv_user )
               TO reported-%other.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD createWithPopup.

    LOOP AT keys INTO DATA(key).

      DATA(ls_param) = key-%param.

      IF ls_param-notiftype IS INITIAL.
        ls_param-notiftype = 'BM'.
      ENDIF.

      IF ls_param-short_text IS INITIAL.
        APPEND VALUE #( %cid = key-%cid
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Description is mandatory' )
                      ) TO reported-notification.
        CONTINUE.
      ENDIF.

      " --- Validations ---
      IF ls_param-plant IS INITIAL.
        APPEND VALUE #( %cid = key-%cid
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Plant is mandatory' )
                      ) TO reported-notification.
        CONTINUE.
      ENDIF.

      IF ls_param-Equipment IS INITIAL.
        APPEND VALUE #( %cid = key-%cid
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Equipment is mandatory' )
                      ) TO reported-notification.
        CONTINUE.
      ENDIF.

*      IF ls_param-WorkCenter IS INITIAL.
*        APPEND VALUE #( %cid = key-%cid
*                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
*                                                      text     = 'Workcenter is mandatory' )
*                      ) TO reported-notification.
*        CONTINUE.
*      ELSE.
*        SELECT SINGLE workcenterinternalid INTO @DATA(lv_arbpl) FROM i_workcenter WHERE workcenter = @ls_param-WorkCenter.
*      ENDIF.

      IF ls_param-dl_codegrp IS INITIAL.
        ls_param-dl_codegrp = 'Y1'.
      ENDIF.

      IF ls_param-dl_code IS INITIAL.
        APPEND VALUE #( %cid = key-%cid
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Basic Stoppage Code is mandatory' )
                      ) TO reported-notification.
        CONTINUE.
      ENDIF.

      IF ls_param-d_codegrp IS INITIAL.
        ls_param-d_codegrp = 'Y2'.
      ENDIF.

      IF ls_param-d_code IS INITIAL.
        APPEND VALUE #( %cid = key-%cid
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Detail Stoppage Code is mandatory' )
                      ) TO reported-notification.
        CONTINUE.
      ENDIF.

      " =========================================================
      " VALIDATION: Duplicate Notification Check
      " Same equipment + same date + same basic/detail stoppage codes
      " =========================================================
      SELECT SINGLE NotificationNo
        FROM ZR_PM_NOTIF
        WHERE EquipmentNo  = @ls_param-Equipment
          AND CreationDate = @( cl_abap_context_info=>get_system_date( ) )
          AND BasicCode    = @ls_param-dl_code
          AND DetailCode   = @ls_param-d_code
        INTO @DATA(lv_dup_notif).

      IF sy-subrc = 0 AND lv_dup_notif IS NOT INITIAL.
        APPEND VALUE #( %cid = key-%cid
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = |Duplicate: Notification { lv_dup_notif ALPHA = OUT } already exists for this equipment with same stoppage codes on today's date.| )
                      ) TO reported-notification.
        CONTINUE.
      ENDIF.

*      " 2. Passed all validations! Add data to the Global Buffer for the Saver class
      APPEND VALUE #(
          cid        = key-%cid
          notiftype  = ls_param-notiftype
          short_text = ls_param-short_text
          plant      = ls_param-plant
          equipment  = ls_param-Equipment
*          wkctr      = lv_arbpl
          dl_codegrp = ls_param-dl_codegrp
          dl_code    = ls_param-dl_code
          d_codegrp  = ls_param-d_codegrp
          d_code     = ls_param-d_code
          breakdown  = ls_param-breakdown
      ) TO lhc_zr_pm_notif=>gt_notif_buffer.

      " Inform UI that processing has started
*      SELECT SINGLE MAX( maintenancenotification )
*              FROM I_MaintenanceNotification
*              WHERE CreationDate = @( cl_abap_context_info=>get_system_date( ) )
*                AND createdbyuser   = @( cl_abap_context_info=>get_user_technical_name( ) )
*              INTO @DATA(lv_last_notif).
      APPEND VALUE #( %cid = key-%cid
                      %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                                    text     = |'Notification is queued for creation...' | )
                    ) TO reported-notification.
    ENDLOOP.

  ENDMETHOD.


  METHOD cba_Partner.
    " This method is called when the user adds a new partner and clicks Save.
    LOOP AT entities_cba INTO DATA(ls_parent).

      " Loop through the new child rows added to this parent
      LOOP AT ls_parent-%target INTO DATA(ls_new_partner).

        " Add it to the global buffer with the 'Insert' flag
        APPEND VALUE #(
            notif_no = ls_parent-NotificationNo
            parvw    = 'VU' " <-- FIX: Ignores UI and forces 'VU'
            partner  = ls_new_partner-Partner
            updkz    = 'I' " I = Insert
        ) TO lhc_zr_pm_notif=>gt_assign_buffer.

        " Map the temporary Content ID (%cid) to tell Fiori it was successful
        INSERT VALUE #( %cid            = ls_new_partner-%cid
                        NotificationNo  = ls_parent-NotificationNo
                        PartnerFunction = ls_new_partner-PartnerFunction )
               INTO TABLE mapped-partner.

      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete_partner.
    " This method is called when the user removes a partner and clicks Save.
    LOOP AT keys INTO DATA(ls_deleted_partner).

      " Add it to the global buffer with the 'Delete' flag
      APPEND VALUE #(
          notif_no = ls_deleted_partner-NotificationNo
          parvw    = ls_deleted_partner-PartnerFunction
          partner  = ls_deleted_partner-PartnerCounter " Or Partner ID depending on your key
          updkz    = 'D' " D = Delete
      ) TO lhc_zr_pm_notif=>gt_assign_buffer.

    ENDLOOP.

  ENDMETHOD.


  METHOD createOrder.
    " 1. Read current data from the RAP Buffer
    READ ENTITIES OF zr_pm_notif IN LOCAL MODE
      ENTITY Notification
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_notifications).

    LOOP AT keys INTO DATA(ls_key).

      READ TABLE lt_notifications INTO DATA(ls_notif) WITH KEY %tky = ls_key-%tky.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      " 2. Validation: Ensure no order exists
      IF ls_notif-MaintenanceOrder IS NOT INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-notification.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = |Notification already has Order { ls_notif-MaintenanceOrder ALPHA = OUT }| )
                      ) TO reported-notification.
        CONTINUE.
      ENDIF.

      " validate whether workcenter has been selected
      IF ls_notif-WorkCenter IS INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-notification.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = |For Order Creation WorkCenter must be maintained | )
                      ) TO reported-notification.
        CONTINUE.
      ENDIF.

      IF NOT ls_notif-NotificationNo IS INITIAL.
        SELECT NotificationNo, Partner
         FROM ZR_PM_NotifPartner
         WHERE NotificationNo = @ls_notif-NotificationNo
         INTO TABLE @DATA(lt_notif_partner).
        IF lt_notif_partner[] IS INITIAL.
          APPEND VALUE #( %tky = ls_key-%tky ) TO failed-notification.
          APPEND VALUE #( %tky = ls_key-%tky
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = |For Order Creation Partner must be maintained | )
                        ) TO reported-notification.
          CONTINUE.
        ENDIF.
      ENDIF.

      " 3. Queue for the Saver Class
      APPEND VALUE #(
          notif_no   = ls_notif-NotificationNo
          plant      = ls_notif-Plant
          short_text = ls_notif-ShortText
          wkctr      = ls_notif-WorkCenter
      ) TO lhc_zr_pm_notif=>gt_order_create_buffer.

      " 4. Send Success Message to Fiori
      APPEND VALUE #( %tky = ls_key-%tky
                      %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                                    text     = |BM Order queued for Notification { ls_notif-NotificationNo ALPHA = OUT }| )
                    ) TO reported-notification.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.



CLASS lsc_ZR_PM_NOTIF DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZR_PM_NOTIF IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.

    " 1. ==========================================
    " NEW NOTIFICATION SAVE LOGIC
    " ==========================================

    DATA: lt_return             TYPE TABLE OF bapiret2,
          es_notifheader_export TYPE bapi2080_nothdre,
          lt_noitemi            TYPE TABLE OF bapi2080_notitemi.
    " Define a local table type for the RIHPA structure
    TYPES tt_rihpa TYPE STANDARD TABLE OF rihpa WITH DEFAULT KEY.

    LOOP AT lhc_zr_pm_notif=>gt_notif_buffer INTO DATA(ls_buffer).

      CLEAR: lt_return, lt_noitemi, es_notifheader_export.

      " Header Data & X-Table
      DATA(ls_notif_header) = VALUE bapi2080_nothdri(
                planplant  = ls_buffer-plant
                short_text = ls_buffer-short_text
                equipment  = ls_buffer-equipment
                plangroup  = '001'
                pm_wkctr   = ls_buffer-wkctr
                breakdown  = ls_buffer-breakdown ).

      " Item Data & X-Table (Mandatory for values to save)
      lt_noitemi = VALUE #( (
                            item_key     = '0001'
                            item_sort_no = '0001'
                            dl_codegrp   = ls_buffer-dl_codegrp
                            dl_code      = ls_buffer-dl_code
                            d_codegrp    = ls_buffer-d_codegrp
                            d_code       = ls_buffer-d_code ) ).

      " Execute BAPI
      CALL FUNCTION 'BAPI_ALM_NOTIF_CREATE'
        EXPORTING
          notif_type         = ls_buffer-notiftype
          notifheader        = ls_notif_header
        IMPORTING
          notifheader_export = es_notifheader_export
        TABLES
          notitem            = lt_noitemi
          return             = lt_return.

      " Check for critical errors before saving
      LOOP AT lt_return INTO DATA(ls_return) WHERE type CA 'EA'.
        EXIT.
      ENDLOOP.

      IF sy-subrc <> 0. " No Errors Found (sy-subrc is 4, meaning the loop found no 'E' or 'A')
        CALL FUNCTION 'BAPI_ALM_NOTIF_SAVE'
          EXPORTING
            number = es_notifheader_export-notif_no
          TABLES
            return = lt_return.

        " NO COMMIT WORK. The framework does it automatically right after this method.
      ENDIF.

      DATA(lv_err_s) = abap_false.
      LOOP AT lt_return INTO DATA(ls_return_s) WHERE type CA 'EA'.
        lv_err_s = abap_true.
        APPEND VALUE #(
          %tky = VALUE #( notificationno = es_notifheader_export-notif_no )
          %msg = new_message(
                          id             = ls_return_s-id
                          number         = ls_return_s-number
                          severity       = if_abap_behv_message=>severity-error
                          v1             = ls_return_s-message_v1
                          v2             = ls_return_s-message_v2
                          v3             = ls_return_s-message_v3
                          v4             = ls_return_s-message_v4 )
        ) TO reported-notification.
      ENDLOOP.

      IF lv_err_s IS INITIAL.
*
*        SELECT SINGLE MAX( maintenancenotification )
*              FROM I_MaintenanceNotification
*              WHERE CreationDate = @( cl_abap_context_info=>get_system_date( ) )
*                AND createdbyuser   = @( cl_abap_context_info=>get_user_technical_name( ) )
*              INTO @DATA(lv_last_notif).
*
*        lv_last_notif += 1.
*
        SELECT SINGLE zuser
          FROM zpm_schedule
         WHERE zplant = @ls_buffer-plant
          INTO @DATA(lv_uname).

        IF sy-subrc = 0.
          lhc_ZR_PM_NOTIF=>sending_email(
            is_mail = VALUE #(
              uname     = lv_uname
              subject   = |A new notification has been created.|
              body      = |Please check the new notification and assign Person Resp(s) and convert to Order.|
              doctype   = 'N'
              docnumber = ''
          )
          ).
        ENDIF.

      ENDIF.

    ENDLOOP.

    " 4. Clear the buffer so it doesn't execute twice!
    CLEAR lhc_zr_pm_notif=>gt_notif_buffer.

    " ==========================================
    " PARTNER ASSIGNMENT LOGIC (Grid +/-)
    " ==========================================

    DATA: lt_partner_add    TYPE TABLE OF bapi2080_notpartnri,
          ls_partner_add    TYPE bapi2080_notpartnri,

          lt_partner_delete TYPE TABLE OF bapi2080_notpartnri,
          ls_partner_delete TYPE bapi2080_notpartnri,

          lt_ret_asgn       TYPE TABLE OF bapiret2.

    LOOP AT lhc_zr_pm_notif=>gt_assign_buffer INTO DATA(ls_assign_buffer)
         GROUP BY ls_assign_buffer-notif_no INTO DATA(lv_notif_no).

      " Always clear your tables at the start of the notification loop!
      CLEAR: lt_partner_add, lt_partner_delete, lt_ret_asgn.

      " 1. Loop through the group and route actions to the correct tables
      LOOP AT GROUP lv_notif_no INTO DATA(ls_partner_action).

        IF ls_partner_action-updkz = 'I'. " Handle Inserts

          " Route directly to ADD table
          CLEAR ls_partner_add.
          ls_partner_add-partn_role = 'VU'.
          ls_partner_add-partner    = ls_partner_action-partner.
          APPEND ls_partner_add TO lt_partner_add.

        ELSEIF ls_partner_action-updkz = 'D'. " Handle Deletes

          DATA(lv_objnr) = |QM{ lv_notif_no }|.
          SELECT SINGLE parnr INTO @DATA(lv_parnr) FROM ihpa WHERE objnr = @lv_objnr AND parvw = 'VU' AND counter = @ls_partner_action-partner.
          " Route directly to DELETE table
          CLEAR ls_partner_delete.
          ls_partner_delete-partn_role = 'VU'.
          ls_partner_delete-partner    = lv_parnr."ls_partner_action-partner.
          APPEND ls_partner_delete TO lt_partner_delete.

        ENDIF.

      ENDLOOP.

      " 2. Call the correct BAPIs based on the populated tables

      " Call ADD
      IF lt_partner_add IS NOT INITIAL.
        CALL FUNCTION 'BAPI_ALM_NOTIF_DATA_ADD'
          EXPORTING
            number      = lv_notif_no
          TABLES
            notifpartnr = lt_partner_add
            return      = lt_ret_asgn.
      ENDIF.

      " Call DELETE
      IF lt_partner_delete IS NOT INITIAL.
        CALL FUNCTION 'BAPI_ALM_NOTIF_DATA_DELETE'
          EXPORTING
            number      = lv_notif_no
          TABLES
            notifpartnr = lt_partner_delete
            return      = lt_ret_asgn.
      ENDIF.

      " 3. Check for errors and Save the Notification

      DATA(lv_has_error) = abap_false.

      " Loop through the return table looking for Errors or Aborts
      LOOP AT lt_ret_asgn TRANSPORTING NO FIELDS WHERE type = 'E' OR type = 'A'.
        lv_has_error = abap_true.
        EXIT. " Stop looping as soon as we find the first error
      ENDLOOP.

      " If no errors were found AND we actually executed a BAPI
      IF lv_has_error = abap_false .
        CALL FUNCTION 'BAPI_ALM_NOTIF_SAVE'
          EXPORTING
            number = lv_notif_no
          TABLES
            return = lt_ret_asgn.
      ENDIF.

      DATA(lv_err_p) = abap_false.
      LOOP AT lt_ret_asgn INTO DATA(ls_return_p) WHERE type CA 'EA'.
        lv_err_p = abap_true.
        APPEND VALUE #(
          %tky = VALUE #( notificationno = lv_notif_no )
          %msg = new_message(
                          id             = ls_return_p-id
                          number         = ls_return_p-number
                          severity       = if_abap_behv_message=>severity-error
                          v1             = ls_return_p-message_v1
                          v2             = ls_return_p-message_v2
                          v3             = ls_return_p-message_v3
                          v4             = ls_return_p-message_v4 )
        ) TO reported-notification.
      ENDLOOP.

    ENDLOOP.

    " Clear buffer so it doesn't accidentally execute twice!
    CLEAR lhc_zr_pm_notif=>gt_assign_buffer.

    " ==========================================
    " HEADER UPDATE LOGIC (Notification Edit)
    " ==========================================
    DATA: ls_header_update   TYPE bapi2080_nothdri,
          ls_header_update_x TYPE bapi2080_nothdri_x,
          lt_noitemi_x       TYPE TABLE OF bapi2080_notitemi_x,
          lt_return_hdr      TYPE TABLE OF bapiret2.

    LOOP AT lhc_zr_pm_notif=>gt_notif_update_buffer INTO DATA(ls_update_buf).
      CLEAR: ls_header_update, ls_header_update_x, lt_return_hdr.

      " 1. Map changed fields to BAPI Header structures
      IF ls_update_buf-short_text_x = abap_true.
        ls_header_update-short_text   = ls_update_buf-short_text.
        ls_header_update_x-short_text = 'X'.
      ENDIF.

      IF ls_update_buf-equipment_x = abap_true.
        ls_header_update-equipment   = ls_update_buf-equipment.
        ls_header_update_x-equipment = 'X'.
      ENDIF.

      IF ls_update_buf-wkctr_x = abap_true.
        ls_header_update-pm_wkctr   = ls_update_buf-wkctr.
        ls_header_update_x-pm_wkctr = 'X'.
      ENDIF.

      " 2. Call the Modify BAPI for the Header
      CALL FUNCTION 'BAPI_ALM_NOTIF_DATA_MODIFY'
        EXPORTING
          number        = ls_update_buf-notif_no
          notifheader   = ls_header_update
          notifheader_x = ls_header_update_x
        TABLES
*         notifitem     = lt_noitemi
*         notifitem_x   = lt_noitemi_x
          return        = lt_return_hdr.

      " 3. Check for errors and Save
      DATA(lv_hdr_error) = abap_false.
      LOOP AT lt_return_hdr TRANSPORTING NO FIELDS WHERE type = 'E' OR type = 'A'.
        lv_hdr_error = abap_true.
        EXIT.
      ENDLOOP.

      IF lv_hdr_error = abap_false.
        CALL FUNCTION 'BAPI_ALM_NOTIF_SAVE'
          EXPORTING
            number = ls_update_buf-notif_no
          TABLES
            return = lt_return_hdr.
      ENDIF.

      DATA(lv_err_u) = abap_false.
      LOOP AT lt_return_hdr INTO DATA(ls_return_u) WHERE type CA 'EA'.
        lv_err_u = abap_true.
        APPEND VALUE #(
          %tky = VALUE #( notificationno = ls_update_buf-notif_no )
          %msg = new_message(
                          id             = ls_return_u-id
                          number         = ls_return_u-number
                          severity       = if_abap_behv_message=>severity-error
                          v1             = ls_return_u-message_v1
                          v2             = ls_return_u-message_v2
                          v3             = ls_return_u-message_v3
                          v4             = ls_return_u-message_v4 )
        ) TO reported-notification.
      ENDLOOP.

    ENDLOOP.

    " Clear buffer so it doesn't accidentally execute twice!
    CLEAR lhc_zr_pm_notif=>gt_notif_update_buffer.


    " ==========================================
    " HEADER DELETION LOGIC (Set DLFL)
    " ==========================================
    DATA: lt_return_del TYPE TABLE OF bapiret2.

    LOOP AT lhc_zr_pm_notif=>gt_notif_delete_buffer INTO DATA(lv_del_notif).
      CLEAR lt_return_del.

      " Use the standard SAP internal function to set the Deletion Flag (DLFL)
      CALL FUNCTION 'IBAPI_ALM_NOTIF_SETDELFLAG'
        EXPORTING
          number = lv_del_notif
        TABLES
          return = lt_return_del.

      " Check for errors
      DATA(lv_del_error) = abap_false.
      LOOP AT lt_return_del TRANSPORTING NO FIELDS WHERE type = 'E' OR type = 'A'.
        lv_del_error = abap_true.
        EXIT.
      ENDLOOP.

      " Save the status change to the database if no errors occurred
      IF lv_del_error = abap_false.
        CALL FUNCTION 'BAPI_ALM_NOTIF_SAVE'
          EXPORTING
            number = lv_del_notif
          TABLES
            return = lt_return_del.
      ENDIF.

      DATA(lv_err_d) = abap_false.
      LOOP AT lt_return_del INTO DATA(ls_return_d) WHERE type CA 'EA'.
        lv_err_d = abap_true.
        APPEND VALUE #(
          %tky = VALUE #( notificationno = lv_del_notif )
          %msg = new_message(
                          id             = ls_return_d-id
                          number         = ls_return_d-number
                          severity       = if_abap_behv_message=>severity-error
                          v1             = ls_return_d-message_v1
                          v2             = ls_return_d-message_v2
                          v3             = ls_return_d-message_v3
                          v4             = ls_return_d-message_v4 )
        ) TO reported-notification.
      ENDLOOP.

    ENDLOOP.

    " Clear buffer so it doesn't accidentally execute twice!
    CLEAR lhc_zr_pm_notif=>gt_notif_delete_buffer.



    " ==========================================
    " PM ORDER CREATION LOGIC (Replicating IW34 Automation)
    " ==========================================
    DATA: lt_methods   TYPE TABLE OF bapi_alm_order_method,
          lt_header    TYPE TABLE OF bapi_alm_order_headers_i,
          lt_operation TYPE TABLE OF bapi_alm_order_operation.

    DATA: lv_counter TYPE i,
          lv_refnum  TYPE n LENGTH 6,
          lv_temp_id TYPE n LENGTH 11,
          lv_orderid TYPE aufnr.

    DATA: BEGIN OF ls_partner,
            notif_no TYPE qmnum,
            order_no TYPE aufnr,
            partner  TYPE ihpa-parnr,
          END OF ls_partner,
          lt_partner LIKE TABLE OF ls_partner,
          lt_prtner  TYPE TABLE OF bapi_alm_order_partn_mul.

    DATA: lt_order_map TYPE TABLE OF bapiret2.

    CLEAR: lt_methods, lt_header, lt_operation, lt_return.

    LOOP AT lhc_zr_pm_notif=>gt_order_create_buffer INTO DATA(ls_order_buffer).

      " 1. Increment counters
      lv_counter += 1.
      lv_refnum  = lv_counter.
      lv_temp_id = lv_counter.
      lv_orderid = |%{ lv_temp_id }|.

      SELECT NotificationNo, Partner
        FROM ZR_PM_NotifPartner
        WHERE NotificationNo = @ls_order_buffer-notif_no
        INTO TABLE @DATA(lt_notif_partners).


      DESCRIBE TABLE lt_notif_partners LINES DATA(lv_lines).
      LOOP AT lt_notif_partners INTO DATA(ls_partner_rec).
        IF  sy-tabix EQ 1 .
          CONTINUE.
        ENDIF.
        " Partner datası (lt_partner: TYPE TABLE OF bapi_alm_order_partn_mul)
        APPEND VALUE #( orderid    = lv_orderid
                        partn_role = 'VU'
                        partner    = ls_partner_rec-Partner ) TO lt_prtner.
      ENDLOOP.

      " 2. Construct Keys
      DATA(lv_hdr_key) = |{ lv_orderid }{ ls_order_buffer-notif_no }|.
      DATA(lv_opr_key) = |{ lv_orderid }0010|.

      " 3. Append Methods (NO SAVE METHOD HERE!)
      APPEND VALUE #( refnumber = lv_refnum objecttype = 'HEADER'    method = 'CREATETONOTIF' objectkey = lv_hdr_key ) TO lt_methods.
      APPEND VALUE #( refnumber = lv_refnum objecttype = 'OPERATION' method = 'CREATE'        objectkey = lv_opr_key ) TO lt_methods.
      IF lv_lines NE 1.
        APPEND VALUE #( refnumber = lv_refnum objecttype = 'PARTNER'   method = 'CREATE'        objectkey = lv_orderid ) TO lt_methods.
      ENDIF.
      APPEND VALUE #( refnumber = lv_refnum objecttype = 'HEADER'    method = 'RELEASE'       objectkey = lv_orderid ) TO lt_methods.

      " 4. Append Header
      APPEND VALUE #( orderid    = lv_orderid
                      order_type = 'BM' ) TO lt_header.

      " 5. Append Operation
      APPEND VALUE #( activity    = '0010'
                      control_key = 'PM01'
                      description = ls_order_buffer-short_text
                      plant       = ls_order_buffer-plant
                      work_cntr   = ls_order_buffer-wkctr ) TO lt_operation.

    ENDLOOP.

    " 6. ONE SINGLE SAVE TO FLUSH THEM ALL
    IF lt_methods IS NOT INITIAL.

      " Tell the BAPI to save all orders currently in its buffer
      APPEND VALUE #( refnumber = '000001' objecttype = '' method = 'SAVE' objectkey = '' ) TO lt_methods.

      " Execute the BAPI
      CALL FUNCTION 'BAPI_ALM_ORDER_MAINTAIN'
        TABLES
          it_methods   = lt_methods
          it_header    = lt_header
          it_operation = lt_operation
          it_partner   = lt_prtner
          return       = lt_return.
    ENDIF.


    DATA(lv_err_o) = abap_false.
    LOOP AT lt_return INTO DATA(ls_return_o) WHERE type CA 'EA'.
      lv_err_o = abap_true.
      APPEND VALUE #(
        %tky = VALUE #( notificationno = ls_order_buffer-notif_no )
        %msg = new_message(
                        id             = ls_return_o-id
                        number         = ls_return_o-number
                        severity       = if_abap_behv_message=>severity-error
                        v1             = ls_return_o-message_v1
                        v2             = ls_return_o-message_v2
                        v3             = ls_return_o-message_v3
                        v4             = ls_return_o-message_v4 )
      ) TO reported-notification.
    ENDLOOP.

    CLEAR: lt_order_map[], lt_order_map.
    lt_order_map = VALUE #( FOR ls_ret IN lt_return
                            WHERE ( number = '126' )
                            (              ls_ret ) ).

    IF lv_err_o IS INITIAL AND NOT lt_order_map[] IS INITIAL.

      SELECT NotificationNo, Partner
        FROM ZR_PM_NotifPartner
        FOR ALL ENTRIES IN @lhc_zr_pm_notif=>gt_order_create_buffer
        WHERE NotificationNo = @lhc_zr_pm_notif=>gt_order_create_buffer-notif_no
        INTO TABLE @lt_notif_partners.

      LOOP AT lt_notif_partners ASSIGNING FIELD-SYMBOL(<fs_np>).
        SHIFT <fs_np>-NotificationNo LEFT DELETING LEADING '0'.
      ENDLOOP.

      LOOP AT lt_order_map INTO DATA(ls_map).
        lt_partner = VALUE #( BASE lt_partner
                              FOR ls_np IN lt_notif_partners
                              WHERE ( NotificationNo = ls_map-message_v3 )
                                    ( notif_no       = ls_map-message_v3
                                      order_no       = ls_map-message_v2
                                      partner        = ls_np-Partner ) ).
      ENDLOOP.

      LOOP AT lt_partner INTO ls_partner.
        lhc_ZR_PM_NOTIF=>sending_email(
          is_mail = VALUE #(
            uname     = ls_partner-partner
            subject   = |Order { ls_partner-order_no } created for { ls_partner-notif_no }.|
            body      = |A new order { ls_partner-order_no } has been created for notification { ls_partner-notif_no } and you have been assigned as a partner.|
            doctype   = 'O'
            docnumber = ls_partner-order_no ) ).
      ENDLOOP.

    ENDIF.

    CLEAR lhc_zr_pm_notif=>gt_order_create_buffer.

  ENDMETHOD.



  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.