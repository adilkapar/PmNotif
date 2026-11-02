@AbapCatalog.sqlViewName: 'ZCDS_PM_NP'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Notification & parner'
@Metadata.ignorePropagatedAnnotations: true
define view Zv_PM_Notifpartner
  as select from ihpa as partner
      inner join   I_MaintenanceNotification as _Notification on _Notification.MaintNotifInternalID = partner.objnr
{
  key _Notification.MaintenanceNotification as NotificationNo,
  key concat( concat( cast( '00000000000000000000' as char20 ),
                      partner.counter ),
              cast( '000000' as char6 ) )   as DraftSeqNo,
      partner.counter                       as PartnerCounter,
      cast ( partner.parvw as char2 )       as PartnerFunction,
      partner.parnr                         as Partner}
where
      partner.objnr    like 'QM%'
  and partner.parvw    =    'VU'
  and partner.kzloesch is initial