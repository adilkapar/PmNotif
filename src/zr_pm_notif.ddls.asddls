@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PM Notification Root View'
define root view entity ZR_PM_NOTIF
  as select from    I_MaintenanceNotification   as notif
  // 1. ADD THIS JOIN: Look for an active Deletion Flag (I0076)
    left outer join jest                        as DelFlag    on  DelFlag.objnr = notif.MaintNotifInternalID
                                                              and DelFlag.stat  = 'I0076' // System Status: Deletion Flag
                                                              and DelFlag.inact = ''      // Ensure the flag is Active
    left outer join qmih                        as qmih       on notif.MaintenanceNotification = qmih.qmnum
    left outer join I_EquipmentText             as eqtxt      on  qmih.equnr     = eqtxt.Equipment
                                                              and eqtxt.Language = $session.system_language
    left outer join I_Equipment                 as equip      on qmih.equnr = equip.Equipment
    left outer join I_MaintNotificationItemData as item       on  notif.MaintenanceNotification    = item.MaintenanceNotification
                                                              and item.MaintenanceNotificationItem = '0001'
    left outer join I_BusinessUserBasic         as reporter   on notif.ReportedByUser = reporter.UserID
    left outer join ZI_PM_BM_WorkCenter         as WC         on WC.WorkCenterID = notif.WorkCenterInternalID
    left outer join qpct                        as basicText  on  basicText.katalogart = item.MaintNotifObjPrtCodeCatalog
                                                              and basicText.codegruppe = item.MaintNotifObjPrtCodeGroup
                                                              and basicText.code       = item.MaintNotifObjPrtCode
                                                              and basicText.sprache    = $session.system_language
    left outer join qpct                        as detailText on  detailText.katalogart = item.MaintNotifDamageCodeCatalog
                                                              and detailText.codegruppe = item.MaintNotifDamageCodeGroup
                                                              and detailText.code       = item.MaintNotificationDamageCode
                                                              and detailText.sprache    = $session.system_language

  // Composition is correctly defined here
  composition [0..*] of ZR_PM_NotifPartner      as _Partner

  association [0..*] to ZI_PM_BM_Equipment      as _Equipment      on _Equipment.Plant = $projection.Plant
  association [0..*] to ZI_PM_BM_WorkCenter     as _WorkCenter     on _WorkCenter.Plant = $projection.Plant
  association [0..*] to ZI_PM_BM_StoppageReason as _StoppageReason on _StoppageReason.Plant = $projection.Plant
{
  key notif.MaintenanceNotification    as NotificationNo,
      notif.NotificationType           as NotifType,
      item.MaintenancePlanningPlant    as Plant,
      //      notif.MaintenanceWorkCenterPlant as WcPlant,
      qmih.equnr                       as EquipmentNo,
      eqtxt.EquipmentName              as EquipmentDesc,
      notif.NotificationText           as ShortText,
      notif.CreatedByUser              as ReportedBy,
      reporter.BirthName               as ReporterName,
      notif.CreationDate               as CreationDate,
      notif.CreationTime               as CreationTime,
      notif.RequiredEndDate            as RequiredEndDate,
      item.MaintNotifObjPrtCodeGroup   as BasicCodeGroup,
      item.MaintNotifObjPrtCode        as BasicCode,
      basicText.kurztext               as BasicCodeText,
      item.MaintNotifDamageCodeGroup   as DetailCodeGroup,
      item.MaintNotificationDamageCode as DetailCode,
      detailText.kurztext              as DetailCodeText,
      notif.NotifProcessingPhase       as ProcessingPhase,
      qmih.msaus                       as Breakdown,


      case notif.NotifProcessingPhase
        when '1' then 'Outstanding'
        when '2' then 'In Process'
        when '3' then 'Completed'
        when '4' then 'Closed'
        else 'Unknown'
      end                              as ProcessingPhaseDesc,

      WC.WorkCenter                    as WorkCenter,
      WC.Description                   as WorkCenterText,
      notif.MaintenanceOrder           as MaintenanceOrder,

      /* Associations */
      _Equipment,
      _WorkCenter,
      _StoppageReason,
      _Partner
}
where
      notif.NotificationType = 'BM'
  and DelFlag.stat           is null