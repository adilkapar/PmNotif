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
  key cast ( partner.parvw as char2 )       as PartnerFunction,
  key partner.counter                       as PartnerCounter,
      partner.parnr                         as Partner}
where
      partner.objnr    like 'QM%'
  and partner.parvw    =    'VU'
  and partner.kzloesch is initial